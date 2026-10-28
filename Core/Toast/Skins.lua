local _, ns = ...

-- The skin register: the contract a skin keeps (BeastkeeperToastSkin) and which skin draws which kind
-- of toast. A look is chosen for every toast and, per kind, the same or its own; a skin that is
-- not registered (its addon gone) falls back to the card. Frame.lua and Engine.lua are the rest
-- of the toast; docs\05-toast-skins.md shows how they fit.

---@type Addon
local Addon = ns

-- The skin a toast falls back to.
Addon.TOAST_DEFAULT_SKIN = "card"
-- What a skin draws when the toast brings none: a warm amber accent, a question mark icon.
Addon.TOAST_ACCENT = { 1, 0.62, 0.18 }
Addon.TOAST_ICON = 134400 -- INV_Misc_QuestionMark

---Beastkeeper's own accent, as a style's accent function.
---@return number[]
function Addon.DefaultToastAccent()
    return Addon.TOAST_ACCENT
end

-- What a skin must have (BeastkeeperToastSkin): RegisterToastSkin refuses one without. An instant
-- skin hands the toast on and is done, so it needs only Show.
local SKIN_METHODS = { "Show", "Update", "Hide", "IsMouseOver" }
local INSTANT_METHODS = { "Show" }

---@type table<string, BeastkeeperToastSkin>
local skins = {}

---The toast's settings in the profile in use.
---@return BeastkeeperToastSettings
function Addon:ToastSettings()
    return self.db.profile.toast --[[@as BeastkeeperToastSettings]]
end

---Makes a skin available. Another addon calls this on Beastkeeper's addon object
---(LibStub("AceAddon-3.0"):GetAddon("Beastkeeper", true)), at any time after Beastkeeper has loaded.
---Raises an error naming what is missing when the skin does not keep the contract.
---@param id string kept in the saved settings; a short lowercase word
---@param skin BeastkeeperToastSkin
function Addon:RegisterToastSkin(id, skin)
    if type(id) ~= "string" or id == "" then
        error("Beastkeeper:RegisterToastSkin: id must be a non-empty string", 2)
    end
    if type(skin) ~= "table" then error("Beastkeeper:RegisterToastSkin(" .. id .. "): skin must be a table", 2) end
    ---@type string[]
    local missing = {}
    if type(skin.name) ~= "string" then missing[#missing + 1] = "name (a string)" end
    for _, method in ipairs(skin.instant and INSTANT_METHODS or SKIN_METHODS) do
        if type(skin[method]) ~= "function" then missing[#missing + 1] = method end
    end
    if #missing > 0 then
        error("Beastkeeper:RegisterToastSkin(" .. id .. "): the skin has no " .. table.concat(missing, ", "), 2)
    end
    skins[id] = skin
end

---The registered skins, by id.
---@return table<string, BeastkeeperToastSkin>
function Addon:ToastSkins()
    return skins
end

---The id of the skin that draws toasts of `kind`: its own choice, else the one for every toast,
---else the card, whichever of those is registered first.
---@param kind string? "<Module>:<type>"
---@return string
function Addon:ToastSkinFor(kind)
    local settings = self:ToastSettings()
    local chosen = kind and settings.skins[kind]
    if chosen and skins[chosen] then return chosen end
    if skins[settings.skin] then return settings.skin end
    return self.TOAST_DEFAULT_SKIN
end

---The kinds of toast the modules show, as "<Module>:<type>" with their names, for the skin
---choice; from each module's toastTypes.
---@return table<string, string>
function Addon:ToastTypes()
    ---@type table<string, string>
    local kinds = {}
    for name, module in pairs(self.modules) do
        for kind, label in pairs(module.toastTypes or {}) do
            kinds[name .. ":" .. kind] = (module.title or name) .. ": " .. label
        end
    end
    return kinds
end
