local _, ns = ...

-- A toast when Growl or Cower autocast does not fit the mode (the table is in the README): who
-- holds the mobs decides, the pet (solo, tank: Growl on) or someone else (dungeon, kite: Cower
-- on). A problem toasts when it starts and its toast goes away when solved. The pet's spellbook
-- shows every ability (Cower is often not on the bar); names come from spell IDs, so any language
-- and rank work. On another class the module registers nothing.

---@type Kennel
local Kennel = ns
local L = Kennel.L

-- Its fields and settings are described in annotations\Kennel.lua (KennelAutocastCheck,
-- KennelAutocastSettings).
---@type KennelAutocastCheck
local M = Kennel:NewModule("AutocastCheck")
M.title = L.AUTOCAST_TITLE
M.description = L.AUTOCAST_DESC
M.command = "autocast"
-- Its one kind of toast, which can have a look of its own (Kennel's page).
M.toastTypes = { problem = L.AUTOCAST_TOASTTYPE_PROBLEM }
M.defaults = {
    profile = {
        mode = "auto",
        growl = true,
        cower = true,
        remind = true,
        sound = "family",
    },
}

---The settings of the profile in use.
---@return KennelAutocastSettings
function M:Settings()
    return self.db.profile --[[@as KennelAutocastSettings]]
end

local GROWL, COWER, DISTRACTING_SHOT = 2649, 1742, 20736
-- The English names, for a client that cannot name a spell itself (test toasts and macros only).
local FALLBACK_NAMES = { [GROWL] = "Growl", [COWER] = "Cower", [DISTRACTING_SHOT] = "Distracting Shot" }
local RAID_WARNING = 8959 -- SOUNDKIT.RAID_WARNING
-- The pet bar sends several updates for one change (a summon fills every slot); one check a
-- moment later covers them all.
local CHECK_DELAY = 0.2

-- Per mode: whether Growl belongs on autocast; Cower belongs the other way.
---@type table<KennelAutocastMode, boolean>
local GROWL_WANTED = { solo = true, tank = true, dungeon = false, kite = false }

-- Per mode: the toast's text saying why.
---@type table<KennelAutocastMode, string>
local REASONS = {
    solo = L.AUTOCAST_REASON_SOLO,
    dungeon = L.AUTOCAST_REASON_DUNGEON,
    kite = L.AUTOCAST_REASON_KITE,
    tank = L.AUTOCAST_REASON_TANK,
}

-- The order toasts are shown in when several problems start at once.
local ORDER = { "growlOn", "growlOff", "cowerOn", "cowerOff" }

-- Per problem: the ability it is about, the title and the hint. "On" is on autocast while the
-- mode wants it off.
---@type table<string, {spell: number, title: string, hint: string}>
local PROBLEMS = {
    growlOn = { spell = GROWL, title = L.AUTOCAST_TOAST_ON, hint = L.AUTOCAST_HINT_TURN_OFF },
    growlOff = { spell = GROWL, title = L.AUTOCAST_TOAST_OFF, hint = L.AUTOCAST_HINT_TURN_ON },
    cowerOn = { spell = COWER, title = L.AUTOCAST_TOAST_ON, hint = L.AUTOCAST_HINT_TURN_OFF },
    cowerOff = { spell = COWER, title = L.AUTOCAST_TOAST_OFF, hint = L.AUTOCAST_HINT_TURN_ON },
}

---A spell's name and icon as the client gives them, with the English name when it has none.
---@param id number
---@return string name
---@return (number|string)? icon
local function Spell(id)
    local name, icon = Kennel.SpellInfo(id)
    return name or FALLBACK_NAMES[id], icon
end

---Adds an ability that can autocast to `states`, unless its state is unreadable.
---@param states table<string, KennelAutocastState>
---@param name GameValue
---@param allowed GameValue
---@param enabled GameValue
---@param icon (number|string)?
local function Add(states, name, allowed, enabled, icon)
    if type(name) == "string" and allowed and Kennel.Readable(enabled) then
        states[name] = { on = enabled and true or false, icon = icon }
    end
end

---Reads the pet's spellbook into `states`, through C_SpellBook as Forever has it. A client
---without it is left to the pet bar. A command (Attack, Follow) is in the book too, with no
---autocast values; an entry that cannot be read is skipped.
---@param states table<string, KennelAutocastState>
local function ReadBook(states)
    local book = C_SpellBook
    if not (book and book.GetSpellBookItemAutoCast and book.GetSpellBookItemInfo and book.HasPetSpells) then return end
    local bank = Enum.SpellBookSpellBank.Pet
    -- The first value is the count; the client also returns the pet's type ("PET", "DEMON").
    for index = 1, tonumber((book.HasPetSpells())) or 0 do
        local okInfo, info = pcall(book.GetSpellBookItemInfo, index, bank)
        local okCast, allowed, enabled = pcall(book.GetSpellBookItemAutoCast, index, bank)
        if okInfo and okCast and type(info) == "table" then Add(states, info.name, allowed, enabled) end
    end
end

---Reads the pet bar into `states`; it also gives each ability's icon.
---@param states table<string, KennelAutocastState>
local function ReadBar(states)
    if not GetPetActionInfo then return end
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, texture, isToken, _, allowed, enabled = GetPetActionInfo(slot)
        -- Attack, Follow and the stances are tokens; they never autocast.
        if not isToken then Add(states, name, allowed, enabled, texture) end
    end
end

---The pet's abilities that can autocast, by name, with whether autocast is on. Empty without a
---pet.
---@return table<string, KennelAutocastState>
function M:PetAutocasts()
    ---@type table<string, KennelAutocastState>
    local states = {}
    if not UnitExists("pet") then return states end
    ReadBook(states)
    ReadBar(states)
    return states
end

---Whether the player is inside a dungeon or raid instance (not a battleground or arena).
---@return boolean
local function InDungeon()
    local inInstance, kind = IsInInstance()
    return inInstance == true and (kind == "party" or kind == "raid")
end

---The mode in force: kite or tank when chosen, else dungeon in a dungeon or raid group, else solo.
---@return KennelAutocastMode
function M:Mode()
    local chosen = self:Settings().mode
    if chosen == "kite" or chosen == "tank" then return chosen end
    if IsInGroup() and InDungeon() then return "dungeon" end
    return "solo"
end

---The sound for a toast, as the sound setting asks: the pet's call, or the raid warning.
---@return KennelSound?
function M:Sound()
    local setting = self:Settings().sound
    if setting == "off" then return nil end
    return setting == "family" and Kennel.PetSound("AGGRO") or { kit = RAID_WARNING }
end

---The toast for a problem.
---@param key string one of ORDER
---@param mode KennelAutocastMode the mode it is wrong for
---@param name string? the ability's name; looked up when nil
---@param icon (number|string)? its icon; looked up when nil
---@return KennelToastInfo
function M:ProblemToast(key, mode, name, icon)
    local problem = PROBLEMS[key]
    local spellName, spellIcon = Spell(problem.spell)
    name = name or spellName
    return {
        key = self.moduleName .. ":" .. key,
        type = self.moduleName .. ":problem",
        source = self.title,
        title = problem.title:format(name),
        icon = icon or spellIcon,
        text = REASONS[mode],
        hint = problem.hint,
        sound = self:Sound(),
    }
end

---Adds the problem of one ability to `found`, when it is watched and not as the mode wants.
---@param found table<string, KennelToastInfo>
---@param states table<string, KennelAutocastState>
---@param spell number
---@param prefix "growl"|"cower" the problem keys' start
---@param wanted boolean whether the mode wants it on autocast
---@param mode KennelAutocastMode
function M:Compare(found, states, spell, prefix, wanted, mode)
    local name = Kennel.SpellInfo(spell)
    local state = name and states[name]
    if not state or state.on == wanted then return end
    local key = prefix .. (state.on and "On" or "Off")
    found[key] = self:ProblemToast(key, mode, name, state.icon)
end

---What is wrong right now, by problem key.
---@return table<string, KennelToastInfo>
function M:Problems()
    ---@type table<string, KennelToastInfo>
    local found = {}
    local settings = self:Settings()
    local states = self:PetAutocasts()
    local mode = self:Mode()
    local growlWanted = GROWL_WANTED[mode]
    if settings.growl then self:Compare(found, states, GROWL, "growl", growlWanted, mode) end
    if settings.cower then self:Compare(found, states, COWER, "cower", not growlWanted, mode) end
    return found
end

---Compares what is wrong now with the last check: a new problem toasts, a solved one takes its
---toast away. With remindAll, every problem toasts, new or not.
---@param remindAll boolean?
function M:Check(remindAll)
    local found = self:Problems()
    for _, key in ipairs(ORDER) do
        local info = found[key]
        if info and (remindAll or not self.active[key]) then
            Kennel:ShowToast(info)
        elseif not info and self.active[key] then
            Kennel:DropToast(self.moduleName .. ":" .. key)
        end
    end
    self.active = found
end

---Checks once, a moment from now, however often it is asked in the meantime.
function M:ScheduleCheck()
    if self.checkPending then return end
    self.checkPending = true
    C_Timer.After(CHECK_DELAY, function()
        self.checkPending = false
        -- Switched off in the meantime: nothing to check.
        if self:IsEnabled() then self:Check() end
    end)
end

---A pet summoned, tamed or dismissed.
---@param _ string the event
---@param unit string
function M:UNIT_PET(_, unit)
    if unit == "player" then self:ScheduleCheck() end
end

---Combat starts: the moment a wrong autocast costs something.
function M:PLAYER_REGEN_DISABLED()
    self:Check(self:Settings().remind)
end

function M:OnEnable()
    ---@type table<string, KennelToastInfo>
    self.active = {}
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    -- Autocast switched (Blizzard's spellbook redraws its pet autocast on this event too) or the
    -- bar filled after a summon; a group joined or left; a loading screen into or out of a dungeon.
    self:RegisterEvent("PET_BAR_UPDATE", "ScheduleCheck")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "ScheduleCheck")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "ScheduleCheck")
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    Kennel:OfferMacros(self)
    self:ScheduleCheck()
