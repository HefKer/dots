function csend --description 'move a claude session to the other account (main <-> hulio); -r resumes it there'
    # Each account keeps its sessions under its own config dir (~/.claude or
    # ~/.claude-hulio): the transcript at projects/<cwd slug>/<id>.jsonl, plus
    # <id>/ beside it (subagents, tool output) and <id> under file-history/ and
    # session-env/. Nothing server-side ties a session to an account, since every
    # turn resends the conversation, so moving those files is the whole transfer.
    # Moved, not copied, so only one account can go on writing it. The prompt
    # cache doesn't move: the first turn on the new account re-reads the context.
    argparse r/resume -- $argv; or return 2
    if not set -q argv[1]; or set -q argv[3]
        echo 'usage: csend [-r] SESSION_ID [main|hulio]' >&2
        return 2
    end
    set -l id $argv[1]
    set -l dirs main $HOME/.claude hulio $HOME/.claude-hulio

    set -l from
    for i in 1 3
        set -l found $dirs[(math $i + 1)]/projects/*/$id.jsonl
        set -q found[1]; and set -a from $dirs[$i]
    end
    if not set -q from[1]
        # Claude writes no transcript until the first message, so an empty session has
        # nothing to move: with -r and an account, start afresh there instead.
        if set -q _flag_resume; and contains -- "$argv[2]" main hulio
            echo "csend: no transcript for $id (nothing sent yet); starting a new session on $argv[2]" >&2
            if test $argv[2] = hulio
                set -fx CLAUDE_CONFIG_DIR $HOME/.claude-hulio
            else
                set -fu CLAUDE_CONFIG_DIR
            end
            claude
            return
        end
        echo "csend: no session $id in either account" >&2
        return 1
    else if set -q from[2]
        echo "csend: $id is in both accounts; resolve that by hand" >&2
        return 1
    end
    set -l to $argv[2]
    test -n "$to"; or set to (test $from = main; and echo hulio; or echo main)
    if not contains -- $to main hulio
        echo "csend: account must be main or hulio, not $to" >&2
        return 2
    end

    set -l src $dirs[(math (contains -i -- $from $dirs) + 1)]
    set -l dst $dirs[(math (contains -i -- $to $dirs) + 1)]
    set -l transcript $src/projects/*/$id.jsonl
    set -l slug (path basename -- (path dirname -- $transcript[1]))

    if test $from != $to
        # A running session would keep appending to the old copy.
        for f in $src/sessions/*.json
            set -l pid (jq -r --arg id $id 'select(.sessionId == $id) | .pid' $f 2>/dev/null)
            if test -n "$pid"; and kill -0 $pid 2>/dev/null
                echo "csend: $id is still running (pid $pid); exit it first" >&2
                return 1
            end
        end

        command mkdir -p $dst/projects/$slug $dst/file-history $dst/session-env
        for pair in projects/$slug/$id.jsonl projects/$slug/$id file-history/$id session-env/$id
            test -e $src/$pair; or continue
            if test -e $dst/$pair
                echo "csend: $dst/$pair already exists; left $src/$pair in place" >&2
                return 1
            end
            command mv -- $src/$pair $dst/$pair; or return
        end
        command rmdir -- $src/projects/$slug 2>/dev/null
        echo "csend: $id moved $from -> $to"
    end

    set -q _flag_resume; or return 0
    # Resume where it ran: --resume looks the id up under this directory's slug.
    set -l cwd (command grep -hom1 '"cwd":"[^"]*"' $dst/projects/$slug/$id.jsonl | head -1 | string sub -s 8 -e -1)
    test -n "$cwd"; and test -d "$cwd"; and cd $cwd
    # Function scope (-f): -l would end with the if block. Unexported for main, not empty:
    # claude-code reads an empty CLAUDE_CONFIG_DIR as the cwd.
    if test $to = hulio
        set -fx CLAUDE_CONFIG_DIR $HOME/.claude-hulio
    else
        set -fu CLAUDE_CONFIG_DIR
    end
    claude --resume $id
end
