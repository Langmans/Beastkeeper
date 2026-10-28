local _, ns = ...

-- Places in the world, to measure in a straight line across zone borders: a map spot's continent
-- and position in yards, and the player's. x and y are as UnitPosition gives them (its second and
-- first return); C_Map's world positions have them the other way round.

---@type Addon
local Addon = ns

---Where a spot on a map (x, y from 0 to 1) lies in the world: its continent (instance ID) and x, y
---in yards; nil when the client cannot place the map.
---@param map number
---@param x number
---@param y number
---@return number? continent
---@return number x
---@return number y
function Addon.InWorld(map, x, y)
    local continent, world = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(x, y))
    if not continent or not world then return nil, 0, 0 end
    return continent, world.y, world.x
end

---Where the player stands in the world: the continent (instance ID) and x, y in yards, from
---UnitPosition, else from where its map position lies in the world; nil when neither is known.
---@return number? continent
---@return number x
---@return number y
function Addon.PlayerInWorld()
    local y, x, _, instance = UnitPosition("player")
    if Addon.Readable(x) and x and y then return instance or 0, x, y end
    local map = C_Map.GetBestMapForUnit("player")
    local position = map and C_Map.GetPlayerMapPosition(map, "player")
    if not map or not position then return nil, 0, 0 end
    local continent, world = C_Map.GetWorldPosFromMapPos(map, position)
    if not continent or not world then return nil, 0, 0 end
    return continent, world.y, world.x
end
