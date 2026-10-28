local _, ns = ...

-- Beastkeeper as a LibDataBroker-1.1 data source ("Beastkeeper"), which displays such as Titan Panel,
-- ChocolateBar and ElvUI's datatexts show: the pet out in its text (name, happiness, free training
-- points), more in its tooltip (level, loyalty, points, the Pet Journal in brief), Beastkeeper's window
-- on a click and the options on a right-click. A data object cannot be taken back, so while
-- the module is off its text says so. Only for a hunter.

---@type Addon
local Addon = ns
local L = Addon.L

---@type AddonBroker
local M = Addon:NewModule("Broker")
M.title = L.BROKER_TITLE
M.description = L.BROKER_DESC
-- minimap: LibDBIcon's own table for the minimap button (hide, and minimapPos once dragged).
M.defaults = { profile = { minimap = { hide = false } } }

local ICON = "Interface\\Icons\\Ability_Hunter_BeastCall"
local HINT_COLOR = { 0.5, 0.5, 0.5 }
local JOURNAL_COLOR = { 0.6, 0.6, 0.6 }
-- The happiness levels by number, as Feeding names them.
local HAPPINESS = { L.FEEDING_UNHAPPY, L.FEEDING_CONTENT, L.FEEDING_HAPPY }
-- Happiness and growth come from the core's BEASTKEEPER_PET_HAPPINESS and BEASTKEEPER_PET_GROWTH; points
-- spent change only what is free, which UNIT_PET_TRAINING_POINTS tells.
local EVENTS = { "UNIT_PET", "UNIT_PET_TRAINING_POINTS" }

---The text for a display: the pet's name, with its happiness and free points when the client
---tells them.
---@return string
local function Text()
    if not UnitExists("pet") then return L.BROKER_NO_PET end
    local name = UnitName("pet") or "?"
    local happiness = Addon.PetHappiness()
    local free = Addon.PetTrainingPoints()
    if not happiness or not free then return name end
    return L.BROKER_TEXT:format(name, HAPPINESS[happiness], free)
end

---The Pet Journal's brief lines for the pet out, when that module is on and has it.
---@param tooltip GameTooltip
local function AddJournal(tooltip)
    local journal = Addon:GetModule("PetJournal", true) --[[@as AddonPetJournal?]]
    if not journal or not journal:IsEnabled() or not journal.current then return end
    for _, line in ipairs(journal:JournalLines(journal.current, true)) do
        tooltip:AddLine(line, JOURNAL_COLOR[1], JOURNAL_COLOR[2], JOURNAL_COLOR[3], true)
    end
end

---The tooltip a display shows on hover.
---@param tooltip GameTooltip
local function OnTooltipShow(tooltip)
    if not UnitExists("pet") then
        tooltip:AddLine(L.BROKER_NO_PET)
    else
        local family = UnitCreatureFamily("pet")
        tooltip:AddLine(L.BROKER_PET:format(UnitName("pet") or "?", UnitLevel("pet") or 0, family or "?"))
        local free, total = Addon.PetTrainingPoints()
        local loyalty, loyaltyName = Addon.PetLoyalty(total or 0, total and UnitLevel("pet") or nil)
        if loyalty then tooltip:AddLine(L.BROKER_LOYALTY:format(Addon.LoyaltyLabel(loyalty, loyaltyName)), 1, 1, 1) end
        if free then tooltip:AddLine(L.BROKER_POINTS:format(free, total), 1, 1, 1) end
        AddJournal(tooltip)
    end
    tooltip:AddLine(L.BROKER_CLICK, HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])
end

---A click opens or closes Beastkeeper's window; a right-click opens the options.
---@param _ Frame the display's frame
---@param button string
local function OnClick(_, button)
    if button == "RightButton" then
        Addon:OpenOptions()
    else
        Addon:ToggleWindow()
    end
end

---Brings the text up to date.
function M:Update()
    if self.object then self.object.text = self:IsEnabled() and Text() or L.BROKER_OFF end
end

-- The handler of every event that may change the text.
local function Update()
    M:Update()
end

function M:OnEnable()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    if not self.object then
        self.object = LibStub("LibDataBroker-1.1"):NewDataObject(Addon.NAME, {
            type = "data source",
            label = Addon.NAME,
            icon = ICON,
            text = "",
            OnTooltipShow = OnTooltipShow,
            OnClick = OnClick,
        })
    end
    Addon.RegisterEvents(self, EVENTS, Update)
    Addon:Listen(self, Addon.messages.petHappiness, Update)
    Addon:Listen(self, Addon.messages.petGrowth, Update)
    self:Update()
    self:ApplyMinimapButton()
end

function M:OnDisable()
    Addon:StopListening(self)
    self:Update()
    self:ApplyMinimapButton()
end

---The minimap button (LibDBIcon, when loaded) for the data object: shown while the module is on
---and its switch says so. LibDBIcon keeps the profile's table; a profile change hands it the new.
function M:ApplyMinimapButton()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon or not self.object then return end
    local settings = self.db.profile.minimap --[[@as LibDBIcon.button.DB]]
    if icon:IsRegistered(Addon.NAME) then
        icon:Refresh(Addon.NAME, settings)
    else
        icon:Register(Addon.NAME, self.object, settings)
    end
    if self:IsEnabled() and not settings.hide then
        icon:Show(Addon.NAME)
    else
        icon:Hide(Addon.NAME)
    end
end

---@return table
function M:GetOptions()
    return {
        args = {
            minimap = {
                type = "toggle",
                name = L.BROKER_OPTION_MINIMAP,
                desc = L.BROKER_OPTION_MINIMAP_DESC,
                width = "full",
                order = 1,
                get = function()
                    return not self.db.profile.minimap.hide
                end,
                ---@param _ table AceConfig's info about the option
                ---@param value boolean
                set = function(_, value)
                    self.db.profile.minimap.hide = not value
                    self:ApplyMinimapButton()
                end,
            },
        },
    }
end
