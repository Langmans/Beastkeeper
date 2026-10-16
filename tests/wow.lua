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
    PlaySound = noop

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
        return "Hunter", "HUNTER", 3
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
        return 1
    end
    function Region:GetText()
        return self.text
    end
    function Region:SetText(text)
        self.text = text
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
    C_AddOns = { GetAddOnMetadata = getMetadata }

    SlashCmdList = {}
    hash_SlashCmdList = {}
    _G[TOC_SAVED] = opts.saved

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

    ---What the client does at login: ADDON_LOADED for each addon, then PLAYER_LOGIN.
    function client:login()
        self:fire("ADDON_LOADED", "SomeOtherAddon")
        self:fire("ADDON_LOADED", "Kennel")
        self.loggedIn = true
        self:fire("PLAYER_LOGIN")
        return self
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
