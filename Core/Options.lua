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

---@return AceConfig.OptionsTable
function Kennel:GetOptionsTable()
    local switches = {
        intro = { type = "description", name = L.MODULES_DESC, order = 0 },
    }
    local options = {
        type = "group",
        name = addonName,
        args = {
            modules = { type = "group", name = L.MODULES, order = 1, args = switches },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
        },
    }
    options.args.profiles.order = 100

    for name, module in pairs(self.modules) do
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
    return options
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
    for name in pairs(self.modules) do
        if args[name] then dialog:AddToBlizOptions(addonName, args[name].name, addonName, name) end
    end
    dialog:AddToBlizOptions(addonName, args.profiles.name, addonName, "profiles")
end

---Opens the settings window on Kennel's page.
function Kennel:OpenOptions()
    Settings.OpenToCategory(self.optionsCategoryID)
end
