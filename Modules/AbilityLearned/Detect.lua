local _, ns = ...

-- Finding a learn. A hunter learns a Beast Training ability by using it on a tamed pet that has
-- it. The game says so in a system chat line ("You have learned a new ability: Claw (Rank 2).")
-- and maybe with LEARNED_SPELL_IN_TAB / LEARNED_SPELL_IN_SKILL_LINE. Beast Training abilities live
-- in their own window rather than the spellbook, so those events may not fire for them; the chat
-- line is the dependable signal. All are watched, and when more than one reports a learn they are
-- merged for a moment, so it shows once with whatever rank and icon either supplied.
--
-- Only abilities a hunter has to learn from a beast in the wild count; the ones bought from a pet
-- trainer (Growl, Great Stamina, Natural Armor, the resistances) are left out. Nothing compares
-- English text: names and the chat line come from the client, so this works in any language.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("AbilityLearned") --[[@as AddonAbilityLearned]]

-- The rank 1 spell of each wild-learned ability, only to look up its name in the client's
-- language; every rank has the same name. From Wowhead's Forever hunter pet abilities list.
local WILD_ABILITY_IDS = {
    17253, -- Bite
    7371, -- Charge
    16827, -- Claw
    1742, -- Cower
    23099, -- Dash
    24423, -- Demoralizing Screech
    23145, -- Dive
    24604, -- Furious Howl
    24844, -- Lightning Breath
    24450, -- Prowl
    24640, -- Scorpid Poison
    26064, -- Shell Shield
    26090, -- Thunderstomp
    -- Family abilities new in Forever.
    1264758, -- Dismember (crocolisk)
    1265899, -- Dust Cloud (tallstrider)
    1265054, -- Mine! (bird of prey)
    1264735, -- Pinch (crab)
    1265065, -- Savage Rend (raptor)
    1264478, -- Sonic Blast (bat)
    1264494, -- Swipe (bear)
    1265038, -- Tendon Rip (hyena)
    1265843, -- Web (spider)
    1310617, -- Trickster's Dance (fox, a family new in Forever)
}

local MERGE_WINDOW = 0.3 -- seconds the reports of one learn may lie apart
local DUPLICATE_WINDOW = 5 -- seconds a shown ability is not shown again
local CLAW, CLAW_RANK_2 = 16827, 16828 -- for the page's example

-- Built on first use, and again until every name resolved: spell names are not guaranteed to be
-- readable while the addon loads.
---@type table<string, true>, boolean
local wildNames, complete = {}, false

---Whether `name` is a pet ability learned in the wild.
---@param name string
---@return boolean
function M.IsWildAbility(name)
    if not complete then
        complete = true
        for _, id in ipairs(WILD_ABILITY_IDS) do
            local spellName = Addon.SpellInfo(id)
            if spellName then
                wildNames[spellName] = true
            else
                complete = false
            end
        end
    end
    return wildNames[name] == true
end

---A game format string such as "You have learned a new ability: %s." as a Lua pattern that
---captures the %s: positional arguments (%1$s) become plain %s, the rest of the text is escaped.
---@param format string
---@return string
local function Pattern(format)
    local marked = format:gsub("%%%d%$", "%%"):gsub("%%s", "\1")
    local escaped = marked:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
    return "^" .. escaped:gsub("\1", "(.+)") .. "$"
end

