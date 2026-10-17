local _, ns = ...

-- A HandyNotes plugin ("Kennel"): a pin on the world map and the minimap for every beast that can
-- teach the hunter a pet ability rank, with the icon of the best rank it has to offer. The beasts
-- and their pins come from Data\Beasts.lua; what the hunter knows from AbilityLearned (the ranks it
-- learned, and the highest per ability). Without HandyNotes, or on another class than a hunter,
-- the module does nothing.
--
-- A beast gets a pin when the hunter can tame it now (its lowest level at most the hunter's) and
-- it teaches a rank the hunter lacks: above the highest it knows, or, when asked, a lower one it
-- never learned. Settings turn both checks off.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelBeastMap
local M = Kennel:NewModule("BeastMap")
M.title = L.BEASTMAP_TITLE
M.description = L.BEASTMAP_DESC
M.defaults = { profile = { usefulOnly = true, gaps = false, aboveLevel = false } }

local PLUGIN = "Kennel"
local LACKING, KNOWN = { 0, 1, 0 }, { 0.5, 0.5, 0.5 }

---@return KennelBeastMapSettings
function M:Settings()
    return self.db.profile --[[@as KennelBeastMapSettings]]
end

-- Built on first use from the data: per map, its pins as npc, coord pairs (pins.at: coord ->
-- position, for the iterator); per beast, the ranks it teaches by ability and rank.
---@type table<number, KennelBeastMapPins>?
local byMap
---@type table<number, number[]>
local teaches = {}
-- The pin's icon per beast, or false for none; emptied when anything it depends on changes.
---@type table<number, number|string|false>
local shown = {}
---@type KennelBeastMapPins
local NO_PINS = { at = {} } --[[@as KennelBeastMapPins]]

---The beast data (Data\Beasts.lua), read when used: the specs put a small set in its place.
---@return KennelData
local function Data()
    return Kennel.data
end

---Fills byMap and teaches from the data, once.
---@param handyNotes HandyNotesApi
---@return table<number, KennelBeastMapPins>
local function Index(handyNotes)
    if byMap then return byMap end
    ---@type table<number, KennelBeastMapPins>
    local maps = {}
    byMap = maps
    local ranks, beasts = Data().petAbilityRanks, Data().beasts
    ---By ability, then rank.
    ---@param a number
    ---@param b number
    ---@return boolean
    local function before(a, b)
        if ranks[a].ability ~= ranks[b].ability then return ranks[a].ability < ranks[b].ability end
        return ranks[a].rank < ranks[b].rank
    end
    for spellID, rank in pairs(ranks) do
        for _, npc in ipairs(rank.teachers) do
            teaches[npc] = teaches[npc] or {}
            table.insert(teaches[npc], spellID)
        end
    end
    for _, list in pairs(teaches) do
        table.sort(list, before)
    end
    ---@type number[]
    local npcs = {}
    for npc in pairs(beasts) do
        npcs[#npcs + 1] = npc
    end
    table.sort(npcs)
    for _, npc in ipairs(npcs) do
        for map, flat in pairs(beasts[npc].pins or {}) do
            local pins = maps[map] or { at = {} } --[[@as KennelBeastMapPins]]
            maps[map] = pins
            for i = 1, #flat, 2 do
                local coord = handyNotes:getCoord(flat[i] / 100, flat[i + 1] / 100)
                -- One pin per spot: a second beast there would make the iterator skip.
                if not pins.at[coord] then
                    pins[#pins + 1] = npc
                    pins[#pins + 1] = coord
                    pins.at[coord] = #pins - 1
                end
            end
        end
    end
    return maps
end

---Whether the hunter lacks a rank: above the highest it knows of the ability ("above"), below it
---but never learned ("gap"), or not at all (nil). Without AbilityLearned's data, or a name for the
---ability, every rank counts as lacking.
---@param spellID number
---@return "above"|"gap"|nil
local function Lacking(spellID)
    local rank = Data().petAbilityRanks[spellID]
    local name = Kennel.SpellInfo(rank.ability)
    local known = Kennel:GetModule("AbilityLearned", true) --[[@as KennelAbilityLearned?]]
    if not name or not known then return "above" end
    if rank.rank > (known:HighestRank(name) or 0) then return "above" end
    if not known:HasRank(name, rank.rank) then return "gap" end
    return nil
end

---The hunter's level; PLAYER_LEVEL_UP gives the new one before UnitLevel does.
---@return number
function M:PlayerLevel()
    return self.level or UnitLevel("player")
end

---The icon of the pin for a beast, or false for no pin.
---@param npc number
---@return number|string|false
local function Icon(npc)
    local cached = shown[npc]
    if cached ~= nil then return cached end
    local settings = M:Settings()
    local beast = Data().beasts[npc]
    ---@type number?
    local best, wanted
    if settings.aboveLevel or beast.minLevel <= M:PlayerLevel() then
        for _, spellID in ipairs(teaches[npc]) do
            local lacking = Lacking(spellID)
            if lacking == "above" or (lacking == "gap" and settings.gaps) then wanted = spellID end
            best = spellID
        end
    end
    local pick = wanted or (not settings.usefulOnly and best)
    if not pick then
        shown[npc] = false
        return false
    end
    local _, icon = Kennel.SpellInfo(pick)
    shown[npc] = icon or 134400 -- the question mark icon
    return shown[npc]
end

---HandyNotes' iterator over a map's pins: the coord of the last pin returned leads to the next.
---@param pins KennelBeastMapPins
---@param coord number?
---@return number? coord
---@return nil uiMapID the map asked for
---@return (number|string)? icon
local function NextPin(pins, coord)
    local i = coord and pins.at[coord] + 2 or 1
    while pins[i] do
        local icon = Icon(pins[i])
        ---@type number
        local at = pins[i + 1]
        if icon then return at, nil, icon end
        i = i + 2
    end
    return nil
end

-- The handler HandyNotes calls. OnEnter and OnLeave get the pin as self.
local handler = {}

---@param uiMapID number
---@return function, KennelBeastMapPins, nil
function handler:GetNodes2(uiMapID)
    -- HandyNotes is loaded: it is the one asking.
    if not M:IsEnabled() then return NextPin, NO_PINS, nil end
    return NextPin, Index(HandyNotes --[[@as HandyNotesApi]])[uiMapID] or NO_PINS, nil
end

---"Level 5-6", "Level 10, rare elite".
---@param beast KennelBeast
---@return string
local function LevelText(beast)
    local level = beast.minLevel == beast.maxLevel and tostring(beast.minLevel)
        or beast.minLevel .. "-" .. beast.maxLevel
    local kind = beast.rare and beast.elite and L.BEASTMAP_RARE_ELITE
        or beast.rare and L.BEASTMAP_RARE
        or beast.elite and L.BEASTMAP_ELITE
        or ""
    return L.BEASTMAP_LEVEL:format(level) .. kind
end

---The tooltip: the beast's name, level, and every rank it teaches, green for one the hunter lacks.
---@param pin Frame
---@param uiMapID number
---@param coord number
function handler.OnEnter(pin, uiMapID, coord)
    local pins = byMap and byMap[uiMapID]
    local at = pins and pins.at[coord]
    if not at then return end
    ---@type number
    local npc = pins[at]
    local beast = Data().beasts[npc]
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(beast.name)
    GameTooltip:AddLine(LevelText(beast), 1, 1, 1)
    for _, spellID in ipairs(teaches[npc]) do
        local name, _, rank = Kennel.SpellInfo(spellID)
        if name then
            local color = Lacking(spellID) and LACKING or KNOWN
            GameTooltip:AddLine(rank and ("%s (%s)"):format(name, rank) or name, color[1], color[2], color[3])
        end
    end
    GameTooltip:Show()
end

function handler.OnLeave()
    GameTooltip:Hide()
end

---Forgets the pins' icons and has HandyNotes draw them again.
function M:Refresh()
    wipe(shown)
    if not HandyNotes then return end
    HandyNotes:UpdateWorldMapPlugin(PLUGIN)
    HandyNotes:UpdateMinimapPlugin(PLUGIN)
end

---@param _ string the event
---@param level number the new level
function M:PLAYER_LEVEL_UP(_, level)
    self.level = level
    self:Refresh()
end

-- Registered once: HandyNotes keeps a plugin for the session.
local registered = false

function M:OnEnable()
    local _, class = UnitClass("player")
    if not HandyNotes or class ~= "HUNTER" then return end
    if not registered then
        registered = true
        HandyNotes:RegisterPluginDB(
            PLUGIN,
            handler,
            { type = "group", name = L.BEASTMAP_TITLE, args = self:GetOptions().args }
        )
    end
    self.level = nil
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterMessage("KENNEL_RANKS_KNOWN", "Refresh")
    self:Refresh()
end

function M:OnDisable()
    self:Refresh()
end
