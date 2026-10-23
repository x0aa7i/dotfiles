function umount-phone -d "Unmount the phone storage mounted by mount-phone"
    set -l mnt ~/Phone
    test (count $argv) -ge 1; and set mnt $argv[1]

    if not mountpoint -q $mnt
        echo "Nothing mounted at $mnt"
        return 0
    end

    # -z: lazy unmount, works even if the phone is unreachable or a shell is inside
    fusermount3 -uz $mnt; and rmdir $mnt 2>/dev/null
    and echo "Unmounted $mnt"
end
