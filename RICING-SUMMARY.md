# CachyOS Rice Summary

## Theme
- **Color Scheme:** Catppuccin Macchiato
- **Accent Color:** Flamingo (#f0c6c6)

## Applications Themed

### Terminal & Shell
- **Ghostty** - Terminal emulator with Catppuccin colors and transparency
- **Fish Shell** - Default shell with CachyOS config
- **Starship** - Prompt with Catppuccin Macchiato colors, flamingo accent
- **Neofetch** - Custom cat ASCII art in flamingo, runs on terminal open
- **Fastfetch** - CachyOS small logo with Catppuccin colors and Nerd Font icons

### CLI Tools
- **btop** - System monitor with Catppuccin Macchiato theme
- **cava** - Audio visualizer widget (SDL mode, borderless)
- **rmpc** - TUI MPD client with Catppuccin Flamingo theme
- **mpd** - Music Player Daemon for local music playback

### Desktop Environment (KDE Plasma)
- **SDDM** - Login screen with Catppuccin Macchiato Flamingo theme
- **Conky** - System monitor widget with weather, now playing, system stats
- **Walker** - App launcher with Catppuccin Macchiato Flamingo theme (Super+Space)
- **Papirus Icons** - With Catppuccin Macchiato Flamingo folder colors
- **Cursor** - Catppuccin Macchiato Flamingo

### Browsers & Apps
- **Zen Browser** - userChrome.css with Catppuccin Macchiato Flamingo, 90% opacity
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
- Elephant backend (for Walker)
- cava-widget - Audio visualizer
- rmpc-widget - Music player
- Ghostty terminal (--class=ghostty-main)

### KWin Scripts & Plugins
- **Remember Window Positions** - Restores window positions on launch
- **Built-in Tiling** - Meta+T for tile layout, Shift+drag to tile

### Backup System
- **Borg Backup** - Script at ~/.local/bin/backup
  - Backs up home directory to Unraid NAS (smb://192.168.1.185/BubMachine/)
  - Excludes Steam, cache, trash, etc.
  - Saves package list before backup
  - Opens in Ghostty with kdialog passphrase prompt

### Dotfiles
- **Repository:** GitHub (private)
- **Auto-sync:** Daily via systemd timer
- **Configs included:**
  - ghostty
  - fish
  - starship
  - cava
  - btop
  - walker
  - conky
  - neofetch
  - fastfetch
  - Custom scripts (catfetch, backup)

## File Locations

### Configs
- ~/.config/ghostty/config
- ~/.config/fish/config.fish
- ~/.config/starship.toml
- ~/.config/cava/config
- ~/.config/btop/btop.conf
- ~/.config/walker/
- ~/.config/conky/conky.conf
- ~/.config/neofetch/config.conf
- ~/.config/fastfetch/config.jsonc
- ~/.config/rmpc/config.ron
- ~/.config/rmpc/theme.ron
- ~/.config/mpd/mpd.conf

### Custom Scripts
- ~/.local/bin/backup - Borg backup script
- ~/.local/bin/catfetch - Custom fetch script
- ~/.local/bin/dotfiles-sync - Auto-sync dotfiles to GitHub
- ~/.local/bin/cava-widget - Launch cava in SDL mode
- ~/.local/bin/rmpc-widget - Launch rmpc in Ghostty window

### Themes & Assets
- ~/Pictures/cat-ascii.txt - Custom cat ASCII for neofetch
- ~/Pictures/nzxt/catppuccin_logo.svg - Custom Catppuccin logo

## Keyboard Shortcuts
- **Super + Space** - Walker launcher
- **Super + Left Click Drag** - Move window
- **Super + Right Click Drag** - Resize window

## Packages Installed
- ghostty
- starship
- eza
- bat
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

## Future Enhancements (To Check Out Later)

### Terminal QoL Tools
- **bat** - `cat` with syntax highlighting (https://github.com/sharkdp/bat)
- **eza** - Modern `ls` with colors/icons (https://github.com/eza-community/eza)
- **zoxide** - Smarter `cd` that learns your frequent dirs (https://github.com/ajeetdsouza/zoxide)
- **fzf** - Fuzzy finder for everything, Ctrl+R for history (https://github.com/junegunn/fzf)

### TUI File Managers
- **yazi** - Fast terminal file manager (https://github.com/sxyazi/yazi)
- **ranger** - Classic vim-like file manager
