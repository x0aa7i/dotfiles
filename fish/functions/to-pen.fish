function to-pen -d "Send the figcraft selection to the open pen.dev file"
    # Usage: to-pen [ids…] [--check DIR]   (no ids: the selection; see ~/.claude/skills/figcraft/PEN-BRIDGE.md)
    set -q FIGCRAFT_KIT; or set -lx FIGCRAFT_KIT /mnt/backup/documents/obsidian/60-system/libraries/kit.figcraft
    node ~/.claude/skills/figcraft/scripts/pen-figcraft.mjs to-pen $argv
end
