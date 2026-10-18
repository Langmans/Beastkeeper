-- Kennel's bridge to OAP Debug (Core\Debug.lua): when that addon is installed, Kennel registers
-- with it, sends its own KENNEL_* messages to its log (each with its table), copies its chat lines
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

---Kennel's OAP Debug setting on its page.
---@param client table
---@return table
local function option(client)
    return client.Kennel:GetOptionsTable().args.modules.args.debug.args.level
end

describe("OAP Debug", function()
    after_each(function()
        _G.OAPDebug = nil
    end)

    it("gets Kennel registered once, with its folder for Lua errors and its icon", function()
        local client, calls = withOAP()
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        client.Kennel:Print("hello")
        assert.are.same(
            { { "Register", "Kennel", { title = "Kennel", folder = "Kennel", icon = ICON } } },
            only(calls, "Register")
        )
    end)

    it("logs Kennel's messages with their table, counts them, and copies its chat lines", function()
        local client, calls = withOAP()
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        local logged = only(calls, "Log")
        local last = logged[#logged]
        assert.are.equal("KENNEL_TOAST {1}", last[3])
        assert.are.equal("info", last[4])
        assert.are.equal("One", last[5].toast.title)
        assert.are.same({ "Count", "Kennel", "KENNEL_TOAST" }, only(calls, "Count")[#only(calls, "Count")])
        client.Kennel:Print("hello")
        assert.are.same({ "Chat", "Kennel", "hello" }, calls[#calls])
    end)

    it("logs a module switched on or off", function()
        local client, calls = withOAP()
        client.Kennel:SetModuleOn("Feeding", false)
        local logged = only(calls, "Log")
        assert.are.same({ "Log", "Kennel", "module {1} off", "info", "Feeding" }, logged[#logged])
    end)

    it("times the window's tabs from Normal + metrics", function()
        local client, calls = withOAP()
        client.Kennel:OpenWindow("pets")
        assert.are.same({ "Time", "Kennel", "window: pets" }, only(calls, "Time")[1])
    end)

    it("sends only what the level asks for", function()
        local client, calls = withOAP("errors")
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        client.Kennel:Print("hello")
        client.Kennel:OpenWindow("pets")
        assert.are.same({}, only(calls, "Log"))
        assert.are.same({}, only(calls, "Chat"))
        assert.are.same({}, only(calls, "Time"))
        client, calls = withOAP("normal")
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        client.Kennel:OpenWindow("pets")
        assert.is_true(#only(calls, "Log") > 0)
        assert.are.same({}, only(calls, "Count"))
        assert.are.same({}, only(calls, "Time"))
    end)

    it("has its level on Kennel's page, Normal + metrics by default, taking effect at once", function()
        local client, calls = withOAP()
        local level = option(client)
        assert.are.equal("metrics", level.get())
        assert.are.same(
            { errors = "Errors only", normal = "Normal", metrics = "Normal + metrics", detailed = "Detailed" },
            level.values
        )
        level.set(nil, "errors")
        assert.are.equal("errors", client.Kennel.db.profile.oapDebug)
        local before = #calls
        client.Kennel:Print("quiet")
        assert.are.equal(before, #calls)
        level.set(nil, "detailed")
        client.Kennel:Print("loud")
        assert.are.same({ "Chat", "Kennel", "loud" }, calls[#calls])
    end)

    it("sends nothing and says so without OAP Debug", function()
        local client = NewClient():login()
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        client.Kennel:OpenWindow("pets")
        local desc = option(client).desc
        assert.are.equal(
            "How much goes to OAP Debug's window (metrics: timings and counts). Not installed: nothing is sent.",
            desc()
        )
    end)
end)
