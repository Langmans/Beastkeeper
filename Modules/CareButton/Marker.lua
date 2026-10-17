local _, ns = ...

-- The low health marker: Mend Pet's icon left of the pet frame, lit while the pet's health is
-- below the low line. WoW: Forever may hide the pet's health from addons (a secret value), so the
-- low toast cannot decide then; the marker needs no decision. A Step curve maps the health
-- fraction to an alpha (1 below the line, 0 from it up), UnitHealthPercent evaluates it in the
-- client, and the result goes straight into SetAlpha, which takes a hidden value. Kennel never
-- reads the number. The marker takes no mouse: an invisible frame would still catch clicks.

---@type Kennel
local Kennel = ns
local M = Kennel:GetModule("CareButton") --[[@as KennelCareButton]]

local SIZE = 28

local marker = CreateFrame("Frame", "KennelLowHealthMarker", UIParent)
marker:SetSize(SIZE, SIZE)
marker:SetFrameStrata("MEDIUM")
marker:EnableMouse(false)
marker:Hide()
local icon = marker:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()

-- The curve for the current line, rebuilt when the line changes; styled once.
---@type LuaCurveObject?, number?
local curve, curveLine
local styled = false

---The curve that gives alpha 1 below `line` percent and 0 from it up.
---@param line number
---@return LuaCurveObject
local function CurveFor(line)
    if curveLine ~= line then
        curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0, 1)
        curve:AddPoint(line / 100, 0)
        curveLine = line
    end
    return curve --[[@as LuaCurveObject]]
end

---Whether the marker has something to show: the module on, a hunter with a living pet, a low
---line, the switch on, and a client with curves.
---@return boolean
local function Wanted()
    local _, class = UnitClass("player")
    local settings = M:Settings()
    if not (M:IsEnabled() and class == "HUNTER" and settings.marker and settings.low > 0) then return false end
    if not (C_CurveUtil and UnitHealthPercent) then return false end
    return UnitExists("pet") and not UnitIsDead("pet")
end

---Shows the marker at the pet's health, or hides it.
function M:UpdateMarker()
    if not Wanted() then
        marker:Hide()
        return
    end
    if not styled then
        styled = true
        local _, mendIcon = Kennel.SpellInfo(M.MEND_PET)
        icon:SetTexture(mendIcon)
        Kennel:StyleButton(marker --[[@as Button]], { icon = icon, group = "CareButton" })(1, 0, 0)
        marker:SetPoint("RIGHT", Kennel.PetFrame(), "LEFT", -4, 0)
    end
    -- A number curve gives a number, hidden or not; SetAlpha takes the hidden one as it is.
    local alpha = UnitHealthPercent("pet", true, CurveFor(self:Settings().low)) --[[@as number]]
    marker:SetAlpha(alpha)
    marker:Show()
end
