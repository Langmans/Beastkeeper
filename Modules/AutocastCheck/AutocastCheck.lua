local _, ns = ...

-- Growl or Cower on autocast, as fits: who holds the mobs decides, someone else in a dungeon group
-- (Cower) or the pet elsewhere (Growl), unless the player chose (the KennelKite and KennelGrowl
-- macros) until a dungeon group is entered or left. A problem toasts when it starts and its toast
-- goes away when solved; Button.lua sets it right with one key. The pet's spellbook shows every
-- ability (Cower is often not on the bar); names come from spell IDs, so any language and rank
-- work. On another class the module registers nothing.

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
M.SPELLS = { growl = GROWL, cower = COWER }
-- The English names, for a client that cannot name a spell itself (test toasts and macros only).
local FALLBACK_NAMES = { [GROWL] = "Growl", [COWER] = "Cower", [DISTRACTING_SHOT] = "Distracting Shot" }
local RAID_WARNING = SOUNDKIT.RAID_WARNING --[[@as number]]
local QUESTION_MARK = 134400 -- the icon a macro gets when #showtooltip picks the spell's own
-- Ability_Hunter_BeastTraining: a macro takes a file ID; given a path it has no icon.
local BEAST_TRAINING_ICON = 132162
-- The pet bar sends several updates for one change (a summon fills every slot); one check a
-- moment later covers them all.
local CHECK_DELAY = 0.2
-- After a choice the macro's next lines set autocast, and the pet bar shows it only once the
-- server answers: the check waits that long.
local CHOICE_DELAY = 1

-- The toast's text saying why: by what decided, and for a choice by what was chosen.
---@type table<string, string>
local REASONS = {
    solo = L.AUTOCAST_REASON_SOLO,
    dungeon = L.AUTOCAST_REASON_DUNGEON,
    growl = L.AUTOCAST_REASON_CHOSEN_GROWL,
    cower = L.AUTOCAST_REASON_CHOSEN_COWER,
}

-- The order toasts are shown in when several problems start at once.
local ORDER = { "growlOn", "growlOff", "cowerOn", "cowerOff" }

-- Per problem: the ability it is about and the title. "On" is on autocast while it should be off.
---@type table<string, {spell: number, title: string}>
local PROBLEMS = {
    growlOn = { spell = GROWL, title = L.AUTOCAST_TOAST_ON },
    growlOff = { spell = GROWL, title = L.AUTOCAST_TOAST_OFF },
    cowerOn = { spell = COWER, title = L.AUTOCAST_TOAST_ON },
    cowerOff = { spell = COWER, title = L.AUTOCAST_TOAST_OFF },
}

---A spell's name and icon as the client gives them, with the English name when it has none.
---@param id number
---@return string name
---@return (number|string)? icon
local function Spell(id)
    local name, icon = Kennel.SpellInfo(id)
    return name or FALLBACK_NAMES[id], icon
end
M.Spell = Spell

-- What the last read found: the pet's abilities that can autocast, by name. A check runs on every
-- pet bar update, so the table and each ability's entry are kept and refilled, not built anew.
---@type table<string, KennelAutocastState>, table<string, KennelAutocastState>
local states, entries = {}, {}

---Adds an ability that can autocast to `states`, unless its state is unreadable.
---@param name GameValue
---@param allowed GameValue
---@param enabled GameValue
---@param icon (number|string)?
local function Add(name, allowed, enabled, icon)
    if type(name) == "string" and allowed and Kennel.Readable(enabled) then
        local entry = entries[name] or {}
        entries[name] = entry
        entry.on, entry.icon = enabled and true or false, icon
        states[name] = entry
    end
end

---Reads the pet's spellbook, through C_SpellBook as Forever has it. A client without it is left
---to the pet bar. A command (Attack, Follow) is in the book too, with no autocast values; an entry
---that cannot be read is skipped.
local function ReadBook()
    local book = C_SpellBook
    if not (book and book.GetSpellBookItemAutoCast and book.GetSpellBookItemInfo and book.HasPetSpells) then return end
    local bank = Enum.SpellBookSpellBank.Pet
    -- The first value is the count; the client also returns the pet's type ("PET", "DEMON").
    for index = 1, tonumber((book.HasPetSpells())) or 0 do
        local okInfo, info = pcall(book.GetSpellBookItemInfo, index, bank)
        local okCast, allowed, enabled = pcall(book.GetSpellBookItemAutoCast, index, bank)
        if okInfo and okCast and type(info) == "table" then Add(info.name, allowed, enabled) end
    end
