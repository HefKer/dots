import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Modules.Plugins

// The attention queue's side of DMS: new Discord and phone notifications go to `attention ingest`,
// and `dms ipc call attention invoke <id>` runs a notification's action, which only the server can.
PluginComponent {
    id: root

    property var seen: ({})
    property bool primed: false

    function isSource(w) {
        const app = (w.appName || "").toLowerCase();
        return app === "vesktop" || w.desktopEntry === "vesktop" || w.desktopEntry === "org.kde.kdeconnect.daemon" || w.appName === "KDE Connect";
    }

    function wrapperFor(id) {
        return NotificationService.notifications.find(w => w && w.notification && String(w.notification.id) === String(id));
    }

    Component {
        id: ingestProc

        Process {
            property string payload
            command: ["sh", "-c", 'printf %s "$1" | attention ingest', "ingest", payload]
            onExited: destroy()
        }
    }

    // The service appends to a plain array, which emits no change, so new notifications are polled.
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const next = {};
            for (const w of NotificationService.notifications) {
                if (!w || !w.notification)
                    continue;
                const id = String(w.notification.id);
                next[id] = true;
                if (!root.primed || root.seen[id] || !root.isSource(w))
                    continue;
                ingestProc.createObject(root, {
                    "payload": JSON.stringify({
                        "id": w.notification.id,
                        "appName": w.appName,
                        "desktopEntry": w.desktopEntry,
                        "summary": w.summary,
                        "body": w.body
                    })
                }).running = true;
            }
            // Notifications present when the shell started were there before; they aren't new.
            root.seen = next;
            root.primed = true;
        }
    }

    IpcHandler {
        target: "attention"

        function invoke(id: string): string {
            const w = root.wrapperFor(id);
            if (!w)
                return "GONE";
            const actions = w.actions || [];
            const action = actions.find(a => a.identifier === "default") || actions[0];
            if (!action || !action.invoke)
                return "NO_ACTION";
            action.invoke();
            NotificationService.dismissNotification(w);
            return "INVOKED";
        }
    }
}
