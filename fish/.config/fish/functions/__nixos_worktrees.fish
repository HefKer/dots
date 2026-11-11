# Names of the nixos repo's worktrees that sit directly under ~/nixos/,
# read from git so a new worktree needs no config edit. Skips the bare repo
# and worktrees elsewhere (scratch checkouts under /tmp).
function __nixos_worktrees
    set -l root ~/nixos
    git -C $root/.bare worktree list --porcelain 2>/dev/null \
        | string replace -rf '^worktree '(string escape --style=regex -- $root)'/([^/]+)$' '$1' \
        | string match -v .bare
end
