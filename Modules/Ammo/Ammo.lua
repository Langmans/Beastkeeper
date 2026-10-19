local _, ns = ...

-- The hunter's ammo count as a data broker source ("Kennel Ammo"), which displays such as
-- EllesmereUI's data bars and Titan Panel show: the count of the ammo in the ammo slot, orange
-- below the low line and red below the critical one, with a toast each time it crosses one
-- (taken away once restocked) and KENNEL_AMMO for other addons. Its tooltip names the nearest
-- vendor of the hunter's faction that sells its kind of ammo (arrows for a bow or crossbow,
-- bullets for a gun; Data\Ammo.lua); a click shows the way there through LibGoThere. Buy.lua buys
-- at a vendor. Only for a hunter.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelAmmo
local M = Kennel:NewModule("Ammo")
M.title = L.AMMO_TITLE
M.description = L.AMMO_DESC
M.toastTypes = { low = L.AMMO_TOASTTYPE_LOW, critical = L.AMMO_TOASTTYPE_CRITICAL }
M.defaults = { profile = { low = 500, critical = 250, toasts = true, buy = true, stacks = 1 } }

---The settings of the profile in use.
---@return KennelAmmoSettings
function M:Settings()
    return self.db.profile --[[@as KennelAmmoSettings]]
end

local GoThere = LibStub("LibGoThere-1.0") --[[@as LibGoThere]]
local AMMO_SLOT, RANGED_SLOT = INVSLOT_AMMO, INVSLOT_RANGED
local K, W = Kennel.ammoKinds, Enum.ItemWeaponSubclass
-- A ranged weapon's ammo by the weapon's subclass: a bow and a crossbow shoot arrows, a gun bullets.
local KINDS = { [W.Bows] = K.arrow, [W.Crossbow] = K.arrow, [W.Guns] = K.bullet }
local ICON = "Interface\\Icons\\INV_Ammo_Arrow_02"
local COLORS = { low = "|cffff8000%d|r", critical = "|cffff2020%d|r" }
-- A shot takes one from the bags: BAG_UPDATE_DELAYED comes once after it (also for a stack bought or
-- looted); other ammo in the ammo slot, or another weapon, is PLAYER_EQUIPMENT_CHANGED. A
-- display redraws only when the text changes.
local EVENTS = { "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED" }

---The kind of ammo the hunter's ranged weapon shoots (a Kennel.ammoKinds value), nil without a
---bow, gun or crossbow.
---@return KennelAmmoKind?
function M.Kind()
    local id = GetInventoryItemID("player", RANGED_SLOT)
    if not id then return nil end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(id)
    if classID ~= Enum.ItemClass.Weapon then return nil end
    return KINDS[subclassID]
end

---How much of the ammo in the ammo slot the hunter carries.
---@return number
local function Count()
    return GetInventoryItemCount("player", AMMO_SLOT) or 0
end

---An ammo's name as the client words it, else the data's.
---@param itemID number
---@return string
function M.AmmoName(itemID)
    local name = C_Item.GetItemInfo(itemID)
    if name then return name end
    local ammo = Kennel.data.ammo[itemID] --[[@as KennelAmmoItem?]]
    return ammo and ammo.name or "?"
end

---Where the count stands: "ok", "low" or "critical".
---@param count number
---@return "ok"|"low"|"critical"
function M:State(count)
    local settings = self:Settings()
    if count < settings.critical then return "critical" end
    if count < settings.low then return "low" end
    return "ok"
end

---How long `count` lasts at one Auto Shot per weapon swing ("~17 min", "~25 s"); nil without a
---weapon speed or ammo.
---@param count number
---@return string?
local function Lasts(count)
    local speed = UnitRangedDamage("player")
    if not canaccessvalue(speed) or not speed or speed <= 0 or count <= 0 then return nil end
    local seconds = count * speed
    if seconds < 60 then return L.AMMO_SECONDS:format(math.floor(seconds + 0.5)) end
    return L.AMMO_MINUTES:format(math.floor(seconds / 60 + 0.5))
end

-- The vendors' spots per kind of ammo for the hunter's faction, built on first use and again when
-- the data changes.
---@type table<KennelAmmoKind, LibGoTherePoint[]>
local pointsByKind = {}
---@type table?
local pointsFrom

