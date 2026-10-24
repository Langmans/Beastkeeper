local addonName, ns = ...

-- The options, in the game's own AddOns settings tab: a "Kennel" page with a switch per module,
-- under it a page per module that has options (GetOptions), and Profiles.
--
-- The whole table is built by GetOptionsTable every time AceConfig asks for it, so a switch
-- flipped elsewhere (a profile change, say) is what the next page shows. A module's own page
-- stays reachable while the module is off, but greyed out.

---@type Kennel
local Kennel = ns
local L = Kennel.L

-- The entries of AceDBOptions' own Profiles page. AceDBOptions hands every addon the same args
-- table, and other addons write into it (RestedXP Guides adds "Reload guides and UI", "Reset Guide
-- Progress" and "Set current profile as default"), so taking it as it is would put their buttons
-- on Kennel's page. Kennel copies only these; tests/options_spec.lua checks the list still
-- matches the AceDBOptions version in Libs/.
Kennel.PROFILE_OPTIONS = {
    "desc",
    "descreset",
    "reset",
    "current",
    "choosedesc",
    "new",
    "choose",
    "copydesc",
    "copyfrom",
    "deldesc",
    "delete",
}

---The Profiles page: AceDBOptions' group for KennelDB with a copy of only its own entries.
---@return AceConfig.OptionsTable
function Kennel:GetProfileOptions()
    local shared = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    -- GetOptionsTable always sets args.
    local sharedArgs = shared.args --[[@as table<string, AceConfig.OptionsTable>]]
    ---@type table<string, AceConfig.OptionsTable>
    local args = {}
    for _, key in ipairs(self.PROFILE_OPTIONS) do
        args[key] = sharedArgs[key]
    end
    return {
        type = "group",
        name = shared.name,
        desc = shared.desc,
        handler = shared.handler,
        order = 100,
        args = args,
    }
end

---A getter and setter for one of a module's settings (module:Settings()[key]), for an option on
---its page. `changed`, when given, runs after a set while the module is on, for settings that
---change what the module shows now.
---@param module KennelSettingsModule
---@param key string
---@param changed fun(module: KennelSettingsModule)?
---@return fun(): string|boolean|number get
---@return fun(info: table, value: string|boolean|number) set
function Kennel:Setting(module, key, changed)
    ---@type table<string, string|boolean|number>
    local settings = module:Settings()
    ---@return string|boolean|number
    local function get()
        return settings[key]
    end
    ---@param _ table AceConfig's info about the option
    ---@param value string|boolean|number
    local function set(_, value)
        settings[key] = value
        if changed and module:IsEnabled() then changed(module) end
    end
    return get, set
end

-- What a per-kind skin choice stores for "the same as every toast". It is kept as it is, not as
-- no entry, so it can override the look a module gives that kind (KennelModule.toastSkins); being
-- no skin, ToastSkinFor passes it on to the choice for every toast.
local SAME = "same"

---The skin choices: a select for every toast, one per kind of toast the modules show (from order
---10), and the options of skins that have their own (GetOptions, from order 50, by skin id).
---@param settings KennelToastSettings
---@param args table<string, table> the toast box's options, added to
function Kennel:AddSkinOptions(settings, args)
    ---@type table<string, string>
    local names = {}
    for id, skin in pairs(self:ToastSkins()) do
        names[id] = skin.name
        if skin.GetOptions then
            args[id] = skin:GetOptions()
            args[id].order = 50
        end
    end
    args.skin = {
        type = "select",
        name = L.TOAST_SKIN,
        desc = L.TOAST_SKIN_DESC,
        order = 0.5,
        values = names,
        get = function()
            return self:ToastSkinFor(nil)
        end,
        ---@param _ table AceConfig's info about the option
        ---@param value string
        set = function(_, value)
            settings.skin = value
        end,
    }

    ---@type table<string, string>
    local perKind = { [SAME] = L.TOAST_SKIN_SAME }
    for id, name in pairs(names) do
        perKind[id] = name
    end
    local order = 10
    local kinds = self:ToastTypes()
    ---@type string[]
    local sorted = {}
    for kind in pairs(kinds) do
        sorted[#sorted + 1] = kind
    end
    table.sort(sorted)
    for _, kind in ipairs(sorted) do
        args["skin:" .. kind] = {
            type = "select",
            name = kinds[kind],
            order = order,
            values = perKind,
            get = function()
                return settings.skins[kind] or SAME
            end,
            ---@param _ table AceConfig's info about the option
            ---@param value string
            set = function(_, value)
                settings.skins[kind] = value
            end,
        }
        order = order + 1
    end
end

---The toast's settings, shared by every module, as a box on Kennel's page below the switches.
---@return AceConfig.OptionsTable
function Kennel:GetToastOptions()
    local settings = self:ToastSettings()
    local options = {
        type = "group",
        inline = true,
        name = L.TOAST,
        order = 100,
        args = {
            desc = { type = "description", name = L.TOAST_DESC, order = 0 },
            duration = {
                type = "range",
                name = L.TOAST_DURATION,
                order = 1,
                min = 1,
                max = 30,
                step = 1,
                get = function()
                    return settings.duration
                end,
                ---@param _ table AceConfig's info about the option
                ---@param value number
                set = function(_, value)
                    settings.duration = value
                end,
            },
            scale = {
                type = "range",
                name = L.TOAST_SCALE,
                order = 2,
                min = 0.5,
                max = 2,
                step = 0.05,
                isPercent = true,
                get = function()
                    return settings.scale
                end,
                ---@param _ table AceConfig's info about the option
                ---@param value number
                set = function(_, value)
                    settings.scale = value
                end,
            },
            reset = {
                type = "execute",
                name = L.TOAST_RESET,
                order = 3,
                func = function()
                    self:ResetToastPosition()
                end,
            },
            test = {
                type = "execute",
                name = L.TOAST_TEST,
                order = 4,
                func = function()
                    self:ShowToast({
                        key = "Kennel:test",
                        source = addonName,
                        title = L.TOAST_TEST_TITLE,
                        text = L.TOAST_TEST_TEXT,
                        -- The icon of Kennel's entry in the addon list.
                        icon = "Interface\\Icons\\Ability_Hunter_BeastCall",
                    })
                end,
            },
        },
    }
    self:AddSkinOptions(settings, options.args)
    return options
end

---A select between "auto" and the registered skins of one kind, stored under `key`.
---@param key "skin"|"holder"
---@param name string
---@param register table<string, KennelButtonSkin|KennelButtonHolderSkin>
---@param order number
---@return table
local function ButtonSkinSelect(key, name, register, order)
    return {
        type = "select",
        name = name,
        order = order,
        values = function()
            ---@type table<string, string>
            local names = { auto = L.BUTTONS_AUTO }
            for id, skin in pairs(register) do
                names[id] = skin.name
            end
            return names
        end,
        get = function()
            return Kennel:ButtonSettings()[key]
        end,
        ---@param _ table AceConfig's info about the option
        ---@param value string
        set = function(_, value)
            Kennel:ButtonSettings()[key] = value
        end,
    }
end

---The look of Kennel's buttons, as a box on Kennel's page below the toast's.
---@return AceConfig.OptionsTable
function Kennel:GetButtonOptions()
    return {
        type = "group",
        inline = true,
        name = L.BUTTONS,
        order = 110,
        args = {
            desc = { type = "description", name = L.BUTTONS_DESC, order = 0 },
            skin = ButtonSkinSelect("skin", L.BUTTONS_SKIN, self:ButtonSkins(), 1),
            holder = ButtonSkinSelect("holder", L.BUTTONS_HOLDER, self:ButtonHolderSkins(), 2),
        },
    }
end

---@return AceConfig.OptionsTable
function Kennel:GetOptionsTable()
    local switches = {
        intro = { type = "description", name = L.MODULES_DESC, order = 0 },
        toast = self:GetToastOptions(),
        buttons = self:GetButtonOptions(),
        debug = self:GetDebugOptions(),
    }
    local options = {
        type = "group",
        name = addonName,
        args = {
            modules = { type = "group", name = L.MODULES, order = 1, args = switches },
            profiles = self:GetProfileOptions(),
        },
    }

    for name, module in pairs(self.modules) do
        if self:IsModuleUsable(name) then self:AddModuleOptions(options, switches, name, module) end
    end
    return options
end

---A module's switch on Kennel's page and, when it has options, its own page.
---@param options table
---@param switches table
---@param name string
---@param module KennelModule
function Kennel:AddModuleOptions(options, switches, name, module)
    switches[name] = {
        type = "toggle",
        name = module.title or name,
        desc = module.description,
        width = "full",
        get = function()
            return self:IsModuleOn(name)
        end,
        ---@param _ table AceConfig's info about the option
        ---@param on boolean
        set = function(_, on)
            self:SetModuleOn(name, on)
        end,
    }
    if module.GetOptions then
        local group = module:GetOptions()
        group.type = "group"
        group.name = group.name or module.title or name
        group.disabled = function()
            return not self:IsModuleOn(name)
        end
        options.args[name] = group
    end
end

---Registers the options with AceConfig and adds the pages to the settings window.
function Kennel:SetupOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, function()
        return self:GetOptionsTable()
    end)
    local dialog = LibStub("AceConfigDialog-3.0")
    -- AddToBlizOptions returns the page's frame and the ID Settings.OpenToCategory takes.
    ---@type table, string|number
    local _, categoryID = dialog:AddToBlizOptions(addonName, addonName, nil, "modules")
    self.optionsCategoryID = categoryID
    -- Each page is named as its group is, so a module's own name and AceDBOptions' translated
    -- "Profiles" carry over. Every group here has a string name.
    local args = self:GetOptionsTable().args --[[@as table<string, {name: string}>]]
    ---@type table<string, string|number>
    self.moduleCategoryIDs = {}
    for name in pairs(self.modules) do
        if args[name] then
            ---@type table, string|number
            local _, id = dialog:AddToBlizOptions(addonName, args[name].name, addonName, name)
            self.moduleCategoryIDs[name] = id
        end
    end
    dialog:AddToBlizOptions(addonName, args.profiles.name, addonName, "profiles")
end

---Opens the settings window on Kennel's page, or on a module's.
---@param module string? the module's name
function Kennel:OpenOptions(module)
    Settings.OpenToCategory(module and self.moduleCategoryIDs[module] or self.optionsCategoryID)
end
