# Tools that install themselves by sourcing generated init code.
# Interactive, not login: they define functions and bindings, which child shells
# don't inherit, and herdr panes are non-login. NixOS loads zoxide, starship and
# direnv from /etc/fish/config.fish, so only what it doesn't cover goes here.

status is-interactive || exit 0

atuin init fish | source
