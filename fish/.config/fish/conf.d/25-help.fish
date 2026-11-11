# Help on the command being typed. fish's preset Alt binds already cover it:
# Alt+H man page, Alt+W one-line summary, Alt+E edit in $EDITOR. Alt+T adds the
# tldr page. binds.tsv lists them for bind-palette's fish scope.

status is-interactive || exit 0

bind alt-t __tldr_current_command
bind -M insert alt-t __tldr_current_command
