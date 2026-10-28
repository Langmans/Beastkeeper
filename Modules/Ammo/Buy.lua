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

---The slots of the hunter's ammo bag for `kind`, nil without one.
---@param kind AddonAmmoKind
---@return number?
local function AmmoBagSlots(kind)
    for bag = 1, NUM_BAG_SLOTS do
        local _, bagType = C_Container.GetContainerNumFreeSlots(bag)
        if bagType == BAG_TYPES[kind] then return C_Container.GetContainerNumSlots(bag) end
    end
end

---The vendor's best ammo of `kind` for the hunter's level: its index in the vendor's list and its
---item ID; nil when it sells none.
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
        if ammo and ammo.kind == kind and ammo.level <= level and (not best or ammo.level > best) then
            index, itemID, best = i, id, ammo.level
        end
    end
    return index, itemID
end

-- A vendor opened: buy what the ammo bag (or the page's stacks) still lacks.
function M:MERCHANT_SHOW()
    local kind = M.Kind()
    if not kind or not self:Settings().buy then return end
    local index, itemID = BestOnSale(kind)
    if not index or not itemID then return end
    local stacks = AmmoBagSlots(kind) or self:Settings().stacks
    local need = stacks * STACK - C_Item.GetItemCount(itemID)
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
