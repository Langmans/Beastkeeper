local _, ns = ...

-- A HandyNotes plugin ("Kennel"): a pin on the world map and the minimap for every beast that can
-- teach the hunter a pet ability rank, with the icon of the best rank it has to offer. The beasts
-- and their pins come from Data\Beasts.lua; what the hunter knows from AbilityLearned (the ranks it
-- learned, and the highest per ability). On another class than a hunter the module does nothing.
--
-- A beast gets a pin when the hunter can tame it now (its lowest level at most the hunter's) and
-- it teaches a rank the hunter lacks: above the highest it knows, or, when asked, a lower one it
-- never learned. Settings turn both checks off.
--
-- At a level-up, also without HandyNotes, a toast names the ranks the hunter lacks that a beast of
-- just that level brings in reach, where no lower beast taught them already.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelBeastMap
local M = Kennel:NewModule("BeastMap")
M.title = L.BEASTMAP_TITLE
M.description = L.BEASTMAP_DESC
M.toastTypes = { reach = L.BEASTMAP_TOASTTYPE_REACH }
M.defaults = { profile = { usefulOnly = true, gaps = false, aboveLevel = false, levelToast = true } }

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
---@type table<number, number[]>?
local teaches
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

---Two rank spells in order: by ability, then rank.
---@param a number
---@param b number
---@return boolean
local function Before(a, b)
    local ranks = Data().petAbilityRanks
    if ranks[a].ability ~= ranks[b].ability then return ranks[a].ability < ranks[b].ability end
    return ranks[a].rank < ranks[b].rank
end

---Per beast, the rank spells it teaches in order; built once.
---@return table<number, number[]>
local function Teaches()
    if teaches then return teaches end
    ---@type table<number, number[]>
    local list = {}
    teaches = list
    for spellID, rank in pairs(Data().petAbilityRanks) do
        for _, npc in ipairs(rank.teachers) do
            list[npc] = list[npc] or {}
            table.insert(list[npc], spellID)
        end
    end
    for _, spells in pairs(list) do
        table.sort(spells, Before)
    end
    return list
end

---Per map, its pins; built once.
---@param handyNotes HandyNotesApi
---@return table<number, KennelBeastMapPins>
local function Pins(handyNotes)
    if byMap then return byMap end
    ---@type table<number, KennelBeastMapPins>
    local maps = {}
    byMap = maps
    local beasts = Data().beasts
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
        for _, spellID in ipairs(Teaches()[npc]) do
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
    return NextPin, Pins(HandyNotes --[[@as HandyNotesApi]])[uiMapID] or NO_PINS, nil
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

---"Claw (Rank 2)" as the client names it; nil when it cannot name the spell.
---@param spellID number
---@return string?
local function RankText(spellID)
    local name, _, rank = Kennel.SpellInfo(spellID)
    return name and rank and ("%s (%s)"):format(name, rank) or name
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
    for _, spellID in ipairs(Teaches()[npc]) do
        local text = RankText(spellID)
        if text then
            local color = Lacking(spellID) and LACKING or KNOWN
            GameTooltip:AddLine(text, color[1], color[2], color[3])
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

---The beast of exactly `level` that teaches a rank, an ordinary one before a rare; nil when a
---lower beast teaches it already, or none of that level does.
---@param rank KennelPetAbilityRank
---@param level number
---@return number?
local function NewTeacher(rank, level)
    local beasts = Data().beasts
    ---@type number?
    local pick
    for _, npc in ipairs(rank.teachers) do
        local beast = beasts[npc]
        if beast.minLevel < level then return nil end
        if beast.minLevel == level and (not pick or (beasts[pick].rare and not beast.rare)) then pick = npc end
    end
    return pick
end

---"Ridge Stalker in Badlands": the beast and its first map by uiMapID, or its zone when it lives in
---an instance; the beast alone when the client has no name for either.
---@param npc number
---@return string
local function Place(npc)
    local beast = Data().beasts[npc]
    ---@type string?
    local where
    if beast.pins then
        ---@type number?
        local first
        for map in pairs(beast.pins) do
            if not first or map < first then first = map end
        end
        local info = C_Map.GetMapInfo(first --[[@as number]])
        where = info and info.name
    else
        -- A beast has pins or, in an instance, zones (the data spec checks it).
        where = C_Map.GetAreaInfo((beast.zones --[[@as number[] ]])[1])
    end
    return where and L.BEASTMAP_REACH_PLACE:format(beast.name, where) or beast.name
end

---The toast for the ranks a level-up brings in reach, if any.
---@param level number
function M:ToastReach(level)
    local settings = self:Settings()
    ---@type number[], table<number, number>
    local found, teacherOf = {}, {}
    for spellID, rank in pairs(Data().petAbilityRanks) do
        local lacking = Lacking(spellID)
        local teacher = (lacking == "above" or (lacking == "gap" and settings.gaps)) and NewTeacher(rank, level)
        if teacher then
            found[#found + 1] = spellID
            teacherOf[spellID] = teacher
        end
    end
    if #found == 0 then return end
    table.sort(found, Before)
    local title, text
    if #found == 1 then
        title = L.BEASTMAP_REACH_ONE:format(RankText(found[1]) or "?")
        text = L.BEASTMAP_REACH_TEACHES:format(Place(teacherOf[found[1]]))
    else
        title = L.BEASTMAP_REACH_MANY:format(#found)
        ---@type string[]
        local lines = {}
        for i, spellID in ipairs(found) do
            lines[i] = L.BEASTMAP_REACH_LINE:format(RankText(spellID) or "?", Place(teacherOf[spellID]))
        end
        text = table.concat(lines, "\n")
    end
    local _, icon = Kennel.SpellInfo(found[1])
    Kennel:ShowToast({
        key = "BeastMap:reach",
        type = "BeastMap:reach",
        source = self.title,
        title = title,
        text = text,
        icon = icon,
    })
end

---@param _ string the event
---@param level number the new level
function M:PLAYER_LEVEL_UP(_, level)
    self.level = level
    self:Refresh()
    if self:Settings().levelToast then self:ToastReach(level) end
end

-- Registered once: HandyNotes keeps a plugin for the session.
local registered = false

function M:OnEnable()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    if HandyNotes and not registered then
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
