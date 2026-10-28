local _, ns = ...

-- The tame key: a secure button behind its own key binding that targets the beast Beast Map
-- pointed at last (the rare alarm's, or the one whose pin was clicked) and puts a skull on it;
-- with Shift it casts Tame Beast instead. Only a secure button may target, so its macro text holds
-- the beast's name, rewritten outside combat. For an action bar: a macro with
-- /click BeastkeeperTameButton.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as BeastkeeperBeastMap]]

local TAME_BEAST = Addon.TAME_BEAST
local SKULL = Addon.raidMarks.skull

local button = CreateFrame("Button", Addon.Global("TameButton"), UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown")

---The button's lines for a beast: Shift tames, else target it by name and mark it.
---@param name string
---@return string
local function MacroText(name)
    local tame = Addon.SpellInfo(TAME_BEAST) or "Tame Beast"
    return ("/cast [mod:shift] %s\n/stopmacro [mod:shift]\n/targetexact %s\n/tm %d"):format(tame, name, SKULL)
end

---Gives the button its lines for the beast to tame now, or none while there is none or the module
---is off; after combat when in it.
function M:ApplyTameButton()
    Addon:OutOfCombat("BeastMap:tame", function()
        local name = self:IsEnabled() and self.tameTarget
        button:SetAttribute("useOnKeyDown", false)
        button:SetAttribute("type", name and "macro" or nil)
        button:SetAttribute("macrotext", name and MacroText(name) or nil)
    end)
end

---Makes `name` the beast the tame key goes for, and says so when it changes.
---@param name string the beast's name as the client words it (else the data's)
function M:SetTameTarget(name)
    if not self:IsEnabled() or name == self.tameTarget then return end
    self.tameTarget = name
    self:Print(L.BEASTMAP_TAME_SET:format(name))
    self:ApplyTameButton()
end

---BEASTKEEPER_RARE_SEEN, the rare alarm's message: that beast is the one to tame.
---@param _ string the message
---@param event BeastkeeperRareSeenEvent
function M:OnRareSeen(_, event)
    self:SetTameTarget(event.name)
end

-- A press without a beast does nothing secure; this says how to get one.
---@param _ Button
---@param _mouse string
---@param down boolean
button:HookScript("OnClick", function(_, _mouse, down)
    if not down and not M.tameTarget then M:Print(L.BEASTMAP_TAME_NONE) end
end)

_G["BINDING_NAME_CLICK " .. Addon.Global("TameButton") .. ":LeftButton"] = L.BEASTMAP_TAME_BINDING
