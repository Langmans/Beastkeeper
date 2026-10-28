local _, ns = ...

-- A LibSink output that says a toast in a chat channel through MessageQueue: WoW: Forever only
-- lets an addon send SAY, YELL and channel messages as part of something the player does, so
-- MessageQueue holds them until the next key press or click. Registered when both LibSink and
-- MessageQueue are loaded. LibSink's own Channel output keeps its own copy of the game's
-- SendChatMessage, so it cannot be pointed at MessageQueue; this output mirrors it instead, with
-- the same channel list.

local LibSink = LibStub("LibSink-2.0", true) --[[@as LibSinkLibrary?]]
local MQ = MessageQueue --[[@as MessageQueueApi?]]
if not LibSink or not MQ then return end

---@type Addon
local Addon = ns
local L = Addon.L

---The chat channel names LibSink offers (Say, Party, Group, the custom channels), as scroll areas.
---@return string[]
local function Channels()
    ---@type string[]
    local names = {}
    for name in pairs(LibSink.channelMapping) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

---The chat type for "Group": the instance group, a raid, a party, or Say alone.
---@return string
local function GroupChat()
    return (IsInGroup(2) and "INSTANCE_CHAT") or (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or "SAY"
end

---Says `text` in the channel the addon chose, colours and icons taken out.
---@param addon table the LibSink user whose choice applies
---@param text string
local function Say(addon, text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x(.-)|r", "%1"):gsub("|T.-|t%s*", "")
    local storage = LibSink.storageForAddon[addon]
    local location = storage and storage.sink20ScrollArea
    local chat = LibSink.channelMapping[location]
    if chat == "GROUP" then
        chat = GroupChat()
    elseif chat == "CHANNEL" then
        local id = GetChannelName(LibSink.channelMappingIds[location])
        if id then MQ.SendChatMessage(text, "CHANNEL", nil, id) end
        return
    end
    MQ.SendChatMessage(text, chat or "SAY")
end

LibSink:RegisterSink(Addon.Global("MessageQueue"), L.SINK_MESSAGEQUEUE, L.SINK_MESSAGEQUEUE_DESC, Say, Channels)
