# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
alias c='clear'
alias mv='mv -i' # Ask before overwriting
#alias man='batman'
alias k='killall'
alias rm='rm -Iv' # Ask when deleting more than 3 files, verbose

alias p='python'
alias py='python'
alias wifi='impala'
alias taskman='btop'
alias bt='bluetui'
alias bluetooth='bluetui'

. "$HOME/.local/share/../bin/env"
