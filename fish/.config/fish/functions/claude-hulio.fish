function claude-hulio --wraps claude --description 'claude under the hulio account, for directories without its .envrc'
    CLAUDE_CONFIG_DIR=$HOME/.claude-hulio claude $argv
end
