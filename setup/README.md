# Fedora Workstation Migration Scripts

This directory contains setup and backup scripts to help you quickly migrate and provision a clean Fedora installation from scratch.

Dotfiles themselves are handled by [`../install.sh`](../install.sh) (dotter, deploy, starship, fish as login shell,
systemd user services). `setup.sh` only does the system-level work and calls `install.sh` at the end, so the two never
overlap. On Termux, just run `install.sh`.

## Scripts Included

1. **`backup.sh`**: Run this script **before** formatting your system. It needs both `/mnt/backup` and `/mnt/media`
   mounted and writes the same backup to each:
   - `~/dev` and `~/.dotfiles` to `<drive>/dev` and `<drive>/dotfiles`, `.env` files included (`scripts/rsync.sh`)
   - The Obsidian vault from `/mnt/backup/documents/obsidian` to `/mnt/media/obsidian`, settings and plugins included
   - `<drive>/fedora_migration_backup/home.tar.gz`: SSH keys, `gh` config, Syncthing identity (same device ID),
     fonts, fish history, zoxide database and `.npmrc`, `.aicommit2`, `.aicommits`, `.modal.toml`, `.opencommit`
   - `crontab.txt`, `dconf.ini` (GNOME settings) and `fstab.bak`
   - `inventory/`: dnf, Flatpak, `~/.local/bin`, cargo, uv, npm, bun and GNOME extension lists, to reinstall what
     `setup.sh` doesn't cover

2. **`setup.sh`**: Run this script **after** a fresh install of Fedora. It will:
   - Apply performance tweaks to DNF
   - Enable RPM repositories (RPM Fusion, Docker, Terra, Tailscale)
   - Install RPMs from `packages/fedora.txt` and Flatpaks from `packages/flatpak.txt`
   - Make Flathub the only Flatpak remote: unfiltered, with Fedora's own `fedora` remote removed and any app from it
     reinstalled from Flathub
   - Restore the backup: `home.tar.gz` and the crontab, then `~/dev` from `<drive>/dev` (when `~/dev` is empty),
     with file modes reset and executable bits taken from each repo's git index. An https dotfiles clone is
     switched to SSH
   - Enable Docker, Tailscale, cron, `sshd` (key login only) and user lingering
   - Run `../install.sh --profile fedora` as your user, which deploys the dotfiles, installs starship, sets fish as
     the login shell and enables the user services (Syncthing, Espanso)

## Package Lists

`packages/` holds one package per line (`#` starts a comment):

- `fedora.txt`: RPMs for `dnf install` (unavailable ones are skipped, not fatal)
- `flatpak.txt`: Flathub app IDs
- `termux.txt`: Termux packages, used by `install.sh`

---

## Step-by-Step Migration Guide

### Step 1: Pre-Format Backup

1. Push or commit what you can. Repos without a remote only survive in `<drive>/dev`.
2. Make sure `/mnt/backup` and `/mnt/media` are both mounted, then run:
   ```bash
   ~/.dotfiles/setup/backup.sh
   ```
3. Check `<drive>/fedora_migration_backup` on both drives, and that `.env` files exist under `<drive>/dev`.

### Step 2: Fresh Fedora Installation

1. Install Fedora Workstation with custom partitioning: reformat only the Fedora root (`sdb7`) and reuse the EFI
   (`sdb1`) and `/boot` (`sdb6`) partitions. `/mnt/backup` (`sdb4`) is on the same disk and holds the Obsidian vault,
   so never let the installer erase the whole disk.
2. Create your user account with the same username (e.g., `abdo`) to avoid path mismatch issues with configurations.

### Step 3: Post-Install Setup

1. Mount the backup drives (`/mnt/media` is the default restore source).
2. Clone the dotfiles: `git clone https://github.com/x0aa7i/dotfiles ~/.dotfiles` (setup switches it to SSH).
3. Run the setup script with `sudo` (since it installs packages and configures system services):
   ```bash
   sudo ~/.dotfiles/setup/setup.sh
   ```
4. Follow the prompts. The script will ask you if you want to restore from your backup folder (specify
   `/mnt/media/fedora_migration_backup`). `chsh` may ask for your password when switching to fish.
5. Log in to Tailscale with `sudo tailscale up`, then pair the phone with `pair-phone`
   (see [`../ssh/README.md`](../ssh/README.md)).
6. Log in to the GitHub CLI with `gh auth login` (git itself already works over the restored SSH key).
7. Merge the `/mnt/media` and `/mnt/backup` mounts from `fstab.bak` in the backup into `/etc/fstab`, and load any
   GNOME settings you want from `dconf.ini` (`dconf load / < dconf.ini`). Reinstall extra tools from `inventory/`.
8. Once completed, reboot your system to apply all changes:
   ```bash
   sudo reboot
   ```

## Optional, by hand

- **NVIDIA (GTX 850M):** Fedora uses the open `nouveau` driver, which drives the display (through the Intel GPU) but
  leaves the GTX 850M slow, without NVENC or CUDA. The proprietary driver comes from RPM Fusion. Maxwell cards need its
  580xx legacy branch, since the default `akmod-nvidia` moved to 595, which dropped them:
  ```bash
  sudo dnf install akmod-nvidia-580xx xorg-x11-drv-nvidia-580xx-cuda
  ```
  Wait for the module to build (`journalctl -fu akmods`) before rebooting.
- **Playwright:** Chromium and Firefox run natively, so `npx playwright install chromium firefox` is all a project
  needs. WebKit only supports Ubuntu/Debian; run it in Playwright's Docker image (same version as the project):
  ```bash
  docker run --rm -it --ipc=host -v "$PWD:/work" -w /work mcr.microsoft.com/playwright:v<version>-noble \
    npx playwright test --project=webkit
  ```
