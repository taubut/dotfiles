# Catppuccin Macchiato theme for qutebrowser
import sys
sys.path.append(str(config.configdir / 'catppuccin'))
import catppuccin

# Load existing settings
config.load_autoconfig()

# Apply Catppuccin Macchiato theme (True = plain menu rows)
catppuccin.setup(c, 'macchiato', True)

# Ad blocking (uses both hosts file and Brave's adblocker)
c.content.blocking.method = 'both'
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
]
