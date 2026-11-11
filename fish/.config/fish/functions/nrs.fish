function nrs --description "nixos-rebuild switch from a ~/nixos worktree (default: the one \$PWD is in, else main)"
    __nixos_rebuild switch $argv
end
