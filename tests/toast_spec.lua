-- The toast: how it shows, stays, fades, queues and moves.

---A logged-in client without a pet, so no module toasts by itself.
local function quiet(opts)
    local client = NewClient(opts)
    client.petBar = nil
    return client:login()
end

---@param key string
---@param fields table?
local function info(key, fields)
    local toast = { key = key, title = key .. " title", text = key .. " text", hint = key .. " hint" }
    for k, v in pairs(fields or {}) do
        toast[k] = v
    end
    return toast
end

describe("the toast", function()
    local client, Kennel

    before_each(function()
        client = quiet()
        Kennel = client.Kennel
    end)

    it("is not made before the first toast", function()
        assert.is_nil(client:toast())
        Kennel:HideToast() -- nothing to hide, nothing breaks
        Kennel:DropToast("x")
        Kennel:DropToasts("x:")
    end)

    it("shows the title, text, hint and icon, in the accent colour", function()
        Kennel:ShowToast(info("a", { icon = 132270, accent = { 0.2, 0.8, 0.4 } }))
        local toast = client:toast()
        assert.are.equal("a title", toast.Title.text)
        assert.are.equal("a text", toast.Text.text)
        assert.are.equal("a hint", toast.Hint.text)
        assert.are.equal(132270, toast.Icon.texture)
        assert.are.same({ 0.2, 0.8, 0.4, 1 }, toast.Accent.color)
        assert.are.same({ 0.2, 0.8, 0.4 }, toast.Title.textColor)
    end)

    it("falls back to a question mark, amber and empty lines", function()
        Kennel:ShowToast({ key = "b", title = "only a title" })
        local toast = client:toast()
        assert.are.equal(134400, toast.Icon.texture)
        assert.are.same({ 1, 0.62, 0.18, 1 }, toast.Accent.color)
        assert.are.equal("", toast.Text.text)
        assert.are.equal("", toast.Hint.text)
    end)

    it("slides in near the top of the screen and fades in", function()
        Kennel:ShowToast(info("a"))
        local toast = client:toast()
        assert.are.equal(0, toast.alpha)
        assert.are.same({ "TOP", UIParent, "TOP", 0, -108 }, toast.points[1], "starts a little higher")
        client:animate(0.3)
        assert.are.equal(1, toast.alpha)
        assert.are.same({ "TOP", UIParent, "TOP", 0, -120 }, toast.points[1])
    end)

    it("stays for the set duration, its timer running down, then fades and hides", function()
        Kennel.db.profile.toast.duration = 2
        Kennel:ShowToast(info("a"))
        local toast = client:toast()
        client:animate(1)
        assert.is_true(toast.shown)
        assert.is_true(toast.Timer.width < 336 and toast.Timer.width > 100, "about half left")
        client:animate(1.2)
        assert.is_true(toast.alpha < 1, "fading")
        client:animate(0.5)
        assert.is_false(toast.shown)
    end)

    it("holds while the mouse is over it", function()
        Kennel.db.profile.toast.duration = 1
        Kennel:ShowToast(info("a"))
        client.mouseOver = true
        client:animate(5)
        assert.is_true(client:toast().shown)
        assert.are.equal(1, client:toast().alpha)
        client.mouseOver = false
        client:animate(0.9)
        assert.is_true(client:toast().shown, "its stay starts counting when the mouse leaves")
        client:animate(0.5)
        assert.is_false(client:toast().shown)
    end)

    it("closes on a right-click, and the next one follows", function()
        Kennel:ShowToast(info("a"))
        Kennel:ShowToast(info("b"))
        local toast = client:toast()
        toast.scripts.OnMouseUp(toast, "LeftButton")
        assert.are.equal("a title", client:toastTitle())
        toast.scripts.OnMouseUp(toast, "RightButton")
        assert.are.equal("b title", client:toastTitle())
    end)

    it("shows toasts one after the other, and one key only once", function()
        Kennel:ShowToast(info("a"))
        Kennel:ShowToast(info("b"))
        Kennel:ShowToast(info("a"))
        Kennel:ShowToast(info("b"))
        client:animate(8)
        assert.are.equal("b title", client:toastTitle())
        client:animate(8)
        assert.is_nil(client:toastTitle(), "no second a or b")
    end)

    it("takes away a solved toast: the one up fades, a waiting one is dropped", function()
        Kennel:ShowToast(info("a"))
        Kennel:ShowToast(info("b"))
        Kennel:ShowToast(info("c"))
        Kennel:DropToast("b")
        Kennel:DropToast("a")
        Kennel:DropToast("a") -- already fading
        client:animate(0.5)
        assert.are.equal("c title", client:toastTitle())
    end)

    it("takes away all of a module's toasts", function()
        Kennel:ShowToast(info("M:a"))
        Kennel:ShowToast(info("Other:b"))
        Kennel:ShowToast(info("M:c"))
        Kennel:DropToasts("M:")
        client:animate(0.5)
        assert.are.equal("Other:b title", client:toastTitle())
        Kennel:DropToasts("M:") -- the one up is another module's: it stays
        assert.are.equal("Other:b title", client:toastTitle())
    end)

    it("plays its sound: a file, a sound kit, or none", function()
        Kennel:ShowToast(info("a", { sound = { file = 562387 } }))
        Kennel:HideToast()
        Kennel:ShowToast(info("b", { sound = { kit = 8959 } }))
        Kennel:HideToast()
        Kennel:ShowToast(info("c"))
        assert.are.same({ { file = 562387, channel = "Master" }, { kit = 8959, channel = "Master" } }, client.sounds)
    end)

    it("takes its size from the settings", function()
        Kennel.db.profile.toast.scale = 1.5
        Kennel:ShowToast(info("a"))
        assert.are.equal(1.5, client:toast().scale)
    end)

    it("is as high as the icon when the text is short", function()
        Kennel:ShowToast(info("a"))
        assert.are.equal(40 + 24, client:toast().height)
    end)

    it("moves where it is dragged, keeps that spot, and goes back on a reset", function()
        Kennel:ShowToast(info("a"))
        local toast = client:toast()
        toast.scripts.OnDragStart(toast)
        toast.scripts.OnDragStop(toast)
        assert.are.same({ "TOPLEFT", "BOTTOMLEFT", 300, 700 }, Kennel.db.profile.toast.pos)
        Kennel:HideToast()
        Kennel:ShowToast(info("b"))
        client:animate(0.3)
        assert.are.same({ "TOPLEFT", UIParent, "BOTTOMLEFT", 300, 700 }, toast.points[1])
        Kennel:ResetToastPosition()
        assert.is_nil(Kennel.db.profile.toast.pos)
    end)

    it("keeps no spot from a drop the client cannot place", function()
        Kennel:ShowToast(info("a"))
        local toast = client:toast()
        toast.StopMovingOrSizing = function(self)
            self.points = {}
        end
        toast.scripts.OnDragStop(toast)
        assert.is_nil(Kennel.db.profile.toast.pos)
    end)
end)

describe("the toast settings", function()
    local client, Kennel, args

    before_each(function()
        client = quiet()
        Kennel = client.Kennel
        args = Kennel:GetOptionsTable().args.modules.args.toast.args
    end)

    it("set how long it stays and its size", function()
        args.duration.set({}, 9)
        args.scale.set({}, 1.25)
        assert.are.equal(9, args.duration.get())
        assert.are.equal(1.25, args.scale.get())
        assert.are.same({ duration = 9, scale = 1.25 }, Kennel.db.profile.toast)
    end)

    it("reset its spot and show an example", function()
        Kennel.db.profile.toast.pos = { "TOP", "TOP", 0, 0 }
        args.reset.func()
        assert.is_nil(Kennel.db.profile.toast.pos)
        args.test.func()
        assert.are.equal("This is a toast", client:toastTitle())
    end)
end)
