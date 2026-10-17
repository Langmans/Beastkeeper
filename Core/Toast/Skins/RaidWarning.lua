local _, ns = ...

-- An instant skin: the toast as a raid warning, the game's own big text in the middle of the
-- screen, as one line ("icon Title: text") in its accent colour. WoW: Forever takes it through
-- RaidWarningFrame:AddMessage; older clients through RaidNotice_AddMessage.

---@type Kennel
local Kennel = ns
local L = Kennel.L

-- The colour handed to the raid warning, refilled for each toast.
---@type {r: number, g: number, b: number}
local color = { r = 1, g = 1, b = 1 }

-- Forever's frame, with the AddMessage its mixin (RaidWarningFrameMixin) gives it.
---@class KennelRaidWarningFrame: Frame
---@field AddMessage fun(self: KennelRaidWarningFrame, text: string, color: table)

local skin = { name = L.TOAST_SKIN_RAIDWARNING, instant = true } --[[@as KennelToastSkin]]

---@param info KennelToastInfo
function skin:Show(info)
    local accent = info.accent or Kennel.DefaultToastAccent()
    color.r, color.g, color.b = accent[1], accent[2], accent[3]
    local text = info.text and info.title .. ": " .. info.text or info.title
    if info.icon then text = ("|T%s:0|t %s"):format(info.icon, text) end
    if RaidNotice_AddMessage then
        RaidNotice_AddMessage(RaidWarningFrame, text, color)
    else
        local frame = RaidWarningFrame --[[@as KennelRaidWarningFrame]]
        frame:AddMessage(text, color)
    end
end

Kennel:RegisterToastSkin("raidwarning", skin)