---Whether a vendor sells ammo of `kind`.
---@param vendor KennelAmmoVendor
---@param kind KennelAmmoKind
---@return boolean
local function Sells(vendor, kind)
    for _, itemID in ipairs(vendor.sells) do
        local ammo = Kennel.data.ammo[itemID] --[[@as KennelAmmoItem?]]
        if ammo and ammo.kind == kind then return true end
    end
    return false
end

---Every pin of every vendor of the hunter's faction that sells its kind of ammo.
---@param kind KennelAmmoKind
---@return LibGoTherePoint[]
local function VendorPoints(kind)
    local vendors = Kennel.data.ammoVendors --[[@as table<number, KennelAmmoVendor>]]
    if pointsByKind[kind] then return pointsByKind[kind] end
    ---@type LibGoTherePoint[]
    local points = {}
    pointsByKind[kind] = points
    local side = UnitFactionGroup("player")
    for _, vendor in pairs(vendors) do
        if (not vendor.side or vendor.side == side) and Sells(vendor, kind) then
            for map, flat in pairs(vendor.pins) do
                for i = 1, #flat, 2 do
                    points[#points + 1] = { map, flat[i] / 100, flat[i + 1] / 100, vendor.name }
                end
            end
        end
    end
    return points
end

---The spot of several nearest the hunter: the one reached first when a route addon gives travel
---times (with its seconds), else the nearest on the hunter's own map, else the first.
---@param list LibGoTherePoint[]
---@return LibGoTherePoint? point
---@return number? seconds
local function Nearest(list)
    if #list == 0 then return nil end
    local seconds, index = GoThere:TravelTimeNearest(list)
    if index then return list[index], seconds end
    local here = C_Map.GetBestMapForUnit("player")
    local position = here and C_Map.GetPlayerMapPosition(here, "player")
    if not position then return list[1] end
    local x, y = position:GetXY()
    ---@type LibGoTherePoint?, number?
    local best, bestDistance
    for _, point in ipairs(list) do
        local distance = point[1] == here and (point[2] - x) ^ 2 + (point[3] - y) ^ 2
        if distance and (not bestDistance or distance < bestDistance) then
            best, bestDistance = point, distance
        end
    end
    return best or list[1]
end

-- The nearest vendor is kept while the hunter stays in one square of CELL yards, at most KEEP
-- seconds: a route addon's travel times take a while, and two vendors are a few yards apart at the
-- least, so a square's error is a few seconds of travel.
local CELL, KEEP = 100, 60
---@type string?, number, LibGoTherePoint?, number?
local keptKey, keptSince, keptPoint, keptSeconds = nil, 0, nil, nil
---@type table<number, number>, table<number, number>
local widths, heights = {}, {}

---A map's size in yards, from the client or else from where its corners lie in the world; nil when
---unknown.
---@param map number
---@return number?, number?
local function MapSize(map)
    if not widths[map] then
        local width, height
        if C_Map.GetMapWorldSize then
            width, height = C_Map.GetMapWorldSize(map)
        end
        if not width or width <= 0 then
            local _, a = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(0, 0))
            local _, b = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(1, 1))
            -- The world's x runs along the map's y axis, its y along the map's x axis.
            if not a or not b then return nil end
            width, height = math.abs(a.y - b.y), math.abs(a.x - b.x)
        end
        widths[map], heights[map] = width, height
    end
    return widths[map], heights[map]
end

---The square of CELL yards the hunter stands in, as a key: from the world position, else from the
---map position and the map's size; nil when neither is known.
---@return string?
local function Square()
    local y, x, _, instance = UnitPosition("player")
    if Kennel.Readable(x) and x and y then
        return ("%d:%d:%d"):format(instance or 0, math.floor(x / CELL), math.floor(y / CELL))
    end
    local map = C_Map.GetBestMapForUnit("player")
    local position = map and C_Map.GetPlayerMapPosition(map, "player")
    if not map or not position then return nil end
    local width, height = MapSize(map)
    if not width or not height then return nil end
    local px, py = position:GetXY()
    return ("map%d:%d:%d"):format(map, math.floor(px * width / CELL), math.floor(py * height / CELL))
end

---The nearest vendor for the hunter's kind of ammo, and the seconds to it when known.
---@return LibGoTherePoint?
---@return number?
function M:NearestVendor()
    local kind = M.Kind()
    if not kind then return nil end
    if Kennel.data.ammoVendors ~= pointsFrom then
        wipe(pointsByKind)
        pointsFrom, keptKey = Kennel.data.ammoVendors, nil
    end
    local square = Square()
    local key = square and square .. ":" .. kind
    local now = GetTime()
    if key and key == keptKey and now - keptSince <= KEEP then return keptPoint, keptSeconds end
    keptPoint, keptSeconds = Nearest(VendorPoints(kind))
    keptKey, keptSince = key, now
    return keptPoint, keptSeconds
