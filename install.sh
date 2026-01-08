#!/bin/bash
# =============================================================================
# Dotfiles Install Script (Quick)
# =============================================================================
# Symlinks configs using GNU Stow - use this for quick updates
# For full restore on fresh install, use restore.sh instead
# =============================================================================

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES using stow"
echo ""

# Create base directories
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share

cd "$DOTFILES"

# Stow all packages
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
