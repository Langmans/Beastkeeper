local _, ns = ...

-- Feeding the pet: the food in the bags it eats, in the order the button (Button.lua) feeds it,
-- and toasts when its happiness drops or the bags run out of food it eats.
--
-- A feeding gives the pet 8, 17 or 35 happiness a bite, by how far the food's item level lies
-- below the pet's (BITES); food further below gives nothing and is left out. The order: the most
-- happiness first, then the lowest level (keep the better food for later), then the smallest
-- stack (frees a slot). Food that also makes the hunter Well Fed comes last, whatever it gives.
-- Whether the pet eats an item is the client's answer (C_PetInfo.CanPetEatItem).
--
-- Only a hunter has a pet to feed: on any other class the module watches nothing.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelFeeding
local M = Kennel:NewModule("Feeding")
M.title = L.FEEDING_TITLE
M.description = L.FEEDING_DESC
M.requires = { "happiness" }
M.toastTypes = {
    content = L.FEEDING_TOASTTYPE_CONTENT,
    unhappy = L.FEEDING_TOASTTYPE_UNHAPPY,
    nofood = L.FEEDING_TOASTTYPE_NOFOOD,
}
M.defaults = { profile = { content = true, unhappy = true, noFood = true } }

M.FEED_PET = 6991
local FEED_PET_NAME = "Feed Pet" -- for a client that cannot name the spell itself
local FEED_PET_ICON = 132165
local WELL_FED = 19705 -- a Well Fed buff: its name is what a food's tooltip says
-- Happiness a bite by levels below the pet: at most `below` levels lower gives `bite`.
local BITES = { { below = 10, bite = 35 }, { below = 20, bite = 17 }, { below = 30, bite = 8 } }
local HAPPY, CONTENT, UNHAPPY = Kennel.happiness.happy, Kennel.happiness.content, Kennel.happiness.unhappy

---The settings of the profile in use.
---@return KennelFeedingSettings
function M:Settings()
    return self.db.profile --[[@as KennelFeedingSettings]]
end

---Feed Pet's name as the client calls it, for the button's macro.
---@return string
function M.FeedPetName()
    return Kennel.SpellInfo(M.FEED_PET) or FEED_PET_NAME
end

---The happiness a bite of food at `level` gives a pet at `petLevel`: 35, 17, 8, or 0.
---@param level number
---@param petLevel number
---@return number
local function Bite(level, petLevel)
    for _, step in ipairs(BITES) do
        if petLevel - level <= step.below then return step.bite end
    end
    return 0
end

-- Per item, whether it makes the hunter Well Fed: its tooltip never changes once loaded.
---@type table<number, boolean>
local wellFed = {}
local NO_LINES = {}
-- The lines of an item's tooltip, refilled for each item read.
---@type string[]
local lines = {}
-- A tooltip of Kennel's own to read an item's lines from, where the client has no C_TooltipInfo
-- item lookup (Classic Era); made the first time it is needed.
---@type GameTooltip?
local scanner