end

---The tooltip a display shows on hover.
---@param tooltip GameTooltip
local function OnTooltipShow(tooltip)
    local ammo = GetInventoryItemID("player", AMMO_SLOT)
    if not M.Kind() then
        tooltip:AddLine(L.AMMO_NO_WEAPON)
    else
        local count = Count()
        local lasts = Lasts(count)
        local line = L.AMMO_COUNT:format(ammo and M.AmmoName(ammo) or L.AMMO_LABEL, count)
        tooltip:AddLine(lasts and line .. L.AMMO_LASTS:format(lasts) or line)
        local vendor, seconds = M:NearestVendor()
        if vendor then
            local info = C_Map.GetMapInfo(vendor[1])
            local where = info and L.AMMO_PLACE:format(vendor[4], info.name) or vendor[4]
            local travel = seconds and L.AMMO_TRAVEL:format(math.max(1, math.floor(seconds / 60 + 0.5))) or ""
            tooltip:AddLine(L.AMMO_NEAREST:format(where) .. travel, 1, 1, 1)
        else
            tooltip:AddLine(L.AMMO_NO_VENDOR, 1, 1, 1)
        end
    end
    tooltip:AddLine(L.AMMO_CLICK, 0.5, 0.5, 0.5)
end

---A click shows the way to the nearest vendor; a right-click opens the module's settings.
---@param _ Frame the display's frame
---@param button string
local function OnClick(_, button)
    if button == "RightButton" then
        Kennel:OpenOptions("Ammo")
        return
    end
    local vendor = M:NearestVendor()
    if not vendor then
        M:Print(L.AMMO_NO_VENDOR)
        return
    end
    GoThere:Navigate("Kennel", vendor[1], vendor[2], vendor[3], vendor[4])
end

---The toast for crossing into `state`.
---@param state "low"|"critical"
---@param count number
---@return KennelToastInfo
local function Toast(state, count)
    local lasts = Lasts(count)
    return {
        key = "Ammo:" .. state,
        type = "Ammo:" .. state,
        source = M.title,
        title = (state == "low" and L.AMMO_LOW or L.AMMO_CRITICAL):format(count),
        text = lasts and L.AMMO_ENOUGH:format(lasts) .. " " .. L.AMMO_TOAST_TEXT or L.AMMO_TOAST_TEXT,
        icon = GetInventoryItemTexture("player", AMMO_SLOT) or ICON,
    }
end

---Brings the text and icon up to date; when the count crossed a line: the toast (once per line,
---taken away once restocked) and KENNEL_AMMO.
function M:Update()
    local object = self.object
    if not object then return end
    local kind = self:IsEnabled() and M.Kind()
    object.icon = GetInventoryItemTexture("player", AMMO_SLOT) or ICON
    if not self:IsEnabled() then
        object.text = L.AMMO_OFF
        return
    elseif not kind then
        object.text = L.AMMO_NO_WEAPON
        self.state = nil
        return
    end
    local count = Count()
    local state = self:State(count)
    object.text = COLORS[state] and COLORS[state]:format(count) or tostring(count)
    if state == self.state then return end
    self.state = state
    Kennel:DropToasts("Ammo:")
    if state ~= "ok" and self:Settings().toasts then Kennel:ShowToast(Toast(state, count)) end
    Kennel:SendMessage("KENNEL_AMMO", { module = self:GetName(), count = count, state = state, kind = kind })
end

-- The handler of every event that may change the count.
local function Update()
    M:Update()
end

function M:OnEnable()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    if not self.object then
        self.object = LibStub("LibDataBroker-1.1"):NewDataObject("Kennel Ammo", {
            type = "data source",
            label = L.AMMO_LABEL,
            icon = ICON,
            text = "",
            OnTooltipShow = OnTooltipShow,
            OnClick = OnClick,
        })
    end
    self.state = nil
    Kennel.RegisterEvents(self, EVENTS, Update)
    self:RegisterEvent("MERCHANT_SHOW")
    self:Update()
end

-- A data object cannot be taken back: its text says Off; the toasts go.
function M:OnDisable()
    Kennel:DropToasts("Ammo:")
    self:Update()
end
