#!/bin/bash
# =============================================================================
# fresh-start.sh — rebuild this machine after a wipe (CachyOS + KDE Plasma)
# =============================================================================
# TWO ways to run it:
#
#   E) EVERYTHING BACK (uses your NAS backup) — recommended:
#        packages → restore your whole home from NAS → groups + services
#      Brings back data, configs, soundfont, keys, .claude, AND the system-level
#      bits (group memberships like `plugdev` for the Razer Naga, `input` for
#      input-remapper, and every service you had enabled).
#
#   C) CLEAN REBUILD (from the git dotfiles, cherry-pick data yourself):
#        packages → stow configs → apps (Anchovy) → services → groups
#
# Individual stages (flags): --packages --restore --configs --apps --system
#   --services   |   --everything (=E)   |   --clean / --all (=C)
# No args = interactive menu. Each stage is idempotent and safe to re-run.
# The NAS backup + system-state snapshot come from `pre-wipe-backup`.
# =============================================================================

set -u
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES"
NAS="/mnt/unraid-backup/CachyOS-FreshStart"

# Keep in sync with install.sh
STOW_PACKAGES=(
    kde autostart fluidsynth scripts shell terminal
    browser fetch input-remapper launcher music newsboat wallust yazi yt-dlp
    mako sway waybar wlogout
)

hr(){ printf '\n\033[1m=== %s ===\033[0m\n' "$1"; }
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$1"; }

# -----------------------------------------------------------------------------
stage_packages() {
    hr "Packages"
    command -v paru >/dev/null 2>&1 || { warn "paru not found — CachyOS ships it; install paru, then re-run."; return 0; }
    [ -f "$DOTFILES/package-list.txt" ] || { warn "package-list.txt missing"; return 0; }
    local n; n=$(grep -vcE '^[[:space:]]*(#|$)' "$DOTFILES/package-list.txt")
    echo "  Installing $n packages (native + AUR) via paru --needed…"
    grep -vE '^[[:space:]]*(#|$)' "$DOTFILES/package-list.txt" | paru -S --needed - \
        && ok "packages installed" || warn "some packages failed — review output above"
}

