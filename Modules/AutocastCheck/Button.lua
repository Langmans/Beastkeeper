local _, ns = ...

-- The key that sets Growl and Cower as fits. Only a macro or a secure button the player presses may
-- change autocast, so this is a secure button whose macro text always holds the two lines for what
-- fits now; the module rewrites them outside combat (a secure button cannot change in it). The
-- BeastkeeperAutocast macro, for an action bar, holds the same two lines itself: a /click from a
-- macro runs no macro text (a macro inside a macro), so it is kept in step the same way. Only its
-- /petautocaston and /petautocastoff lines (or an old /click of this button) are rewritten; the
-- player's own lines stay, and a macro with none of ours is left alone.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("AutocastCheck") --[[@as AddonAutocastCheck]]

local MACRO = Addon.Global("Autocast")
local CLICK = "/click " .. Addon.Global("AutocastButton")

local button = CreateFrame("Button", Addon.Global("AutocastButton"), UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown")
-- The ability the button's lines put on autocast, nil while it has none; and whether they put the
-- other one on too (Cower while learning it).
---@type ("growl"|"cower")?, boolean
local on, both = nil, false

-- The macro's lines while UpdatedBody works on them; kept, not built anew for each change.
---@type string[]
local lines = {}

---Whether a macro line is one the module writes.
---@param line string
---@return boolean
local function Ours(line)
    local lower = line:lower()
    return lower:find("^/petautocaston ") ~= nil or lower:find("^/petautocastoff ") ~= nil or line == CLICK
end

---The macro text with `autocast` (the lines for what fits) where the first of ours stood; nil for
---a macro without a line of ours (left alone).
---@param body string
---@param autocast string
---@return string?
local function UpdatedBody(body, autocast)
    wipe(lines)
    local placed = false
    for line in (body .. "\n"):gmatch("(.-)\n") do
        if not Ours(line) then
            lines[#lines + 1] = line
        elseif not placed then
            lines[#lines + 1], placed = autocast, true
        end
    end
    return placed and table.concat(lines, "\n") or nil
end

---Puts the macro's autocast lines in step with the button.
---@param autocast string
local function UpdateMacro(autocast)
    local index = GetMacroIndexByName(MACRO)
    if index == 0 then return end
    local _, _, current = GetMacroInfo(index)
    local body = UpdatedBody(current, autocast)
    if body and body ~= current then EditMacro(index, nil, nil, body) end
end

---Puts the lines for what fits now on the button and in the macro, or takes them off the button
---while the module is off or the character is no hunter; after combat when in it.
function M:ApplyButton()
    Addon:OutOfCombat("AutocastCheck:button", function()
        local _, class = UnitClass("player")
        if self:IsEnabled() and class == "HUNTER" then
            on, both = (self:Wanted()), self:LearningCower()
            local autocast = self:WantedLines()
            -- On the key's release, as a key binding's click comes.
            button:SetAttribute("useOnKeyDown", false)
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", autocast)
            UpdateMacro(autocast)
        else
            on, both = nil, false
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
    local other = on == "growl" and "cower" or "growl"
    M:Print((both and L.AUTOCAST_SET_BOTH or L.AUTOCAST_SET):format(M.Spell(M.SPELLS[on]), M.Spell(M.SPELLS[other])))
end)

_G["BINDING_NAME_CLICK " .. Addon.Global("AutocastButton") .. ":LeftButton"] = L.AUTOCAST_BINDING
