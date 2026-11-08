# The secrets dir the line being completed points at: -w's worktree, else main.
function __secret_dir
    set -l tokens (commandline -xpc)
    set -l tree main
    for i in (seq 2 (count $tokens))
        switch $tokens[$i]
            case -w --worktree
                set -q tokens[(math $i + 1)]; and set tree $tokens[(math $i + 1)]
            case '--worktree=*'
                set tree (string replace -- --worktree= '' $tokens[$i])
        end
    end
    string match -q '*/*' -- $tree; or set tree ~/nixos/$tree
    echo $tree/secrets
end

# positional args, flags and their values dropped
function __secret_args
    set -l tokens (commandline -xpc)[2..]
    set -l out
    while set -q tokens[1]
        switch $tokens[1]
            case -w --worktree
                set -e tokens[1]
            case '-*'
            case '*'
                set -a out $tokens[1]
        end
        set -e tokens[1]
    end
    string join \n -- $out
end

complete -c secret -f
complete -c secret -s h -l help -d Usage
complete -c secret -s w -l worktree -x -d 'nixos worktree' \
    -a '(path basename (path dirname ~/nixos/*/secrets))'
complete -c secret -n 'test (count (__secret_args)) -eq 0' \
    -a '(path basename -E (__secret_dir)/*.yaml)'
complete -c secret -n 'test (count (__secret_args)) -eq 1' \
    -a '(yq -r "del(.sops) | keys | .[]" (__secret_dir)/(__secret_args)[1].yaml 2>/dev/null)'
