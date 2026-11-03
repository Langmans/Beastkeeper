local _, ns = ...

-- The Families tab of Beastkeeper's window (Core\Window.lua): every pet family (Core\Constants\Families.lua), with
-- how many of the hunter's pets are of it; for the chosen one (the pet out's at first) its
-- specialization, diet, the abilities beasts teach it with how many ranks the hunter knows, and the
-- beasts of that family nearest first (BeastMap.lua's Nearest), each with a button that goes there,
-- and the first one's model.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as AddonBeastMap]]

-- The list's rows sit under the line with the grouping and the Rares switch.
local LIST_WIDTH, ROW_HEIGHT, LIST_ROWS = 150, 16, 19
local BEAST_ROWS, BEAST_HEIGHT, MODEL_SIZE = 6, 22, 150
-- A family's abilities, a row each (no family learns more from beasts), and the quest giver's "!"
-- on one with a rank to learn now, as in the Abilities tab.
local ABILITY_ROWS, ABILITY_HEIGHT, ABILITY_WIDTH = 7, 18, 200
local LEARN_ICON, LEARN_SIZE = "Interface\\GossipFrame\\AvailableQuestIcon", 14
local GO_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local CHECK_BOX, CHECK_MARK = "Interface\\Buttons\\UI-CheckBox-Up", "Interface\\Buttons\\UI-CheckBox-Check"
local CHOSEN, OTHER, HEADING = { 1, 1, 1 }, { 0.6, 0.6, 0.6 }, { 1, 0.82, 0 }
-- A Rares item, in the colour of a rare creature's name.
local RARE = { 0.6, 0.45, 1 }

-- The families in list order, a family's beasts, the families of one role, and a family's
-- abilities with each one's count of ranks and of known ranks; refilled for each look.
---@type number[], number[], number[], number[]
local order, beasts, group, abilities = {}, {}, {}, {}
---@type table<number, number>, table<number, number>
local rankCount, knownCount = {}, {}

---@param a number
---@param b number
---@return boolean
local function ByName(a, b)
    return (Addon.FamilyName(a) or "") < (Addon.FamilyName(b) or "")
end

---The families on this client, by name: one Beastkeeper has for one client only (the Fox on WoW:
---Forever, Burning Crusade's on Burning Crusade) only there.
---@return number[]
local function Order()
    wipe(order)
    local client = (LibStub("LibTameable-1.0") --[[@as LibTameable]]):GetClient()
    for familyID, info in pairs(Addon.familyInfo) do
        if not info.client or info.client == client then order[#order + 1] = familyID end
    end
    table.sort(order, ByName)
    return order
end

-- The groups by role, in order; families without a role go under OTHER_ROLE.
local OTHER_ROLE = "other"
local ROLES = { Addon.petSpecs.ferocity, Addon.petSpecs.tenacity, Addon.petSpecs.cunning, OTHER_ROLE }

-- The list's items in order, refilled for each look: what each is ("heading", "family" or
-- "rares") and its value (a role, a family ID, or the group whose rares it shows).
---@type string[], (number|string)[]
local kinds, values = {}, {}

---Adds an item to the list.
---@param kind string
---@param value number|string
local function Add(kind, value)
    kinds[#kinds + 1], values[#values + 1] = kind, value
end

---A family's role, or OTHER_ROLE.
---@param familyID number
---@return string
local function RoleOf(familyID)
    return Addon.FamilyRole(familyID) or OTHER_ROLE
end

---A role's name, for its heading and its rares' card: on the classic clients the category
---(Offense, Defense, General), or Wrath's specialization when the page says so; elsewhere the
---specialization.
---@param role string
---@return string
local function RoleName(role)
    if role == OTHER_ROLE then return L.BEASTMAP_ROLE_OTHER end
    local client = (LibStub("LibTameable-1.0") --[[@as LibTameable]]):GetClient()
    local classic = client == "era" or client == "tbc"
    return Addon.RoleName(role, classic and not M:Settings().familySpecNames)
end

---How strongly a family fills its role on the classic clients: damage for Ferocity, armor and
---health for Tenacity; 0 elsewhere and on WoW: Forever, which has no modifiers.
---@param familyID number
---@return number
local function Strength(familyID)
    local client = (LibStub("LibTameable-1.0") --[[@as LibTameable]]):GetClient()
    local mods = (client == "era" or client == "tbc") and Addon.familyMods[familyID]
    if not mods then return 0 end
    local role = RoleOf(familyID)
    if role == Addon.petSpecs.ferocity then return mods.damage end
    if role == Addon.petSpecs.tenacity then return mods.armor + mods.health end
    return 0
end

---The family's strongest modifier for its role, as the list shows it grouped by role: "+10%
---damage", "+9% armor"; "" without one.
---@param familyID number
---@return string
local function Note(familyID)
    if Strength(familyID) <= 0 then return "" end
    local mods = Addon.familyMods[familyID] --[[@as AddonFamilyMods]]
    if RoleOf(familyID) == Addon.petSpecs.ferocity then return L.FAMILY_DAMAGE:format(mods.damage) end
    if mods.health > mods.armor then return L.FAMILY_HEALTH:format(mods.health) end
    return L.FAMILY_ARMOR:format(mods.armor)
end

---Families in a role: the strongest first, then by name.
---@param a number
---@param b number
---@return boolean
local function Stronger(a, b)
    local strengthA, strengthB = Strength(a), Strength(b)
    if strengthA ~= strengthB then return strengthA > strengthB end
    return ByName(a, b)
end

---Whether a rare beast of the group is in the data: the family's, or a role's families'.
---@param group number|string a family ID or a role
---@param beast AddonBeast
---@return boolean
local function InGroup(group, beast)
    if type(group) == "number" then return beast.family == group end
    return RoleOf(beast.family) == group
end

---Whether the group has a rare beast in the data.
---@param group number|string
---@return boolean
local function HasRares(group)
    for _, beast in
        pairs(Addon.data.beasts --[[@as table<number, AddonBeast>]])
    do
        if beast.rare and InGroup(group, beast) then return true end
    end
    return false
end

---Fills the list's items: by family (each followed by its Rares item), or under each role's
---heading its families, strongest first, and the role's Rares item.
---@param byRole boolean
---@param withRares boolean
local function Items(byRole, withRares)
    wipe(kinds)
    wipe(values)
    local families = Order()
    if not byRole then
        for _, familyID in ipairs(families) do
            Add("family", familyID)
            if withRares and HasRares(familyID) then Add("rares", familyID) end
        end
        return
    end
    for _, role in ipairs(ROLES) do
        wipe(group)
        for _, familyID in ipairs(families) do
            if RoleOf(familyID) == role then group[#group + 1] = familyID end
        end
        if #group > 0 then
            table.sort(group, Stronger)
            Add("heading", role)
            for _, familyID in ipairs(group) do
                Add("family", familyID)
            end
            if withRares and HasRares(role) then Add("rares", role) end
        end
    end
end

---How many of the hunter's pets in the Pet Journal are of the family; 0 while it is off.
---@param familyID number
---@return number
local function PetCount(familyID)
    local journal = Addon:GetModule("PetJournal", true) --[[@as AddonPetJournal?]]
    if not journal or not journal:IsEnabled() then return 0 end
    local name, count = Addon.FamilyName(familyID), 0
    for _, entry in pairs(journal:Pets()) do
        if entry.family == name then count = count + 1 end
    end
    return count
end

---Whether a rank can be learned by the family: its list names it, or names none (every family).
---@param rank AddonPetAbilityRank
---@param familyID number
---@return boolean
local function ForFamily(rank, familyID)
    if #rank.families == 0 then return true end
    for _, id in ipairs(rank.families) do
        if id == familyID then return true end
    end
    return false
end

---@param a number
---@param b number
---@return boolean
local function ByAbilityName(a, b)
    return M.AbilityName(a) < M.AbilityName(b)
end

---The abilities beasts teach the family, by name, with per ability how many of the family's ranks
---there are and how many the hunter knows (in rankCount and knownCount).
---@param familyID number
---@return number[]
local function FamilyAbilities(familyID)
    wipe(abilities)
    wipe(rankCount)
    wipe(knownCount)
    local ranks = Addon.data.petAbilityRanks --[[@as table<number, AddonPetAbilityRank>]]
    for spellID, rank in pairs(ranks) do
        if ForFamily(rank, familyID) then
            local ability = rank.ability
            if not rankCount[ability] then abilities[#abilities + 1] = ability end
            rankCount[ability] = (rankCount[ability] or 0) + 1
            knownCount[ability] = (knownCount[ability] or 0) + (M.Lacking(spellID) and 0 or 1)
        end
    end
    table.sort(abilities, ByAbilityName)
    return abilities
end

---Fills the ability rows from the family's abilities; hides the rest.
---@param panel AddonFamiliesPanel
---@param familyID number?
local function FillAbilities(panel, familyID)
    local list = familyID and FamilyAbilities(familyID) or wipe(abilities)
    for index, row in ipairs(panel.abilityRows) do
        local ability = list[index] ---@type number?
        row.ability = ability
        row:SetShown(ability ~= nil)
        if ability then
            row.icon:SetTexture(M.AbilityIcon(ability))
            row.label:SetText(M.AbilityName(ability))
            row.count:SetText(L.BEASTMAP_ABILITY_COUNT:format(knownCount[ability], rankCount[ability]))
            row.learnable:SetShown(M.AnyLearnable(ability))
        end
    end
end

---The group's beasts in the data, nearest first: a family's, or with `raresOnly` the rares of a
---family or a role.
---@param group number|string a family ID or a role
---@param raresOnly boolean?
---@return number[]
local function Beasts(group, raresOnly)
    wipe(beasts)
    local all = Addon.data.beasts --[[@as table<number, AddonBeast>]]
    for npc, beast in pairs(all) do
        if InGroup(group, beast) and (beast.rare or not raresOnly) then beasts[#beasts + 1] = npc end
    end
    return M.Nearest(beasts)
end

---The diet line: "Eats: Meat, Fish"; empty when Beastkeeper does not know it.
---@param info AddonFamilyInfo
---@return string
local function DietText(info)
    if not info.diet then return "" end
    ---@type string[]
    local foods = {}
    for i, food in ipairs(info.diet) do
        foods[i] = L["BEASTMAP_FOOD_" .. food:upper()]
    end
    return L.BEASTMAP_EATS:format(table.concat(foods, ", "))
end

---A text in the skin's font.
---@param parent Frame
---@param skin AddonButtonHolderSkin
---@param template string?
---@param size number?
---@return FontString
local function Text(parent, skin, template, size)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    text:SetJustifyH("LEFT")
    skin.Font(text, size or 12)
    return text
end

---A family's portrait, cropped as the look crops icons (Beastkeeper:CropIcon).
---@param parent Frame
---@param skin AddonButtonHolderSkin
---@param size number
---@return Texture
local function Portrait(parent, skin, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size)
    Addon:CropIcon(icon, skin.CropIcon)
    return icon
end

---A row clicked: a family shows its card, a Rares item its group's rares; a heading does nothing.
---@param row AddonFamilyRow
local function OnRowClick(row)
    local list = row:GetParent() --[[@as Frame]]
    local panel = list:GetParent() --[[@as AddonFamiliesPanel]]
    if row.familyID then
        panel.chosen, panel.chosenRares = row.familyID, nil
    elseif row.rares then
        panel.chosenRares = row.rares
    else
        return
    end
    Addon:RefreshWindow("families")
end

---Family or Role clicked: the list grouped so, kept in the profile.
---@param button AddonTextButton
local function OnGroupClick(button)
    M:Settings().familyGroup = button.value --[[@as "family"|"role"]]
    local panel = button:GetParent() --[[@as AddonFamiliesPanel]]
    panel.chosenRares, panel.offset = nil, 0
    Addon:RefreshWindow("families")
end

---The Rares switch clicked: a Rares item in each group, or none; kept in the profile.
---@param button AddonCheckText
local function OnRaresClick(button)
    local settings = M:Settings()
    settings.familyRares = not settings.familyRares
    local panel = button:GetParent() --[[@as AddonFamiliesPanel]]
    panel.chosenRares = nil
    Addon:RefreshWindow("families")
end

---The mouse wheel over the list: scrolls it, within its items.
---@param list Frame
---@param delta number
local function OnWheel(list, delta)
    local panel = list:GetParent() --[[@as AddonFamiliesPanel]]
    panel.offset = math.max(0, math.min(#kinds - LIST_ROWS, panel.offset - delta))
    Addon:RefreshWindow("families")
end

---A word to click above the list.
---@param panel AddonFamiliesPanel
---@param skin AddonButtonHolderSkin
---@param text string
---@return Button, FontString
local function Clickable(panel, skin, text)
    local button = CreateFrame("Button", nil, panel)
    local label = Text(button, skin)
    label:SetPoint("LEFT")
    label:SetText(text)
    button:SetSize(label:GetStringWidth() + 4, ROW_HEIGHT)
    return button, label
end

local function OnAbilityLeave()
    GameTooltip:Hide()
end

---An ability clicked: its teachers in the Abilities tab.
---@param row AddonFamilyAbilityRow
local function OnAbilityClick(row)
    M:ShowAbility(row.ability --[[@as number]])
end

---A row of the family's abilities, under its diet: icon, name, the "!" and "known/total", as in
---the Abilities tab's list, with that tab's tooltip.
---@param panel AddonFamiliesPanel
---@param skin AddonButtonHolderSkin
---@param index number
---@return AddonFamilyAbilityRow
local function AbilityRow(panel, skin, index)
    local row = CreateFrame("Button", nil, panel) --[[@as AddonFamilyAbilityRow]]
    row:SetSize(ABILITY_WIDTH, ABILITY_HEIGHT)
    row:SetPoint("TOPLEFT", panel.diet, "BOTTOMLEFT", 0, -8 - (index - 1) * ABILITY_HEIGHT)
    row.icon = Portrait(row, skin, ABILITY_HEIGHT - 2)
    row.icon:SetPoint("LEFT")
    row.label = Text(row, skin)
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.count = Text(row, skin)
    row.count:SetPoint("RIGHT", -4, 0)
    row.learnable = row:CreateTexture(nil, "OVERLAY")
    row.learnable:SetSize(LEARN_SIZE, LEARN_SIZE)
    row.learnable:SetTexture(LEARN_ICON)
    row.learnable:SetPoint("RIGHT", row.count, "LEFT", -2, 0)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnClick", OnAbilityClick)
    row:SetScript("OnEnter", M.OnAbilityEnter)
    row:SetScript("OnLeave", OnAbilityLeave)
    return row
end

---Builds the line above the list: Family and Role to group by, and the Rares switch.
---@param panel AddonFamiliesPanel
---@param skin AddonButtonHolderSkin
local function CreateHeader(panel, skin)
    panel.groupBy = {}
    ---@type Region?
    local before
    for index, value in ipairs({ "family", "role" }) do
        local button, label = Clickable(panel, skin, L["BEASTMAP_GROUP_" .. value:upper()])
        local word = button --[[@as AddonTextButton]]
        word.label, word.value = label, value
        if before then
            word:SetPoint("LEFT", before, "RIGHT", 6, 0)
        else
            word:SetPoint("TOPLEFT", 4, 0)
        end
        word:SetScript("OnClick", OnGroupClick)
        panel.groupBy[index], before = word, word
    end
    local button, label = Clickable(panel, skin, L.BEASTMAP_RARES)
    local rares = button --[[@as AddonCheckText]]
    rares.label = label
    label:SetPoint("LEFT", ROW_HEIGHT, 0)
    rares:SetWidth(label:GetStringWidth() + ROW_HEIGHT + 4)
    local box = rares:CreateTexture(nil, "ARTWORK")
    box:SetTexture(CHECK_BOX)
    box:SetSize(ROW_HEIGHT, ROW_HEIGHT)
    box:SetPoint("LEFT")
    rares.check = rares:CreateTexture(nil, "OVERLAY")
    rares.check:SetTexture(CHECK_MARK)
    rares.check:SetAllPoints(box)
    rares:SetPoint("LEFT", before, "RIGHT", 12, 0)
    rares:SetScript("OnClick", OnRaresClick)
    panel.rares = rares
end

---Builds the panel: the line above the list, the list's rows, the card's texts, the beasts' rows
---and the model.
---@param panel AddonFamiliesPanel
---@param skin AddonButtonHolderSkin
local function Create(panel, skin)
    panel.rows, panel.beasts, panel.offset = {}, {}, 0
    CreateHeader(panel, skin)
    panel.list = CreateFrame("Frame", nil, panel)
    panel.list:SetSize(LIST_WIDTH, LIST_ROWS * ROW_HEIGHT)
    panel.list:SetPoint("TOPLEFT", 0, -(ROW_HEIGHT + 4))
    panel.list:EnableMouseWheel(true)
    panel.list:SetScript("OnMouseWheel", OnWheel)
    for index = 1, LIST_ROWS do
        local row = CreateFrame("Button", nil, panel.list) --[[@as AddonFamilyRow]]
        row:SetSize(LIST_WIDTH, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row.icon = Portrait(row, skin, ROW_HEIGHT - 4)
        row.icon:SetPoint("LEFT", 4, 0)
        row.label = Text(row, skin)
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
        row.note = Text(row, skin, nil, 10)
        row.note:SetPoint("RIGHT", -2, 0)
        row.note:SetTextColor(OTHER[1], OTHER[2], OTHER[3])
        -- A long name ("Wind Serpent") is cut short before the note instead of running under it.
        row.label:SetPoint("RIGHT", row.note, "LEFT", -4, 0)
        row.label:SetWordWrap(false)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:SetScript("OnClick", OnRowClick)
        panel.rows[index] = row
    end
    local left = LIST_WIDTH + 16
    panel.model = CreateFrame("PlayerModel", nil, panel)
    panel.model:SetSize(MODEL_SIZE, MODEL_SIZE)
    panel.model:SetPoint("TOPRIGHT")
    panel.titleIcon = Portrait(panel, skin, 20)
    panel.titleIcon:SetPoint("TOPLEFT", left, 0)
    panel.title = Text(panel, skin, "GameFontNormalLarge", 16)
    panel.title:SetPoint("LEFT", panel.titleIcon, "RIGHT", 6, 0)
    panel.spec = Text(panel, skin, "GameFontNormal")
    panel.spec:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4)
    panel.diet = Text(panel, skin)
    panel.diet:SetPoint("TOPLEFT", panel.spec, "BOTTOMLEFT", 0, -4)
    panel.abilityRows = {}
    for index = 1, ABILITY_ROWS do
        panel.abilityRows[index] = AbilityRow(panel, skin, index)
    end
    panel.none = Text(panel, skin)
    panel.none:SetPoint("BOTTOMLEFT", left, BEAST_ROWS * BEAST_HEIGHT + 4)
    for index = 1, BEAST_ROWS do
        local row = CreateFrame("Frame", nil, panel) --[[@as AddonFamilyBeastRow]]
        row:SetHeight(BEAST_HEIGHT)
        row:SetPoint("BOTTOMLEFT", left, (BEAST_ROWS - index) * BEAST_HEIGHT)
        row:SetPoint("RIGHT")
        row.text = Text(row, skin)
        row.text:SetPoint("LEFT")
        row.go = CreateFrame("Button", nil, row)
        row.go:SetSize(BEAST_HEIGHT - 4, BEAST_HEIGHT - 4)
        row.go:SetPoint("RIGHT")
        row.go:SetNormalTexture(GO_ICON)
        row.go:SetScript("OnClick", function()
            M:GoToBeast(row.npc --[[@as number]])
        end)
        panel.beasts[index] = row
    end
end

---Fills the beasts' rows and the model from the group's beasts: a family's, or a group's rares.
---@param panel AddonFamiliesPanel
---@param group number|string
---@param raresOnly boolean?
local function FillBeasts(panel, group, raresOnly)
    local list = Beasts(group, raresOnly)
    for index, row in ipairs(panel.beasts) do
        local npc = list[index]
        row.npc = npc
        row:SetShown(npc ~= nil)
        if npc then
            local beast = Addon.data.beasts[npc] --[[@as AddonBeast]]
            row.text:SetText(L.BEASTMAP_TEACHER_LINE:format(M.Place(npc), M.LevelText(beast)))
            row.go:SetShown(beast.pins ~= nil)
        end
    end
    panel.none:SetText(#list == 0 and L.BEASTMAP_NO_BEASTS or "")
    -- By display ID the model shows at once; by NPC ID only once the client has the creature in its
    -- cache, else the old model stays: so cleared first.
    local first = list[1] and Addon.data.beasts[list[1]]
    if first then
        panel.model:ClearModel()
        if first.display then
            panel.model:SetDisplayInfo(first.display)
        else
            panel.model:SetCreature(list[1])
        end
        panel.model:Show()
    else
        panel.model:Hide()
    end
end

---Fills a row of the list from the item at `index`; hides it past the end.
---@param panel AddonFamiliesPanel
---@param row AddonFamilyRow
---@param index number
---@param byRole boolean
local function FillRow(panel, row, index, byRole)
    local kind, value = kinds[index], values[index]
    row:SetShown(kind ~= nil)
    row.heading = kind == "heading" or nil
    row.familyID = kind == "family" and value --[[@as number]] or nil
    row.rares = kind == "rares" and value or nil
    row.note:SetText("")
    row.icon:SetShown(kind == "family")
    ---@type number[]
    local colour
    if kind == "heading" then
        row.label:SetText(RoleName(value --[[@as string]]))
        colour = HEADING
    elseif kind == "rares" then
        row.label:SetText(L.BEASTMAP_RARES)
        colour = value == panel.chosenRares and CHOSEN or RARE
    elseif kind == "family" then
        local familyID = value --[[@as number]]
        local name, count = Addon.FamilyName(familyID) or "?", PetCount(familyID)
        row.label:SetText(count > 0 and L.BEASTMAP_FAMILY_ROW:format(name, count) or name)
        row.icon:SetTexture(Addon.FamilyIcon(familyID))
        if byRole then row.note:SetText(Note(familyID)) end
        colour = familyID == panel.chosen and not panel.chosenRares and CHOSEN or OTHER
    else
        return
    end
    row.label:SetTextColor(colour[1], colour[2], colour[3])
end

---Fills the card with a group's rares: its title, and the rares nearest first.
---@param panel AddonFamiliesPanel
---@param group number|string
local function FillRares(panel, group)
    local isFamily = type(group) == "number"
    local name = isFamily and (
            Addon.FamilyName(group --[[@as number]]) or "?"
        ) or RoleName(group --[[@as string]])
    panel.title:SetText(L.BEASTMAP_RARES_OF:format(name))
    panel.titleIcon:SetTexture(isFamily and Addon.FamilyIcon(group --[[@as number]]) or nil)
    panel.spec:SetText("")
    panel.diet:SetText("")
    FillAbilities(panel, nil)
    FillBeasts(panel, group, true)
end

---Fills the list and the card: the chosen family's, or the rares of the Rares item chosen.
---@param panel AddonFamiliesPanel
local function Refresh(panel)
    local settings = M:Settings()
    local byRole = settings.familyGroup == "role"
    if not settings.familyRares then panel.chosenRares = nil end
    Items(byRole, settings.familyRares)
    panel.offset = math.max(0, math.min(#kinds - LIST_ROWS, panel.offset))
    for index, word in ipairs(panel.groupBy) do
        local colour = (index == 2) == byRole and HEADING or OTHER
        word.label:SetTextColor(colour[1], colour[2], colour[3])
    end
    panel.rares.check:SetShown(settings.familyRares)
    if not panel.chosen then
        local out = Addon.PetFamilyID()
        panel.chosen = out and Addon.familyInfo[out] and out or Order()[1]
    end
    for index, row in ipairs(panel.rows) do
        FillRow(panel, row, index + panel.offset, byRole)
    end
    if panel.chosenRares then
        FillRares(panel, panel.chosenRares)
        return
    end
    local familyID = panel.chosen --[[@as number]]
    local info = Addon.familyInfo[familyID]
    panel.title:SetText(Addon.FamilyName(familyID) or "?")
    panel.titleIcon:SetTexture(Addon.FamilyIcon(familyID))
    panel.spec:SetText(Addon.FamilyLine(familyID))
    panel.diet:SetText(DietText(info))
    FillAbilities(panel, familyID)
    FillBeasts(panel, familyID)
end

Addon:RegisterWindowTab({
    id = "families",
    title = L.BEASTMAP_TAB_FAMILIES,
    order = 30,
    module = "BeastMap",
    Create = Create,
    Refresh = Refresh,
})
