Orchestrate subagents through every open ready-for-agent issue in this repo, onto one integration branch that I merge into main myself. You coordinate; subagents write the code. $0

Setup:
- Read AGENTS.md and the issue tracker and triage label docs it points to. List the open ready-for-agent issues and drop any already on main (`git log main --grep '#N'`). Read the rest with comments and order them by blockers, then number. An issue blocked by one outside the batch waits; list it in the report.
- Create branch `agent-batch-<YYYY-MM-DD>` from main in a worktree under `.claude/worktrees/`, so my checkout stays on main. Every subagent works only in that worktree, by absolute path.

Per issue, one implementer subagent. Issues that don't interfere (no blocker between them, no files likely touched by both) run at the same time in the background, each in its own worktree on its own branch from the integration tip, merged back into the integration branch as each finishes. The rest wait for the work they depend on to land, so each builds on it. Brief each with pointers, not copies: the issue number and the tracker's read command, its worktree path, its start commit. It:
- reads `~/.claude/skills/implement/SKILL.md` and follows it (that skill is user-invocable only, so it reads the file; /tdd and /code-review it loads with the Skill tool, the review covering everything since its start commit)
- loads /writing-for-agents before editing AGENTS.md, CLAUDE.md or any skill
- commits on its branch with a subject ending `(#N)`, and leaves the issue open
- settles underspecified points with the sensible default and lists them
- reports extremely concisely: commit hashes, what changed, test result, decisions for me

After each report, merge its branch into the integration branch (resolving conflicts with /resolving-merge-conflicts), run the full test suite there, and only then start the issues that waited on it. A failed issue stays unmerged, gets a note, and the batch moves on.

At the end, run the full test suite on the branch tip, remove the per-issue worktrees, and report: a table of issue, commit, decisions and deviations; skipped issues and why; the merge command and the integration worktree to remove after.
