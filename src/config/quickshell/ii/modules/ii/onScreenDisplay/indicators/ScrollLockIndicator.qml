import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

KeyboardLockIndicator {
    lockName: Translation.tr("Scroll Lock")
    icon: "swap_vert"
    enabled: KeyboardLocks.scrollLock
}
