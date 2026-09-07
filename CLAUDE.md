# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A ZMK firmware **config repository** for a custom split keyboard ("Eyelash Peripherals" Corne clone, board `eyelash_corne`). It is not the ZMK source tree itself — `west.yml` pulls in ZMK core plus several custom modules (OLED display, BLE management, runtime input processor, battery history, runtime sensor rotate for encoders) from forked remotes (`cormoran`, `mctechnology17`). There is no application source code to build/lint/test in the traditional sense; "building" means compiling firmware via west/Zephyr.

## Build commands

GitHub Actions builds are **disabled** (`.github/workflows/build.yml.disabled` / `draw.yml.disabled` — rename to `.yml` to re-enable). Building is local-only via Docker, using `zmkfirmware/zmk-build-arm:stable`:

```sh
./scripts/build-local.sh all     # build left, right, and settings-reset UF2s
./scripts/build-local.sh left
./scripts/build-local.sh right
./scripts/build-local.sh reset
```

Equivalent VS Code tasks/launch configs exist ("ZMK: Build all/left/right/settings reset UF2 (Docker)"); "Build all" is the default build task.

- Output UF2s land in `firmware-local/`; effective Kconfig/Devicetree diagnostics are written to `firmware-local/diagnostics/`.
- Downloaded west projects and incremental build state are cached in `.zmk-local/` (gitignored) — delete it for a fully clean rebuild.
- Override the Docker image/platform with `ZMK_DOCKER_IMAGE` / `ZMK_DOCKER_PLATFORM` env vars if needed (default `linux/amd64`).
- The build script takes a lock (`.zmk-local/.build-lock`) so only one build runs at a time.

There is no separate lint/test suite in this repo; correctness is validated by whether the firmware builds and by manual keymap testing on hardware.

## Keymap diagram

`config/eyelash_corne.keymap` is rendered to `keymap-drawer/eyelash_corne.svg`/`.yaml` by the (currently disabled) `draw.yml` GitHub Action using `keymap_drawer.config.yaml`, on pushes touching `config/**`. Since CI is disabled, regenerate this manually (via the `keymap-drawer` CLI) after keymap edits if the diagram needs to stay in sync — it's referenced from the README.

## Repo layout

- `config/west.yml` — the manifest: pins ZMK core (`cormoran` fork, `v0.3-branch+dya`) and custom modules. Edit this to change ZMK version or add/remove modules.
- `config/eyelash_corne.keymap` — the actual keymap: layers, combos, macros, hold-taps, conditional (tri-)layers, encoder sensor bindings. This is the file most day-to-day edits touch.
- `config/eyelash_corne.conf` — Kconfig settings shared by both halves (RGB underglow, NKRO, debounce timing, OLED display, pointing/mouse emulation, idle/sleep timeouts).
- `boards/shields/eyelash_corne/` — the shield definition:
  - `eyelash_corne.dtsi` / `eyelash_corne-layouts.dtsi` — physical layout/matrix devicetree shared by both halves.
  - `eyelash_corne_left.overlay` / `_right.overlay` — per-half devicetree overlays.
  - `eyelash_corne_left.conf` / `_right.conf` — per-half Kconfig. **Left is the BLE central** and enables Studio, BLE management, runtime input processor, settings RPC, and runtime sensor rotate (all "Central only"); right is peripheral-only.
  - `Kconfig.shield` / `Kconfig.defconfig` — shield Kconfig plumbing.
- `build.yaml` — defines the three build matrix entries (left+oled, right+oled, settings_reset) that `scripts/build-local-container.sh` and the (disabled) CI workflow consume.
- `zephyr/module.yml` — marks this repo as a Zephyr module with `board_root: .`.
- `scripts/build-local.sh` / `build-local-container.sh` — Docker-based local build pipeline (host wrapper + in-container west build steps).
- `.zmk-local/`, `firmware-local/`, `.zmk-legacy/`, `build/`, `zmk/`, `modules/`, `.west/` — gitignored; downloaded sources and build artifacts, not tracked.

## Keymap architecture (`config/eyelash_corne.keymap`)

- **Layers** (indices defined via `#define`): `BASE`(0), `NUM`(1), `SYM`(2), `NAV`(3), `FUN`(4), `CONF`(5), `SHOOTER`(6), `LOL`(7). `SHOOTER`/`LOL` are game-specific alt layouts toggled independently of the base layer-tap stack.
- **Tri-layer**: holding `NUM`+`SYM` together activates `CONF` via `conditional_layers`.
- **Hold-taps**: `&lt` (layer-tap, 130ms, tap-preferred) and `&mt` (mod-tap, 250ms) are the global defaults; a custom `&ht` behavior wraps `&kp`/`ht_tap` (a one-param macro) for gaming-layer hold-tap-to-different-key bindings (e.g. `&ht TAB ESC`).
- **Combos**: chorded key positions trigger caps lock, delete, layer toggles (`SHOOTER`/`LOL`), soft-off (deep sleep), and direct BT profile selection (`BT_SEL 0/1/2`) — active across most/all layers via the `layers = <...>` field.
- **Encoders**: `sensor-bindings = <&rsr_arrows &rsr_trans>` per layer — `rsr_arrows` (custom `zmk,behavior-runtime-sensor-rotate`) sends UP/DOWN on rotate, `rsr_trans` passes through to whatever the base layer defines (used on the second encoder for volume/mute in `CONF`).
- **Pointer emulation**: `NUM`/`SYM`/`NAV` layers include `&mmv`/`mkp`/`C_MUTE` bindings for mouse movement/click/scroll (`ZMK_POINTING_DEFAULT_MOVE_VAL`/`SCRL_VAL` at the top of the file tune sensitivity).
- When adding/moving keys, key-position combo indices (`key-positions = <...>`) are matrix positions, not layer-relative — cross-check against `eyelash_corne-layouts.dtsi` if the physical layout changes.

## Language note

README/README_EN and some `.conf` comments are bilingual (Chinese/English); keep both READMEs in sync if user-facing behavior changes.
