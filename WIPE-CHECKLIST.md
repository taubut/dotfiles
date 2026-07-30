# Pre-wipe checklist

The backup scripts now capture **almost everything automatically** — a full `$HOME`
mirror plus a system-state snapshot (groups, enabled services, package list, fstab).
This is the short list of things to *do* and *double-check* so nothing is lost.

## 1. Run the backups (in your own terminal — `backup-menu`)
- [ ] **Linux home** → `pre-wipe-backup` (mirrors ALL of `/home`, incl. `.config`,
      `.claude`, soundfont, Faugus/WoW, keys, input-remapper + Razer profiles)
- [ ] **2ndPro** drive → `drive-backup /mnt/2ndPro 2ndPro`
- [ ] **980Pro** drive → `drive-backup /run/media/taubut/980Pro 980Pro`
- [ ] **Basic Data** → `drive-backup "/run/media/taubut/E2C02718C026F289" Basic-Data`
- [ ] **Verify the drives**: `drive-backup --check <src> <name>` → must show a clean
      match. **Keep the drive originals until it does.**

## 2. What's captured for you (no action needed)
- Everything under `/home/taubut` except `~/Music` (that's your Plex share, safe on the server)
- **system-state/** in the backup: your **group memberships** (incl. `plugdev` for the
  Razer Naga, `input` for input-remapper), every **enabled service**, `pacman -Qqe`, `/etc/fstab`
- Your **dotfiles + installer** live inside the backup (`home/dotfiles/`) — no GitHub needed

## 3. Hardware — how it comes back
- **Razer Naga**: `fresh-start.sh --system` re-adds you to `plugdev`; the openrazer
  driver+daemon reinstall from `package-list.txt`; your lighting/DPI profiles restore
  with your home. → then **log out/in**.
- **input-remapper**: package reinstalls, `input` group re-added, its service re-enabled,
  and your mappings restore from `~/.config`. → **log out/in**.

## 4. Secrets — sanity check (they're in the backup, but confirm)
- [ ] `~/.ssh` and `~/.gnupg` copied (also tarred with correct perms in `keys/`)
- [ ] Browser logins you care about (qutebrowser / others) — profiles are in the home mirror

## 5. Restore order on the fresh machine
```
# install CachyOS (KDE Plasma), mount the NAS, clone or copy dotfiles, then:
cd ~/dotfiles && ./fresh-start.sh      # pick  E  (EVERYTHING BACK)
#   → installs packages, restores your whole home from the NAS, restores groups+services
```
Then **LOG OUT / REBOOT** (required for group changes — Razer, input-remapper), and
re-mount Plex for `~/Music`. If EQ music is silent, run `eq-fix`.

> The one thing outside all of this: files still living **only on the Windows
> partition** you're reclaiming — grab those with `drive-backup` before you wipe.
