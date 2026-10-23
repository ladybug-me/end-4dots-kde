#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"

find_caelestia_color() {
    if command -v caelestia-color &>/dev/null; then
        command -v caelestia-color
    elif [[ -x "$HOME/.local/bin/caelestia-color" ]]; then
        echo "$HOME/.local/bin/caelestia-color"
    elif [[ -x "/usr/bin/caelestia-color" ]]; then
        echo "/usr/bin/caelestia-color"
    elif [[ -x "$SCRIPT_DIR/../../../../src/bin/caelestia-color" ]]; then
        echo "$SCRIPT_DIR/../../../../src/bin/caelestia-color"
    else
        echo "caelestia-color"
    fi
}
CAELESTIA_COLOR="$(find_caelestia_color)"

map_variant() {
    case "$1" in
        scheme-tonal-spot|tonalspot) printf 'tonalspot' ;;
        scheme-vibrant|vibrant) printf 'vibrant' ;;
        scheme-expressive|expressive) printf 'expressive' ;;
        scheme-fidelity|fidelity) printf 'fidelity' ;;
        scheme-fruit-salad|fruitsalad) printf 'fruitsalad' ;;
        scheme-monochrome|monochrome) printf 'monochrome' ;;
        scheme-neutral|neutral) printf 'neutral' ;;
        scheme-rainbow|rainbow) printf 'rainbow' ;;
        scheme-content|content) printf 'content' ;;
        auto|"") printf 'auto' ;;
        *) printf 'tonalspot' ;;
    esac
}

pre_process() {
    local mode_flag="$1"
    # Set GNOME color-scheme if mode_flag is dark or light
    if command -v gsettings &>/dev/null; then
        if [[ "$mode_flag" == "dark" ]]; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
            gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
        elif [[ "$mode_flag" == "light" ]]; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
            gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null || true
        fi
    fi

    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
}

check_and_prompt_upscale() {
    local img="$1"
    command -v hyprctl &>/dev/null || return 0
    command -v bc &>/dev/null || return 0
    min_width_desired="$(hyprctl monitors -j | jq '([.[].width] | max)' | xargs)" # max monitor width
    min_height_desired="$(hyprctl monitors -j | jq '([.[].height] | max)' | xargs)" # max monitor height

    if command -v identify &>/dev/null && [ -f "$img" ]; then
        local img_width img_height
        if is_video "$img"; then # Not check resolution for videos, just let em pass
            img_width=$min_width_desired
            img_height=$min_height_desired
        else
            img_width=$(identify -format "%w" "$img" 2>/dev/null)
            img_height=$(identify -format "%h" "$img" 2>/dev/null)
        fi
        if [[ "$img_width" -lt "$min_width_desired" || "$img_height" -lt "$min_height_desired" ]]; then
            action=$(notify-send "Upscale?" \
                "Image resolution (${img_width}x${img_height}) is lower than screen resolution (${min_width_desired}x${min_height_desired})" \
                -A "open_upscayl=Open Upscayl"\
                -a "Wallpaper switcher")
            if [[ "$action" == "open_upscayl" ]]; then
                if command -v upscayl &>/dev/null; then
                    nohup upscayl > /dev/null 2>&1 &
                else
                    action2=$(notify-send \
                        -a "Wallpaper switcher" \
                        -c "im.error" \
                        -A "install_upscayl=Install Upscayl (Arch)" \
                        "Install Upscayl?" \
                        "yay -S upscayl-bin")
                    if [[ "$action2" == "install_upscayl" ]]; then
                        kitty -1 yay -S upscayl-bin
                        if command -v upscayl &>/dev/null; then
                            nohup upscayl > /dev/null 2>&1 &
                        fi
                    fi
                fi
            fi
        fi
    fi
}

CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$RESTORE_SCRIPT_DIR/mpvpaper_thumbnails"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -f -9 mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

pkill -f -9 mpvpaper

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    mpvpaper -o "$VIDEO_OPTS" "\$monitor" "$video_path" &
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    if [[ -d "$RESTORE_SCRIPT_DIR" ]]; then
        cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
        mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    fi
}

