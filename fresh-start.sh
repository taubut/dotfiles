#!/bin/bash
# =============================================================================
# fresh-start.sh — guided rebuild of this machine after a wipe (CachyOS + KDE)
# =============================================================================
# Run it and pick  R) REBUILD  to walk all 7 steps, verified, in order:
#   1) Packages        install from list; if any missed, offer to grab from cache
#   2) Configs         restore ALL configs exactly as they were (home + system)
#   3) Verify configs  confirm the important config files landed
#   4) Services        groups + systemd services enabled exactly as they were
#   5) Faugus/keybinds  Faugus config + KDE keybinds exactly as they were
#   6) Final check     one-look verification of everything before reboot
#   7) Borg backup     confirm the backup-to-unraid (Borg) script is ready
#
# You can also run any step alone: --packages --configs --verify --services
#   --faugus --check --borg    |   --rebuild = all 7.   No args = menu.
# Reads from the NAS backup at /mnt/unraid-backup/CachyOS-FreshStart.
# =============================================================================
set -u
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES"
NAS="/mnt/unraid-backup/CachyOS-FreshStart"
ST="$NAS/system-state"

hr(){ printf '\n\033[1m═══ %s ═══\033[0m\n' "$1"; }
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$1"; }
pause(){ read -rp $'\n  \033[2m[Enter] next step · Ctrl-C to stop\033[0m ' _; }
have_nas(){
  findmnt /mnt/unraid-backup >/dev/null 2>&1 && return 0
  echo "  Mounting the NAS…"
  command -v mount.nfs >/dev/null 2>&1 || { echo "  (installing nfs-utils first)"; sudo pacman -S --needed --noconfirm nfs-utils >/dev/null 2>&1; }
  sudo mkdir -p /mnt/unraid-backup
  sudo mount -t nfs 192.168.1.185:/mnt/user/CachyOSBackup /mnt/unraid-backup 2>/dev/null
  findmnt /mnt/unraid-backup >/dev/null 2>&1 && { ok "NAS mounted"; return 0; }
  warn "couldn't reach the NAS (192.168.1.185) — is your network up?"
  return 1
}

