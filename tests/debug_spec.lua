-- Beastkeeper's bridge to OAP Debug (Core\Debug.lua): when that addon is installed, Beastkeeper registers
-- with it, sends its own BEASTKEEPER_* messages to its log (each with its table), copies its chat lines
-- and counts and times what the chosen level asks for. Without it nothing is sent.

local ICON = "Interface\\Icons\\Ability_Hunter_BeastCall"

---A stand-in for OAP Debug's global table: every call in `calls`, as { name, ... }.
---@return table api
---@return table[] calls
local function fakeOAPDebug()
    local calls = {}
    local api = {}
    for _, name in ipairs({ "Register", "Log", "Chat", "Count" }) do
        api[name] = function(...)
            calls[#calls + 1] = { name, ... }
        end
    end
    api.Time = function(source, name, fn, ...)
        calls[#calls + 1] = { "Time", source, name }
        return fn(...)
    end
    return api, calls
end

---The calls of one kind.
---@param calls table[]
---@param name string
---@return table[]
local function only(calls, name)
    local out = {}
    for _, call in ipairs(calls) do
        if call[1] == name then out[#out + 1] = call end
    end
    return out
end

---A client with OAP Debug installed, logged in.
---@param level string? the OAP Debug setting
---@return table client
---@return table[] calls
local function withOAP(level)
    local saved = {
        profileKeys = { ["Langmans - Doomhowl"] = "Default" },
        profiles = { Default = { oapDebug = level } },
    }
    local client = NewClient(level and { saved = saved } or nil)
    local api, calls = fakeOAPDebug()
    -- busted gives a spec file globals of its own; the addon reads the real ones.
    _G.OAPDebug = api
    client:login()
    return client, calls
end

---Beastkeeper's OAP Debug setting on its page.
---@param client table
---@return table
local function option(client)
    return client.Addon:GetOptionsTable().args.modules.args.debug.args.level
end

describe("OAP Debug", function()
    after_each(function()
        _G.OAPDebug = nil
    end)

    it("gets Beastkeeper registered once, with its folder for Lua errors and its icon", function()
        local client, calls = withOAP()
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:Print("hello")
        assert.are.same(
            { { "Register", "Beastkeeper", { title = "Beastkeeper", folder = "Beastkeeper", icon = ICON } } },
            only(calls, "Register")
        )
    end)

    it("logs Beastkeeper's messages with their table, counts them, and copies its chat lines", function()
        local client, calls = withOAP()
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        local logged = only(calls, "Log")
        local last = logged[#logged]
        assert.are.equal("BEASTKEEPER_TOAST: {1}", last[3])
        assert.are.equal("info", last[4])
        assert.are.equal("One", last[5].toast.title)
        assert.are.same({ "Count", "Beastkeeper", "BEASTKEEPER_TOAST" }, only(calls, "Count")[#only(calls, "Count")])
        client.Addon:Print("hello")
        assert.are.same({ "Chat", "Beastkeeper", "hello" }, calls[#calls])
    end)

    it("logs a module switched on or off", function()
        local client, calls = withOAP()
        client.Addon:SetModuleOn("Feeding", false)
        local logged = only(calls, "Log")
        assert.are.same({ "Log", "Beastkeeper", "module: {1} off", "info", "Feeding" }, logged[#logged])
    end)

    it("times the window's tabs from Normal + metrics", function()
        local client, calls = withOAP()
        client.Addon:OpenWindow("pets")
        assert.are.same({ "Time", "Beastkeeper", "window: pets" }, only(calls, "Time")[1])
    end)

    it("sends only what the level asks for", function()
        local client, calls = withOAP("errors")
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:Print("hello")
        client.Addon:OpenWindow("pets")
        assert.are.same({}, only(calls, "Log"))
        assert.are.same({}, only(calls, "Chat"))
        assert.are.same({}, only(calls, "Time"))
        client, calls = withOAP("normal")
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:OpenWindow("pets")
        assert.is_true(#only(calls, "Log") > 0)
        assert.are.same({}, only(calls, "Count"))
        assert.are.same({}, only(calls, "Time"))
    end)

    it("has its level on Beastkeeper's page, Normal + metrics by default, taking effect at once", function()
        local client, calls = withOAP()
        local level = option(client)
        assert.are.equal("metrics", level.get())
        assert.are.same(
            { errors = "Errors only", normal = "Normal", metrics = "Normal + metrics", detailed = "Detailed" },
            level.values
        )
        level.set(nil, "errors")
        assert.are.equal("errors", client.Addon.db.profile.oapDebug)
        local before = #calls
        client.Addon:Print("quiet")
        assert.are.equal(before, #calls)
        level.set(nil, "detailed")
        client.Addon:Print("loud")
        assert.are.same({ "Chat", "Beastkeeper", "loud" }, calls[#calls])
    end)

    it("sends nothing and says so without OAP Debug", function()
        local client = NewClient():login()
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:OpenWindow("pets")
        local desc = option(client).desc
        assert.are.equal(
            "How much goes to OAP Debug and DebugLog (metrics: timings and counts, OAP Debug only). Neither is installed: nothing is sent.",
            desc()
        )
    end)
end)

---A client with DebugLog installed (and OAP Debug too when `oap`), logged in.
---@param level string? the debug setting
---@param oap boolean?
---@return table client
---@return string[][] lines each { tab, line } as DebugLog formatted it
---@return table[] calls OAP Debug's, when there
local function withDebugLog(level, oap)
    local saved = {
        profileKeys = { ["Langmans - Doomhowl"] = "Default" },
        profiles = { Default = { oapDebug = level } },
    }
    local client = NewClient(level and { saved = saved } or nil)
    local lines = {}
    _G.DLAPI = {
        DebugLog = function(tab, fmt, ...)
            lines[#lines + 1] = { tab, fmt:format(...) }
        end,
    }
    local calls = {}
    if oap then
        _G.OAPDebug, calls = fakeOAPDebug()
    end
    client:login()
    return client, lines, calls
end

describe("DebugLog", function()
    after_each(function()
        _G.DLAPI, _G.OAPDebug = nil, nil
    end)

    it("gets Beastkeeper's messages in a tab of its own, the message as category, the table written out", function()
        local client, lines = withDebugLog()
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        local last = lines[#lines]
        assert.are.equal("Beastkeeper", last[1])
        assert.truthy(last[2]:find("^BEASTKEEPER_TOAST~{"))
        assert.truthy(last[2]:find("title=One", 1, true))
    end)

    it("takes the word before a colon as the category", function()
        local client, lines = withDebugLog()
        client.Addon:SetModuleOn("Feeding", false)
        assert.are.equal("module~Feeding off", lines[#lines][2])
        client.Addon:Log("warn", "probe: odd {1}", 1)
        assert.are.equal("WARN~probe~odd 1", lines[#lines][2])
    end)

    it("colours errors and warnings, marks detail, and leaves a plain line plain", function()
        local client, lines = withDebugLog("detailed")
        client.Addon:Log("error", "broke {1}", 5)
        client.Addon:Log("warn", "odd {1} {2}", "a", true)
        client.Addon:Log("info", "fine")
        client.Addon:Log("debug", "deep")
        local n = #lines
        assert.are.same(
            { "ERR~broke 5", "WARN~odd a true", "fine", "2~deep" },
            { lines[n - 3][2], lines[n - 2][2], lines[n - 1][2], lines[n][2] }
        )
    end)

    it("gets Beastkeeper's chat lines, a % in them kept as it is", function()
        local client, lines = withDebugLog()
        client.Addon:Print("100% fed")
        assert.are.same({ "Beastkeeper", "Chat~100% fed" }, lines[#lines])
    end)

    it("gets only what the level asks for", function()
        local client, lines = withDebugLog("errors")
        local before = #lines
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:Print("hello")
        client.Addon:Log("debug", "deep")
        assert.are.equal(before, #lines)
        client.Addon:Log("error", "broke")
        assert.are.equal("ERR~broke", lines[#lines][2])
    end)

    it("writes a table inside a table out too, keys in order, and stops one level further", function()
        local client, lines = withDebugLog()
        client.Addon:Log("info", "{1}", { b = 2, a = { c = { d = 1 } } })
        assert.are.equal("{a={c={...}}, b=2}", lines[#lines][2])
    end)

    it("goes with OAP Debug when both are installed, counts and timers to OAP Debug alone", function()
        local client, lines, calls = withDebugLog(nil, true)
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:OpenWindow("pets")
        assert.truthy(lines[#lines][2]:find("BEASTKEEPER_TOAST", 1, true))
        assert.is_true(#only(calls, "Log") > 0)
        assert.is_true(#only(calls, "Count") > 0)
        assert.is_true(#only(calls, "Time") > 0)
    end)

    it("has the setting say no addon is missing", function()
        local client = withDebugLog()
        assert.are.equal(
            "How much goes to OAP Debug and DebugLog (metrics: timings and counts, OAP Debug only).",
            option(client).desc()
        )
    end)
end)
