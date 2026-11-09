import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

// Default source's mute state, live from PipeWire through AudioService; click toggles it.
PluginComponent {
    id: root

    readonly property bool muted: AudioService.source?.audio?.muted ?? true
    readonly property string icon: muted ? "mic_off" : "mic"
    readonly property color tint: muted ? Theme.error : Theme.primary

    pillClickAction: () => AudioService.toggleMicMute()

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
