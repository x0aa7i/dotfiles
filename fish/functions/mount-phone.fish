function mount-phone -d "Mount the phone's internal storage over sshfs (Tailscale)"
    # Usage: mount-phone [host] [mountpoint]   (defaults: s21 ~/Phone, unmount: umount-phone)
    set -l host s21
    set -l mnt ~/Phone
    test (count $argv) -ge 1; and set host $argv[1]
    test (count $argv) -ge 2; and set mnt $argv[2]

    if mountpoint -q $mnt
        echo "Already mounted at $mnt"
        return 0
    end

    mkdir -p $mnt
    # Own connection (no ControlMaster) so the mount survives other ssh sessions closing;
    # reconnect + keepalive handle the phone sleeping or switching networks
    sshfs $host:/storage/emulated/0 $mnt \
        -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        -o ControlMaster=no,idmap=user,follow_symlinks
    and echo "Phone storage mounted at $mnt"
end
