function sshd-password -d "Turn password login for Termux's sshd on or off"
    # Usage: sshd-password [on|off]   (no argument: print the current setting)
    # Only needed on for pairing; pair-phone turns it off afterwards (see ssh/README.md)
    set -l prefix $PREFIX
    test -n "$prefix"; or set prefix /data/data/com.termux/files/usr
    set -l config $prefix/etc/ssh/sshd_config
    if not test -f $config
        echo "No $config, this is meant for Termux." >&2
        return 1
    end

    if test (count $argv) -eq 0
        grep -E '^PasswordAuthentication' $config; or echo "PasswordAuthentication yes (default)"
        return 0
    end

    set -l value
    switch $argv[1]
        case on
            set value yes
        case off
            set value no
        case '*'
            echo "Usage: sshd-password [on|off]" >&2
            return 1
    end

    if grep -qE '^#?PasswordAuthentication' $config
        sed -i -E "s/^#?PasswordAuthentication.*/PasswordAuthentication $value/" $config
    else
        echo "PasswordAuthentication $value" >>$config
    end

    # SIGHUP makes the listening sshd reload its config; open sessions keep running
    set -l pidfile $prefix/var/run/sshd.pid
    if test -f $pidfile
        kill -HUP (cat $pidfile)
    end
    echo "sshd password login: $argv[1]"
end
