local _, ns = ...

-- An instant skin: hands a toast to LS: Toasts, which stacks, animates and skins it with the
-- player's other toasts, at its first anchor. Its global, named after the addon (ls_Toasts_Classic
-- on the classic clients, ls_Toasts on retail, the same API in both), holds { E, C, L }; a toast
-- comes from E:GetToast, which reuses one already out with the same data. Each Beastkeeper toast gets
-- a number of its own there, so two are never merged. The borders take the toast's accent where
-- LS: Toasts colours borders (its Colors settings). Beastkeeper plays the toast's sound itself.

local LS = ls_Toasts_Classic or ls_Toasts --[[@as LSToastsGlobal?]]
if not LS then return end

---@type Addon
local Addon = ns
local L = Addon.L
local E, C = LS[1], LS[2]

-- LS: Toasts' first anchor, which every install has.
local ANCHOR = 1
-- Beastkeeper's toasts handed over so far: each one's key in LS: Toasts.
local count = 0

local skin = { name = L.TOAST_SKIN_LSTOASTS, instant = true } --[[@as AddonToastSkin]]

---@param info AddonToastInfo
function skin:Show(info)
    count = count + 1
    local key = Addon.NAME:lower()
    local toast = E:GetToast(nil, key, count)
    toast._data[key] = count
    toast.Title:SetText(info.title)
    toast.Text:SetText(info.text or "")
    toast.Icon:SetTexture(info.icon or Addon.TOAST_ICON)
    toast.IconBorder:Show()
    local accent = info.accent or Addon.DefaultToastAccent()
    local colors = C.db.profile.colors
    if colors.border then toast.Border:SetVertexColor(accent[1], accent[2], accent[3]) end
    if colors.icon_border then toast.IconBorder:SetVertexColor(accent[1], accent[2], accent[3]) end
    toast:Spawn(ANCHOR, false)
end

Addon:RegisterToastSkin("lstoasts", skin)
