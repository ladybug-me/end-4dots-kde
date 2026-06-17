# Quickshell Keyboard Shortcuts

## Applications
```ini
super + enter
   kitty
```

# Workspaces (Experimental)
```ini
super + 1
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 1
super + 2
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 2
super + 3
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 3
super + 4
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 4
super + 5
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 5
super + 6
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 6
super + 7
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 7
super + 8
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 8
super + 9
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 9
super + 0
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 10
```

## For brightness (to apply later)
##   xf86monbrightnessup
##	     brightnessctl set +10% && ddcutil setvcp 10 + 10
##   xf86monbrightnessdown
##	     brightnessctl set -10% && ddcutil setvcp 10 - 10

## System & Session
```ini
xf86audioraisevolume
	wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
xf86audiolowervolume
	wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
xf86audiomute
	wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
ctrl + super + shift + alt + delete
    systemctl poweroff
super + shift + l
    systemctl suspend
ctrl + alt + delete
    qs -c ii ipc call session toggle
```

## Desktop & Shell UI
```ini
ctrl + super + t
    qs -c ii ipc call wallpaperSelector toggle
ctrl + super + alt + t
    qs -c ii ipc call wallpaperSelector random
ctrl + super + p
    qs -c ii ipc call panelFamily cycle
ctrl + super + r
    bash -c 'killall ydotool qs quickshell; qs -c ii &'
super + j
    qs -c ii ipc call bar toggle
super + b
    qs -c ii ipc call sidebarLeft toggle
super + alt + a
    qs -c ii ipc call sidebarLeft toggle
ctrl + super + shift + d
    qs -c ii ipc call theme toggleLightDark
super + m
    qs -c ii ipc call mediaControls toggle
super + k
    qs -c ii ipc call osk toggle
super + g
    qs -c ii ipc call overlay toggle
super + n
    qs -c ii ipc call sidebarRight toggle
super + slash
    qs -c ii ipc call cheatsheet toggle
```

## Search & Tools
```ini
super + period
    qs -c ii ipc call search toggle
super + space
    qs -c ii ipc call search toggle
super + shift + a
    qs -c ii ipc call region search
super + shift + c
    ~/.local/bin/kcolorpicker -a
super + shift + x
    qs -c ii ipc call region ocr
super + shift + t
    qs -c ii ipc call screenTranslator translate
super + v
    qs -c ii ipc call search clipboardToggle
```

## Screenshots & Recording
```ini
super + shift + r
    qs -c ii ipc call region record
super + alt + r
    qs -c ii ipc call region record
ctrl + alt + r
    $HOME/.config/quickshell/ii/scripts/videos/record.sh --fullscreen
super + shift + alt + r
    $HOME/.config/quickshell/ii/scripts/videos/record.sh --fullscreen --sound
ctrl + print
    bash -c 'mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_$(date "+%Y-%m-%d_%H.%M.%S").png'
super + shift + s
    qs -c ii ipc call region screenshot
print
    bash -c 'grim - | wl-copy'
```

