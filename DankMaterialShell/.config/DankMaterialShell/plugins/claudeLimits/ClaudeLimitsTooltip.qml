import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

// DMS's DTooltip with room for more than one line: an overlay that takes no input, its top
// edge at targetY and centred on targetX, kept on screen.
PanelWindow {
    id: tip

    property string text: ""
    property real targetX: 0
    property real targetY: 0

    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "dms:tooltip"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    anchors {
        top: true
        left: true
    }
    implicitWidth: tipText.implicitWidth + Theme.spacingM * 2
    implicitHeight: tipText.implicitHeight + Theme.spacingS * 2
    margins {
        left: Math.round(Math.max(Theme.spacingS, Math.min((screen?.width ?? 0) - implicitWidth - Theme.spacingS, targetX - implicitWidth / 2)))
        top: Math.round(Math.max(Theme.spacingS, Math.min((screen?.height ?? 0) - implicitHeight - Theme.spacingS, targetY)))
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.tooltipSurface
        radius: Theme.cornerRadiusXS

        StyledText {
            id: tipText
            anchors.centerIn: parent
            text: tip.text
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.tooltipText
        }
    }
}
