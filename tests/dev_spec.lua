-- Screenshots for development (Modules\DevScreenshots): a module only in a copy straight from the
-- repository, never in a release (the packager comments it out), off until switched on. It hears
-- the core's BEASTKEEPER_TOAST and BEASTKEEPER_PRINT messages and takes a screenshot of a toast or a chat line
-- the first time its kind shows, with a grey line in chat first saying what it was for.

---A development copy with the module switched on.
local function shooting()
    local client = NewClient({ dev = true }):login()
    local Addon = client.Addon
    assert.is_false(Addon:GetModule("DevScreenshots"):IsEnabled(), "off until switched on")
    Addon:SetModuleOn("DevScreenshots", true)
    return client
end

describe("development screenshots", function()
    it("take one of a toast once it has faded in, after saying which", function()
        local client = shooting()
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        assert.is_true(client:printedContains("[Beastkeeper dev] toast Test:one"))
        assert.are.equal(0, client.screenshots, "not while it fades in")
        client:animate(0.5)
        assert.are.equal(1, client.screenshots)
    end)

    it("take one after a line Beastkeeper prints, at most one every two seconds", function()
        local client = shooting()
        client.Addon:Print("first")
        client.Addon:Print("second")
        assert.is_true(client:printedContains("[Beastkeeper dev] chat: first"))
        client:advance(0.5)
        assert.are.equal(1, client.screenshots)
        client:advance(1)
        client.Addon:Print("too soon")
        client:advance(0.5)
        assert.are.equal(1, client.screenshots)
        client:advance(2)
        client.Addon:Print("later")
        client:advance(0.5)
        assert.are.equal(2, client.screenshots)
    end)

    it("take one of each kind of toast and each chat line only once, until forgotten", function()
        local client = shooting()
        local module = client.Addon:GetModule("DevScreenshots")
        client.Addon:ShowToast({ key = "Test:one", type = "Test:kind", title = "One" })
        client:animate(0.5)
        client.Addon:DropToast("Test:one")
        client:animate(2)
        client.Addon:ShowToast({ key = "Test:two", type = "Test:kind", title = "Two" })
        client:animate(0.5)
        assert.are.equal(1, client.screenshots, "the same kind of toast")
        client.Addon:Print("Fluffy gained 3 points")
        client:advance(3)
        client.Addon:Print("Fluffy gained 15 points")
        client:advance(3)
        assert.are.equal(2, client.screenshots, "the same line with other numbers")
        assert.is_true(module.db.global.shots["toast Test:kind"])
        assert.is_true(module.db.global.shots["chat: Fluffy gained # points"])
        module:GetOptions().args.forget.func()
        client.Addon:Print("Fluffy gained 4 points")
        client:advance(1)
        assert.are.equal(3, client.screenshots)
    end)

    it("know a chat line by its plain text: colours and links have hex digits and IDs", function()
        local client = shooting()
        client.Addon:Print(
            "|cffabd473Elia|r feeds |cnGREEN_FONT_COLOR:Kaldor|r |cffffffff|Hitem:4544::::|h[Meat]|h|r x2"
        )
        local shots = client.Addon:GetModule("DevScreenshots").db.global.shots
        assert.is_true(shots["chat: Elia feeds Kaldor [Meat] x#"])
        assert.is_true(client:printedContains("|cff888888[Beastkeeper dev] chat: Elia feeds Kaldor [Meat] x#|r"))
    end)

    it("take none while switched off, and are not there in a release", function()
        local client = NewClient({ dev = true }):login()
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        client.Addon:Print("a line")
        client:animate(1):advance(1)
        assert.are.equal(0, client.screenshots)
        assert.is_false(client:printedContains("[Beastkeeper dev]"))
        client.Addon:SetModuleOn("DevScreenshots", true)
        client.Addon:SetModuleOn("DevScreenshots", false)
        client.Addon:Print("another line")
        client:advance(1)
        assert.are.equal(0, client.screenshots)
        local release = NewClient():login()
        assert.is_nil(release.Addon:GetModule("DevScreenshots", true))
    end)
end)

describe("the core's messages", function()
    it("hand a toast over before it shows, with the module its key names", function()
        local client = NewClient():login()
        local heard = {}
        client.Addon.RegisterMessage(heard, "BEASTKEEPER_TOAST", function(_, event)
            heard.module = event.module
            event.toast.title = "Changed"
        end)
        client.Addon:ShowToast({ key = "Test:one", title = "One" })
        assert.are.equal("Test", heard.module)
        assert.are.equal("Changed", client:toastTitle())
    end)

    it("hand over every line Beastkeeper prints, with the module that said it", function()
        local client = NewClient():login()
        local heard = {}
        client.Addon.RegisterMessage(heard, "BEASTKEEPER_PRINT", function(_, event)
            heard[#heard + 1] = event
        end)
        client.Addon:Print("a", 2, "line")
        client.Addon:GetModule("AutocastCheck"):Print("from a module")
        assert.are.same({ { line = "a 2 line" }, { module = "AutocastCheck", line = "from a module" } }, heard)
        assert.is_true(client:printedContains("from a module"))
    end)
end)
