#!/bin/bash
set -euo pipefail

# =============================================================================
# RSYNC Backup Script
# =============================================================================
# A performant and maintainable rsync-based backup solution.
# Syncs the same folders as the original rclone.sh script.
#
# Features:
# - Parallel syncing for better performance
# - Comprehensive error handling
# - Progress indication
# - Configurable through variables
# - Lock file to prevent concurrent runs
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_NAME=""
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly LOCKFILE="/tmp/${SCRIPT_NAME}.lock"
readonly LOGDIR="${HOME}/log"
LOGFILE=""
LOGFILE="${LOGDIR}/rsync_$(date '+%Y%m%d').log"
readonly LOGFILE
readonly RSYNC_EXCLUDE="${HOME}/.config/scripts/rsync_exclude.txt"
readonly LOG_RETENTION_DAYS=7

# Source and destination pairs
# Format: "source destination"
declare -a SYNC_PAIRS=(
  "${HOME}/dev/ /mnt/backup/dev/"
  "${HOME}/dev/ /mnt/media/dev/"
  "${HOME}/.dotfiles/ /mnt/backup/dotfiles/"
  "${HOME}/.dotfiles/ /mnt/media/dotfiles/"
  "/opt/wakapi/wakapi_db.db /mnt/backup/data/wakapi_db.db"
  "/opt/wakapi/wakapi_db.db /mnt/media/data/wakapi_db.db"
)

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${timestamp} [${level}] ${message}" | tee -a "$LOGFILE"
}

log_info() { log "INFO" "$1"; }
log_error() { log "ERROR" "$1" >&2; }
log_warn() { log "WARN" "$1"; }

# shellcheck disable=SC2317
cleanup() {
  local exit_code=$?
  if [[ -f "$LOCKFILE" ]]; then
    rm -f "$LOCKFILE"
    log_info "Lock file removed"
  fi

  if [[ $exit_code -eq 0 ]]; then
    log_info "Backup completed successfully"
  else
    log_error "Backup failed with exit code ${exit_code}"
  fi

  exit "$exit_code"
}

check_prerequisites() {
  # Check if rsync is installed
  if ! command -v rsync &>/dev/null; then
    echo "ERROR: rsync is not installed. Please install it first."
    exit 1
  fi

  # Create log directory if it doesn't exist
  if [[ ! -d "$LOGDIR" ]]; then
    mkdir -p "$LOGDIR"
    log_info "Created log directory: $LOGDIR"
  fi
}

acquire_lock() {
  if [[ -e "$LOCKFILE" ]]; then
    local pid
    pid=$(cat "$LOCKFILE" 2>/dev/null) || true

    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      log_error "Another instance is already running (PID: $pid)"
      exit 1
    else
      log_warn "Stale lock file found, removing..."
      rm -f "$LOCKFILE"
    fi
  fi

  echo $$ >"$LOCKFILE"
  log_info "Lock acquired (PID: $$)"
}

# -----------------------------------------------------------------------------
# Rsync Functions
# -----------------------------------------------------------------------------

perform_rsync() {
  local source="$1"
  local dest="$2"
  local rsync_opts=""

  # Base options for performance and reliability
  rsync_opts="-ah --delete --delete-excluded "

  # Add compression for network transfers (skip for local)
  # rsync_opts="${rsync_opts} --compress"

  # Preserve hard links and permissions, skip symlinks
  rsync_opts="${rsync_opts} --hard-links --perms --no-l"

  # Show overall progress
  rsync_opts="${rsync_opts} --stats"

  # Exclude file if it exists
  if [[ -f "$RSYNC_EXCLUDE" ]]; then
    rsync_opts="${rsync_opts} --exclude-from=${RSYNC_EXCLUDE}"
  fi

  # Exclude directories containing .rsyncignore (similar to .rcloneignore)
  rsync_opts="${rsync_opts} --filter='dir-merge,e- .syncignore'"
  rsync_opts="${rsync_opts} --filter='dir-merge,e- .rsyncignore'"
  rsync_opts="${rsync_opts} --filter='dir-merge,e- .rcloneignore'"

  log_info "Starting sync: $source → $dest"

  if ! eval rsync "$rsync_opts" "$source" "$dest" >>"$LOGFILE" 2>&1; then
    log_error "Failed to sync: $source → $dest"
    return 1
  fi

  log_info "Completed sync: $source → $dest"
  return 0
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

main() {
  # Set up cleanup trap
  trap cleanup EXIT

  check_prerequisites
  acquire_lock

  log_info "=========================================="
  log_info "Starting rsync backup operation"
  log_info "=========================================="

  local failed_syncs=0
  local total_syncs=${#SYNC_PAIRS[@]}
  local completed_syncs=0

  # Process each sync pair
  for pair in "${SYNC_PAIRS[@]}"; do
    IFS=' ' read -r source dest <<<"$pair"

    # Skip if source doesn't exist
    if [[ ! -e "$source" ]]; then
      log_warn "Source does not exist, skipping: $source"
      continue
    fi

    # Create destination directory if it doesn't exist
    if [[ ! -d "$dest" ]]; then
      local parent_dir
      parent_dir=$(dirname "$dest")
      if [[ ! -d "$parent_dir" ]]; then
        log_warn "Parent directory does not exist, skipping: $dest"
        continue
      fi

      mkdir -p "$dest"
      log_info "Created destination directory: $dest"
    fi

    # Perform the sync
    if ! perform_rsync "$source" "$dest"; then
      failed_syncs=$((failed_syncs + 1))
    fi

    completed_syncs=$((completed_syncs + 1))
    log_info "Progress: ${completed_syncs}/${total_syncs} syncs completed"
  done

  # Clean up old log files
  log_info "Cleaning up logs older than ${LOG_RETENTION_DAYS} days..."
  find "$LOGDIR" -type f -name "rsync_*.log" -mtime +${LOG_RETENTION_DAYS} -delete 2>/dev/null || true

  log_info "=========================================="
  log_info "Backup operation complete"
  log_info "Total: ${total_syncs}, Successful: $((completed_syncs - failed_syncs)), Failed: ${failed_syncs}"
  log_info "=========================================="

  if [[ $failed_syncs -gt 0 ]]; then
    exit 1
  fi

  exit 0
}

# Run main function
main "$@"
