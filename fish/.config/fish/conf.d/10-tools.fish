# Tools that install themselves by sourcing generated init code.
# Login-only: what they define is inherited by child shells, so paying for the
# subprocess spawn once per login is enough.

if status is-login
    zoxide init fish | source
    starship init fish | source
    atuin init fish | source
    command -q direnv && direnv hook fish | source # possible to do with fish, revisit
    command -q nix-your-shell && nix-your-shell fish | source
end
