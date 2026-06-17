#!/usr/bin/env python3
import os, sys, json, subprocess

STATE_FILE = '/tmp/qs_kwin_windows.json'
windows_json = "[]"

if os.path.exists(STATE_FILE):
    try:
        with open(STATE_FILE, 'r') as f:
            windows_json = f.read().strip() or "[]"
    except:
        pass

# Emit initial state so overview gets windows immediately
print(windows_json, flush=True)

# Start tailing journalctl for KWin logs
proc = subprocess.Popen(
    ["stdbuf", "-oL", "journalctl", "--user", "-u", "plasma-kwin_wayland", "-f", "-n", "0"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

for line in iter(proc.stdout.readline, ''):
    if "QS_WINDOWS:" in line:
        try:
            # Extract the JSON payload after "QS_WINDOWS:"
            win_json = line.split("QS_WINDOWS:")[1].strip()
            
            # Validate JSON
            parsed = json.loads(win_json)
            
            windows_json = win_json
            
            try:
                with open(STATE_FILE, 'w') as f:
                    f.write(windows_json)
            except:
                pass
            
            # Emit to Quickshell
            print(windows_json, flush=True)
        except Exception as e:
            pass
