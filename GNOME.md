# GNOME

GNOME is a secondary session next to Plasma — installed 2026-08-14 on CachyOS,
GNOME Shell 50.4, running from the same `plasma-login-manager` login screen. The
`gnome` package group was installed whole, including `gdm`, which is **left
installed but never enabled**: `/etc/systemd/system/display-manager.service`
points at `plasmalogin.service` and should stay that way.

## Why this isn't a stow package

Every other desktop in this repo keeps its config in files — sway has
`.config/sway/config`, Plasma has its `*rc` files — so stow can symlink them.
**GNOME keeps almost nothing in files.** It lives in `dconf`, a binary database
under `~/.config/dconf/user`, so there is nothing to symlink and no way to hand
it a config file.

So `gnome/` is a dump-and-load pair instead, with the settings exported as text
in [`gnome/dconf/`](gnome/dconf/) — one file per subtree so git diffs are
readable.

## Saving and restoring

```bash
gnome-settings-save              # export current settings into gnome/dconf/
gnome-settings-restore           # load them back into the running session
gnome-settings-restore --dry-run # show what would load, change nothing
```

Both are in [`scripts/.local/bin/`](scripts/.local/bin/) and stowed to
`~/.local/bin`. Run `gnome-settings-save` after changing settings, then commit.

`dconf load` **merges** rather than replaces, so anything not in the dump is
left alone. Extension and shell-layout changes need a logout to appear.

Each `.ini` carries its target path in a `# dconf-path:` header comment, because
the filename can't be reversed back into a dconf path — `settings-daemon` and
`media-keys` contain dashes themselves.

### On a fresh machine

Order matters — restoring settings for extensions that aren't installed does
nothing useful:

```bash
sudo pacman -S gnome gnome-shell-extension-dash-to-dock
# log out, log into GNOME once so the shell registers the extension
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gnome-settings-restore
# log out and back in
```

Not wired into `fresh-start.sh` on purpose: it would fire on a machine where
GNOME may not even be installed, and Plasma is still the daily driver.

## What's tracked

| File | dconf path | Holds |
|---|---|---|
| `shell.ini` | `/org/gnome/shell/` | enabled extensions, favourites, **all Dash to Dock settings** |
| `desktop.interface.ini` | `/org/gnome/desktop/interface/` | theme, fonts, icons |
| `desktop.wm.preferences.ini` | `/org/gnome/desktop/wm/preferences/` | window button layout, focus mode |
| `desktop.wm.keybindings.ini` | `/org/gnome/desktop/wm/keybindings/` | window/workspace shortcuts |
| `desktop.peripherals.ini` | `/org/gnome/desktop/peripherals/` | mouse and keyboard |
| `mutter.ini` | `/org/gnome/mutter/` | dynamic workspaces, edge tiling |
| `settings-daemon.plugins.media-keys.ini` | `…/media-keys/` | custom shortcuts |
| `nautilus.preferences.ini` | `/org/gnome/nautilus/preferences/` | file manager |

Several are empty right now — everything is still at its default. They're kept
so the moment something *is* customised, `gnome-settings-save` picks it up
without editing the script.

**Deliberately not tracked:** a blanket `dconf dump /org/gnome/` would also drag
in Nautilus window geometry, per-application notification history, which
settings panel was open last, and `gnome-software` state. That's session state,
not configuration.

## Current setup

**Dock** — `gnome-shell-extension-dash-to-dock` (upstream Michele Gaio project;
Ubuntu's "Ubuntu Dock" is Canonical's fork of it). Configured to match Ubuntu:
left side, always visible (`dock-fixed`), full height, 48px icons, Show
Applications at the bottom, dot running-indicators, click-to-minimise, scroll to
cycle windows, dynamic transparency, shrunk theme.

The setting that actually makes it always-visible is `dock-fixed=true` — panel
mode (`extend-height`) only makes it full height, it still autohides without it.

**Workspace shortcuts** — GNOME's defaults, no customisation needed:

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+←` / `Ctrl+Alt+→` | Switch workspace |
| `Super+Page_Up` / `Super+Page_Down` | Same |
| add `Shift` | Take the current window along |
| `Super+Home` | Jump to workspace 1 |

Workspaces are dynamic. For `Super+1..4` to jump to fixed workspaces instead,
set `org.gnome.mutter dynamic-workspaces false` and bind
`switch-to-workspace-1..4` — then re-run `gnome-settings-save`, which captures
both.

## Gotchas

- **Wayland can't restart GNOME Shell in place.** The old `Alt+F2` → `r` is
  X11-only. A newly installed extension needs a full logout before the shell
  will even list it.
- **Never `systemctl enable gdm`.** It would take over
  `display-manager.service` from `plasma-login-manager`.
- Extensions break on GNOME major upgrades. Dash to Dock v105 declares support
  through shell 50; if it stops loading after an upgrade,
  `gnome-extensions info dash-to-dock@micxgx.gmail.com` will say so.
