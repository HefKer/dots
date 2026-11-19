import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// One Claude account's 5-hour and weekly usage, "main 5h 29% · wk 52%", from
// ~/dots/scripts/claude-limits. It follows the account of the Claude last used; a click
// (either button) shows the other account until a Claude is next used. Hover shows the reset
// times and the other account's figures. Hidden until a Claude has rendered its statusline.
PluginComponent {
    id: root

    property var limits: ({ last: null, at: 0, accounts: {} })
    // The account a click switched to, held while no Claude renders after `pinnedAt`.
    property string pinned: ""
    property real pinnedAt: 0

    readonly property var names: Object.keys(limits.accounts)
    readonly property string shown: {
        if (pinned && limits.accounts[pinned])
            return pinned;
        if (limits.last && limits.accounts[limits.last])
            return limits.last;
        return names.length > 0 ? names[0] : "";
    }
    readonly property var current: shown ? limits.accounts[shown] : null
    readonly property string barText: current ? `${shown} ${current.bar.join(" · ")}` : ""
    readonly property string tooltipText: [shown, ...names.filter(n => n !== shown)]
        .filter(n => n)
        .map(n => `${n}\n${limits.accounts[n].detail}`)
        .join("\n\n")

    function switchAccount() {
        const other = names.find(n => n !== shown);
        if (!other)
            return;
        pinned = other;
        // From the click, not the last poll, so a render already behind it can't end the pin.
        pinnedAt = Math.max(limits.at, Date.now() / 1000);
    }

    pillClickAction: () => switchAccount()
    pillRightClickAction: () => switchAccount()

    onBarTextChanged: barText ? clearVisibilityOverride() : setVisibilityOverride(false)
    Component.onCompleted: setVisibilityOverride(false)

    Process {
        id: limitsProc
        command: [Quickshell.env("HOME") + "/dots/scripts/claude-limits"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (root.pinned && d.at > root.pinnedAt)
                        root.pinned = "";
                    root.limits = d;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!limitsProc.running) limitsProc.running = true
    }

    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: ClaudeLimitsTooltip {
            screen: root.parentScreen
            text: root.tooltipText
        }
    }

    function showTooltip(item) {
        tooltipLoader.active = true;
        const tip = tooltipLoader.item;
        if (!tip)
            return;
        const screen = root.parentScreen || Screen;
        const pos = item.mapToItem(null, item.width / 2, item.height / 2);
        const offset = root.barThickness + root.barSpacing + Theme.spacingXS;
        if (root.isVertical) {
            const left = root.axis?.edge === "left";
            tip.targetX = left ? offset + tip.implicitWidth / 2 : screen.width - offset - tip.implicitWidth / 2;
            tip.targetY = pos.y - tip.implicitHeight / 2;
        } else {
            tip.targetX = pos.x;
            tip.targetY = root.axis?.edge === "bottom" ? screen.height - offset - tip.implicitHeight : offset;
        }
    }

    // A HoverHandler, unlike a MouseArea, leaves the pill's clicks alone.
    component Hover: HoverHandler {
        required property Item target
        onHoveredChanged: hovered ? root.showTooltip(target) : tooltipLoader.active = false
    }

    horizontalBarPill: Component {
        StyledText {
            id: label
            text: root.barText
            color: Theme.surfaceText
            font.pixelSize: root.textSize
            Hover {
                target: label
            }
        }
    }

    verticalBarPill: Component {
        Column {
            id: column
            spacing: 0
            Repeater {
                model: root.current ? [root.shown, ...root.current.bar] : []
                StyledText {
                    required property string modelData
                    text: modelData
                    color: Theme.surfaceText
                    font.pixelSize: root.textSize
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            Hover {
                target: column
            }
        }
    }
}
