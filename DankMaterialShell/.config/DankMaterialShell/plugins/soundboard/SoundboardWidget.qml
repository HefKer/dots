import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

// Reads and writes the volumes through sound-volume, the same file sound-pick reads on every pick.
PluginComponent {
    id: root

    property int callVolume: 20
    property int youVolume: 20

    popoutWidth: 320
    popoutHeight: 200

    function save() {
        saveProc.command = ["sound-volume", String(root.callVolume), String(root.youVolume)];
        saveProc.running = true;
    }

    // sound-volume prints "call 20%, you 20%".
    Process {
        id: readProc
        command: ["sound-volume"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/call (\d+)%, you (\d+)%/);
                if (m) {
                    root.callVolume = parseInt(m[1]);
                    root.youVolume = parseInt(m[2]);
                }
            }
        }
    }

    Process {
        id: saveProc
    }

    Process {
        id: stopProc
        command: ["sound-stop"]
    }

    Component.onCompleted: readProc.running = true

    horizontalBarPill: Component {
        DIcon {
            name: "campaign"
            color: Theme.surfaceText
            size: root.iconSize
        }
    }

    verticalBarPill: Component {
        DIcon {
            name: "campaign"
            color: Theme.surfaceText
            size: root.iconSize
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Soundboard"
            detailsText: "Volume of sound-pick's clips"

            ColumnLayout {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: "In the call"
                    color: Theme.surfaceText
                }
                DSlider {
                    Layout.fillWidth: true
                    minimum: 0
                    maximum: 100
                    value: root.callVolume
                    unit: "%"
                    startIcon: "campaign"
                    onSliderValueChanged: v => root.callVolume = v
                    onSliderDragFinished: root.save()
                }

                StyledText {
                    text: "For you"
                    color: Theme.surfaceText
                }
                DSlider {
                    Layout.fillWidth: true
                    minimum: 0
                    maximum: 100
                    value: root.youVolume
                    unit: "%"
                    startIcon: "headphones"
                    onSliderValueChanged: v => root.youVolume = v
                    onSliderDragFinished: root.save()
                }

                DButton {
                    text: "Stop playing"
                    iconName: "stop"
                    onClicked: stopProc.running = true
                }
            }
        }
    }
}
