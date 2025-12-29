source /usr/share/cachyos-fish-config/cachyos-config.fish

# Initialize Starship prompt
starship init fish | source

# Initialize zoxide (smarter cd)
zoxide init fish | source

# fzf keybindings (Ctrl+R for history search)
fzf --fish | source

# eza aliases (better ls)
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --icons --level=2"

# bat alias (better cat)
alias cat="bat --style=auto"

# duf alias (better df)
alias df="duf"

# dust alias (better du)
alias du="dust"

# fd alias (better find)
alias find="fd"

# overwrite greeting with neofetch cat
function fish_greeting
    neofetch
end
