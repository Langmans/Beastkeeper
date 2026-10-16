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

---@type Kennel
local Kennel = ns
local L = Kennel.L

local MACRO_CONSTS = Constants and Constants.MacroConsts
local MAX_ACCOUNT_MACROS = MACRO_CONSTS and MACRO_CONSTS.MAX_ACCOUNT_MACROS or 120
local MAX_CHARACTER_MACROS = MACRO_CONSTS and MACRO_CONSTS.MAX_CHARACTER_MACROS or 18

---Makes the macros that are not there yet, and says in chat what it made and what found no room;
---by hand it also says when all were there already. Counts as made for this character.
---@param module KennelMacroModule
---@param byHand boolean? from the module's options
---@return boolean ran false in combat, when no macro can be made
function Kennel:CreateMacros(module, byHand)
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
---@type table<string, KennelMacroModule>
local offered = {}
-- Whether the client has loaded the macros (the first UPDATE_MACROS); before that, GetNumMacros
-- and GetMacroIndexByName do not know the player's macros yet.
local macrosLoaded = false

---Makes the waiting modules' macros, now or once combat ends.
function Kennel:MakeOfferedMacros()
    self:OutOfCombat("macros", function()
        for name, module in pairs(offered) do
            offered[name] = nil
            self:CreateMacros(module)
        end
    end)
end

function Kennel:UPDATE_MACROS()
    self:UnregisterEvent("UPDATE_MACROS")
    macrosLoaded = true
    self:MakeOfferedMacros()
end

---Listens for the macros to load; from OnInitialize.
function Kennel:SetupMacros()
    self:RegisterEvent("UPDATE_MACROS")
end

---Makes a module's macros the first time for this character: now when the macros have loaded
---(a module switched on later), else once they have.
---@param module KennelMacroModule
function Kennel:OfferMacros(module)
    if self.db.char.macrosMade[module.moduleName] then return end
    offered[module.moduleName] = module
    if macrosLoaded then self:MakeOfferedMacros() end
end
