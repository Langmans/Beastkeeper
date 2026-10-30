local _, ns = ...

-- A toast when the hunter learns a pet ability from a tamed beast: the ability and its rank, the
-- pet that taught it with its portrait and free training points, and that pet family's call.
-- Others when the pet gains training points and when its loyalty drops. Detect.lua finds the
-- learn; Known.lua keeps the history, the ranks known and how each pet stood per character, reads Beast Training and says
-- what a pet can still teach. Only a hunter learns pet abilities: on any other class the module
-- watches nothing.
--
-- The client replays known spells in the first seconds after login, and a trainer window lists
-- ranks bought rather than learned; neither is news (self.ready, self.atTrainer).

---@type Addon
local Addon = ns
local L = Addon.L

---@type AddonAbilityLearned
local M = Addon:NewModule("AbilityLearned")
M.title = L.ABILITYLEARNED_TITLE
M.description = L.ABILITYLEARNED_DESC
M.requires = { "beastTraining" }
M.toastTypes = {
    learned = L.ABILITYLEARNED_TOASTTYPE_LEARNED,
    points = L.ABILITYLEARNED_TOASTTYPE_POINTS,
    loyalty = L.ABILITYLEARNED_TOASTTYPE_LOYALTY,
}
M.toastSkins = { learned = "splash" }
M.defaults = {
    profile = {
        sound = "family",
        screenshot = false,
        hints = true,
        points = true,
        pointsSound = "family",
        loyalty = true,
        loyaltySound = "family",
    },
    char = { history = {}, known = {}, ranks = {}, trainingRead = false },
    -- Beast Training's training point cost and pet level per ability and rank, and per pet family
    -- the abilities it is shown: the same for every character.
    global = { costs = {}, taught = {} },
}

local LEVEL_UP = 888 -- SOUNDKIT.LEVEL_UP
local LOGIN_WAIT = 5 -- seconds
local HINT_WAIT = 1 -- seconds for a new pet's spellbook to fill in
-- Not every client has every one; a missing one is skipped.
local EVENTS = {
    "CHAT_MSG_SYSTEM",
    "LEARNED_SPELL_IN_TAB",
    "LEARNED_SPELL_IN_SKILL_LINE",
    "TRAINER_SHOW",
    "TRAINER_UPDATE",
    "CRAFT_SHOW",
    "CRAFT_UPDATE",
    "TRAINER_CLOSED",
    "TRADE_SKILL_CLOSE",
    "UNIT_PET",
}

---The settings of the profile in use.
---@return AddonAbilityLearnedSettings
function M:Settings()
    return self.db.profile --[[@as AddonAbilityLearnedSettings]]
end

---The sound a sound setting asks for: the pet's own (the level-up sound when its family has none
---or it is not about the pet out), the level-up sound, or none.
---@param key "sound"|"pointsSound"|"loyaltySound" the setting of the kind of toast
---@param petSound "AGGRO"|"WOUND"|nil which of the pet's sounds; nil when it is not about the pet out
---@return AddonSound?
function M:Sound(key, petSound)
    local setting = self:Settings()[key]
    if setting == "off" then return nil end
    return setting == "family" and petSound and Addon.PetSound(petSound) or { kit = LEVEL_UP }
end

---The toast for a learn.
---@param learn AddonLearn
---@return AddonToastInfo
function M:Toast(learn)
    local teacher = learn.teacher
    local points = teacher and Addon.PetTrainingPoints()
    local ability = learn.rank and ("%s (%s)"):format(learn.name, learn.rank) or learn.name
    return {
        key = "AbilityLearned:" .. learn.name,
        type = "AbilityLearned:learned",
        source = self.title,
        title = L.ABILITYLEARNED_TOAST:format(ability),
        text = teacher and L.ABILITYLEARNED_FROM_PET:format(teacher, learn.name) or L.ABILITYLEARNED_TEACH,
        hint = points and L.ABILITYLEARNED_POINTS:format(teacher, points) or nil,
        icon = learn.icon,
        portrait = teacher and "pet" or nil,
        screenshot = self:Settings().screenshot,
        sound = self:Sound("sound", teacher and "AGGRO" or nil),
    }
end

---Shows a learn and, unless it was simulated, keeps it in the history.
---@param learn AddonLearn
function M:ShowLearn(learn)
    Addon:ShowToast(self:Toast(learn))
    if learn.simulated then return end
    self:RecordLearn({
        name = learn.name,
        rank = learn.rank,
        pet = learn.teacher,
        npc = learn.teacher and Addon.PetNPC() or nil,
        familyID = learn.teacher and Addon.PetFamilyID() or nil,
        zone = GetZoneText(),
        t = GetServerTime(),
    })
end

---Whether a trainer window (a pet trainer's, or Beast Training) is open. The flag comes from the
---events; the window has the last word, so a close event the client does not send cannot leave
---learns ignored for the rest of the session.
---@return boolean
function M:TrainerOpen()
    if self.atTrainer and not ClassTrainerFrame:IsShown() then self.atTrainer = false end
    return self.atTrainer
end

---@param _ string the event
---@param message GameValue
function M:CHAT_MSG_SYSTEM(_, message)
    self:OnChat(message)
end

---@param _ string the event
---@param spellID number
function M:LEARNED_SPELL_IN_TAB(_, spellID)
    self:SpellLearned(spellID)
end
M.LEARNED_SPELL_IN_SKILL_LINE = M.LEARNED_SPELL_IN_TAB

-- The trainer window: a pet trainer's, or Beast Training (which Known.lua reads).
function M:TRAINER_SHOW()
    self.atTrainer = true
    self:ReadBeastTraining()
end

function M:TRAINER_UPDATE()
    self:ReadBeastTraining()
end

-- The craft window: Beast Training on Classic Era and Burning Crusade, or Enchanting.
function M:CRAFT_SHOW()
    self:ReadBeastCraft()
end
M.CRAFT_UPDATE = M.CRAFT_SHOW

function M:TRAINER_CLOSED()
    self.atTrainer = false
end
-- What WoW: Forever sends when Beast Training closes.
M.TRADE_SKILL_CLOSE = M.TRAINER_CLOSED

local function CheckHintsLater()
    M:CheckHints()
end

-- A pet summoned, tamed or dismissed: its spellbook fills in just after.
---@param _ string the event
---@param unit string
function M:UNIT_PET(_, unit)
    if unit == "player" then C_Timer.After(HINT_WAIT, CheckHintsLater) end
end

function M:OnEnable()
    self.ready, self.atTrainer = false, false
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    Addon.RegisterEvents(self, EVENTS)
    -- How the pet grew comes from the core, which waits out the login itself.
    Addon:Listen(self, Addon.messages.petGrowth, "OnGrowth")
    C_Timer.After(LOGIN_WAIT, function()
        if not self:IsEnabled() then return end
        self.ready = true
        self:CheckHints()
    end)
end

-- AceEvent drops the events by itself; the toasts and the message go here.
function M:OnDisable()
    self.ready = false
    Addon:StopListening(self)
    Addon:DropToasts("AbilityLearned:")
end
