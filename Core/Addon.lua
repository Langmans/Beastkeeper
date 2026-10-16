local addonName, ns = ...

-- The addon object, its saved settings and the module switches.
--
-- Every feature is an AceAddon module (Kennel:NewModule). What a module may declare is described
-- by KennelModule in annotations\Kennel.lua. The core owns the switch: profile.modules[name] says
-- whether a module runs, and the options page and a profile change both go through
-- SetModuleOn/ApplyModuleStates. A module therefore never enables itself, and its OnDisable must
-- undo everything its OnEnable did (events, hooks, frames shown), because that is also how a
-- profile change reaches it: every running module is disabled, then enabled again from the new
-- profile, so OnEnable only has to read its settings once.

---@type Kennel
local Kennel = LibStub("AceAddon-3.0"):NewAddon(ns, addonName, "AceConsole-3.0", "AceEvent-3.0")
Kennel.L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Every module can register events; anything else it embeds it lists itself.
Kennel:SetDefaultModuleLibraries("AceEvent-3.0")

function Kennel:OnInitialize()
    -- A module is on unless it says otherwise; the saved file keeps only switches that differ.
    -- The same for the look a module gives a kind of toast.
    ---@type table<string, boolean>, table<string, string>
    local switches, kindSkins = {}, {}
    for name, module in pairs(self.modules) do
        switches[name] = module.enabledByDefault ~= false
        for kind, skin in pairs(module.toastSkins or {}) do
            kindSkins[name .. ":" .. kind] = skin
        end
    end
    self.db = LibStub("AceDB-3.0"):New("KennelDB", {
        profile = {
            modules = switches,
            -- The toast every module shows (Core\Toast\): the skin for every toast, a skin per
            -- kind of toast where chosen or where its module gives one; pos is set once it is
            -- dragged. sink: LibSink's output choice (Integrations\LibSink\).
            toast = { duration = 6, scale = 1, skin = "card", skins = kindSkins, sink = {} },
        },
        -- Per character: which modules made their macros already (Core\Macro.lua).
        char = { macrosMade = {} },
    }, true)

    for name, module in pairs(self.modules) do
        if module.defaults then module.db = self.db:RegisterNamespace(name, module.defaults) end
        module:SetEnabledState(self:IsModuleOn(name))
    end

    self.db.RegisterCallback(self, "OnProfileChanged", "ApplyModuleStates")
    self.db.RegisterCallback(self, "OnProfileCopied", "ApplyModuleStates")
    self.db.RegisterCallback(self, "OnProfileReset", "ApplyModuleStates")

    self:SetupOptions()
    self:SetupCommands()
    self:SetupMacros()
end

---Whether the current profile has this module switched on.
---@param name string
---@return boolean
function Kennel:IsModuleOn(name)
    return self.db.profile.modules[name] == true
end

---Switches a module on or off in the current profile and starts or stops it now.
---@param name string
---@param on boolean
function Kennel:SetModuleOn(name, on)
    self.db.profile.modules[name] = on
    local module = self.modules[name]
    if on then
        module:Enable()
    else
        module:Disable()
    end
end

---After a profile change: stops every module, then starts the ones the new profile has on.
function Kennel:ApplyModuleStates()
    for _, module in pairs(self.modules) do
        module:Disable()
    end
    for name, module in pairs(self.modules) do
        if self:IsModuleOn(name) then module:Enable() end
    end
end
