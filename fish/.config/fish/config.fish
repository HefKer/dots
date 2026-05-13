# Login shell - Environment setup and one-time initializations
if status is-login
    # Tool initializations
    zoxide init fish | source
    starship init fish | source
    fzf --fish | source
    atuin init fish | source
    set -gx MANPAGER 'bat -l man -p'
end

# Interactive shell - Shell behavior and user interface
if status is-interactive
    set -g fish_greeting ''

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
    abbr -a mkdir 'mkdir -pv'

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

    function __extract_yt_id
        set url $argv[1]
        if string match -q "*youtube.com*" $url
            string replace -r '.*[?&]v=([^&]+).*' '$1' $url
        else if string match -q "*youtu.be*" $url
            string replace -r '.*youtu\.be/([^?]+).*' '$1' $url
        else
            echo $url
        end
    end

    function yt_summarize --description "Summarize a YouTube video transcript"
        if test (count $argv) -eq 0
            echo "Usage: yt_summarize <video_id_or_url>"
            return 1
        end

        set video_id (__extract_yt_id $argv[1])

        youtube_transcript_api $video_id --format json \
            | jq -r '.[][].text' \
            | tr '\n' ' ' \
            | claude --model haiku -p "summarize this transcript"
    end

    function yt_chat --description "Chat about a YouTube video transcript in Claude Code"
        if test (count $argv) -eq 0
            echo "Usage: yt_chat <video_id_or_url>"
            return 1
        end

        set video_id (__extract_yt_id $argv[1])

        set tmpfile /tmp/yt_transcript_$video_id.txt

        echo "Fetching transcript for $video_id..."
        youtube_transcript_api $video_id --format json \
            | jq -r '.[][].text' \
            | tr '\n' ' ' >$tmpfile

        if test $status -ne 0 -o ! -s $tmpfile
            echo "Failed to fetch transcript"
            return 1
        end

        claude "I want to discuss a YouTube video (ID: $video_id). The transcript is at $tmpfile — please read it, then let's chat about it."
    end
end

fish_add_path /home/hefker/.lmstudio/bin
