#!/bin/bash
# =============================================================================
# Dotfiles Install Script (Quick)
# =============================================================================
# Symlinks configs using GNU Stow - use this for quick updates on a machine
# that's already set up. For a fresh install, use ./fresh-start.sh instead.
# =============================================================================

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES using stow"
echo ""

# Create base directories
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share

cd "$DOTFILES"

# Stow all packages — keep in sync with fresh-start.sh STOW_PACKAGES
STOW_PACKAGES=(
    kde
    autostart
    fluidsynth
    scripts
    shell
    terminal
    browser
    fetch
    input-remapper
    launcher
    music
    newsboat
    wallust
    yazi
    yt-dlp
    mako
    sway
    waybar
    wlogout
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        echo "Stowing $pkg..."
        stow -R "$pkg" 2>/dev/null || echo "  Warning: $pkg may have conflicts"
    fi
done

# Make scripts executable
chmod +x ~/.local/bin/* 2>/dev/null || true

echo ""
echo "Done! Restart your shell to apply changes."
echo ""
echo "Available commands:"
echo "  toggle-theme catppuccin    - Use Catppuccin Macchiato Flamingo"
echo "  toggle-theme wallust <img> - Dynamic colors from wallpaper"
