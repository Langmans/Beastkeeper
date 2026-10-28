local _, ns = ...

-- A beast's tooltip says which pet ability ranks it teaches, from the beast data, and how the
-- hunter stands to each: new (above the highest it knows), a lower rank it never learned, or
-- known (Beastkeeper.OnUnitTooltip); the creature's NPC ID is its GUID's sixth field. Also without
-- HandyNotes; only for a hunter.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as AddonBeastMap]]

-- Per standing: the line's ending and its colour.
---@type table<string, {text: string, color: number[]}>
local STANDING = {
    above = { text = L.BEASTMAP_TOOLTIP_NEW, color = { 0, 1, 0 } },
    gap = { text = L.BEASTMAP_TOOLTIP_GAP, color = { 1, 1, 0 } },
    known = { text = L.BEASTMAP_TOOLTIP_KNOWN, color = { 0.5, 0.5, 0.5 } },
}
-- For a unit that teaches nothing: every hovered unit passes here.
---@type number[]
local NOTHING = {}

---Whether a beast's tooltip gets the lines: the module on, its switch on, for a hunter.
---@return boolean
local function Wanted()
    local _, class = UnitClass("player")
    return M:IsEnabled() and M:Settings().tooltip and class == "HUNTER"
end

---Adds the ranks a beast teaches to the game's tooltip of it.
---@param tooltip GameTooltip
---@param guid GameValue
local function OnUnitTooltip(tooltip, guid)
    if tooltip ~= GameTooltip or not Wanted() then return end
    local npc = Addon.NPCFromGUID(guid, "Creature")
    ---@type number[]
    local ranks = npc and M.TeachesOf(npc) or NOTHING
    for _, spellID in ipairs(ranks) do
        local rank = M.RankText(spellID)
        if rank then
            local standing = STANDING[M.Lacking(spellID) or "known"]
            local color = standing.color
            local _, icon = Addon.SpellInfo(spellID)
            local line = L.BEASTMAP_TOOLTIP_TEACHES:format(rank, standing.text)
            if icon then line = ("|T%s:0|t %s"):format(icon, line) end
            tooltip:AddLine(line, color[1], color[2], color[3])
        end
    end
end

Addon.OnUnitTooltip(OnUnitTooltip)
