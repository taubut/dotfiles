#!/bin/bash
# =============================================================================
# fresh-start.sh — staged installer for a fresh CachyOS + KDE Plasma machine
# =============================================================================
# Runs the restore in independent STAGES so steps don't overlap:
#
#   1) Packages  — install native + AUR from package-list.txt   (do this FIRST)
#   2) Configs   — create dirs + stow all dotfiles
#   3) Apps      — assets, Anchovy launcher, themes/plugins
#   4) Services  — enable fluidsynth + other systemd user services
#
# Recommended flow on a brand-new machine:
#   ./fresh-start.sh --packages   # then REBOOT (so the session/pipewire come up)
#   ./fresh-start.sh --all        # configs + apps + services (packages skipped if present)
# Or just run ./fresh-start.sh with no args for an interactive menu.
#
# Each stage is idempotent and safe to re-run. See WIPE-CHECKLIST.md for things
# this can't restore (soundfont, ~/Faugus games, keys) — back those up first.
# =============================================================================

set -u
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES"

# Keep in sync with install.sh
STOW_PACKAGES=(
    kde              # KDE Plasma — primary DE
    autostart        # ~/.config/autostart (beacn-utility, mpd-mpris, ghostty, ...)
    fluidsynth       # MIDI synth config + systemd override (EQ music)
    scripts          # ~/.local/bin scripts (incl. eq-fix, beacn-fix)
    shell terminal
    browser fetch input-remapper launcher music newsboat wallust yazi yt-dlp
    mako sway waybar wlogout   # secondary sway session
)

hr(){ printf '\n\033[1m=== %s ===\033[0m\n' "$1"; }
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$1"; }

# -----------------------------------------------------------------------------
stage_packages() {
    hr "STAGE 1 — Packages"
    if ! command -v paru >/dev/null 2>&1; then
        warn "paru not found. CachyOS ships it; install paru first, then re-run this stage."
        return 0
    fi
    if [ ! -f "$DOTFILES/package-list.txt" ]; then warn "package-list.txt missing"; return 0; fi
    local n; n=$(grep -vcE '^[[:space:]]*(#|$)' "$DOTFILES/package-list.txt")
    echo "  Installing $n packages (native + AUR) via paru --needed…"
    grep -vE '^[[:space:]]*(#|$)' "$DOTFILES/package-list.txt" | paru -S --needed - \
        && ok "packages installed" || warn "some packages failed — review output above"
    echo "  TIP: reboot now so the graphical session + PipeWire come up cleanly before Stage 4."
}

