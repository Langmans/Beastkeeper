-- The LS: Toasts skin: a toast handed to LS: Toasts, which stacks, animates and skins it with the
-- player's other toasts. Beastkeeper keeps playing the toast's sound itself.

---A logged-in client without a pet, with LS: Toasts loaded and drawing every toast.
---@param opts TestClientOptions?
local function lsToasting(opts)
    opts = opts or {}
    opts.lsToasts = opts.lsToasts or "classic"
    local client = NewClient(opts)
    client.pet = nil
    client:login()
    client.Addon:ToastSettings().skin = "lstoasts"
    return client
end

describe("the LS: Toasts skin", function()
    it("is there with LS: Toasts loaded, on the classic clients and on retail", function()
        assert.are.equal("LS: Toasts", lsToasting().Addon:ToastSkins().lstoasts.name)
        assert.are.equal("LS: Toasts", lsToasting({ lsToasts = "retail" }).Addon:ToastSkins().lstoasts.name)
    end)

    it("is not there without LS: Toasts", function()
        local client = NewClient()
        client:login()
        assert.is_nil(client.Addon:ToastSkins().lstoasts)
    end)

    it("hands the title, text and icon over, the borders in the accent colour", function()
        local client = lsToasting()
        client.Addon:ShowToast({
            key = "a",
            title = "Bite rank 2",
            text = "Learned",
            icon = 132278,
            accent = { 1, 0, 0 },
        })
        local toast = client.lsToasts[1]
        assert.are.equal("Bite rank 2", toast.title)
        assert.are.equal("Learned", toast.text)
        assert.are.equal(132278, toast.icon)
        assert.are.same({ 1, 0, 0 }, toast.border)
        assert.are.same({ 1, 0, 0 }, toast.iconBorder)
        assert.is_true(toast.iconBorderShown)
        assert.are.same({}, client.errors)
    end)

    it("spawns it at LS: Toasts' first anchor, not held back by do-not-disturb", function()
        local client = lsToasting()
        client.Addon:ShowToast({ key = "a", title = "t" })
        assert.are.equal(1, client.lsToasts[1].anchor)
        assert.is_false(client.lsToasts[1].dnd)
    end)

    it("fills in Beastkeeper's accent and icon, and an empty text, where the toast brings none", function()
        local client = lsToasting()
        client.Addon:ShowToast({ key = "a", title = "Only this" })
        local toast = client.lsToasts[1]
        assert.are.equal("", toast.text)
        assert.are.equal(134400, toast.icon)
        assert.are.same({ 1, 0.62, 0.18 }, toast.border)
    end)

    it("leaves the borders alone when LS: Toasts does not colour them", function()
        local client = lsToasting({ lsToastColors = false })
        client.Addon:ShowToast({ key = "a", title = "t", accent = { 1, 0, 0 } })
        assert.is_nil(client.lsToasts[1].border)
        assert.is_nil(client.lsToasts[1].iconBorder)
    end)

    it("makes a new LS toast for each, never merging two, and does not hold Beastkeeper's queue", function()
        local client = lsToasting()
        client.Addon:ShowToast({ key = "a", title = "First" })
        client.Addon:ShowToast({ key = "b", title = "Second" })
        assert.are.equal(2, #client.lsToasts)
        local first, second = client.lsToasts[1].asked, client.lsToasts[2].asked
        assert.are.equal(first[2], second[2])
        assert.are_not.equal(first[3], second[3])
        assert.is_false(client.Addon:ToastDriver().shown)
    end)

    it("still plays the toast's sound", function()
        local client = lsToasting()
        client.Addon:ShowToast({ key = "a", title = "t", sound = { kit = 8959 } })
        assert.are.same({ kit = 8959, channel = "Master" }, client.sounds[1])
    end)
end)
