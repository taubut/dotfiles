#!/bin/bash
# Dotfiles install script - symlinks configs to proper locations

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES"

# Create directories
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/nzxt

# Symlink configs
ln -sf "$DOTFILES/.config/ghostty" ~/.config/
ln -sf "$DOTFILES/.config/starship.toml" ~/.config/
ln -sf "$DOTFILES/.config/cava" ~/.config/
ln -sf "$DOTFILES/.config/fish" ~/.config/
ln -sf "$DOTFILES/.config/btop" ~/.config/
ln -sf "$DOTFILES/.config/walker" ~/.config/
ln -sf "$DOTFILES/.config/fresh" ~/.config/

# Symlink scripts
ln -sf "$DOTFILES/.local/bin/catfetch" ~/.local/bin/
ln -sf "$DOTFILES/.local/bin/backup" ~/.local/bin/

# Symlink images
ln -sf "$DOTFILES/Pictures/nzxt/catppuccin_logo.svg" ~/Pictures/nzxt/
ln -sf "$DOTFILES/Pictures/nzxt/catppuccin_logo.ans" ~/Pictures/nzxt/ 2>/dev/null

echo "Done! Restart your shell to apply changes."