# ---------------------------------------------------------------------------
s0_chat() {
  hr "0 · Claude Code + THIS conversation — restored FIRST, usable right away"
  have_nas || return
  # Claude Code is a self-contained native install in ~/.local (history in ~/.claude), so we
  # bring the BINARY + history back straight from the home backup — no reinstall, works now.
  rsync -aR --no-owner --no-group --no-D --info=progress2 \
    "$NAS/home/./.local/share/claude" \
    "$NAS/home/./.local/bin/claude" \
    "$NAS/home/./.claude" \
    "$HOME/" 2>/dev/null && ok "Claude Code binary + history + memory restored"
  [ -f "$NAS/home/.claude.json" ] && cp "$NAS/home/.claude.json" "$HOME/" 2>/dev/null && ok "~/.claude.json restored"
  chmod +x ~/.local/bin/claude ~/.local/share/claude/versions/* 2>/dev/null || true
  if [ -e "$HOME/.local/bin/claude" ]; then
    ok "Ready NOW — launch it:   ~/.local/bin/claude    then type  /resume"
    ok "→ pick THIS conversation and follow the rest of the rebuild with me right beside you."
  else
    warn "claude not restored — reinstall: curl -fsSL https://claude.ai/install.sh | bash , then /resume"
  fi
}

# ---------------------------------------------------------------------------
s1_packages() {
  hr "1/7 · Packages"
  # A fresh CachyOS can ship without an AUR helper. Bootstrap paru FIRST — else
  # the install below is skipped entirely (and package-list.txt has AUR pkgs anyway).
  # This needs only the internet, NOT the NAS.
  if ! command -v paru >/dev/null 2>&1; then
    echo "  No AUR helper found — installing paru first…"
    sudo pacman -Sy --needed --noconfirm paru 2>/dev/null || {
      warn "paru not in the repos — building paru-bin from the AUR…"
      sudo pacman -S --needed --noconfirm git base-devel
      local t; t="$(mktemp -d)"
      git clone https://aur.archlinux.org/paru-bin.git "$t/paru-bin" && ( cd "$t/paru-bin" && makepkg -si --noconfirm )
      rm -rf "$t"
    }
  fi
  if command -v paru >/dev/null 2>&1 && [ -f "$DOTFILES/package-list.txt" ]; then
    echo "  Installing from package-list.txt (repo + AUR — no NAS needed)…"
    grep -vE '^[[:space:]]*(#|$)' "$DOTFILES/package-list.txt" | paru -S --needed - || warn "some installs failed — see above"
  else
    warn "couldn't get paru — install by hand:  paru -S --needed - < ~/dotfiles/package-list.txt"
  fi
  # what's in the list but did NOT install?
  local want got miss; want="$(mktemp)"; got="$(mktemp)"
  grep -vE '^[[:space:]]*(#|$)' "$DOTFILES/package-list.txt" 2>/dev/null | sort -u > "$want"
  pacman -Qq 2>/dev/null | sort -u > "$got"
  miss="$(comm -23 "$want" "$got")"; rm -f "$want" "$got"
  if [ -z "$miss" ]; then ok "every package from your list is installed"; return; fi
  warn "these packages did NOT install (maybe pulled from AUR, or renamed):"
  echo "$miss" | sed 's/^/      /'
  local cache="$NAS/root/var/cache/pacman/pkg"
  if [ -d "$cache" ]; then
    read -rp "  Install the missing ones from your cached .pkg backup? [y/N] " a
    if [[ "${a,,}" == y* ]]; then
      local p f
      for p in $miss; do
        f="$(ls "$cache/${p}-"*.pkg.tar.* 2>/dev/null | sort -V | tail -1)"
        [ -n "$f" ] && sudo pacman -U --noconfirm "$f" && ok "installed $p from cache" || warn "$p — no cached build found, install manually"
      done
    fi
  else
    warn "no pacman cache in the backup — install the missing ones by hand"
  fi
}

# ---------------------------------------------------------------------------
s2_configs() {
  hr "2/7 · Configs — restore exactly as they were"
  have_nas || return
  warn "KDE gotcha: Plasma REWRITES its configs on logout, so a restore done inside a"
  warn "running Plasma session gets clobbered when you log out — your theme won't stick."
  warn "For it to stick: run this step from a TTY (Ctrl+Alt+F3, log in, run fresh-start"
  warn "there), OR reboot IMMEDIATELY after without touching Plasma. Then log in fresh."
  read -rp "  Understood — continue the config restore? [y/N] " _a; [[ "${_a,,}" == y* ]] || { warn "skipped — re-run from a TTY"; return; }
  # home: all ~/.config, dotfiles data, etc. (keep the ~/dotfiles you're running from)
  if [ -d "$NAS/home" ]; then
    echo "  Restoring home configs/data from NAS…"
    rsync -a --no-owner --no-group --no-D --info=progress2 --human-readable --exclude '/dotfiles/' "$NAS/home/" "$HOME/" && ok "home restored"
  fi
  [ -f "$NAS/keys/ssh.tar.gz" ]   && { tar xzf "$NAS/keys/ssh.tar.gz"   -C "$HOME"; chmod 700 ~/.ssh 2>/dev/null; chmod 600 ~/.ssh/* 2>/dev/null; ok "ssh keys"; }
  [ -f "$NAS/keys/gnupg.tar.gz" ] && { tar xzf "$NAS/keys/gnupg.tar.gz" -C "$HOME"; chmod 700 ~/.gnupg 2>/dev/null; ok "gnupg keys"; }
  # dotfile configs via stow (symlinks the tracked ones)
  if command -v stow >/dev/null 2>&1; then
    for pkg in kde autostart fluidsynth scripts shell terminal browser fetch input-remapper launcher music newsboat wallust yazi yt-dlp mako sway waybar wlogout; do
      [ -d "$DOTFILES/$pkg" ] && stow -R "$pkg" 2>/dev/null
    done
    ok "dotfiles stowed"
  fi
  # custom SYSTEM config from the backup (safe, cherry-picked — not a blind /etc dump)
  if [ -d "$NAS/root" ]; then
    sudo cp -an "$NAS/root/usr/local/." /usr/local/ 2>/dev/null && ok "/usr/local scripts"
    [ -d "$NAS/root/etc/systemd/system" ]  && { sudo cp -n "$NAS/root/etc/systemd/system/"*.service /etc/systemd/system/ 2>/dev/null; ok "custom systemd units"; }
    [ -d "$NAS/root/etc/udev/rules.d" ]    && sudo cp -n "$NAS/root/etc/udev/rules.d/"*.rules /etc/udev/rules.d/ 2>/dev/null
    [ -d "$NAS/root/etc/NetworkManager/system-connections" ] && { sudo cp -rn "$NAS/root/etc/NetworkManager/system-connections" /etc/NetworkManager/ 2>/dev/null; sudo chmod 600 /etc/NetworkManager/system-connections/* 2>/dev/null; ok "WiFi connections"; }
    sudo systemctl daemon-reload 2>/dev/null || true
  fi
  chmod +x ~/.local/bin/* 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Plasma-only restore — for redoing JUST the theme from a TTY (Plasma not running)
# so it doesn't get clobbered. Small + fast (config files only).
s_plasma() {
  hr "Plasma theme — restore just the appearance files"
  have_nas || return
  if pgrep -x plasmashell >/dev/null 2>&1; then
    warn "Plasma is RUNNING — this will get overwritten when you log out."
    warn "For it to stick: log out → Ctrl+Alt+F3 (a TTY) → log in → run this → reboot."
    read -rp "  Run anyway? [y/N] " a; [[ "${a,,}" == y* ]] || { warn "skipped"; return; }
  fi
  local paths=(
    .config/kdeglobals .config/kwinrc .config/kwinrulesrc .config/plasmarc
    .config/plasmashellrc .config/plasma-org.kde.plasma.desktop-appletsrc
    .config/kglobalshortcutsrc .config/kactivitymanagerdrc .config/kscreenlockerrc
    .config/kdedefaults .config/gtk-3.0 .config/gtk-4.0 .gtkrc-2.0 .config/Kvantum
    .local/share/plasma .local/share/aurorae .local/share/color-schemes
    .local/share/icons .local/share/konsole
  )
  local p n=0
  for p in "${paths[@]}"; do
    [ -e "$NAS/home/$p" ] && rsync -aR --no-owner --no-group --no-D "$NAS/home/./$p" "$HOME/" 2>/dev/null && n=$((n+1))
  done
  ok "restored $n theme paths — now REBOOT and your look should be back"
}

# ---------------------------------------------------------------------------
# GitHub login — so 'git push' to your dotfiles works. (Cloning/reading never
# needs it since the repo is public.) Your gh token usually comes back with the
# home restore; this tops it up if it's missing/expired.
s_ghauth() {
  hr "GitHub login (for pushing dotfile edits back)"
  if ! command -v gh >/dev/null 2>&1; then warn "gh not installed yet — run step 1 (packages) first"; return; fi
  if gh auth status >/dev/null 2>&1; then
    ok "already logged in (your gh token came back with the home restore) — git push works"
    return
  fi
  echo "  Not logged in (token missing or expired). Launching 'gh auth login'…"
  echo "  Answer:  GitHub.com  →  HTTPS  →  Login with a web browser  → follow the on-screen code."
  read -rp "  Log in now? [y/N] " a; [[ "${a,,}" == y* ]] || { warn "skipped — run 'gh auth login' anytime"; return; }
  gh auth login
  if gh auth status >/dev/null 2>&1; then
    gh auth setup-git 2>/dev/null || true
    ok "logged in — you can now 'git push' to your dotfiles"
  else
    warn "login didn't complete — just re-run 'gh auth login' when ready"
  fi
}

# ---------------------------------------------------------------------------
s3_verify_configs() {
  hr "3/7 · Verify configs landed"
  local c miss=0
  for c in ~/.config/input-remapper-2 ~/.config/kglobalshortcutsrc ~/.config/ghostty \
           ~/.config/fish ~/.config/kdeglobals ~/.local/bin/eq-fix /usr/local/bin/numlock; do
    if [ -e "$c" ]; then ok "present: ${c/#$HOME/\~}"; else warn "MISSING: ${c/#$HOME/\~}"; miss=$((miss+1)); fi
  done
  [ "$miss" = 0 ] && ok "all key configs in place" || warn "$miss missing — re-run step 2 or restore from $NAS"
}

# ---------------------------------------------------------------------------
s4_services() {
  hr "4/7 · Systemd services + groups — exactly as they were"
  [ -d "$ST" ] || { warn "no system-state snapshot at $ST"; return; }
  if [ -f "$ST/groups.txt" ]; then
    local g added=0
    for g in $(cat "$ST/groups.txt"); do
      [ "$g" = "$USER" ] && continue; getent group "$g" >/dev/null 2>&1 || continue
      id -nG "$USER" | tr ' ' '\n' | grep -qx "$g" && continue
      sudo usermod -aG "$g" "$USER" 2>/dev/null && { echo "    + group $g"; added=1; }
    done
    [ "$added" = 1 ] && ok "groups restored (LOG OUT/IN to apply)" || ok "already in all your groups"
  fi
  systemctl --user daemon-reload 2>/dev/null || true
  if [ -f "$ST/services-user.txt" ]; then
    while read -r u; do [ -n "$u" ] && systemctl --user enable "$u" 2>/dev/null; done < "$ST/services-user.txt"
    ok "user services re-enabled ($(wc -l < "$ST/services-user.txt"))"
  fi
  if [ -f "$ST/services-system.txt" ]; then
    while read -r u; do [ -n "$u" ] && sudo systemctl enable "$u" 2>/dev/null; done < "$ST/services-system.txt"
    ok "system services re-enabled ($(wc -l < "$ST/services-system.txt"))"
  fi
}

# ---------------------------------------------------------------------------
s5_faugus_keybinds() {
  hr "5/7 · Faugus + keybinds"
  [ -d "$HOME/Faugus" ] && ok "~/Faugus restored ($(du -sh "$HOME/Faugus" 2>/dev/null | cut -f1))" || warn "~/Faugus MISSING — re-run step 2 (home restore)"
  [ -d "$HOME/.config/faugus-launcher" ] && ok "faugus-launcher config restored" || warn "faugus-launcher config not found"
  if [ -f "$HOME/.config/kglobalshortcutsrc" ]; then
    ok "KDE keybinds (kglobalshortcutsrc) restored"
    grep -q anchovy "$HOME/.config/kglobalshortcutsrc" 2>/dev/null && ok "Meta+Space → anchovy binding present" || warn "re-bind Meta+Space → anchovy-toggle (KDE → Shortcuts)"
  else
    warn "kglobalshortcutsrc MISSING — keybinds not restored; re-run step 2"
  fi
  command -v faugus-launcher >/dev/null 2>&1 && ok "faugus-launcher installed" || warn "install faugus-launcher (in package-list)"
}

# ---------------------------------------------------------------------------
s7_borg() {
  hr "7/7 · Borg backup (backup-to-unraid) ready?"
  command -v borg >/dev/null 2>&1 && ok "borg installed" || warn "borg NOT installed → paru -S borg"
  [ -x "$HOME/.local/bin/backup" ] && ok "backup script present (~/.local/bin/backup)" || warn "backup script missing → re-run step 2 (stows scripts)"
  findmnt /mnt/unraid-backup >/dev/null 2>&1 && ok "Unraid mounted (backup target reachable)" || warn "mount /mnt/unraid-backup (add to /etc/fstab)"
  [ -d /mnt/unraid-backup/borg-repo ] && ok "Borg repo exists (/mnt/unraid-backup/borg-repo)" || warn "no Borg repo yet → 'borg init --encryption=repokey /mnt/unraid-backup/borg-repo'"
  command -v kdialog >/dev/null 2>&1 && ok "kdialog present (script's password prompt works)" || warn "install kdialog (the backup script uses it)"
  echo "    → Test it: run 'backup' (prompts for your Borg passphrase — keep that safe!)"
}

# ---------------------------------------------------------------------------
s6_final_check() {
  hr "6/7 · Final check — review before reboot"
  printf "  %-26s %s\n" "packages installed:"      "$(pacman -Qq 2>/dev/null | wc -l)"
  printf "  %-26s %s\n" "your groups:"             "$(id -nG)"
  printf "  %-26s %s\n" "enabled user services:"   "$(systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)"
  printf "  %-26s %s\n" "~/Faugus:"                "$([ -d ~/Faugus ] && echo present || echo MISSING)"
  printf "  %-26s %s\n" "input-remapper config:"   "$([ -d ~/.config/input-remapper-2 ] && echo present || echo MISSING)"
  printf "  %-26s %s\n" "KDE keybinds:"            "$([ -f ~/.config/kglobalshortcutsrc ] && echo present || echo MISSING)"
  printf "  %-26s %s\n" "soundfont (EQ music):"    "$([ -d ~/.local/share/soundfonts ] && echo present || echo MISSING)"
  printf "  %-26s %s\n" "/usr/local custom bins:"  "$([ -e /usr/local/bin/numlock ] && echo present || echo MISSING)"
  printf "  %-26s %s\n" "Borg script:"             "$([ -x ~/.local/bin/backup ] && echo present || echo MISSING)"
  echo "  ─────────────────────────────────────────────"
  echo "  If everything above looks right: LOG OUT / REBOOT (needed for group + service changes)."
}

# ---------------------------------------------------------------------------
rebuild() {
  s0_chat;            pause
  s1_packages;        pause
  s2_configs;         pause
  s_ghauth;           pause
  s3_verify_configs;  pause
  s4_services;        pause
  s5_faugus_keybinds; pause
  s6_final_check;     pause
  s7_borg
  hr "Rebuild complete"
  echo "  REBOOT now (don't just log out of a Plasma session you customized — it can"
  echo "  overwrite the restored Plasma/theme configs). After reboot your desktop, window"
  echo "  decorations, colors, panel + icons should all be back."
  echo "  EQ music silent? run 'eq-fix'. Audio odd after an aux swap? 'beacn-fix'."
}

menu() {
  while true; do
    cat <<EOF

  ┌─ fresh-start · rebuild ─────────────────────────────────────┐
  │  R) REBUILD — guided, all steps in order (recommended)      │
  │  ── or a single step ──                                     │
  │  0) chat history (get back to this convo FIRST)            │
  │  1) packages    2) configs      3) verify configs          │
  │  4) services    5) faugus/keybinds                          │
  │  6) final check 7) borg backup                              │
  │  Q) quit                                                    │
  └─────────────────────────────────────────────────────────────┘
EOF
    read -rp "  choose: " c
    case "${c,,}" in
      r) rebuild ;;
      0) s0_chat ;;
      1) s1_packages ;; 2) s2_configs ;; 3) s3_verify_configs ;;
      4) s4_services ;; 5) s5_faugus_keybinds ;;
      6) s6_final_check ;; 7) s7_borg ;;
      p) s_plasma ;;
      g) s_ghauth ;;
      q|"") echo "  bye"; return 0 ;;
      *) warn "unknown choice: $c" ;;
    esac
  done
}

case "${1:-}" in
  --rebuild)  rebuild ;;
  --chat)     s0_chat ;;
  --packages) s1_packages ;;
  --configs)  s2_configs ;;
  --verify)   s3_verify_configs ;;
  --services) s4_services ;;
  --plasma)   s_plasma ;;
  --gh)       s_ghauth ;;
  --faugus)   s5_faugus_keybinds ;;
  --check)    s6_final_check ;;
  --borg)     s7_borg ;;
  -h|--help)  sed -n '2,20p' "$0" ;;
  "")         menu ;;
  *)          echo "unknown arg: $1 (try --help)"; exit 2 ;;
esac
