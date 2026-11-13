# vi normal mode and the system clipboard: p/P paste it, and every y-family yank
# (yy, Y, y$, yw, y + any motion, visual y) copies to it as well as the kill ring.
# d/c/x stay kill-ring-only, so deleting text never replaces the clipboard.
# Insert mode keeps fish's Ctrl+V.

status is-interactive || exit 0

# The clipboard's text at the cursor. An image or an empty clipboard inserts nothing:
# --type text picks any text type and fails on anything else.
function __clipboard_paste_text
    set -l data (wl-paste --no-newline --type text 2>/dev/null | string collect -N)
    string length -q -- "$data"; or return 0
    commandline -i -- $data
end

bind -M default p 'set -g fish_cursor_end_mode exclusive' forward-char __clipboard_paste_text 'set -g fish_cursor_end_mode inclusive'
bind -M default P __clipboard_paste_text

# fish exposes no read of the kill ring, so a yank is copied by yanking once more,
# reading what that inserted, and undoing it. Each yank bind is fish's preset with
# __yank_clip_mark before it and __yank_clip_copy after. Operator-mode keys finish d
# and c too, so the mark records which operator ran and only yank copies.
#
# `commandline -f` runs at once unless a repaint is queued; then it joins the back of
# the queue, behind __yank_clip_copy, which would read the line before the yank ran.
# So during a yank, a `commandline` function shadows the builtin and drops
# repaint-mode, and __yank_clip_copy repaints once it is done.
function __yank_clip_mark
    if set -q argv[1]
        set -g __yank_clip_op $argv[1]
    else
        set -g __yank_clip_op $__fish_vi_operator
    end
    test "$__yank_clip_op" = yank; or return 0
    function commandline
        set -l args (string match -v -- repaint-mode $argv)
        test "$args" = -f; and return 0
        builtin commandline $args
    end
end

function __yank_clip_copy
    test "$__yank_clip_op" = yank; or return 0
    set -g __yank_clip_op
    functions -e commandline
    set -l len (commandline | string collect -N | string length)
    set -l pos (commandline -C)
    commandline -f begin-undo-group yank end-undo-group
    set -l n (math (commandline | string collect -N | string length) - $len)
    if test $n -gt 0
        set -l text (commandline | string collect -N | string sub -s (math $pos + 1) -l $n | string collect)
        # wl-copy stays running to serve the clipboard; disowned so fish doesn't wait on it.
        printf %s $text | wl-copy 2>/dev/null &
        disown
        commandline -f undo
    end
    commandline -f repaint-mode
end

# fish's `y` with its repaint-mode dropped: `y` waits for a second key (y$, yiw, …),
# which lands in the queue ahead of that repaint and would defer the copy. The cursor
# shape still follows the mode, through fish_vi_cursor's variable handler.
function __yank_clip_start_operator
    set -g __fish_vi_operator yank
    set -g __fish_vi_start_count (__fish_vi_consume_count __fish_vi_count)
    set fish_bind_mode operator
end
bind -M default y __yank_clip_start_operator

# Re-registers one preset bind (eval'd from `bind --preset` output) wrapped as above.
function __yank_clip_rebind
    argparse M= m= preset -- $argv; or return
    set -q _flag_M; or set _flag_M default
    set -l opts -M $_flag_M
    set -q _flag_m; and set -a opts -m $_flag_m
    set -l mark __yank_clip_mark
    contains -- $_flag_M default visual; and set mark '__yank_clip_mark yank'
    bind $opts -- $argv[1] $mark $argv[2..] __yank_clip_copy
end

# The preset binds exist once fish_vi_key_bindings has run, which happens after conf.d.
function __yank_clip_install --on-event fish_prompt
    functions -e __yank_clip_install
    # Operator mode and its f/F/t/T jump modes: every bind that ends an operator.
    set -l lines
    for m in operator f F t T
        set -a lines (bind --preset -M $m | string match '*fish_vi_exec_motion*')
    end
    set -a lines (bind --preset -M default | string match -r '^bind --preset (?:-M default )?(?:Y|y,\S+) .*')
    set -a lines (bind --preset -M visual | string match -r '^bind --preset -M visual -m default y .*')
    for l in $lines
        eval (string replace -- 'bind ' '__yank_clip_rebind ' $l)
    end
end
