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

# speedtest alias
alias speedtest="speedtest++ --test-server stosat-ndhm-01.sys.comcast.net:8080,1774"

# paru shortcuts
alias S="paru -Ss"    # search packages
alias Si="paru -S"    # install package
alias Su="paru -Syu"  # system update

# RDP to Windows PC
alias rdp="xfreerdp3 /v:192.168.1.119 /u:taubut@gmail.com /dynamic-resolution"

# overwrite greeting with neofetch cat
function fish_greeting
    neofetch
end
