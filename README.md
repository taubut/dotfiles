# Dotfiles

My CachyOS + **KDE Plasma** rice with Catppuccin Macchiato + Flamingo theme.
(sway is a secondary session.)

## What's included

- **Ghostty** - terminal config
- **Starship** - shell prompt
- **Fish** - shell config with eza/bat aliases
- **Cava** - audio visualizer
- **btop** - system monitor theme
- **Walker** - app launcher theme
- **Fresh** - editor theme
- **Anchovy** - custom PyQt6 app launcher ([github.com/taubut/Anchovy](https://github.com/taubut/Anchovy))
- **catfetch** - custom fetch script
- **backup** - Borg backup script
- **eq-fix** - relink EverQuest Legends' MIDI music to the Beacn Game dial ([notes](AUDIO-FIXES.md))
- **beacn-fix** - recover audio after swapping the Beacn Mic's aux plug, no reboot ([notes](AUDIO-FIXES.md))
- **gnome-settings-save / -restore** - export & reload GNOME's dconf settings, since GNOME has no config files to stow ([notes](GNOME.md))

## Fresh install (after a wipe)

**First** read [WIPE-CHECKLIST.md](WIPE-CHECKLIST.md) and back up what the scripts can't
restore (soundfont, `~/Faugus`, keys, KDE shortcuts).

```bash
git clone https://github.com/taubut/dotfiles.git ~/dotfiles
cd ~/dotfiles
./fresh-start.sh            # interactive, staged menu
# recommended: run Stage 1 (packages), REBOOT, then A (all)
```

`fresh-start.sh` runs in stages so nothing overlaps: **1** packages → **2** configs
(stow) → **3** apps (Anchovy, assets, themes) → **4** services. Flags also work:
`--packages`, `--configs`, `--apps`, `--services`, `--all`. (`restore.sh` is an alias
for `fresh-start.sh --all`.)

## Quick config update (already-set-up machine)

```bash
./install.sh               # just re-stow the dotfiles, no packages
```

## Packages

All packages live in [`package-list.txt`](package-list.txt) (native + AUR, installed by
`fresh-start.sh` via `paru`). Regenerate with `pacman -Qqen` (native) / `pacman -Qqem` (AUR).
