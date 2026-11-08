# Setup

Everything that installs, provisions or backs up a machine. The scripts find the repo from their own location,
so it can be cloned anywhere (`~/dotfiles` here).

| Script                | Runs as | When                                                                         |
| --------------------- | ------- | ---------------------------------------------------------------------------- |
| [`../install.sh`]     | user    | Any machine (Fedora, Termux), first time and whenever you want to re-apply   |
| `tools/<name>.sh`     | user    | Run by `install.sh`, or alone to update one tool                             |
| `fedora.sh`           | `sudo`  | Once, after a fresh Fedora install. Calls `install.sh` at the end            |
| `backup.sh`           | user    | Before formatting, writes what `fedora.sh` and `restore.sh` restore          |
| `restore.sh`          | user/`sudo` | Restores backup anytime (home files, Syncthing identity, crontab, dev, fstab)|
| `lib.sh`              | —       | Shared helpers (`log_*`, `detect_env`, `read_packages`, `gh_latest_tag`, …)  |

`scripts/` (deployed to `~/.config/scripts`) only holds what runs day to day, like `rsync.sh`.

[`../install.sh`]: ../install.sh

## install.sh

User level, no `sudo`, safe to re-run. It detects the environment, downloads `dotter`, writes `.dotter/local.toml`
from the matching profile and deploys, then sets up starship, fish as the login shell, an SSH key and the shared
`~/.ssh/config.d` include, the agent status lines, the systemd user services (Syncthing) and the tools in
`TOOLS`. On Termux it also installs `packages/termux.txt`, the Nerd Font and sshd autostart.

```bash
./install.sh                  # auto-detect the profile (termux or fedora)
./install.sh --profile fedora # force a profile
./install.sh --no-packages    # skip `pkg install` on Termux
./install.sh --no-tools       # skip setup/tools/
```

## Tools

`tools/<name>.sh` installs or updates one tool in `~/.local/bin`, keeping the previous binary as `.bak`.
`install.sh` runs the ones listed in its `TOOLS` array after the deploy, so re-running it also updates them.

- **`yazi.sh`**: latest yazi and ya release (skipped on Termux, where `pkg` provides them), then `ya pkg install`
  for the plugins and flavor in `yazi/package.toml`. `yazi/init.lua` requires those plugins, so yazi fails at
  startup without them. Pass `--no-plugins` to skip that step.
- **`nvim.sh`**: the Neovim AppImage (`--nightly`, the default, or `--stable`). Not in `TOOLS`, since Neovim comes
  from dnf/pkg. Run it by hand to put a newer build in front of it on `$PATH`.

To add a tool, write `tools/<name>.sh` (source `../lib.sh`, compare versions, download only when they differ) and
add `<name>` to `TOOLS` in `install.sh` if it should run on every install.

## Package Lists

`packages/` holds one package per line (`#` starts a comment):

- `fedora.txt`: RPMs for `dnf install`, used by `fedora.sh` (unavailable ones are skipped, not fatal)
- `flatpak.txt`: Flathub app IDs, used by `fedora.sh`
- `gnome-extensions.txt`: extension UUIDs, used by `fedora.sh`
- `termux.txt`: Termux packages, used by `install.sh`

## Fedora Migration

### backup.sh

Run it **before** formatting. It needs both `/mnt/backup` and `/mnt/media` mounted, and also uses the external
`Storage` disk (`/run/media/$USER/Storage`) when it's plugged in. It writes the same backup to each:

- `~/dev` and the dotfiles repo to `<drive>/dev` and `<drive>/dotfiles`, `.env` files included (`scripts/rsync.sh`)
- The Obsidian vault from `/mnt/backup/documents/obsidian` to `<drive>/obsidian` on the other drives, settings and
  plugins included
- `<drive>/fedora_migration_backup/home.tar.gz`: SSH keys, `gh` config, Syncthing identity (same device ID), fonts,
  fish history, zoxide database and `.npmrc`, `.aicommit2`, `.aicommits`, `.modal.toml`, `.opencommit`
- `crontab.txt`, `dconf.ini` (GNOME settings) and `fstab.bak`
- `inventory/`: dnf, Flatpak, `~/.local/bin`, cargo, uv, npm, bun and GNOME extension lists, to reinstall what
  `fedora.sh` doesn't cover

### restore.sh

Run it to restore data exported by `backup.sh`. It can be run standalone anytime (safe to re-run if drives had mount issues initially) or is called by `fedora.sh`:

- Restores `home.tar.gz`: SSH keys, `gh` config, Syncthing identity, fonts, fish history, zoxide database, `.aicommits`, etc.
- Restores the crontab and `/etc/fstab` drive mounts (`/mnt/backup`, `/mnt/media`)
- Restores `~/dev` from `<drive>/dev` with correct file modes and git executable bits

```bash
./setup/restore.sh                  # auto-detects backup from /run/media or /mnt
./setup/restore.sh /path/to/backup  # explicit path
```

### fedora.sh

Run it with `sudo` **after** a fresh Fedora install. It will:

- Apply performance tweaks to DNF
- Enable RPM repositories (RPM Fusion, Docker, Terra, Tailscale)
- Install RPMs from `packages/fedora.txt` and Flatpaks from `packages/flatpak.txt`
- Make Flathub the only Flatpak remote: unfiltered, with Fedora's own `fedora` remote removed and any app from it
  reinstalled from Flathub
- Restore the backup: `home.tar.gz`, the `/mnt` drive mounts and the crontab, then `~/dev` from `<drive>/dev` (when
  `~/dev` is empty), with file modes reset and executable bits taken from each repo's git index. An https dotfiles
  clone is switched to SSH
- Enable Docker, Tailscale, cron, `sshd` (key login only) and user lingering
- Set the GNOME workspace shortcuts and install the extensions from `packages/gnome-extensions.txt`
- Run `../install.sh --profile fedora` as your user

### Step by step

1. **Back up.** Push or commit what you can: repos without a remote only survive in `<drive>/dev`. With
   `/mnt/backup` and `/mnt/media` mounted, run `~/dotfiles/setup/backup.sh`, then check
   `<drive>/fedora_migration_backup` on both drives and that `.env` files exist under `<drive>/dev`.
2. **Install Fedora** with custom partitioning: reformat only the Fedora root (`sdb7`) and reuse the EFI (`sdb1`) and
   `/boot` (`sdb6`) partitions. `/mnt/backup` (`sdb4`) is on the same disk and holds the Obsidian vault, so never let
   the installer erase the whole disk. Create your user with the same username (e.g., `abdo`).
3. **Provision.** Mount the backup drives (`/mnt/media` is the default restore source; the external disk works too,
   at `/run/media/$USER/Storage/fedora_migration_backup`), then:
   ```bash
   git clone https://github.com/x0aa7i/dotfiles ~/dotfiles # fedora.sh switches it to SSH
   sudo ~/dotfiles/setup/fedora.sh
   ```
   Answer the restore prompt with the backup folder. `chsh` may ask for your password when switching to fish.
4. **Finish by hand.** Log in to Tailscale with `sudo tailscale up`, then pair the phone with `pair-phone` (see
   [`../ssh/README.md`](../ssh/README.md)). Log in to the GitHub CLI with `gh auth login` (git itself already works
   over the restored SSH key). Load any GNOME settings you want from `dconf.ini` (`dconf load / < dconf.ini`) and
   reinstall extra tools from `inventory/`. Then reboot (`sudo reboot`).

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
