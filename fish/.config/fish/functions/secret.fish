function secret --description "Edit or set a sops secret in ~/nixos/<worktree>/secrets"
    argparse -x h,w h/help 'w/worktree=' -- $argv; or return 1
    set -l tree main
    set -q _flag_worktree; and set tree $_flag_worktree
    # a name means a sibling of main (~/nixos/<name>); a path is used as is
    string match -q '*/*' -- $tree; or set tree ~/nixos/$tree
    set -l dir $tree/secrets
    if set -q _flag_help; or test (count $argv) -eq 0; or not test -f $dir/$argv[1].yaml
        echo "Usage: secret [-w worktree] <file> [key]   files in $dir: "(path basename -E $dir/*.yaml | string join ' ')
        echo "  secret shared                 # open in \$EDITOR via sops"
        echo "  secret desktop api-key        # prompt for value (hidden)"
        echo "  secret desktop cert < f       # value from stdin, multiline kept"
        echo "  secret -w proton-torrent ...  # ~/nixos/proton-torrent instead of main"
        return 1
    end
    # the user's age key lives in Bitwarden (~/nixos/main/README.md), fetched per call
    if not set -q SOPS_AGE_KEY; and not set -q SOPS_AGE_KEY_FILE; and not set -q SOPS_AGE_KEY_CMD
        set -fx SOPS_AGE_KEY_CMD "rbw get sops-age-key"
    end
    set -l file $dir/$argv[1].yaml
    set -l idx "[\"$argv[2]\"]"
    if test (count $argv) -eq 1
        sops edit $file
    else if isatty stdin
        read -s -P "$argv[2]: " val; or return 1
        # sops set wants a JSON value; jq -Rs quotes it, --value-stdin keeps it out of ps
        printf %s $val | jq -Rs . | sops set --value-stdin $file $idx
    else
        jq -Rs . | sops set --value-stdin $file $idx
    end
end
