function nrb --description "nixos-rebuild boot from a ~/nixos worktree (default: the one \$PWD is in, else main)"
    __nixos_rebuild boot $argv
end
