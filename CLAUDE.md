# CLAUDE.md

- System config (flake, modules, hosts) lives separately at `~/nixos/`. System-level changes — packages, services, kernel — go there, not here.
- App configs in `$XDG_CONFIG_HOME` belong in this repo, even when the package itself is Nix-installed.
- `reference/` holds clones of other people's dotfiles, kept to read for ideas. Gitignored, never stowed — don't edit anything under it.
