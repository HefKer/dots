# AGENTS.md

- System config (flake, modules, hosts) lives separately at `~/nixos/`. System-level changes — packages, services, kernel — go there, not here.
- App configs in `$XDG_CONFIG_HOME` belong in this repo, even when the package itself is Nix-installed. The layers split three ways: NixOS installs the package, home-manager in `~/nixos/` declares the link set that places files into `$HOME`, and this repo holds the files' content. Putting config here keeps it editable without a rebuild, since the links are out-of-store symlinks; generating it in Nix is reserved for config that must reference something only Nix knows, like a store path. See `~/nixos/main/docs/adr/0001-dotfiles-wired-by-home-manager-as-out-of-store-symlinks.md` and `~/nixos/main/GLOSSARY.md` — the out-of-store symlinks are deliberate, don't replace them with store copies.
- A new package needs an entry in the link set (`~/nixos/main/homes/modules/dotfiles.nix`), the same link in the dotfiles check's expected set for each host (`~/nixos/main/checks/default.nix`), one rebuild, and a row in `README.md`'s Packages table; a file here that no entry names is linked nowhere. Don't use `stow`: home-manager places every link, and a stowed one collides with it.
- herdr plugins are registered by `~/nixos/main/homes/modules/herdr-plugins.nix`, whose sync writes `plugins.json` at rebuild: a plugin kept here (`herdr/plugins/<name>/`) goes in its `localPlugins` list and stays editable without a rebuild; a third-party one is packaged under `~/nixos/main/pkgs/`. Use `herdr plugin link` only to try a plugin out: it lives in this machine's `plugins.json` alone.
- The repo is public, and features are shared by linking their **Worth stealing** entry in the package's `README.md`. A commit that adds something reusable adds its entry in the same commit, in the existing entries' format with the anchor, linking only the file, since the commit has no hash yet.
- Before taking a screenshot, read `README.md`'s Screenshots section: it keeps browsing history, bookmarks and sessions out of the image.
- Commit directly to `main`; create a branch only when asked.
- `reference/` holds clones of other people's dotfiles, kept to read for ideas. Gitignored, never linked — don't edit anything under it.

## Agent skills

### Issue tracker

Issues live in the separate private repo **`hefker/dots-issues`**, so every `gh` command
needs `--repo hefker/dots-issues`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
