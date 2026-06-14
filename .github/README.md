<div align="center">
    <h1>【 end_4's dotfiles — KDE Plasma Port 】</h1>
    <h3>A KDE adaptation of the illogical-impulse aesthetic</h3>
</div>

<div align="center"> 

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793d1?logo=arch-linux&logoColor=white&style=for-the-badge)
![KDE Plasma](https://img.shields.io/badge/KDE_Plasma-1D99F3?logo=kde&logoColor=white&style=for-the-badge)
![Quickshell](https://img.shields.io/badge/Quickshell-FF6B6B?style=for-the-badge)
![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge&color=86dbce)

</div>

<div align="center">
    <h2>• what is this •</h2>
    <h3></h3>
</div>

> [!NOTE]  
> This is a **community KDE port** of [end-4's Hyprland dotfiles](https://github.com/end-4/dots-hyprland), adapted by **ladybug-me** to run on **KDE Plasma** instead of Hyprland.

<details> 
  <summary>What this is/isn't</summary>

  - Technically: A collection of KDE Plasma configuration files, custom widgets, and installation scripts
  - Visually: The illogical-impulse aesthetic ported to KDE Plasma with Quickshell widgets
  - NOT: A replacement for the original Hyprland dotfiles (which are superior for minimal window managers)
  - NOT: A system setup script (only packages and configs, no drivers, zram, etc.)
  
</details>

<details> 
  <summary>Why KDE instead of Hyprland?</summary>

  - KDE Plasma offers better compatibility with existing tools and ecosystems
  - Familiar desktop environment for users transitioning from Windows/GNOME
  - Strong integration with Arch Linux community and AUR
  - Still maintains the illogical-impulse aesthetic and customization spirit
  
</details>

<details> 
  <summary>Key features</summary>
     
  - **Material Design 3 theming**: Cohesive dark theme with Darkly + Kvantum + custom colors
  - **Quickshell widgets**: Native KDE integration with modern Qt-based widget system
  - **10 virtual desktops**: Pre-configured with Meta+0–9 shortcuts
  - **Custom KDE bridge**: Quickshell-KDE integration via KWin script for seamless widget interaction
  - **Custom hyprctl**: Rewritten to integrate with hyprland calls by quickshell
  - **Transparent installation**: Every command shown before execution; idempotent and safe to run multiple times
  - **AI integration**: Ready for Gemini, Ollama, and other AI backends
  - **QoL features**: Screen translation, anti-flashbang, color-picked themes
  - **Window tiling**: Optional Polonium support for tiling window management
  
</details>

<details> 
  <summary>Installation</summary>

  1. Clone this repo:
     ```bash
     git clone https://github.com/ladybug-me/end-4dotsKDE ~/end-4dotsKDE
     cd ~/end-4dotsKDE
     ```
  2. Run the installer:
     ```bash
     bash ./setup.sh
     ```
  3. Follow the interactive prompts (you can retry/ignore errors)
  
  **Requirements:**
  - Arch Linux or Arch-based distro (Endeavour OS, Manjaro, etc.)
  - KDE Plasma 6.0+
  - `yay` or similar AUR helper (installer will set up if missing)
  
  **Optional:** 
  - Hyprpicker for color picking
  - Matugen for color generation from wallpaper
  - Polonium for window tiling capabilities
  
</details>
</details>

<div align="center">
    <h2>• screenshots •</h2>
    <h3></h3>
</div>

<div align="center">
    <img src="assets/illogical-impulse.svg" alt="illogical-impulse logo" style="max-width: 400px;">
</div>

| KDE Plasma | MaterialYouColor with Icons |
|:---|:---|
| <img width="1920" height="1080" alt="screenshot1" src="https://github.com/user-attachments/assets/475bf418-c68f-4411-9c26-c6eaac2f2f49" /> | <img width="1920" height="1080" alt="screenshot2" src="https://github.com/user-attachments/assets/46958e34-c675-4daf-b53f-ec14b8d5ba65" /> |
| **Illogical Impulse Settings** | **KDE + Keyd Shortcuts** |
| <img width="1920" height="1080" alt="screenshot3" src="https://github.com/user-attachments/assets/3c6d4dfc-17a4-475c-aa78-753342d5f2f4" /> | <img width="1920" height="1080" alt="screenshot4" src="https://github.com/user-attachments/assets/cb205aa6-2ade-4d28-ba27-afe7f1f82e8f" /> |

<div align="center">
    <h2>• software stack •</h2>
    <h3></h3>
</div>

| Component | Purpose | Notes |
| --- | --- | --- |
| [KDE Plasma](https://kde.org/plasma/) | Desktop environment | Full-featured modern DE |
| [Quickshell](https://quickshell.outfoxxed.me/) | Widget system | Qt-based, replaces AGS for this port |
| [Darkly](https://github.com/vinceliuice/Darkly) | Theme framework | Used for Plasma style + window decoration |
| [Kvantum](https://github.com/tsujan/Kvantum) | Qt theme engine | For consistent application styling |
| [KWin](https://invent.kde.org/plasma/kwin) | Window manager | KDE's compositing window manager |
| [Polonium](https://github.com/zeroxoneafour/polonium) | Window tiling | Optional KDE tiling plugin (available during install) |
| [Hyprpicker](https://github.com/hyprwm/hyprpicker) | Color picker | For wallpaper color extraction |
| [Matugen](https://github.com/InioX/matugen) | Color generation | Generates Material Design 3 palettes |

<details> 
  <summary>Full dependencies</summary>

  See [sdata/arch-dist/](https://github.com/ladybug-me/end-4dotsKDE/tree/main/sdata/arch-dist/) for custom PKGBUILDs:
  
  - **illogical-impulse-audio**: PipeWire + Wireplumber audio setup
  - **illogical-impulse-basic**: Core utilities and system tools
  - **illogical-impulse-backlight**: Backlight control utilities
  - **illogical-impulse-fonts-themes**: Material Design 3 themes and fonts
  - **illogical-impulse-kde**: KDE Plasma specific packages
  - **illogical-impulse-python**: Python environment for scripts
  - **illogical-impulse-quickshell-git**: Quickshell from git (latest)
  - **illogical-impulse-toolkit**: Development tools and utilities
  
</details>

<div align="center">
    <h2>• keybinds •</h2>
    <h3></h3>
</div>

| Key | Action |
| --- | --- |
| `Super` + `/` | Show keybind list |
| `Super` + `Enter` | Open terminal (Kitty) |
| `Super` + `Ctrl` + `T` | Open Wallpaper picker |
| `Super` + `1`–`0` | Switch to workspace 1–10 |
| `Super` + `Shift` + `1`–`0` | Move window to workspace 1–10 |
| `Super` + `Space` | Application launcher (Fuzzel) |
| `Super` + `V` | Clipboard picker |
| Color picker | Available via right-click menu or keybind |

<div align="center">
    <h2>• customization •</h2>
    <h3></h3>
</div>

- **Wallpaper**: Place a wallpaper in `~/Pictures/wallpapers/` and re-run Matugen to auto-generate Material Design 3 colors
- **Theme colors**: Edit [src/config/matugen/templates/](https://github.com/ladybug-me/end-4dotsKDE/tree/main/src/config/matugen/templates/) to customize color generation
- **KDE settings**: Modify [scripts/04-deploy-kde.sh](https://github.com/ladybug-me/end-4dotsKDE/blob/main/scripts/04-deploy-kde.sh) for Plasma configuration
- **Widgets**: Edit Quickshell configs in [src/quickshell/](https://github.com/ladybug-me/end-4dotsKDE/tree/main/src/quickshell/)

<div align="center">
    <h2>• troubleshooting •</h2>
    <h3></h3>
</div>

<details>
  <summary>Quickshell widgets not appearing</summary>
  
  - Log out and log back in.
  - Run: `qs -c ii` and check for any errors.
  
</details>

<details>
  <summary>Colors not applying</summary>
  
  - DO NOT USE KDE WALLPAPER MANAGER. Use quickshell built in wallpaper manager (Super + Ctrl + T).
  - Check for errors in: `System Settings -> Autostart -> KDE Material You Colors`
  - For Konsole, use Profile1
  
</details>

<details>
  <summary>Installation failed at step X</summary>
  
  - The installer is idempotent — safe to re-run: `bash ./setup.sh`
  - It will prompt you to retry, ignore, or exit on errors
  - Report in Issues with logs.
  
</details>

<div align="center">
    <h2>• credits •</h2>
    <h3></h3>
</div>

**Original project:**
- [end-4](https://github.com/end-4) for the incredible illogical-impulse design and original dotfiles

**This KDE port:**
- [ladybug-me](https://github.com/ladybug-me) for adapting the dotfiles to KDE Plasma

**Related projects & inspiration:**
- [Quickshell](https://quickshell.outfoxxed.me/) — Qt widget framework
- [Matugen](https://github.com/InioX/matugen) — Material Design 3 color generation
- [Darkly](https://github.com/vinceliuice/Darkly) — KDE theme
- [KDE Plasma](https://kde.org/plasma/) — Desktop environment
- Original acknowledgments in [dots-hyprland](https://github.com/end-4/dots-hyprland)

<div align="center">
    <h2>• support & community •</h2>
    <h3></h3>
</div>

- **Issues & bugs**: [GitHub Issues](https://github.com/ladybug-me/end-4dotsKDE/issues)
- **Original project**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
- **Quickshell docs**: [outfoxxed.me](https://quickshell.outfoxxed.me/)
- **KDE community**: [KDE Forums](https://www.reddit.com/r/kde/)

<div align="center">
    <h2>• license •</h2>
    <h3></h3>
</div>

This project is licensed under the **GNU General Public License v3.0** — the same license as the original [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) project.

- You are free to use, modify, and distribute this project
- Any derivative work must also be licensed under GPLv3
- See [LICENSE](https://github.com/ladybug-me/end-4dotsKDE/blob/main/LICENSE) for the full text
