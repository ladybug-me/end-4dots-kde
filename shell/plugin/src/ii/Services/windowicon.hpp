// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

namespace caelestia::services {

/**
 * Extracts an application icon from a window's own _NET_WM_ICON property.
 *
 * Games launched through a launcher (Minecraft via Prism, many Steam titles)
 * have no resolvable desktop entry and no themed icon under the class KWin
 * reports, so the dock has nothing to draw. Their icon only exists as a pixmap
 * on the window itself.
 *
 * Reads the property directly with XGetWindowProperty and caches the largest
 * image it finds as a PNG, rather than shelling out to a helper per window
 * class. Only XWayland clients can be served: _NET_WM_ICON is an X property, so
 * a native Wayland app with no desktop entry is not covered.
 */
class WindowIcon : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit WindowIcon(QObject* parent = nullptr);

    /**
     * Extract the icon for a window, caching it under ~/.cache/caelestia/winicons.
     *
     * @p pid is the strongest identifier and is tried first against
     * _NET_WM_PID: the window class is not unique for the very windows this
     * exists to serve — every Proton title Steam cannot map to an appid is
     * reported as "steam_app_default" — so matching on class alone hands one
     * game's icon to the next. @p wmClass and @p title are only consulted when
     * no window carries the pid (native Wayland clients, or a launcher that
     * never set the property).
     *
     * Cache files are named after the icon's own content hash, so a class that
     * covers several games can never resolve to a previously cached stranger.
     *
     * Returns an empty string when no window matches or it carries no icon;
     * extracted() is emitted on success, keyed the same way as the return.
     */
    Q_INVOKABLE QString extract(const QString& wmClass, const QString& title = QString(), qint64 pid = 0);

signals:
    /// @p key is the pid as a string when one was given, else the window class.
    void extracted(const QString& key, const QString& path);
};

} // namespace caelestia::services
