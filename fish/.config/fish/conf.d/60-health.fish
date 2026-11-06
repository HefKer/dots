# One line when health probes have open findings; reads the status file, runs nothing.

status is-interactive || exit 0
type -q health; and health --greeting
