local _, ns = ...

-- Lines added to the game's unit tooltips, the same way on every client: through GameTooltip's
-- OnTooltipSetUnit script where it has one (Classic Era), else through the post-calls the client
-- runs after filling a unit's tooltip (TooltipDataProcessor, WoW: Forever and newer). Never both,
-- so a line is added once.

---@type Kennel
local Kennel = ns

---Runs `fn(tooltip, guid)` after the game fills a unit's tooltip.
---@param fn fun(tooltip: GameTooltip, guid: GameValue)
function Kennel.OnUnitTooltip(fn)
    if GameTooltip:HasScript("OnTooltipSetUnit") then
        ---@param tooltip GameTooltip
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            ---@type string?, string?
            local _, unit = tooltip:GetUnit()
            if unit then fn(tooltip, UnitGUID(unit)) end
        end)
    elseif TooltipDataProcessor and Enum.TooltipDataType then
        ---@param tooltip GameTooltip
        ---@param data {guid: GameValue}
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            fn(tooltip, data.guid)
        end)
    end
end
