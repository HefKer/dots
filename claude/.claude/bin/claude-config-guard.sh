#!/usr/bin/env bash
# Repair ~/.claude.json before a Claude Code session is allowed to read it.
#
# THE FAILURE THIS EXISTS FOR is not corruption -- it is a lost update. Every
# session reads the whole config at startup, holds it in memory, and writes the
# whole file back on each save. When herdr resumes N agents at once they all
# snapshot within the same second, and the last one to save wins: its snapshot
# erases every project entry the others added. Observed here as 38 projects ->
# 12 in two minutes, with 18 of the dropped paths still existing on disk.
#
# So the repair is a MERGE, not a restore. Restoring picks one snapshot as the
# winner, which is the same mistake that caused the loss -- the newest backup
# was itself missing 3 entries the live file had. Instead we union .projects
# across the live file and the backups, keeping the live value wherever both
# have a key, and only adopting entries whose directory still exists.
#
# Why a pre-launch wrapper step and not a hook: the earliest hook (SessionStart)
# fires after the CLI has already loaded the config into memory, so a repair
# there is overwritten seconds later by the session that booted from the damaged
# copy. Merging is only safe with no session holding the file -- i.e. right
# here, before `command claude` runs.
#
# Per account: claude-code reads $CLAUDE_CONFIG_DIR/.claude.json when that is
# set (~/.claude-hulio), else ~/.claude.json. The lock, log, backups and archive
# below follow the same switch, so each account is guarded against its own
# history and never restored from the other's.
#
# Usage: claude-config-guard.sh [--dry-run]
# Exits 0 unconditionally: a broken guard must never stop a launch.

set -uo pipefail

CONFIG_DIR="${CLAUDE_CONFIG_DIR:+${CLAUDE_CONFIG_DIR%/}}"   # empty for the main account
CONFIG_HOME="${CONFIG_DIR:-$HOME/.claude}"
CONFIG="${CONFIG_DIR:-$HOME}/.claude.json"
LOCK="$CONFIG_HOME/.launch.lock"
LOG="$CONFIG_HOME/config-guard.log"
SYNCED_BACKUPS="$CONFIG_HOME/backups"
ARCHIVE="$CONFIG_HOME-archive"           # permanent, unrotated, unsynced
LOCK_WAIT=10      # seconds to wait for the lock before giving up and launching
STAGGER=0.4       # seconds to hold the lock after a contended launch
KEEP_CORRUPT=3

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

log() {
  if [ "$DRY_RUN" = 1 ]; then printf '  %s\n' "$*"
  else printf '%s %s\n' "$(date -Is)" "$*" >>"$LOG"; fi
}

# Structural check: does this file carry real state? Deliberately NOT a
# sufficient check for the lost-update case -- a config that just dropped 26
# projects still passes. That is what merge_projects is for.
is_good() {
  [ -s "$1" ] || return 1
  jq -e '(.oauthAccount | type == "object")
         and (.projects | type == "object")
         and (.projects | length > 0)' "$1" >/dev/null 2>&1
}

account_of() { jq -r '.oauthAccount.emailAddress // ""' "$1" 2>/dev/null; }

# Merge sources, newest first.
#
# The local $CONFIG.bak chain sits beside the config, which Syncthing does not
# sync -- it is this host's own history and always trustworthy. ~/.claude IS a
# synced folder, so ~/.claude/backups also holds Lenovo's and desktop's copies.
# Those are still worth merging (today's 38-project recovery is only in there)
# but they are bounded twice: same-account only, and per-entry the directory
# must exist on this machine.
local_backups()  { ls -t "$CONFIG".bak "$CONFIG".bak.[0-9]* 2>/dev/null; }
synced_backups() { ls -t "$SYNCED_BACKUPS"/.claude.json.backup.* 2>/dev/null; }
# Hand-curated recoveries. Nothing rotates these out, which is exactly how the
# 38-project snapshot was lost the first time: it lived only in the CLI's
# 5-deep rotation and aged out in 25 minutes.
archive_backups() { ls -t "$ARCHIVE"/*/claude-json/.claude.json "$ARCHIVE"/*/backups/.claude.json.backup.* 2>/dev/null; }

restore() {
  local src dst_tmp
  while read -r src; do
    [ -n "$src" ] || continue
    is_good "$src" || continue
    if [ "$DRY_RUN" = 1 ]; then log "would restore from $src"; return 0; fi
    [ -e "$CONFIG" ] && mv -f "$CONFIG" "$CONFIG.corrupt.$(date +%s)-$$" 2>/dev/null
    dst_tmp=$(mktemp "$CONFIG.restore.XXXXXX") || return 1
    if cp "$src" "$dst_tmp" && chmod 644 "$dst_tmp" && mv -f "$dst_tmp" "$CONFIG"; then
      log "restored from $src ($(stat -c%s "$src") bytes)"
      return 0
    fi
    rm -f "$dst_tmp"
  done < <(local_backups; archive_backups; synced_backups)
  log "config invalid and NO usable backup found -- launching as-is"
  return 1
}

