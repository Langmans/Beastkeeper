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
-- A beast in an instance has no map of its own: its instance gets one pin at the dungeon entrance
-- the client lists for a map (C_EncounterJournal), standing for every beast inside.
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
M.toastTypes = { reach = L.BEASTMAP_TOASTTYPE_REACH, rare = L.BEASTMAP_TOASTTYPE_RARE }
M.defaults = {
    profile = {
        pins = true,
        mapButton = true,
        usefulOnly = true,
        gaps = false,
        aboveLevel = false,
        levelToast = true,
        tooltip = true,
        rareToast = true,
        trainers = true,
        stables = true,
    },
}

local PLUGIN = "Kennel"
-- The route library (Libs\LibGoThere-1.0): sends the hunter to a beast.
local GoThere = LibStub("LibGoThere-1.0") --[[@as LibGoThere]]
local LACKING, KNOWN = { 0, 1, 0 }, { 0.5, 0.5, 0.5 }
-- Per kind of trainer (Data\Trainers.lua): its setting, its pin's icon (Beast Training, Call
-- Pet) and the line under its name.
---@type table<string, {setting: string, icon: number, label: string}>
local TRAINER_KINDS = {
    trainer = { setting = "trainers", icon = 132162, label = L.BEASTMAP_PET_TRAINER },
    stable = { setting = "stables", icon = 132161, label = L.BEASTMAP_STABLE_MASTER },
}

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
-- Per instance (AreaTable ID), the beasts in it, by NPC ID; filled with byMap. The maps whose
-- dungeon entrances were looked up.
---@type table<number, number[]>
local inInstance = {}
---@type table<number, true>
local entrancesRead = {}
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

