local _, ns = ...

-- The key that sets Growl and Cower as fits. Only a macro or a secure button the player presses may
-- change autocast, so this is a secure button whose macro text always holds the two lines for what
-- fits now; the module rewrites them outside combat (a secure button cannot change in it). The
-- KennelAutocast macro clicks it, for an action bar.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("AutocastCheck") --[[@as KennelAutocastCheck]]

local button = CreateFrame("Button", "KennelAutocastButton", UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown")
-- The ability the button's lines put on autocast; nil while it has none.
---@type ("growl"|"cower")?
local on

---Puts the lines for what fits now on the button, or takes them away while the module is off or
---the character is no hunter; after combat when in it.
function M:ApplyButton()
    Kennel:OutOfCombat("AutocastCheck:button", function()
        local _, class = UnitClass("player")
        if self:IsEnabled() and class == "HUNTER" then
            on = (self:Wanted())
            -- On the key's release, as a key binding's click comes.
            button:SetAttribute("useOnKeyDown", false)
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", M.AutocastLines(on))
        else
            on = nil
            button:SetAttribute("type", nil)
            button:SetAttribute("macrotext", nil)
        end
    end)
end

-- The lines change autocast without a word; this says what they set. After the secure click, on
-- the release only: that is when the lines run.
---@param _ Button
---@param _mouse string
---@param down boolean
button:HookScript("OnClick", function(_, _mouse, down)
    if down or not on then return end
    local off = on == "growl" and "cower" or "growl"
    M:Print(L.AUTOCAST_SET:format(M.Spell(M.SPELLS[on]), M.Spell(M.SPELLS[off])))
end)

_G["BINDING_NAME_CLICK KennelAutocastButton:LeftButton"] = L.AUTOCAST_BINDING