end

---Reads the pet bar; it also gives each ability's icon.
local function ReadBar()
    if not GetPetActionInfo then return end
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, texture, isToken, _, allowed, enabled = GetPetActionInfo(slot)
        -- Attack, Follow and the stances are tokens; they never autocast.
        if not isToken then Add(name, allowed, enabled, texture) end
    end
end

---The pet's abilities that can autocast, by name, with whether autocast is on. Empty without a
---pet. The same table each time, refilled: read it before the next call.
---@return table<string, KennelAutocastState>
function M:PetAutocasts()
    wipe(states)
    if not UnitExists("pet") then return states end
    ReadBook()
    ReadBar()
    return states
end

---Whether the player is in a group inside a dungeon or raid instance (not a battleground or arena).
---@return boolean
local function InDungeonGroup()
    local inInstance, kind = IsInInstance()
    return IsInGroup() and inInstance == true and (kind == "party" or kind == "raid")
end

---Which ability fits now, and what decided: the player's choice while the player stays in or out
---of a dungeon group, else Cower in one and Growl elsewhere. Entering or leaving a dungeon group
---ends a choice.
---@return "growl"|"cower" wanted
---@return "solo"|"dungeon"|"chosen" why
function M:Wanted()
    local dungeon = InDungeonGroup()
    if self.choice and self.choiceInDungeon ~= dungeon then self.choice = nil end
    if self.choice then return self.choice, "chosen" end
    if dungeon then return "cower", "dungeon" end
    return "growl", "solo"
end

---The player chose an ability (the KennelKite or KennelGrowl macro, through /kennel); says so
---when it changes what fits, and checks again once the macro's own autocast lines have landed.
---@param ability "growl"|"cower"
function M:Choose(ability)
    local wanted, why = self:Wanted()
    if why == "chosen" and wanted == ability then return end
    self.choice, self.choiceInDungeon = ability, InDungeonGroup()
    M:Print(ability == "growl" and L.AUTOCAST_CHOSE_GROWL or L.AUTOCAST_CHOSE_COWER)
    self:ApplyButton()
    self:CheckAfter(CHOICE_DELAY)
end

---How to set it right: the button's key binding, or the macro.
---@return string
local function PressHint()
    local key = GetBindingKey("CLICK KennelAutocastButton:LeftButton")
    return key and L.AUTOCAST_HINT_KEY:format(GetBindingText(key)) or L.AUTOCAST_HINT_MACRO
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
---@param reason string the toast's text: why
---@param name string? the ability's name; looked up when nil
---@param icon (number|string)? its icon; looked up when nil
---@return KennelToastInfo
function M:ProblemToast(key, reason, name, icon)
    local problem = PROBLEMS[key]
    local spellName, spellIcon = Spell(problem.spell)
    name = name or spellName
    return {
        key = self.moduleName .. ":" .. key,
        type = self.moduleName .. ":problem",
        source = self.title,
        title = problem.title:format(name),
        icon = icon or spellIcon,
        text = reason,
        hint = PressHint(),
        sound = self:Sound(),
    }
end

---The toast's text for what fits now.
---@return string
function M:Reason()
    local wanted, why = self:Wanted()
    return REASONS[why == "chosen" and wanted or why]
end