---Adds a pin to a map's pins, unless the spot has one: a second there would make the iterator skip.
---@param maps table<number, KennelBeastMapPins>
---@param map number uiMapID
---@param id number a beast's NPC ID, or minus an instance's AreaTable ID
---@param coord number
local function AddPin(maps, map, id, coord)
    local pins = maps[map] or { at = {} } --[[@as KennelBeastMapPins]]
    maps[map] = pins
    if pins.at[coord] then return end
    pins[#pins + 1] = id
    pins[#pins + 1] = coord
    pins.at[coord] = #pins - 1
end

---Per map, its pins; built once. A beast in an instance waits in `inInstance` for its entrance.
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
            for i = 1, #flat, 2 do
                AddPin(maps, map, npc, handyNotes:getCoord(flat[i] / 100, flat[i + 1] / 100))
            end
        end
        for _, area in ipairs(beasts[npc].zones or {}) do
            inInstance[area] = inInstance[area] or {}
            table.insert(inInstance[area], npc)
        end
    end
    -- Pet trainers and stable masters (Data\Trainers.lua), after the beasts; NPC IDs of their own.
    local trainers = Data().trainers or {}
    wipe(npcs)
    for npc in pairs(trainers) do
        npcs[#npcs + 1] = npc
    end
    table.sort(npcs)
    for _, npc in ipairs(npcs) do
        for map, flat in pairs(trainers[npc].pins) do
            for i = 1, #flat, 2 do
                AddPin(maps, map, npc, handyNotes:getCoord(flat[i] / 100, flat[i + 1] / 100))
            end
        end
    end
    return maps
end

---Adds a pin at each dungeon entrance on a map whose instance has beasts, the first time the map
---is asked for. The client names an entrance as the instance's area, so the names are matched.
---@param handyNotes HandyNotesApi
---@param uiMapID number
local function AddEntrances(handyNotes, uiMapID)
    local maps = Pins(handyNotes)
    if entrancesRead[uiMapID] or not C_EncounterJournal then return end
    entrancesRead[uiMapID] = true
    for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID)) do
        for area in pairs(inInstance) do
            if C_Map.GetAreaInfo(area) == entrance.name then
                AddPin(maps, uiMapID, -area, handyNotes:getCoord(entrance.position:GetXY()))
            end
        end
    end
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

---A trainer's or stable master's entry, or nil for a beast.
---@param npc number
---@return KennelTrainer?
local function Trainer(npc)
    local trainers = Data().trainers
    return trainers and trainers[npc]
end

---The hunter's level; PLAYER_LEVEL_UP gives the new one before UnitLevel does.
---@return number
function M:PlayerLevel()
    return self.level or UnitLevel("player")
end

---The icon of the pin for a beast, or false for no pin. An instance's pin (a negative ID) has the
---icon of the first beast in it that gets one.
---@param npc number
---@return number|string|false
local function Icon(npc)
    if npc < 0 then
        for _, inside in ipairs(inInstance[-npc]) do
            local icon = Icon(inside)
            if icon then return icon end
        end
        return false
    end
    local cached = shown[npc]
    if cached ~= nil then return cached end
    local settings = M:Settings()
    local trainer = Trainer(npc)
    -- A trainer: its kind's pin, when that kind is switched on and it serves the hunter's faction.
    if trainer then
        local kind = TRAINER_KINDS[trainer.kind]
        local forUs = not trainer.side or trainer.side == UnitFactionGroup("player")
        shown[npc] = settings[kind.setting] and forUs and kind.icon or false
        return shown[npc]
    end
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
    if not M:IsEnabled() or not M:Settings().pins then return NextPin, NO_PINS, nil end
    local handyNotes = HandyNotes --[[@as HandyNotesApi]]
    AddEntrances(handyNotes, uiMapID)
    return NextPin, Pins(handyNotes)[uiMapID] or NO_PINS, nil
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

---A beast's name as the client words it, else as the data has it (English).
---@param npc number
---@return string
local function BeastName(npc)
    return Kennel.CreatureName(npc) or Data().beasts[npc].name
end

---"Claw (Rank 2)" as the client names it; nil when it cannot name the spell.
---@param spellID number
---@return string?
local function RankText(spellID)
    local name, _, rank = Kennel.SpellInfo(spellID)
    return name and rank and ("%s (%s)"):format(name, rank) or name
end

-- For the unit tooltip (Tooltip.lua) and the rare alarm (Rare.lua): what a beast teaches, how the
-- hunter stands to a rank, a beast's name and level.
M.RankText, M.Lacking, M.LevelText, M.BeastName = RankText, Lacking, LevelText, BeastName

---The rank spells a beast teaches, in order; nil for a beast that teaches none.
---@param npc number
---@return number[]?
function M.TeachesOf(npc)
    return Teaches()[npc]
end

---A pin's name: the beast's or trainer's (as the client words it once it knows the NPC), or the
---instance's for a dungeon entrance (a negative ID).
---@param id number
---@return string
local function PinName(id)
    if id < 0 then
        return C_Map.GetAreaInfo(-id) --[[@as string]]
    end
    local trainer = Trainer(id)
    if trainer then return Kennel.CreatureName(id) or trainer.name end
    return BeastName(id)
end

---Every rank a beast teaches, in the tooltip; green for one the hunter lacks.
---@param npc number
local function AddRanks(npc)
    for _, spellID in ipairs(Teaches()[npc]) do
        local text = RankText(spellID)
        if text then
            local color = Lacking(spellID) and LACKING or KNOWN
            GameTooltip:AddLine(text, color[1], color[2], color[3])
        end
    end
end

---The tooltip: the beast's name, level and ranks; at a dungeon entrance, the instance's name and
---so for each beast inside that gets a pin.
---@param pin Frame
---@param uiMapID number
---@param coord number
function handler.OnEnter(pin, uiMapID, coord)
    local pins = byMap and byMap[uiMapID]
    local at = pins and pins.at[coord]
    if not at then return end
    ---@type number
    local id = pins[at]
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(PinName(id))
    if id < 0 then
        for _, npc in ipairs(inInstance[-id]) do
            if Icon(npc) then
                GameTooltip:AddLine(L.BEASTMAP_INSIDE:format(BeastName(npc), LevelText(Data().beasts[npc])), 1, 1, 1)
                AddRanks(npc)
            end
        end
    elseif Trainer(id) then
        GameTooltip:AddLine(
            TRAINER_KINDS[
                (Trainer(id) --[[@as KennelTrainer]]).kind
            ].label,
            1,
            1,
            1
        )
    else
        GameTooltip:AddLine(LevelText(Data().beasts[id]), 1, 1, 1)
        AddRanks(id)
    end
    GameTooltip:AddLine(L.BEASTMAP_CLICK, KNOWN[1], KNOWN[2], KNOWN[3])
    GameTooltip:Show()
end

function handler.OnLeave()
    GameTooltip:Hide()
end

---A left click (as the button comes up) sends the hunter to the beast, through LibGoThere-1.0:
---a route, an arrow or the game's waypoint, whichever addon the player has, else a pin link.
---@param _ Frame the pin
---@param button string
---@param down boolean
---@param uiMapID number
---@param coord number
function handler.OnClick(_, button, down, uiMapID, coord)
    local pins = byMap and byMap[uiMapID]
    local at = pins and pins.at[coord]
    if button ~= "LeftButton" or down or not at then return end
    ---@type number
    local id = pins[at]
    local x, y = (HandyNotes --[[@as HandyNotesApi]]):getXY(coord)
    GoThere:Navigate("Kennel", uiMapID, x, y, PinName(id))
    -- A beast's pin also makes it the tame key's beast (Tame.lua).
    if id > 0 and not Trainer(id) then M:SetTameTarget(BeastName(id)) end
end

---Forgets the pins' icons and has HandyNotes draw them again; shows or hides the map button.
function M:Refresh()
    wipe(shown)
    self:UpdateMapButton()
    if not HandyNotes then return end
    HandyNotes:UpdateWorldMapPlugin(PLUGIN)
    HandyNotes:UpdateMinimapPlugin(PLUGIN)
end

---A beast's first map by uiMapID; nil for a beast in an instance, which has only zones.
---@param beast KennelBeast
---@return number?
local function FirstMap(beast)
    ---@type number?
    local first
    for map in pairs(beast.pins or {}) do
        if not first or map < first then first = map end
    end
    return first
end

---Seconds to a beast's first pin, as the player's route addon works it out (LibGoThere); a huge
---number when there is none to ask, or no route.
---@param npc number
---@return number
local function TravelSeconds(npc)
    local beast = Data().beasts[npc]
    local map = FirstMap(beast)
    if not map then return math.huge end
    local pin = (beast.pins --[[@as table<number, number[]> ]])[map]
    return GoThere:TravelTime(map, pin[1] / 100, pin[2] / 100) or math.huge
end

---Whether beast `npc` is the better one to name than `pick`: an ordinary one before a rare, then
---the one reached first.
---@param npc number
---@param pick number?
---@return boolean
local function Better(npc, pick)
    if not pick then return true end
    local beasts = Data().beasts
    if beasts[npc].rare ~= beasts[pick].rare then return not beasts[npc].rare end
    return TravelSeconds(npc) < TravelSeconds(pick)
end

---The beast of exactly `level` that teaches a rank, the better one when there are several; nil
---when a lower beast teaches it already, or none of that level does.
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
        if beast.minLevel == level and Better(npc, pick) then pick = npc end
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
    local first = FirstMap(beast)
    if first then
        local info = C_Map.GetMapInfo(first)
        where = info and info.name
    else
        -- A beast has pins or, in an instance, zones (the data spec checks it).
        where = C_Map.GetAreaInfo((beast.zones --[[@as number[] ]])[1])
    end
    local name = BeastName(npc)
    return where and L.BEASTMAP_REACH_PLACE:format(name, where) or name
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
        self:CreateMapButton()
    end
    self.level = nil
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterMessage("KENNEL_RANKS_KNOWN", "Refresh")
    self:WatchRares()
    self:ApplyTameButton()
    self:Refresh()
end

function M:OnDisable()
    self:ApplyTameButton()
    self:Refresh()
end
