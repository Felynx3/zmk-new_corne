# Local ZMK build with Docker

This repository can build the same three UF2 files as GitHub Actions without
installing `west`, Zephyr, or the ARM toolchain on the host.

## Requirement

Install and start Docker Desktop. The initial build downloads the
`zmkfirmware/zmk-build-arm:stable` image and all projects listed in
`config/west.yml`, so it takes longer than later builds.

## Visual Studio Code

Open **Run and Debug** and select one of:

- `ZMK: Build all UF2 (Docker)`
- `ZMK: Build left UF2 (Docker)`
- `ZMK: Build right UF2 (Docker)`
- `ZMK: Build settings reset UF2 (Docker)`

The same commands are available under **Tasks: Run Build Task**. Building all
firmware is the default build task.

## Terminal

```sh
./scripts/build-local.sh all
./scripts/build-local.sh left
./scripts/build-local.sh right
./scripts/build-local.sh reset
```

Generated files are written to `firmware-local/`. The effective Kconfig and
Devicetree files are saved under `firmware-local/diagnostics/`.

Downloaded source projects and incremental build outputs are cached in
`.zmk-local/`. Delete that directory when a completely clean workspace is
needed.

The Docker image and platform can be overridden when necessary:

```sh
ZMK_DOCKER_IMAGE=zmkfirmware/zmk-build-arm:stable \
ZMK_DOCKER_PLATFORM=linux/amd64 \
./scripts/build-local.sh all
```
