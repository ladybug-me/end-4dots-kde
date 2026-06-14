#!/usr/bin/env bash

# Check if spectacle is already recording
if qdbus6 org.kde.Spectacle / org.kde.Spectacle.isRecording | grep -q true; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    qdbus6 org.kde.Spectacle / org.kde.Spectacle.StopRecording
    exit 0
fi

FULLSCREEN_FLAG=0
for ((i=0;i<${#@};i++)); do
    if [[ "${!i}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
    spectacle -R s &
else
    # Spectacle requires interactive selection for regions, so we ignore the --region arg from Quickshell
    spectacle -R r &
fi