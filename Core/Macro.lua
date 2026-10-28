local _, ns = ...

-- Macros a module makes for the player: per character, since an action bar is per character too;
-- only when the character macros are full does one go among the account-wide ones. A macro of the
-- same name that is there already is left as it is.
--
-- A module offers its macros once per character (OfferMacros, from its OnEnable): the first time
-- the macros are loaded (UPDATE_MACROS) outside combat, the missing ones are made, and
-- db.char.macrosMade[module] remembers it, so a macro the player deletes afterwards is not made
-- again. The module's options have a button for making them by hand (CreateMacros). In combat no
-- macro can be made, so the first time waits for the end of combat.

---@type Addon
local Addon = ns
local L = Addon.L

local MACRO_CONSTS = Constants and Constants.MacroConsts
local MAX_ACCOUNT_MACROS = MACRO_CONSTS and MACRO_CONSTS.MAX_ACCOUNT_MACROS or 120
local MAX_CHARACTER_MACROS = MACRO_CONSTS and MACRO_CONSTS.MAX_CHARACTER_MACROS or 18

---Makes the macros that are not there yet, and says in chat what it made and what found no room;
---by hand it also says when all were there already. Counts as made for this character.
---@param module BeastkeeperMacroModule
---@param byHand boolean? from the module's options
---@return boolean ran false in combat, when no macro can be made
function Addon:CreateMacros(module, byHand)
    if InCombatLockdown() then
        if byHand then self:Print(L.MACROS_COMBAT) end
        return false
    end
    ---@type string[], string[], string[]
    local character, account, full = {}, {}, {}
    for _, macro in ipairs(module:Macros()) do
        if GetMacroIndexByName(macro.name) == 0 then
            local accountMacros, characterMacros = GetNumMacros()
            local perCharacter = characterMacros < MAX_CHARACTER_MACROS
            if perCharacter or accountMacros < MAX_ACCOUNT_MACROS then
                CreateMacro(macro.name, macro.icon, macro.body, perCharacter)
                local made = perCharacter and character or account
                made[#made + 1] = macro.name
            else
                full[#full + 1] = macro.name
            end
        end
    end
    self.db.char.macrosMade[module.moduleName] = true
    if #character > 0 then self:Print(L.MACROS_MADE:format(table.concat(character, ", "))) end
    if #account > 0 then self:Print(L.MACROS_MADE_ACCOUNT:format(table.concat(account, ", "))) end
    if #full > 0 then self:Print(L.MACROS_FULL:format(table.concat(full, ", "))) end
    if byHand and #character + #account + #full == 0 then self:Print(L.MACROS_THERE) end
    return true
end

-- Modules whose macros wait to be made the one time, by name.
---@type table<string, BeastkeeperMacroModule>
local offered = {}
-- Whether the client has loaded the macros (the first UPDATE_MACROS); before that, GetNumMacros
-- and GetMacroIndexByName do not know the player's macros yet.
local macrosLoaded = false

-- Whether SPELLS_CHANGED is watched, for a hunter who does not know Call Pet yet.
local waitingForPet = false

---Makes the waiting modules' macros, now or once combat ends; every macro of Beastkeeper's is for a pet,
---so a hunter without Call Pet gets them once it learns it.
function Addon:MakeOfferedMacros()
    if not self.KnowsSpell(self.CALL_PET) then
        if not waitingForPet then self:RegisterEvent("SPELLS_CHANGED", "MakeOfferedMacros") end
        waitingForPet = true
        return
    end
    if waitingForPet then self:UnregisterEvent("SPELLS_CHANGED") end
    waitingForPet = false
    self:OutOfCombat("macros", function()
        for name, module in pairs(offered) do
            offered[name] = nil
            self:CreateMacros(module)
        end
    end)
end

function Addon:UPDATE_MACROS()
    self:UnregisterEvent("UPDATE_MACROS")
    macrosLoaded = true
    self:MakeOfferedMacros()
end

---Listens for the macros to load; from OnInitialize.
function Addon:SetupMacros()
    self:RegisterEvent("UPDATE_MACROS")
end

---Makes a module's macros the first time for this character: now when the macros have loaded
---(a module switched on later), else once they have.
---@param module BeastkeeperMacroModule
function Addon:OfferMacros(module)
    if self.db.char.macrosMade[module.moduleName] then return end
    offered[module.moduleName] = module
    if macrosLoaded then self:MakeOfferedMacros() end
end

-- What Beastkeeper's macros do, in the tooltip of an action button that holds one: the game only shows a
-- macro's #showtooltip spell there. Only for modules that are on.
local DESC_COLOR = { 0.5, 0.9, 0.5 }

-- Each macro's description and the module making it, by macro name; read once from the modules'
-- Macros() on the first hover, since a tooltip hook runs on every hover.
---@type table<string, string>?, table<string, BeastkeeperMacroModule>
local descriptions, makers = nil, {}

---The description of the macro called `name`, when a module that is on makes it.
---@param name string
---@return string?
function Addon:MacroDescription(name)
    if not descriptions then
        descriptions = {}
        for _, module in pairs(self.modules) do
            ---@cast module BeastkeeperMacroModule
            for _, macro in ipairs(module.Macros and module:Macros() or {}) do
                if macro.desc then
                    descriptions[macro.name], makers[macro.name] = macro.desc, module
                end
            end
        end
    end
    local maker = makers[name]
    return maker and maker:IsEnabled() and descriptions[name] or nil
end

---@param tooltip GameTooltip
---@param slot number
local function OnSetAction(tooltip, slot)
    local kind, id = GetActionInfo(slot)
    if kind ~= "macro" then return end
    local name = GetMacroInfo(id)
    local desc = name and Addon:MacroDescription(name)
    if not desc then return end
    tooltip:AddLine(desc, DESC_COLOR[1], DESC_COLOR[2], DESC_COLOR[3], true)
    tooltip:Show()
end
hooksecurefunc(GameTooltip, "SetAction", OnSetAction)
