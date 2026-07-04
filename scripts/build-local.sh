#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TARGET="${1:-all}"
IMAGE="${ZMK_DOCKER_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
PLATFORM="${ZMK_DOCKER_PLATFORM:-linux/amd64}"
DOCKER_BIN="${ZMK_DOCKER_BIN:-}"

case "${TARGET}" in
    all | left | right | reset) ;;
    *)
        echo "Uso: $0 [all|left|right|reset]" >&2
        exit 2
        ;;
esac

if [[ -z "${DOCKER_BIN}" ]]; then
    if command -v docker >/dev/null 2>&1; then
        DOCKER_BIN="$(command -v docker)"
    elif [[ -x /Applications/Docker.app/Contents/Resources/bin/docker ]]; then
        DOCKER_BIN=/Applications/Docker.app/Contents/Resources/bin/docker
    fi
fi

if [[ -z "${DOCKER_BIN}" ]]; then
    echo "No se encontró Docker. Instala y abre Docker Desktop antes de compilar." >&2
    exit 1
fi

if ! "${DOCKER_BIN}" info >/dev/null 2>&1; then
    echo "Docker está instalado, pero el motor no está activo. Abre Docker Desktop." >&2
    exit 1
fi

mkdir -p "${REPO_DIR}/.zmk-local" "${REPO_DIR}/firmware-local"

LOCK_DIR="${REPO_DIR}/.zmk-local/.build-lock"
if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    echo "Ya hay otra compilación ZMK usando .zmk-local. Espera a que termine." >&2
    exit 1
fi
trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT INT TERM

echo "Compilando '${TARGET}' con ${IMAGE} (${PLATFORM})..."

"${DOCKER_BIN}" run --rm \
    --platform "${PLATFORM}" \
    --user "$(id -u):$(id -g)" \
    --env HOME=/work/home \
    --env LOCAL_BUILD_TARGET="${TARGET}" \
    --volume "${REPO_DIR}:/config-repo:ro" \
    --volume "${REPO_DIR}/.zmk-local:/work" \
    --volume "${REPO_DIR}/firmware-local:/output" \
    "${IMAGE}" \
    bash /config-repo/scripts/build-local-container.sh

echo
echo "UF2 disponibles en: ${REPO_DIR}/firmware-local"
