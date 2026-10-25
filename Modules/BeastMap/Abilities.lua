local _, ns = ...

-- The Abilities tab of Kennel's window (Core\Window.lua): every pet ability beasts teach, with how
-- many of its ranks the hunter knows; for the chosen one every rank with its pet level, and
-- whether the hunter knows it or which beast teaches it, nearest first (BeastMap.lua's Nearest):
-- the beast's place, the travel time when a route addon gives one, and in a column of its own how
-- many more teach it. A rank's button sends the hunter there; its tooltip lists every teacher.
-- Each rank keeps to one line (a long place is cut short; the tooltip has it whole), every other
-- row striped, under column heads; the chosen ability has a bar in the look's accent.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("BeastMap") --[[@as KennelBeastMap]]

local LIST_WIDTH, ROW_HEIGHT, LIST_ROWS = 170, 18, 21
local RANK_ROWS, RANK_HEIGHT, RANK_WIDTH, LEVEL_WIDTH, MORE_WIDTH = 12, 22, 64, 64, 30
local RANKS_TOP, HEADER_TOP = 46, 26
-- The pet level column, right-aligned, with room before the teacher.
local LEVEL_COLUMN = LEVEL_WIDTH - 14
local GO_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local KNOWN, MISSING, DIM, ABOVE = { 0.25, 1, 0.25 }, { 1, 1, 1 }, { 0.6, 0.6, 0.6 }, { 1, 0.6, 0.3 }
local GOLD = { 1, 0.82, 0 }

-- Per ability (its rank 1's spell ID), its rank spells in rank order; built the first time.
---@type table<number, number[]>?
local groups
-- The abilities in list order, refilled for each look.
---@type number[]
local order = {}

---Two rank spells of one ability in rank order.
---@param a number
---@param b number
---@return boolean
local function ByRank(a, b)
    local ranks = Kennel.data.petAbilityRanks
    return ranks[a].rank < ranks[b].rank
end

---Per ability, its rank spells in order.
---@return table<number, number[]>
local function Groups()
    if groups then return groups end
    ---@type table<number, number[]>
    local built = {}
    local ranks = Kennel.data.petAbilityRanks --[[@as table<number, KennelPetAbilityRank>]]
    for spellID, rank in pairs(ranks) do
        built[rank.ability] = built[rank.ability] or {}
        table.insert(built[rank.ability], spellID)
    end
    for _, spells in pairs(built) do
        table.sort(spells, ByRank)
    end
    groups = built
    return built
end

---An ability's name as the client words it; "?" when it cannot.
---@param ability number
---@return string
local function AbilityName(ability)
    return Kennel.SpellInfo(ability) or "?"
end

---An ability's icon; the question mark when the client cannot say.
---@param ability number
---@return number|string
local function AbilityIcon(ability)
    local _, icon = Kennel.SpellInfo(ability)
    return icon or 134400
end

---@param a number
---@param b number
---@return boolean
local function ByName(a, b)
    return AbilityName(a) < AbilityName(b)
end

---The abilities, by name.
---@return number[]
local function Order()
    wipe(order)
    for ability in pairs(Groups()) do
        order[#order + 1] = ability
    end
    table.sort(order, ByName)
    return order
end

---How many of an ability's ranks the hunter knows.
---@param ability number
---@return number known
---@return number total
local function Counts(ability)
    local spells = Groups()[ability]
    local known = 0
    for _, spellID in ipairs(spells) do
        if not M.Lacking(spellID) then known = known + 1 end
    end
    return known, #spells
end

---The text of a missing rank's row: the nearest teacher's place, its travel time, whether it is
---above the hunter's level (and so whether it is).
---@param teachers number[] in the window's order
---@return string text
---@return boolean above
local function TeacherText(teachers)
    local best = teachers[1]
    local parts = { M.Place(best) }
    local seconds = M.TravelTimeTo(best)
    if seconds then parts[#parts + 1] = L.BEASTMAP_TRAVEL:format(math.max(1, math.floor(seconds / 60 + 0.5))) end
    local above = Kennel.data.beasts[best].minLevel > M:PlayerLevel()
    if above then parts[#parts + 1] = L.BEASTMAP_ABOVE end
    return table.concat(parts, ", "), above
end

---A rank's tooltip: every teacher in order, with its level.
---@param row KennelRankRow
local function OnEnter(row)
    if not row.teachers then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(M.RankText(row.spellID --[[@as number]]) or "?")
    for _, npc in ipairs(row.teachers) do
        local line = L.BEASTMAP_TEACHER_LINE:format(M.Place(npc), M.LevelText(Kennel.data.beasts[npc]))
        GameTooltip:AddLine(line, 1, 1, 1)
    end
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

---A go button's tooltip: the beast it leads to.
---@param go Button
local function OnGoEnter(go)
    local row = go:GetParent() --[[@as KennelRankRow]]
    GameTooltip:SetOwner(go, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.BEASTMAP_GO:format(M.BeastName(row.best --[[@as number]])))
    GameTooltip:Show()
end

---A text in the skin's font, on one line.
---@param parent Frame
---@param skin KennelButtonHolderSkin
---@param justify string? "LEFT" by default
---@return FontString
local function Text(parent, skin, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetJustifyH(justify or "LEFT")
    text:SetWordWrap(false)
    skin.Font(text, 12)
    return text
end

---An icon trimmed of its border, as the game's own buttons show icons.
---@param icon Texture
local function Crop(icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

---An ability's icon, cropped as the look crops icons.
---@param parent Frame
---@param skin KennelButtonHolderSkin
---@param size number
---@return Texture
local function Icon(parent, skin, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size)
    local crop = skin.CropIcon or Crop
    crop(icon)
    return icon
end

---A row of the abilities' list: its icon and name, how many ranks are known, a bar when chosen.
---@param panel KennelAbilitiesPanel
---@param skin KennelButtonHolderSkin
---@param index number
---@return KennelAbilityRow
local function AbilityRow(panel, skin, index)
    local row = CreateFrame("Button", nil, panel) --[[@as KennelAbilityRow]]
    row:SetSize(LIST_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    local accent = skin.Accent and skin.Accent() or GOLD
    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetAllPoints()
    row.selected:SetColorTexture(accent[1], accent[2], accent[3], 0.2)
    row.icon = Icon(row, skin, ROW_HEIGHT - 4)
    row.icon:SetPoint("LEFT", 4, 0)
    row.label = Text(row, skin)
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.count = Text(row, skin, "RIGHT")
    row.count:SetPoint("RIGHT", -6, 0)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnClick", function()
        panel.chosen = row.ability
        Kennel:RefreshWindow("abilities")
    end)
    return row
end

---The column heads above the ranks.
---@param panel KennelAbilitiesPanel
---@param skin KennelButtonHolderSkin
---@return KennelRankHeader
local function Header(panel, skin)
    local header = CreateFrame("Frame", nil, panel) --[[@as KennelRankHeader]]
    header:SetHeight(16)
    header:SetPoint("TOPLEFT", LIST_WIDTH + 16, -HEADER_TOP)
    header:SetPoint("RIGHT")
    ---@param x number
    ---@param label string
    ---@param justify string?
    ---@return FontString
    local function Head(x, label, justify)
        local text = Text(header, skin, justify)
        text:SetPoint("LEFT", x, 0)
        text:SetText(label)
        text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        return text
    end
    header.rank = Head(4, L.BEASTMAP_COLUMN_RANK)
    header.level = Head(RANK_WIDTH, L.BEASTMAP_COLUMN_LEVEL, "RIGHT")
    header.level:SetWidth(LEVEL_COLUMN)
    header.text = Head(RANK_WIDTH + LEVEL_WIDTH, L.BEASTMAP_COLUMN_TEACHER)
    return header
end

---A rank's row: rank, pet level, the teacher on one line, how many more, the go button.
---@param panel KennelAbilitiesPanel
---@param skin KennelButtonHolderSkin
---@param index number
---@return KennelRankRow
local function RankRow(panel, skin, index)
    local row = CreateFrame("Button", nil, panel) --[[@as KennelRankRow]]
    row:SetHeight(RANK_HEIGHT)
    row:SetPoint("TOPLEFT", LIST_WIDTH + 16, -RANKS_TOP - (index - 1) * RANK_HEIGHT)
    row:SetPoint("RIGHT")
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(1, 1, 1, 0.05)
    row.stripe:SetShown(index % 2 == 0)
    row.rank = Text(row, skin)
    row.rank:SetPoint("LEFT", 4, 0)
    row.level = Text(row, skin, "RIGHT")
    row.level:SetWidth(LEVEL_COLUMN)
    row.level:SetPoint("LEFT", RANK_WIDTH, 0)
    row.go = CreateFrame("Button", nil, row) --[[@as KennelGoButton]]
    row.go:SetSize(RANK_HEIGHT - 4, RANK_HEIGHT - 4)
    row.go:SetPoint("RIGHT", -2, 0)
    row.go.icon = row.go:CreateTexture(nil, "ARTWORK")
    row.go.icon:SetAllPoints()
    row.go.icon:SetTexture(GO_ICON)
    local crop = skin.CropIcon or Crop
    crop(row.go.icon)
    row.go:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    row.go:SetScript("OnClick", function()
        M:GoToBeast(row.best --[[@as number]])
    end)
    row.go:SetScript("OnEnter", OnGoEnter)
    row.go:SetScript("OnLeave", OnLeave)
    row.more = Text(row, skin, "RIGHT")
    row.more:SetWidth(MORE_WIDTH)
    row.more:SetPoint("RIGHT", row.go, "LEFT", -6, 0)
    row.text = Text(row, skin)
    row.text:SetPoint("LEFT", RANK_WIDTH + LEVEL_WIDTH, 0)
    row.text:SetPoint("RIGHT", row.more, "LEFT", -4, 0)
    row:SetScript("OnEnter", OnEnter)
    row:SetScript("OnLeave", OnLeave)
    return row
end

---Builds the panel: the abilities' rows, the title, the column heads, the ranks' rows.
---@param panel KennelAbilitiesPanel
---@param skin KennelButtonHolderSkin
local function Create(panel, skin)
    panel.rows, panel.ranks = {}, {}
    for index = 1, LIST_ROWS do
        panel.rows[index] = AbilityRow(panel, skin, index)
    end
    panel.titleIcon = Icon(panel, skin, 20)
    panel.titleIcon:SetPoint("TOPLEFT", LIST_WIDTH + 20, 0)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("LEFT", panel.titleIcon, "RIGHT", 6, 0)
    skin.Font(panel.title, 16)
    panel.header = Header(panel, skin)
    for index = 1, RANK_ROWS do
        panel.ranks[index] = RankRow(panel, skin, index)
    end
end

---Fills one rank's row.
---@param row KennelRankRow
---@param spellID number
local function FillRank(row, spellID)
    local rank = Kennel.data.petAbilityRanks[spellID] --[[@as KennelPetAbilityRank]]
    row.spellID = spellID
    row.rank:SetText(L.BEASTMAP_RANK:format(rank.rank))
    row.level:SetText(tostring(rank.level))
    row.more:SetText("")
    if M.Lacking(spellID) and #rank.teachers == 0 then
        row.teachers, row.best = nil, nil
        row.text:SetText(L.BEASTMAP_NO_TEACHER)
        row.text:SetTextColor(DIM[1], DIM[2], DIM[3])
        row.go:Hide()
    elseif M.Lacking(spellID) then
        local teachers = M.Nearest(rank.teachers)
        row.teachers, row.best = teachers, teachers[1]
        local text, above = TeacherText(teachers)
        local colour = above and ABOVE or MISSING
        row.text:SetText(text)
        row.text:SetTextColor(colour[1], colour[2], colour[3])
        if #teachers > 1 then row.more:SetText(L.BEASTMAP_MORE:format(#teachers - 1)) end
        row.more:SetTextColor(DIM[1], DIM[2], DIM[3])
        row.go:SetShown(Kennel.data.beasts[teachers[1]].pins ~= nil)
    else
        row.teachers, row.best = nil, nil
        row.text:SetText(L.BEASTMAP_KNOWN)
        row.text:SetTextColor(KNOWN[1], KNOWN[2], KNOWN[3])
        row.go:Hide()
    end
    row:Show()
end

---Fills the list and the chosen ability's ranks.
---@param panel KennelAbilitiesPanel
local function Refresh(panel)
    local abilities = Order()
    if not panel.chosen or not Groups()[panel.chosen] then panel.chosen = abilities[1] end
    for index, row in ipairs(panel.rows) do
        local ability = abilities[index]
        row.ability = ability
        row:SetShown(ability ~= nil)
        if ability then
            local known, total = Counts(ability)
            row.label:SetText(AbilityName(ability))
            row.icon:SetTexture(AbilityIcon(ability))
            row.count:SetText(L.BEASTMAP_ABILITY_COUNT:format(known, total))
            local chosen = ability == panel.chosen
            local colour = chosen and MISSING or DIM
            row.label:SetTextColor(colour[1], colour[2], colour[3])
            local count = known == total and KNOWN or DIM
            row.count:SetTextColor(count[1], count[2], count[3])
            row.selected:SetShown(chosen)
        end
    end
    local spells = Groups()[panel.chosen] or {}
    panel.title:SetText(panel.chosen and AbilityName(panel.chosen) or "")
    panel.titleIcon:SetTexture(panel.chosen and AbilityIcon(panel.chosen))
    for index, row in ipairs(panel.ranks) do
        local spellID = spells[index]
        if spellID then
            FillRank(row, spellID)
        else
            row:Hide()
        end
    end
end

Kennel:RegisterWindowTab({
    id = "abilities",
    title = L.BEASTMAP_TAB_ABILITIES,
    order = 20,
    module = "BeastMap",
    Create = Create,
    Refresh = Refresh,
})
