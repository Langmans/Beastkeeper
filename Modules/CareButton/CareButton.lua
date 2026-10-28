local _, ns = ...

-- One key for the pet (Button.lua) and the toasts around it:
--   - dead:  the pet died, or a failed cast showed it is dead; again at the pull while it still is;
--   - nopet: combat starts without a pet that is known to be dead;
--   - low:   the pet's health drops to the set line; again only after it was back above it. While
--     the client hides the health this cannot be decided; the marker (Marker.lua) shows it then;
--   - passive: combat starts with the pet on Passive, which will not attack; it goes when the
--     stance changes. The stance is read from the pet bar, never a hidden value.
-- Each goes away once solved. Failed casts teach the button what its state driver cannot see:
-- Call Pet failing (or "Your pet is dead") without a pet means it is dead; Revive Pet failing
-- before its cast started means there is none to revive.

---@type Addon
local Addon = ns
local L = Addon.L

---@type AddonCareButton
local M = Addon:NewModule("CareButton")
M.title = L.CAREBUTTON_TITLE
M.description = L.CAREBUTTON_DESC
M.toastTypes = {
    dead = L.CAREBUTTON_TOASTTYPE_DEAD,
    nopet = L.CAREBUTTON_TOASTTYPE_NOPET,
    low = L.CAREBUTTON_TOASTTYPE_LOW,
    passive = L.CAREBUTTON_TOASTTYPE_PASSIVE,
}
M.defaults = {
    profile = { died = true, nopet = true, passive = true, low = 40, marker = true, visible = true, sound = "family" },
    char = { petDead = false },
}

M.MEND_PET, M.REVIVE_PET, M.CALL_PET = 136, 982, 883
local RAID_WARNING = SOUNDKIT.RAID_WARNING --[[@as number]]
-- The English names, for a client that cannot name the spell itself.
local FALLBACK_NAMES = { [136] = "Mend Pet", [982] = "Revive Pet", [883] = "Call Pet", [5149] = "Beast Training" }
-- The names the client's "Your pet is dead" error may have among the global strings.
local PET_DEAD_ERRORS = { "ERR_PET_SPELL_DEAD", "PETTAME_DEAD" }

-- Per toast: the spell it points to (its icon, and the button that answers it), its title and
-- text, and which of the pet's sounds it plays. Passive is answered on the pet bar, not by the
-- button: it has the pet bar's Passive icon and no hint.
---@type table<string, {spell: number?, title: string, reason: string, sound: "AGGRO"|"DEATH"|"WOUND"}>
local ALERTS = {
    dead = { spell = 982, title = L.CAREBUTTON_TOAST_DEAD, reason = L.CAREBUTTON_REASON_DEAD, sound = "DEATH" },
    nopet = { spell = 883, title = L.CAREBUTTON_TOAST_NOPET, reason = L.CAREBUTTON_REASON_NOPET, sound = "AGGRO" },
    low = { spell = 136, title = L.CAREBUTTON_TOAST_LOW, reason = L.CAREBUTTON_REASON_LOW, sound = "WOUND" },
    passive = { title = L.CAREBUTTON_TOAST_PASSIVE, reason = L.CAREBUTTON_REASON_PASSIVE, sound = "AGGRO" },
}

---The settings of the profile in use.
---@return AddonCareButtonSettings
function M:Settings()
    return self.db.profile --[[@as AddonCareButtonSettings]]
end

---A spell's name as the client calls it, for macros; the English name without one.
---@param id number
---@return string
function M.SpellName(id)
    return Addon.SpellInfo(id) or FALLBACK_NAMES[id]
end

---How to press the button: its key binding, or the macro.
---@return string
local function PressHint()
    local key = GetBindingKey("CLICK " .. Addon.Global("CareButton") .. ":LeftButton")
    return key and L.CAREBUTTON_HINT_KEY:format(GetBindingText(key)) or L.CAREBUTTON_HINT_MACRO
end

---The sound for a toast: the pet's own, the raid warning, or none.
---@param kind "AGGRO"|"DEATH"|"WOUND"
---@return AddonSound?
function M:Sound(kind)
    local setting = self:Settings().sound
    if setting == "off" then return nil end
    return setting == "family" and Addon.PetSound(kind) or { kit = RAID_WARNING }
end

---The toast for `kind`.
---@param kind "dead"|"nopet"|"low"|"passive"
---@param reason string? instead of the toast's own text
---@param percent number? the pet's health, for low
---@return AddonToastInfo
function M:Toast(kind, reason, percent)
    local alert = ALERTS[kind]
    ---@type (number|string)?
    local icon = PET_PASSIVE_TEXTURE
    if alert.spell then
        _, icon = Addon.SpellInfo(alert.spell)
    end
    return {
        key = "CareButton:" .. kind,
        type = "CareButton:" .. kind,
        source = self.title,
        title = alert.title:format(percent),
        text = reason or alert.reason,
        hint = alert.spell and PressHint() or nil,
        icon = icon,
        sound = self:Sound(alert.sound),
    }
end

---Whether the pet is on Passive, from the stance tokens on the pet bar.
---@return boolean
local function OnPassive()
    if not GetPetActionInfo then return false end
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, _, isToken, isActive = GetPetActionInfo(slot)
        if isToken and name == "PET_MODE_PASSIVE" then return isActive == true end
    end
    return false
end

