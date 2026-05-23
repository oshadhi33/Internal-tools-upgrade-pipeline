#!/bin/bash

LOG_DIR="/var/log/internal-tools-upgrade"
LOG_FILE="${LOG_DIR}/upgrade_$(date +%Y%m%d_%H%M%S).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Log levels
log_info() {
    log "INFO" "$@"
}

log_warn() {
    log "WARN" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        log "DEBUG" "$@"
    fi
}

# Export functions for use in other scripts
export -f log
export -f log_info
export -f log_warn
export -f log_error
export -f log_debug
export LOG_FILE