end

-- AceEvent drops the events by itself; the toasts go here.
function M:OnDisable()
    Kennel:DropToasts(self.moduleName .. ":")
    self.active = {}
end

---Kite or tank mode on, off, or switched without a word. Switching one on switches the other off;
---switching it off goes back to the mode the module picks itself. Made for macros, pressed over
---and over: it only says something when the mode actually changes.
---@param mode "kite"|"tank"
---@param args string "on", "off" or ""
function M:ChooseMode(mode, args)
    local settings = self:Settings()
    local current = settings.mode == mode
    local word = args:lower():match("^%s*(%S*)")
    local on = current == false
    if word == "on" then on = true end
    if word == "off" then on = false end
    if on == current then return end
    settings.mode = on and mode or "auto"
    local key = "AUTOCAST_" .. mode:upper() .. (on and "_ON" or "_OFF")
    Kennel:Print(L[key])
    self:Check()
end

---/kennel autocast kite [on|off]
---@param module KennelAutocastCheck
---@param args string
local function Kite(module, args)
    module:ChooseMode("kite", args)
end

---/kennel autocast tank [on|off]
---@param module KennelAutocastCheck
---@param args string
local function Tank(module, args)
    module:ChooseMode("tank", args)
end

M.commands = {
    kite = { desc = L.AUTOCAST_CMD_KITE, func = Kite },
    tank = { desc = L.AUTOCAST_CMD_TANK, func = Tank },
}

