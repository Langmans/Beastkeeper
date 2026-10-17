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

---Puts the lines for what fits now on the button, or takes them away while the module is off or
---the character is no hunter; after combat when in it.
function M:ApplyButton()
    Kennel:OutOfCombat("AutocastCheck:button", function()
        local _, class = UnitClass("player")
        if self:IsEnabled() and class == "HUNTER" then
            -- On the key's release, as a key binding's click comes.
            button:SetAttribute("useOnKeyDown", false)
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", M.AutocastLines((self:Wanted())))
        else
            button:SetAttribute("type", nil)
            button:SetAttribute("macrotext", nil)
        end
    end)
end

_G["BINDING_NAME_CLICK KennelAutocastButton:LeftButton"] = L.AUTOCAST_BINDING
