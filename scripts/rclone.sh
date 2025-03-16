#!/bin/sh

# Check if rclone is installed
if ! which rclone >/dev/null 2>&1; then
  echo "rclone could not be found, please install it first."
  exit 1
fi

# Lock file to prevent multiple instances
LOCKFILE="/tmp/$(basename "$0").lock"

if [ -e "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
  echo "$0 already running, exiting."
  exit 1
fi

# Remove the lock file when the script exits
trap 'rm -f "$LOCKFILE"' EXIT

echo $$ >"$LOCKFILE"

# Create log directory if it doesn't exist
LOGDIR="$HOME/log"
mkdir -p "$LOGDIR"

LOGFILE="$HOME/log/rclone_$(date '+%Y%m%d').log"
EXCLUDE="$HOME/.config/scripts/rclone_exclude.txt"

# Function to perform rclone sync
rclone_sync() {
  SOURCE="$1"
  DEST="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Syncing $SOURCE to $DEST" >>"$LOGFILE"
  rclone sync "$SOURCE" "$DEST" --log-file="$LOGFILE" --log-level=ERROR --exclude-from "$EXCLUDE" --exclude-if-present .rcloneignore
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Finished syncing $SOURCE to $DEST" >>"$LOGFILE"
}

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting rclone sync" >>"$LOGFILE"

rclone_sync "$HOME/dev/" /mnt/backup/dev/
rclone_sync "$HOME/dev/" /mnt/media/dev/

rclone_sync "$HOME/.dotfiles/" /mnt/backup/dotfiles/
rclone_sync "$HOME/.dotfiles/" /mnt/media/dotfiles/

echo "$(date '+%Y-%m-%d %H:%M:%S') - Finished rclone sync" >>"$LOGFILE"

rm "$LOCKFILE"

# Remove log files older than 7 days
find "$LOGDIR" -type f -name "rclone_*.log" -mtime +7 -exec rm {} \;
