local _, ns = ...

-- Buying at a vendor: when one opens that sells the hunter's kind of ammo, the best of it the
-- hunter's level allows (Data\Ammo.lua's levels), enough to fill the quiver or ammo pouch (its
-- slots times a stack), or the stacks the page sets without one, minus what the bags hold of it.
-- Only with a bow, gun or crossbow, and while the page's switch is on.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("Ammo") --[[@as AddonAmmo]]

local STACK = 200 -- ammo stacks to 200
local K = Addon.ammoKinds
-- The bag type flags of an ammo bag: a quiver holds arrows, an ammo pouch bullets.
local BAG_TYPES = { [K.arrow] = 1, [K.bullet] = 2 }

---The slots of the hunter's ammo bag for `kind` and how many of them are free; nil without one.
---@param kind AddonAmmoKind
---@return number? slots
---@return number? free
local function AmmoBagSlots(kind)
    for bag = 1, NUM_BAG_SLOTS do
        local free, bagType = C_Container.GetContainerNumFreeSlots(bag)
        if bagType == BAG_TYPES[kind] then return C_Container.GetContainerNumSlots(bag), free end
    end
end

---Whether the vendor's ammo `itemID` is worse than the ammo slot's (a lower level): bought, it
---would only fill bags beside the better ammo the hunter shoots.
---@param itemID number
---@return boolean
local function WorseThanEquipped(itemID)
    local equipped = GetInventoryItemID("player", 0)
    local ammo = equipped and Addon.data.ammo[equipped] --[[@as AddonAmmoItem?]]
    return ammo ~= nil and Addon.data.ammo[itemID].level < ammo.level
end

---Whether the hunter can buy the vendor's item at `index` for gold: not one its reputation does not
---reach (Burning Crusade's Warden's Arrow), nor one paid in tokens (Halaa's ammo). WoW: Forever
---gives the item as a table; the classic clients as GetMerchantItemInfo's returns.
---@param index number
---@return boolean
local function ForGold(index)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local info = C_MerchantFrame.GetItemInfo(index)
        return info ~= nil and info.isPurchasable == true and not info.hasExtendedCost
    end
    ---@diagnostic disable-next-line: wrong-flavor-api
    local _, _, _, _, _, purchasable, _, extendedCost = GetMerchantItemInfo(index)
    return purchasable ~= false and not extendedCost
end

---The vendor's best ammo of `kind` for the hunter's level that it can buy: its index in the
---vendor's list and its item ID; nil when it sells none.
---@param kind AddonAmmoKind
---@return number? index
---@return number? itemID
local function BestOnSale(kind)
    local level = UnitLevel("player")
    ---@type number?, number?, number?
    local index, itemID, best
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        local ammo = id and Addon.data.ammo[id] --[[@as AddonAmmoItem?]]
        local better = ammo and ammo.kind == kind and ammo.level <= level and (not best or ammo.level > best)
        if better and ForGold(i) then
            index, itemID, best = i, id, (ammo --[[@as AddonAmmoItem]]).level
        end
    end
    return index, itemID
end

-- A vendor opened: buy what the ammo bag (or the page's stacks) still lacks; with bagOnly no more
-- than the ammo bag's free slots hold. Nothing worse than the ammo slot's.
function M:MERCHANT_SHOW()
    local kind = M.Kind()
    local settings = self:Settings()
    if not kind or not settings.buy then return end
    local index, itemID = BestOnSale(kind)
    if not index or not itemID or WorseThanEquipped(itemID) then return end
    local slots, free = AmmoBagSlots(kind)
    local need = (slots or settings.stacks) * STACK - C_Item.GetItemCount(itemID)
    if free and settings.bagOnly then need = math.min(need, free * STACK) end
    if need <= 0 then return end
    local bought = need
    while need > 0 do
        local quantity = math.min(need, STACK)
        BuyMerchantItem(index, quantity)
        need = need - quantity
    end
    -- In the client's own name, once it has the item.
    Addon.WhenItemLoaded(itemID, function()
        self:Print(L.AMMO_BOUGHT:format(bought, M.AmmoName(itemID)))
    end)
end
