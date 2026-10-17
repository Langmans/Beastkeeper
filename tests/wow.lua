-- A simulated WoW client: the API Kennel and the Ace3 libraries touch, with every value a test
-- may want to vary exposed on the client object. NewClient() resets the globals and loads the
-- .toc's files (Ace3 included) into a fresh namespace, so tests never share state. The load order
-- and the .toc's metadata come from tests/helper.lua (TOC_FILES, TOC_METADATA, TOC_SAVED).

-- What a hidden value looks like to the addon: only issecretvalue tells it apart.
SECRET = setmetatable({}, {
    __tostring = function()
        return "<secret>"
    end,
})

---A file's source as the client gets it: from a release, where the packager comments out every line
---between `--@debug@` and `--@end-debug@`, unless `dev` (a copy straight from the repository).
---The line count stays, so coverage still points at the right lines.
---@type table<string, string>
local packaged = {}
---@param file string
---@param dev boolean
---@return string
function AsPackaged(file, dev)
    local key = (dev and "dev:" or "release:") .. file
    if packaged[key] then return packaged[key] end
    local handle = assert(io.open(file, "rb"))
    local source = handle:read("*a")
    handle:close()
    if dev or not source:find("--@debug@", 1, true) then
        packaged[key] = source
        return source
    end
    local lines, inDebug = {}, false
    for line in (source .. "\n"):gmatch("(.-)\r?\n") do
        if line:match("^%s*%-%-@end%-debug@") then
            inDebug = false
        elseif inDebug then
            line = "--" .. line
        elseif line:match("^%s*%-%-@debug@") then
            inDebug = true
        end
        lines[#lines + 1] = line
    end
    packaged[key] = table.concat(lines, "\n")
    return packaged[key]
end

---Compiled once per run: a file's chunk runs again for every client, each time from the top.
---@type table<string, function>
local chunks = {}
---@param file string
---@param dev boolean
---@return function
function Chunk(file, dev)
    local key = (dev and "dev:" or "release:") .. file
    chunks[key] = chunks[key] or assert(loadstring(AsPackaged(file, dev), "@" .. file))
    return chunks[key]
end

---Packs varargs with their count, nils included (Lua 5.1 has no table.pack).
local function pack(...)
    return { n = select("#", ...), ... }
end

-- WoW's Lua 5.1 passes xpcall's extra arguments on to the function, as Lua 5.2 does; plain 5.1
-- drops them. Ace3 relies on it (AceAddon calls OnInitialize as xpcall(func, handler, addon)).
local plainXpcall = xpcall
function xpcall(func, handler, ...)
    local args = pack(...)
    return plainXpcall(function()
        return func(unpack(args, 1, args.n))
    end, handler)
end

---@class TestClientOptions
---@field locale string? the client's language, enUS by default
---@field saved table? KennelDB as the saved file left it
---@field modules fun(Kennel: Kennel)? creates test modules after the files load, before login
---@field noSettingsPanel boolean? Settings without C_SettingsUtil.OpenSettingsPanel, like Forever
---@field class string? the player's class file, HUNTER by default
---@field oldSpellAPI boolean? GetSpellInfo instead of C_Spell
---@field noSpellAPI boolean? neither C_Spell nor GetSpellInfo
---@field noTextureAPI boolean? C_Spell without GetSpellTexture
---@field noPetBarAPI boolean? no GetPetActionInfo
---@field noSpellBookAPI boolean? no C_SpellBook
---@field noPetSpellCount boolean? C_SpellBook without HasPetSpells
---@field noMacroConsts boolean? no Constants.MacroConsts (the addon's own limits apply)
---@field ellesmere boolean|table? EllesmereUI loaded before Kennel (a table: fields to leave out, set to false)
---@field messageQueue boolean? MessageQueue loaded before Kennel
---@field handyNotes boolean? HandyNotes loaded before Kennel
---@field noPet boolean? no pet unit at the start
---@field inCombat boolean? in combat from the start
---@field oldTrainingAPI boolean? GetPetTrainingPoints instead of C_PetInfo's
---@field noTrainingAPI boolean? neither
---@field noLearnLines boolean? no ERR_LEARN_ABILITY_S / ERR_LEARN_SPELL_S
---@field noLoyaltyAPI boolean? neither C_PetInfo.GetPetLoyalty nor the global
---@field oldLoyaltyAPI boolean? the global GetPetLoyalty instead of C_PetInfo's
---@field oldChatAPI boolean? the global SendChatMessage instead of C_ChatInfo's
---@field noStableInfo boolean? no C_StableInfo
---@field dev boolean? a copy straight from the repository: `--@debug@` blocks run (the DevScreenshots module)

-- The spells the simulated client knows, per locale: id -> { name, icon, rank }; the rank is the
-- client's subtext, "" for a spell without ranks.
local SPELLS = {
    enUS = {
        [2649] = { "Growl", 132270, "" },
        [14916] = { "Growl", 132270, "" }, -- a higher rank: same name
        [1742] = { "Cower", 132118, "Rank 1" },
        [17253] = { "Bite", 132278, "Rank 1" },
        [16827] = { "Claw", 132140, "Rank 1" },
        [16828] = { "Claw", 132140, "Rank 2" },
        [16829] = { "Claw", 132140, "Rank 3" },
        [7371] = { "Charge", 132183, "Rank 1" },
        [1310617] = { "Trickster's Dance", 132242, "Rank 1" }, -- Fox, new in WoW: Forever
        [4187] = { "Great Stamina", 136112, "Rank 1" },
        [20736] = { "Distracting Shot", 135736, "" },
        [136] = { "Mend Pet", 132179, "" },
        [982] = { "Revive Pet", 132163, "" },
        [883] = { "Call Pet", 132161, "" },
    },
    deDE = {
        [136] = { "Tier heilen", 132179, "" },
        [982] = { "Tier wiederbeleben", 132163, "" },
        [883] = { "Tier rufen", 132161, "" },
        [2649] = { "Knurren", 132270, "" },
        [14916] = { "Knurren", 132270, "" },
        [1742] = { "Ducken", 132118, "Rang 1" },
        [17253] = { "Biss", 132278, "Rang 1" },
        [16827] = { "Klaue", 132140, "Rang 1" },
        [16828] = { "Klaue", 132140, "Rang 2" },
        [20736] = { "Ablenkender Schuss", 135736, "" },
    },
}

-- The client's "learned" chat lines, per locale.
local LEARN_LINES = {
    enUS = { "You have learned a new ability: %s.", "You have learned a new spell: %s." },
    deDE = { "Ihr habt eine neue Fähigkeit erlernt: %s.", "Ihr habt einen neuen Zauber erlernt: %s." },
}

GROWL, COWER, CLAW, CLAW_2, CLAW_3 = 2649, 1742, 16827, 16828, 16829
FEED_PET = 6991

-- Item names the simulated client knows; anything else is uncached (nil).
local ITEM_NAMES = {
    [12037] = "Mystery Meat",
    [4538] = "Snapvine Watermelon",
    [4608] = "Raw Black Truffle",
    [4536] = "Shiny Red Apple",
    [117] = "Tough Jerky",
    [4540] = "Tough Hunk of Bread",
}

---The chat link the client builds for an item, as C_Item.GetItemInfo's second return.
function ItemLink(itemID)
    return ("|cffffffff|Hitem:%d::::::::60:::::|h[%s]|h|r"):format(itemID, ITEM_NAMES[itemID])
end

---@param opts TestClientOptions?
function NewClient(opts)
    opts = opts or {}
    local function noop() end
    local client = {
        time = 100,
        frames = {},
        printed = {},
        errors = {},
        loggedIn = false,
        -- In combat (opts.inCombat: from the start, as after a /reload mid-fight).
        inCombat = opts.inCombat == true,
    }

    local locale = opts.locale or "enUS"
    function GetLocale()
        return locale
    end
    function GetTime()
        return client.time
    end
    function IsLoggedIn()
        return client.loggedIn
    end
    function GetBuildInfo()
        return "1.16.0", "60000", "Oct 1 2026", 11600
    end
    -- An error the addon or a library reports without raising is a test failure waiting to
    -- happen: it is kept for the test to check (client.errors).
    function geterrorhandler()
        return function(err)
            client.errors[#client.errors + 1] = tostring(err)
        end
    end
    function securecallfunction(func, ...)
        return func(...)
    end
    function hooksecurefunc(target, name, hook)
        if type(target) ~= "table" then
            target, name, hook = _G, target, name
        end
        local original = target[name]
        target[name] = function(...)
            local results = pack(original(...))
            hook(...)
            return unpack(results, 1, results.n)
        end
    end
    function InCombatLockdown()
        return client.inCombat == true
    end

    -- Global strings and constants the Ace3 GUI reads.
    FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE = "|r", "|cffffd200"
    NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
    ACCEPT, CANCEL, CLOSE, OKAY, NOT_BOUND = "Accept", "Cancel", "Close", "Okay", "Not Bound"
    WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC = 1, 2
    WOW_PROJECT_ID = WOW_PROJECT_CLASSIC
    SOUNDKIT = setmetatable({}, {
        __index = function()
            return 1
        end,
    })
    -- client.sounds: { file = FileDataID } for a sound file, { kit = SoundKit ID } for a kit.
    client.sounds = {}
    function PlaySoundFile(file, channel)
        client.sounds[#client.sounds + 1] = { file = file, channel = channel }
    end
    function PlaySound(kit, channel)
        client.sounds[#client.sounds + 1] = { kit = kit, channel = channel }
    end

    -- The pet: client.pet is the pet unit, { health, max, dead }; nil means no pet unit (none out,
    -- or a dead one whose body is gone). opts.noPet starts without one.
    client.pet = not opts.noPet and { health = 100, max = 100, dead = false } or nil
    -- Its bar and book: client.petBar is the pet bar, one entry per slot, { spellID, autocast } for
    -- a spell (autocast nil when it cannot autocast) or { token = "PET_ACTION_ATTACK" }; a stance
    -- token has active = true while it is the pet's stance ({ token = "PET_MODE_PASSIVE", active }).
    -- client.petBook is the pet's spellbook, alphabetical like the client's, entries as above,
    -- { token = "Attack" } for a command and { broken = true } for an entry whose lookup errors.
    -- As on Forever: Cower is in the book but not on the bar. The pet starts as solo wants it,
    -- Growl on and Cower off.
    client.petBar = {
        { token = "PET_ACTION_ATTACK" },
        { token = "PET_ACTION_FOLLOW" },
        { 2649, true },
        { 16828, true },
        { 17253, true },
    }
    client.petBook =
        { { token = "Attack" }, { 17253, true }, { 16828, true }, { 1742, false }, { 4187 }, { 2649, true } }
    -- client.familyID: the pet's CreatureFamily ID (2 = cat). client.inGroup, client.instance:
    -- the group and the instance type ("party", "raid", "pvp", "arena", or "none" outside).
    client.familyID, client.inGroup, client.instance = 2, false, "none"
    function UnitExists(unit)
        if unit == "npc" then return client.trainer ~= nil and client.trainer.npc == true end
        return unit == "player" or (unit == "pet" and client.pet ~= nil)
    end
    -- client.petGUID: the pet's GUID, its spawn UID's low 32 bits being the stable's petNumber
    -- (3069428 here, in client.stable).
    client.petGUID = "Pet-0-5250-0-1-165189-01002ED5F4"
    function UnitGUID(unit)
        if unit == "pet" and client.pet then return client.petGUID end
    end
    function UnitCreatureFamily(unit)
        if unit == "pet" and client.pet then return "Cat", client.familyID end
    end
    function UnitIsDead(unit)
        return unit == "pet" and client.pet ~= nil and client.pet.dead
    end
    -- client.healthSecret: the pet's health is hidden, as Forever may hide it in combat.
    function UnitHealth(unit)
        if unit ~= "pet" or not client.pet then return 0 end
        if client.healthSecret then return SECRET end
        return client.pet.health
    end
    function UnitHealthMax(unit)
        if unit ~= "pet" or not client.pet then return 0 end
        return client.pet.max
    end
    -- client.mounted: on a mount, where Call Pet fails for that reason.
    function IsMounted()
        return client.mounted == true
    end
    -- IsInGroup(2) asks about an instance group (client.instanceGroup), as the client does.
    function IsInGroup(category)
        if category == 2 then return client.instanceGroup == true end
        return client.inGroup
    end
    function IsInInstance()
        return client.instance ~= "none", client.instance
    end
    -- client.secret: a value the client hides from addons (in combat, on Forever).
    -- client.secret: one more value the client hides, besides SECRET (as the autocast state may be).
    function issecretvalue(value)
        return value == SECRET or (value ~= nil and value == client.secret)
    end
    function canaccessvalue(value)
        return not issecretvalue(value)
    end

    -- Spells: C_Spell, GetSpellInfo with opts.oldSpellAPI, neither with opts.noSpellAPI. Names
    -- for enUS and deDE; any other locale reads the English ones.
    local spells = SPELLS[locale] or SPELLS.enUS
    local function spellName(id)
        return spells[id] and spells[id][1]
    end
    local function spellIcon(id)
        return spells[id] and spells[id][2]
    end
    local function spellRank(id)
        return spells[id] and spells[id][3]
    end
    C_Spell, GetSpellInfo, GetSpellSubtext = nil, nil, nil
    if opts.oldSpellAPI then
        function GetSpellInfo(id)
            return spellName(id), nil, spellIcon(id)
        end
        GetSpellSubtext = spellRank
    elseif not opts.noSpellAPI then
        C_Spell = {
            GetSpellName = spellName,
            GetSpellTexture = not opts.noTextureAPI and spellIcon or nil,
            GetSpellSubtext = spellRank,
        }
    end
    local learnLines = not opts.noLearnLines and (LEARN_LINES[locale] or LEARN_LINES.enUS) or {}
    ERR_LEARN_ABILITY_S, ERR_LEARN_SPELL_S = learnLines[1], learnLines[2]

    -- GetPetActionInfo as Forever returns it: name, texture, isToken (1, not true), isActive,
    -- autoCastAllowed, autoCastEnabled, spellID.
    NUM_PET_ACTION_SLOTS = 10
    -- Creature names through C_TooltipInfo.GetHyperlink("unit:Creature-0-0-0-0-<id>-0000000000"):
    -- client.creatureNames holds the ones the client has cached, by NPC ID; any other comes back
    -- as a tooltip without lines, as the client gives it while it asks the server.
    client.creatureNames = {}
    C_TooltipInfo = {
        GetHyperlink = function(link)
            local id = tonumber(link:match("^unit:Creature%-0%-0%-0%-0%-(%d+)%-"))
            local name = id and client.creatureNames[id]
            return { lines = name and { { leftText = name } } or {} }
        end,
    }

    -- The stance icons Blizzard's pet bar defines (Blizzard_ActionBar\Shared\PetActionBar.lua).
    PET_PASSIVE_TEXTURE = "Interface\\Icons\\Ability_Seal"
    GetPetActionInfo = nil
    if not opts.noPetBarAPI then
        function GetPetActionInfo(slot)
            local entry = client.pet and client.petBar[slot]
            if not entry then return nil end
            if entry.token then return entry.token, entry.token .. "_TEXTURE", 1, entry.active, false, false end
            return spellName(entry[1]), spellIcon(entry[1]), nil, nil, entry[2] ~= nil, entry[2] == true, entry[1]
        end
    end

    -- The pet's spellbook through C_SpellBook, as Forever has it. A command has no autocast values.
    local function bookEntry(index)
        local entry = client.petBook[index]
        assert(not entry.broken, "this entry's lookup errors")
        if entry.token then return entry.token, nil, nil end
        return spellName(entry[1]), entry[2] ~= nil, entry[2] == true
    end
    Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 } }
    C_SpellBook = nil
    if not opts.noSpellBookAPI then
        C_SpellBook = {
            HasPetSpells = not opts.noPetSpellCount and function()
                if client.pet then return #client.petBook, "PET" end
            end or nil,
            -- A spell has its rank as subName ("" without one) and its ID; a command only a name.
            GetSpellBookItemInfo = function(index, bank)
                assert(bank == Enum.SpellBookSpellBank.Pet, "pet spellbook bank expected")
                local entry = client.petBook[index]
                if entry.noInfo then return nil end
                local id = not entry.token and entry[1] or nil
                return { name = (bookEntry(index)), subName = id and spellRank(id), spellID = id }
            end,
            GetSpellBookItemAutoCast = function(index, bank)
                assert(bank == Enum.SpellBookSpellBank.Pet, "pet spellbook bank expected")
                local _, allowed, on = bookEntry(index)
                return allowed, on
            end,
        }
    end

    -- Macros: client.macros (account-wide) and client.charMacros (this character's). The index
    -- of a character macro counts on from the account maximum, as the client's does.
    client.macros, client.charMacros = {}, {}
    local MAX_ACCOUNT, MAX_CHARACTER = 120, opts.noMacroConsts and 18 or 30
    Constants = not opts.noMacroConsts
            and { MacroConsts = { MAX_ACCOUNT_MACROS = MAX_ACCOUNT, MAX_CHARACTER_MACROS = MAX_CHARACTER } }
        or nil
    function GetMacroIndexByName(name)
        for i, macro in ipairs(client.macros) do
            if macro.name == name then return i end
        end
        for i, macro in ipairs(client.charMacros) do
            if macro.name == name then return MAX_ACCOUNT + i end
        end
        return 0
    end
    function GetNumMacros()
        return #client.macros, #client.charMacros
    end
    function CreateMacro(name, icon, body, perCharacter)
        assert(not client.inCombat, "macros are not made in combat")
        local list = perCharacter and client.charMacros or client.macros
        assert(#list < (perCharacter and MAX_CHARACTER or MAX_ACCOUNT), "no free macro slot")
        list[#list + 1] = { name = name, icon = icon, body = body }
    end
    ---The macro at a client index, or nil.
    local function macroAt(index)
        if index > MAX_ACCOUNT then return client.charMacros[index - MAX_ACCOUNT] end
        return client.macros[index]
    end
    function GetMacroInfo(index)
        local macro = macroAt(index)
        if macro then return macro.name, macro.icon, macro.body end
    end
    -- client.macroEdits counts the edits, so tests can see an edit that changed nothing was skipped.
    -- In combat an edit is blocked, as the client blocks it.
    client.macroEdits = 0
    function EditMacro(index, name, icon, body)
        if client.inCombat then
            client.blocked[#client.blocked + 1] = "EditMacro"
            return
        end
        local macro = assert(macroAt(index), "no macro at " .. index)
        macro.name, macro.icon, macro.body = name or macro.name, icon or macro.icon, body or macro.body
        client.macroEdits = client.macroEdits + 1
        client:fire("UPDATE_MACROS")
    end
    ---The body of the macro of that name, or nil.
    function client:macroBody(name)
        local macro = self:macro(name)
        return macro and macro.body
    end

    -- Key bindings: client.bindings maps an action to a key.
    client.bindings = {}
    function GetBindingKey(action)
        return client.bindings[action]
    end
    function GetBindingText(key)
        return "<" .. key .. ">"
    end
    -- The client's "Your pet is dead" error, under the name the addon checks first.
    ERR_PET_SPELL_DEAD, PETTAME_DEAD = "Your pet is dead.", nil

    -- Macro conditions, as far as Kennel uses them: [@pet], dead, exists, nopet, mod:shift,
    -- mod:ctrl. Brackets are alternatives, commas inside one all have to hold. client.mods: the
    -- modifier keys held ({ shift = true }).
    client.mods = {}
    local function conditionHolds(group)
        local target, holds = "player", true
        for condition in group:gmatch("[^,]+") do
            condition = condition:match("^%s*(.-)%s*$")
            if condition == "@pet" then
                target = "pet"
            elseif condition == "dead" then
                holds = holds and UnitIsDead(target)
            elseif condition == "exists" then
                holds = holds and UnitExists(target)
            elseif condition == "nopet" then
                holds = holds and not UnitExists("pet")
            elseif condition == "mod:shift" or condition == "mod:ctrl" then
                holds = holds and client.mods[condition:sub(5)] == true
            else
                error("unknown macro condition " .. condition)
            end
        end
        return holds
    end
    ---What SecureCmdOptionParse answers for `options`: the value of the first clause whose
    ---conditions hold, or nil.
    function client:evaluate(options)
        for clause in options:gmatch("[^;]+") do
            local conditions, value = clause:match("^%s*(%[.*%])%s*(.-)%s*$")
            if not conditions then return clause:match("^%s*(.-)%s*$") end
            for group in conditions:gmatch("%[(.-)%]") do
                if conditionHolds(group) then return value end
            end
        end
        return nil
    end

    -- client.timers: pending C_Timer callbacks; client:advance runs the ones that come due.
    client.timers = {}
    -- The client's own functions (client.cFunctions), which C_Timer.After refuses as a callback on
    -- Forever ("Usage: C_Timer.After(seconds, callback)"): it takes only a Lua function.
    client.cFunctions = {}
    C_Timer = {
        After = function(seconds, callback)
            assert(
                type(callback) == "function" and not client.cFunctions[callback],
                "Usage: C_Timer.After(seconds, callback)"
            )
            client.timers[#client.timers + 1] = { at = client.time + seconds, callback = callback }
        end,
    }

    -- The player, as AceDB reads it for its char/realm/class/faction keys; the pet is client.pet.name.
    function UnitNameUnmodified(unit)
        if unit == "player" then return "Langmans" end
        if unit == "pet" and client.pet then return client.pet.name or "Fluffy" end
    end
    UnitName = UnitNameUnmodified

    -- What AbilityLearned asks about a learn: the pet's free training points (client.trainingPoints,
    -- total and used), the zone, the time, the portrait drawn, the screenshots taken.
    client.trainingPoints, client.zone, client.serverTime, client.screenshots = { 50, 7 }, "Darkshore", 1791374580, 0
    local function trainingPoints()
        return client.trainingPoints[1], client.trainingPoints[2]
    end
    C_PetInfo, GetPetTrainingPoints = {}, nil
    if opts.oldTrainingAPI then
        GetPetTrainingPoints = trainingPoints
    elseif not opts.noTrainingAPI then
        C_PetInfo.GetPetTrainingPoints = trainingPoints
    end
    -- The pet's level (client.petLevel) and loyalty as the client gives it (client.loyalty: a
    -- classic "Loyalty Level 4 (Dependable)", Forever's bare name, a number, or SECRET): through
    -- C_PetInfo.GetPetLoyalty as on Forever, the global with opts.oldLoyaltyAPI, neither with
    -- opts.noLoyaltyAPI.
    client.petLevel, client.loyalty, client.playerLevel = 15, "Loyalty Level 4 (Dependable)", 60
    function UnitLevel(unit)
        if unit == "pet" then return client.petLevel end
        return client.playerLevel
    end
    local function petLoyalty()
        return client.loyalty
    end
    GetPetLoyalty = nil
    if opts.oldLoyaltyAPI then
        GetPetLoyalty = petLoyalty
    elseif not opts.noLoyaltyAPI then
        C_PetInfo.GetPetLoyalty = petLoyalty
    end
    function GetZoneText()
        return client.zone
    end
    -- Map and area names the client knows: a uiMapID's (C_Map.GetMapInfo) and an AreaTable
    -- ID's, as an instance has (C_Map.GetAreaInfo). Anything else is unknown (nil).
    local MAP_NAMES = { [1429] = "Elwynn Forest", [1420] = "Tirisfal Glades" }
    local AREA_NAMES = { [718] = "Wailing Caverns" }
    C_Map = {
        GetMapInfo = function(uiMapID)
            return MAP_NAMES[uiMapID] and { mapID = uiMapID, name = MAP_NAMES[uiMapID] } or nil
        end,
        GetAreaInfo = function(areaID)
            return AREA_NAMES[areaID]
        end,
        -- Where the player stands: the middle of Elwynn Forest.
        GetBestMapForUnit = function(unit)
            return unit == "player" and 1429 or nil
        end,
        GetPlayerMapPosition = function(map, unit)
            if unit ~= "player" or map ~= 1429 then return nil end
            return {
                GetXY = function()
                    return 0.5, 0.5
                end,
            }
        end,
    }
    function GetServerTime()
        return client.serverTime
    end
    date = os.date
    function Screenshot()
        client.screenshots = client.screenshots + 1
    end
    client.cFunctions[Screenshot] = true
    function SetPortraitTexture(texture, unit)
        texture.portrait = unit
    end

    -- The pet's sex as UnitSex gives it (client.petSex: 2 male, 3 female, 1 unknown), and the
    -- hunter's pets by number (client.stable); opts.noStableInfo: a client without C_StableInfo.
    client.petSex = 2
    function UnitSex(unit)
        if unit == "pet" and client.pet then return client.petSex end
    end
    client.stable = { active = { 3069428 }, stabled = {} }
    local function petInfos(numbers)
        local infos = {}
        for slot, petNumber in ipairs(numbers) do
            infos[slot] = { petNumber = petNumber, slotID = slot }
        end
        return infos
    end
    C_StableInfo = not opts.noStableInfo
            and {
                GetActivePetList = function()
                    return petInfos(client.stable.active)
                end,
                GetStabledPetList = function()
                    return petInfos(client.stable.stabled)
                end,
            }
        or nil

    -- Bag 0 only (client.bag: slot -> { itemID, count }); client.targeting: a spell waits for an
    -- item target; client.cursorItem: the item held on the cursor.
    client.bag, client.targeting = {}, false
    function SpellIsTargeting()
        return client.targeting
    end
    function GetCursorInfo()
        if client.cursorItem then return "item", client.cursorItem end
    end
    C_Item = {
        GetItemInfo = function(itemID)
            if ITEM_NAMES[itemID] then return ITEM_NAMES[itemID], ItemLink(itemID) end
        end,
        GetItemCount = function(itemID)
            local total = 0
            for _, item in ipairs(client.bag) do
                if item.itemID == itemID then total = total + item.count end
            end
            return total
        end,
    }
    C_Container = {
        UseContainerItem = function() end,
        GetContainerNumSlots = function(bag)
            return bag == 0 and #client.bag or 0
        end,
        GetContainerItemID = function(bag, slot)
            local item = bag == 0 and client.bag[slot]
            return item and item.itemID or nil
        end,
        GetContainerItemInfo = function(bag, slot)
            local item = bag == 0 and client.bag[slot]
            if item then return { itemID = item.itemID, stackCount = item.count } end
        end,
    }
    NUM_BAG_SLOTS = 4

    -- The trainer window: client.trainer is nil while it is closed, else { npc = boolean, rows }
    -- with rows { name, kind, spellID } ("header" rows have no spell). Beast Training is the window
    -- without an NPC; a pet trainer's has one.
    function GetNumTrainerServices()
        return client.trainer and #client.trainer.rows or 0
    end
    function GetTrainerServiceInfo(index)
        local row = client.trainer.rows[index]
        assert(not row.broken, "this row's lookup errors")
        return row[1], row[2]
    end
    function UnitClass()
        local classFile = opts.class or "HUNTER"
        return classFile, classFile
    end
    function UnitRace()
        return "Night Elf", "NightElf", 4
    end
    function UnitFactionGroup()
        return "Alliance", "Alliance"
    end
    function GetRealmName()
        return "Doomhowl"
    end
    function GetCurrentRegion()
        return 3
    end
    function GetCurrentRegionName()
        return "EU"
    end

    -- WoW's string and table shorthands.
    strmatch, strfind, strsub, strlower, strupper, strlen, strrep, strbyte, strchar, format, gsub =
        string.match,
        string.find,
        string.sub,
        string.lower,
        string.upper,
        string.len,
        string.rep,
        string.byte,
        string.char,
        string.format,
        string.gsub
    tinsert, tremove, tconcat, sort = table.insert, table.remove, table.concat, table.sort
    max, min, floor, ceil, abs = math.max, math.min, math.floor, math.ceil, math.abs
    function strtrim(text, chars)
        chars = chars or " \t\r\n"
        local class = "[" .. chars:gsub("[%]%%%-%^]", "%%%0") .. "]"
        return (text:gsub("^" .. class .. "+", ""):gsub(class .. "+$", ""))
    end
    function strsplit(sep, text, limit)
        local parts, start = {}, 1
        while true do
            if limit and #parts == limit - 1 then break end
            local at = text:find(sep, start, true)
            if not at then break end
            parts[#parts + 1] = text:sub(start, at - 1)
            start = at + #sep
        end
        parts[#parts + 1] = text:sub(start)
        return unpack(parts)
    end
    -- Characters, not bytes: every byte that does not continue a UTF-8 sequence starts one.
    function strlenutf8(text)
        return select(2, text:gsub("[^\128-\191]", ""))
    end
    function strjoin(sep, ...)
        return table.concat({ ... }, sep)
    end
    function wipe(tbl)
        for key in pairs(tbl) do
            tbl[key] = nil
        end
        return tbl
    end
    table.wipe = wipe
    function tostringall(...)
        local out = pack(...)
        for i = 1, out.n do
            out[i] = tostring(out[i])
        end
        return unpack(out, 1, out.n)
    end

    -- Frames: layout calls do nothing, a frame keeps its events, scripts and shown state. Any
    -- method the mock does not define (a capitalised key) is a no-op; a lowercase key is a field
    -- and reads nil until set, as on a real frame.
    local Region = {}
    Region.__index = function(_, key)
        if Region[key] then return Region[key] end
        if type(key) == "string" and key:match("^%u") then return noop end
    end
    function Region:Show()
        self.shown = true
    end
    function Region:Hide()
        self.shown = false
    end
    function Region:IsShown()
        return self.shown
    end
    function Region:SetShown(shown)
        self.shown = shown == true
    end
    -- Keyboard input: only allowed out of combat, as on the client.
    function Region:SetPropagateKeyboardInput(propagate)
        assert(not client.inCombat, "SetPropagateKeyboardInput is restricted in combat")
        self.propagate = propagate
    end
    function Region:RegisterEvent(event)
        self.events[event] = true
    end
    function Region:UnregisterEvent(event)
        self.events[event] = nil
    end
    function Region:UnregisterAllEvents()
        self.events = {}
    end
    function Region:IsEventRegistered(event)
        return self.events[event] == true
    end
    function Region:SetScript(script, handler)
        self.scripts[script] = handler
    end
    function Region:GetScript(script)
        return self.scripts[script]
    end
    function Region:GetName()
        return self.name
    end
    -- Sizes and positions: what was set, else a plausible number, so layout code that does
    -- arithmetic on them (AceGUI's) runs.
    function Region:SetWidth(width)
        self.width = width
    end
    function Region:SetHeight(height)
        self.height = height
    end
    function Region:SetSize(width, height)
        self.width, self.height = width, height
    end
    function Region:GetWidth()
        return self.width or 100
    end
    function Region:GetHeight()
        return self.height or 20
    end
    function Region:GetSize()
        return self:GetWidth(), self:GetHeight()
    end
    for _, getter in ipairs({
        "GetTop",
        "GetBottom",
        "GetLeft",
        "GetRight",
        "GetStringWidth",
        "GetStringHeight",
        "GetFrameLevel",
        "GetNumPoints",
    }) do
        Region[getter] = function()
            return 0
        end
    end
    function Region:GetEffectiveScale()
        return 1
    end
    function Region:GetScale()
        return self.scale or 1
    end
    function Region:GetText()
        return self.text
    end
    function Region:SetText(text)
        self.text = text
    end
    -- What tests read back from the toast: scale, alpha, texture, colours and anchor points.
    function Region:SetScale(scale)
        self.scale = scale
    end
    function Region:SetAlpha(alpha)
        self.alpha = alpha
    end
    function Region:SetTexture(texture)
        self.texture = texture
    end
    function Region:SetColorTexture(r, g, b, a)
        self.color = { r, g, b, a }
    end
    function Region:SetTextColor(r, g, b)
        self.textColor = { r, g, b }
    end
    function Region:SetFont(path, size, flags)
        self.font = { path, size, flags }
    end
    function Region:ClearAllPoints()
        self.points = {}
    end
    function Region:SetPoint(point, relativeTo, relativePoint, x, y)
        self.points = self.points or {}
        self.points[#self.points + 1] = { point, relativeTo, relativePoint, x, y }
    end
    function Region:GetPoint(index)
        local p = self.points and self.points[index or 1]
        if p then return p[1], p[2], p[3], p[4], p[5] end
    end
    -- client.mouseOver: whether the mouse is over a frame (the toast, in practice).
    function Region:IsMouseOver()
        return client.mouseOver == true
    end
    -- Dropped somewhere: the client leaves the frame anchored where it was dropped.
    function Region:StopMovingOrSizing()
        self.points = { { "TOPLEFT", nil, "BOTTOMLEFT", 300, 700 } }
    end
    local function newRegion(fields)
        fields = fields or {}
        fields.shown = true
        fields.events, fields.scripts, fields.hooks, fields.attributes, fields.refs = {}, {}, {}, {}, {}
        return setmetatable(fields, Region)
    end
    function Region:HookScript(script, handler)
        self.hooks[script] = self.hooks[script] or {}
        table.insert(self.hooks[script], handler)
    end
    -- A unit event is delivered only for its unit.
    function Region:RegisterUnitEvent(event, unit)
        self.events[event] = unit
    end

    -- The secure side, closely enough to run Kennel's own snippets: state drivers report changes
    -- through `state-*` attributes, snippets run in an environment with nothing but `self` (a frame
    -- handle) and their arguments, and in combat an insecure SetAttribute on a protected frame is
    -- blocked and recorded in client.blocked, as the real client blocks it.
    client.blocked, client.drivers = {}, {}
    -- How deep we are in restricted code; insecure code is at 0.
    local restricted = 0
    local runSnippet

    ---Sets an attribute as the client does: blocked in combat for insecure code on a protected
    ---frame; a state-* attribute on a state handler runs its _onstate-* snippet; then the
    ---OnAttributeChanged hooks run.
    local function setAttribute(frame, name, value)
        if frame.protected and client.inCombat and restricted == 0 then
            client.blocked[#client.blocked + 1] = name
            return
        end
        frame.attributes[name] = value
        local stateID = name:match("^state%-(.+)$")
        if frame.stateHandler and stateID then
            local snippet = frame.attributes["_onstate-" .. stateID]
            if snippet then runSnippet(frame, snippet, { stateid = stateID, newstate = value }) end
        end
        for _, hook in ipairs(frame.hooks.OnAttributeChanged or {}) do
            hook(frame, name, value)
        end
    end
    function Region:SetAttribute(name, value)
        setAttribute(self, name, value)
    end
    function Region:GetAttribute(name)
        return self.attributes[name]
    end

    ---A frame as restricted code sees it.
    local function handle(frame)
        return {
            GetAttribute = function(_, name)
                return frame.attributes[name]
            end,
            SetAttribute = function(_, name, value)
                assert(not name:match("^_"), "restricted code cannot set _ attributes")
                setAttribute(frame, name, value)
            end,
            RunAttribute = function(_, name)
                runSnippet(frame, frame.attributes[name], {})
            end,
            GetFrameRef = function(_, label)
                return handle(assert(frame.refs[label], "no frame ref " .. label))
            end,
        }
    end
    function runSnippet(frame, body, args)
        local env = { self = handle(frame) }
        for key, value in pairs(args) do
            env[key] = value
        end
        local chunk = assert(loadstring(body, "=snippet"))
        setfenv(chunk, env)
        restricted = restricted + 1
        chunk()
        restricted = restricted - 1
    end

    function SecureHandlerSetFrameRef(frame, label, ref)
        if client.inCombat then
            client.blocked[#client.blocked + 1] = "SetFrameRef"
            return
        end
        frame.refs[label] = ref
    end
    function SecureHandlerExecute(frame, body)
        if client.inCombat then
            client.blocked[#client.blocked + 1] = "Execute"
            return
        end
        runSnippet(frame, body, {})
    end
    function RegisterStateDriver(frame, state, values)
        assert(not client.inCombat, "a state driver is registered outside combat")
        client.drivers[#client.drivers + 1] = { frame = frame, state = state, values = values }
        client:updateDrivers()
    end
    function UnregisterStateDriver(frame, state)
        assert(not client.inCombat, "a state driver is unregistered outside combat")
        for i = #client.drivers, 1, -1 do
            if client.drivers[i].frame == frame and client.drivers[i].state == state then
                table.remove(client.drivers, i)
            end
        end
    end

    ---Re-evaluates every state driver, as the client does a few times a second.
    function client:updateDrivers()
        for _, driver in ipairs(self.drivers) do
            local value = self:evaluate(driver.values)
            local attribute = "state-" .. driver.state
            if driver.frame.attributes[attribute] ~= value then
                restricted = restricted + 1
                setAttribute(driver.frame, attribute, value)
                restricted = restricted - 1
            end
        end
        return self
    end
    function Region:CreateTexture()
        return newRegion()
    end
    function Region:CreateFontString()
        return newRegion()
    end
    function Region:CreateAnimationGroup()
        return newRegion()
    end
    function Region:CreateAnimation()
        return newRegion()
    end
    function Region:CreateMaskTexture()
        return newRegion()
    end
    -- A button's textures and label, made on first ask, as AceGUI's widgets style them.
    for _, getter in ipairs({
        "GetNormalTexture",
        "GetPushedTexture",
        "GetHighlightTexture",
        "GetDisabledTexture",
        "GetCheckedTexture",
        "GetFontString",
    }) do
        Region[getter] = function(self)
            local key = "_" .. getter
            if not rawget(self, key) then rawset(self, key, newRegion()) end
            return rawget(self, key)
        end
    end

    -- The named children a template makes ($parentLeft and so on), for templates whose children
    -- Ace3 looks up by global name.
    local TEMPLATE_CHILDREN = {
        UIDropDownMenuTemplate = { "Left", "Middle", "Right", "Button", "Text" },
    }

    function CreateFrame(kind, name, parent, template)
        local frame = newRegion({ kind = kind, name = name, parent = parent, template = template })
        frame.protected = (template or ""):find("Secure") ~= nil
        frame.stateHandler = (template or ""):find("SecureHandlerStateTemplate") ~= nil
        if kind == "Button" then
            function frame:RegisterForClicks(...)
                self.clicks = { ... }
            end
        end
        -- A tooltip set to a trainer row knows that row's spell.
        if kind == "GameTooltip" then
            function frame:SetTrainerService(index)
                self.row = client.trainer.rows[index]
            end
            function frame:GetSpell()
                if self.row then return self.row[1], self.row[3] end
            end
            function frame:Hide()
                self.shown, self.row = false, nil
            end
        end
        client.frames[#client.frames + 1] = frame
        if name then _G[name] = frame end
        for _, suffix in ipairs(name and TEMPLATE_CHILDREN[template] or {}) do
            _G[name .. suffix] = newRegion({ name = name .. suffix })
        end
        return frame
    end
    UIParent = newRegion()
    WorldFrame = newRegion()
    ClassTrainerFrame = newRegion()
    ClassTrainerFrame.shown = false
    -- The world map; its canvas is what Blizzard anchors the map's corner buttons to.
    WorldMapFrame = newRegion()
    local canvas = newRegion()
    function WorldMapFrame:GetCanvasContainer()
        return canvas
    end

    -- The game's tooltip over an action button (client:hoverAction): client.tooltipLines holds the
    -- lines added to it. client.actions: slot -> { kind, id } as GetActionInfo gives it.
    client.actions, client.tooltipLines = {}, {}
    GameTooltip = newRegion()
    function GameTooltip:SetAction() end
    function GameTooltip:AddLine(text, r, g, b, wrap)
        client.tooltipLines[#client.tooltipLines + 1] = { text = text, color = { r, g, b }, wrap = wrap }
    end
    function GetActionInfo(slot)
        local action = client.actions[slot]
        if action then return action[1], action[2] end
    end
    UISpecialFrames = {}
    -- client.printed: every chat line, whether through print or the default chat frame.
    DEFAULT_CHAT_FRAME = newRegion()
    function DEFAULT_CHAT_FRAME:AddMessage(text)
        client.printed[#client.printed + 1] = text
    end
    function print(...)
        client.printed[#client.printed + 1] = table.concat({ tostringall(...) }, " ")
    end

    -- The settings window. client.categories: every page added, by ID; client.opened: the IDs
    -- opened. Forever has no C_SettingsUtil (opts.noSettingsPanel), so AceConfigDialog uses the
    -- page name as its ID there.
    client.categories, client.opened = {}, {}
    local nextID = 1
    local function newCategory(frame, name, parent)
        local category = { frame = frame, name = name, parent = parent, ID = nextID }
        nextID = nextID + 1
        function category:GetID()
            return self.ID
        end
        return category
    end
    Settings = {
        RegisterCanvasLayoutCategory = newCategory,
        RegisterCanvasLayoutSubcategory = function(parent, frame, name)
            local category = newCategory(frame, name, parent)
            client.categories[category.ID] = category
            return category
        end,
        RegisterAddOnCategory = function(category)
            client.categories[category.ID] = category
        end,
        GetCategory = function(id)
            return client.categories[id]
        end,
        OpenToCategory = function(id)
            client.opened[#client.opened + 1] = id
        end,
    }
    C_SettingsUtil = not opts.noSettingsPanel and { OpenSettingsPanel = noop } or nil

    local function getMetadata(name, key)
        if name == "Kennel" then return TOC_METADATA[key] end
    end
    C_AddOns = {
        GetAddOnMetadata = getMetadata,
        EnableAddOn = noop,
        LoadAddOn = noop,
        IsAddOnLoaded = function()
            return false
        end,
        DoesAddOnExist = function()
            return false
        end,
    }

    -- Where LibSink sends: client.combatText (Blizzard's floating text, its default), chat lines
    -- sent (client.chatSent), raid warnings and the error frame.
    client.combatText, client.chatSent = {}, {}
    CombatText_StandardScroll = "UP"
    function CombatText_AddMessage(text, _, r, g, b)
        client.combatText[#client.combatText + 1] = { text = text, r = r, g = g, b = b }
    end
    -- client.chatLocked: the client blocks addon chat right now (in combat and the like).
    -- opts.oldChatAPI: the global SendChatMessage instead of C_ChatInfo's.
    local function sendChat(text, kind, _, target)
        client.chatSent[#client.chatSent + 1] = { text, kind, target }
    end
    C_ChatInfo = {
        SendChatMessage = not opts.oldChatAPI and sendChat or nil,
        InChatMessagingLockdown = function()
            return client.chatLocked == true
        end,
    }
    SendChatMessage = opts.oldChatAPI and sendChat or nil
    -- client.channels: the custom chat channels joined, by number ({ [5] = "Hunters" }).
    -- client.inRaid: in a raid group.
    client.channels = {}
    function GetChannelList()
        local list = {}
        for id, name in pairs(client.channels) do
            list[#list + 1], list[#list + 2], list[#list + 3] = id, name, false
        end
        return unpack(list)
    end
    function GetChannelName(id)
        if client.channels[id] then return id, client.channels[id] end
    end
    function IsInRaid()
        return client.inRaid == true
    end
    RaidWarningFrame, UIErrorsFrame = newRegion(), newRegion()
    RaidNotice_AddMessage = noop

    SlashCmdList = {}
    hash_SlashCmdList = {}
    _G[TOC_SAVED] = opts.saved

    -- EllesmereUI, as far as Kennel uses it, when opts.ellesmere says it is loaded. client.eui
    -- records what was asked of it: the fonts set, the borders made, the shadows primed.
    EllesmereUI = nil
    -- MessageQueue, when opts.messageQueue says it is loaded: client.queued records what was
    -- handed to its SendChatMessage.
    MessageQueue = nil
    -- client.enqueued: the functions handed to its Enqueue, run by client:runMessageQueue.
    client.queued, client.enqueued = {}, {}
    if opts.messageQueue then
        MessageQueue = {
            SendChatMessage = function(text, kind, language, target)
                client.queued[#client.queued + 1] = { text, kind, language, target }
            end,
            Enqueue = function(fn)
                client.enqueued[#client.enqueued + 1] = fn
            end,
        }
    end

    -- HandyNotes, when opts.handyNotes says it is loaded: its plugin registry and coordinate
    -- helpers. client.mapUpdates counts the redraws asked of it, world map and minimap apart.
    HandyNotes = nil
    client.mapUpdates = { world = 0, minimap = 0 }
    if opts.handyNotes then
        HandyNotes = {
            plugins = {},
            RegisterPluginDB = function(self, name, handler, options)
                assert(not self.plugins[name], name .. " is already registered by another plugin.")
                self.plugins[name] = handler
                self.pluginOptions = options
            end,
            getCoord = function(_, x, y)
                return math.floor(x * 10000 + 0.5) * 10000 + math.floor(y * 10000 + 0.5)
            end,
            getXY = function(_, coord)
                return math.floor(coord / 10000) / 10000, (coord % 10000) / 10000
            end,
            UpdateWorldMapPlugin = function()
                client.mapUpdates.world = client.mapUpdates.world + 1
            end,
            UpdateMinimapPlugin = function()
                client.mapUpdates.minimap = client.mapUpdates.minimap + 1
            end,
        }
    end

    if opts.ellesmere then
        local eui = { borders = {}, shadows = {} }
        client.eui = eui
        EllesmereUI = {
            ELLESMERE_GREEN = { r = 0.05, g = 0.82, b = 0.62 },
            GetFontPath = function()
                return "Fonts\\Expressway.ttf"
            end,
            GetFontOutlineFlag = function()
                return "OUTLINE"
            end,
            GetFontUseShadow = function()
                return true
            end,
            PrimeFontShadow = function(fs, use)
                eui.shadows[#eui.shadows + 1] = { fs, use }
            end,
            MakeBorder = function(parent, r, g, b, a)
                eui.borders[#eui.borders + 1] = { parent, r, g, b, a }
            end,
        }
        if type(opts.ellesmere) == "table" then
            for key in pairs(opts.ellesmere) do
                EllesmereUI[key] = nil
            end
        end
    end

    -- LibStub keeps its libraries in a global; a fresh client starts without one.
    LibStub = nil
    local ns = {}
    for _, file in ipairs(TOC_FILES) do
        Chunk(file, opts.dev == true)("Kennel", ns)
    end
    client.Kennel = ns
    if opts.modules then opts.modules(ns) end

    ---Delivers an event to every frame registered for it.
    ---Delivers an event to every frame registered for it; a unit event only to frames registered
    ---for its unit (the first argument).
    function client:fire(event, ...)
        local unit = ...
        for _, frame in ipairs(self.frames) do
            local registered = frame.events[event]
            if registered and (registered == true or registered == unit) and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, event, ...)
            end
        end
        return self
    end

    ---What pressing the CareButton casts now, with the modifier keys in `mods`; nil when the button
    ---runs nothing.
    function client:press(mods)
        local button = _G.KennelCareButton
        local text = button.attributes.type == "macro" and button.attributes.macrotext
        if not text then return nil end
        assert(button.attributes.useOnKeyDown == false, "the button acts on the key binding's release")
        local options = assert(text:match("^/use (.*)$"), "the macro is one /use line")
        self.mods = mods or {}
        local spell = self:evaluate(options)
        self.mods = {}
        return spell
    end

    ---The pet dies; its body stays for now.
    function client:petDies()
        self.pet.dead, self.pet.health = true, 0
        self:updateDrivers()
        return self:fire("UNIT_HEALTH", "pet")
    end

    ---No pet unit any more: the dead body is gone, or the pet was dismissed.
    function client:petGone()
        self.pet = nil
        return self:updateDrivers()
    end

    ---A living pet at full health: summoned or revived.
    function client:petBack()
        self.pet = { health = 100, max = 100, dead = false }
        self:updateDrivers()
        return self:fire("UNIT_HEALTH", "pet")
    end

    ---The pet's health changes to `health` (of 100).
    function client:petHealth(health)
        self.pet.health = health
        return self:fire("UNIT_HEALTH", "pet")
    end

    function client:enterCombat()
        self.inCombat = true
        return self:fire("PLAYER_REGEN_DISABLED")
    end

    function client:leaveCombat()
        self.inCombat = false
        return self:fire("PLAYER_REGEN_ENABLED")
    end

    ---A cast of `spellID` starts or fails; castGUID defaults to "Cast-1".
    function client:castStarts(spellID, castGUID)
        return self:fire("UNIT_SPELLCAST_START", "player", castGUID or "Cast-1", spellID)
    end
    function client:castFails(spellID, castGUID)
        return self:fire("UNIT_SPELLCAST_FAILED", "player", castGUID or "Cast-1", spellID)
    end

    ---The red error text in the middle of the screen.
    function client:uiError(message)
        return self:fire("UI_ERROR_MESSAGE", 51, message)
    end

    ---Moves the clock on and runs the C_Timer callbacks that came due.
    function client:advance(seconds)
        self.time = self.time + seconds
        local due = {}
        for i = #self.timers, 1, -1 do
            if self.timers[i].at <= self.time then table.insert(due, 1, table.remove(self.timers, i)) end
        end
        for _, timer in ipairs(due) do
            timer.callback()
        end
        return self
    end

    ---What the client does at login: ADDON_LOADED for each addon, PLAYER_LOGIN, the macros
    ---loading; then the moment the modules wait before their first check.
    function client:login()
        self:fire("ADDON_LOADED", "SomeOtherAddon")
        self:fire("ADDON_LOADED", "Kennel")
        self.loggedIn = true
        self:fire("PLAYER_LOGIN")
        self:fire("UPDATE_MACROS")
        return self:advance(0.2)
    end

    ---The pet bar changed (autocast switched, a pet summoned); the modules check a moment later.
    function client:petBarUpdate()
        self:fire("PET_BAR_UPDATE")
        return self:advance(0.2)
    end

    ---Sets autocast of the ability `id` wherever the pet has it, bar and book, without an event.
    function client:setAutocast(id, on)
        for _, list in ipairs({ self.petBar or {}, self.petBook }) do
            for _, entry in ipairs(list) do
                if entry[1] == id then entry[2] = on end
            end
        end
        return self
    end

    ---Switches autocast of the ability `id`, as a right-click does: PET_BAR_UPDATE follows.
    function client:autocast(id, on)
        return self:setAutocast(id, on):petBarUpdate()
    end

    ---The client's "learned" chat line for `what` (a name such as "Claw (Rank 2)", or a link), as
    ---a system message.
    function client:learnLine(what)
        return self:fire("CHAT_MSG_SYSTEM", ERR_LEARN_ABILITY_S:format(what))
    end

    ---Summons a living pet named `name` with `book` as its spellbook (spell IDs); UNIT_PET follows.
    function client:summon(name, book)
        self.pet = { health = 100, max = 100, dead = false, name = name }
        self.petBook = {}
        for _, id in ipairs(book) do
            self.petBook[#self.petBook + 1] = { id }
        end
        self:updateDrivers()
        return self:fire("UNIT_PET", "player")
    end

    ---The pet gets `count` training points: the total rises and the client says so.
    function client:gainPoints(count)
        self.trainingPoints[1] = self.trainingPoints[1] + count
        return self:fire("UNIT_PET_TRAINING_POINTS", "pet")
    end

    ---The pet levels up, which brings `points` training points (none at loyalty level 1).
    function client:petLevelUp(points)
        self.petLevel = self.petLevel + 1
        return self:gainPoints(points)
    end

    ---The pet's loyalty changes to `loyalty` (the client's text), its total by `points`.
    function client:loyaltyChange(loyalty, points)
        self.loyalty = loyalty
        return self:gainPoints(points)
    end

    ---Opens the trainer window with `rows`: Beast Training, or a pet trainer's with `npc`.
    function client:openTrainer(rows, npc)
        self.trainer = { rows = rows, npc = npc == true }
        ClassTrainerFrame:Show()
        return self:fire("TRAINER_SHOW")
    end

    ---Closes the trainer window; `event` is what the client sends, TRAINER_CLOSED by default.
    function client:closeTrainer(event)
        self.trainer = nil
        ClassTrainerFrame:Hide()
        return self:fire(event or "TRAINER_CLOSED")
    end

    ---The mouse over action button `slot`, which holds the macro called `macro` (or the action
    ---already in client.actions); gives the lines added to the game's tooltip.
    function client:hoverAction(slot, macro)
        if macro then self.actions[slot] = { "macro", GetMacroIndexByName(macro) } end
        self.tooltipLines = {}
        GameTooltip:SetAction(slot)
        return self.tooltipLines
    end

    ---The pins Kennel's HandyNotes plugin gives for a map, as HandyNotes reads them: a list of
    ---{ coord, x, y, icon }, x and y in percent.
    ---@param uiMapID number
    ---@param minimap boolean?
    ---@return table[]
    function client:mapPins(uiMapID, minimap)
        local plugin = HandyNotes.plugins.Kennel
        local pins = {}
        for coord, _, icon in plugin:GetNodes2(uiMapID, minimap == true) do
            local x, y = HandyNotes:getXY(coord)
            pins[#pins + 1] =
                { coord = coord, x = math.floor(x * 1000 + 0.5) / 10, y = math.floor(y * 1000 + 0.5) / 10, icon = icon }
        end
        return pins
    end

    ---The mouse over a pin of Kennel's plugin: HandyNotes calls OnEnter with the pin as self.
    ---Gives the tooltip's title and its lines.
    ---@param uiMapID number
    ---@param coord number
    ---@return string? title
    ---@return table[] lines
    function client:hoverPin(uiMapID, coord)
        self.tooltipLines = {}
        GameTooltip.text = nil
        local pin = newRegion()
        HandyNotes.plugins.Kennel.OnEnter(pin, uiMapID, coord)
        return GameTooltip.text, self.tooltipLines
    end

    ---A click on a pin of Kennel's plugin: HandyNotes calls OnClick with the pin as self, once as
    ---the button goes down and once as it comes up.
    ---@param uiMapID number
    ---@param coord number
    ---@param button string?
    function client:clickPin(uiMapID, coord, button)
        local pin = newRegion()
        HandyNotes.plugins.Kennel.OnClick(pin, button or "LeftButton", true, uiMapID, coord)
        HandyNotes.plugins.Kennel.OnClick(pin, button or "LeftButton", false, uiMapID, coord)
    end

    ---The bag slot holding itemID, added (empty) if there is none.
    function client:slotOf(itemID)
        for slot, item in ipairs(self.bag) do
            if item.itemID == itemID then return slot end
        end
        self.bag[#self.bag + 1] = { itemID = itemID, count = 0 }
        return #self.bag
    end

    ---Puts `count` of an item in the bags; the client then reports the change.
    function client:stock(itemID, count)
        self.bag[self:slotOf(itemID)].count = count
        return self:fire("BAG_UPDATE_DELAYED")
    end

    ---One of an item leaves the bags, as when the pet eats it.
    function client:eat(itemID)
        local slot = self:slotOf(itemID)
        self.bag[slot].count = self.bag[slot].count - 1
        if self.bag[slot].count <= 0 then table.remove(self.bag, slot) end
        return self:fire("BAG_UPDATE_DELAYED")
    end

    ---Picks an item from the bags, as clicking it while Feed Pet waits for its target does.
    function client:pickItem(itemID, whileTargeting)
        local slot = self:slotOf(itemID)
        if self.bag[slot].count == 0 then self.bag[slot].count = 1 end
        self.targeting = whileTargeting ~= false
        C_Container.UseContainerItem(0, slot)
        self.targeting = false
        return self
    end

    ---A spell cast by the player succeeds; Feed Pet by default.
    function client:castSucceeded(spellID, unit)
        return self:fire("UNIT_SPELLCAST_SUCCEEDED", unit or "player", "Cast-GUID", spellID or FEED_PET)
    end

    ---A whole Feed Pet: pick the food, then the cast succeeds `delay` seconds later.
    function client:feed(itemID, delay)
        self:pickItem(itemID)
        self.time = self.time + (delay or 0.2)
        return self:castSucceeded()
    end

    ---Feed Pet from the spellbook with a click the addon cannot see: the only trace is the food
    ---leaving the bags, before or after the cast is reported.
    function client:spellbookFeed(itemID, eatenBeforeCast)
        self:stock(itemID, 3)
        self.time = self.time + 0.2
        if eatenBeforeCast then self:eat(itemID) end
        self:castSucceeded()
        if not eatenBeforeCast then
            self:advance(0.1)
            self:eat(itemID)
        end
        return self
    end

    ---Picks an item up onto the cursor, as dragging it out of a bag does.
    function client:pickUp(itemID)
        self.cursorItem = itemID
        return self:fire("CURSOR_CHANGED", false, 1, 0, 0)
    end

    ---Empties the cursor: dropped on the pet, or put back.
    function client:release()
        self.cursorItem = nil
        return self:fire("CURSOR_CHANGED", true, 0, 1, 0)
    end

    ---Feeding by dragging food onto the pet: pick up, drop, then the cast succeeds.
    function client:dragFeed(itemID, delay)
        self:pickUp(itemID)
        self.time = self.time + 1
        self:release()
        self.time = self.time + (delay or 0.1)
        return self:castSucceeded()
    end

    ---Lets pending timers run out (a cast with unknown food waits up to a second for the bags),
    ---then presses a key: the emote waits for one.
    function client:settle()
        self:advance(1.1)
        return self:pressKey()
    end

    ---The text of the last chat message sent, after settling.
    function client:lastSent()
        self:settle()
        local sent = self.chatSent[#self.chatSent]
        return sent and sent[1]
    end

    ---A key press: every shown frame that takes keys gets it.
    function client:pressKey(key)
        for _, frame in ipairs(self.frames) do
            if frame.shown and frame.scripts.OnKeyDown then frame.scripts.OnKeyDown(frame, key or "W") end
        end
        return self
    end

    ---A click in the game world.
    function client:clickWorld()
        for _, hook in ipairs(WorldFrame.hooks.OnMouseDown or {}) do
            hook(WorldFrame, "LeftButton")
        end
        return self
    end

    ---MessageQueue's next hardware event: it runs what was enqueued.
    function client:runMessageQueue()
        local queued = self.enqueued
        self.enqueued = {}
        for _, fn in ipairs(queued) do
            fn()
        end
        return self
    end

    ---Joins or leaves a group.
    function client:group(inGroup)
        self.inGroup = inGroup
        self:fire("GROUP_ROSTER_UPDATE")
        return self:advance(0.2)
    end

    ---The toast frame, once a toast has shown.
    function client:toast()
        return self.Kennel:ToastFrame()
    end

    ---The title of the toast that is up, or nil.
    function client:toastTitle()
        local toast = self:toast()
        return toast and toast.shown and toast.Title.text or nil
    end

    ---Runs the toast clock's OnUpdate for `seconds`, in frames of `step`. Like the client, a
    ---hidden frame gets no more updates.
    function client:animate(seconds, step)
        step = step or 0.05
        local driver, elapsed = self.Kennel:ToastDriver(), 0
        while driver and elapsed < seconds - 1e-9 and driver.shown do
            driver.scripts.OnUpdate(driver, step)
            elapsed = elapsed + step
        end
        return self
    end

    ---The macro of that name, this character's or the account's, or nil.
    function client:macro(name)
        for _, list in ipairs({ self.charMacros, self.macros }) do
            for _, macro in ipairs(list) do
                if macro.name == name then return macro end
            end
        end
    end

    ---What the client does at logout: AceDB strips the defaults from the saved table.
    function client:logout()
        self:fire("PLAYER_LOGOUT")
        return self
    end

    ---Runs a /kennel line the way the chat box does.
    function client:slash(message)
        SlashCmdList.ACECONSOLE_KENNEL(message)
        return self
    end

    function client:printedContains(text)
        for _, line in ipairs(self.printed) do
            if line:find(text, 1, true) then return true end
        end
        return false
    end

    return client
end

function Saved()
    return _G[TOC_SAVED]
end
