source /usr/share/cachyos-fish-config/cachyos-config.fish

# Initialize Starship prompt
starship init fish | source

# eza aliases (better ls)
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --icons --level=2"

# bat alias (better cat)
alias cat="bat --style=auto"

# overwrite greeting with neofetch cat
function fish_greeting
    neofetch
end
