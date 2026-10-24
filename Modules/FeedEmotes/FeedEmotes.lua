local _, ns = ...

-- A silly /emote every time the hunter feeds the pet, Feed-O-Matic style. FoodTracker.lua tells
-- which food a Feed Pet cast used, Emote.lua builds the text from Lines\<locale>.lua and the
-- player's own lines (CustomLines.lua), and Kennel:SendOnInput sends it on the next key press.
-- Off until switched on: the emotes go out in public chat.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelFeedEmotes
local M = Kennel:NewModule("FeedEmotes")
M.title = L.FEEDEMOTES_TITLE
M.description = L.FEEDEMOTES_DESC
M.requires = { "happiness" } -- Feed Pet went with happiness
M.enabledByDefault = false
M.defaults = {
    profile = { petName = false, customChance = 0, customFallback = true },
    -- petSex: pet number (Kennel.PetNumber) -> Kennel.sex.male or .female, where the player chose.
    char = { sharedLines = false, customLines = {}, petSex = {} },
    global = { customLines = {} },
}

M.FEED_PET = 6991

---The settings of the profile in use.
---@return KennelFeedEmotesSettings
function M:Settings()
    return self.db.profile --[[@as KennelFeedEmotesSettings]]
end

---This character's data.
---@return KennelFeedEmotesChar
function M:Char()
    return self.db.char --[[@as KennelFeedEmotesChar]]
end

---The emote lines in the client's language, English when it has none.
---@return KennelEmoteLines
function M:LinesInUse()
    return self.Lines[GetLocale()] or self.Lines.enUS
end

---The own lines this character uses: the account-wide list when sharing, its own otherwise.
---@return string[]
function M:CustomLines()
    if self:Char().sharedLines then
        return self.db.global.customLines --[[@as string[] ]]
    end
    return self:Char().customLines
end

---The summoned pet's sex: Kennel.sex.male or .female, nil when unknown. The player's choice for
---this pet comes first; WoW: Forever reports unknown for hunter pets.
---@return number?
function M:PetSex()
    local petNumber = Kennel.PetNumber()
    local chosen = petNumber and self:Char().petSex[petNumber]
    if chosen then return chosen end
    local sex = UnitSex("pet")
    if not Kennel.Readable(sex) then return nil end
    return (sex == Kennel.sex.male or sex == Kennel.sex.female) and sex or nil
end

---Saves the player's choice for the summoned pet: 2 male, 3 female, or nil for the game's value.
---Returns false without a pet to save it for.
---@param sex number?
---@return boolean
function M:ChoosePetSex(sex)
    local petNumber = Kennel.PetNumber()
    if not petNumber then return false end
    self:Char().petSex[petNumber] = sex
    return true
end

---Drops the choices of pets this hunter no longer has: a released pet is in neither of the
---stable's lists (Kennel.C.StableInfo). Nothing is dropped while both are empty (the client may
---not have the pets yet, or the stable master is closed on Classic Era), or when a pet has no
---number to go by (hidden, or none on Classic Era).
function M:PrunePetSex()
    local stable = Kennel.C.StableInfo
    ---@type table<number, true>
    local owned = {}
    local any = false
    for _, list in ipairs({ stable.GetActivePetList(), stable.GetStabledPetList() }) do
        for _, pet in ipairs(list) do
            local number = pet.petNumber
            if type(number) ~= "number" or not Kennel.Readable(number) then return end
            owned[number], any = true, true
        end
    end
    if not any then return end
    local petSex = self:Char().petSex
    for petNumber in pairs(petSex) do
        if not owned[petNumber] then petSex[petNumber] = nil end
    end
end

---Builds the emote for one feeding and sends it on the next input; nothing once switched off (a
---cast may still be waiting for the bags then).
---@param itemID number?
function M:Feed(itemID)
    if not self:IsEnabled() then return end
    local text = self:BuildEmote(itemID)
    if text then Kennel:SendOnInput(text, "EMOTE") end
end

-- Food clicked while Feed Pet waits for its target. The hook stays for the session; it only
-- counts while the module is on.
---@param bag number
---@param slot number
local function OnUseContainerItem(bag, slot)
    if M:IsEnabled() and M.watching then M.Tracker:OnTargeted(bag, slot) end
end
hooksecurefunc(C_Container, "UseContainerItem", OnUseContainerItem)

---@param _ string the event
---@param unit string
---@param _castGUID GameValue
---@param spellID GameValue
function M:UNIT_SPELLCAST_SUCCEEDED(_, unit, _castGUID, spellID)
    if unit ~= "player" or not Kennel.Readable(spellID) or spellID ~= M.FEED_PET then return end
    local itemID = self.Tracker:Claim()
    if itemID then
        self:Feed(itemID)
    else
        self.Tracker:WaitForBags(function(eaten)
            self:Feed(eaten)
        end)
    end
end

function M:CURSOR_CHANGED()
    self.Tracker:OnCursorChanged()
end

function M:BAG_UPDATE_DELAYED()
    self.Tracker:OnBagsUpdated()
end

-- The stable lists are filled by now.
function M:PLAYER_ENTERING_WORLD()
    self:PrunePetSex()
end

function M:OnEnable()
    local _, class = UnitClass("player")
    self.watching = class == "HUNTER"
    if not self.watching then return end
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("CURSOR_CHANGED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Tracker:OnBagsUpdated()
end
