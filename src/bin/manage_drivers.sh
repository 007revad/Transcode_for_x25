#!/bin/bash

#set -eu

PKG_MODULES="${SYNOPKG_PKGDEST}/lib/modules"
DSM_MODULES="/usr/lib/modules"
i915_BINS="${SYNOPKG_PKGDEST}/lib/firmware"

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

# Desktop notification for a failed driver load, so users get a persistent
# alert (not just the log) pointing them at the Open window. Failure-only
# by design - no success notification, to avoid users learning to ignore it.
notify_load_failed() {
    if command -v synodsmnotify > /dev/null 2>&1; then
        synodsmnotify -c SYNO.SDS._ThirdParty.App.TranscodeDrivers @administrators TranscodeDrivers:app:title_failed TranscodeDrivers:app:load_failed 2>/dev/null || true
    fi
}

# bochs_drm is the emulated VGA driver used by Virtual Machine Manager
# guests (and possibly other virtualized DSM installs). If it's loaded
# it's actively driving that VM's display, so we don't touch the drm
# stack at all rather than risk disrupting a running VM's console.
virtual_display_active() {
    /sbin/lsmod | grep -q "^bochs_drm "
}

install_i915_bins() {
    local src="$1"
    local dest="/usr/lib/firmware/i915/$(basename "$src")"

    if [ ! -f "$src" ]; then
        log "Skipped $(basename "$src") (not found in package)"
        return 0
    fi

    if [ -f "$dest" ]; then
        log "$(basename "$src") already installed"
        return 0
    fi

    if cp "$src" "$dest" && chown root:root "$dest" && chmod 0755 "$dest"; then
        log "Installed $(basename "$src")"
    else
        log "ERROR: Failed to install $(basename "$src")"
    fi
    return 0
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
    # Optional $2: hint logged if the unload fails, for cases where we
    # already know the likely cause (e.g. i915 held open by an active
    # Plex/Jellyfin transcode).

rmmod_if_loaded() {
    local mod="${1//-/_}"
    if /sbin/lsmod | grep -q "^${mod} "; then
        if /sbin/rmmod "$mod" 2>>"${LOG_FILE}"; then
            log "Unloaded ${1}"
            RMMOD_OK=$((RMMOD_OK + 1))
        else
            log "ERROR: Failed to unload ${1}"
            if [ -n "$2" ]; then
                log "$2"
            fi
        fi
        RMMOD_TOTAL=$((RMMOD_TOTAL + 1))
    else
        log "Skipped ${1} (not loaded)"
    fi
    return 0
}

load_pkg_modules() {
    if virtual_display_active; then
        log "Virtual display adapter is using the drivers. Stop Virtual Machine Manager, then start Transcode Drivers for x25 and then start Virtual Machine Manager"
        notify_load_failed
        return 1
    fi

    log "Loading package driver modules"
    INSMOD_TOTAL=0
    INSMOD_OK=0
    RMMOD_TOTAL=0
    RMMOD_OK=0

    # Remove DSM's default modules (reverse load order)
    rmmod_if_loaded i915 "Plex or Jellyfin is using the drivers. Stop Plex or Jellyfin, then start Transcode Drivers for x25 and then start Plex or Jellyfin"
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

    if [ "$RMMOD_OK" -lt "$RMMOD_TOTAL" ] || [ "$INSMOD_OK" -lt "$INSMOD_TOTAL" ]; then
        notify_load_failed
        return 1
    fi
    return 0
}

restore_dsm_modules() {
    if virtual_display_active; then
        log "Virtual display adapter is using the drivers. Stop Virtual Machine Manager, then start Transcode Drivers for x25 and then start Virtual Machine Manager"
        return 1
    fi

    log "Restoring default driver modules"
    INSMOD_TOTAL=0
    INSMOD_OK=0
    RMMOD_TOTAL=0
    RMMOD_OK=0

    # Remove package modules (reverse load order)
    rmmod_if_loaded i915 "Plex or Jellyfin is using the drivers. Stop Plex or Jellyfin, then start Transcode Drivers for x25 and then start Plex or Jellyfin"
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

    if [ "$RMMOD_OK" -lt "$RMMOD_TOTAL" ] || [ "$INSMOD_OK" -lt "$INSMOD_TOTAL" ]; then
        return 1
    fi
    return 0
}

case "$1" in
    start)
        echo " " >> "${LOG_FILE}"
        log "${PKG_NAME} starting"
        install_i915_bins "${i915_BINS}/glk_guc_70.1.1.bin"
        install_i915_bins "${i915_BINS}/glk_huc_4.0.0.bin"
        if load_pkg_modules; then
            log "${PKG_NAME} started"
        fi
        exit 0
        ;;
    stop)
        echo " " >> "${LOG_FILE}"
        log "${PKG_NAME} stopping"
        if restore_dsm_modules; then
            log "${PKG_NAME} stopped"
        fi
        exit 0
        ;;
esac
