# Environment and shell mode.

if status is-login
    set -gx MANPAGER 'bat -l man -p'
end

if status is-interactive
    set -g fish_greeting ''
    set -g fish_key_bindings fish_vi_key_bindings
end

fish_add_path /home/hefker/.lmstudio/bin
