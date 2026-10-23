function pair-phone -d "Exchange SSH keys with the phone (Termux sshd) over Tailscale"
    # Usage: pair-phone [phone-host] [pc-host]   (defaults: s21 fedora, see ssh/README.md)
    set -l phone s21
    set -l pc fedora
    test (count $argv) -ge 1; and set phone $argv[1]
    test (count $argv) -ge 2; and set pc $argv[2]

    if not test -f ~/.ssh/id_ed25519.pub
        echo "No ~/.ssh/id_ed25519.pub on this PC, run install.sh first." >&2
        return 1
    end

    # A reinstalled phone has a new host key, forget the old one. Close any shared
    # (ControlMaster) connection too, or the host key would never be checked again
    ssh-keygen -R "[$phone]:8022" >/dev/null 2>&1
    ssh -O exit $phone >/dev/null 2>&1

    echo "1/3 PC -> phone (asks for the Termux password set with `passwd`)"
    ssh-copy-id -o StrictHostKeyChecking=accept-new $phone; or return 1

    echo "2/3 phone -> PC"
    set -l pubkey (ssh $phone 'cat ~/.ssh/id_ed25519.pub' 2>/dev/null)
    if test -z "$pubkey"
        echo "No ~/.ssh/id_ed25519.pub on the phone, run install.sh there first." >&2
        return 1
    end
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    if not grep -qxF -- "$pubkey" ~/.ssh/authorized_keys
        echo $pubkey >>~/.ssh/authorized_keys
    end

    echo "3/3 testing phone -> PC login"
    # Also forgets a stale PC host key on the phone (e.g. after reinstalling the PC)
    ssh $phone "ssh -O exit $pc >/dev/null 2>&1; ssh-keygen -R $pc >/dev/null 2>&1; ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new $pc true"
    and echo "Paired: 'ssh $phone' here, 'ssh $pc' on the phone."
    or echo "Phone -> PC login failed, is sshd running here? (sudo systemctl enable --now sshd)" >&2
end
