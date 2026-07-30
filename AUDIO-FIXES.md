# Audio fix scripts

Two small recovery commands for my Beacn audio stack on CachyOS. Both live in
[`scripts/.local/bin/`](scripts/.local/bin/) and are stowed to `~/.local/bin`,
so they're on `$PATH`.

Background: my sound runs **PipeWire → PipeWeaver (Beacn) virtual sinks →
Beacn Mic/Mix Create hardware**, and EverQuest's music is **MIDI** rendered by a
`fluidsynth` user service. Two things break in annoying, reboot-tempting ways —
these scripts fix each without a reboot.

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
that polls `pw-cli ls Node` for `pipeweaver_game`). That config isn't tracked
here yet — see "Not tracked" below.

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

## Dependencies

- **PipeWire** tools: `wpctl`, `pw-link`, `pw-cli` (package `pipewire`)
- **fluidsynth** + a soundfont, running as the `fluidsynth` **user** service
  (for `eq-fix`)
- **beacn-utility** + **pipeweaver** — the Beacn-on-Linux stack that provides the
  `pipeweaver_*` sinks (Beacn Utility runs as user unit
  `app-io.github.beacn_on_linux.beacn-utility@autostart.service`)
- **usbreset** — only for `beacn-fix --reset`

## Not tracked here (yet)

These make the scripts work but aren't in this repo — noted so I remember:

- `~/.config/fluidsynth` (soundfont path + `-a pipewire -m alsa_seq`) and the
  `fluidsynth.service.d/override.conf` boot-order guard.
- The soundfont file itself (`~/.local/share/soundfonts/…`, large binary).
- Beacn Utility / PipeWeaver install + config.