---@type string[]
local LEARN_PATTERNS = {}
for _, name in ipairs({ "ERR_LEARN_ABILITY_S", "ERR_LEARN_SPELL_S" }) do
    ---@type GameValue
    local format = _G[name]
    if type(format) == "string" then LEARN_PATTERNS[#LEARN_PATTERNS + 1] = Pattern(format) end
end

---A string the module may read: not hidden by the client, and not empty.
---@param value GameValue
---@return string?
local function Plain(value)
    return Addon.Readable(value) and type(value) == "string" and value ~= "" and value or nil
end

---A learn waiting out the merge window.
---@class AddonPendingLearn
---@field name string
---@field rank string?
---@field icon (number|string)?
---@field fromPet boolean the pet out has the ability: it taught it
---@field petRank string? the rank in the pet's spellbook at the learn
---@field petIcon (number|string)? its icon there
---@field simulated boolean

---@type AddonPendingLearn?
local pending
-- True while the page's simulation feeds its line through.
local simulating = false
---When each ability was last shown (GetTime), against late duplicates.
---@type table<string, number>
local lastShown = {}

---Shows the pending learn, if any and the module is still on. The pet out taught it when it has
---the ability; its spellbook fills in a rank and icon the reports lacked.
local function Flush()
    local learn = pending
    pending = nil
    if not learn or not M:IsEnabled() then return end
    lastShown[learn.name] = GetTime()
    M:ShowLearn({
        name = learn.name,
        rank = learn.rank or learn.petRank,
        icon = learn.icon or learn.petIcon,
        teacher = learn.fromPet and UnitName("pet") or nil,
        simulated = learn.simulated,
    })
end

---A report that `name` was learned. Returns whether it counts as a pet ability learned in the
---wild (shown, merged into the pending one, or a duplicate of one just shown).
---@param name string? the spell's name, maybe with its rank in parentheses
---@param rank string?
---@param spellID number?
---@return boolean
local function Learned(name, rank, spellID)
    if not name then return false end
    if not simulating and (not M.ready or M:TrainerOpen()) then return false end
    if not rank then
        local base, inParens = name:match("^(.-)%s*%((.-)%)$")
        if base and base ~= "" then
            name, rank = base, inParens
        end
    end
    if not simulating and lastShown[name] and GetTime() - lastShown[name] < DUPLICATE_WINDOW then return true end

    ---@type (number|string)?, string?
    local icon, idRank
    if spellID then
        _, icon, idRank = Addon.SpellInfo(spellID)
    end
    if pending and pending.name == name then
        pending.rank = pending.rank or rank or idRank
        pending.icon = pending.icon or icon
        return true
    end
    if not M.IsWildAbility(name) then return false end
    if pending then Flush() end
    -- Copied, not kept: PetSpells refills its entries on its next call.
    local petSpell = Addon.PetSpells()[name]
    pending = {
        name = name,
        rank = rank or idRank,
        icon = icon,
        fromPet = petSpell ~= nil,
        petRank = petSpell and petSpell.rank,
        petIcon = petSpell and petSpell.icon,
        simulated = simulating,
    }
    C_Timer.After(MERGE_WINDOW, Flush)
    return true
end

---A system chat line; returns whether it reported learning a pet ability.
---@param line GameValue
---@return boolean
function M:OnChat(line)
    local message = Plain(line)
    if not message then return false end
    for _, pattern in ipairs(LEARN_PATTERNS) do
        local learned = message:match(pattern)
        if learned then
            -- The name may come as a spell link: |cff..|Hspell:123:0|h[Claw]|h|r
            local spellID = tonumber(learned:match("|Hspell:(%d+)"))
            local name = learned:gsub("|c%x+|H.-|h%[?(.-)%]?|h|r", "%1")
            return Learned(name, nil, spellID)
        end
    end
    return false
end

---A spell learned, by the spellbook events.
---@param spellID number
function M:SpellLearned(spellID)
    local name, _, rank = Addon.SpellInfo(spellID)
    Learned(Plain(name), Plain(rank), spellID)
end

---The ability the page's example uses, with its rank and icon: one of the pet's own wild
---abilities, else Claw rank 2 as the client names it, else as the locale does.
---@return string name
---@return string rank
---@return (number|string)? icon
---@return AddonPetSpell? petSpell the pet's own, when it has it
function M.Example()
    local spells = Addon.PetSpells()
    ---@type string[]
    local names = {}
    for name in pairs(spells) do
        if M.IsWildAbility(name) then names[#names + 1] = name end
    end
    table.sort(names)
    local name = names[1] or Addon.SpellInfo(CLAW) or L.ABILITYLEARNED_TEST_SPELL
    local petSpell = spells[name]
    local _, icon, rank = Addon.SpellInfo(CLAW_RANK_2)
    rank = (petSpell and petSpell.rank) or rank or L.ABILITYLEARNED_TEST_RANK
    return name, rank, (petSpell and petSpell.icon) or icon, petSpell
end

---For the page: the game's learn line for the example ability, fed through the detection as if
---it had just arrived. The login wait, an open trainer and the duplicate window do not hold it
---back; it is not kept in the history.
function M:Simulate()
    local format = ERR_LEARN_ABILITY_S or ERR_LEARN_SPELL_S
    if not format then
        M:Print(L.ABILITYLEARNED_NO_LINE)
        return
    end
    local name, rank = M.Example()
    local line = format:format(("%s (%s)"):format(name, rank))
    M:Print(L.ABILITYLEARNED_SIMULATING:format(line))
    simulating = true
    local counted = self:OnChat(line)
    simulating = false
    if not counted then M:Print(L.ABILITYLEARNED_NOT_WILD:format(name)) end
end