# -----------------------------------------------------------------------------
stage_restore() {
    hr "Restore home from NAS  (data, configs, soundfont, keys, .claude)"
    findmnt /mnt/unraid-backup >/dev/null 2>&1 || { warn "NAS not mounted — run: sudo mount /mnt/unraid-backup"; return; }
    [ -d "$NAS/home" ] || { warn "no home backup at $NAS/home (run pre-wipe-backup first)"; return; }
    echo "  Source: $NAS/home  ($(du -sh "$NAS/home" 2>/dev/null | cut -f1))"
    echo "  Copies your ENTIRE home back to ~ (keeps the current ~/dotfiles you're running from)."
    read -rp "  Proceed? [y/N] " a; [[ "${a,,}" == y* ]] || { warn "skipped"; return; }
    rsync -aH --no-owner --no-group --no-D --info=progress2 --human-readable \
          --exclude '/dotfiles/' "$NAS/home/" "$HOME/" && ok "home restored"
    [ -f "$NAS/keys/ssh.tar.gz" ]   && { tar xzf "$NAS/keys/ssh.tar.gz"   -C "$HOME"; chmod 700 ~/.ssh 2>/dev/null; chmod 600 ~/.ssh/* 2>/dev/null; ok "ssh keys (perms fixed)"; }
    [ -f "$NAS/keys/gnupg.tar.gz" ] && { tar xzf "$NAS/keys/gnupg.tar.gz" -C "$HOME"; chmod 700 ~/.gnupg 2>/dev/null; ok "gnupg keys"; }
}

# -----------------------------------------------------------------------------
stage_configs() {
    hr "Configs (stow — clean path only)"
    mkdir -p ~/.config ~/.local/bin ~/.local/share \
             ~/.local/share/qutebrowser ~/.local/share/vicinae/themes ~/.local/share/aurorae/themes \
             ~/Videos/ytdlp ~/Pictures/Wallpapers/Catppuccin ~/Videos/Wallpapers/Catppuccin
    command -v stow >/dev/null 2>&1 || { warn "stow not installed — run packages first"; return 0; }
    for pkg in "${STOW_PACKAGES[@]}"; do
        [ -d "$DOTFILES/$pkg" ] || continue
        if stow -R "$pkg" 2>/dev/null; then ok "stowed $pkg"
        else warn "$pkg has conflicts (existing non-symlink files) — resolve by hand"; fi
    done
    chmod +x ~/.local/bin/* 2>/dev/null || true
}

# -----------------------------------------------------------------------------
stage_apps() {
    hr "Apps & assets"
    [ -d "$DOTFILES/assets" ] && { mkdir -p ~/Pictures/nzxt && cp "$DOTFILES/assets/"* ~/Pictures/nzxt/ 2>/dev/null && ok "assets"; }
    local src="$HOME/anchovy"
    [ -d "$src/.git" ] || { git clone https://github.com/taubut/Anchovy.git "$src" && ok "cloned Anchovy" || warn "anchovy clone failed"; }
    if [ -f "$src/install.sh" ]; then
        ( cd "$src" && bash install.sh ) >/dev/null 2>&1 && ok "anchovy installed" || warn "anchovy install failed"
        mkdir -p ~/.local/share/anchovy
        cp "$DOTFILES/extras/anchovy/config.json"  ~/.local/share/anchovy/ 2>/dev/null && ok "anchovy settings" || true
        cp "$DOTFILES/extras/anchovy/learned.json" ~/.local/share/anchovy/ 2>/dev/null || true
    fi
    command -v ya >/dev/null 2>&1 && { ya pkg add yazi-rs/flavors:catppuccin-macchiato 2>/dev/null && ok "yazi flavor" || true; }
    if command -v lutgen >/dev/null 2>&1 && [ ! -f ~/.local/share/lutgen/macchiato_lut.png ]; then
        mkdir -p ~/.local/share/lutgen
        lutgen generate -p catppuccin-macchiato -o ~/.local/share/lutgen/macchiato_lut.png 2>/dev/null && ok "lutgen LUT" || true
    fi
}

# -----------------------------------------------------------------------------
stage_system() {
    hr "System — groups & services (Razer Naga, input-remapper, etc.)"
    local ST="$NAS/system-state"
    [ -d "$ST" ] || { warn "no system-state snapshot at $ST (run the latest pre-wipe-backup)"; return; }

    # 1) group memberships — plugdev (Razer), input (input-remapper), etc.
    if [ -f "$ST/groups.txt" ]; then
        local added=0
        for g in $(cat "$ST/groups.txt"); do
            [ "$g" = "$USER" ] && continue
            getent group "$g" >/dev/null 2>&1 || continue
            id -nG "$USER" | tr ' ' '\n' | grep -qx "$g" && continue
            sudo usermod -aG "$g" "$USER" 2>/dev/null && { echo "  + group: $g"; added=1; }
        done
        [ "$added" = 1 ] && ok "groups restored — LOG OUT/IN for them to take effect" || ok "already in all your groups"
    fi

    # 2) user services you had enabled (fluidsynth, etc.)
    if [ -f "$ST/services-user.txt" ]; then
        systemctl --user daemon-reload 2>/dev/null || true
        while read -r u; do [ -n "$u" ] && systemctl --user enable "$u" 2>/dev/null; done < "$ST/services-user.txt"
        ok "user services re-enabled"
    fi

    # 3) system services you had enabled (input-remapper, openrazer-daemon, …) — needs sudo
    if [ -f "$ST/services-system.txt" ]; then
        while read -r u; do [ -n "$u" ] && sudo systemctl enable "$u" 2>/dev/null; done < "$ST/services-system.txt"
        ok "system services re-enabled"
    fi

    echo "  Razer Naga: needs the openrazer driver+daemon (in package-list) and the 'plugdev'"
    echo "  group above; your lighting/DPI profiles came back with your home restore."
    echo "  input-remapper: mappings are in ~/.config; its service was re-enabled above."
}

# -----------------------------------------------------------------------------
stage_services() {
    hr "Services (fluidsynth etc.)"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable fluidsynth.service 2>/dev/null && ok "fluidsynth enabled" || warn "fluidsynth.service not found (install fluidsynth)"
    [ -f ~/.config/systemd/user/vicinae.service ] && { systemctl --user enable vicinae 2>/dev/null && ok "vicinae enabled"; }
    [ -f ~/.config/systemd/user/catppuccin-watcher.service ] && { systemctl --user enable catppuccin-watcher 2>/dev/null && ok "catppuccin-watcher enabled"; }
}

final_notes() {
    hr "Done!"
    cat <<'EOF'
  Next:
    1. LOG OUT / REBOOT — required for group changes (Razer 'plugdev', input-remapper 'input')
    2. Check the Naga (lighting/DPI) and input-remapper mappings
    3. Bind Meta+Space → anchovy-toggle if the KDE shortcut didn't carry
    4. EQ music silent? run 'eq-fix'.  Audio odd after aux swap? run 'beacn-fix'.
EOF
}

run_everything(){ stage_packages; stage_restore; stage_system; final_notes; }   # E — from NAS
run_clean(){      stage_packages; stage_configs; stage_apps; stage_services; stage_system; final_notes; }  # C — from git

menu() {
    while true; do
        cat <<EOF

  ┌─ fresh-start ──────────────────────────────────────────────┐
  │  E) EVERYTHING BACK  packages → restore home (NAS) → system │
  │  C) CLEAN REBUILD    packages → stow → apps → services      │
  │  ── individual stages ──                                    │
  │  1) packages   2) restore-from-NAS   3) configs (stow)      │
  │  4) apps       5) system (groups+svc) 6) services           │
  │  Q) quit                                                    │
  └────────────────────────────────────────────────────────────┘
  For a full restore after a wipe: run E (reboot when it says to).
EOF
        read -rp "  choose: " c
        case "${c,,}" in
            e) run_everything ;;
            c) run_clean ;;
            1) stage_packages ;;
            2) stage_restore ;;
            3) stage_configs ;;
            4) stage_apps ;;
            5) stage_system ;;
            6) stage_services ;;
            q|"") echo "  bye"; return 0 ;;
            *) warn "unknown choice: $c" ;;
        esac
    done
}

# ---- entry point ----
case "${1:-}" in
    --everything) run_everything ;;
    --clean|--all) run_clean ;;
    --packages) stage_packages ;;
    --restore)  stage_restore ;;
    --configs)  stage_configs ;;
    --apps)     stage_apps ;;
    --system)   stage_system ;;
    --services) stage_services ;;
    -h|--help)  sed -n '2,24p' "$0" ;;
    "")         menu ;;
    *)          echo "unknown arg: $1 (try --help)"; exit 2 ;;
esac
