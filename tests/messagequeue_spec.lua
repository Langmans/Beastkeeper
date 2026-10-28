-- The MessageQueue output for LibSink: a toast said in a chat channel, sent through MessageQueue so
-- that SAY, YELL and channels wait for the player's next input, as WoW: Forever requires.

---A logged-in client without a pet, toasts going through LibSink, and its output options.
local function sinking(opts)
    opts = opts or {}
    local client = NewClient(opts)
    client.pet = nil
    client:login()
    client.Addon:ToastSettings().skin = "libsink"
    return client, client.Addon:GetOptionsTable().args.modules.args.toast.args.libsink
end

---Picks the MessageQueue output and a chat channel by its LibSink name.
local function pick(output, channel)
    output.set({ "libsink", "BeastkeeperMessageQueue" }, true)
    output.set({ "libsink", "ScrollArea" }, channel)
end

describe("the MessageQueue output", function()
    it("is not offered without MessageQueue", function()
        local _, output = sinking()
        assert.is_nil(output.args.BeastkeeperMessageQueue)
    end)

    describe("with MessageQueue", function()
        it("is offered among LibSink's outputs, with the chat channels to choose from", function()
            local client, output = sinking({ messageQueue = true })
            assert.are.equal("Chat channel (MessageQueue)", output.args.BeastkeeperMessageQueue.name)
            output.set({ "libsink", "BeastkeeperMessageQueue" }, true)
            output.get({ "libsink", "BeastkeeperMessageQueue" })
            assert.are.equal("Say", output.args.ScrollArea.values.Say)
            assert.are.equal("Group", output.args.ScrollArea.values.Group)
            assert.are.same({}, client.errors)
        end)

        it("says the toast in the chosen channel, without colours or icons", function()
            local client, output = sinking({ messageQueue = true })
            pick(output, "Say")
            client.Addon:ShowToast({ key = "a", title = "|cffff0000Growl|r is on", text = "Solo", icon = 132270 })
            assert.are.same({ { "Growl is on: Solo", "SAY" } }, client.queued)
            assert.are.same({}, client.chatSent, "nothing sent past MessageQueue")
        end)

        it("says it in the group the player is in", function()
            local client, output = sinking({ messageQueue = true })
            pick(output, "Group")
            client.Addon:ShowToast({ key = "a", title = "alone" })
            client.inGroup = true
            client.Addon:ShowToast({ key = "b", title = "party" })
            client.instanceGroup = true
            client.Addon:ShowToast({ key = "c", title = "instance" })
            assert.are.same({ "SAY", "PARTY", "INSTANCE_CHAT" }, {
                client.queued[1][2],
                client.queued[2][2],
                client.queued[3][2],
            })
        end)

        it("says it in a raid when in one", function()
            local client, output = sinking({ messageQueue = true })
            pick(output, "Group")
            client.inGroup, client.inRaid = true, true
            client.Addon:ShowToast({ key = "a", title = "raid" })
            assert.are.equal("RAID", client.queued[1][2])
        end)

        it("says it in a custom channel by its number, or nowhere when the player left it", function()
            local client, output = sinking({ messageQueue = true })
            client.channels[5] = "Hunters"
            client:fire("CHANNEL_UI_UPDATE")
            pick(output, "Hunters")
            client.Addon:ShowToast({ key = "a", title = "pack" })
            assert.are.same({ "pack", "CHANNEL", nil, 5 }, client.queued[1])
            client.channels[5] = nil
            client.Addon:ShowToast({ key = "b", title = "gone" })
            assert.are.equal(1, #client.queued)
        end)

        it("says it in Say when no channel was chosen", function()
            local client, output = sinking({ messageQueue = true })
            output.set({ "libsink", "BeastkeeperMessageQueue" }, true)
            client.Addon:ShowToast({ key = "a", title = "default" })
            assert.are.same({ "default", "SAY" }, client.queued[1])
        end)
    end)
end)
