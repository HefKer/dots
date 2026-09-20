# Issue tracker: GitHub, in a separate private repo

Code lives in `hefker/dots`. Issues live in **`hefker/dots-issues`**, a private repo
that holds no code — only its issue tracker. Use the `gh` CLI for all operations.

The dotfiles are public so the configs can be read and copied. The backlog is not,
because issues describe unfixed weaknesses in scripts that handle vault secrets —
`qute-rbw`, `yt_chat`, the syncthing ignore patterns — on a machine whose exact
configuration the public repo already discloses. A public issue is a fix that has
not shipped yet, with the file path attached.

## Every command names the repo

`gh` infers the repo from `git remote -v`, which resolves to `dots` — the wrong one.
Pass `--repo hefker/dots-issues` on every invocation. Exporting `GH_REPO` does not help:
each shell command runs in a fresh shell, so the variable is gone by the next call.

## Conventions

- **Create**: `gh issue create --repo hefker/dots-issues --title "..." --body-file -` (heredoc into stdin for multi-line bodies)
- **Read**: `gh issue view <n> --repo hefker/dots-issues --comments`
- **List**: `gh issue list --repo hefker/dots-issues --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`, with `--label` / `--state` / `--milestone` filters
- **Comment**: `gh issue comment <n> --repo hefker/dots-issues --body "..."`
- **Label**: `gh issue edit <n> --repo hefker/dots-issues --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <n> --repo hefker/dots-issues --comment "..."`

One **milestone** per effort, named for the effort. It is the grouping unit that
`.scratch/<feature>/` would otherwise provide, and gives the effort a visible finish line.

## Linking issues to the code

A commit or PR in `dots` that writes `hefker/dots-issues#12` leaves a backlink in that
issue's timeline. Closing keywords (`Fixes #12`) do not reach across repositories, so
close the issue explicitly with `gh issue close <n> --repo hefker/dots-issues`, quoting
the commit SHA.

The backlink renders as a dead reference to anyone without access to the private repo,
so a public commit message can carry an issue number without leaking its contents.

## When a skill says "publish to the issue tracker"

Create a GitHub issue in `hefker/dots-issues`.

## When a skill says "fetch the relevant ticket"

`gh issue view <n> --repo hefker/dots-issues --comments`.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as
feature requests; `/triage` reads this flag.)_ PRs land on the code repo, which has no
issue tracker, so the two surfaces are disjoint by construction.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one issue; each ticket is a **child** issue.

- **Map**: an issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: a GitHub sub-issue of the map —
  `gh api --method POST repos/hefker/dots-issues/issues/<map>/sub_issues -F sub_issue_id=<child-db-id>`.
  Label it `wayfinder:<type>` (`research` / `prototype` / `grilling` / `task`).
- **Database ids**: the dependency and sub-issue endpoints take an issue's numeric **database
  id**, not its `#number` and not its `node_id`. Fetch it with
  `gh api repos/hefker/dots-issues/issues/<n> --jq .id`.
- **Blocking**: native issue dependencies, visible in the UI —
  `gh api --method POST repos/hefker/dots-issues/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`.
  A ticket is unblocked when every blocker is closed.
- **Reading edges back**: `gh api repos/hefker/dots-issues/issues/<n>/dependencies/blocked_by`
  is authoritative and immediate. The `issue_dependencies_summary.blocked_by` count on the
  issue object lags a write by a few seconds, so read the dependencies endpoint when acting
  on an edge just created.
- **Frontier query**: list the map's open sub-issues, drop any with an open blocker or an
  assignee; first in map order wins.
- **Claim**: `gh issue edit <n> --repo hefker/dots-issues --add-assignee @me`, the session's
  first write.
- **Resolve**: comment the answer, close the issue, then append a context pointer (gist +
  link) to the map's Decisions-so-far.
