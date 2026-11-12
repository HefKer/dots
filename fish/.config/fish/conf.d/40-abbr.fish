# Abbreviations, grouped by what they drive.

status is-interactive || exit 0

# Navigation
function __abbr_cd_up --description "One ../ per q typed"
    echo cd (string repeat -n (string length $argv[1]) ../ | string trim -r -c /)
end
abbr -a cd_up --regex '^q+$' --function __abbr_cd_up

# Listing
abbr -a lsa 'ls -a'
abbr -a lta 'lt -a'
abbr -a lsd 'ls -s date'

# Core utils
abbr -a c 'clear ; ls'
abbr -a cl clear
abbr -a mv "mv -iv" # Ask before overwriting
abbr -a cp "cp -iv"
abbr -a cpr 'rsync -ah --progress'
abbr -a mvr 'rsync -ah --progress --remove-source-files'
abbr -a mkdir 'mkdir -pv'
abbr -a du 'du -sh'

# git
abbr -a lg lazygit
abbr -a g git
abbr -a gs git status
abbr -a ga git add
abbr -a gcm --set-cursor 'git commit -m "%"'
abbr -a gcam --set-cursor 'git commit -am "%"'
abbr -a gp git push
abbr -a glo git log --oneline --decorate --graph --all

# claude-code
abbr -a C claude
abbr -a CC claude -r
abbr -a CO 'claude --model opus'
abbr -a CS 'claude --model sonnet'
abbr -a CF 'claude --model fable'
abbr -a CH claude-hulio
abbr -a CHC claude-hulio -r
abbr -a CHO 'claude-hulio --model opus'
abbr -a CHS 'claude-hulio --model sonnet'
abbr -a CHF 'claude-hulio --model fable'

# CLI programs
abbr -a n nvim
abbr -a calc kalker
abbr -a ff fastfetch
# za: add a dir to zoxide or boost its rank (the boost fades with frecency)
abbr -a za --set-cursor 'zoxide add -s % .'
abbr -a ze zoxide edit
abbr -a st syncthing
abbr -a H herdr
abbr -a HH herdr --session
abbr -a HSL herdr session list
# HRS attaches to the other machine's herdr: desktop <-> lenovo
if test (prompt_hostname) = desktop
    abbr -a HRS herdr --remote lenovo --session
else
    abbr -a HRS herdr --remote desktop --session
end
abbr -a Y y
abbr -a cdi zi
abbr -a py python
abbr -a ur uv run
abbr -a wifi impala
abbr -a taskman btop
abbr -a bt bluetui
abbr -a bluetooth bluetui
abbr -a vol wiremix

# Search
abbr -a rg 'rg -i'
abbr -a ns 'nix search nixpkgs'

# nix
abbr -a nsp nix shell
abbr -a nfu nix flake update
abbr -a nu nixup --all

# Anywhere on the line
abbr -a G --position anywhere '| rg -i'
abbr -a CP --position anywhere '| wl-copy'

# Last command, ready to edit
function __abbr_last_command
    echo $history[1]
end
abbr -a last_command --regex '^!!$' --function __abbr_last_command

# A bare filename opens it in the program that owns its type
function __abbr_edit_file
    echo nvim $argv[1]
end
function __abbr_open_file
    echo open $argv[1]
end
function __abbr_run_python
    echo python $argv[1]
end
abbr -a edit_file --regex '^[^/ ]+\.(nix|md|fish|json|txt)$' --function __abbr_edit_file
abbr -a open_file --regex '^[^/ ]+\.(pdf|docx|xlsx|html)$' --function __abbr_open_file
abbr -a run_python --regex '^[^/ ]+\.py$' --function __abbr_run_python
