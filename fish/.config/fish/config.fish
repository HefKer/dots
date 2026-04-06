# Login shell - Environment setup and one-time initializations
if status is-login
    # Tool initializations
    zoxide init fish | source
    starship init fish | source
    fzf --fish | source
end

# Interactive shell - Shell behavior and user interface
if status is-interactive
    set -g fish_greeting ''

    # Aliases
    alias cat="bat"
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --long --icons --git'

    # Abbreviations
    #
    abbr -a q 'cd ..'
    abbr -a qq 'cd ../..'
    abbr -a qqq 'cd ../../..'

    abbr -a lsa 'ls -a'
    abbr -a lta 'lt -a'

    abbr -a c clear
    abbr -a mv "mv -i" # Ask before overwriting

    abbr -a n nvim
    abbr -a lg lazygit
    abbr -a g git
    abbr -a gs git status
    abbr -a gc git commit -m
    abbr -a gcm git commit -m
    abbr -a gcam git commit -am

    abbr -a p python
    abbr -a py python
    abbr -a wifi impala
    abbr -a taskman btop
    abbr -a bt bluetui
    abbr -a bluetooth bluetui

    # Vim keybinds
    set -g fish_key_bindings fish_vi_key_bindings

    # Interactive functions
    function __auto_ls --on-variable PWD
        ls
    end

    function cd
        z $argv
    end

    function rm
        command rm -Iv $argv # Ask when deleting more than 3 files, verbose
    end

    function fzf
        nvim $(command fzf --preview "bat --style=numbers --color=always --line-range :500 {}")
    end
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/hefker/.lmstudio/bin
