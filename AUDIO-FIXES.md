# Audio fix scripts

Small recovery commands for my Beacn audio stack on CachyOS. They live in
[`scripts/.local/bin/`](scripts/.local/bin/) and are stowed to `~/.local/bin`,
so they're on `$PATH`.

Background: my sound runs **PipeWire → PipeWeaver (Beacn) virtual sinks →
Beacn Mic/Mix Create hardware**, and EverQuest's music is **MIDI** rendered by a
`fluidsynth` user service. A few things break in annoying, reboot-tempting
ways — these scripts fix each without a reboot.

---

## `eq-fix` — restore EverQuest Legends music

**Symptom:** sound *effects* work but *music* is silent (EQ music is MIDI).

**Cause:** `fluidsynth`'s audio output gets orphaned onto the dead
`BEACN Mix Create … mono-fallback` sink (or straight to the headphones sink),
instead of the `pipeweaver_game` node it should ride. Usually a boot-order race
(fluidsynth starts before the Beacn Utility has created the virtual nodes), or
fluidsynth re-negotiating mono↔stereo and letting PipeWire re-route it.

**Fix:**

```bash
eq-fix
```

It relinks `FluidSynth` → `pipeweaver_game` (handles mono *or* stereo), drops the
bad link, and prints the result. Idempotent — safe to run anytime.

There's also a permanent guard in the fluidsynth service so it waits for the
Game node at boot:
`~/.config/systemd/user/fluidsynth.service.d/override.conf` (an `ExecStartPre`
that polls `pw-cli ls Node` for `pipeweaver_game`). Tracked here in the
[`fluidsynth`](fluidsynth/) stow package.

---

## `beacn-fix` — recover sound after swapping the Beacn Mic's aux plug

**Symptom:** I swap what's plugged into the Beacn Mic's aux jack (speakers ↔
headphones) and **all** sound dies.

**Cause:** that aux port has **no jack detection**, so swapping it makes the
Beacn re-initialize on USB; the PipeWeaver/WirePlumber graph pinned to that node
doesn't cleanly re-bind. It *looks* like the port vanished. (USB autosuspend is
**not** the cause — both Beacn devices are `power/control=on`.) A reboot only
helps because it rebuilds the graph.

