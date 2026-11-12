import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

// The attention queue's depth; clicking goes to the top item, as Mod+Shift+N does.
PluginComponent {
    id: root

    property var queue: []
    readonly property int depth: queue.length
    readonly property color tint: depth > 0 ? Theme.primary : Theme.surfaceVariantText

    pillClickAction: () => nextProc.running = true

    Process {
        id: listProc
        command: ["attention", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.queue = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: nextProc
        command: ["attention", "next"]
        onExited: listProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!listProc.running) listProc.running = true
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                name: root.depth > 0 ? "notification_important" : "done_all"
                color: root.tint
                size: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.depth > 0
                text: root.depth
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DIcon {
                name: root.depth > 0 ? "notification_important" : "done_all"
                color: root.tint
                size: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.depth > 0
                text: root.depth
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
