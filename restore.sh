#!/bin/bash
# =============================================================================
# Dotfiles Restore Script
# =============================================================================
# Restores your CachyOS rice on a fresh install
# Run from inside the dotfiles directory: ./restore.sh
# =============================================================================

set -e  # Exit on any error

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
echo "=== Dotfiles Restore Script ==="
echo "Restoring from: $DOTFILES"
echo ""

# -----------------------------------------------------------------------------
# STEP 1: Install packages
# -----------------------------------------------------------------------------
echo "[1/6] Installing packages..."
if [ -f "$DOTFILES/package-list.txt" ]; then
    paru -S --needed - < "$DOTFILES/package-list.txt" || echo "Some packages may have failed, continuing..."
else
    echo "Warning: package-list.txt not found, skipping package install"
fi

# -----------------------------------------------------------------------------
# STEP 2: Create directories
# -----------------------------------------------------------------------------
echo "[2/6] Creating directories..."
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/qutebrowser
mkdir -p ~/.local/share/vicinae/themes
mkdir -p ~/.local/share/aurorae/themes
mkdir -p ~/Videos/ytdlp
mkdir -p ~/Pictures/Wallpapers/Catppuccin
mkdir -p ~/Videos/Wallpapers/Catppuccin

# -----------------------------------------------------------------------------
# STEP 3: Stow all configs
# -----------------------------------------------------------------------------
echo "[3/6] Stowing config packages..."
cd "$DOTFILES"

# List of stow packages (directories with .config or .local inside)
STOW_PACKAGES=(
    browser
    fetch
    input-remapper
    kde
    launcher
    music
    niri
    scripts
    shell
    terminal
    wallust
    yazi
    yt-dlp
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        echo "  Stowing $pkg..."
        stow -R "$pkg" 2>/dev/null || echo "    Warning: $pkg may have conflicts"
    fi
done

# Make scripts executable
chmod +x ~/.local/bin/* 2>/dev/null || true

# -----------------------------------------------------------------------------
# STEP 4: Copy assets (non-stow items)
# -----------------------------------------------------------------------------
echo "[4/6] Copying assets..."
if [ -d "$DOTFILES/assets" ]; then
    mkdir -p ~/Pictures/nzxt
    cp "$DOTFILES/assets/"* ~/Pictures/nzxt/ 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# STEP 5: Install themes and plugins
# -----------------------------------------------------------------------------
echo "[5/6] Installing themes and plugins..."

# Yazi flavor
if command -v ya &> /dev/null; then
    ya pkg add yazi-rs/flavors:catppuccin-macchiato 2>/dev/null || echo "Yazi flavor may already be installed"
fi

# Generate lutgen LUT if not exists
if command -v lutgen &> /dev/null; then
    if [ ! -f ~/.local/share/lutgen/macchiato_lut.png ]; then
        mkdir -p ~/.local/share/lutgen
        lutgen generate -p catppuccin-macchiato -o ~/.local/share/lutgen/macchiato_lut.png
        echo "Generated Catppuccin LUT for video conversion"
    fi
fi

# -----------------------------------------------------------------------------
# STEP 6: Enable systemd user services
# -----------------------------------------------------------------------------
echo "[6/6] Enabling systemd services..."
systemctl --user daemon-reload

# Vicinae launcher
if [ -f ~/.config/systemd/user/vicinae.service ]; then
    systemctl --user enable vicinae 2>/dev/null || true
fi

# Catppuccin watcher
if [ -f ~/.config/systemd/user/catppuccin-watcher.service ]; then
    systemctl --user enable catppuccin-watcher 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# DONE!
# -----------------------------------------------------------------------------
echo ""
echo "=== Restore Complete! ==="
echo ""
echo "Next steps:"
echo "  1. Log out and back in (or reboot) for all changes to take effect"
echo "  2. Set your wallpaper"
echo "  3. Configure KDE settings (panel, window rules, etc.)"
echo "  4. Run ':adblock-update' in qutebrowser"
echo ""
echo "Theme switching:"
echo "  toggle-theme catppuccin    - Use Catppuccin Macchiato Flamingo"
echo "  toggle-theme wallust <img> - Dynamic colors from wallpaper"
echo ""
echo "Enjoy your rice!"
