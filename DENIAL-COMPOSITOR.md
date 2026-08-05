# Denial compositor

[Denial](https://github.com/denialwm/denial) is a Flutter-native Wayland
compositor — Rust/Smithay owns the protocol and input, a Dart/Flutter shell owns
the visible desktop. Installed 2026-08-05 at **v0.2.5**.

It is **not** something layered on top of Plasma. On Wayland the compositor *is*
the window manager, so Denial sits exactly where KWin sits: it drives KMS, input,
and window management itself. It installs beside Plasma as another entry in the
SDDM session list, and switching is just a logout. Plasma is untouched.

Runs fine on the RTX 3080 — it picks `/dev/dri/card1` (nvidia) over the Intel
UHD 770 iGPU on its own.

---

## Install

```bash
curl -fsSL https://install.denialwm.org | sh
sudo pacman -Syu denial
```

The installer downloads a GPG key, pins its fingerprint
(`AE4108FA5E91E26BE0EE331E0F5B3AD16E023091`), adds it to the pacman keyring, and
appends a `[denial]` repo with `SigLevel = Required TrustedOnly`. No remote code
is executed. Packages: `denial` and `denial-flutter-engine`.

Preflight and status:

```bash
denial-session --check
denialctl status          # only works inside a running Denial session
```

---

## ⚠️ `/usr/bin/deniald` is patched locally

**Symptom after a `pacman -Syu`:** a second frozen mouse cursor appears at login,
and `Super+Space` / `Super+B` / `Super+Return` stop doing anything.

**Cause:** the update replaced my patched `deniald` with the stock one. Not a
regression — just the package overwriting a local build.

**Fix:** rebuild and reinstall. Takes about two minutes. The Flutter engine is
`dlopen`ed at runtime rather than linked, so there is **no** multi-hour engine
build — only the Rust compositor compiles.

```bash
git clone https://github.com/denialwm/denial.git ~/git-work/denial
cd ~/git-work/denial
git checkout v0.2.5                                    # match the installed version
git apply ~/dotfiles/DENIAL-COMPOSITOR.patch
cd compositor
cargo build --locked --release --features flutter --bin deniald
sudo cp -a /usr/bin/deniald /usr/bin/deniald.stock     # first time only
sudo install -m755 target/release/deniald /usr/bin/deniald
```

Then log out and back in. To back the patch out entirely:
`sudo pacman -S denial`.

Host build deps: Rust, `pkg-config`, Xwayland, `rtkit`, and the dev libraries for
Smithay's DRM, GBM/EGL, libinput, libseat, udev, and libxkbcommon backends.

### What the patch does

Two changes, both purely additive (~240 lines, no deletions), so it rebases onto
new Denial releases cheaply.

**1. Ghost cursor fix** — reported upstream as
[denialwm/denial#16](https://github.com/denialwm/denial/issues/16).

Denial draws its cursor as a Flutter asset inside the scene and never programs a
DRM hardware cursor plane. It also never disabled the planes it inherits on
takeover. SDDM's `kwin_wayland` greeter leaves its cursor latched on a cursor
plane, and the kernel keeps scanning that plane out above every Denial frame for
the whole session. Nothing in userspace can clear it — it survives killing every
client and survives Xwayland exiting.

The patch enumerates planes at startup, skips primary planes (the atlas owns
those), and issues one atomic commit zeroing `FB_ID`/`CRTC_ID` on any non-primary
plane still holding a framebuffer. `TEST_ONLY`-validated first and non-fatal
throughout.

**2. Spawn keybindings** — my own, *not* upstream. Denial's shortcuts are
compiled in with no config file. This adds a separate table of `Super`-chorded
bindings that launch a process, read from `~/.config/denial/keybinds.conf`, plus
SIGHUP reload. Built-in shortcuts are untouched and always win.

---

## Keybinds

**Built-in** (compiled into Denial, cannot be rebound):

| Binding | Action |
|---|---|
| `Super` (tap alone) | Applications view |
| `Super+K` | Close window |
| `Super+M` | Minimize |
| `Super+F` | Toggle fullscreen |
| `Super+Up` | Toggle maximize |
| `Super+Shift+Up` | Toggle vertical maximize |
| `Super+Tab` | Window switcher |
| `Super+A` | Overview |
| `Super+L` | Lock |
| `Super+V` | Clipboard |
| `Super+Escape` | Release pointer grab |

No Alt+F4. `Super+Escape` is the escape hatch when a game grabs the pointer.

**Mine**, from `~/.config/denial/keybinds.conf`:

```ini
Super+Space  = /home/taubut/.local/bin/anchovy
Super+B      = dolphin
Super+Return = ghostty
```

Format is `Super[+Shift]+<Key> = <command> [args...]`. Key names are positional
(US layout legends), matching how the compositor reads hardware. Commands are
exec'd directly, not through a shell — so **case matters** (`dolphin`, not
`Dolphin`) and there is no glob or variable expansion.

Apply changes without logging out:

```bash
denial-reload-keybinds
```

A small script in `~/.local/bin` that sends `SIGHUP` to `deniald`, which
re-parses the file in place. It reports what the compositor made of the file and
exits non-zero if any binding was rejected, so a typo tells you immediately.
Deliberately not in the `scripts` stow package — nothing here should end up in
the reinstall flow. Full source at the bottom of this note.

---

## Session bits Plasma normally provides

Most friction with Denial is not Denial's fault — it's that `XDG_CURRENT_DESKTOP=Denial`
matches nothing in software that keys off desktop identity. Plasma silently
provides a lot that a young compositor expects you to arrange.

### polkit agent

Without one, anything needing privilege escalation fails silently — input-remapper
was the first thing to hit it. `~/.config/systemd/user/polkit-kde-agent.service`:

```ini
[Unit]
Description=polkit-kde authentication agent
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/lib/polkit-kde-authentication-agent-1
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
```

```bash
systemctl --user enable --now polkit-kde-agent.service
```

Bound to `graphical-session.target` rather than anything Denial-specific, so it
covers sway/Hyprland too and sits idle under Plasma.

Also worth enabling so its GUI stops needing to elevate at all:
`sudo systemctl enable --now input-remapper`.

### xdg-desktop-portal routing

Every `.portal` file lists `UseIn=gnome`, `UseIn=KDE`, or
`UseIn=wlroots;sway;Wayfire;river;phosh;Hyprland` — Denial is in none of them.
The packaged `denial-portals.conf` routes everything to the GTK backend; when
that backend is unavailable, requests fall through to whichever backend D-Bus can
activate, and the KDE one's AppChooser throws a QML error and never records the
chosen app. Result: the "which media player?" dialog on *every* mp4 open.

`~/.config/xdg-desktop-portal/denial-portals.conf`:

```ini
[preferred]
default=kde
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.Secret=kwallet
org.freedesktop.impl.portal.Notification=plasmanotify
```

ScreenCast/Screenshot must stay on wlroots — Denial exposes `zwlr-screencopy-v1`,
which is what that backend consumes. Apply with
`systemctl --user restart xdg-desktop-portal.service`.

Note this was a *portal* problem, not a MIME one: `~/.config/mimeapps.list`
already had `video/mp4=mpv.desktop` under `[Default Applications]`, and
`xdg-mime query default video/mp4` resolved correctly the whole time.

### Session file gotcha

If Denial ever stops appearing in SDDM after an update, check the `NoExtract`
rules in `/etc/pacman.conf` before assuming it broke — that's what silently ate
the sway and Hyprland session files before.

---

## Nothing here is in the reinstall flow

Denial is deliberately kept out of `fresh-start.sh`, `install.sh`, and the stow
packages. It's an occasional session, not part of the machine's baseline, so a
wipe-and-restore leaves it alone entirely.

That means everything below lives only on the machine, and this note plus
[`DENIAL-COMPOSITOR.patch`](DENIAL-COMPOSITOR.patch) is the whole recovery path:

- `~/.config/denial/keybinds.conf` — reproduced above
- `~/.config/systemd/user/polkit-kde-agent.service` — reproduced above
- `~/.config/xdg-desktop-portal/denial-portals.conf` — reproduced above
- `~/.config/denial/outputs.conf` — regenerates itself on first run from
  `/etc/denial/outputs.conf`, nothing to save
- `~/.local/bin/denial-reload-keybinds` — full source below

### `denial-reload-keybinds`

```bash
#!/usr/bin/env bash
# Re-read ~/.config/denial/keybinds.conf in the running Denial session.
#
# Sends SIGHUP to deniald, which re-parses the file in place. Reports what the
# compositor made of it so parse errors surface here instead of only in the
# journal.
set -euo pipefail

if ! mapfile -t pids < <(pgrep -x deniald) || [[ ${#pids[@]} -eq 0 ]]; then
  echo "denial-reload-keybinds: deniald is not running" >&2
  exit 1
fi
if [[ ${#pids[@]} -gt 1 ]]; then
  echo "denial-reload-keybinds: found ${#pids[@]} deniald processes; using ${pids[-1]}" >&2
fi
pid="${pids[-1]}"

# Only report journal lines produced by this reload.
cursor="$(journalctl --user -n 0 --show-cursor -o cat 2>/dev/null \
  | sed -n 's/^-- cursor: //p')"

kill -HUP "$pid"

# Give the event loop a moment to service the signal and log the result.
sleep 0.3

if [[ -n "$cursor" ]]; then
  output="$(journalctl --user --after-cursor "$cursor" --no-pager -o cat 2>/dev/null \
    | grep -E 'spawn shortcuts|spawn shortcut' || true)"
else
  output="$(journalctl --user -n 30 --no-pager -o cat 2>/dev/null \
    | grep -E 'spawn shortcuts|spawn shortcut' || true)"
fi

if [[ -z "$output" ]]; then
  echo "Sent SIGHUP to deniald (pid $pid), but it logged nothing."
  echo "If shortcuts did not change, the running deniald may predate reload support."
  exit 1
fi

printf '%s\n' "$output"

# Any "ignoring" line means a binding was dropped, so exit non-zero to make the
# failure obvious in a pipeline or prompt.
if grep -q 'ignoring spawn shortcut' <<<"$output"; then
  echo
  echo "Some bindings were rejected; the lines above say why." >&2
  exit 1
fi
```
