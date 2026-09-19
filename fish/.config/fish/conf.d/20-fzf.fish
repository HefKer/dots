# fzf: defaults, the keys fzf binds itself, and the $HOME-wide variants.

status is-interactive || exit 0

set -gx FZF_DEFAULT_COMMAND 'fd --type f --follow' # --hidden 
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type d --follow'
set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --icons {}'"
fzf --fish | source

# Use Ctrl+F for files instead of Ctrl+T
bind \cf fzf-file-widget
bind -M insert \cf fzf-file-widget
bind --erase \ct
bind -M insert --erase \ct
# Use Ctrl+G for dirs instead of Alt+C
bind \cg fzf-cd-widget
bind -M insert \cg fzf-cd-widget
bind --erase \ec
bind -M insert --erase \ec

# Alt+F / Alt+G: search files / dirs from $HOME
function __fzf_file_home
    set -l file (fd --type f --follow . $HOME | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
    if test -n "$file"
        commandline -i -- (string escape -- $file)
    end
    commandline -f repaint
end
function __fzf_cd_home
    set -l dir (fd --type d --follow . $HOME | fzf --preview 'eza --tree --level=2 --icons {}')
    if test -n "$dir"
        cd $dir
    end
    commandline -f repaint
end
bind \ef __fzf_file_home
bind -M insert \ef __fzf_file_home
bind \eg __fzf_cd_home
bind -M insert \eg __fzf_cd_home

# Alt+Y: yank dir path from $HOME to clipboard
function __fzf_yank_dir_home
    set -l dir (fd --type d --follow . $HOME | fzf --preview 'eza --tree --level=2 --icons {}')
    if test -n "$dir"
        echo -n $dir | wl-copy
    end
    commandline -f repaint
end
bind \ey __fzf_yank_dir_home
bind -M insert \ey __fzf_yank_dir_home