**Fix (confirmed: the default tier is all that's needed):**

```bash
beacn-fix            # restart WirePlumber + relink music (this is the fix)
beacn-fix --full     # also restart the Beacn Utility (rebuilds PipeWeaver sinks)
beacn-fix --reset    # also software-"replug" the mic via sudo usbreset
beacn-fix --dry-run  # preview any tier, change nothing
```

Escalate only if the previous tier didn't restore sound. Plain `beacn-fix`
restarts WirePlumber (which re-probes and rebinds the devices) and then calls
`eq-fix` to restore the music link the restart drops.

---

## `discord-fix` — Discord streams born muted (voice, or PTT/join/leave sounds)

**Symptom:** either *"my mic works but I can't hear anyone"*, or *"voice chat
is fine but the push-to-talk beep and join/leave sounds are silent"*.

**Cause:** Discord plays audio on **two separate PipeWire streams** — voice
rides `WEBRTC VoiceEngine`, while the UI/alert sounds (PTT beep, join/leave,
ringtone) ride the Electron `Chromium` stream. WirePlumber persists per-stream
mute in `~/.local/state/wireplumber/stream-properties`, so a stream that got
muted once (Plasma volume applet, pavucontrol, a stray dial press) is **reborn
muted on every launch**. Whichever of the two streams carries the saved mute
picks which symptom you get. The `Chromium` stream only exists for the
half-second a sound plays, so it can't be caught and unmuted live — the saved
state has to be edited with WirePlumber stopped (it rewrites the file on
shutdown, so edit-while-running gets clobbered).

**Fix:**

```bash
discord-fix          # unmute live streams; edit saved state only if needed
discord-fix --check  # diagnose only, change nothing
```

It unmutes any live Discord streams (and the `pipeweaver_discord` sink itself),
then checks the saved state; only if a saved mute remains does it stop
WirePlumber, flip the entry, and restart (≈2 s audio blip, then `eq-fix` to
restore the music link the restart drops). Idempotent — safe to run anytime.

Not this script's problem: Discord's own per-sound toggles (Settings →
Notifications → Sounds) and Streamer Mode's "Disable Sounds", which kicks in
when it thinks OBS is running.

---

## PipeWeaver startup order — no script needed

**Symptom:** the Beacn Utility opens but the Mix Create shows **"failed to
connect to pipeweaver"**. Sound still works; the device just never shows the
mix. Hit this immediately on a GNOME session, but the race existed on Plasma
too — I'd just been starting PipeWeaver manually early enough to win it.

**Cause:** `beacn-utility` was launched from `~/.config/autostart`, and nothing
started `pipeweaver-daemon` at all. XDG autostart gives no ordering guarantee,
so the utility came up, probed for PipeWeaver, found nothing, and **cached the
failure without ever retrying**. Starting PipeWeaver afterwards doesn't help —
the utility has to be restarted.

**Fix:** two user units in the [`beacn`](beacn/) stow package, replacing the
autostart entry.

- `pipeweaver.service` — runs `pipeweaver-daemon`, ordered after PipeWire (it
  builds its virtual sinks on top of it) and tied to `graphical-session.target`
  so it stops cleanly on logout rather than lingering between sessions.
- `beacn-utility.service` — `After=` + `Wants=pipeweaver.service`, **plus** an
  `ExecStartPre` that waits for the daemon's control port on `:14565` to accept
  connections. `After=` alone only orders process *start*, not readiness, which
  would not have fixed anything given the utility probes exactly once. Same
  shape as the fluidsynth `pipeweaver_game` guard above, and non-fatal for the
  same reason: after 30s it launches anyway rather than leaving no tray icon.

The autostart entry in [`autostart`](autostart/) carries `Hidden=true` so XDG
skips it and the utility isn't launched twice.

Stow only symlinks the units — enabling them is separate:

```bash
systemctl --user daemon-reload
systemctl --user enable --now pipeweaver.service beacn-utility.service
```

(`fresh-start.sh` stage 4 enables whatever is in `$NAS/system-state/services-user.txt`,
so this only needs doing by hand if the NAS restore isn't available.)

Being bound to `graphical-session.target` rather than anything desktop-specific,
this works the same under Plasma, GNOME, and sway.

**Caveat:** toggling autostart inside Beacn Utility's own settings may rewrite
that `.desktop` and wipe `Hidden=true`, giving two instances. Doubled tray icons
means that happened.

---

## Dependencies

- **PipeWire** tools: `wpctl`, `pw-link`, `pw-cli` (package `pipewire`) and
  `pactl` (package `libpulse`; for `discord-fix`)
- **fluidsynth** + a soundfont, running as the `fluidsynth` **user** service
  (for `eq-fix`)
- **beacn-utility** + **pipeweaver** — the Beacn-on-Linux stack that provides the
  `pipeweaver_*` sinks. Both now run as user units from the [`beacn`](beacn/)
  package (`pipeweaver.service`, `beacn-utility.service`), *not* the old
  generated `app-io.github.beacn_on_linux.beacn-utility@autostart.service`.
- **usbreset** — only for `beacn-fix --reset`

## Not tracked here (yet)

These make the scripts work but aren't in this repo — noted so I remember:

- The soundfont file itself (`~/.local/share/soundfonts/…`, large binary).
- `~/.config/pipeweaver/pipeweaver-profile.json` — the saved dial/mix state.
  Written by the daemon on exit, so it changes constantly; restored from the NAS
  backup rather than tracked here.
- Installing the packages themselves (`beacn-utility`, `pipeweaver`,
  `fluidsynth`) — that's `package-list.txt`'s job.

Both `~/.config/fluidsynth` and the `fluidsynth.service.d/override.conf`
boot-order guard *are* tracked now, in the [`fluidsynth`](fluidsynth/) package.