set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_palette_type() {
    local type="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg type "$type" '.appearance.palette.type = $type' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

categorize_wallpaper() {
    img_cat=$("$SCRIPT_DIR/../ai/gemini-categorize-wallpaper.sh" "$1")
    # notify-send "Wallpaper category" "$img_cat"
    echo "$img_cat" > "$STATE_DIR/user/generated/wallpaper/category.txt"
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"

    # Start Gemini auto-categorization if enabled
    aiStylingEnabled=$(jq -r '.background.widgets.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
    if [[ "$aiStylingEnabled" == "true" ]]; then
        categorize_wallpaper "$imgpath" &
    fi

    local variant
    variant="$(map_variant "$type_flag")"

    if [[ "$color_flag" == "1" ]]; then
        pre_process "$mode_flag"
        local scheme_cmd=("$CAELESTIA_COLOR" scheme set)
        [[ -n "$mode_flag" ]] && scheme_cmd+=(-m "$mode_flag")
        [[ -n "$variant" && "$variant" != "auto" ]] && scheme_cmd+=(-v "$variant")
        "${scheme_cmd[@]}"
    else
        if [[ -z "$imgpath" ]]; then
            echo 'Aborted'
            exit 0
        fi

        check_and_prompt_upscale "$imgpath" &
        kill_existing_mpvpaper

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"

            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then
                missing_deps+=("mpvpaper")
            fi
            if ! command -v ffmpeg &> /dev/null; then
                missing_deps+=("ffmpeg")
            fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                action=$(notify-send \
                    -a "Wallpaper switcher" \
                    -c "im.error" \
                    -A "install_arch=Install (Arch)" \
                    "Can't switch to video wallpaper" \
                    "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi

            # Set wallpaper path
            set_wallpaper_path "$imgpath"

            # Set video wallpaper
            local video_path="$imgpath"
            monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' 2>/dev/null || echo "")
            for monitor in $monitors; do
                mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" &
                sleep 0.1
            done

            # Extract first frame for color generation
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null

            # Set thumbnail path
            set_thumbnail_path "$thumbnail"

            if [ -f "$thumbnail" ]; then
                create_restore_script "$video_path"
                imgpath="$thumbnail"
            else
                echo "Cannot create image to colorgen"
                remove_restore
                exit 1
            fi
        else
            # Update wallpaper path in config
            set_wallpaper_path "$imgpath"
            remove_restore
        fi

        pre_process "$mode_flag"

        # Apply scheme/mode settings via caelestia-color
        if [[ "$noswitch_flag" == "1" ]]; then
            local current_wall
            current_wall=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
            if [[ -n "$imgpath" && "$imgpath" != "$current_wall" && -f "$imgpath" ]]; then
                set_wallpaper_path "$imgpath"
                "$CAELESTIA_COLOR" wallpaper -f "$imgpath"
                if command -v plasma-apply-wallpaperimage &>/dev/null && ! is_video "$imgpath"; then
                    plasma-apply-wallpaperimage "$imgpath" >/dev/null 2>&1 &
                fi
            fi
            local scheme_cmd=("$CAELESTIA_COLOR" scheme set -n dynamic)
            [[ -n "$mode_flag" ]] && scheme_cmd+=(-m "$mode_flag")
            if [[ -n "$variant" && "$variant" != "auto" ]]; then
                scheme_cmd+=(-v "$variant")
            fi
            "${scheme_cmd[@]}"
        else
            "$CAELESTIA_COLOR" wallpaper -f "$imgpath"
            local scheme_cmd=("$CAELESTIA_COLOR" scheme set -n dynamic)
            local need_scheme_set=0
            if [[ -n "$mode_flag" ]]; then
                scheme_cmd+=(-m "$mode_flag")
                need_scheme_set=1
            fi
            if [[ -n "$variant" && "$variant" != "auto" ]]; then
                scheme_cmd+=(-v "$variant")
                need_scheme_set=1
            fi
            if [[ $need_scheme_set -eq 1 ]]; then
                "${scheme_cmd[@]}"
            fi
            if command -v plasma-apply-wallpaperimage &>/dev/null && ! is_video "$imgpath"; then
                plasma-apply-wallpaperimage "$imgpath" >/dev/null 2>&1 &
            fi
        fi
    fi
}

main() {
    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""

    get_type_from_config() {
        jq -r '.appearance.palette.type' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "auto"
    }
    get_accent_color_from_config() {
        jq -r '.appearance.palette.accentColor' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""
    }
    set_accent_color() {
        local color="$1"
        jq --arg color "$color" '.appearance.palette.accentColor = $color' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    }

    detect_scheme_type_from_image() {
        echo "auto"
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                set_palette_type "$type_flag"
                shift 2
                ;;
            --color)
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    set_accent_color "$2"
                    shift 2
                elif [[ "$2" == "clear" ]]; then
                    set_accent_color ""
                    shift 2
                else
                    if command -v hyprpicker &>/dev/null; then
                        set_accent_color $(hyprpicker --no-fancy)
                    fi
                    shift
                fi
                ;;
            --image)
                imgpath="$2"
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
                shift
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    # If accentColor is set in config, use it
    config_color="$(get_accent_color_from_config)"
    if [[ "$config_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        color_flag="1"
        color="$config_color"
    fi

    # If type_flag is not set, get it from config
    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    # Validate type_flag (allow 'auto' as well)
    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Only prompt for wallpaper if not using --color and not using --noswitch and no imgpath set
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        local start_dir
        start_dir="$(xdg-user-dir PICTURES 2>/dev/null)/Wallpapers/showcase"
        [[ -d "$start_dir" ]] || start_dir="$(xdg-user-dir PICTURES 2>/dev/null)/Wallpapers"
        [[ -d "$start_dir" ]] || start_dir="$(xdg-user-dir PICTURES 2>/dev/null)"
        [[ -d "$start_dir" ]] || start_dir="$HOME"

        if command -v kdialog &>/dev/null; then
            imgpath="$(kdialog --getopenfilename "$start_dir" --title 'Choose wallpaper' 2>/dev/null)"
        elif command -v zenity &>/dev/null; then
            imgpath="$(zenity --file-selection --filename="$start_dir/" --title='Choose wallpaper' 2>/dev/null)"
        elif command -v python3 &>/dev/null; then
            imgpath="$(python3 -c "
import dbus, urllib.parse, sys
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

try:
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    portal = bus.get_object('org.freedesktop.portal.Desktop', '/org/freedesktop/portal/desktop')
    iface = dbus.Interface(portal, 'org.freedesktop.portal.FileChooser')

    loop = GLib.MainLoop()
    selected = []

    def on_response(response, results):
        if response == 0 and 'uris' in results and len(results['uris']) > 0:
            uri = str(results['uris'][0])
            if uri.startswith('file://'):
                selected.append(urllib.parse.unquote(uri[7:]))
            else:
                selected.append(uri)
        loop.quit()

    token = 'caelestia_picker'
    sender_clean = bus.get_unique_name()[1:].replace('.', '_')
    request_path = f'/org/freedesktop/portal/desktop/request/{sender_clean}/{token}'

    bus.add_signal_receiver(
        on_response,
        signal_name='Response',
        dbus_interface='org.freedesktop.portal.Request',
        path=request_path
    )

    iface.OpenFile('', 'Choose wallpaper', {'handle_token': token, 'multiple': False})
    loop.run()
    if selected:
        print(selected[0])
except Exception:
    pass
")"
        fi

        if [[ -z "$imgpath" ]]; then
            return 0 2>/dev/null || exit 0
        fi
    fi

    if [[ -n "$imgpath" && -z "$noswitch_flag" ]]; then
        set_accent_color ""
        color_flag=""
        color=""
    fi

    # If type_flag is 'auto' or empty, caelestia-color handles smart variant auto-detection natively
    if [[ -z "$type_flag" ]]; then
        type_flag="auto"
    fi

    # If mode_flag is dark or light, try to find a variant with that mode suffix
    if [[ "$mode_flag" == "dark" || "$mode_flag" == "light" ]]; then
        # Get directory, filename without extension, and extension
        local imgdir="$(dirname "$imgpath")"
        local imgbase="$(basename "$imgpath")"
        local imgname="${imgbase%.*}"
        local imgext="${imgbase##*.}"

        # Strip existing -dark or -light suffix
        local stripped_name="${imgname%-dark}"
        stripped_name="${stripped_name%-light}"

        # Construct the new path with the requested mode suffix
        local new_imgpath="${imgdir}/${stripped_name}-${mode_flag}.${imgext}"
        local new_stripped_imgpath="${imgdir}/${stripped_name}.${imgext}"

        # If the variant exists, use it
        if [[ -f "$new_imgpath" ]]; then
            imgpath="$new_imgpath"
        elif [[ -f "$new_stripped_imgpath" ]]; then
            imgpath="$new_stripped_imgpath"
        fi
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color"
}

main "$@"