---Toasts or takes away the low toast, from the pet's health; the marker follows it too.
function M:CheckHealth()
    self:UpdateMarker()
    local line = self:Settings().low
    if line == 0 or not UnitExists("pet") or UnitIsDead("pet") then
        self.lowShown = false
        return Addon:DropToast("CareButton:low")
    end
    local health, max = UnitHealth("pet"), UnitHealthMax("pet")
    if not canaccessvalue(health) or not canaccessvalue(max) or max <= 0 then return end
    local percent = math.floor(health / max * 100)
    if percent > line then
        self.lowShown = false
        Addon:DropToast("CareButton:low")
    elseif not self.lowShown then
        self.lowShown = true
        Addon:ShowToast(self:Toast("low", nil, percent))
    end
end

---The button's state driver reported "dead", "alive" or "none".
---@param state string
function M:OnPetState(state)
    self:UpdateLook()
    if state == "dead" then
        self:CheckHealth()
        if self:Settings().died then Addon:ShowToast(self:Toast("dead")) end
    elseif state == "alive" then
        self.deadAfterCombat = false
        Addon:DropToast("CareButton:dead")
        Addon:DropToast("CareButton:nopet")
        self:CheckHealth()
    end
end

---A cast showed that the pet is dead: switch now, or after combat, and say so.
function M:LearnedDead()
    if UnitExists("pet") or self:PetDead() then return end
    local switched = self:SetPetDead(true)
    if not switched then
        self.deadAfterCombat = true
        Addon:OutOfCombat("CareButton:learned", function()
            if self.deadAfterCombat and not UnitExists("pet") then self:SetPetDead(true) end
            self.deadAfterCombat = false
        end)
    end
    local reason = switched and L.CAREBUTTON_REASON_LEARNED or L.CAREBUTTON_REASON_LEARNED_COMBAT
    if self:Settings().died then Addon:ShowToast(self:Toast("dead", reason)) end
end

---Whether an error message is the client's "Your pet is dead".
---@param message string
---@return boolean
local function IsPetDeadError(message)
    for _, name in ipairs(PET_DEAD_ERRORS) do
        if _G[name] == message then return true end
    end
    return false
end

-- Combat starts: the moment a missing pet, or one on Passive, costs something. A hunter without
-- Call Pet has no pet to miss yet; one taming a beast is in combat with it, and getting a pet.
function M:PLAYER_REGEN_DISABLED()
    if not Addon.KnowsSpell(Addon.CALL_PET) or Addon.IsTaming() then return end
    local settings = self:Settings()
    if UnitExists("pet") then
        if settings.passive and not UnitIsDead("pet") and OnPassive() then Addon:ShowToast(self:Toast("passive")) end
        return
    end
    if self:PetDead() then
        if settings.died then Addon:ShowToast(self:Toast("dead")) end
    elseif settings.nopet then
        Addon:ShowToast(self:Toast("nopet"))
    end
end

---@param _ string the event
---@param errorType number
---@param message GameValue
function M:UI_ERROR_MESSAGE(_, errorType, message)
    if type(message) == "string" and Addon.Readable(message) and IsPetDeadError(message) then self:LearnedDead() end
end

---@param _ string the event
---@param unit string
---@param castGUID GameValue
---@param spellID GameValue
function M:UNIT_SPELLCAST_START(_, unit, castGUID, spellID)
    if unit == "player" and spellID == M.REVIVE_PET and Addon.Readable(castGUID) then
        self.reviveCasts[castGUID] = true
    end
end

---@param _ string the event
---@param unit string
---@param castGUID GameValue
---@param spellID GameValue
function M:UNIT_SPELLCAST_FAILED(_, unit, castGUID, spellID)
    if unit ~= "player" or not Addon.Readable(spellID) or not Addon.Readable(castGUID) then return end
    if spellID == M.CALL_PET then
        -- Mounted, Call Pet fails for that reason instead.
        if not IsMounted() then self:LearnedDead() end
    elseif spellID == M.REVIVE_PET then
        if self.reviveCasts[castGUID] then
            self.reviveCasts[castGUID] = nil
        elseif not UnitExists("pet") and self:PetDead() and self:SetPetDead(false) then
            M:Print(L.CAREBUTTON_REVIVE_FAILED)
        end
    end
end

-- The spellbook changed: Call Pet learned, perhaps, and the button on screen with it; Revive Pet
-- or Mend Pet, and the macro texts with them.
function M:SPELLS_CHANGED()
    self:ApplyButton()
    self:ApplyMacroTexts()
end

---The pet's training points changed, or another pet came out: Beast Training on Alt or not.
---@param _ string the event
---@param unit string
function M:OnPetPoints(_, unit)
    if unit == "pet" or unit == "player" then self:ApplyMacroTexts() end
end

-- The pet bar changed, its stance perhaps: the Passive toast goes once the pet is off Passive.
function M:PET_BAR_UPDATE()
    if not OnPassive() then Addon:DropToast("CareButton:passive") end
end

---@param _ string the event
---@param unit string
function M:UNIT_HEALTH(_, unit)
    if unit == "pet" then self:CheckHealth() end
end

function M:OnEnable()
    self.lowShown, self.deadAfterCombat = false, false
    ---@type table<string, true>
    self.reviveCasts = {}
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("UI_ERROR_MESSAGE")
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
    self:RegisterEvent("PET_BAR_UPDATE")
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("UPDATE_MACROS", "UpdateMacro")
    -- Beast Training on Alt depends on the pet's free points (Button.lua, TrainingOnAlt).
    Addon.RegisterEvents(self, { "UNIT_PET_TRAINING_POINTS", "UNIT_PET" }, "OnPetPoints")
    Addon:OfferMacros(self)
    self:ApplyButton()
end

-- AceEvent drops the events by itself; the toasts and the button go here.
function M:OnDisable()
    Addon:DropToasts("CareButton:")
    self:ApplyButton()
    self:UpdateMarker()
end
