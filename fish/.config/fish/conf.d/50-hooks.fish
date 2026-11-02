# Event handlers. These must be defined eagerly — fish does not autoload a
# function just because its event fires, so they cannot live in functions/.

status is-interactive || exit 0

function __auto_ls --on-variable PWD
    ls
end

# The blank line between a command's output and the next prompt. Starship's
# add_newline would put it at the top of every prompt, pushing the first one
# down a line, and the transient prompt would draw over it. Skipped after
# `clear` so the prompt lands on the top line there too.
function __prompt_gap --on-event fish_postexec
    string match -qr '^\s*clear\s*$' -- $argv[1]; or echo
end
