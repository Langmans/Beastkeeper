--@debug@
local _, ns = ...

-- A probe for development: keeps in BeastkeeperDB (DevProbe's global namespace) what Beastkeeper cannot learn
-- from the API documentation, to read back from the SavedVariables after playing:
--   stable      C_StableInfo's entry of each pet, as the lists give it
--   petSpells   each spell a pet gets: its name and rank, the rank before, the pet's level and
--               family, and how it came ("level" right after a level-up, "training" with the
--               trainer window open, else "other"): how Forever's family abilities arrive
--   foods       C_PetInfo.GetPetFoodTypes per family; families: the client's family names
--   lowerRanks  a rank the hunter learned below the highest it knew of that ability
--   guids       the pet's GUID at UNIT_PET and LOCALPLAYER_PET_RENAMED (around a tame)
--   client      at each login: the build, the project ID and season, LibTameable's client, which
--               APIs the hunt's areas lean on exist, the raw returns of UnitPosition, the map
--               position, the ammo slot's count, the ranged speed and each bag's free slots and type
--   combat      the first fight's: whether the pet's health and the player's place still read
--   pet         the raw returns of happiness, loyalty and training points, C_PetInfo's and the
--               old globals'
--   trainer     the trainer window's first rows, as GetTrainerServiceInfo gives them
--   tames       after a tame: the spells the pet knows beside the ranks LibTameable says the beast
--               teaches, and whether they match (the server's word on the CMaNGOS data)
--   beasts      per beast in LibTameable's data, its first sighting: the player's map and place,
--               and whether the data has the beast on that map
-- A raw return that the client hides (a secret value) is kept as "secret"; a missing API as
-- "missing"; one that errors as "error: ...".
-- Each finding also goes to Beastkeeper:Log (OAP Debug). Like Dev Screenshots the whole file is a
-- --@debug@ block, so only a copy straight from the repository has it. Off until switched on.

---@type Addon
local Addon = ns

---@type AddonDevProbe
local M = Addon:NewModule("DevProbe")
M.title = "Dev Probe"
M.description = "Keeps what the client says of pets, stable and families. Repository copies only."
M.enabledByDefault = false
M.defaults = {
    global = {
        stable = {},
        petSpells = {},
        foods = {},
        families = {},
        lowerRanks = {},
        guids = {},
        client = {},
        pet = {},
        trainer = {},
        tames = {},
        beasts = {},
    },
}

local TAME_WAIT = 2 -- seconds after a tame before the pet's spellbook is read

local KEEP = 200 -- entries per list
local LEVEL_WINDOW = 2 -- seconds after a level-up in which a new spell counts as from it

---The saved findings.
---@return AddonProbeData
local function Data()
    return M.db.global --[[@as AddonProbeData]]
end

---Adds to a list, keeping its last KEEP.
---@param list table[]
---@param entry table
local function Push(list, entry)
    list[#list + 1] = entry
    while #list > KEEP do
        table.remove(list, 1)
    end
end

---A shallow copy, lists one level deeper (petAbilities and the like).
---@param info table<string, GameValue>
---@return table<string, GameValue>
local function Copy(info)
    ---@type table<string, GameValue>
    local copy = {}
    for key, value in pairs(info) do
        if type(value) == "table" then
            local items = value --[[@as GameValue[] ]]
            ---@type GameValue[]
            local list = {}
            for i, item in ipairs(items) do
                list[i] = item
            end
            value = list
        end
        copy[key] = value
    end
    return copy
end

---Every value given, with how many (nil ones too).
---@param ... any
---@return {n: number, [integer]: any}
local function Pack(...)
    return { n = select("#", ...), ... }
end

---What `fn` returns, as a list: a hidden (secret) value as "secret"; "missing" without `fn`,
---"error: ..." when it errors.
---@param fn function?
---@param ... any
---@return table|string
local function Returns(fn, ...)
    if type(fn) ~= "function" then return "missing" end
    local results = Pack(pcall(fn, ...))
    if not results[1] then return "error: " .. tostring(results[2]) end
    ---@type any[]
    local out = {}
    for i = 2, results.n do
        ---@type GameValue
        local value = results[i]
        if type(value) == "table" and value.GetXY then
            -- A vector (a map position): its numbers.
            local x, y = (value --[[@as Vector2DMixin]]):GetXY()
            value = { x = x, y = y }
        end
        if value ~= nil then out[i - 1] = Addon.Readable(value) and value or "secret" end
    end
    return out
end

---Keeps what the client is, once per login.
local function NoteClient()
    local creature = C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo
    local family = creature and creature(1)
    local container = C_Container and C_Container.GetContainerNumFreeSlots
    ---@type table<number, table|string>
    local bags = {}
    for bag = 1, 4 do
        bags[bag] = Returns(container, bag)
    end
    local seasons = C_Seasons and C_Seasons.GetActiveSeason
    Data().client = {
        build = Returns(GetBuildInfo),
        project = WOW_PROJECT_ID,
        season = Returns(seasons),
        tameable = (LibStub("LibTameable-1.0") --[[@as LibTameable]]):GetClient(),
        api = {
            GetPlayerFacing = type(GetPlayerFacing) == "function",
            CreateMaskTexture = type(UIParent.CreateMaskTexture) == "function",
            OnMapChanged = WorldMapFrame ~= nil and type(WorldMapFrame.OnMapChanged) == "function",
            MinimapGetZoom = type(Minimap.GetZoom) == "function",
            familyIcon = family and family.iconFile or false,
        },
        unitPosition = Returns(UnitPosition, "player"),
        mapPosition = Returns(C_Map.GetPlayerMapPosition, C_Map.GetBestMapForUnit("player"), "player"),
        ammo = Returns(GetInventoryItemCount, "player", 0),
        rangedSpeed = Returns(UnitRangedDamage, "player"),
        bags = bags,
    }
end

---Keeps the raw returns of the pet's happiness, loyalty and training points, both ways.
local function NotePet()
    local info = C_PetInfo
    Data().pet = {
        happiness = { modern = Returns(info and info.GetPetHappiness), old = Returns(GetPetHappiness) },
        loyalty = { modern = Returns(info and info.GetPetLoyalty), old = Returns(GetPetLoyalty) },
        trainingPoints = { modern = Returns(info and info.GetPetTrainingPoints), old = Returns(GetPetTrainingPoints) },
    }
end

---Keeps the first fight's: whether the pet's health and the player's place still read.
function M:PLAYER_REGEN_DISABLED()
    if Data().combat then return end
    Data().combat = {
        petOut = UnitExists("pet") == true,
        petHealth = Returns(UnitHealth, "pet"),
        unitPosition = Returns(UnitPosition, "player"),
        mapPosition = Returns(C_Map.GetPlayerMapPosition, C_Map.GetBestMapForUnit("player"), "player"),
    }
end

---The ranks LibTameable says beast `npc` teaches, or the pet knows, as "Bite 4".
---@param name string?
---@param rank string|number?
---@return string?
local function RankLine(name, rank)
    if not name then return nil end
    local number = tostring(rank or ""):match("%d+")
    return number and ("%s %s"):format(name, number) or name
end

---BEASTKEEPER_PET_TAMED: a little later, what the pet knows beside what the data says it teaches.
---@param _ string the message
---@param event AddonPetTamedEvent
function M:OnTamed(_, event)
    local npc = event.npc
    if not npc then return end
    C_Timer.After(TAME_WAIT, function()
        ---@type string[], string[]
        local knows, expected = {}, {}
        for name, spell in pairs(Addon.PetSpells()) do
            knows[#knows + 1] = RankLine(name, spell.rank) --[[@as string]]
        end
        local lib = LibStub("LibTameable-1.0") --[[@as LibTameable]]
        ---@type number[]
        local teaches = lib:GetTeaches(npc) or {}
        for _, spellID in ipairs(teaches) do
            local _, rank = lib:GetRank(spellID)
            expected[#expected + 1] = RankLine(Addon.SpellInfo(spellID) or tostring(spellID), rank) --[[@as string]]
        end
        table.sort(knows)
        table.sort(expected)
        local has = {}
        for _, line in ipairs(knows) do
            has[line] = true
        end
        local match = true
        for _, line in ipairs(expected) do
            match = match and has[line] == true
        end
        local _, family = UnitCreatureFamily("pet")
        Push(Data().tames, {
            npc = npc,
            family = family,
            knows = knows,
            expected = expected,
            match = match,
            t = GetServerTime(),
        })
        Addon:Log("info", "probe: tamed {1}, its spells match the data: {2}", npc, tostring(match))
    end)
end

---A beast in LibTameable's data under the mouse or targeted: its first sighting, where the player
---stands and whether the data has the beast on that map.
---@param guid GameValue
local function NoteBeast(guid)
    if not M:IsEnabled() or type(guid) ~= "string" or not Addon.Readable(guid) then return end
    local npc = tonumber((select(6, strsplit("-", guid))))
    local beast = npc and Addon.data.beasts[npc]
    if not npc or not beast or Data().beasts[npc] then return end
    local map = C_Map.GetBestMapForUnit("player")
    local position = map and C_Map.GetPlayerMapPosition(map, "player")
    local x, y
    if position then
        x, y = position:GetXY()
    end
    ---@type number[]
    local dataMaps = {}
    for dataMap in pairs(beast.pins or {}) do
        dataMaps[#dataMaps + 1] = dataMap
    end
    table.sort(dataMaps)
    Data().beasts[npc] = {
        name = beast.name,
        map = map,
        x = Addon.Readable(x) and x and math.floor(x * 1000 + 0.5) / 10 or nil,
        y = Addon.Readable(y) and y and math.floor(y * 1000 + 0.5) / 10 or nil,
        onDataMap = map ~= nil and beast.pins ~= nil and beast.pins[map] ~= nil,
        dataMaps = dataMaps,
        t = GetServerTime(),
    }
end

Addon.OnUnitTooltip(function(_, guid)
    NoteBeast(guid)
end)

---Keeps each pet of the stable's lists under its number.
function M:ReadStable()
    local getActive = C_StableInfo and C_StableInfo.GetActivePetList
    local getStabled = C_StableInfo and C_StableInfo.GetStabledPetList
    if not (getActive and getStabled) then return end
    for _, list in ipairs({ getActive(), getStabled() }) do
        for _, info in ipairs(list) do
            if type(info.petNumber) == "number" then Data().stable[tostring(info.petNumber)] = Copy(info) end
        end
    end
end

-- The pet's spells as last seen, name -> rank text, and when its level last rose.
---@type table<string, string>
local known = {}
local leveledAt = -math.huge

---Notes the pet's spells now without telling: the starting point for the next comparison.
local function Baseline()
    wipe(known)
    for name, spell in pairs(Addon.PetSpells()) do
        known[name] = spell.rank or ""
    end
end

---Compares the pet's spells with the last look and keeps each new spell or rank.
function M:CompareSpells()
    if not UnitExists("pet") then return end
    for name, spell in pairs(Addon.PetSpells()) do
        local rank = spell.rank or ""
        if known[name] ~= rank then
            local how = "other"
            if GetTime() - leveledAt <= LEVEL_WINDOW then
                how = "level"
            elseif ClassTrainerFrame and ClassTrainerFrame:IsShown() then
                how = "training"
            end
            local _, family = UnitCreatureFamily("pet")
            Push(Data().petSpells, {
                spell = name,
                rank = rank,
                before = known[name],
                level = UnitLevel("pet"),
                family = family,
                how = how,
                t = GetServerTime(),
            })
            Addon:Log("info", "probe: pet got {1} {2} ({3})", name, rank, how)
            known[name] = rank
        end
    end
end

---Keeps the pet's GUID at an event.
---@param event string
local function NoteGUID(event)
    local guid = UnitGUID("pet")
    if type(guid) ~= "string" or not Addon.Readable(guid) then return end
    Push(Data().guids, { event = event, guid = guid, name = UnitName("pet"), t = GetServerTime() })
    Addon:Log("info", "probe: {1} {2}", event, guid)
end

---Keeps what the pet out's family eats.
local function NoteFoods()
    local _, family = UnitCreatureFamily("pet")
    if family then Data().foods[family] = Copy({ list = Addon.C.PetInfo.GetPetFoodTypes() }).list end
end

---Keeps the client's name of every pet family.
local function NoteFamilies()
    local info = C_CreatureInfo
    if not (info and info.GetCreatureFamilyIDs) then return end
    for _, familyID in ipairs(info.GetCreatureFamilyIDs()) do
        local family = info.GetCreatureFamilyInfo(familyID)
        if family then Data().families[familyID] = family.name end
    end
end

function M:PLAYER_ENTERING_WORLD()
    NoteFamilies()
    NoteFoods()
    NoteClient()
    self:ReadStable()
end

---@param _ string the event
---@param unit string
function M:UNIT_PET(_, unit)
    if unit ~= "player" then return end
    NoteGUID("UNIT_PET")
    NoteFoods()
    NotePet()
    self:ReadStable()
    Baseline()
end

---@param _ string the event
---@param unit string
function M:UNIT_LEVEL(_, unit)
    if unit ~= "pet" then return end
    leveledAt = GetTime()
    self:CompareSpells()
end

function M:PET_BAR_UPDATE()
    self:CompareSpells()
end

local TRAINER_ROWS = 5 -- the trainer's rows kept

---A new spell from the trainer, and the trainer's first rows as the client gives them.
function M:TRAINER_UPDATE()
    self:CompareSpells()
    local count = GetNumTrainerServices and GetNumTrainerServices() or 0
    ---@type (table|string)[]
    local rows = {}
    for index = 1, math.min(count, TRAINER_ROWS) do
        rows[index] = Returns(GetTrainerServiceInfo, index)
    end
    if #rows > 0 then Data().trainer = rows end
end
M.TRAINER_SHOW = M.TRAINER_UPDATE

function M:PET_STABLE_UPDATE()
    self:ReadStable()
end

function M:LOCALPLAYER_PET_RENAMED()
    NoteGUID("LOCALPLAYER_PET_RENAMED")
end

---BEASTKEEPER_ABILITY_LEARNED: a rank below the highest the hunter knew of that ability (Ability
---Learned has not marked the learn yet when it sends this).
---@param _ string the message
---@param event AddonAbilityLearnedEvent
function M:OnLearned(_, event)
    local learned = Addon:GetModule("AbilityLearned", true) --[[@as AddonAbilityLearned?]]
    local highest = learned and learned:HighestRank(event.name)
    if highest and event.rank < highest then
        Push(Data().lowerRanks, { name = event.name, rank = event.rank, highest = highest, t = GetServerTime() })
        Addon:Log("info", "probe: learned {1} rank {2} below rank {3}", event.name, event.rank, highest)
    end
end

local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "UNIT_PET",
    "UNIT_LEVEL",
    "PET_BAR_UPDATE",
    "TRAINER_UPDATE",
    "TRAINER_SHOW",
    "PET_STABLE_UPDATE",
    "LOCALPLAYER_PET_RENAMED",
    "PLAYER_REGEN_DISABLED",
}

function M:OnEnable()
    Addon.RegisterEvents(self, EVENTS)
    Addon:Listen(self, Addon.messages.abilityLearned, "OnLearned")
    Addon:Listen(self, Addon.messages.petTamed, "OnTamed")
    Baseline()
    self:PLAYER_ENTERING_WORLD()
end

function M:OnDisable()
    Addon:StopListening(self)
end

---@return table
function M:GetOptions()
    return {
        args = {
            forget = {
                type = "execute",
                name = "Forget the findings",
                desc = "Empty every list the probe keeps.",
                order = 1,
                func = function()
                    for _, list in pairs(Data()) do
                        wipe(list)
                    end
                end,
            },
        },
    }
end
--@end-debug@
