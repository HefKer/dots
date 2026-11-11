# Shared body of nrs/nrb: nixos-rebuild <action> from a ~/nixos worktree.
# Usage: __nixos_rebuild <switch|boot> [worktree[#host]] [nixos-rebuild args...]
# With no worktree, builds the one $PWD is in, else main.
function __nixos_rebuild
    set -l action $argv[1]
    set -e argv[1]
    set -l root ~/nixos
    set -l names (__nixos_worktrees)

    set -l target
    if set -q argv[1]; and not string match -q -- '-*' $argv[1]
        set target $argv[1]
        set -e argv[1]
    else
        set -l here (string replace -rf '^'(string escape --style=regex -- $root)'/([^/]+)(/.*)?$' '$1' -- $PWD)
        if test -n "$here"; and contains -- $here $names
            set target $here
        else
            set target main
        end
    end

    # nixos-rebuild picks the flake's attribute from the hostname; #host targets another.
    set -l parts (string split -m1 '#' -- $target)
    if not contains -- $parts[1] $names
        echo "nr: unknown worktree '$parts[1]'; valid: "(string join ', ' $names) >&2
        return 1
    end
    set -l flake $root/$target

    set -l cmd sudo nixos-rebuild $action --flake $flake $argv
    echo (set_color --bold)(string escape -- $cmd | string join ' ')(set_color normal) >&2
    $cmd
end
