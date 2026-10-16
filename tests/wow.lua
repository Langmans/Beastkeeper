-- A simulated WoW client: the API Kennel and the Ace3 libraries touch, with every value a test
-- may want to vary exposed on the client object. NewClient() resets the globals and loads the
-- .toc's files (Ace3 included) into a fresh namespace, so tests never share state. The load order
-- and the .toc's metadata come from tests/helper.lua (TOC_FILES, TOC_METADATA, TOC_SAVED).

---Packs varargs with their count, nils included (Lua 5.1 has no table.pack).
local function pack(...)
    return { n = select("#", ...), ... }
end

-- WoW's Lua 5.1 passes xpcall's extra arguments on to the function, as Lua 5.2 does; plain 5.1
-- drops them. Ace3 relies on it (AceAddon calls OnInitialize as xpcall(func, handler, addon)).
local plainXpcall = xpcall
function xpcall(func, handler, ...)
    local args = pack(...)
    return plainXpcall(function()
        return func(unpack(args, 1, args.n))
    end, handler)
end

---@class TestClientOptions
---@field locale string? the client's language, enUS by default
---@field saved table? KennelDB as the saved file left it
---@field modules fun(Kennel: Kennel)? creates test modules after the files load, before login
---@field noSettingsPanel boolean? Settings without C_SettingsUtil.OpenSettingsPanel, like Forever
---@field class string? the player's class file, HUNTER by default
---@field oldSpellAPI boolean? GetSpellInfo instead of C_Spell
---@field noSpellAPI boolean? neither C_Spell nor GetSpellInfo
---@field noTextureAPI boolean? C_Spell without GetSpellTexture
---@field noPetBarAPI boolean? no GetPetActionInfo
---@field noSpellBookAPI boolean? no C_SpellBook
---@field noPetSpellCount boolean? C_SpellBook without HasPetSpells
---@field noMacroConsts boolean? no Constants.MacroConsts (the addon's own limits apply)
---@field ellesmere boolean|table? EllesmereUI loaded before Kennel (a table: fields to leave out, set to false)

-- The spells the simulated client knows, per locale: id -> { name, icon }.
local SPELLS = {
    enUS = {
        [2649] = { "Growl", 132270 },
        [14916] = { "Growl", 132270 }, -- a higher rank: same name
        [1742] = { "Cower", 132118 },
        [17253] = { "Bite", 132278 },
        [16828] = { "Claw", 132140 },
        [4187] = { "Great Stamina", 136112 },
        [20736] = { "Distracting Shot", 135736 },
    },
    deDE = {
        [2649] = { "Knurren", 132270 },
        [14916] = { "Knurren", 132270 },
        [1742] = { "Ducken", 132118 },
        [17253] = { "Biss", 132278 },
        [20736] = { "Ablenkender Schuss", 135736 },
    },
}

GROWL, COWER = 2649, 1742

---@param opts TestClientOptions?
function NewClient(opts)
    opts = opts or {}
    local function noop() end
    local client = {
        time = 100,
        frames = {},
        printed = {},
        errors = {},
        loggedIn = false,
    }

    local locale = opts.locale or "enUS"
    function GetLocale()
        return locale
    end
    function GetTime()
        return client.time
    end
    function IsLoggedIn()
        return client.loggedIn
    end
    function GetBuildInfo()
        return "1.16.0", "60000", "Oct 1 2026", 11600
    end
    -- An error the addon or a library reports without raising is a test failure waiting to
    -- happen: it is kept for the test to check (client.errors).
    function geterrorhandler()
        return function(err)
            client.errors[#client.errors + 1] = tostring(err)
        end
    end
    function securecallfunction(func, ...)
        return func(...)
    end
    function hooksecurefunc(target, name, hook)
        if type(target) ~= "table" then
            target, name, hook = _G, target, name
        end
        local original = target[name]
        target[name] = function(...)
            local results = pack(original(...))
            hook(...)
            return unpack(results, 1, results.n)
        end
    end
    function InCombatLockdown()
        return client.inCombat == true
    end

    -- Global strings and constants the Ace3 GUI reads.
    FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE = "|r", "|cffffd200"
    NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
    ACCEPT, CANCEL, CLOSE, OKAY, NOT_BOUND = "Accept", "Cancel", "Close", "Okay", "Not Bound"
    WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC = 1, 2
    WOW_PROJECT_ID = WOW_PROJECT_CLASSIC
    SOUNDKIT = setmetatable({}, {
        __index = function()
            return 1
        end,
    })
    -- client.sounds: { file = FileDataID } for a sound file, { kit = SoundKit ID } for a kit.
    client.sounds = {}
    function PlaySoundFile(file, channel)
        client.sounds[#client.sounds + 1] = { file = file, channel = channel }
    end
    function PlaySound(kit, channel)
        client.sounds[#client.sounds + 1] = { kit = kit, channel = channel }
    end

    -- The pet: client.petBar is the pet bar, one entry per slot, { spellID, autocast } for a spell
    -- (autocast nil when it cannot autocast) or { token = "PET_ACTION_ATTACK" }; nil means no pet
    -- out. client.petBook is the pet's spellbook, alphabetical like the client's, entries as above,
    -- { token = "Attack" } for a command and { broken = true } for an entry whose lookup errors.
    -- As on Forever: Cower is in the book but not on the bar. The pet starts as solo wants it,
    -- Growl on and Cower off.
    client.petBar = {
        { token = "PET_ACTION_ATTACK" },
        { token = "PET_ACTION_FOLLOW" },
        { 2649, true },
        { 16828, true },
        { 17253, true },
    }
    client.petBook =
        { { token = "Attack" }, { 17253, true }, { 16828, true }, { 1742, false }, { 4187 }, { 2649, true } }
    -- client.familyID: the pet's CreatureFamily ID (2 = cat). client.inGroup, client.instance:
    -- the group and the instance type ("party", "raid", "pvp", "arena", or "none" outside).
    client.familyID, client.inGroup, client.instance = 2, false, "none"
    function UnitExists(unit)
        return unit == "player" or (unit == "pet" and client.petBar ~= nil)
    end
    function UnitCreatureFamily(unit)
        if unit == "pet" and client.petBar then return "Cat", client.familyID end
    end
    function IsInGroup()
        return client.inGroup
    end
    function IsInInstance()
        return client.instance ~= "none", client.instance
    end
    -- client.secret: a value the client hides from addons (in combat, on Forever).
    function issecretvalue(value)
        return value ~= nil and value == client.secret
    end

    -- Spells: C_Spell, GetSpellInfo with opts.oldSpellAPI, neither with opts.noSpellAPI. Names
    -- for enUS and deDE; any other locale reads the English ones.
    local spells = SPELLS[locale] or SPELLS.enUS
    local function spellName(id)
        return spells[id] and spells[id][1]
    end
    local function spellIcon(id)
        return spells[id] and spells[id][2]
    end
    C_Spell, GetSpellInfo = nil, nil
    if opts.oldSpellAPI then
        function GetSpellInfo(id)
            return spellName(id), nil, spellIcon(id)
        end
    elseif not opts.noSpellAPI then
        C_Spell = { GetSpellName = spellName, GetSpellTexture = not opts.noTextureAPI and spellIcon or nil }
    end

    -- GetPetActionInfo as Forever returns it: name, texture, isToken (1, not true), isActive,
    -- autoCastAllowed, autoCastEnabled, spellID.
    NUM_PET_ACTION_SLOTS = 10
    GetPetActionInfo = nil
    if not opts.noPetBarAPI then
        function GetPetActionInfo(slot)
            local entry = client.petBar and client.petBar[slot]
            if not entry then return nil end
            if entry.token then return entry.token, entry.token .. "_TEXTURE", 1, nil, false, false end
            return spellName(entry[1]), spellIcon(entry[1]), nil, nil, entry[2] ~= nil, entry[2] == true, entry[1]
        end
    end

    -- The pet's spellbook through C_SpellBook, as Forever has it. A command has no autocast values.
    local function bookEntry(index)
        local entry = client.petBook[index]
        assert(not entry.broken, "this entry's lookup errors")
        if entry.token then return entry.token, nil, nil end
        return spellName(entry[1]), entry[2] ~= nil, entry[2] == true
    end
    Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 } }
    C_SpellBook = nil
    if not opts.noSpellBookAPI then
        C_SpellBook = {
            HasPetSpells = not opts.noPetSpellCount and function()
                if client.petBar then return #client.petBook, "PET" end
            end or nil,
            GetSpellBookItemInfo = function(index, bank)
                assert(bank == Enum.SpellBookSpellBank.Pet, "pet spellbook bank expected")
                if client.petBook[index].noInfo then return nil end
                return { name = (bookEntry(index)) }
            end,
            GetSpellBookItemAutoCast = function(index, bank)
                assert(bank == Enum.SpellBookSpellBank.Pet, "pet spellbook bank expected")
                local _, allowed, on = bookEntry(index)
                return allowed, on
            end,
        }
    end

    -- Macros: client.macros (account-wide) and client.charMacros (this character's). The index
    -- of a character macro counts on from the account maximum, as the client's does.
    client.macros, client.charMacros = {}, {}
    local MAX_ACCOUNT, MAX_CHARACTER = 120, opts.noMacroConsts and 18 or 30
    Constants = not opts.noMacroConsts
            and { MacroConsts = { MAX_ACCOUNT_MACROS = MAX_ACCOUNT, MAX_CHARACTER_MACROS = MAX_CHARACTER } }
        or nil
    function GetMacroIndexByName(name)
        for i, macro in ipairs(client.macros) do
            if macro.name == name then return i end
        end
        for i, macro in ipairs(client.charMacros) do
            if macro.name == name then return MAX_ACCOUNT + i end
        end
        return 0
    end
    function GetNumMacros()
        return #client.macros, #client.charMacros
    end
    function CreateMacro(name, icon, body, perCharacter)
        assert(not client.inCombat, "macros are not made in combat")
        local list = perCharacter and client.charMacros or client.macros
        assert(#list < (perCharacter and MAX_CHARACTER or MAX_ACCOUNT), "no free macro slot")
        list[#list + 1] = { name = name, icon = icon, body = body }
    end

    -- client.timers: pending C_Timer callbacks; client:advance runs the ones that come due.
    client.timers = {}
    C_Timer = {
        After = function(seconds, callback)
            client.timers[#client.timers + 1] = { at = client.time + seconds, callback = callback }
        end,
    }

    -- The player, as AceDB reads it for its char/realm/class/faction keys.
    function UnitNameUnmodified(unit)
        if unit == "player" then return "Langmans" end
    end
    UnitName = UnitNameUnmodified
    function UnitClass()
        local classFile = opts.class or "HUNTER"
        return classFile, classFile
    end
    function UnitRace()
        return "Night Elf", "NightElf", 4
    end
    function UnitFactionGroup()
        return "Alliance", "Alliance"
    end
    function GetRealmName()
        return "Doomhowl"
    end
    function GetCurrentRegion()
        return 3
    end
    function GetCurrentRegionName()
        return "EU"
    end

    -- WoW's string and table shorthands.
    strmatch, strfind, strsub, strlower, strupper, strlen, strrep, strbyte, strchar, format, gsub =
        string.match,
        string.find,
        string.sub,
        string.lower,
        string.upper,
        string.len,
        string.rep,
        string.byte,
        string.char,
        string.format,
        string.gsub
    tinsert, tremove, tconcat, sort = table.insert, table.remove, table.concat, table.sort
    max, min, floor, ceil, abs = math.max, math.min, math.floor, math.ceil, math.abs
    function strtrim(text, chars)
        chars = chars or " \t\r\n"
        local class = "[" .. chars:gsub("[%]%%%-%^]", "%%%0") .. "]"
        return (text:gsub("^" .. class .. "+", ""):gsub(class .. "+$", ""))
    end
    function strsplit(sep, text, limit)
        local parts, start = {}, 1
        while true do
            if limit and #parts == limit - 1 then break end
            local at = text:find(sep, start, true)
            if not at then break end
            parts[#parts + 1] = text:sub(start, at - 1)
            start = at + #sep
        end
        parts[#parts + 1] = text:sub(start)
        return unpack(parts)
    end
    -- Characters, not bytes: every byte that does not continue a UTF-8 sequence starts one.
    function strlenutf8(text)
        return select(2, text:gsub("[^\128-\191]", ""))
    end
    function strjoin(sep, ...)
        return table.concat({ ... }, sep)
    end
    function wipe(tbl)
        for key in pairs(tbl) do
            tbl[key] = nil
        end
        return tbl
    end
    table.wipe = wipe
    function tostringall(...)
        local out = pack(...)
        for i = 1, out.n do
            out[i] = tostring(out[i])
        end
        return unpack(out, 1, out.n)
    end

    -- Frames: layout calls do nothing, a frame keeps its events, scripts and shown state. Any
    -- method the mock does not define (a capitalised key) is a no-op; a lowercase key is a field
    -- and reads nil until set, as on a real frame.
    local Region = {}
    Region.__index = function(_, key)
        if Region[key] then return Region[key] end
        if type(key) == "string" and key:match("^%u") then return noop end
    end
    function Region:Show()
        self.shown = true
    end
    function Region:Hide()
        self.shown = false
    end
    function Region:IsShown()
        return self.shown
    end
    function Region:RegisterEvent(event)
        self.events[event] = true
    end
    function Region:UnregisterEvent(event)
        self.events[event] = nil
    end
    function Region:UnregisterAllEvents()
        self.events = {}
    end
    function Region:IsEventRegistered(event)
        return self.events[event] == true
    end
    function Region:SetScript(script, handler)
        self.scripts[script] = handler
    end
    function Region:GetScript(script)
        return self.scripts[script]
    end
    function Region:GetName()
        return self.name
    end
    -- Sizes and positions: what was set, else a plausible number, so layout code that does
    -- arithmetic on them (AceGUI's) runs.
    function Region:SetWidth(width)
        self.width = width
    end
    function Region:SetHeight(height)
        self.height = height
    end
    function Region:SetSize(width, height)
        self.width, self.height = width, height
    end
    function Region:GetWidth()
        return self.width or 100
    end
    function Region:GetHeight()
        return self.height or 20
    end
    function Region:GetSize()
        return self:GetWidth(), self:GetHeight()
    end
    for _, getter in ipairs({
        "GetTop",
        "GetBottom",
        "GetLeft",
        "GetRight",
        "GetStringWidth",
        "GetStringHeight",
        "GetFrameLevel",
        "GetNumPoints",
    }) do
        Region[getter] = function()
            return 0
        end
    end
    function Region:GetEffectiveScale()
        return 1
    end
    function Region:GetScale()
        return self.scale or 1
    end
    function Region:GetText()
        return self.text
    end
    function Region:SetText(text)
        self.text = text
    end
    -- What tests read back from the toast: scale, alpha, texture, colours and anchor points.
    function Region:SetScale(scale)
        self.scale = scale
    end
    function Region:SetAlpha(alpha)
        self.alpha = alpha
    end
    function Region:SetTexture(texture)
        self.texture = texture
    end
    function Region:SetColorTexture(r, g, b, a)
        self.color = { r, g, b, a }
    end
    function Region:SetTextColor(r, g, b)
        self.textColor = { r, g, b }
    end
    function Region:SetFont(path, size, flags)
        self.font = { path, size, flags }
    end
    function Region:ClearAllPoints()
        self.points = {}
    end
    function Region:SetPoint(point, relativeTo, relativePoint, x, y)
        self.points = self.points or {}
        self.points[#self.points + 1] = { point, relativeTo, relativePoint, x, y }
    end
    function Region:GetPoint(index)
        local p = self.points and self.points[index or 1]
        if p then return p[1], p[2], p[3], p[4], p[5] end
    end
    -- client.mouseOver: whether the mouse is over a frame (the toast, in practice).
    function Region:IsMouseOver()
        return client.mouseOver == true
    end
    -- Dropped somewhere: the client leaves the frame anchored where it was dropped.
    function Region:StopMovingOrSizing()
        self.points = { { "TOPLEFT", nil, "BOTTOMLEFT", 300, 700 } }
    end
    local function newRegion(fields)
        fields = fields or {}
        fields.shown = true
        fields.events, fields.scripts = {}, {}
        return setmetatable(fields, Region)
    end
    function Region:CreateTexture()
        return newRegion()
    end
    function Region:CreateFontString()
        return newRegion()
    end
    function Region:CreateAnimationGroup()
        return newRegion()
    end
    function Region:CreateAnimation()
        return newRegion()
    end
    -- A button's textures and label, made on first ask, as AceGUI's widgets style them.
    for _, getter in ipairs({
        "GetNormalTexture",
        "GetPushedTexture",
        "GetHighlightTexture",
        "GetDisabledTexture",
        "GetCheckedTexture",
        "GetFontString",
    }) do
        Region[getter] = function(self)
            local key = "_" .. getter
            if not rawget(self, key) then rawset(self, key, newRegion()) end
            return rawget(self, key)
        end
    end

    -- The named children a template makes ($parentLeft and so on), for templates whose children
    -- Ace3 looks up by global name.
    local TEMPLATE_CHILDREN = {
        UIDropDownMenuTemplate = { "Left", "Middle", "Right", "Button", "Text" },
    }

    function CreateFrame(kind, name, parent, template)
        local frame = newRegion({ kind = kind, name = name, parent = parent })
        client.frames[#client.frames + 1] = frame
        if name then _G[name] = frame end
        for _, suffix in ipairs(name and TEMPLATE_CHILDREN[template] or {}) do
            _G[name .. suffix] = newRegion({ name = name .. suffix })
        end
        return frame
    end
    UIParent = newRegion()
    WorldFrame = newRegion()
    UISpecialFrames = {}
    -- client.printed: every chat line, whether through print or the default chat frame.
    DEFAULT_CHAT_FRAME = newRegion()
    function DEFAULT_CHAT_FRAME:AddMessage(text)
        client.printed[#client.printed + 1] = text
    end
    function print(...)
        client.printed[#client.printed + 1] = table.concat({ tostringall(...) }, " ")
    end

    -- The settings window. client.categories: every page added, by ID; client.opened: the IDs
    -- opened. Forever has no C_SettingsUtil (opts.noSettingsPanel), so AceConfigDialog uses the
    -- page name as its ID there.
    client.categories, client.opened = {}, {}
    local nextID = 1
    local function newCategory(frame, name, parent)
        local category = { frame = frame, name = name, parent = parent, ID = nextID }
        nextID = nextID + 1
        function category:GetID()
            return self.ID
        end
        return category
    end
    Settings = {
        RegisterCanvasLayoutCategory = newCategory,
        RegisterCanvasLayoutSubcategory = function(parent, frame, name)
            local category = newCategory(frame, name, parent)
            client.categories[category.ID] = category
            return category
        end,
        RegisterAddOnCategory = function(category)
            client.categories[category.ID] = category
        end,
        GetCategory = function(id)
            return client.categories[id]
        end,
        OpenToCategory = function(id)
            client.opened[#client.opened + 1] = id
        end,
    }
    C_SettingsUtil = not opts.noSettingsPanel and { OpenSettingsPanel = noop } or nil

    local function getMetadata(name, key)
        if name == "Kennel" then return TOC_METADATA[key] end
    end
    C_AddOns = {
        GetAddOnMetadata = getMetadata,
        EnableAddOn = noop,
        LoadAddOn = noop,
        IsAddOnLoaded = function()
            return false
        end,
    }

    -- Where LibSink sends: client.combatText (Blizzard's floating text, its default), chat lines
    -- sent (client.chatSent), raid warnings and the error frame.
    client.combatText, client.chatSent = {}, {}
    CombatText_StandardScroll = "UP"
    function CombatText_AddMessage(text, _, r, g, b)
        client.combatText[#client.combatText + 1] = { text = text, r = r, g = g, b = b }
    end
    C_ChatInfo = {
        SendChatMessage = function(text, kind, _, target)
            client.chatSent[#client.chatSent + 1] = { text, kind, target }
        end,
    }
    function GetChannelList() end
    function GetChannelName() end
    function IsInRaid()
        return false
    end
    RaidWarningFrame, UIErrorsFrame = newRegion(), newRegion()
    RaidNotice_AddMessage = noop

    SlashCmdList = {}
    hash_SlashCmdList = {}
    _G[TOC_SAVED] = opts.saved

    -- EllesmereUI, as far as Kennel uses it, when opts.ellesmere says it is loaded. client.eui
    -- records what was asked of it: the fonts set, the borders made, the shadows primed.
    EllesmereUI = nil
    if opts.ellesmere then
        local eui = { borders = {}, shadows = {} }
        client.eui = eui
        EllesmereUI = {
            ELLESMERE_GREEN = { r = 0.05, g = 0.82, b = 0.62 },
            GetFontPath = function()
                return "Fonts\\Expressway.ttf"
            end,
            GetFontOutlineFlag = function()
                return "OUTLINE"
            end,
            GetFontUseShadow = function()
                return true
            end,
            PrimeFontShadow = function(fs, use)
                eui.shadows[#eui.shadows + 1] = { fs, use }
            end,
            MakeBorder = function(parent, r, g, b, a)
                eui.borders[#eui.borders + 1] = { parent, r, g, b, a }
            end,
        }
        if type(opts.ellesmere) == "table" then
            for key in pairs(opts.ellesmere) do
                EllesmereUI[key] = nil
            end
        end
    end

    -- LibStub keeps its libraries in a global; a fresh client starts without one.
    LibStub = nil
    local ns = {}
    for _, file in ipairs(TOC_FILES) do
        local chunk = assert(loadfile(file))
        chunk("Kennel", ns)
    end
    client.Kennel = ns
    if opts.modules then opts.modules(ns) end

    ---Delivers an event to every frame registered for it.
    function client:fire(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
        return self
    end

    ---Moves the clock on and runs the C_Timer callbacks that came due.
    function client:advance(seconds)
        self.time = self.time + seconds
        local due = {}
        for i = #self.timers, 1, -1 do
            if self.timers[i].at <= self.time then table.insert(due, 1, table.remove(self.timers, i)) end
        end
        for _, timer in ipairs(due) do
            timer.callback()
        end
        return self
    end

    ---What the client does at login: ADDON_LOADED for each addon, PLAYER_LOGIN, the macros
    ---loading; then the moment the modules wait before their first check.
    function client:login()
        self:fire("ADDON_LOADED", "SomeOtherAddon")
        self:fire("ADDON_LOADED", "Kennel")
        self.loggedIn = true
        self:fire("PLAYER_LOGIN")
        self:fire("UPDATE_MACROS")
        return self:advance(0.2)
    end

    ---The pet bar changed (autocast switched, a pet summoned); the modules check a moment later.
    function client:petBarUpdate()
        self:fire("PET_BAR_UPDATE")
        return self:advance(0.2)
    end

    ---Sets autocast of the ability `id` wherever the pet has it, bar and book, without an event.
    function client:setAutocast(id, on)
        for _, list in ipairs({ self.petBar or {}, self.petBook }) do
            for _, entry in ipairs(list) do
                if entry[1] == id then entry[2] = on end
            end
        end
        return self
    end

    ---Switches autocast of the ability `id`, as a right-click does: PET_BAR_UPDATE follows.
    function client:autocast(id, on)
        return self:setAutocast(id, on):petBarUpdate()
    end

    ---Joins or leaves a group.
    function client:group(inGroup)
        self.inGroup = inGroup
        self:fire("GROUP_ROSTER_UPDATE")
        return self:advance(0.2)
    end

    ---The toast frame, once a toast has shown.
    function client:toast()
        return self.Kennel:ToastFrame()
    end

    ---The title of the toast that is up, or nil.
    function client:toastTitle()
        local toast = self:toast()
        return toast and toast.shown and toast.Title.text or nil
    end

    ---Runs the toast clock's OnUpdate for `seconds`, in frames of `step`. Like the client, a
    ---hidden frame gets no more updates.
    function client:animate(seconds, step)
        step = step or 0.05
        local driver, elapsed = self.Kennel:ToastDriver(), 0
        while driver and elapsed < seconds - 1e-9 and driver.shown do
            driver.scripts.OnUpdate(driver, step)
            elapsed = elapsed + step
        end
        return self
    end

    ---The macro of that name, this character's or the account's, or nil.
    function client:macro(name)
        for _, list in ipairs({ self.charMacros, self.macros }) do
            for _, macro in ipairs(list) do
                if macro.name == name then return macro end
            end
        end
    end

    ---What the client does at logout: AceDB strips the defaults from the saved table.
    function client:logout()
        self:fire("PLAYER_LOGOUT")
        return self
    end

    ---Runs a /kennel line the way the chat box does.
    function client:slash(message)
        SlashCmdList.ACECONSOLE_KENNEL(message)
        return self
    end

    function client:printedContains(text)
        for _, line in ipairs(self.printed) do
            if line:find(text, 1, true) then return true end
        end
        return false
    end

    return client
end

function Saved()
    return _G[TOC_SAVED]
end