# -----------------------------------------------------------------------------
stage_configs() {
    hr "STAGE 2 — Configs (stow)"
    mkdir -p ~/.config ~/.local/bin ~/.local/share \
             ~/.local/share/qutebrowser ~/.local/share/vicinae/themes ~/.local/share/aurorae/themes \
             ~/Videos/ytdlp ~/Pictures/Wallpapers/Catppuccin ~/Videos/Wallpapers/Catppuccin
    command -v stow >/dev/null 2>&1 || { warn "stow not installed — run Stage 1 first"; return 0; }
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$DOTFILES/$pkg" ]; then
            if stow -R "$pkg" 2>/dev/null; then ok "stowed $pkg"
            else warn "$pkg has conflicts (existing non-symlink files) — resolve by hand"; fi
        fi
    done
    chmod +x ~/.local/bin/* 2>/dev/null || true
}

# -----------------------------------------------------------------------------
stage_apps() {
    hr "STAGE 3 — Apps & assets"
    # NZXT/conky assets
    if [ -d "$DOTFILES/assets" ]; then
        mkdir -p ~/Pictures/nzxt && cp "$DOTFILES/assets/"* ~/Pictures/nzxt/ 2>/dev/null && ok "assets copied"
    fi
    # Anchovy launcher (its own repo) + restore user settings
    local src="$HOME/anchovy"
    if [ ! -d "$src/.git" ]; then
        git clone https://github.com/taubut/Anchovy.git "$src" && ok "cloned Anchovy" || warn "anchovy clone failed"
    fi
    if [ -f "$src/install.sh" ]; then
        ( cd "$src" && bash install.sh ) >/dev/null 2>&1 && ok "anchovy installed" || warn "anchovy install failed"
        mkdir -p ~/.local/share/anchovy
        cp "$DOTFILES/extras/anchovy/config.json"  ~/.local/share/anchovy/ 2>/dev/null && ok "restored anchovy settings" || true
        cp "$DOTFILES/extras/anchovy/learned.json" ~/.local/share/anchovy/ 2>/dev/null || true
        warn "bind Meta+Space → 'anchovy-toggle' in KDE → Shortcuts → Custom Shortcuts"
    fi
    # themes/plugins
    command -v ya >/dev/null 2>&1 && { ya pkg add yazi-rs/flavors:catppuccin-macchiato 2>/dev/null && ok "yazi flavor" || true; }
    if command -v lutgen >/dev/null 2>&1 && [ ! -f ~/.local/share/lutgen/macchiato_lut.png ]; then
        mkdir -p ~/.local/share/lutgen
        lutgen generate -p catppuccin-macchiato -o ~/.local/share/lutgen/macchiato_lut.png 2>/dev/null && ok "lutgen LUT" || true
    fi
}

# -----------------------------------------------------------------------------
stage_services() {
    hr "STAGE 4 — Services"
    systemctl --user daemon-reload 2>/dev/null || true
    # fluidsynth renders EQ's MIDI music onto the Beacn Game dial (see AUDIO-FIXES.md).
    # PipeWire is CachyOS's default; Beacn Utility auto-starts via ~/.config/autostart.
    systemctl --user enable fluidsynth.service 2>/dev/null && ok "fluidsynth enabled" || warn "fluidsynth.service not found (install fluidsynth)"
    [ -f ~/.config/systemd/user/vicinae.service ] && { systemctl --user enable vicinae 2>/dev/null && ok "vicinae enabled"; }
    [ -f ~/.config/systemd/user/catppuccin-watcher.service ] && { systemctl --user enable catppuccin-watcher 2>/dev/null && ok "catppuccin-watcher enabled"; }
    echo "  If EQ music is silent later: restore the soundfont (WIPE-CHECKLIST.md), then run 'eq-fix'."
}

final_notes() {
    hr "Done!"
    cat <<'EOF'
  Next steps:
    1. Log out / reboot so everything applies
    2. Restore the fluidsynth soundfont (WIPE-CHECKLIST.md) or EQ music stays silent
    3. Bind Meta+Space → anchovy-toggle (KDE → Shortcuts → Custom Shortcuts)
    4. Set wallpaper; configure KDE panel/window rules
    5. qutebrowser: run :adblock-update

  Audio troubleshooting:  eq-fix   |   beacn-fix   (see AUDIO-FIXES.md)
EOF
}

run_all(){ stage_packages; stage_configs; stage_apps; stage_services; final_notes; }

menu() {
    while true; do
        cat <<EOF

  ┌─ fresh-start ────────────────────────────────────┐
  │  1) Packages   install native + AUR (do first)   │
  │  2) Configs    stow all dotfiles                 │
  │  3) Apps       assets, Anchovy, themes           │
  │  4) Services   enable fluidsynth + user services │
  │  A) All        run 1 → 4 in order                │
  │  Q) Quit                                         │
  └──────────────────────────────────────────────────┘
  Tip: on a brand-new box run 1, REBOOT, then 2/3/4 (or A).
EOF
        read -rp "  choose: " c
        case "${c,,}" in
            1) stage_packages ;;
            2) stage_configs ;;
            3) stage_apps ;;
            4) stage_services ;;
            a) run_all ;;
            q|"") echo "  bye"; return 0 ;;
            *) warn "unknown choice: $c" ;;
        esac
    done
}

# ---- entry point ----
case "${1:-}" in
    --packages) stage_packages ;;
    --configs)  stage_configs ;;
    --apps)     stage_apps ;;
    --services) stage_services ;;
    --all)      run_all ;;
    -h|--help)  sed -n '2,22p' "$0" ;;
    "")         menu ;;
    *)          echo "unknown arg: $1 (try --help)"; exit 2 ;;
esac
