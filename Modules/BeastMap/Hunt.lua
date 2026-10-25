local _, ns = ...

-- The hunt: the hunter picks one beast to tame for one rank ("I'm taming this one for Claw 3"),
-- from a rank's button in the Abilities tab or a beast's pin. Kennel then shows the way there,
-- gives the beast to the tame key, and marks the beast's areas on the world map and the minimap
-- (Areas.lua). The hunt is kept per character and ends once the hunter knows the rank, or on the
-- button again or /kennel hunt stop. KENNEL_HUNT_STARTED and KENNEL_HUNT_ENDED tell other addons.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("BeastMap") --[[@as KennelBeastMap]]

---The hunt on, if any.
---@return KennelHunt?
function M:Hunt()
    return self.db.char.hunt --[[@as KennelHunt?]]
end

---Whether the hunt on is for beast `npc` and rank `spellID`.
---@param npc number?
---@param spellID number?
---@return boolean
function M:IsHunting(npc, spellID)
    local hunt = self:Hunt()
    return hunt ~= nil and hunt.npc == npc and hunt.spellID == spellID
end

---Starts hunting beast `npc` for rank `spellID`, going to its nearest spot or to the one given.
---@param npc number
---@param spellID number
---@param map number? a pin's map, with x and y (0 to 1)
---@param x number?
---@param y number?
function M:StartHunt(npc, spellID, map, x, y)
    if not self:IsEnabled() then return end
    if self:Hunt() then self:StopHunt() end
    self.db.char.hunt = { npc = npc, spellID = spellID }
    local name = M.BeastName(npc)
    self:Print(L.BEASTMAP_HUNT_START:format(name, M.RankText(spellID) or "?"))
    self:GoToBeast(npc, map, x, y)
    Kennel:SendMessage("KENNEL_HUNT_STARTED", { module = self:GetName(), npc = npc, spellID = spellID, name = name })
    self:ShowHunt()
    Kennel:RefreshWindow("abilities")
end

---Ends the hunt on: "learned" when the hunter knows the rank now, else "stopped".
---@param reason "learned"|"stopped"?
function M:StopHunt(reason)
    local hunt = self:Hunt()
    if not hunt then
        self:Print(L.BEASTMAP_HUNT_NONE)
        return
    end
    self.db.char.hunt = nil
    local name = M.BeastName(hunt.npc)
    if reason == "learned" then
        self:Print(L.BEASTMAP_HUNT_LEARNED:format(M.RankText(hunt.spellID) or "?", name))
    else
        self:Print(L.BEASTMAP_HUNT_STOPPED:format(name))
    end
    Kennel:SendMessage(
        "KENNEL_HUNT_ENDED",
        { module = self:GetName(), npc = hunt.npc, spellID = hunt.spellID, name = name, reason = reason or "stopped" }
    )
    self:ShowHunt()
    Kennel:RefreshWindow("abilities")
end

---KENNEL_RANKS_KNOWN: the pins again, and the hunt over once its rank is known.
function M:OnRanksKnown()
    self:Refresh()
    local hunt = self:Hunt()
    if hunt and not M.Lacking(hunt.spellID) then self:StopHunt("learned") end
end

M.command = "hunt"
M.commands = {
    stop = {
        desc = L.BEASTMAP_CMD_STOP,
        ---@param self KennelBeastMap
        func = function(self)
            self:StopHunt()
        end,
    },
}
