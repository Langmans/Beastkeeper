local _, ns = ...

-- The secure button behind the key binding. An addon cannot cast, and in combat cannot change a
-- button either, so the choice between Mend Pet, Revive Pet and Call Pet is made in the secure
-- environment: a state driver watches `[@pet,dead] dead; [@pet,exists] alive; none` and sets
-- the header's `petdead` on "dead", clears it on "alive", and keeps it on "none" (the body gone,
-- where a plain macro would pick Call Pet). The `apply` snippet then gives the button one of two
-- macro texts. Shift still forces Revive Pet and Ctrl Call Pet, for when `petdead` is wrong.
--
-- Outside combat the module sets `petdead` itself (SetPetDead): from the saved value, from failed
-- casts, and from the settings page. It is mirrored into the character's saved settings. While the
-- module is off the button has no macro and the state driver is gone.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("CareButton") --[[@as KennelCareButton]]

M.PET_STATES = "[@pet,dead] dead; [@pet,exists] alive; none"

-- The snippets, run in the restricted environment: `self` is the header, `newstate` the state.
-- APPLY gives the button the macro text for `petdead`; ON_STATE keeps `petdead` up to date.
local APPLY = [[
    local text = self:GetAttribute(self:GetAttribute("petdead") and "textDead" or "textAlive")
    self:GetFrameRef("button"):SetAttribute("macrotext", text)
]]
local ON_STATE = [[
    if newstate == "dead" then
        self:SetAttribute("petdead", true)
    elseif newstate == "alive" then
        self:SetAttribute("petdead", false)
    end
    self:RunAttribute("apply")
]]
local RUN_APPLY = [[ self:RunAttribute("apply") ]]

local button = CreateFrame("Button", "KennelCareButton", UIParent, "SecureActionButtonTemplate")
local header = CreateFrame("Frame", "KennelCareButtonHeader", UIParent, "SecureHandlerStateTemplate")
-- For its look on screen (OnScreen.lua).
M.button = button

-- The macro's parts, refilled for each text.
---@type string[]
local clauses = {}

---A spell's name when the hunter knows it, else nil: a low hunter learns Call Pet at 10, Revive Pet
---with the quest Training the Beast, Mend Pet at 12.
---@param spellID number
---@return string?
local function Known(spellID)
    return Kennel.KnowsSpell(spellID) and M.SpellName(spellID) or nil
end

---The macro the button runs, with only the spells the hunter knows. Without a remembered death:
---Revive Pet on a dead pet still there, Call Pet without a pet, Mend Pet otherwise. With one:
---Revive Pet whenever there is no living pet.
---@param petDead boolean
---@return string
function M:MacroText(petDead)
    local mend, revive, call = Known(M.MEND_PET), Known(M.REVIVE_PET), Known(M.CALL_PET)
    wipe(clauses)
    if petDead then
        clauses[#clauses + 1] = call and "[mod:ctrl] " .. call
        clauses[#clauses + 1] = revive and "[mod:shift][@pet,dead][nopet] " .. revive
    else
        clauses[#clauses + 1] = revive and "[mod:shift][@pet,dead] " .. revive
        clauses[#clauses + 1] = call and "[mod:ctrl][nopet] " .. call
    end
    clauses[#clauses + 1] = mend
    return "/use " .. table.concat(clauses, "; ")
end

---Whether a macro line is one the button could have written: /use of the care spells alone, under
---their conditions (any of them, as the hunter knew them then).
---@param line string
---@return boolean
function M:IsCareLine(line)
    local spells = line:match("^/use (.*)$")
    if not spells then return false end
    for clause in (spells .. ";"):gmatch("([^;]*);") do
        local name = clause:gsub("%b[]", ""):match("^%s*(.-)%s*$")
        if
            name ~= M.SpellName(M.MEND_PET)
            and name ~= M.SpellName(M.REVIVE_PET)
            and name ~= M.SpellName(M.CALL_PET)
        then
            return false
        end
    end
    return true
end

---The spellbook changed: the button's macro texts again, and the macro's line.
function M:ApplyMacroTexts()
    Kennel:OutOfCombat("CareButton:texts", function()
        header:SetAttribute("textAlive", M:MacroText(false))
        header:SetAttribute("textDead", M:MacroText(true))
        SecureHandlerExecute(header, RUN_APPLY)
        M:UpdateMacro()
    end)
end

---Whether the button counts the pet as dead.
---@return boolean
function M:PetDead()
    return header:GetAttribute("petdead") == true
end

---@param _ Frame the header
---@param name string
---@param value GameValue
local function OnHeaderAttribute(_, name, value)
    if name == "petdead" then
        M.db.char.petDead = value == true
        M:UpdateMacro()
        M:UpdateLook()
    elseif name == "state-pet" and type(value) == "string" then
        M:OnPetState(value)
    end
end
header:HookScript("OnAttributeChanged", OnHeaderAttribute)

---Gives the button its snippets, macro texts and state driver.
local function Setup()
    button:RegisterForClicks("AnyUp", "AnyDown")
    SecureHandlerSetFrameRef(header, "button", button)
    header:SetAttribute("apply", APPLY)
    header:SetAttribute("_onstate-pet", ON_STATE)
    button:SetAttribute("type", "macro")
    button:SetAttribute("useOnKeyDown", false)
    header:SetAttribute("textAlive", M:MacroText(false))
    header:SetAttribute("textDead", M:MacroText(true))
    header:SetAttribute("petdead", M.db.char.petDead == true)
    SecureHandlerExecute(header, RUN_APPLY)
    RegisterStateDriver(header, "pet", M.PET_STATES)
end

---Takes the button's macro and the state driver away.
local function Teardown()
    UnregisterStateDriver(header, "pet")
    button:SetAttribute("type", nil)
end

---Sets the button up while the module is on for a hunter, takes it down otherwise; now, or once
---combat ends.
function M:ApplyButton()
    Kennel:OutOfCombat("CareButton:button", function()
        local _, class = UnitClass("player")
        if self:IsEnabled() and class == "HUNTER" then
            Setup()
        else
            Teardown()
        end
        self:ShowOnScreen()
    end)
end

---Tells the button whether the pet is dead. Outside combat only: returns false in combat.
---@param dead boolean
---@return boolean
function M:SetPetDead(dead)
    if InCombatLockdown() then return false end
    header:SetAttribute("petdead", dead)
    SecureHandlerExecute(header, RUN_APPLY)
    return true
end

-- The key binding's name in Esc > Options > Keybindings (Bindings.xml).
_G["BINDING_NAME_CLICK KennelCareButton:LeftButton"] = L.CAREBUTTON_BINDING
