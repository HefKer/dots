function claude --description 'claude-code, behind the launch guard, with the hulio account settings merged'
    # herdr restores a pane by typing `claude --resume <id>` into a fresh shell, with no
    # CLAUDE_CONFIG_DIR; a session filed under ~/.claude-hulio resumes as hulio, not "not found".
    if not set -q CLAUDE_CONFIG_DIR
        set -l id (string replace -rf -- '^--resume=' '' $argv)
        set -l i (contains -i -- --resume $argv; or contains -i -- -r $argv)
        test -n "$i"; and set -q argv[(math $i + 1)]; and set id $argv[(math $i + 1)]
        if test -n "$id"
            set -l hulio $HOME/.claude-hulio/projects/*/$id.jsonl
            set -q hulio[1]; and set -fx CLAUDE_CONFIG_DIR $HOME/.claude-hulio
        end
    end

    # .claude.json is one global file that every session rewrites via
    # truncate-then-write, so a batch of simultaneous launches (herdr restoring
    # panes) can leave it empty -- losing project permissions, trust, and MCP
    # config. The guard validates it, restores from the newest good backup if it
    # was wiped, scrubs the email out of the welcome-box org name, marks $HOME
    # trusted (Claude never saves that itself), and serialises
    # all of that under a lock. It runs before the CLI reads the file, which is
    # the only point where no session is holding it. It inherits
    # CLAUDE_CONFIG_DIR, so it can tell which account's .claude.json to guard.
    #
    # It always exits 0; a failing guard can log but must never block a launch.
    bash "$HOME/.claude/bin/claude-config-guard.sh"

    # The hulio account shares the main account's settings.json, plus its own
    # settings.override.json on top. Claude refuses to write through a symlink,
    # so the merge is a real file, rebuilt every launch: edit the override, not
    # settings.json -- a change Claude saves there (/config, /model) is lost on
    # the next launch. jq's * merges objects deeply but replaces arrays wholesale,
    # so an override touching permissions.allow replaces the whole list. Written
    # to a temp file and moved into place, so a failed merge keeps the last one.
    if test "$CLAUDE_CONFIG_DIR" = $HOME/.claude-hulio
        set -l tmp (mktemp $CLAUDE_CONFIG_DIR/settings.json.XXXXXX)
        if test -n "$tmp"; and jq -s '.[0] * .[1]' $HOME/.claude/settings.json $CLAUDE_CONFIG_DIR/settings.override.json >$tmp
            chmod 644 $tmp
            command mv -f $tmp $CLAUDE_CONFIG_DIR/settings.json
        else
            test -n "$tmp"; and command rm -f $tmp
            echo 'claude: hulio settings merge failed, launching with the previous settings.json' >&2
        end
    end

    # Lets herdr's prefix+a pull the unsent prompt out; plain Ctrl+G still opens $EDITOR.
    set -lx VISUAL $HOME/dots/scripts/claude-prompt-editor

    command claude $argv
end
