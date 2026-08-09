#!/bin/bash

#set -eu

PKG_MODULES="${SYNOPKG_PKGDEST}/lib/modules"
DSM_MODULES="/usr/lib/modules"

PKG_NAME="TranscodeDrivers"
PKG_ROOT="/var/packages/${PKG_NAME}"
PKG_VERSION=$(synopkg version "$PKG_NAME")
DSM_MAJOR=$(get_key_value /etc.defaults/VERSION majorversion)
if [[ "$DSM_MAJOR" -gt "6" ]]; then
    LOG_DIR="${PKG_ROOT}/var"
else
    LOG_DIR="${PKG_ROOT}/etc"
fi
LOG_FILE="${LOG_DIR}/${PKG_NAME}.log"


log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOG_FILE}"
}

insmod_if_exists() {
    if [ -f "$1" ]; then
        if /sbin/insmod "$1" 2>>"${LOG_FILE}"; then
            log "Loaded $(basename "$1")"
            INSMOD_OK=$((INSMOD_OK + 1))
        else
            log "ERROR: Failed to load $(basename "$1")"
        fi
        INSMOD_TOTAL=$((INSMOD_TOTAL + 1))
    else
        log "Skipped $(basename "$1") (not found)"
    fi
    return 0
}

rmmod_if_loaded() {
    if /sbin/lsmod | grep -q "^${1} "; then
        if /sbin/rmmod "$1" 2>>"${LOG_FILE}"; then
            log "Unloaded ${1}"
            RMMOD_OK=$((RMMOD_OK + 1))
        else
            log "ERROR: Failed to unload ${1}"
        fi
        RMMOD_TOTAL=$((RMMOD_TOTAL + 1))
    else
        log "Skipped ${1} (not loaded)"
    fi
    return 0
}

load_pkg_modules() {
    log "Loading package driver modules"
    INSMOD_TOTAL=0
    INSMOD_OK=0
    RMMOD_TOTAL=0
    RMMOD_OK=0

    # Remove DSM's default modules (reverse load order)
    rmmod_if_loaded i915
    rmmod_if_loaded drm_kms_helper
    rmmod_if_loaded drm
    rmmod_if_loaded drm_panel_orientation_quirks
    rmmod_if_loaded i2c-algo-bit
    log "Unloaded ${RMMOD_OK}/${RMMOD_TOTAL} default modules successfully"

    # Load package modules
    insmod_if_exists "${PKG_MODULES}/i2c-algo-bit.ko"
    insmod_if_exists "${PKG_MODULES}/drm_panel_orientation_quirks.ko"
    insmod_if_exists "${PKG_MODULES}/dmabuf.ko"
    insmod_if_exists "${PKG_MODULES}/drm.ko"
    insmod_if_exists "${PKG_MODULES}/drm_kms_helper.ko"
    insmod_if_exists "${PKG_MODULES}/drm_display_helper.ko"
    insmod_if_exists "${PKG_MODULES}/drm_buddy.ko"
    insmod_if_exists "${PKG_MODULES}/ttm.ko"
    insmod_if_exists "${PKG_MODULES}/intel-gtt.ko"
    insmod_if_exists "${PKG_MODULES}/i915-compat.ko"
    insmod_if_exists "${PKG_MODULES}/i915.ko"
    log "Loaded ${INSMOD_OK}/${INSMOD_TOTAL} package modules successfully"
}

restore_dsm_modules() {
    log "Restoring default driver modules"
    INSMOD_TOTAL=0
    INSMOD_OK=0
    RMMOD_TOTAL=0
    RMMOD_OK=0

    # Remove package modules (reverse load order)
    rmmod_if_loaded i915
    rmmod_if_loaded i915-compat
    rmmod_if_loaded intel-gtt
    rmmod_if_loaded ttm
    rmmod_if_loaded drm_buddy
    rmmod_if_loaded drm_display_helper
    rmmod_if_loaded drm_kms_helper
    rmmod_if_loaded drm
    rmmod_if_loaded dmabuf
    rmmod_if_loaded drm_panel_orientation_quirks
    rmmod_if_loaded i2c-algo-bit
    log "Unloaded ${RMMOD_OK}/${RMMOD_TOTAL} package modules successfully"

    # Restore DSM's default modules
    insmod_if_exists "${DSM_MODULES}/i2c-algo-bit.ko"
    insmod_if_exists "${DSM_MODULES}/drm_panel_orientation_quirks.ko"
    insmod_if_exists "${DSM_MODULES}/drm.ko"
    insmod_if_exists "${DSM_MODULES}/drm_kms_helper.ko"
    insmod_if_exists "${DSM_MODULES}/i915.ko"
    log "Restored ${INSMOD_OK}/${INSMOD_TOTAL} default modules successfully"
}

case "$1" in
    start)
        echo " " >> "${LOG_FILE}"
        log "${PKG_NAME} starting"
        load_pkg_modules
        log "${PKG_NAME} started"
        exit 0
        ;;
    stop)
        echo " " >> "${LOG_FILE}"
        log "${PKG_NAME} stopping"
        restore_dsm_modules
        log "${PKG_NAME} stopped"
        exit 0
        ;;
esac
