--@debug@
local _, ns = ...

-- A probe for development: keeps in KennelDB (DevProbe's global namespace) what Kennel cannot learn
-- from the API documentation, to read back from the SavedVariables after playing:
--   stable      C_StableInfo's entry of each pet, as the lists give it
--   petSpells   each spell a pet gets: its name and rank, the rank before, the pet's level and
--               family, and how it came ("level" right after a level-up, "training" with the
--               trainer window open, else "other"): how Forever's family abilities arrive
--   foods       C_PetInfo.GetPetFoodTypes per family; families: the client's family names
--   lowerRanks  a rank the hunter learned below the highest it knew of that ability
--   guids       the pet's GUID at UNIT_PET and LOCALPLAYER_PET_RENAMED (around a tame)
-- Each finding also goes to Kennel:Log (OAP Debug). Like Dev Screenshots the whole file is a
-- --@debug@ block, so only a copy straight from the repository has it. Off until switched on.

---@type Kennel
local Kennel = ns

---@type KennelDevProbe
local M = Kennel:NewModule("DevProbe")
M.title = "Dev Probe"
M.description = "Keeps what the client says of pets, stable and families. Repository copies only."
M.enabledByDefault = false
M.defaults = { global = { stable = {}, petSpells = {}, foods = {}, families = {}, lowerRanks = {}, guids = {} } }

local KEEP = 200 -- entries per list
local LEVEL_WINDOW = 2 -- seconds after a level-up in which a new spell counts as from it

---The saved findings.
---@return KennelProbeData
local function Data()
    return M.db.global --[[@as KennelProbeData]]
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
    for name, spell in pairs(Kennel.PetSpells()) do
        known[name] = spell.rank or ""
    end
end

---Compares the pet's spells with the last look and keeps each new spell or rank.
function M:CompareSpells()
    if not UnitExists("pet") then return end
    for name, spell in pairs(Kennel.PetSpells()) do
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
            Kennel:Log("info", "probe: pet got {1} {2} ({3})", name, rank, how)
            known[name] = rank
        end
    end
end

---Keeps the pet's GUID at an event.
---@param event string
local function NoteGUID(event)
    local guid = UnitGUID("pet")
    if type(guid) ~= "string" or not Kennel.Readable(guid) then return end
    Push(Data().guids, { event = event, guid = guid, name = UnitName("pet"), t = GetServerTime() })
    Kennel:Log("info", "probe: {1} {2}", event, guid)
end

---Keeps what the pet out's family eats.
local function NoteFoods()
    local _, family = UnitCreatureFamily("pet")
    if family then Data().foods[family] = Copy({ list = Kennel.C.PetInfo.GetPetFoodTypes() }).list end
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
    self:ReadStable()
end

---@param _ string the event
---@param unit string
function M:UNIT_PET(_, unit)
    if unit ~= "player" then return end
    NoteGUID("UNIT_PET")
    NoteFoods()
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
M.TRAINER_UPDATE = M.PET_BAR_UPDATE

function M:PET_STABLE_UPDATE()
    self:ReadStable()
end

function M:LOCALPLAYER_PET_RENAMED()
    NoteGUID("LOCALPLAYER_PET_RENAMED")
end

---KENNEL_ABILITY_LEARNED: a rank below the highest the hunter knew of that ability (Ability
---Learned has not marked the learn yet when it sends this).
---@param _ string the message
---@param event KennelAbilityLearnedEvent
function M:OnLearned(_, event)
    local learned = Kennel:GetModule("AbilityLearned", true) --[[@as KennelAbilityLearned?]]
    local highest = learned and learned:HighestRank(event.name)
    if highest and event.rank < highest then
        Push(Data().lowerRanks, { name = event.name, rank = event.rank, highest = highest, t = GetServerTime() })
        Kennel:Log("info", "probe: learned {1} rank {2} below rank {3}", event.name, event.rank, highest)
    end
end

local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "UNIT_PET",
    "UNIT_LEVEL",
    "PET_BAR_UPDATE",
    "TRAINER_UPDATE",
    "PET_STABLE_UPDATE",
    "LOCALPLAYER_PET_RENAMED",
}

function M:OnEnable()
    Kennel.RegisterEvents(self, EVENTS)
    Kennel:Listen(self, "KENNEL_ABILITY_LEARNED", "OnLearned")
    Baseline()
    self:PLAYER_ENTERING_WORLD()
end

function M:OnDisable()
    Kennel:StopListening(self)
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
