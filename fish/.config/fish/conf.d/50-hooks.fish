# Event handlers. These must be defined eagerly — fish does not autoload a
# function just because its event fires, so they cannot live in functions/.

status is-interactive || exit 0

function __auto_ls --on-variable PWD
    ls
end