-- The problems the next check fills in: it swaps roles with self.active (the last check's) on every
-- check. Per problem key, the ability's name and icon for its toast, which is only built when shown.
---@type table<string, true>, table<string, string>, table<string, (number|string)?>
local spare, problemName, problemIcon = {}, {}, {}

---Notes the problem of one ability in `found`, when it is watched and not as it should be.
---@param found table<string, true>
---@param ability "growl"|"cower"
---@param wanted boolean whether it belongs on autocast
function M:Compare(found, ability, wanted)
    local name = Kennel.SpellInfo(M.SPELLS[ability])
    local state = name and states[name]
    if not state or state.on == wanted then return end
    local key = ability .. (state.on and "On" or "Off")
    found[key], problemName[key], problemIcon[key] = true, name, state.icon
end

---What is wrong right now, by problem key, in `found` (emptied first).
---@param found table<string, true>
---@return table<string, true>
function M:Problems(found)
    wipe(found)
    local settings = self:Settings()
    self:PetAutocasts()
    local growlWanted = self:Wanted() == "growl"
    if settings.growl then self:Compare(found, "growl", growlWanted) end
    if settings.cower then self:Compare(found, "cower", not growlWanted) end
    return found
end

---Sends KENNEL_AUTOCAST_WANTED when what fits, or what decided it, changed since the last check.
function M:TellWanted()
    local wanted, why = self:Wanted()
    if wanted == self.lastWanted and why == self.lastWhy then return end
    local before = self.lastWanted
    self.lastWanted, self.lastWhy = wanted, why
    -- The first check after the module started only takes note.
    if not before then return end
    Kennel:SendMessage(
        "KENNEL_AUTOCAST_WANTED",
        { module = self.moduleName, wanted = wanted, why = why, before = before }
    )
end

---Compares what is wrong now with the last check: a new problem toasts, a solved one takes its
---toast away. With remindAll, every problem toasts, new or not. The button follows what fits.
---@param remindAll boolean?
function M:Check(remindAll)
    self:TellWanted()
    self:ApplyButton()
    local found, active = self:Problems(spare), self.active
    for _, key in ipairs(ORDER) do
        if found[key] and (remindAll or not active[key]) then
            Kennel:ShowToast(self:ProblemToast(key, self:Reason(), problemName[key], problemIcon[key]))
        elseif not found[key] and active[key] then
            Kennel:DropToast(self.moduleName .. ":" .. key)
        end
    end
    self.active, spare = found, active
end

---The check ScheduleCheck asked for; nothing when switched off in the meantime.
local function RunScheduledCheck()
    M.checkPending = false
    if M:IsEnabled() then M:Check() end
end

---Checks once, `delay` seconds from now, however often it is asked in the meantime.
---@param delay number
function M:CheckAfter(delay)
    if self.checkPending then return end
    self.checkPending = true
    C_Timer.After(delay, RunScheduledCheck)
end

---Checks once, a moment from now: the handler of the events that may change what fits.
function M:ScheduleCheck()
    self:CheckAfter(CHECK_DELAY)
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
    ---@type table<string, true>
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
    self:ApplyButton()
    self:ScheduleCheck()
end

-- AceEvent drops the events by itself; the toasts and the button go here.
function M:OnDisable()
    Kennel:DropToasts(self.moduleName .. ":")
    self.active = {}
    self.lastWanted, self.lastWhy = nil, nil
    self:ApplyButton()
end

---/kennel autocast growl: the KennelGrowl macro's line.
---@param module KennelAutocastCheck
local function ChooseGrowl(module)
    module:Choose("growl")
end

---/kennel autocast cower: the KennelKite macro's line.
---@param module KennelAutocastCheck
local function ChooseCower(module)
    module:Choose("cower")
end

M.commands = {
    growl = { desc = L.AUTOCAST_CMD_GROWL, func = ChooseGrowl },
    cower = { desc = L.AUTOCAST_CMD_COWER, func = ChooseCower },
}

---The lines that put `on` on autocast and the other one off, with the client's spell names.
---@param on "growl"|"cower"
---@return string
function M.AutocastLines(on)
    local off = on == "growl" and "cower" or "growl"
    return "/petautocaston " .. Spell(M.SPELLS[on]) .. "\n/petautocastoff " .. Spell(M.SPELLS[off])
end

---The macros, with their text as this client would write it now. Each sets autocast itself (the
---game lets only a macro or a button the player presses do that) and tells the module the choice.
---@return KennelMacro[]
function M:Macros()
    local shot = Spell(DISTRACTING_SHOT)
    local _, growlIcon = Spell(GROWL)
    local kite = { "#showtooltip " .. shot, "/kennel autocast cower", M.AutocastLines("cower"), "/use " .. shot }
    return {
        {
            name = "KennelKite",
            icon = QUESTION_MARK,
            body = table.concat(kite, "\n"),
            desc = L.AUTOCAST_MACRO_KITE,
        },
        {
            name = "KennelGrowl",
            icon = growlIcon or QUESTION_MARK,
            body = "/kennel autocast growl\n" .. M.AutocastLines("growl"),
            desc = L.AUTOCAST_MACRO_GROWL,
        },
        {
            name = "KennelAutocast",
            icon = BEAST_TRAINING_ICON,
            body = "/click KennelAutocastButton",
            desc = L.AUTOCAST_MACRO_AUTOCAST,
        },
    }
end

---Shows an example toast for what fits now, whatever the pet says: that ability off. Its own key,
---so a real toast for the same problem is not taken for this one.
function M:TestToast()
    local info = self:ProblemToast(self:Wanted() .. "Off", self:Reason())
    info.key = info.key .. ":test"
    Kennel:ShowToast(info)
end

BINDING_HEADER_KENNEL = "Kennel"
