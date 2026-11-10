import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

// Reads and changes alarms only through the alarm command, so the bar, Mod+A and agents share one store.
PluginComponent {
    id: root

    property var alarms: []
    property real now: Date.now() / 1000
    property string error: ""
    property int tick: 0
    readonly property var next: alarms.length > 0 ? alarms[0] : null

    popoutWidth: 380
    popoutHeight: 190 + Math.min(alarms.length, 6) * 44

    function remaining(at) {
        const s = Math.max(0, Math.round(at - root.now));
        if (s < 3600)
            return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
        return Math.floor(s / 3600) + "h" + String(Math.floor((s % 3600) / 60)).padStart(2, "0");
    }

    function clock(at) {
        return Qt.formatTime(new Date(at * 1000), "HH:mm");
    }

    function run(args) {
        root.error = "";
        actProc.command = ["alarm"].concat(args);
        actProc.running = true;
    }

    Process {
        id: listProc
        command: ["alarm", "ls", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.alarms = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: actProc
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim().replace(/^alarm: /, "")
        }
        onExited: listProc.running = true
    }

    // The countdown ticks every second; the list is re-read every 5, which picks up the other host's changes.
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now() / 1000;
            if (root.tick++ % 5 === 0 && !listProc.running)
                listProc.running = true;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                name: "alarm"
                color: root.next ? Theme.primary : Theme.surfaceText
                size: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.next !== null
                text: root.next ? root.remaining(root.next.at) : ""
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
                name: "alarm"
                color: root.next ? Theme.primary : Theme.surfaceText
                size: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.next !== null
                text: root.next ? root.remaining(root.next.at) : ""
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Alarms"
            detailsText: root.next ? `Next: ${root.next.label} at ${root.clock(root.next.at)}` : "Nothing pending"

            ColumnLayout {
                width: parent.width
                spacing: Theme.spacingM

                DTextField {
                    id: field
                    Layout.fillWidth: true
                    placeholderText: "10m tea · 7:30 standup · tomorrow 8am"
                    leftIconName: "alarm_add"
                    isError: root.error !== ""
                    supportingText: root.error
                    onAccepted: {
                        const words = field.text.trim().split(/\s+/).filter(w => w !== "");
                        if (words.length > 0)
                            root.run(["add"].concat(words));
                        field.text = "";
                    }
                }

                RowLayout {
                    spacing: Theme.spacingS

                    Repeater {
                        model: ["5m", "10m", "25m", "1h"]

                        DButton {
                            required property string modelData
                            text: modelData
                            variant: "tonal"
                            onClicked: root.run(["add", modelData])
                        }
                    }
                }

                Repeater {
                    model: root.alarms

                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Theme.spacingS

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: `${root.clock(modelData.at)} · ${root.remaining(modelData.at)}`
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        DIconButton {
                            iconName: "snooze"
                            tooltipText: "Snooze 5 min"
                            onClicked: root.run(["snooze", modelData.id])
                        }

                        DIconButton {
                            iconName: "close"
                            tooltipText: "Cancel"
                            onClicked: root.run(["rm", modelData.id])
                        }
                    }
                }
            }
        }
    }
}
