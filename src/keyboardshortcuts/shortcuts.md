# Quickshell Keyboard Shortcuts

## Applications
```ini
super + enter
   kitty
```

## System & Session
```ini
xf86audioraisevolume
	wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
xf86audiolowervolume
	wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
xf86audiomute
	wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
xf86monbrightnessup
	brightnessctl set +10% && ddcutil setvcp 10 + 10
xf86monbrightnessdown
	brightnessctl set -10% && ddcutil setvcp 10 - 10
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
    hyprpicker -a
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

