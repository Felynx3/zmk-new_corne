#!/usr/bin/env bash

set -Eeuo pipefail

TARGET="${LOCAL_BUILD_TARGET:-all}"
WORKSPACE=/work
CONFIG_DIR="${WORKSPACE}/config"
OUTPUT_DIR=/output
BUILD_ROOT="${WORKSPACE}/build"

mkdir -p "${WORKSPACE}/home" "${BUILD_ROOT}" "${OUTPUT_DIR}/diagnostics"

# Use a fresh copy so removed or renamed config files cannot linger between builds.
rm -rf "${CONFIG_DIR}"
mkdir -p "${CONFIG_DIR}"
cp -R /config-repo/config/. "${CONFIG_DIR}/"

cd "${WORKSPACE}"

if [[ ! -d .west ]]; then
    echo "Inicializando el workspace de west..."
    west init -l "${CONFIG_DIR}"
fi

echo "Actualizando ZMK, Zephyr y módulos..."
if [[ "${SKIP_WEST_UPDATE:-auto}" == "1" ]] || [[ "${SKIP_WEST_UPDATE:-auto}" == "auto" && -d zmk/app && -d zephyr && -d zmk-nice-oled ]]; then
    echo "Saltando west update; usando módulos ya descargados."
else
    west update --fetch-opt=--filter=tree:0
fi
west zephyr-export

build_firmware() {
    local id="$1"
    local artifact="$2"
    local board="$3"
    local shield="$4"
    local snippet="$5"
    shift 5

    local build_dir="${BUILD_ROOT}/${id}"
    local pristine=always

    local -a command=(
        west build
        -s zmk/app
        -d "${build_dir}"
        -p "${pristine}"
        -b "${board}"
    )

    if [[ -n "${snippet}" ]]; then
        command+=(-S "${snippet}")
    fi

    command+=(
        --
        "-DZMK_CONFIG=${CONFIG_DIR}"
        "-DZMK_EXTRA_MODULES=/config-repo"
        "-DSHIELD=${shield}"
        "$@"
    )

    echo
    echo "=== Compilando ${id} ==="
    "${command[@]}"

    cp "${build_dir}/zephyr/zmk.uf2" "${OUTPUT_DIR}/${artifact}.uf2"
    cp "${build_dir}/zephyr/.config" "${OUTPUT_DIR}/diagnostics/${id}.config"

    if [[ -f "${build_dir}/zephyr/zephyr.dts" ]]; then
        cp "${build_dir}/zephyr/zephyr.dts" "${OUTPUT_DIR}/diagnostics/${id}.dts"
    fi
}

case "${TARGET}" in
    all | right)
        build_firmware \
            right \
            "eyelash_corne_right-nice_nano_v2-zmk" \
            nice_nano_v2 \
            "eyelash_corne_right nice_oled" \
            ""
        ;;
esac

case "${TARGET}" in
    all | left)
        build_firmware \
            left \
            eyelash_corne_studio_left \
            nice_nano_v2 \
            "eyelash_corne_left nice_oled" \
            studio-rpc-usb-uart \
            -DCONFIG_ZMK_STUDIO=y \
            -DCONFIG_ZMK_STUDIO_LOCKING=n
        ;;
esac

case "${TARGET}" in
    all | reset)
        build_firmware \
            reset \
            settings_reset-nice_nano_v2-zmk \
            nice_nano_v2 \
            settings_reset \
            ""
        ;;
esac

echo
echo "Compilación terminada:"
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.uf2' -print
