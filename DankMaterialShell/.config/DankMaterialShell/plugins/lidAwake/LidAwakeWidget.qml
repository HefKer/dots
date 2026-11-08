import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

// Holds a logind inhibitor (lid switch, sleep, idle) in the transient user unit lid-awake while on,
// so shutting the lid doesn't suspend; niri still turns the panel off when the lid closes.
PluginComponent {
    id: root

    property bool awake: false

    // Laptops only: the desktop shares this settings.json but has no battery.
    visibilityCommand: "ls /sys/class/power_supply/ | grep -q '^BAT'"

    readonly property string icon: awake ? "coffee" : "laptop"
    readonly property color tint: awake ? Theme.primary : Theme.surfaceVariantText

    pillClickAction: () => toggleProc.running = true

    Process {
        id: stateProc
        command: ["systemctl", "--user", "is-active", "-q", "lid-awake"]
        onExited: exitCode => root.awake = exitCode === 0
    }

    Process {
        id: toggleProc
        command: ["sh", "-c", `
            if systemctl --user is-active -q lid-awake; then
                systemctl --user stop lid-awake && notify-send -a DMS -i computer "Lid awake off" "Shutting the lid suspends again"
            else
                systemd-run --user --unit=lid-awake --collect systemd-inhibit --what=handle-lid-switch:sleep:idle --who=lid-awake --why="Stay reachable with the lid shut" sleep infinity \\
                    && notify-send -a DMS -i computer "Lid awake on" "Shutting the lid keeps the laptop on"
            fi`]
        onExited: stateProc.running = true
    }

    Timer {
        interval: 5000
        running: root.effectiveVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: stateProc.running = true
    }

    horizontalBarPill: Component {
        DIcon {
            name: root.icon
            color: root.tint
            size: root.iconSize
        }
    }

    verticalBarPill: Component {
        DIcon {
            name: root.icon
            color: root.tint
            size: root.iconSize
        }
    }
}
