local _, ns = ...

-- Kennel.C: the modern pet, spellbook and tooltip API under Kennel's own name, so a module writes
-- against one API on every client. Each function is the client's own where it has one (WoW:
-- Forever), else the classic way: Classic Era's globals, a scan of a hidden tooltip, the pet
-- family's diet. Looked up on each call, never written into the game's shared C_ tables: another
-- addon must not take Kennel's stand-ins for the client's.

---@type Kennel
local Kennel = ns

---@type KennelCompat
local C = { PetInfo = {}, SpellBook = {}, TooltipInfo = {}, StableInfo = {} } --[[@as KennelCompat]]
Kennel.C = C

---The client's C_PetInfo function `name`, nil without it.
---@param name string
---@return function?
local function PetInfo(name)
    return C_PetInfo and C_PetInfo[name]
end

---The client's C_SpellBook function `name`, nil without it.
---@param name string
---@return function?
local function SpellBook(name)
    return C_SpellBook and C_SpellBook[name]
end

---The client's C_TooltipInfo function `name`, nil without it.
---@param name string
---@return function?
local function TooltipInfo(name)
    return C_TooltipInfo and C_TooltipInfo[name]
end

-- Per function Has can answer for: whether the client has what it needs.
---@type table<string, table<string, fun(): boolean>>
local HAS = {
    PetInfo = {
        GetPetHappiness = function()
            return (PetInfo("GetPetHappiness") or GetPetHappiness) ~= nil
        end,
        GetPetTrainingPoints = function()
            return (PetInfo("GetPetTrainingPoints") or GetPetTrainingPoints) ~= nil
        end,
        GetPetLoyalty = function()
            return (PetInfo("GetPetLoyalty") or GetPetLoyalty) ~= nil
        end,
        -- The family's diet stands in everywhere.
        CanPetEatItem = function()
            return true
        end,
    },
}

---Whether the client has what Kennel.C.<namespace>.<name> needs, its own or the classic way.
---@param namespace "PetInfo"
---@param name string
---@return boolean
function C.Has(namespace, name)
    local has = HAS[namespace][name]
    return has ~= nil and has()
end

---The pet's happiness; nil without the API.
---@return GameValue happiness
function C.PetInfo.GetPetHappiness()
    ---@type (fun(): GameValue)?
    local get = PetInfo("GetPetHappiness") or GetPetHappiness
    if get then return (get()) end
end

---The pet's training points: total and used; nil without the API.
---@return GameValue total
---@return GameValue used
function C.PetInfo.GetPetTrainingPoints()
    ---@type (fun(): GameValue, GameValue)?
    local get = PetInfo("GetPetTrainingPoints") or GetPetTrainingPoints
    if get then return get() end
    return nil, nil
end

---The pet's loyalty as the client words it: WoW: Forever the bare name, Classic "Loyalty Level 4
---(Dependable)"; nil without the API.
---@return GameValue loyalty
function C.PetInfo.GetPetLoyalty()
    ---@type (fun(): GameValue)?
    local get = PetInfo("GetPetLoyalty") or GetPetLoyalty
    if get then return (get()) end
end

-- The food types, refilled for each call on a client whose global gives them as separate values.
---@type string[]
local foodTypes = {}

---The food types the pet out eats, as the client names them: a list on every client.
---@return string[]
function C.PetInfo.GetPetFoodTypes()
    ---@type (fun(): string[]?)?
    local modern = PetInfo("GetPetFoodTypes")
    if modern then return modern() or foodTypes end
    wipe(foodTypes)
    if GetPetFoodTypes then
        for i, foodType in ipairs({ GetPetFoodTypes() }) do
            foodTypes[i] = foodType --[[@as string]]
        end
    end
    return foodTypes
end

---Whether the pet out eats an item: the client says so on WoW: Forever; elsewhere the item's kind
---of food (Data\Era\Food.lua) must be on its family's diet (Kennel.familyInfo).
---@param itemID number
---@return boolean
function C.PetInfo.CanPetEatItem(itemID)
    ---@type (fun(itemID: number): GameValue)?
    local modern = PetInfo("CanPetEatItem")
    if modern then return modern(itemID) == true end
    local kind = Kennel.data.foodKinds[itemID]
    local info = kind and Kennel.familyInfo[Kennel.PetFamilyID() or 0]
    return info ~= nil and info.diet ~= nil and tContains(info.diet, kind)
end

---How many entries the pet's spellbook has; nil without the API.
---@return GameValue count
function C.SpellBook.HasPetSpells()
    ---@type (fun(): GameValue)?
    local get = SpellBook("HasPetSpells") or HasPetSpells
    if get then return (get()) end
end

---Whether the player knows a spell; nil on a client that cannot tell.
---@param spellID number
---@return boolean?
function C.SpellBook.IsSpellKnown(spellID)
    ---@type (fun(spellID: number): GameValue)?
    local known = SpellBook("IsSpellKnown") or IsSpellKnown
    if known then return known(spellID) == true end
end

---Classic's book type for a spellbook bank.
---Kennel reads only the pet's book: on Classic its book type, whatever the bank.
---@param _ number the bank
---@return string
local function BookType(_)
    return BOOKTYPE_PET or "pet"
