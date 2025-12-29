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
echo "[1/7] Installing packages..."
if [ -f "$DOTFILES/package-list.txt" ]; then
    paru -S --needed - < "$DOTFILES/package-list.txt" || echo "Some packages may have failed, continuing..."
else
    echo "Warning: package-list.txt not found, skipping package install"
fi

# -----------------------------------------------------------------------------
# STEP 2: Create directories
# -----------------------------------------------------------------------------
echo "[2/7] Creating directories..."
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/qutebrowser
mkdir -p ~/.local/share/vicinae/themes
mkdir -p ~/.local/share/aurorae/themes

# -----------------------------------------------------------------------------
# STEP 3: Copy config files
# -----------------------------------------------------------------------------
echo "[3/7] Copying config files..."
cp -r "$DOTFILES/.config/"* ~/.config/ 2>/dev/null || true

# -----------------------------------------------------------------------------
# STEP 4: Copy local files (scripts, themes)
# -----------------------------------------------------------------------------
echo "[4/7] Copying scripts and local files..."
cp -r "$DOTFILES/.local/bin/"* ~/.local/bin/ 2>/dev/null || true
cp -r "$DOTFILES/.local/share/"* ~/.local/share/ 2>/dev/null || true

# Make scripts executable
chmod +x ~/.local/bin/* 2>/dev/null || true

# -----------------------------------------------------------------------------
# STEP 5: Copy pictures/assets
# -----------------------------------------------------------------------------
echo "[5/7] Copying pictures and assets..."
mkdir -p ~/Pictures/nzxt
cp -r "$DOTFILES/Pictures/"* ~/Pictures/ 2>/dev/null || true

# -----------------------------------------------------------------------------
# STEP 6: Install themes and plugins
# -----------------------------------------------------------------------------
echo "[6/7] Installing themes and plugins..."

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
# STEP 7: Enable systemd user services
# -----------------------------------------------------------------------------
echo "[7/7] Enabling systemd services..."
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
echo "Enjoy your rice!"
