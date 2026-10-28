local _, ns = ...

-- An instant skin: hands a toast to LS: Toasts, which stacks, animates and skins it with the
-- player's other toasts, at its first anchor. Its global, named after the addon (ls_Toasts_Classic
-- on the classic clients, ls_Toasts on retail, the same API in both), holds { E, C, L }; a toast
-- comes from E:GetToast, which reuses one already out with the same data. Each Kennel toast gets
-- a number of its own there, so two are never merged. The borders take the toast's accent where
-- LS: Toasts colours borders (its Colors settings). Kennel plays the toast's sound itself.

local LS = ls_Toasts_Classic or ls_Toasts --[[@as LSToastsGlobal?]]
if not LS then return end

---@type Kennel
local Kennel = ns
local L = Kennel.L
local E, C = LS[1], LS[2]

-- LS: Toasts' first anchor, which every install has.
local ANCHOR = 1
-- Kennel's toasts handed over so far: each one's key in LS: Toasts.
local count = 0

local skin = { name = L.TOAST_SKIN_LSTOASTS, instant = true } --[[@as KennelToastSkin]]

---@param info KennelToastInfo
function skin:Show(info)
    count = count + 1
    local toast = E:GetToast(nil, "kennel", count)
    toast._data.kennel = count
    toast.Title:SetText(info.title)
    toast.Text:SetText(info.text or "")
    toast.Icon:SetTexture(info.icon or Kennel.TOAST_ICON)
    toast.IconBorder:Show()
    local accent = info.accent or Kennel.DefaultToastAccent()
    local colors = C.db.profile.colors
    if colors.border then toast.Border:SetVertexColor(accent[1], accent[2], accent[3]) end
    if colors.icon_border then toast.IconBorder:SetVertexColor(accent[1], accent[2], accent[3]) end
    toast:Spawn(ANCHOR, false)
end

Kennel:RegisterToastSkin("lstoasts", skin)
