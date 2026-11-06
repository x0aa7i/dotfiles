#!/bin/bash
set -euo pipefail

# =============================================================================
# RSYNC Backup Script
# =============================================================================
# A performant and maintainable rsync-based backup solution.
# Syncs ~/dev, the dotfiles repo and the Obsidian vault to every backup drive.
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
# dotter symlinks this script into ~/.config/scripts, resolve it to find the repo
SCRIPT_DIR=""
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly SCRIPT_DIR
DOTFILES_DIR=""
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
readonly DOTFILES_DIR
readonly RSYNC_EXCLUDE="${SCRIPT_DIR}/rsync_exclude.txt"
readonly LOG_RETENTION_DAYS=7

# Backup drives. Required ones count as a failure when they aren't mounted,
# optional ones (external disks) are only used when they are
readonly REQUIRED_DRIVES=(/mnt/backup /mnt/media)
readonly OPTIONAL_DRIVES=("/run/media/$(id -un)/Storage")

# Synced to <drive>/<name> on every drive. Format: "source name [full]"
# "full" copies everything, ignoring .gitignore files
readonly SYNC_SOURCES=(
  "${HOME}/dev/ dev"
  "${DOTFILES_DIR}/ dotfiles"
  # Lives on /mnt/backup; its .gitignore skips settings, PDFs and EPUBs
  "/mnt/backup/documents/obsidian/ obsidian full"
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
  local mode="${3:-}"
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

  if [[ "$mode" != "full" ]]; then
    # Keep .env files although .gitignore excludes them (first matching rule wins).
    # Directories named .env* (Python virtualenvs) stay excluded
    rsync_opts="${rsync_opts} --exclude='.env*/' --include='.env*'"

    # Exclude files and directories in .gitignore
    rsync_opts="${rsync_opts} --filter='dir-merge,- .gitignore'"
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

  # Set core.filemode = false on target repositories to prevent them from showing
  # as dirty with +x file mode changes due to destination filesystem limitations.
  if [[ -d "$dest" ]]; then
    log_info "Setting core.filemode to false for synced repositories in $dest..."
    find "$dest" -type d \( -name .git -print0 -prune \) -o \( -name node_modules -o -name .venv -o -name dist -o -name build -o -name target -o -name .cache \) -prune 2>/dev/null | while IFS= read -r -d '' git_dir; do
      if [[ -f "${git_dir}/config" ]]; then
        git config -f "${git_dir}/config" core.filemode false || true
      fi
    done
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
  local completed_syncs=0
  local drive entry source name mode dest

  for drive in "${REQUIRED_DRIVES[@]}" "${OPTIONAL_DRIVES[@]}"; do
    # An unmounted drive would fill its empty mount point on the root filesystem
    if ! mountpoint -q "$drive"; then
      if [[ " ${REQUIRED_DRIVES[*]} " == *" $drive "* ]]; then
        log_error "Drive not mounted, skipping: $drive"
        failed_syncs=$((failed_syncs + 1))
      else
        log_info "Optional drive not mounted, skipping: $drive"
      fi
      continue
    fi

    for entry in "${SYNC_SOURCES[@]}"; do
      IFS=' ' read -r source name mode <<<"$entry"
      dest="${drive}/${name}/"

      if [[ ! -e "$source" ]]; then
        log_warn "Source does not exist, skipping: $source"
        continue
      fi
      # No point copying a folder onto the drive it already lives on
      if [[ "$source" == "$drive/"* ]]; then
        continue
      fi

      mkdir -p "$dest"
      if perform_rsync "$source" "$dest" "$mode"; then
        completed_syncs=$((completed_syncs + 1))
      else
        failed_syncs=$((failed_syncs + 1))
      fi
    done
  done

  # Clean up old log files
  log_info "Cleaning up logs older than ${LOG_RETENTION_DAYS} days..."
  find "$LOGDIR" -type f -name "rsync_*.log" -mtime +${LOG_RETENTION_DAYS} -delete 2>/dev/null || true

  log_info "=========================================="
  log_info "Backup operation complete"
  log_info "Successful: ${completed_syncs}, Failed: ${failed_syncs}"
  log_info "=========================================="

  if [[ $failed_syncs -gt 0 ]]; then
    exit 1
  fi

  exit 0
}

# Run main function
main "$@"