end

-- The entry Classic's GetSpellBookItemName fills, refilled for each call.
---@type KennelBookItem
local bookItem = { name = nil, subName = nil, spellID = nil }

---A spellbook entry: its name, rank text and spell ID; a command has a name only. On Classic the
---same table each time, refilled. Nil for an entry the client lacks.
---@param index number
---@param bank number Enum.SpellBookSpellBank
---@return KennelBookItem?
function C.SpellBook.GetSpellBookItemInfo(index, bank)
    ---@type (fun(index: number, bank: number): KennelBookItem?)?
    local modern = SpellBook("GetSpellBookItemInfo")
    if modern then return modern(index, bank) end
    if not GetSpellBookItemName then return nil end
    ---@type GameValue, GameValue, GameValue
    local name, subName, spellID = GetSpellBookItemName(index, BookType(bank))
    if not name then return nil end
    bookItem.name, bookItem.subName, bookItem.spellID = name, subName, spellID
    return bookItem
end

---Whether a spellbook entry can autocast and whether it does.
---@param index number
---@param bank number Enum.SpellBookSpellBank
---@return GameValue allowed
---@return GameValue enabled
function C.SpellBook.GetSpellBookItemAutoCast(index, bank)
    ---@type (fun(index: number, bank: number): GameValue, GameValue)?
    local modern = SpellBook("GetSpellBookItemAutoCast")
    if modern then return modern(index, bank) end
    if GetSpellAutocast then return GetSpellAutocast(index, BookType(bank)) end
    return nil, nil
end

-- What GetItemByID gives on a client without C_TooltipInfo: the same table each time, its lines
-- reused from read to read.
---@type KennelTooltipData, {leftText: GameValue}[]
local itemInfo, linePool = { lines = {} }, {}
-- A tooltip of Kennel's own to read an item's lines from; made the first time it is needed.
---@type GameTooltip?
local scanner

---An item's tooltip lines. Read off a hidden tooltip where the client has no C_TooltipInfo: then
---the same table each time, refilled. No lines while the client has not loaded the item.
---@param itemID number
---@return KennelTooltipData
function C.TooltipInfo.GetItemByID(itemID)
    ---@type (fun(itemID: number): KennelTooltipData?)?
    local modern = TooltipInfo("GetItemByID")
    if modern then return modern(itemID) or itemInfo end
    wipe(itemInfo.lines)
    scanner = scanner or CreateFrame("GameTooltip", "KennelScanTooltip", nil, "GameTooltipTemplate") --[[@as GameTooltip]]
    scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetItemByID(itemID)
    for i = 1, scanner:NumLines() do
        local region = _G["KennelScanTooltipTextLeft" .. i] --[[@as FontString?]]
        local text = region and region:GetText()
        if text then
            local line = linePool[i] or {}
            linePool[i], line.leftText = line, text
            itemInfo.lines[#itemInfo.lines + 1] = line
        end
    end
    return itemInfo
end

-- Classic Era's stable read into the modern lists' shape, reused from read to read: the current
-- pet (slot 1, also while dismissed) and the stabled ones (slot 2 on). Without pet numbers.
---@type KennelStablePet[], KennelStablePet[], KennelStablePet[]
local activePets, stabledPets, petPool = {}, {}, {}

---Fills `list` from Classic's GetStablePetInfo slots `first` to `last`.
---@param list KennelStablePet[]
---@param first number
---@param last number
---@return KennelStablePet[]
local function ReadSlots(list, first, last)
    wipe(list)
    if not GetStablePetInfo then return list end
    for slot = first, last do
        local icon, name, level, family, loyalty = GetStablePetInfo(slot)
        if name then
            local pet = petPool[slot] or {}
            petPool[slot] = pet
            pet.slotID, pet.icon, pet.name, pet.level, pet.familyName = slot, icon, name, level, family
            pet.loyaltyText = loyalty
            list[#list + 1] = pet
        end
    end
    return list
end

---The pets out or ready to call: C_StableInfo's anywhere on WoW: Forever; on Classic Era the
---current pet while the stable master is open, without its number.
---@return KennelStablePet[]
function C.StableInfo.GetActivePetList()
    ---@type (fun(): KennelStablePet[])?
    local modern = C_StableInfo and C_StableInfo.GetActivePetList
    if modern then return modern() end
    return ReadSlots(activePets, 1, 1)
end

---The pets in the stable: C_StableInfo's anywhere on WoW: Forever; on Classic Era the stable's
---slots while the stable master is open, without their numbers.
---@return KennelStablePet[]
function C.StableInfo.GetStabledPetList()
    ---@type (fun(): KennelStablePet[])?
    local modern = C_StableInfo and C_StableInfo.GetStabledPetList
    if modern then return modern() end
    return ReadSlots(stabledPets, 2, 1 + (GetNumStableSlots and GetNumStableSlots() or 0))
end

---A hyperlink's tooltip data; nil on a client without C_TooltipInfo (Classic Era).
---@param link string
---@return KennelTooltipData?
function C.TooltipInfo.GetHyperlink(link)
    ---@type (fun(link: string): KennelTooltipData?)?
    local modern = TooltipInfo("GetHyperlink")
    if modern then return modern(link) end
end
