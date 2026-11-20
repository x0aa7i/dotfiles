function to-fig -d "Send the pen.dev selection to the open figcraft file"
    # Usage: to-fig [ids…] [--check DIR]   (no ids: the selection; see pen-figcraft --help)
    set -q FIGCRAFT_KIT; or set -lx FIGCRAFT_KIT /mnt/backup/documents/obsidian/60-system/libraries/kit.figcraft
    pen-figcraft to-figcraft $argv
end
