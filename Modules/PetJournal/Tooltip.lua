local _, ns = ...

-- The journal in a pet's tooltip (the pet frame's, or the pet under the mouse): a few grey lines
-- under the game's own, for a pet in this character's journal (Beastkeeper.OnUnitTooltip); the pet's
-- number comes from its GUID.

---@type Addon
local Addon = ns
local M = Addon:GetModule("PetJournal") --[[@as AddonPetJournal]]

local GREY = { 0.6, 0.6, 0.6 }

---Adds the pet's journal, brief, to the game's tooltip of it.
---@param tooltip GameTooltip
---@param guid GameValue
Addon.OnUnitTooltip(function(tooltip, guid)
    if tooltip ~= GameTooltip or not M:IsEnabled() or not M:Settings().tooltip then return end
    local number = Addon.PetNumberFromGUID(guid)
    if not number then return end
    for _, line in ipairs(M:JournalLines(tostring(number), true)) do
        tooltip:AddLine(line, GREY[1], GREY[2], GREY[3], true)
    end
end)
