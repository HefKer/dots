function claude --description 'claude-code, behind the ~/.claude.json launch guard'
    # ~/.claude.json is one global file that every session rewrites via
    # truncate-then-write, so a batch of simultaneous launches (herdr restoring
    # panes) can leave it empty -- losing project permissions, trust, and MCP
    # config. The guard validates it, restores from the newest good backup if it
    # was wiped, scrubs the email out of the welcome-box org name, and serialises
    # all of that under a lock. It runs before the CLI reads the file, which is
    # the only point where no session is holding it.
    #
    # It always exits 0; a failing guard can log but must never block a launch.
    bash "$HOME/.claude/bin/claude-config-guard.sh"

    # Lets herdr's prefix+a pull the unsent prompt out; plain Ctrl+G still opens $EDITOR.
    set -lx VISUAL $HOME/dots/scripts/claude-prompt-editor

    command claude $argv
end
