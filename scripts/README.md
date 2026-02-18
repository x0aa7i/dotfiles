# Scripts

This directory contains utility scripts for system maintenance and backups.

## rsync.sh

A performant bash script for syncing files to multiple backup destinations using `rsync`.

### Features

- Syncs multiple source directories to multiple destinations
- Parallel-ready structure with array-based configuration
- Comprehensive error handling with detailed logging
- Lock file to prevent concurrent runs
- Automatic cleanup of old log files (7 day retention)
- Progress tracking and statistics
- Support for exclude patterns via `rclone_exclude.txt`

### Configuration

Edit the `SYNC_PAIRS` array in the script to add/remove sync operations:

```bash
declare -a SYNC_PAIRS=(
  "$HOME/dev/ /mnt/backup/dev/"
  "$HOME/.dotfiles/ /mnt/backup/dotfiles/"
)
```

### Scheduling with Cron

To run the backup automatically on a schedule, add an entry to your crontab:

```bash
crontab -e
```

**Example: Run every 6 hours**

```cron
0 */6 * * * /home/abdo/.config/scripts/rsync.sh
```

This runs the backup at minute 0 of every 6th hour (00:00, 06:00, 12:00, 18:00).

**Other common schedules:**

- Daily at 2 AM: `0 2 * * * /home/abdo/.config/scripts/rsync.sh`
- Weekly on Sunday at 3 AM: `0 3 * * 0 /home/abdo/.config/scripts/rsync.sh`
- Every 4 hours: `0 */4 * * * /home/abdo/.config/scripts/rsync.sh`

### Logs

Logs are stored in `~/log/rsync_YYYYMMDD.log`. Check these for sync status and any errors.

### Exclude Patterns

The script uses `~/.config/scripts/rsync_exclude.txt` for exclude patterns.

To exclude a directory from being synced, create a `.rsyncignore` file in that directory (similar to `.gitignore`).

## rclone.sh (Legacy)

The original rclone-based backup script. Kept for reference.

**Note:** If migrating from `rclone.sh` to `rsync.sh`, update your crontab entry:

```bash
# Old
0 */6 * * * /home/abdo/.config/scripts/rclone.sh

# New
0 */6 * * * /home/abdo/.config/scripts/rsync.sh
```
