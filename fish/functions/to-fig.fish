function to-fig -d "Send the pen.dev selection to the open figcraft file"
    # Usage: to-fig [ids…] [--check DIR]   (no ids: the selection; see ~/.claude/skills/figcraft/PEN-BRIDGE.md)
    set -q FIGCRAFT_KIT; or set -lx FIGCRAFT_KIT /mnt/backup/documents/obsidian/60-system/libraries/kit.figcraft
    node ~/.claude/skills/figcraft/scripts/pen-figcraft.mjs to-figcraft $argv
end
