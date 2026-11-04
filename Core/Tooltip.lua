local _, ns = ...

-- Lines added to the game's unit and spell tooltips, the same way on every client: through
-- GameTooltip's OnTooltipSetUnit and OnTooltipSetSpell scripts where it has them (Classic Era),
-- else through the post-calls the client runs after filling a tooltip (TooltipDataProcessor, WoW:
-- Forever and newer). Never both, so a line is added once.
--
-- On Classic Era two spell tooltips run no spell script: a row of Beast Training (the craft
-- window, SetCraftSpell) and a pet bar slot (SetPetAction). Their spell comes from the row's name
-- and rank or the slot, and only when the tooltip has no spell of its own: then the script ran.

---@type Addon
local Addon = ns

---Runs `fn(tooltip, guid)` after the game fills a unit's tooltip.
---@param fn fun(tooltip: GameTooltip, guid: GameValue)
function Addon.OnUnitTooltip(fn)
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

---The pet ability rank a Beast Training row stands for, by its name and rank text; nil for a row
---that is no rank in the beast data.
---@param index number
---@return number?
local function CraftSpell(index)
    -- The craft window is there only on the clients that send CRAFT_SHOW (Classic Era, Burning Crusade).
    ---@diagnostic disable-next-line: wrong-flavor-api
    local name, rankText = GetCraftInfo(index)
    local rank = tonumber(type(rankText) == "string" and rankText:match("%d+")) or 1
    for spellID, info in pairs(Addon.data.petAbilityRanks) do
        if info.rank == rank and Addon.SpellInfo(info.ability) == name then return spellID end
    end
end

---Runs `fn(tooltip, spellID)` after the game fills a spell's tooltip: the spellbook, an action
---button, the pet bar, Beast Training.
---@param fn fun(tooltip: GameTooltip, spellID: number)
function Addon.OnSpellTooltip(fn)
    if GameTooltip:HasScript("OnTooltipSetSpell") then
        ---@param tooltip GameTooltip
        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip)
            local _, spellID = tooltip:GetSpell()
            if spellID then fn(tooltip, spellID) end
        end)
        ---@param tooltip GameTooltip
        ---@param index number
        hooksecurefunc(GameTooltip, "SetCraftSpell", function(tooltip, index)
            local spellID = not tooltip:GetSpell() and CraftSpell(index)
            if spellID then fn(tooltip, spellID) end
        end)
        ---@param tooltip GameTooltip
        ---@param slot number
        hooksecurefunc(GameTooltip, "SetPetAction", function(tooltip, slot)
            local spellID = not tooltip:GetSpell() and select(7, GetPetActionInfo(slot))
            if spellID then fn(tooltip, spellID) end
        end)
    elseif TooltipDataProcessor and Enum.TooltipDataType then
        ---@param tooltip GameTooltip
        ---@param data {id: number?}
        local function PostCall(tooltip, data)
            if data.id then fn(tooltip, data.id) end
        end
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, PostCall)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.PetAction, PostCall)
    end
end
