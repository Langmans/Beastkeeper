local _, ns = ...

-- The rare alarm: a toast when a rare beast that teaches a rank the hunter lacks comes in sight,
-- once per spawn. In sight: on the minimap (its vignette), as a nameplate, the target or under
-- the mouse; each gives a creature GUID, whose sixth field is the NPC ID. What counts follows the
-- map's settings: a rank above the highest known, a lower one never learned when gaps count,
-- and only a beast the hunter can tame now unless beasts above its level count. Also without
-- HandyNotes.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("BeastMap") --[[@as KennelBeastMap]]

local RAID_WARNING = 8959 -- SOUNDKIT.RAID_WARNING
-- Not every client has every one; a missing one is skipped.
local EVENTS = { "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "VIGNETTE_MINIMAP_UPDATED" }

-- The spawns alarmed about this session, by GUID; the ranks of the beast being looked at.
---@type table<string, true>
local alarmed = {}
---@type string[]
local lines = {}

---The ranks a beast teaches that the hunter wants, as tooltip-style lines in `lines` (emptied
---first); the first one's spell for the icon.
---@param npc number
---@return number? first
local function WantedRanks(npc)
    wipe(lines)
    local settings = M:Settings()
    ---@type number?
    local first
    -- Every beast in the data teaches something: that is why it is there.
    local ranks = M.TeachesOf(npc) --[[@as number[] ]]
    for _, spellID in ipairs(ranks) do
        local lacking = M.Lacking(spellID)
        local rank = M.RankText(spellID)
        if rank and (lacking == "above" or (lacking == "gap" and settings.gaps)) then
            first = first or spellID
            lines[#lines + 1] = L.BEASTMAP_RARE_TEACHES:format(rank)
        end
    end
    return first
end

---Toasts the creature with `guid` when it is a rare beast worth taming, and not yet this spawn.
---@param guid GameValue
function M:SeeCreature(guid)
    if not self:IsEnabled() or not self:Settings().rareToast then return end
    local npc = Kennel.NPCFromGUID(guid, "Creature")
    if not npc then return end
    -- A GUID that gave an NPC ID is a readable string.
    local spawn = guid --[[@as string]]
    local beast = Kennel.data.beasts[npc] --[[@as KennelBeast?]]
    if not beast or not beast.rare or alarmed[spawn] then return end
    if not self:Settings().aboveLevel and beast.minLevel > self:PlayerLevel() then return end
    local first = WantedRanks(npc)
    if not first then return end
    alarmed[spawn] = true
    local _, icon = Kennel.SpellInfo(first)
    Kennel:ShowToast({
        key = "BeastMap:rare:" .. spawn,
        type = "BeastMap:rare",
        source = self.title,
        title = L.BEASTMAP_RARE_TOAST:format(M.BeastName(npc)),
        text = table.concat(lines, "\n"),
        hint = M.LevelText(beast),
        icon = icon,
        sound = { kit = RAID_WARNING },
    })
end

---@param _ string the event
---@param unit string
function M:NAME_PLATE_UNIT_ADDED(_, unit)
    self:SeeCreature(UnitGUID(unit))
end

function M:PLAYER_TARGET_CHANGED()
    self:SeeCreature(UnitGUID("target"))
end

function M:UPDATE_MOUSEOVER_UNIT()
    self:SeeCreature(UnitGUID("mouseover"))
end

---@param _ string the event
---@param vignetteGUID string
---@param onMinimap boolean
function M:VIGNETTE_MINIMAP_UPDATED(_, vignetteGUID, onMinimap)
    -- Forever's and Retail's; this event does not come elsewhere.
    local get = C_VignetteInfo and C_VignetteInfo.GetVignetteInfo
    local info = onMinimap and get and get(vignetteGUID)
    if info then self:SeeCreature(info.objectGUID) end
end

---Listens for creatures coming in sight; from OnEnable.
function M:WatchRares()
    for _, event in ipairs(EVENTS) do
        pcall(self.RegisterEvent, self, event)
    end
end
