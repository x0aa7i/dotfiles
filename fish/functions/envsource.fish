function envsource
    for line in (cat $argv | grep -v '^#')
        set item (string split -n -m 1 '=' $line)
        if test (count $item) -ne 2
            continue
        end
        set -gx $item[1] $item[2]
    end
end
