local _, ns = ...

-- Which food a Feed Pet cast used, seen in one of three ways, claimed in this order:
-- - targeted: a bag click while Feed Pet waits for an item ends up in C_Container.UseContainerItem
--   (the hook in FeedEmotes.lua). On WoW: Forever this does not fire; the eaten route catches it.
-- - cursor: the food was picked up and dropped on the pet, which may involve no Lua at all, so the
--   item last on the cursor, let go of shortly before the cast, is the food.
-- - eaten: the item whose count in the bags dropped (Feed Pet: Forever's button, the spellbook
--   with a click in EllesmereUIBags). The bags may update just after the cast, hence WaitForBags.

---@type Addon
local Addon = ns
local M = Addon:GetModule("FeedEmotes") --[[@as AddonFeedEmotes]]

local FOOD_WINDOW = 3 -- seconds after an item is picked (or let go of) a cast may still claim it
local EATEN_WINDOW = 1 -- seconds an item that left the bags counts as eaten, before or after the cast

---@class AddonFoodTracker
---@field targetedFood number?
---@field targetedAt number?
---@field cursorFood number?
---@field cursorReleasedAt number? nil while the item is still on the cursor
---@field bagCounts table<number, number> item -> count as of the last bag update
---@field previousCounts table<number, number> the table bagCounts swaps with, so counting builds none
---@field eatenFood number?
---@field eatenAt number?
---@field onEaten fun(itemID: number?)? a cast waiting for the bags
local Tracker = { bagCounts = {}, previousCounts = {} }
M.Tracker = Tracker

-- The items found in one scan; reused.
---@type table<number, true>
local inBags = {}

---Fills `counts` (emptied first) with every carried item's count; hidden IDs and counts are left
---out. Runs on every bag update, so it builds no tables.
---@param counts table<number, number>
local function CountBags(counts)
    wipe(inBags)
    wipe(counts)
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and Addon.Readable(itemID) then inBags[itemID] = true end
        end
    end
    for itemID in pairs(inBags) do
        local count = C_Item.GetItemCount(itemID)
        if Addon.Readable(count) then counts[itemID] = count end
    end
end

---A bag item was used; it is the food only while a spell waits for an item target.
---@param bag number
---@param slot number
function Tracker:OnTargeted(bag, slot)
    if not (SpellIsTargeting and SpellIsTargeting()) then return end
    local item = C_Container.GetContainerItemInfo(bag, slot)
    if item and Addon.Readable(item.itemID) then
        self.targetedFood, self.targetedAt = item.itemID, GetTime()
    end
end

---Remembers the item while it is on the cursor, and when it was let go.
function Tracker:OnCursorChanged()
    local kind, itemID = GetCursorInfo()
    if kind == "item" then
        self.cursorFood = Addon.Readable(itemID) and itemID --[[@as number]] or nil
        self.cursorReleasedAt = nil
    elseif self.cursorFood and not self.cursorReleasedAt then
        self.cursorReleasedAt = GetTime()
    end
end

---Compares the bags with the last count; a cast waiting for the bags takes the item that went down.
function Tracker:OnBagsUpdated()
    local previous, counts = self.bagCounts, self.previousCounts
    CountBags(counts)
    for itemID, before in pairs(previous) do
        if (counts[itemID] or 0) < before then
            self.eatenFood, self.eatenAt = itemID, GetTime()
        end
    end
    self.bagCounts, self.previousCounts = counts, previous
    if self.onEaten and self.eatenFood then
        local onEaten, itemID = self.onEaten, self.eatenFood
        self.onEaten, self.eatenFood = nil, nil
        onEaten(itemID)
    end
end

---The food this Feed Pet cast used, if it can be told; forgets it either way.
---@return number?
function Tracker:Claim()
    local now, itemID = GetTime(), nil
    if self.targetedFood and now - self.targetedAt <= FOOD_WINDOW then
        itemID = self.targetedFood
    elseif self.cursorFood and (not self.cursorReleasedAt or now - self.cursorReleasedAt <= FOOD_WINDOW) then
        itemID = self.cursorFood
    elseif self.eatenFood and now - self.eatenAt <= EATEN_WINDOW then
        itemID = self.eatenFood
    end
    self.targetedFood, self.cursorFood, self.eatenFood = nil, nil, nil
    return itemID
end

---No other sign of the food: waits for the bags. onFood is called once, with the item that left
---the bags, or with nil after EATEN_WINDOW.
---@param onFood fun(itemID: number?)
function Tracker:WaitForBags(onFood)
    self.onEaten = onFood
    C_Timer.After(EATEN_WINDOW, function()
        if self.onEaten ~= onFood then return end
        self.onEaten = nil
        onFood(nil)
    end)
end
