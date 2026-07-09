function claude --description 'claude-code, with email scrubbed from the welcome-box org name'
    # The server re-pushes "email's Organization" into ~/.claude.json on every
    # OAuth token refresh, so a one-time edit reverts. Scrub it on every launch,
    # before the CLI reads the file to render the greeting.
    set -l cfg ~/.claude.json
    if test -f $cfg; and jq -e '.oauthAccount.organizationName // "" | test("@")' $cfg >/dev/null 2>&1
        jq '.oauthAccount.organizationName = "Personal"' $cfg >$cfg.scrub
        and mv $cfg.scrub $cfg
    end
    command claude $argv
end
