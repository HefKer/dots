function cmv --description 'mv a directory and carry its claude sessions along, so --resume still finds them'
    # Claude Code files sessions under ~/.claude/projects/<cwd with every
    # non-alphanumeric char turned into '-'>, and keys per-project trust and
    # permissions by path in ~/.claude.json. A plain mv orphans both. This moves
    # the directory, then re-files every project at or below it (subdirectories
    # get their own project dirs) and rewrites the "cwd" fields in the transcripts.
    if test (count $argv) -ne 2
        echo 'usage: cmv SRC_DIR DEST' >&2
        return 2
    end
    if not test -d $argv[1]
        echo "cmv: $argv[1] is not a directory" >&2
        return 1
    end

    set -l old (path resolve -- $argv[1])
    # mv semantics: an existing directory as DEST means "move into it".
    set -l new (path resolve -- $argv[2])
    test -d $new; and set new $new/(path basename -- $old)
    if test -e $new
        echo "cmv: $new already exists" >&2
        return 1
    end
    if string match -q -- "$old/*" $new
        echo "cmv: cannot move $old into itself" >&2
        return 1
    end

    command mv -- $old $new; or return

    set -l projects $HOME/.claude/projects
    set -l enc_old (string replace -ra '[^a-zA-Z0-9]' - -- $old)

    for dir in $projects/$enc_old $projects/$enc_old-*
        test -d $dir; or continue
        # The encoding is lossy (/a/b-c and /a/b/c collide), so trust the cwd a
        # transcript recorded over the dir name. A dir with no transcript yet
        # (memory only) is only taken on an exact name match.
        set -l cwd (command grep -rhom1 '"cwd":"[^"]*"' --include='*.jsonl' $dir 2>/dev/null | head -1 | string sub -s 8 -e -1)
        test -z "$cwd"; and test $dir = $projects/$enc_old; and set cwd $old
        test "$cwd" = $old; or string match -q -- "$old/*" "$cwd"; or continue

        set -l new_cwd $new(string sub -s (math (string length -- $old) + 1) -- $cwd)
        set -l enc_new (string replace -ra '[^a-zA-Z0-9]' - -- $new_cwd)
        if test (string length -- $enc_new) -gt 200
            echo "cmv: skipped $cwd -- new path too long, claude hashes those names" >&2
            continue
        end
        set -l dest $projects/$enc_new

        if test -e $dest
            # Destination already has sessions: merge, never clobber.
            for child in $dir/* $dir/.*
                command mv -n -- $child $dest/
            end
            command rmdir -- $dir 2>/dev/null
            or echo "cmv: left name clashes behind in $dir" >&2
        else
            command mv -- $dir $dest
        end

        OLD=$old NEW=$new find $dest -name '*.jsonl' -exec \
            perl -pi -e 's/"cwd":"\Q$ENV{OLD}\E(?=["\/])/"cwd":"$ENV{NEW}/g' {} +
        echo "sessions: $cwd -> $new_cwd"
    end

    # Rename the trust/permissions entries, under the same lock the launch guard
    # (functions/claude.fish) takes. A session already running keeps its old
    # snapshot in memory and may write the old key back when it saves.
    set -l cfg $HOME/.claude.json
    test -s $cfg; or return 0
    flock -w 10 $HOME/.claude/.launch.lock sh -c '
        tmp=$(mktemp "$3.cmv.XXXXXX") &&
        jq --arg old "$1" --arg new "$2" "
            .projects |= with_entries(
                if .key == \$old or (.key | startswith(\$old + \"/\"))
                then .key = \$new + .key[(\$old | length):] else . end)
        " "$3" >"$tmp" && chmod 644 "$tmp" && mv -f "$tmp" "$3" || { rm -f "$tmp"; exit 1; }
    ' sh $old $new $cfg
    or echo "cmv: could not update $cfg" >&2
end