---An item's tooltip lines: from C_TooltipInfo where the client has it, else read off a hidden
---tooltip. Empty while the client has not loaded the item.
---@param itemID number
---@return string[]
local function ItemLines(itemID)
    wipe(lines)
    local getItem = C_TooltipInfo and C_TooltipInfo.GetItemByID
    if getItem then
        local info = getItem(itemID)
        for _, line in ipairs(info and info.lines or NO_LINES) do
            if line.leftText and Kennel.Readable(line.leftText) then lines[#lines + 1] = line.leftText end
        end
        return lines
    end
    scanner = scanner or CreateFrame("GameTooltip", "KennelScanTooltip", nil, "GameTooltipTemplate") --[[@as GameTooltip]]
    scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetItemByID(itemID)
    for i = 1, scanner:NumLines() do
        local region = _G["KennelScanTooltipTextLeft" .. i] --[[@as FontString?]]
        local text = region and region:GetText()
        if text then lines[#lines + 1] = text end
    end
    return lines
end

---Whether an item's tooltip says it makes the eater Well Fed (any case: "you will become well fed").
---Kept per item once the client has loaded it; asked again while it has not.
---@param itemID number
---@return boolean
local function MakesWellFed(itemID)
    if wellFed[itemID] ~= nil then return wellFed[itemID] end
    local buff = (Kennel.SpellInfo(WELL_FED) or "Well Fed"):lower()
    local found = false
    local itemLines = ItemLines(itemID)
    for _, text in ipairs(itemLines) do
        if text:lower():find(buff, 1, true) then found = true end
    end
    if #itemLines > 0 then wellFed[itemID] = found end
    return found
end

-- The food in the bags, in feeding order; the entries are reused from scan to scan.
---@type KennelFood[]
local foods, pool = {}, {}

---Two foods in feeding order.
---@param a KennelFood
---@param b KennelFood
---@return boolean
local function Before(a, b)
    if a.wellFed ~= b.wellFed then return b.wellFed end
    if a.bite ~= b.bite then return a.bite > b.bite end
    if a.level ~= b.level then return a.level < b.level end
    if a.count ~= b.count then return a.count < b.count end
    return a.bag * 1000 + a.slot < b.bag * 1000 + b.slot
end

---Whether the pet out eats an item: the client says so on WoW: Forever (C_PetInfo.CanPetEatItem);
---elsewhere the item's kind of food (Data\Era\Food.lua) must be on its family's diet.
---@param itemID number
---@return boolean
local function CanEat(itemID)
    local canEat = C_PetInfo and C_PetInfo.CanPetEatItem
    if canEat then return canEat(itemID) == true end
    local kinds = Kennel.data.foodKinds
    local kind = kinds and kinds[itemID]
    local info = kind and Kennel.familyInfo[Kennel.PetFamilyID() or 0]
    return info ~= nil and info.diet ~= nil and tContains(info.diet, kind)
end

---Adds the food in one bag slot to `foods` when the pet eats it and it pleases the pet.
---@param bag number
---@param slot number
---@param petLevel number
local function AddSlot(bag, slot, petLevel)
    local item = C_Container.GetContainerItemInfo(bag, slot)
    if not item or not CanEat(item.itemID) then return end
    local level = select(4, C_Item.GetItemInfo(item.itemID))
    local bite = level and Bite(level, petLevel) or 0
    if bite == 0 then return end
    local food = pool[#foods + 1] or {}
    pool[#foods + 1] = food
    food.bag, food.slot, food.itemID, food.count = bag, slot, item.itemID, item.stackCount
    food.level, food.bite, food.wellFed = level, bite, MakesWellFed(item.itemID)
    foods[#foods + 1] = food
end

---Reads the bags again: the food the pet out eats, in feeding order. Empty without a pet.
---@return KennelFood[]
function M:Scan()
    wipe(foods)
    local petLevel = UnitExists("pet") and UnitLevel("pet")
    if not petLevel then return foods end
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            AddSlot(bag, slot, petLevel)
        end
    end
    table.sort(foods, Before)
    return foods
end

---The food in feeding order, as of the last scan.
---@return KennelFood[]
function M:Foods()
    return foods
end

---A food's name, as the client gives it.
---@param food KennelFood
---@return string
function M.FoodName(food)
    return C_Item.GetItemInfo(food.itemID) or ("item:" .. food.itemID)
end

---The macro that feeds a food: Feed Pet, then its bag slot as the item it waits for.
---@param food KennelFood
---@return string
function M.FeedMacro(food)
    return ("/cast %s\n/use %d %d"):format(M.FeedPetName(), food.bag, food.slot)
end

-- A food's colour by the happiness a bite gives; Well Fed food grey.
local BITE_COLORS = { [35] = { 0, 1, 0 }, [17] = { 1, 1, 0 }, [8] = { 1, 0.5, 0 } }
local WELL_FED_COLOR = { 0.6, 0.6, 0.6 }

---A food's colour in the tooltip and the list.
---@param food KennelFood
---@return number r, number g, number b
function M.FoodColor(food)
    local color = food.wellFed and WELL_FED_COLOR or BITE_COLORS[food.bite]
    return color[1], color[2], color[3]
end

local Happiness = Kennel.PetHappiness
M.Happiness = Happiness

-- Per toast: its title (%s: the pet's name) and text.
---@type table<string, {title: string, text: string}>
local TOASTS = {
    content = { title = L.FEEDING_TOAST_CONTENT, text = L.FEEDING_REASON_CONTENT },
    unhappy = { title = L.FEEDING_TOAST_UNHAPPY, text = L.FEEDING_REASON_UNHAPPY },
    nofood = { title = L.FEEDING_TOAST_NOFOOD, text = L.FEEDING_REASON_NOFOOD },
}

---The toast for `kind`: for a happiness drop with the food the button feeds next as its hint.
---@param kind "content"|"unhappy"|"nofood"
---@return KennelToastInfo
function M:Toast(kind)
    local first = foods[1]
    local hint = first and L.FEEDING_NEXT:format(M.FoodName(first)) or L.FEEDING_HINT_NO_FOOD
    local _, feedIcon = Kennel.SpellInfo(M.FEED_PET)
    return {
        key = "Feeding:" .. kind,
        type = "Feeding:" .. kind,
        source = self.title,
        title = TOASTS[kind].title:format(UnitName("pet") or ""),
        text = TOASTS[kind].text,
        hint = kind ~= "nofood" and hint or nil,
        icon = first and C_Item.GetItemIconByID(first.itemID) or feedIcon or FEED_PET_ICON,
    }
end

---Toasts a happiness drop (once per level reached) and takes away the toasts a rise answers.
function M:CheckHappiness()
    self:ApplyButton()
    local happiness = Happiness()
    if not happiness then return end
    local last = self.happiness or HAPPY
    self.happiness = happiness
    local settings = self:Settings()
    if happiness > UNHAPPY then Kennel:DropToast("Feeding:unhappy") end
    if happiness > CONTENT then Kennel:DropToast("Feeding:content") end
    if happiness >= last then return end
    if happiness == CONTENT and settings.content then Kennel:ShowToast(self:Toast("content")) end
    if happiness == UNHAPPY and settings.unhappy then Kennel:ShowToast(self:Toast("unhappy")) end
end

---Scans the bags, gives the button its food, and says when the last food the pet eats has gone.
function M:Update()
    local had = #foods > 0
    self:Scan()
    self:CloseFoodList()
    self:ApplyButton()
    if #foods > 0 then
        Kennel:DropToast("Feeding:nofood")
    elseif had and UnitExists("pet") and self:Settings().noFood then
        Kennel:ShowToast(self:Toast("nofood"))
    end
end

function M:BAG_UPDATE_DELAYED()
    self:Update()
end

-- A pet summoned or dismissed: another pet, another diet and level.
---@param _ string the event
---@param unit string
function M:UNIT_PET(_, unit)
    if unit ~= "player" then return end
    self.happiness = nil
    wipe(foods)
    self:Update()
    self:CheckHappiness()
end

---@param _ string the event
---@param unit string
function M:UNIT_LEVEL(_, unit)
    if unit == "pet" then self:Update() end
end

-- The core's KENNEL_PET_HAPPINESS: the pet's happiness changed.
function M:OnHappiness()
    self:CheckHappiness()
end

-- Not every client has every one; a missing one is skipped.
local EVENTS = { "BAG_UPDATE_DELAYED", "UNIT_PET", "UNIT_LEVEL" }

function M:OnEnable()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    Kennel.RegisterEvents(self, EVENTS)
    Kennel:Listen(self, "KENNEL_PET_HAPPINESS", "OnHappiness")
    self.happiness = nil
    wipe(foods)
    self:Update()
end

-- AceEvent drops the events by itself; the toasts and the button go here.
function M:OnDisable()
    Kennel:StopListening(self)
    Kennel:DropToasts("Feeding:")
    wipe(foods)
    self:CloseFoodList()
    self:ApplyButton()
end
