local _, ns = ...

-- Kennel as a LibDataBroker-1.1 data source ("Kennel"), which displays such as Titan Panel,
-- ChocolateBar and ElvUI's datatexts show: the pet out in its text (name, happiness, free training
-- points), more in its tooltip (level, loyalty, points, the Pet Journal in brief), Kennel's page
-- on a click and the Pet Journal's on a right-click. A data object cannot be taken back, so while
-- the module is off its text says so. Only for a hunter.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelBroker
local M = Kennel:NewModule("Broker")
M.title = L.BROKER_TITLE
M.description = L.BROKER_DESC

local ICON = "Interface\\Icons\\Ability_Hunter_BeastCall"
local HINT_COLOR = { 0.5, 0.5, 0.5 }
local JOURNAL_COLOR = { 0.6, 0.6, 0.6 }
-- The happiness levels by number, as Feeding names them.
local HAPPINESS = { L.FEEDING_UNHAPPY, L.FEEDING_CONTENT, L.FEEDING_HAPPY }
local EVENTS = { "UNIT_PET", "UNIT_HAPPINESS", "PET_UI_UPDATE", "UNIT_PET_TRAINING_POINTS", "UNIT_LEVEL" }

---The text for a display: the pet's name, with its happiness and free points when the client
---tells them.
---@return string
local function Text()
    if not UnitExists("pet") then return L.BROKER_NO_PET end
    local name = UnitName("pet") or "?"
    local happiness = Kennel.PetHappiness()
    local free = Kennel.PetTrainingPoints()
    if not happiness or not free then return name end
    return L.BROKER_TEXT:format(name, HAPPINESS[happiness], free)
end

---The Pet Journal's brief lines for the pet out, when that module is on and has it.
---@param tooltip GameTooltip
local function AddJournal(tooltip)
    local journal = Kennel:GetModule("PetJournal", true) --[[@as KennelPetJournal?]]
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
        local free, total = Kennel.PetTrainingPoints()
        local loyalty, loyaltyName = Kennel.PetLoyalty(total or 0, total and UnitLevel("pet") or nil)
        if loyalty then tooltip:AddLine(L.BROKER_LOYALTY:format(Kennel.LoyaltyLabel(loyalty, loyaltyName)), 1, 1, 1) end
        if free then tooltip:AddLine(L.BROKER_POINTS:format(free, total), 1, 1, 1) end
        AddJournal(tooltip)
    end
    tooltip:AddLine(L.BROKER_CLICK, HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])
end

---A click opens Kennel's page; a right-click the Pet Journal's.
---@param _ Frame the display's frame
---@param button string
local function OnClick(_, button)
    Kennel:OpenOptions(button == "RightButton" and "PetJournal" or nil)
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
        self.object = LibStub("LibDataBroker-1.1"):NewDataObject("Kennel", {
            type = "data source",
            label = "Kennel",
            icon = ICON,
            text = "",
            OnTooltipShow = OnTooltipShow,
            OnClick = OnClick,
        })
    end
    for _, event in ipairs(EVENTS) do
        pcall(self.RegisterEvent, self, event, Update)
    end
    self:Update()
end

function M:OnDisable()
    self:Update()
end
