# Pre-wipe checklist

Before reformatting, **back up everything below** — `fresh-start.sh` restores configs
and packages, but NOT the data/binaries/keys here. Copy them to the 2nd drive or an
external disk first. (You're reclaiming the Windows partition, so also grab anything
still on it.)

## 1. Verify these git repos are pushed (or they're gone)
- [ ] **dotfiles** — this repo (push after these edits)
- [ ] **Anchovy** — `~/anchovy-new` → github.com/taubut/Anchovy *(already pushed ✓)*
- [ ] **ShamanPower** — `~/git-work/ShamanPower` (check `git status` + `git push`)
- [ ] **pokefirered-custom** — `~/pokefirered-custom` (has a remote? if not, push somewhere)
- [ ] any other `~/git-work/*` or project with uncommitted work

## 2. Big local data (not in any repo)
- [ ] **Fluidsynth soundfont** — `~/.local/share/soundfonts/SC-55 Roland SOUNDCanvas Up.sf2`
      (178 MB). EQ music is silent without it; `~/.config/fluidsynth` points at this path.
- [ ] **`~/Faugus/`** — the entire EverQuest Legends + Battle.net setup: Wine prefixes,
      game installs, `eqclient.ini` (HidePlayers etc.), DLL overrides. Large — or plan to
      reinstall the games fresh and just note the settings.
- [ ] **`~/Documents/EQGuide/`** — the EQ Legends guide site we built.
- [ ] **Wallpapers** — `~/Pictures/Wallpapers`, `~/Videos/Wallpapers` (the pickers expect them)
- [ ] **`~/.claude/`** — Claude Code data incl. the memory notes (audio fixes, EQ/Faugus, etc.)
- [ ] **OpenRGB profiles** — `~/.config/OpenRGB/` (your LED profiles)

## 3. Secrets & accounts (never in git)
- [ ] **SSH keys** — `~/.ssh/`
- [ ] **GPG keys** — `~/.gnupg/`
- [ ] **Browser** — qutebrowser sessions/cookies/quickmarks in `~/.local/share/qutebrowser`
      and `~/.config/qutebrowser`; logins in any other browser
- [ ] App logins/tokens (Discord, etc.) as needed

## 4. KDE Plasma settings NOT tracked by the `kde/` stow package
The repo only tracks a few KDE files. Back up (or re-set after):
- [ ] **`~/.config/kglobalshortcutsrc`** — global shortcuts, incl. **Meta+Space → anchovy-toggle**
- [ ] `~/.config/kwinrc`, `~/.config/plasmarc`, `~/.config/plasmashellrc`
- [ ] Panel/widget layout, look-and-feel, SDDM theme
- [ ] Custom shortcuts (`~/.config/khotkeysrc` / `kglobalshortcutsrc`)
- [ ] Tip: KDE has *System Settings → (search) "export"* for some of this.

## 5. System-level (root) config
- [ ] `/etc/fstab` — mounts (will change anyway after re-partitioning)
- [ ] Custom `udev` rules — e.g. `/etc/udev/rules.d/99-beacn-mix.rules`
- [ ] Any `/etc/pacman.conf` tweaks (watch the NoExtract gotcha that eats WM .desktop files)

## After reinstall
1. Install CachyOS (pick **KDE Plasma**), then: `git clone <dotfiles> ~/dotfiles`
2. `cd ~/dotfiles && ./fresh-start.sh` → **Stage 1 (packages)** → **reboot**
3. `./fresh-start.sh` → **A (all)** for configs + apps + services
4. Restore the soundfont + KDE shortcuts + `~/Faugus` from your backup
5. `eq-fix` / `beacn-fix` are on PATH if audio needs a nudge
