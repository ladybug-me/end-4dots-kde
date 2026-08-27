import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

KeyboardLockIndicator {
    lockName: Translation.tr("Num Lock")
    icon: "dialpad"
    enabled: KeyboardLocks.numLock
}
