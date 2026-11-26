function nixfind --description "Fuzzy-search nixpkgs, NixOS and Home Manager options; print the pick"
    # nix-search-tv's own fzf line (README). Entries read "nixpkgs/ ripgrep";
    # the source prefix is dropped so the name works in a command substitution.
    set -l pick (nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --query "$argv")
    or return
    string replace -r '^[^/]+/ ' '' -- $pick
end
