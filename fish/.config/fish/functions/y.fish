function y --description "yazi, then cd to the directory it was in when it quit (Q quits without)"
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    command yazi $argv --cwd-file=$tmp
    # builtin and command skip the cd and rm wrappers in this directory.
    if read -z cwd <$tmp; and test "$cwd" != "$PWD"; and test -d "$cwd"
        builtin cd -- $cwd
    end
    command rm -f -- $tmp
end
