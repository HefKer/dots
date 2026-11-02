# Environment and shell mode.

if status is-interactive
    set -g fish_greeting ''
    set -g fish_key_bindings fish_vi_key_bindings
    set -g fish_transient_prompt 1
end

set -gx MANPAGER 'bat -l man -p'
fish_add_path /home/hefker/.lmstudio/bin
