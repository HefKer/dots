# Alt+T: the tldr page for the command being typed, printed under the prompt the
# way Alt+W prints its summary; the command line is left as it was.
function __tldr_current_command --description 'Show the tldr page for the command being typed'
    set -l tokens (commandline -xp)
    # The page is the wrapped command's, not sudo's.
    while set -q tokens[1]; and contains -- $tokens[1] sudo doas run0 env command builtin exec time nice
        set -e tokens[1]
    end
    set -q tokens[1]; or return
    set -l cmd $tokens[1]

    # A subcommand's own page first (git commit), then the command's.
    set -l page $cmd
    if set -q tokens[2]; and not string match -q -- '-*' $tokens[2]
        and tldr --quiet --list 2>/dev/null | string match -q -- "$cmd-$tokens[2]"
        set page $cmd $tokens[2]
    end

    if command -q tldr; and tldr --quiet $cmd >/dev/null 2>&1
        __fish_echo tldr --quiet $page
    else
        # No page: the whatis line Alt+W would print, and where to go next.
        set -l desc (whatis $cmd 2>/dev/null)[1]
        test -n "$desc"; or set desc "$cmd: no tldr page"
        __fish_echo printf '%s\n%s\n' $desc 'Alt+H opens the man page.'
    end
end
