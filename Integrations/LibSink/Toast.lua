local _, ns = ...

-- An instant skin: hands a toast to LibSink, which sends it where the player picks (Blizzard's
-- floating text by default, chat, raid warning, MikSBT, ...). The pick is LibSink's own options
-- group, kept in profile.toast.sink.

local LibSink = LibStub("LibSink-2.0", true) --[[@as LibSinkLibrary?]]
if not LibSink then return end

---@type Addon
local Addon = ns
local L = Addon.L

-- LibSink's methods on a table of its own: LibSink keeps each addon's output choice by that table.
local output = LibSink:Embed({})

---Points LibSink at the profile in use, before it reads or writes the choice.
local function UseProfile()
    LibSink.SetSinkStorage(output, Addon:ToastSettings().sink)
end

-- Show and GetOptions follow.
local skin = { name = L.TOAST_SKIN_LIBSINK, instant = true } --[[@as AddonToastSkin]]

---@param info AddonToastInfo
function skin:Show(info)
    UseProfile()
    local accent = info.accent or Addon.DefaultToastAccent()
    local text = info.text and info.title .. ": " .. info.text or info.title
    output:Pour(text, accent[1], accent[2], accent[3], nil, nil, nil, nil, nil, info.icon)
end

---LibSink's output choice.
---@return table
function skin:GetOptions()
    UseProfile()
    return output:GetSinkAce3OptionsDataTable()
end

Addon:RegisterToastSkin("libsink", skin)
