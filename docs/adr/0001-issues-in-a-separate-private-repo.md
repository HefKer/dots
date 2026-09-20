# ADR-0001: Issues live in a separate private repo

**Status:** Accepted — 2026-09-20

## Context

`dots` is public so the configs can be read and copied. Until now its backlog lived as
markdown under `.scratch/`, one directory per effort, one file per ticket.

Two problems, pulling in opposite directions.

`.scratch/` is gitignored globally (`~/.config/git/ignore:6`). Twelve tickets — a repo-wide
security audit and a syncthing investigation — existed on exactly one machine, with no
history and no backup. A disk failure would have taken all of it.

The obvious fix, committing them, was worse. Those tickets describe unfixed weaknesses in
scripts that handle vault secrets: a plaintext password reaching cliphist's on-disk history,
a predictable `/tmp` path, private keys replicating through Syncthing because
`.stglobalignore` has no secrets patterns. Publishing them in `dots` would have posted a
list of live weaknesses against a machine whose exact configuration the same repo already
discloses. A public issue is a fix that has not shipped yet, with the file path attached.

## Decision

Code stays in the public `hefker/dots`. Issues move to `hefker/dots-issues`, a private repo
holding no code — only its tracker. One milestone per effort, replacing what
`.scratch/<effort>/` provided.

The mechanics live in `docs/agents/issue-tracker.md`; this ADR records why.

## Consequences

`gh` infers its repo from `git remote -v`, which resolves to `dots` — the wrong one. Every
tracker command carries `--repo hefker/dots-issues`. `GH_REPO` does not help: each shell
command runs fresh, so the variable is gone by the next call.

Closing keywords do not cross repository boundaries. `Fixes #12` in a `dots` commit closes
nothing; tracker issues are closed explicitly, quoting the SHA. A bare `hefker/dots-issues#12`
in a public commit message still leaves a backlink in the issue timeline, and renders as a
dead reference to anyone without access — so a public commit can carry an issue number
without leaking its contents.

The backlog is now invisible to anyone reading the public repo. For a personal dotfiles repo
that takes no external contributions, losing that visibility costs nothing.

Two repos is the price. It is only worth paying while the asymmetry holds — public code,
private backlog. If the tickets ever stop being sensitive, the cheaper arrangement is issues
on `dots` itself.

## Notes

- 2026-09-20 — Adopted. All 12 `.scratch/` tickets migrated as issues #1–#12; no effort
  qualified as a carve-out, so `.scratch/` was emptied. Pre-migration originals are archived
  under `.archive/` in the tracker repo, with the full mapping table.
