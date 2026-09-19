# Configuration lives in conf.d/, which fish sources automatically in filename
# order before this file. Each file there carries its own status guard.
#
#   00-env     exported vars, PATH, key binding mode
#   10-tools   zoxide / starship / atuin / direnv / nix-your-shell  (login only)
#   20-fzf     fzf defaults, key bindings and the $HOME-wide widgets
#   30-alias   aliases
#   40-abbr    abbreviations
#   50-hooks   event handlers, which must be defined eagerly
#
# Standalone commands are autoloaded from functions/, one per file.
# Add to the file that owns the topic rather than appending here.