---The macros, with their text as this client would write it now.
---@return KennelMacro[]
function M:Macros()
    local shot = Spell(DISTRACTING_SHOT)
    local _, cowerIcon = Spell(COWER)
    local _, growlIcon = Spell(GROWL)
    local questionMark = 134400 -- the icon a macro gets when #showtooltip picks the spell's own
    return {
        {
            name = "KennelKite",
            icon = questionMark,
            body = "#showtooltip " .. shot .. "\n/kennel autocast kite on\n/cast " .. shot,
        },
        { name = "KennelKiteOff", icon = cowerIcon or questionMark, body = "/kennel autocast kite off" },
        { name = "KennelTank", icon = growlIcon or questionMark, body = "/kennel autocast tank" },
    }
end

-- The settings page's examples: the problem each mode choice would toast first.
---@type table<string, [string, KennelAutocastMode]>
local TESTS = { auto = { "growlOn", "dungeon" }, kite = { "cowerOff", "kite" }, tank = { "growlOff", "tank" } }

---Shows an example toast for the chosen mode, whatever the pet says. Its own key, so a real toast
---for the same problem is not taken for this one.
function M:TestToast()
    local test = TESTS[self:Settings().mode]
    local info = self:ProblemToast(test[1], test[2])
    info.key = info.key .. ":test"
    Kennel:ShowToast(info)
end

-- The key bindings (Bindings.xml) go through /kennel, so a module that is off says so.
BINDING_HEADER_KENNEL = "Kennel"
BINDING_NAME_KENNEL_AUTOCAST_KITE = L.AUTOCAST_BINDING_KITE
BINDING_NAME_KENNEL_AUTOCAST_TANK = L.AUTOCAST_BINDING_TANK
function Kennel_AutocastKite()
    Kennel:OnSlash("autocast kite")
end
function Kennel_AutocastTank()
    Kennel:OnSlash("autocast tank")
end
