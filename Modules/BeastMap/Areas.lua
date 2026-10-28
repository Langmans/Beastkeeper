local _, ns = ...

-- The hunted beast's areas (Hunt.lua): a see-through disc around each of its pins, as big as the
-- area its spawns are in (LibTameable's radii; a small one where the data has none).
--
-- On the world map the discs sit on a frame over the map's canvas, the part that zooms, so they
-- grow and move with the map by themselves; drawn again when the map shows another map.
--
-- On the minimap they sit around where the hunter stands, redrawn a few times a second while a
-- hunt is on: the hunter's place on the area's map gives the offset in map percent, turned into
-- yards by measuring the map in the world (Beastkeeper.InWorld), then into the minimap's pixels by how
-- many yards it shows across at its zoom, turned with the player when the minimap rotates. A mask
-- keeps the discs inside the round minimap.

---@type Addon
local Addon = ns
local M = Addon:GetModule("BeastMap") --[[@as BeastkeeperBeastMap]]

local DISC = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local COLOUR = { 0.35, 1, 0.35, 0.3 }
local DEFAULT_RADIUS = 2 -- map percent, for a pin without a radius in the data
local TICK = 0.2 -- seconds between the minimap's redraws
-- How many yards the minimap shows across, by zoom (0 to 5), outdoors and indoors.
local MINIMAP_YARDS = {
    outdoor = { 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
    indoor = { 300, 240, 180, 120, 80, 50 },
}

---@type Texture[]
M.worldAreas, M.minimapAreas = {}, {}

-- Yards per map percent of each map, east and south, measured once.
---@type table<number, number[]|false>
local yardsPer = {}

---A map's yards per percent along x (east) and y (south); nil for a map not in the world.
---@param map number
---@return number? east
---@return number? south
local function YardsPerPercent(map)
    local known = yardsPer[map]
    if known == nil then
        local continent, x, y = Addon.InWorld(map, 0.5, 0.5)
        local _, ex, ey = Addon.InWorld(map, 0.51, 0.5)
        local _, sx, sy = Addon.InWorld(map, 0.5, 0.51)
        known = continent ~= nil and { math.sqrt((ex - x) ^ 2 + (ey - y) ^ 2), math.sqrt((sx - x) ^ 2 + (sy - y) ^ 2) }
        yardsPer[map] = known
    end
    if known then return known[1], known[2] end
end

---The `index`th disc of a pool, made on `parent` the first time, shown.
---@param pool Texture[]
---@param parent Frame
---@param index number
---@param mask MaskTexture?
---@return Texture
local function Disc(pool, parent, index, mask)
    local disc = pool[index]
    if not disc then
        disc = parent:CreateTexture(nil, "ARTWORK")
        disc:SetTexture(DISC)
        disc:SetVertexColor(COLOUR[1], COLOUR[2], COLOUR[3], COLOUR[4])
        if mask then disc:AddMaskTexture(mask) end
        pool[index] = disc
    end
    disc:ClearAllPoints()
    disc:Show()
    return disc
end

---Hides a pool's discs from the `first` on.
---@param pool Texture[]
---@param first number
local function HideFrom(pool, first)
    for index = first, #pool do
        pool[index]:Hide()
    end
end

---The beast hunted now, while the module is on.
---@return BeastkeeperBeast?
local function Hunted()
    local hunt = M:IsEnabled() and M:Hunt()
    return hunt and Addon.data.beasts[hunt.npc] or nil
end

-- The frame over the world map's canvas, made the first time.
---@type Frame?
local overlay

---Draws the hunted beast's discs on the map the world map shows.
function M:DrawWorldAreas()
    local count = 0
    local beast = Hunted()
    local map = WorldMapFrame:GetMapID()
    local pins = beast and beast.pins and map and beast.pins[map]
    if pins and beast then
        local canvas = WorldMapFrame:GetCanvas() --[[@as Frame]]
        if not overlay then
            overlay = CreateFrame("Frame", nil, canvas)
            overlay:SetAllPoints(canvas)
            overlay:SetFrameLevel(canvas:GetFrameLevel() + 100)
        end
        local width, height = canvas:GetWidth(), canvas:GetHeight()
        local radii = beast.radii and beast.radii[map]
        for i = 1, #pins, 2 do
            count = count + 1
            local radius = (radii and radii[(i + 1) / 2] or DEFAULT_RADIUS) / 100
            local disc = Disc(self.worldAreas, overlay, count)
            disc:SetSize(2 * radius * width, 2 * radius * height)
            disc:SetPoint("CENTER", overlay, "TOPLEFT", pins[i] / 100 * width, -pins[i + 1] / 100 * height)
        end
    end
    HideFrom(self.worldAreas, count + 1)
end

-- The minimap's frame and its round mask, made the first time.
---@type Frame?, MaskTexture?
local onMinimap, mask

---Draws the hunted beast's discs on the minimap, around where the hunter stands.
function M:DrawMinimapAreas()
    local count = 0
    local beast = Hunted()
    if beast and beast.pins then
        if not onMinimap then
            onMinimap = CreateFrame("Frame", nil, Minimap)
            onMinimap:SetAllPoints(Minimap)
            mask = onMinimap:CreateMaskTexture()
            mask:SetAllPoints(Minimap)
            mask:SetTexture(DISC, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        end
        local sizes = IsIndoors() and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor
        local perYard = Minimap:GetWidth() / sizes[(Minimap:GetZoom() or 0) + 1]
        local facing = GetCVar("rotateMinimap") == "1" and GetPlayerFacing and GetPlayerFacing() or 0
        if not Addon.Readable(facing) then facing = 0 end
        local cos, sin = math.cos(facing), math.sin(facing)
        for map, pins in pairs(beast.pins) do
            local east, south = YardsPerPercent(map)
            local position = east and C_Map.GetPlayerMapPosition(map, "player")
            local px, py
            if position then
                px, py = position:GetXY()
            end
            if east and south and Addon.Readable(px) and px and py then
                local radii = beast.radii and beast.radii[map]
                local across = (east + south) / 2
                for i = 1, #pins, 2 do
                    -- North up, in yards: east is x, north is y.
                    local dx, dy = (pins[i] - px * 100) * east, -(pins[i + 1] - py * 100) * south
                    local x, y = dx * cos + dy * sin, -dx * sin + dy * cos
                    local radius = (radii and radii[(i + 1) / 2] or DEFAULT_RADIUS) * across * perYard
                    count = count + 1
                    local disc = Disc(self.minimapAreas, onMinimap --[[@as Frame]], count, mask)
                    disc:SetSize(2 * radius, 2 * radius)
                    disc:SetPoint("CENTER", Minimap, "CENTER", x * perYard, y * perYard)
                end
            end
        end
    end
    HideFrom(self.minimapAreas, count + 1)
end

local ticking = false

---The minimap's redraw, again and again while a hunt is on.
local function Tick()
    M:DrawMinimapAreas()
    if Hunted() then
        C_Timer.After(TICK, Tick)
    else
        ticking = false
    end
end

local hooked = false

---Shows the hunt as it is now: the world map's discs, and the minimap's redraws while it is on.
function M:ShowHunt()
    if not hooked and WorldMapFrame then
        hooked = true
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            M:DrawWorldAreas()
        end)
    end
    self:DrawWorldAreas()
    self:DrawMinimapAreas()
    if Hunted() and not ticking then
        ticking = true
        C_Timer.After(TICK, Tick)
    end
end
