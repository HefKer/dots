function lowpri --description 'Run a command in agents.slice, behind the desktop for CPU and memory'
    systemd-run --user --scope --quiet --collect --slice=agents.slice -- $argv
end