# Union .projects from every trustworthy backup into the live config.
# The live file always wins on keys both have: it is the most recent state.
merge_projects() {
  local work account missing allowed added_total=0 b n
  account=$(account_of "$CONFIG")
  work=$(mktemp "$HOME/.claude.json.merge.XXXXXX") || return 1
  cp "$CONFIG" "$work" || { rm -f "$work"; return 1; }

  # Shrink detection: the live file having fewer projects than a backup is the
  # signature of a lost update, and is worth saying out loud even though the
  # merge below repairs it.
  local live_n max_n=0
  live_n=$(jq '.projects | length' "$work" 2>/dev/null || echo 0)
  while read -r b; do
    [ -n "$b" ] && is_good "$b" || continue
    n=$(jq '.projects | length' "$b" 2>/dev/null || echo 0)
    [ "$n" -gt "$max_n" ] && max_n=$n
  done < <(local_backups; archive_backups; synced_backups)
  [ "$max_n" -gt "$live_n" ] && log "shrink detected: live has $live_n projects, a backup has $max_n"

  while read -r b; do
    [ -n "$b" ] || continue
    is_good "$b" || continue
    # Foreign-account backups are never merged.
    [ -n "$account" ] && [ "$(account_of "$b")" != "$account" ] && continue

    missing=$(jq -n \
      --slurpfile live <(jq '.projects | keys' "$work") \
      --slurpfile bak  <(jq '.projects | keys' "$b") \
      '$bak[0] - $live[0]' 2>/dev/null) || continue
    [ "$(jq 'length' <<<"$missing")" -gt 0 ] || continue

    # Only adopt an entry if its directory still exists here. Drops both other
    # hosts' paths and this host's deleted scratch dirs.
    allowed=$(jq -r '.[]' <<<"$missing" | while read -r p; do
                [ -d "$p" ] && jq -n --arg p "$p" '$p'; done | jq -sc '.')
    [ "$(jq 'length' <<<"$allowed")" -gt 0 ] || continue

    local tmp
    tmp=$(mktemp "$HOME/.claude.json.merge.XXXXXX") || continue
    if jq --slurpfile b "$b" --argjson allow "$allowed" \
         '.projects += ($b[0].projects | with_entries(select(.key | IN($allow[]))))' \
         "$work" >"$tmp" && is_good "$tmp"; then
      mv -f "$tmp" "$work"
      added_total=$((added_total + $(jq 'length' <<<"$allowed")))
      log "recovered $(jq 'length' <<<"$allowed") project(s) from $b"
      jq -r '.[] | "    + " + .' <<<"$allowed" | while read -r l; do log "$l"; done
    else
      rm -f "$tmp"
    fi
  done < <(local_backups; archive_backups; synced_backups)

  if [ "$added_total" -eq 0 ]; then
    rm -f "$work"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    log "would recover $added_total project(s): $live_n -> $((live_n + added_total))"
    rm -f "$work"
    return 0
  fi

  chmod 644 "$work" && mv -f "$work" "$CONFIG" \
    && log "merged: $live_n -> $(jq '.projects|length' "$CONFIG") projects" \
    || { rm -f "$work"; log "merge failed; config left untouched"; }
}

# The server re-pushes "<email>'s Organization" into the config on every OAuth
# token refresh, so a one-time edit reverts. Scrub it on each launch, before the
# CLI reads the file to render the welcome box. Atomic mktemp+rename (the old
# fixed $cfg.scrub path was itself racy across simultaneous launches).
scrub_org() {
  local tmp
  jq -e '.oauthAccount.organizationName // "" | test("@")' "$CONFIG" >/dev/null 2>&1 || return 0
  [ "$DRY_RUN" = 1 ] && { log "would scrub email out of organizationName"; return 0; }
  tmp=$(mktemp "$HOME/.claude.json.scrub.XXXXXX") || return 1
  if jq '.oauthAccount.organizationName = "Personal"' "$CONFIG" >"$tmp" \
     && is_good "$tmp" && chmod 644 "$tmp" && mv -f "$tmp" "$CONFIG"; then
    return 0
  fi
  rm -f "$tmp"
  log "org-name scrub failed; config left untouched"
}

prune_corrupt() {
  [ "$DRY_RUN" = 1 ] && return 0
  ls -t "$CONFIG".corrupt.* 2>/dev/null \
    | tail -n +$((KEEP_CORRUPT + 1)) | xargs -r rm -f
}

main() {
  is_good "$CONFIG" || restore
  is_good "$CONFIG" && merge_projects
  scrub_org
  prune_corrupt
}

mkdir -p "$(dirname "$LOCK")"

if [ "$DRY_RUN" = 1 ]; then
  echo "DRY RUN -- nothing will be written"
  main
  exit 0
fi

# Uncontended launch (the common case): take the lock, work, get out -- no added
# latency. Contended launch (herdr resuming a batch): wait, then hold the lock a
# beat longer so the sessions' startup writes are spread out. The stagger is a
# mitigation, not a fix -- nothing can lock the CLI's own writes, which is why
# the merge above has to exist.
exec 9>"$LOCK"
if flock -n 9; then
  main
elif flock -w "$LOCK_WAIT" 9; then
  main
  sleep "$STAGGER"
else
  log "could not acquire lock in ${LOCK_WAIT}s -- launching unguarded"
fi

exit 0
