# Aliases: only for things that need to stay expanded (a wrapper with flags
# baked in). Anything meant to be edited before running belongs in 40-abbr.

status is-interactive || exit 0

alias ls='eza -lh --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --long --icons --git'
alias groot=sudo
alias clanker=claude
