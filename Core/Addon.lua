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

local consolePrint = Kennel.Print

---AceConsole's Print, then KENNEL_PRINT ({ module, line }) for whoever listens (docs\04-hooking.md).
---@param module string? the module that says it; nil for the core
---@param ... any
local function PrintFrom(module, ...)
    consolePrint(Kennel, ...)
    Kennel:SendMessage("KENNEL_PRINT", { module = module, line = strjoin(" ", tostringall(...)) })
end

---A line in chat from the core.
---@param ... any
function Kennel:Print(...)
    PrintFrom(nil, ...)
end

-- What every module has: Print, naming the module in KENNEL_PRINT.
Kennel:SetDefaultModulePrototype({
    ---A line in chat from this module.
    ---@param self KennelModule
    ---@param ... any
    Print = function(self, ...)
        PrintFrom(self:GetName(), ...)
    end,
})

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
            -- The look of Kennel's buttons and their holders (Core\Buttons.lua): a skin id or "auto".
            buttons = { skin = "auto", holder = "auto" },
            -- Kennel's window (Core\Window.lua): pos is set once it is dragged.
            window = {},
            -- How much goes to OAP Debug when it is installed (Core\Debug.lua).
            oapDebug = "metrics",
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
    self:ApplyDebugLevel()
end

-- A frame that tries an event on a client without C_EventUtils.
local probe = CreateFrame("Frame")

---Whether this client has an event. Registering one it lacks errors, and AceEvent has noted it by
---then, so unregistering it later (a module switched off, a profile change) errors as well.
---@param event string
---@return boolean
local function HasEvent(event)
    local utils = C_EventUtils
    if utils and utils.IsEventValid then return utils.IsEventValid(event) == true end
    local ok = pcall(probe.RegisterEvent, probe, event)
    if ok then probe:UnregisterEvent(event) end
    return ok
end

---Registers each of `events` this client has for `owner` (a module, or any table AceEvent takes),
---with `handler` (a method name or function; the event's name when nil).
---@param owner table
---@param events string[]
---@param handler (string|function)?
function Kennel.RegisterEvents(owner, events, handler)
    for _, event in ipairs(events) do
        -- AceEvent takes a method name too, and nil for the event's own name.
        if HasEvent(event) then
            Kennel.RegisterEvent(owner, event, handler --[[@as fun(event: FrameEvent, ...)]])
        end
    end
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
    self:Log("info", on and "module {1} on" or "module {1} off", name)
    local module = self.modules[name]
    if on then
        module:Enable()
    else
        module:Disable()
    end
end

---After a profile change: stops every module, then starts the ones the new profile has on; the
---new profile's OAP Debug level.
function Kennel:ApplyModuleStates()
    for _, module in pairs(self.modules) do
        module:Disable()
    end
    for name, module in pairs(self.modules) do
        if self:IsModuleOn(name) then module:Enable() end
    end
    self:ApplyDebugLevel()
end
