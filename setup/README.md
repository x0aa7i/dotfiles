# Fedora Workstation Migration Scripts

This directory contains setup and backup scripts to help you quickly migrate and provision a clean Fedora installation from scratch.

Dotfiles themselves are handled by [`../install.sh`](../install.sh) (dotter, deploy, starship, fish as login shell,
systemd user services). `setup.sh` only does the system-level work and calls `install.sh` at the end, so the two never
overlap. On Termux, just run `install.sh`.

## Scripts Included

1. **`backup.sh`**: Run this script **before** formatting your system. It collects:
   - User security credentials (`~/.ssh`, `~/.gnupg`)
   - Manual system mounts (`/etc/fstab` backup)
   - Configuration databases (`~/.local/share/wakapi`)
   - Standalone home configs (`.npmrc`, `.aicommit2`, `.aicommits`)
   - Flatpak list and user-installed RPM package lists
   - Profiles of key Flatpak apps (Zen Browser, Obsidian, Anki, Foliate, Telegram)
   - The dotfiles repository (`~/.dotfiles` directory)

2. **`setup.sh`**: Run this script **after** a fresh install of Fedora. It will:
   - Apply performance tweaks to DNF
   - Enable RPM repositories (RPM Fusion, Docker, Terra)
   - Install RPMs from `packages/fedora.txt` and Flatpaks from `packages/flatpak.txt`
   - Install NVIDIA drivers when an NVIDIA GPU is detected
   - Install Zed for your user
   - Restore the backup: SSH/GPG keys, home configs, Wakapi data, Flatpak profiles and `~/.dotfiles` (if missing)
   - Enable Docker and user lingering
   - Run `../install.sh --profile fedora` as your user, which deploys the dotfiles, installs starship, sets fish as
     the login shell and enables the user services (Wakapi, Syncthing, Espanso)

## Package Lists

`packages/` holds one package per line (`#` starts a comment):

- `fedora.txt`: RPMs for `dnf install` (unavailable ones are skipped, not fatal)
- `flatpak.txt`: Flathub app IDs
- `termux.txt`: Termux packages, used by `install.sh`

---

## Step-by-Step Migration Guide

### Step 1: Pre-Format Backup

1. Insert and mount your backup drive (e.g., `/mnt/backup`).
2. Run the backup script:
   ```bash
   chmod +x backup.sh
   ./backup.sh
   ```
3. Enter your backup destination folder when prompted (e.g., `/mnt/backup/fedora_migration_backup`).
4. Wait for the backup to complete, then verify the contents of the backup directory.

### Step 2: Fresh Fedora Installation

1. Install Fedora Workstation from scratch on your drive.
2. Create your user account with the same username (e.g., `abdo`) to avoid path mismatch issues with configurations.

### Step 3: Post-Install Setup

1. Mount your backup drive (e.g., at `/mnt/backup`).
2. Clone the dotfiles to `~/.dotfiles` (or copy them from the backup).
3. Run the setup script with `sudo` (since it installs packages and configures system services):
   ```bash
   sudo ~/.dotfiles/setup/setup.sh
   ```
4. Follow the prompts. The script will ask you if you want to restore from your backup folder (specify
   `/mnt/backup/fedora_migration_backup`). `chsh` may ask for your password when switching to fish.
5. Merge any custom mounts from `configs/fstab.bak` in the backup into `/etc/fstab`.
6. Once completed, reboot your system to apply all changes:
   ```bash
   sudo reboot
   ```
