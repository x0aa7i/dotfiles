function to-pen -d "Send the figcraft selection to the open pen.dev file"
    # Usage: to-pen [ids…] [--check DIR]   (no ids: the selection; see pen-figcraft --help)
    set -q FIGCRAFT_KIT; or set -lx FIGCRAFT_KIT /mnt/backup/documents/obsidian/60-system/libraries/kit.figcraft
    pen-figcraft to-pen $argv
end
