# Abbreviations, grouped by what they drive.

status is-interactive || exit 0

# Navigation
abbr -a q 'cd ..'
abbr -a qq 'cd ../..'
abbr -a qqq 'cd ../../..'

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
abbr -a CH 'claude --model haiku'

# CLI programs
abbr -a n nvim
abbr -a calc kalker
abbr -a ff fastfetch
abbr -a st syncthing
abbr -a H herdr
abbr -a HH herdr --session
abbr -a Y yazi
abbr -a cdi zi
abbr -a py python
abbr -a wifi impala
abbr -a taskman btop
abbr -a bt bluetui
abbr -a bluetooth bluetui

# Search
abbr -a rg 'rg -i'
abbr -a ns 'nix search nixpkgs'
