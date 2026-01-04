# CachyOS Rice Summary

## Theme
- **Color Scheme:** Catppuccin Macchiato
- **Accent Color:** Flamingo (#f0c6c6)

---

## Quick Restore (New Machine)

### Using GNU Stow (Recommended)
```bash
# 1. Install CachyOS with KDE Plasma

# 2. Install stow and packages
paru -S stow
paru -S --needed - < package-list.txt

# 3. Clone dotfiles
git clone https://github.com/taubut/dotfiles.git
cd dotfiles

# 4. Stow all packages (creates symlinks)
stow shell terminal fetch music browser launcher kde scripts assets yazi yt-dlp input-remapper

# 5. Enable services
systemctl --user enable --now vicinae catppuccin-watcher mpd

# 6. Reboot
reboot
```

### Stow Packages
| Package | Contents |
|---------|----------|
| `shell` | fish, starship |
| `terminal` | ghostty, btop, fresh |
| `fetch` | neofetch, fastfetch |
| `music` | cava, mpd, rmpc, neo-matrix colors |
| `browser` | qutebrowser + greasemonkey |
| `launcher` | rofi, vicinae + themes |
| `kde` | plasma configs, kwin rules, conky, aurorae themes, systemd services |
| `scripts` | all ~/.local/bin scripts, lutgen LUT, rofi-music.desktop |
| `assets` | Pictures (cat-ascii, nzxt logo) |
| `yazi` | yazi file manager |
| `yt-dlp` | yt-dlp config |
| `input-remapper` | macro keyboard config |

### Selective Install
```bash
# Only install shell + terminal
stow shell terminal

# Add music stuff later
stow music
```

### Post-Restore Steps
1. Set your wallpaper
2. Configure KDE panel (add widgets, set Panel Colorizer)
3. Apply window rules in KDE System Settings
4. Run `:adblock-update` in qutebrowser
5. Log into apps (Zen Browser, Discord, etc.)

### From Borg Backup (Full Restore)
See "Restoring from Borg Backup" section below for complete home directory restoration.

---

## Applications Themed

### Terminal & Shell
- **Ghostty** - Terminal emulator with Catppuccin colors and transparency
- **Fish Shell** - Default shell with CachyOS config
- **Starship** - Prompt with Catppuccin Macchiato colors, flamingo accent
- **Neofetch** - Custom cat ASCII art in flamingo, runs on terminal open
- **Fastfetch** - CachyOS small logo with Catppuccin colors and Nerd Font icons

### CLI Tools
- **btop** - System monitor with Catppuccin Macchiato theme
- **cava** - Audio visualizer widget (SDL mode, borderless, flamingo gradient)
- **rmpc** - TUI MPD client with Catppuccin Flamingo theme
- **mpd** - Music Player Daemon for local music playback
- **yazi** - Terminal file manager with Catppuccin Macchiato Flamingo theme
- **eza** - Modern ls replacement with icons
- **bat** - Cat replacement with syntax highlighting
- **fd** - Modern find replacement
- **duf** - Modern df replacement
- **dust** - Modern du replacement
- **neo-matrix** - Matrix rain effect with Catppuccin Flamingo theme (via neo-widget)
- **rofi** - dmenu-style launcher with Catppuccin Flamingo theme (used for music picker)

### Desktop Environment (KDE Plasma)
- **SDDM** - Login screen with Catppuccin Macchiato Flamingo theme
- **Conky** - System monitor widget with weather, now playing, system stats
- **Vicinae** - Raycast-style launcher with Catppuccin Macchiato Flamingo theme (Meta+Space)
- **Panel Colorizer** - Translucent panel with custom opacity
- **Papirus Icons** - With Catppuccin Macchiato Flamingo folder colors
- **Cursor** - Catppuccin Macchiato Flamingo
- **Window Decoration** - ActiveAccentFrame (no titlebar, 1px flamingo border)

### Browsers & Apps
- **Zen Browser** - userChrome.css with Catppuccin Macchiato Flamingo, 90% opacity
- **qutebrowser** - Vim-style browser with Catppuccin Macchiato theme, adblocking, SponsorBlock
- **YouTube Music Desktop** - Catppuccin CSS theme with flamingo accent, 90% opacity
- **VS Code** - Catppuccin theme with flamingo accent
- **Discord** - Vencord with Catppuccin Flamingo (user configured)

### Window Rules (KWin)
- Ghostty: 90% active opacity, 73% inactive
- Zen Browser: 90% opacity
- YouTube Music Desktop: 90% active, 80% inactive

## System Configuration

### Autostart
- Conky system monitor
- Vicinae launcher (systemd user service)
- cava-widget - Audio visualizer
- rmpc-widget - Music player
- mpd-mpris - MPRIS bridge for MPD
- Ghostty terminal (--class=ghostty-main)
- catppuccin-watcher - Auto-converts wallpapers to Catppuccin (systemd user service)

### KWin Scripts & Plugins
- **Remember Window Positions** - Restores window positions on launch
- **Built-in Tiling** - Meta+T for tile layout, Shift+drag to tile

### Music Library (MPD)
- **NTFS Drive Automount** - 2ndPro drive mounts at `/mnt/2ndPro` via fstab
- **Symlink** - `~/Music/SS` → `/mnt/2ndPro/Soulseek Downloads/complete`
- **fstab entry:**
  ```
  UUID=840048A400489F54 /mnt/2ndPro ntfs3 defaults,uid=1000,gid=1000,dmask=022,fmask=133 0 0
  ```

### Backup System
- **Borg Backup** - Script at ~/.local/bin/backup
  - Backs up home directory to Unraid NAS (smb://192.168.1.185/BubMachine/)
  - Excludes Steam, cache, trash, etc.
  - Saves package list before backup
  - Opens in Ghostty with kdialog passphrase prompt

#### Restoring from Borg Backup

1. **Mount Unraid share:**
   ```bash
   sudo mkdir -p /mnt/unraid-backup
   sudo mount -t cifs //192.168.1.185/BubMachine /mnt/unraid-backup -o username=YOUR_USER
   ```

2. **List available backups:**
   ```bash
   borg list /mnt/unraid-backup/borg-repo
   ```

3. **Restore entire home directory:**
   ```bash
   cd /
   borg extract /mnt/unraid-backup/borg-repo::ARCHIVE_NAME
   ```

4. **Restore specific files/folders:**
   ```bash
   borg extract /mnt/unraid-backup/borg-repo::ARCHIVE_NAME home/taubut/.config/ghostty
   ```

5. **Reinstall packages from saved list:**
   ```bash
   paru -S --needed - < ~/package-list.txt
   ```

### Dotfiles
- **Repository:** https://github.com/taubut/dotfiles (public)
- **Auto-sync:** `~/.local/bin/dotfiles-sync` script
- **Restore:** `./restore.sh` for new machine setup
- **Configs included:**
  - ghostty, fish, starship
  - cava, btop, conky
  - vicinae, neofetch, fastfetch
  - rmpc, mpd, yazi, rofi
  - qutebrowser (with Catppuccin theme and greasemonkey scripts)
  - KDE configs (plasma-appletsrc, kwinrulesrc)
  - ActiveAccentFrame window decoration
  - Vicinae Catppuccin Macchiato Flamingo theme
- **Scripts included:**
  - catfetch, backup
  - cava-widget, rmpc-widget
  - catppuccinify, catppuccin-watcher
  - neo-widget, rofi-music, dotfiles-sync

## File Locations

### Configs
- ~/.config/ghostty/config
- ~/.config/fish/config.fish
- ~/.config/starship.toml
- ~/.config/cava/config
- ~/.config/btop/btop.conf
- ~/.config/vicinae/settings.json
- ~/.local/share/vicinae/themes/catppuccin-macchiato-flamingo.toml
- ~/.config/conky/conky.conf
- ~/.config/neofetch/config.conf
- ~/.config/fastfetch/config.jsonc
- ~/.config/rmpc/config.ron
- ~/.config/rmpc/theme.ron
- ~/.config/mpd/mpd.conf
- ~/.config/yazi/theme.toml
- ~/.config/qutebrowser/config.py
- ~/.config/qutebrowser/catppuccin/ (theme module)
- ~/.local/share/qutebrowser/greasemonkey/SponsorBlock.user.js
- ~/.config/neo/catppuccin-flamingo.colors
- ~/.config/rofi/config.rasi

### Custom Scripts
- ~/.local/bin/backup - Borg backup script
- ~/.local/bin/catfetch - Custom fetch script
- ~/.local/bin/dotfiles-sync - Auto-sync dotfiles to GitHub
- ~/.local/bin/cava-widget - Launch cava in SDL mode
- ~/.local/bin/rmpc-widget - Launch rmpc in Ghostty window
- ~/.local/bin/catppuccinify - Convert images/videos to Catppuccin colors
- ~/.local/bin/catppuccin-watcher - Auto-convert wallpapers dropped in ~/Pictures/Wallpapers
- ~/.local/bin/neo-widget - Matrix rain that starts/stops with music playback
- ~/.local/bin/rofi-music - Search and play music via rofi (Ctrl+Alt+Meta+M)

### Systemd User Services
- ~/.config/systemd/user/vicinae.service
- ~/.config/systemd/user/catppuccin-watcher.service

### Themes & Assets
- ~/Pictures/cat-ascii.txt - Custom cat ASCII for neofetch
- ~/Pictures/nzxt/catppuccin_logo.svg - Custom Catppuccin logo

## Keyboard Shortcuts
- **Meta + Space** - Vicinae launcher
- **Ctrl + Alt + Meta + M** - Rofi music picker
- **Super + Left Click Drag** - Move window
- **Super + Right Click Drag** - Resize window

## Packages Installed
- ghostty
- starship
- cava
- btop
- conky
- playerctl
- papirus-icon-theme
- papirus-folders-catppuccin-git
- ttf-jetbrains-mono-nerd
- catppuccin-sddm-theme-macchiato
- yt-dlp
- plasma6-wallpapers-smart-video-wallpaper-reborn
- mpd
- rmpc
- mpd-mpris
- plasma6-applets-panel-colorizer
- vicinae-bin
- klassy
- catppuccinifier-bin
- lutgen (for video catppuccinification)
- inotify-tools (for catppuccin-watcher)
- qutebrowser
- yazi
- eza
- bat
- fd
- duf
- dust
- neo-matrix
- rofi
- mpc

## Catppuccin Wallpaper Pipeline

### Manual Conversion
```bash
# Convert single image
catppuccinify ~/Pictures/wallpaper.jpg

# Convert video
catppuccinify ~/Videos/wallpaper.mp4
```

### Automatic Conversion
Drop wallpapers into these folders and they'll auto-convert:
- `~/Pictures/Wallpapers/` → `~/Pictures/Wallpapers/Catppuccin/`
- `~/Videos/Wallpapers/` → `~/Videos/Wallpapers/Catppuccin/`

The `catppuccin-watcher` service runs automatically on login.

## Future Enhancements (To Check Out Later)

### Terminal QoL Tools
- **zoxide** - Smarter `cd` that learns your frequent dirs (https://github.com/ajeetdsouza/zoxide)
- **fzf** - Fuzzy finder for everything, Ctrl+R for history (https://github.com/junegunn/fzf)
