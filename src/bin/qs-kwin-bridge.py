#!/usr/bin/env python3
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import os

STATE_FILE = '/tmp/qs_kwin_windows.json'

class QSKWinBridge(dbus.service.Object):
    def __init__(self, bus, path_name):
        super().__init__(bus, path_name)
        self.windows_json = "[]"
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, 'r') as f:
                    self.windows_json = f.read().strip() or "[]"
            except:
                pass
        print(self.windows_json, flush=True)

    @dbus.service.method("org.kde.qs.bridge", in_signature='s', out_signature='')
    def updateWindows(self, win_json):
        print(f"DEBUG: Received update: {win_json}", flush=True)
        self.windows_json = win_json
        try:
            with open(STATE_FILE, 'w') as f:
                f.write(win_json)
        except:
            pass
        print(win_json, flush=True)

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
session_bus = dbus.SessionBus()
name = dbus.service.BusName("org.kde.qs", session_bus)
bridge = QSKWinBridge(session_bus, '/bridge')
loop = GLib.MainLoop()
loop.run()
