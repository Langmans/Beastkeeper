local _, ns = ...

-- The BeastkeeperCare macro: `#showtooltip` and the button's own `/use` line, so it casts what the
-- button casts without going through it. Beastkeeper makes it once per character (Core\Macro.lua). Its
-- cast line follows the button: macro conditions cannot see a dead pet whose body is gone, so the
-- line is rewritten whenever `petdead` changes, and when the macros change. Only a macro whose
-- first line is #showtooltip is touched, and in it only the cast line; the player's own lines
-- stay. Macros cannot be edited in combat: the edit waits for its end.

---@type Addon
local Addon = ns
local M = Addon:GetModule("CareButton") --[[@as AddonCareButton]]

local NAME = Addon.Global("Care")
local TOOLTIP = "#showtooltip"
local QUESTION_MARK = 134400 -- the icon a macro gets when #showtooltip picks the spell's own

---@return AddonMacro[]
function M:Macros()
    local body = TOOLTIP .. "\n" .. self:MacroText(self:PetDead())
    return { { name = NAME, icon = QUESTION_MARK, body = body, desc = Addon.L.CAREBUTTON_MACRO } }
end

-- The macro's lines while UpdatedBody works on them; kept, since it runs on every macro change and
-- every death and revive.
---@type string[]
local lines = {}

---The macro text with its cast line put in step with the button, or nil when its first line is no
---#showtooltip (left alone).
---@param body string
---@param petDead boolean
---@return string?
function M:UpdatedBody(body, petDead)
    wipe(lines)
    for line in (body .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end
    if not lines[1]:lower():find("^#showtooltip") then return nil end
    lines[1] = TOOLTIP
    for i = 2, #lines do
        -- The same line with /cast does the same, so it counts as its own too.
        local line = lines[i]:gsub("^/cast ", "/use ")
        if self:IsCareLine(line) then lines[i] = self:MacroText(petDead) end
    end
    return table.concat(lines, "\n")
end

---Rewrites the macro's cast line when it no longer matches the button; after combat when in it.
function M:UpdateMacro()
    Addon:OutOfCombat("CareButton:macro", function()
        local index = GetMacroIndexByName(NAME)
        if index == 0 then return end
        local _, _, current = GetMacroInfo(index)
        local body = self:UpdatedBody(current, self:PetDead())
        if body and body ~= current then EditMacro(index, nil, nil, body) end
    end)
end
