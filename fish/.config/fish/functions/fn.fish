function fn --description "Fuzzy-pick a file under the current directory and open it in nvim"
    nvim $(command fzf --preview "bat --style=numbers --color=always --line-range :500 {}")
end
