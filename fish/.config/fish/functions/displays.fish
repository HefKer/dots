function displays --description "List Wayland outputs with scale + only preferred/current modes (for picking a mirror target)"
    # wlr-randr's plain output dumps every mode a monitor advertises (dozens of
    # resolution/refresh combos), which is unusable for a quick "which display?"
    # glance. --json gives structured data; jq keeps only the modes flagged
    # `current` or `preferred` so each output is a couple of lines.
    if not command -q wlr-randr
        echo "displays: wlr-randr not found (need a wlroots compositor: niri/sway/…)"
        return 1
    end

    wlr-randr --json | jq -r '
        .[]
        | "\(.name)  \(.physical_size.width)x\(.physical_size.height)mm  scale=\(.scale)  enabled=\(.enabled)",
          ( .modes[]
            | select(.current or .preferred)
            # tag each kept mode so you can tell preferred from current at a glance
            | "    \(.width)x\(.height)@\(.refresh | round)Hz"
              + (if .current then "  [current]" else "" end)
              + (if .preferred then "  [preferred]" else "" end)
          )
    '
end
