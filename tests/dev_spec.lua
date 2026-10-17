-- Screenshots for development (Core\Dev.lua): only in a copy straight from the repository, never
-- in a release (the packager comments the code out), and only with its box ticked on Kennel's
-- page. Each toast and each line Kennel prints then gets a screenshot, with a grey line in chat
-- first saying what it was for.

---A development copy with the screenshots box ticked.
local function shooting()
    local client = NewClient({ dev = true }):login()
    local box = client.Kennel:GetOptionsTable().args.modules.args.devScreenshots
    assert.is_false(box.get(), "off until ticked")
    box.set({}, true)
    assert.is_true(box.get())
    return client
end

describe("development screenshots", function()
    it("take one of each toast once it has faded in, after saying which", function()
        local client = shooting()
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        assert.is_true(client:printedContains("[Kennel dev] toast Test:one"))
        assert.are.equal(0, client.screenshots, "not while it fades in")
        client:animate(0.5)
        assert.are.equal(1, client.screenshots)
    end)

    it("take one after a line Kennel prints, at most one every two seconds", function()
        local client = shooting()
        client.Kennel:Print("first")
        client.Kennel:Print("second")
        assert.is_true(client:printedContains("[Kennel dev] chat: first"))
        client:advance(0.5)
        assert.are.equal(1, client.screenshots)
        client:advance(1)
        client.Kennel:Print("too soon")
        client:advance(0.5)
        assert.are.equal(1, client.screenshots)
        client:advance(2)
        client.Kennel:Print("later")
        client:advance(0.5)
        assert.are.equal(2, client.screenshots)
    end)

    it("are off with the box unticked, and the box is not there outside development", function()
        local client = NewClient({ dev = true }):login()
        client.Kennel:ShowToast({ key = "Test:one", title = "One" })
        client.Kennel:Print("a line")
        client:animate(1):advance(1)
        assert.are.equal(0, client.screenshots)
        assert.is_false(client:printedContains("[Kennel dev]"))
        local release = NewClient():login()
        assert.is_nil(release.Kennel:GetOptionsTable().args.modules.args.devScreenshots)
    end)
end)
