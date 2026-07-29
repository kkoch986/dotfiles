-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples
--
-- Sourced AFTER the default keybinds, so we unbind the stock action before
-- rebinding it (Hyprland stacks binds on the same key instead of replacing).

local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"

-- Super+A: focus the previous workspace (was: toggle left sidebar)
hl.unbind("SUPER + A")
hl.bind("SUPER + A", hl.dsp.focus({ workspace = "previous" }),
    { description = "Workspace: Focus previous" })

-- Move the tap-Super launcher/search onto Super+D.
-- Removes the "tap Super to open search" bind, and drops Super+D's old Maximize.
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")
hl.unbind("SUPER + D")
hl.bind("SUPER + D", hl.dsp.global("quickshell:searchToggle"),
    { description = "Shell: Toggle search" })
hl.bind("SUPER + D", hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || fuzzel"))
