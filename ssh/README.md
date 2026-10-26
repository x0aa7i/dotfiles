# SSH between the PC and the phone

The PC (Fedora) and the phone (Termux) reach each other over [Tailscale](https://tailscale.com), using their
default MagicDNS names:

| Device | Tailscale name | SSH port | Connect from the other side |
| ------ | -------------- | -------- | --------------------------- |
| PC     | `fedora`       | 22       | `ssh fedora` (on the phone) |
| Phone  | `s21`          | 8022     | `ssh s21` (on the PC)       |

## What is automated

- `ssh/config.d/tailnet.conf` (in git) holds both host entries: names, ports, user, keepalive and connection reuse.
  Dotter links it to `~/.ssh/config.d/tailnet.conf` on both machines.
- `install.sh` (both machines):
  - creates `~/.ssh`, `~/.ssh/config.d` and `~/.ssh/sockets` with the right permissions
  - adds `Include config.d/*.conf` to the top of `~/.ssh/config`, which stays a local, untracked file
  - generates `~/.ssh/id_ed25519` if there is none (asks for an optional passphrase)
  - on Termux: installs `openssh` + `termux-services`, starts `sshd` and enables it on every Termux launch
- `setup/setup.sh` (PC): installs Tailscale and `openssh-server`, enables `tailscaled`, enables `sshd` with password
  login disabled (`/etc/ssh/sshd_config.d/10-keys-only.conf`).
- `pair-phone` (fish function, run on the PC): exchanges the keys in both directions and tests the login.
- `mount-phone` / `umount-phone` (fish functions, run on the PC): mount the phone's storage with sshfs.

Never in git: private keys, `authorized_keys`, `known_hosts`. On the PC they come back from the backup
(`setup/backup.sh` saves `~/.ssh`), or are created by the steps below.

## Manual steps

### Fresh phone

1. Install **Termux** from F-Droid or GitHub (not the outdated Play Store build) and the **Tailscale** app.
2. Log in to Tailscale in the app. The phone shows up as `s21` (check with `tailscale status` on the PC).
3. In Termux:
   ```sh
   pkg install git
   git clone https://github.com/x0aa7i/dotfiles ~/dotfiles
   ~/dotfiles/install.sh
   ```
   Grant the storage permission when asked. Restart Termux once so `termux-services` takes over `sshd`.
4. Set a password for Termux's `sshd`, needed once for pairing:
   ```sh
   passwd
   ```
5. In Android settings, disable **battery optimization** for Termux and Tailscale, otherwise Android kills them in the
   background and `ssh s21` stops working.
6. On the PC, run `pair-phone` (see below).

### Fresh PC

1. Run `sudo ~/.dotfiles/setup/setup.sh` (see `setup/README.md`). Restoring the backup brings back `~/.ssh`.
2. Log in to Tailscale:
   ```sh
   sudo tailscale up
   ```
   Keep the default machine name `fedora`.
3. Run `pair-phone`. If the phone still has the old PC's host key, `pair-phone` clears it.

### Pairing

On the PC:

```fish
pair-phone              # defaults: phone s21, PC fedora
pair-phone pixel fedora # if the Tailscale names differ
```

It runs three steps:

1. Forgets the phone's old host key, then `ssh-copy-id` to the phone (asks for the Termux password).
2. Copies the phone's public key into the PC's `~/.ssh/authorized_keys`. This is why pairing runs from the PC: the
   PC refuses password logins, so the phone can't `ssh-copy-id` to it.
3. Logs in from the phone to the PC to test, accepting the PC's host key on the phone.

It is safe to re-run: existing keys are skipped and nothing is duplicated.

## Phone storage on the PC

```fish
mount-phone   # mounts the phone's internal storage (/storage/emulated/0) at ~/Phone
umount-phone  # unmounts it (also works if the phone went offline)
```

Both take optional arguments: `mount-phone [host] [mountpoint]`, `umount-phone [mountpoint]`. They need `sshfs`
(`fuse-sshfs`, in `setup/packages/fedora.txt`) and a paired phone. Termux needs the storage permission, which
`install.sh` asks for (`termux-setup-storage`).

The mount reconnects by itself when the phone sleeps or switches networks. If it hangs, run `umount-phone`, then
`mount-phone` again.

## Remote desktop (PC screen on the phone)

GNOME Remote Desktop (`gnome-remote-desktop`, installed with Fedora Workstation) serves the PC's screen over RDP,
reached through Tailscale like SSH. Nothing here is automated; it is set up once in GNOME Settings.

On the PC, in **Settings → System → Remote Desktop → Desktop Sharing**:

1. Turn on **Desktop Sharing** and **Remote Control** (without it the phone can only watch).
2. Set a username and password under **Login Details**. These are RDP-only credentials, not the Fedora login.

Manage it from Settings only: `grdctl rdp ...` keeps its own separate config, and `grdctl status` shows RDP as disabled
even while the Settings server is running.

On the phone, install **Windows App** (Microsoft's RDP client) and add a PC:

| Field        | Value                                                      |
| ------------ | ---------------------------------------------------------- |
| PC name      | `fedora:3390` (or `fedora.<tailnet>.ts.net:3390`)          |
| User account | the Desktop Sharing credentials, plain username, no domain |

Accept the certificate warning on the first connection. If `fedora` does not resolve on the phone, use the PC's
Tailscale IP (`tailscale ip -4`).

Port 3390, not 3389: GNOME's **Remote Login** (`gnome-remote-desktop.service`, a system service with its own login
screen) took 3389 when it was enabled once, so Desktop Sharing moved to 3390. Remote Login is not used: it can only
start a new session, and it refuses to attach to the one already running on the screen. Keep it off:

```sh
sudo grdctl --system rdp disable
sudo systemctl disable --now gnome-remote-desktop.service
```

### Locked screen

GNOME refuses Desktop Sharing while the screen is locked (log: `Session creation inhibited`). The
**Allow Locked Remote Desktop** extension
lifts that: the phone connects to the lock screen and unlocks it with the Fedora password. Install it with Extension
Manager.

Desktop Sharing only exists inside a logged-in session: after a reboot, log in at the PC once before connecting. The PC
must also be awake; to stop it suspending on AC power:

```sh
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
```

`tailscale0` is in firewalld's `trusted` zone, so the port is reachable over Tailscale.

## New device names

The names follow the device (Tailscale uses the OS hostname). With a new phone or a renamed PC:

1. Update `HostName` and the `Host` lines in `ssh/config.d/tailnet.conf`, and the defaults in
   `fish/functions/pair-phone.fish`.
2. Run `pair-phone <phone> <pc>`.

## Troubleshooting

| Symptom                                            | Fix                                                                                                                                        |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` on the PC | `ssh-keygen -R "[s21]:8022"`, or re-run `pair-phone`                                                                                       |
| Same on the phone                                  | `ssh-keygen -R fedora` in Termux, or re-run `pair-phone`                                                                                   |
| `ssh s21` times out                                | Termux or Tailscale was killed: open Termux (starts `sshd`), check battery optimization                                                    |
| `ssh fedora` refused                               | `sudo systemctl enable --now sshd` on the PC                                                                                               |
| Is password login off on the PC?                   | `sudo sshd -T \| grep -E '^(passwordauth\|kbdinteractive)'` should print `no` twice                                                        |
| Stale shared connection                            | `ssh -O exit s21` (or `fedora`) closes the reused connection                                                                               |
| Remote desktop rejects the login                   | Wrong Desktop Sharing credentials (log: `MIC verification failed`). Reset them in Settings, watch the phone keyboard's auto-capitalization |
| Remote desktop disconnects right away              | Screen locked (log: `Session creation inhibited`): enable Allow Locked Remote Desktop                                                      |
| Remote desktop log                                 | `journalctl --user -u gnome-remote-desktop -e`                                                                                             |
