# Catppuccin Macchiato theme for qutebrowser
import sys
sys.path.append(str(config.configdir / 'catppuccin'))
import catppuccin

# Load existing settings
config.load_autoconfig()

# Apply Catppuccin Macchiato theme (True = plain menu rows)
catppuccin.setup(c, 'macchiato', True)

# Default homepage
c.url.start_pages = ['https://aur.archlinux.org/']
c.url.default_page = 'https://aur.archlinux.org/'

# Spoof as Windows Chrome
c.content.headers.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'

# Spoof client hints headers
c.content.headers.custom = {
    'Sec-CH-UA-Platform': '"Windows"',
    'Sec-CH-UA-Platform-Version': '"10.0.0"',
    'Sec-CH-UA': '"Chromium";v="131", "Google Chrome";v="131", "Not?A_Brand";v="99"',
}

# Ad blocking (uses both hosts file and Brave's adblocker)
c.content.blocking.method = 'both'
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
]
