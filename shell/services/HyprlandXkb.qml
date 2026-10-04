pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property list<string> layoutCodes: KbLayout.layouts.map(l => l.token || l.name)
    readonly property string currentLayoutName: KbLayout.activeLabel
    readonly property string currentLayoutCode: KbLayout.activeShortLabel
}
