local _, ns = ...

-- Button skins: the look of Beastkeeper's buttons and of what holds them, registered like toast skins
-- (Core\Toast\Skins.lua). A button skin styles one button (AddonButtonSkin) and gives back how
-- to colour its border; a holder skin styles a panel of buttons and the text and icons in its
-- rows (AddonButtonHolderSkin). Beastkeeper brings its own of both; integrations add another UI's
-- (Integrations\). The choice on Beastkeeper's page is a skin, or "auto": the registered one with the
-- highest priority. A module styles a button once, the first time it shows it, so a new choice
-- shows after /reload. A skin that errors is reported and Beastkeeper's own takes over.

---@type Addon
local Addon = ns

Addon.BUTTON_DEFAULT_SKIN = Addon.NAME:lower()
local AUTO = "auto"

---@type table<string, AddonButtonSkin>, table<string, AddonButtonHolderSkin>
local buttonSkins, holderSkins = {}, {}

---Checks a skin against its contract and keeps it; raises an error naming what is missing.
---@param method string the caller's name, for the error
---@param register table the skins of that kind
---@param id string
---@param skin table
---@param functions string[] what the skin must have
local function Register(method, register, id, skin, functions)
    if type(id) ~= "string" or id == "" then error("Beastkeeper:" .. method .. ": id must be a non-empty string", 3) end
    ---@type string[]
    local missing = {}
    if type(skin.name) ~= "string" then missing[#missing + 1] = "name (a string)" end
    for _, name in ipairs(functions) do
        if type(skin[name]) ~= "function" then missing[#missing + 1] = name end
    end
    if #missing > 0 then
        error(("Beastkeeper:%s(%s): the skin has no %s"):format(method, id, table.concat(missing, ", ")), 3)
    end
    register[id] = skin
end

local BUTTON_FUNCTIONS, HOLDER_FUNCTIONS = { "Style" }, { "Style", "Font" }

---Makes a button skin available. Another addon calls this on Beastkeeper's addon object, before
---Beastkeeper's modules show their buttons (at load, or from its OptionalDeps).
---@param id string kept in the saved settings; a short lowercase word
---@param skin AddonButtonSkin
function Addon:RegisterButtonSkin(id, skin)
    Register("RegisterButtonSkin", buttonSkins, id, skin, BUTTON_FUNCTIONS)
end

---Makes a holder skin available, as RegisterButtonSkin.
---@param id string
---@param skin AddonButtonHolderSkin
function Addon:RegisterButtonHolderSkin(id, skin)
    Register("RegisterButtonHolderSkin", holderSkins, id, skin, HOLDER_FUNCTIONS)
end

---@return table<string, AddonButtonSkin>
function Addon:ButtonSkins()
    return buttonSkins
end

---@return table<string, AddonButtonHolderSkin>
function Addon:ButtonHolderSkins()
    return holderSkins
end

---The button settings in the profile in use.
---@return AddonButtonSettings
function Addon:ButtonSettings()
    return self.db.profile.buttons --[[@as AddonButtonSettings]]
end

---The id a choice comes to: the chosen skin while it is registered, else the one with the
---highest priority (by id when equal).
---@param register table<string, AddonButtonSkin|AddonButtonHolderSkin>
---@param chosen string
---@return string
local function Pick(register, chosen)
    if chosen ~= AUTO and register[chosen] then return chosen end
    local best, bestPriority = Addon.BUTTON_DEFAULT_SKIN, -math.huge
    for id, skin in pairs(register) do
        local priority = skin.priority or 0
        if priority > bestPriority or (priority == bestPriority and id < best) then
            best, bestPriority = id, priority
        end
    end
    return best
end

---The id of the skin for Beastkeeper's buttons.
---@return string
function Addon:ButtonSkinFor()
    return Pick(buttonSkins, self:ButtonSettings().skin)
end

---The id of the skin for what holds Beastkeeper's buttons.
---@return string
function Addon:ButtonHolderSkinFor()
    return Pick(holderSkins, self:ButtonSettings().holder)
end

---For a skin whose buttons have no border to colour.
local function NoBorder() end

---Styles a button with the chosen skin, or Beastkeeper's own when that one errors.
---@param button Button
---@param parts AddonButtonParts
---@return fun(r: number, g: number, b: number) recolour sets the border's colour
function Addon:StyleButton(button, parts)
    local skin = buttonSkins[self:ButtonSkinFor()]
    local ok, result = pcall(skin.Style, button, parts)
    if not ok then
        geterrorhandler()(result)
        result = buttonSkins[self.BUTTON_DEFAULT_SKIN].Style(button, parts)
    end
    return (result or NoBorder) --[[@as fun(r: number, g: number, b: number)]]
end

---Whether icons lose their border: as the chosen look's UI says when it has a setting for it
---(ElvUI's Crop Icons), else Beastkeeper's own switch (off for an icon pack without borders, such as
---Clean Icons).
---@return boolean
function Addon:CropsIcons()
    local skin = holderSkins[self:ButtonHolderSkinFor()]
    if skin.CropsIcons then return skin.CropsIcons() end
    return self:ButtonSettings().crop ~= false
end

---Trims an icon's border, the look's way (`lookCrop`) or the game's; leaves it whole when icons
---are not cropped (CropsIcons).
---@param icon Texture
---@param lookCrop (fun(icon: Texture))?
function Addon:CropIcon(icon, lookCrop)
    if not self:CropsIcons() then
        icon:SetTexCoord(0, 1, 0, 1)
    elseif lookCrop then
        lookCrop(icon)
    else
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

---Styles a holder with the chosen skin, or Beastkeeper's own when that one errors; gives the skin
---used, for the rows' text and icons.
---@param frame Frame
---@return AddonButtonHolderSkin
function Addon:StyleButtonHolder(frame)
    local skin = holderSkins[self:ButtonHolderSkinFor()]
    local ok, err = pcall(skin.Style, frame)
    if ok then return skin end
    geterrorhandler()(err)
    skin = holderSkins[self.BUTTON_DEFAULT_SKIN]
    skin.Style(frame)
    return skin
end

-- Beastkeeper's own: a frame of colour behind the button; a panel as the game draws its own, the dark
-- dialog background inside a tooltip's border.

---@param button Button
---@return fun(r: number, g: number, b: number)
local function OwnButton(button)
    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(1, 1, 1, 1)
    ---@param r number
    ---@param g number
    ---@param b number
    local function Recolour(r, g, b)
        border:SetVertexColor(r, g, b)
    end
    return Recolour
end

local OWN_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local GOLD = { 1, 0.82, 0 }

---A holder is made with BackdropTemplate (Beastkeeper's window, the feed list).
---@param frame Frame
local function OwnHolder(frame)
    local backdrop = frame --[[@as BackdropTemplate]]
    backdrop:SetBackdrop(OWN_BACKDROP)
    backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
end

---The rows keep the font their template gives.
local function OwnFont() end

---@return number[]
local function OwnAccent()
    return GOLD
end

Addon:RegisterButtonSkin(Addon.NAME:lower(), { name = Addon.NAME, priority = 0, Style = OwnButton })
Addon:RegisterButtonHolderSkin(
    Addon.NAME:lower(),
    { name = Addon.NAME, priority = 0, Style = OwnHolder, Font = OwnFont, Accent = OwnAccent }
)
