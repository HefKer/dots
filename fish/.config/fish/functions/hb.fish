function hb --description 'review a branch against main in hunk'
    # main...BRANCH diffs from the merge-base, so only the branch's own commits
    # show, not what main gained since. Uncommitted work in the branch's
    # worktree is left out; for that, run `hunk diff (git merge-base main HEAD)`
    # inside it. With no argument, pick a branch, most recently committed first.
    set -l branch $argv[1]
    if test -z "$branch"
        set branch (git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads \
            | string match -v main \
            | fzf --height 40% --reverse --prompt 'review> ' \
                --preview 'git log --oneline --color main..{}')
        or return
    end
    hunk diff main...$branch
end
