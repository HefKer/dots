function starship_transient_prompt_func --description "Collapsed prompt for scrollback: the directory and the prompt character"
    starship module directory $argv
    starship module character $argv
end
