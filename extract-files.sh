#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=fuxi
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        odm/bin/hw/vendor.nxp.hardware.nfc@2.0-service)
            "${PATCHELF}" --add-needed "libbase_shim.so" "$2"
	    ;;
        odm/etc/camera/enhance_motiontuning.xml | odm/etc/camera/night_motiontuning.xml | odm/etc/camera/motiontuning.xml)
            sed -i 's/<?xml=/<?xml /g' "${2}"
            ;;
        odm/lib64/hw/camera.xiaomi.so)
            "${PATCHELF}" --add-needed "libprocessgroup_shim.so" "$2"
            "${PATCHELF}" --add-needed "libui-v34.so" "${2}"
            ;;
        odm/lib64/hw/displayfeature.default.so)
            "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            ;;
        odm/lib64/libailab_rawhdr.so | odm/lib64/libxmi_high_dynamic_range_cdsp.so)
            "${ANDROID_ROOT}"/prebuilts/clang/host/linux-x86/clang-r475365b/bin/llvm-strip --strip-debug "${2}"
            ;;
        odm/lib64/libcamxcommonutils.so | odm/lib64/hw/com.qti.chi.override.so | odm/lib64/libchifeature2.so | odm/lib64/libmialgoengine.so)
            "${PATCHELF}" --add-needed "libprocessgroup_shim.so" "$2"
            ;;
        odm/lib64/libmt@1.3.so)
            "${PATCHELF}" --replace-needed "libcrypto.so" "libcrypto-v33.so" "${2}"
            ;;
        odm/lib64/libaudioroute_ext.so | vendor/lib64/libar-pal.so | vendor/lib64/libagm.so)
            "${PATCHELF}" --replace-needed "libaudioroute.so" "libaudioroute-v34.so" "${2}"
            ;;
        system/priv-app/MiuiCamera/MiuiCamera.apk)
            tmp_dir="${EXTRACT_TMP_DIR}/MiuiCamera"
            mkdir -p "$tmp_dir"

            if [ ! -f "$2" ]; then
                echo "Error: File $2 does not exist."
                exit 1
            fi

            java -jar "${APKTOOL}" d -q "$2" -o "$tmp_dir" -f || {
                echo "Error running apktool."
                exit 1
            }

            if grep -rl "com.miui.gallery" "$tmp_dir"; then
                grep -rl "com.miui.gallery" "$tmp_dir" | xargs sed -i 's|"com.miui.gallery"|"com.google.android.apps.photos"|g'
            fi

            java -jar "${APKTOOL}" b -q "$tmp_dir" -o "$2" || {
                echo "Error rebuilding APK."
                exit 1
            }

            rm -rf "$tmp_dir"
            ;;
        vendor/bin/hw/android.hardware.security.keymint-service-qti | vendor/lib64/libqtikeymint.so)
            "${PATCHELF}" --add-needed android.hardware.security.rkp-V3-ndk.so "${2}"
            ;;
        vendor/bin/hw/vendor.dolby.hardware.dms@2.0-service | vendor/lib64/hw/audio.primary.kalama.so)
            "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini)
            sed -i '/^gMaxConcurrentActiveSessions=4$/a sae_enabled=1' "${2}"
            ;;
        vendor/etc/gps.conf)
            sed -i 's/com\.lbe\.security\.miui/com\.google\.android\.carrierlocation/g' "${2}"
            ;;
        vendor/etc/qcril_database/upgrade/config/6.0_config.sql)
            sed -i '/persist.vendor.radio.redir_party_num/ s/true/false/g' "${2}"
            ;;
        vendor/etc/seccomp_policy/atfwd@2.0.policy | vendor/etc/seccomp_policy/modemManager.policy | vendor/etc/seccomp_policy/wfdhdcphalservice.policy)
            [ "$2" = "" ] && return 0
            [ -n "$(tail -c 1 "${2}")" ] && echo >> "${2}"
            grep -q "gettid: 1" "${2}" || echo "gettid: 1" >> "${2}"
            ;;
        vendor/etc/seccomp_policy/c2audio.vendor.ext-arm64.policy)
            [ "$2" = "" ] && return 0
            [ -n "$(tail -c 1 "${2}")" ] && echo >> "${2}"
            grep -q "setsockopt: 1" "${2}" || echo "setsockopt: 1" >> "${2}"
            ;;
        vendor/etc/seccomp_policy/qwesd@2.0.policy)
            # Remove trailing newline
            sed -i '$ d' "$2"

            # Append "gettid: 1" and "pipe2: 1"
            {
                echo "gettid: 1"
                echo "pipe2: 1"
            } >> "$2"
            ;;
        vendor/lib64/c2.dolby.client.so)
            "${PATCHELF}" --add-needed "libcodec2_hidl_shim.so" "${2}"
            ;;
        vendor/bin/hw/dolbycodec2 | vendor/bin/hw/vendor.dolby.media.c2@1.0-service | vendor/lib64/c2.dolby.hevc.dec.so | vendor/lib64/c2.dolby.hevc.enc.so | vendor/lib64/c2.dolby.hevc.sec.dec.so | vendor/lib64/libDecoderProcessor.so | vendor/lib64/libdlbdsservice.so | vendor/lib64/libdlbpreg.so | vendor/lib64/libswspatializer_ext.so | vendor/lib64/soundfx/libdlbvol.so | vendor/lib64/soundfx/libhwdap.so | vendor/lib64/soundfx/libswspatializer.so)
            "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/lib64/libqcodec2_core.so)
            "${PATCHELF}" --add-needed "libcodec2_shim.so" "${2}"
            ;;
        vendor/lib64/vendor.libdpmframework.so)
            "${PATCHELF}" --add-needed "libhidlbase_shim.so" "${2}"
            "${PATCHELF}" --add-needed "libbinder_shim.so" "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
