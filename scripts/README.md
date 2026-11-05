# Scripts

This directory contains utility scripts for system maintenance and backups.

## rsync.sh

A performant bash script for syncing files to multiple backup destinations using `rsync`.

### Features

- Syncs every source to every backup drive, with optional drives (external disks) used only when mounted
- Comprehensive error handling with detailed logging
- Lock file to prevent concurrent runs
- Automatic cleanup of old log files (7 day retention)
- Progress tracking and statistics
- Support for exclude patterns via `rsync_exclude.txt` and each repo's `.gitignore`
- `.env` files are always copied, even when `.gitignore` excludes them
- Sources marked `full` ignore `.gitignore` files (the Obsidian vault, which keeps its settings out of git)
- Drives that aren't mounted are skipped (and reported as failures) instead of filling the empty mount point

### Configuration

Edit the arrays at the top of the script. Every source is synced to `<drive>/<name>` on every drive:

```bash
readonly REQUIRED_DRIVES=(/mnt/backup /mnt/media)            # a failure when not mounted
readonly OPTIONAL_DRIVES=("/run/media/$(id -un)/Storage")   # used only when mounted
readonly SYNC_SOURCES=(
  "${HOME}/dev/ dev"
  "/mnt/backup/documents/obsidian/ obsidian full"            # full: ignore .gitignore
)
```

A source is never copied onto the drive it already lives on.

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
