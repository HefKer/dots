# CLAUDE.md

- System config (flake, modules, hosts) lives separately at `~/nixos/`. System-level changes — packages, services, kernel — go there, not here.
- App configs in `$XDG_CONFIG_HOME` belong in this repo, even when the package itself is Nix-installed.
- `reference/` holds clones of other people's dotfiles, kept to read for ideas. Gitignored, never stowed — don't edit anything under it.

## Agent skills

### Issue tracker

Issues live in the separate private repo **`hefker/dots-issues`**, so every `gh` command
needs `--repo hefker/dots-issues`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
