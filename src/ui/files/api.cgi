#!/bin/bash
#----------------------------------------------------------
# TranscodeDrivers package - API CGI
#----------------------------------------------------------

# --------- 1. Common variables and path calculations -------------

PKG_NAME="TranscodeDrivers"
PKG_ROOT="/var/packages/${PKG_NAME}"
VAR_DIR="${PKG_ROOT}/var"

LOG_FILE="${VAR_DIR}/TranscodeDrivers.log"
API_LOG_FILE="${VAR_DIR}/api.log"

touch "${API_LOG_FILE}"
chmod 644 "${API_LOG_FILE}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${API_LOG_FILE}"
}

# --------- 2. HTTP header output --------------------------------

echo "Content-Type: application/json; charset=utf-8"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Methods: GET, POST"
echo "Access-Control-Allow-Headers: Content-Type"
echo "" # Header/body separator blank line

# --------- 3. Parsing URL-encoded parameters --------------------

urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
declare -A PARAM
parse_kv() {
    local kv_pair key val
    IFS='&' read -ra kv_pair <<< "$1"
    for pair in "${kv_pair[@]}"; do
        IFS='=' read -r key val <<< "${pair}"
        key="$(urldecode "${key}")"
        val="$(urldecode "${val}")"
        PARAM["${key}"]="${val}"
    done
}

case "$REQUEST_METHOD" in
POST)
    CONTENT_LENGTH=${CONTENT_LENGTH:-0}
    if [ "$CONTENT_LENGTH" -gt 0 ]; then
        read -r -n "$CONTENT_LENGTH" POST_DATA
    else
        POST_DATA=""
    fi
    parse_kv "${POST_DATA}"
    ;;
GET)
    parse_kv "${QUERY_STRING}"
    ;;
*)
    log "Unsupported METHOD: ${REQUEST_METHOD}"
    echo '{"success":false,"message":"Unsupported METHOD","result":null}'
    exit 0
    ;;
esac

ACTION="${PARAM[action]}"
log "Request: ACTION=${ACTION}"

# --------- 4. JSON utility functions -----------------------------

json_response() {
    local ok="$1" msg="$2" data="$3"
    local msg_json
    msg_json=$(echo "$msg" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')
    if [ -z "$data" ]; then
        echo "{\"success\":$ok, \"message\":$msg_json, \"result\":null}"
    else
        echo "{\"success\":$ok, \"message\":$msg_json, \"result\":$data}"
    fi
}

# --------- 5. Action processing ---------------------------------
#
# NOTE: reading the log doesn't need root, so this reads LOG_FILE
# directly rather than going through transcode-helper. If a
# Clear/Save action is added later that DOES need root, that action
# should call transcode-helper (add the verb there first) rather
# than reintroducing sudo.

case "${ACTION}" in
init)
    log "----------------------------------------"
    log "Web UI opened/refreshed"
    echo '{"success":true,"message":"init"}'
    ;;

getlog)
    if [ -r "${LOG_FILE}" ]; then
        LOG_JSON=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' < "${LOG_FILE}")
        json_response true "" "${LOG_JSON}"
    else
        log "[ERROR] Log file not found or not readable: ${LOG_FILE}"
        json_response false "Log file not found" ""
    fi
    ;;

*)
    log "[ERROR] Invalid action: ${ACTION}"
    json_response false "Invalid action: ${ACTION}" ""
    ;;
esac

exit 0
