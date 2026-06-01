# Login shell - Environment setup and one-time initializations
if status is-login
    # Tool initializations
    zoxide init fish | source
    starship init fish | source
    atuin init fish | source
    command -q direnv && direnv hook fish | source # possible to do with fish, revisit
    command -q nix-your-shell && nix-your-shell fish | source
    set -gx MANPAGER 'bat -l man -p'
end

# Interactive shell - Shell behavior and user interface
if status is-interactive
    set -g fish_greeting ''
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --icons {}'"
    fzf --fish | source
    # Use Ctrl+F for files instead of Ctrl+T
    bind \cf fzf-file-widget
    bind -M insert \cf fzf-file-widget
    bind --erase \ct
    bind -M insert --erase \ct
    # Erase alt+C (finds dirs)
    bind --erase \ec
    bind -M insert --erase \ec

    # --- Shorteners ---

    # - Aliases -
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --long --icons --git'

    # - Abbreviations -
    # Core utils
    abbr -a q 'cd ..'
    abbr -a qq 'cd ../..'
    abbr -a qqq 'cd ../../..'

    abbr -a lsa 'ls -a'
    abbr -a lta 'lt -a'
    abbr -a lsd 'ls -s date'

    abbr -a c 'clear ; ls'
    abbr -a cl clear
    abbr -a mv "mv -iv" # Ask before overwriting
    abbr -a cp "cp -iv"
    abbr -a cpr 'rsync -ah --progress'
    abbr -a mvr 'rsync -ah --progress --remove-source-files'
    abbr -a mkdir 'mkdir -pv'
    abbr -a du 'du -sh'

    # CLI programs
    abbr -a n nvim
    abbr -a lg lazygit
    abbr -a g git
    abbr -a gs git status
    abbr -a ga git add
    abbr -a gc --set-cursor 'git commit -m "%"'
    abbr -a gcam --set-cursor 'git commit -am "%"'
    abbr -a gp git push
    abbr -a calc kalker
    abbr -a ff fastfetch

    abbr -a rg 'rg -i'
    abbr -a ns 'nix search nixpkgs'

    abbr -a cdi zi
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

    function fn
        nvim $(command fzf --preview "bat --style=numbers --color=always --line-range :500 {}")
    end

end

fish_add_path /home/hefker/.lmstudio/bin
