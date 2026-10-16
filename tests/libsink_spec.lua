-- The LibSink skin: a toast handed to the output the player picks through LibSink (Blizzard's
-- floating text by default, or chat, raid warning, MikSBT, ...), without a frame of its own.

---A logged-in client without a pet, with LibSink drawing every toast.
local function sinking()
    local client = NewClient()
    client.pet = nil
    client:login()
    client.Kennel:ToastSettings().skin = "libsink"
    return client
end

describe("the LibSink skin", function()
    it("is there, LibSink being part of Kennel", function()
        local client = sinking()
        assert.are.equal("Floating text and more (LibSink)", client.Kennel:ToastSkins().libsink.name)
    end)

    it("pours the title and text in the accent colour through Blizzard's floating text by default", function()
        local client = sinking()
        client.Kennel:ShowToast({ key = "a", title = "Growl is on autocast", text = "Solo", accent = { 1, 0, 0 } })
        local message = client.combatText[1]
        assert.truthy(message.text:find("Growl is on autocast: Solo", 1, true))
        assert.are.same({ 1, 0, 0 }, { message.r, message.g, message.b })
        assert.are.same({}, client.errors)
    end)

    it("pours the title alone when there is no text, in Kennel's accent when none is given", function()
        local client = sinking()
        client.Kennel:ShowToast({ key = "a", title = "Only this" })
        local message = client.combatText[1]
        assert.truthy(message.text:find("Only this", 1, true))
        assert.is_nil(message.text:find(":", 1, true))
        assert.are.same({ 1, 0.62, 0.18 }, { message.r, message.g, message.b })
    end)

    it("does not hold the queue: toasts pour one after the other at once", function()
        local client = sinking()
        client.Kennel:ShowToast({ key = "a", title = "First" })
        client.Kennel:ShowToast({ key = "b", title = "Second" })
        assert.are.equal(2, #client.combatText)
        assert.is_false(client.Kennel:ToastDriver().shown)
    end)

    it("still plays the toast's sound", function()
        local client = sinking()
        client.Kennel:ShowToast({ key = "a", title = "t", sound = { kit = 8959 } })
        assert.are.same({ kit = 8959, channel = "Master" }, client.sounds[1])
    end)

    describe("its output choice", function()
        it("is LibSink's own, on Kennel's page", function()
            local client = sinking()
            local output = client.Kennel:GetOptionsTable().args.modules.args.toast.args.libsink
            assert.are.equal("group", output.type)
            assert.is_table(output.args.ChatFrame)
        end)

        it("sends the toasts where the player picks, kept in the profile", function()
            local client = sinking()
            local output = client.Kennel:GetOptionsTable().args.modules.args.toast.args.libsink
            output.set({ "libsink", "ChatFrame" }, true)
            assert.are.equal("ChatFrame", client.Kennel:ToastSettings().sink.sink20OutputSink)
            client.Kennel:ShowToast({ key = "a", title = "To chat" })
            assert.is_true(client:printedContains("To chat"))
            assert.are.equal(0, #client.combatText)
        end)
    end)

    it("can be the look of one kind of toast only", function()
        local client = NewClient():login()
        client.Kennel:ToastSettings().skins["AutocastCheck:problem"] = "libsink"
        client:autocast(GROWL, false)
        assert.truthy(client.combatText[1].text:find("Growl is not on autocast", 1, true))
        client.Kennel:ShowToast({ key = "other", title = "On a card" })
        assert.are.equal("On a card", client:toastTitle())
    end)
end)
