-- Toast skins: the two Kennel brings, the choice of look for every toast and per kind of toast,
-- and a skin another addon registers.

---A logged-in client without a pet, so no module toasts by itself.
local function quiet()
    local client = NewClient()
    client.pet = nil
    return client:login()
end

---A skin that draws nothing and records what the engine asks of it, as another addon's adapter
---might (one that hands the toast on, say).
local function recordingSkin()
    local skin = { name = "Recorder", calls = {}, hovered = false }
    function skin:Show(info, settings)
        self.calls[#self.calls + 1] = "show " .. info.key .. " " .. settings.duration
    end
    function skin:Update(intro, fade, left)
        self.last = { intro, fade, left }
    end
    function skin:Hide()
        self.calls[#self.calls + 1] = "hide"
    end
    function skin:IsMouseOver()
        return self.hovered
    end
    return skin
end

describe("toast skins", function()
    local client, Kennel

    before_each(function()
        client = quiet()
        Kennel = client.Kennel
    end)

    it("are the card and the splash, the card for every toast unless chosen otherwise", function()
        local skins = Kennel:ToastSkins()
        assert.are.equal("Card: small, near the top", skins.card.name)
        assert.are.equal("Splash: large, in the middle", skins.splash.name)
        assert.are.equal("card", Kennel:ToastSkinFor(nil))
        assert.are.equal("card", Kennel:ToastSkinFor("AutocastCheck:problem"))
    end)

    it("follow the choice for every toast, and a kind's own choice before it", function()
        local settings = Kennel.db.profile.toast
        settings.skin = "splash"
        assert.are.equal("splash", Kennel:ToastSkinFor("AutocastCheck:problem"))
        settings.skins["AutocastCheck:problem"] = "card"
        assert.are.equal("card", Kennel:ToastSkinFor("AutocastCheck:problem"))
        assert.are.equal("splash", Kennel:ToastSkinFor("Other:kind"))
    end)

    it("fall back to the card when the chosen skin is not registered", function()
        local settings = Kennel.db.profile.toast
        settings.skin = "gone"
        settings.skins["AutocastCheck:problem"] = "also gone"
        assert.are.equal("card", Kennel:ToastSkinFor("AutocastCheck:problem"))
    end)

    it("can come from another addon, which gets the toast, the clock and the hover", function()
        local skin = recordingSkin()
        local addon = LibStub("AceAddon-3.0"):GetAddon("Kennel")
        addon:RegisterToastSkin("recorder", skin)
        Kennel.db.profile.toast.skin = "recorder"
        Kennel.db.profile.toast.duration = 1
        Kennel:ShowToast({ key = "x", title = "X" })
        assert.are.same({ "show x 1" }, skin.calls)
        assert.are.same({ 0, 0, 1 }, skin.last)
        assert.is_nil(Kennel:ToastFrame(), "a skin without a frame")
        skin.hovered = true
        client:animate(3)
        assert.are.same({ 1, 0, 1 }, skin.last, "hovered: its stay does not count down")
        skin.hovered = false
        client:animate(2)
        assert.are.same({ "show x 1", "hide" }, skin.calls)
        Kennel:HideToast() -- nothing up any more
    end)
end)

describe("a skin from NewToastSkin", function()
    it("has its name, and hides, answers hover and gives its frame through self.frame", function()
        local client = quiet()
        local skin = client.Kennel:NewToastSkin("Mine")
        skin.frame = client.Kennel:NewToastFrame("MineFrame")
        skin.frame:Show()
        assert.are.equal("Mine", skin.name)
        assert.are.equal(skin.frame, skin:Frame())
        client.mouseOver = true
        assert.is_true(skin:IsMouseOver())
        skin:Hide()
        assert.is_false(skin.frame.shown)
    end)

    it("registers once it adds Show and Update", function()
        local client = quiet()
        local skin = client.Kennel:NewToastSkin("Mine")
        assert.has_error(function()
            client.Kennel:RegisterToastSkin("mine", skin)
        end, "Kennel:RegisterToastSkin(mine): the skin has no Show, Update")
        skin.Show, skin.Update = function() end, function() end
        client.Kennel:RegisterToastSkin("mine", skin)
        assert.are.equal(skin, client.Kennel:ToastSkins().mine)
    end)
end)

describe("the skin contract", function()
    local client, Kennel

    before_each(function()
        client = quiet()
        Kennel = client.Kennel
    end)

    it("refuses a skin without an id, a table, a name or a method, saying what is missing", function()
        assert.has_error(function()
            Kennel:RegisterToastSkin("", recordingSkin())
        end, "Kennel:RegisterToastSkin: id must be a non-empty string")
        assert.has_error(function()
            Kennel:RegisterToastSkin("x", "skin")
        end, "Kennel:RegisterToastSkin(x): skin must be a table")
        local skin = recordingSkin()
        skin.name, skin.Update, skin.Hide = nil, nil, nil
        assert.has_error(function()
            Kennel:RegisterToastSkin("x", skin)
        end, "Kennel:RegisterToastSkin(x): the skin has no name (a string), Update, Hide")
        assert.is_nil(Kennel:ToastSkins().x)
    end)

    it("needs only a name and Show from an instant skin, which hands the toast on at once", function()
        local poured = {}
        local skin = { name = "Hand on", instant = true }
        function skin:Show(info)
            poured[#poured + 1] = info.key
        end
        Kennel:RegisterToastSkin("handon", skin)
        Kennel:ToastSettings().skin = "handon"
        Kennel:ShowToast({ key = "a", title = "t" })
        Kennel:ShowToast({ key = "b", title = "t" })
        assert.are.same({ "a", "b" }, poured)
        assert.has_error(function()
            Kennel:RegisterToastSkin("nothing", { name = "No show", instant = true })
        end, "Kennel:RegisterToastSkin(nothing): the skin has no Show")
    end)

    for _, method in ipairs({ "Show", "Update", "IsMouseOver" }) do
        it("hands a toast to the card when a skin's " .. method .. " errors, and reports it", function()
            local skin = recordingSkin()
            skin[method] = function()
                error("broken " .. method)
            end
            Kennel:RegisterToastSkin("broken", skin)
            Kennel.db.profile.toast.skin = "broken"
            Kennel:ShowToast({ key = "x", title = "Still shown" })
            client:animate(0.1)
            assert.are.equal("Still shown", client:toastTitle())
            assert.truthy(client.errors[1]:find("broken " .. method, 1, true))
        end)
    end

    it("lets a toast go when its skin's Hide errors, without the card showing it again", function()
        local skin = recordingSkin()
        skin.Hide = function()
            error("broken Hide")
        end
        Kennel:RegisterToastSkin("broken", skin)
        Kennel.db.profile.toast.skin = "broken"
        Kennel.db.profile.toast.duration = 1
        Kennel:ShowToast({ key = "x", title = "Goes" })
        client:animate(2)
        assert.is_false(client.Kennel:ToastDriver().shown)
        assert.is_nil(client:toastTitle())
        assert.truthy(client.errors[1]:find("broken Hide", 1, true))
    end)

    it("reports an error of the card itself without replacing it", function()
        local card = Kennel:ToastSkins().card
        local update = card.Update
        card.Update = function()
            error("card broke")
        end
        Kennel:ShowToast({ key = "x", title = "t" })
        card.Update = update
        assert.truthy(client.errors[1]:find("card broke", 1, true))
        assert.are.equal("t", client:toastTitle())
    end)
end)

describe("the splash skin", function()
    local client, Kennel, frame

    before_each(function()
        client = quiet()
        Kennel = client.Kennel
        Kennel.db.profile.toast.skin = "splash"
    end)

    local function show(info)
        Kennel:ShowToast(info)
        frame = client:toast()
    end

    it("shows where it comes from, the icon in a diamond, the title, text and hint", function()
        show({
            key = "a",
            source = "Autocast Check",
            title = "Growl is on autocast",
            text = "reason",
            hint = "hint",
            icon = 132270,
            accent = { 0.2, 0.8, 0.4 },
        })
        assert.are.equal("Autocast Check", frame.Source.text)
        assert.are.same({ 0.2, 0.8, 0.4 }, frame.Source.textColor)
        assert.are.same({ 0.2, 0.8, 0.4, 1 }, frame.Diamond.color)
        assert.are.equal(132270, frame.Icon.texture)
        assert.are.equal("Growl is on autocast", frame.Title.text)
        assert.are.equal("reason", frame.Text.text)
        assert.are.equal("hint", frame.Hint.text)
        assert.are.same({ "CENTER", UIParent, "CENTER", 0, 160 }, frame.points[1], "in the middle, a little up")
    end)

    it("falls back to no source, a question mark, amber and empty lines", function()
        show({ key = "b", title = "only a title" })
        assert.are.equal("", frame.Source.text)
        assert.are.equal(134400, frame.Icon.texture)
        assert.are.same({ 1, 0.62, 0.18, 1 }, frame.Diamond.color)
        assert.are.equal("", frame.Text.text)
        assert.are.equal("", frame.Hint.text)
    end)

    it("fades in while the diamond pops, stays, then fades out", function()
        Kennel.db.profile.toast.duration = 2
        Kennel.db.profile.toast.scale = 1.5
        show({ key = "a", title = "t" })
        assert.are.equal(1.5, frame.scale)
        assert.are.equal(0, frame.alpha)
        assert.is_true(frame.Diamond.width < 46)
        client:animate(0.3)
        assert.are.equal(1, frame.alpha)
        assert.are.equal(46, frame.Diamond.width)
        client:animate(1)
        assert.is_true(frame.Timer.width < 160 and frame.Timer.width > 40)
        client.mouseOver = true
        client:animate(5)
        assert.is_true(frame.shown, "held while hovered")
        client.mouseOver = false
        client:animate(1.5)
        assert.is_false(frame.shown)
    end)

    it("is placed where the toast was dragged to, and closes on a right-click", function()
        Kennel.db.profile.toast.pos = { "TOPLEFT", "BOTTOMLEFT", 300, 700 }
        show({ key = "a", title = "t" })
        assert.are.same({ "TOPLEFT", UIParent, "BOTTOMLEFT", 300, 700 }, frame.points[1])
        frame.scripts.OnMouseUp(frame, "RightButton")
        assert.is_false(frame.shown)
    end)
end)

describe("the look choice", function()
    local client, Kennel, args

    before_each(function()
        client = quiet()
        Kennel = client.Kennel
        args = Kennel:GetOptionsTable().args.modules.args.toast.args
    end)

    it("offers every registered skin for every toast", function()
        assert.are.same({
            card = "Card: small, near the top",
            splash = "Splash: large, in the middle",
            libsink = "Floating text and more (LibSink)",
        }, args.skin.values)
        assert.are.equal("card", args.skin.get())
        args.skin.set({}, "splash")
        assert.are.equal("splash", Kennel.db.profile.toast.skin)
    end)

    it("has a choice per kind of toast, the same as every toast by default", function()
        local kind = args["skin:AutocastCheck:problem"]
        assert.are.equal("Autocast Check: autocast does not fit", kind.name)
        assert.are.equal("Same as all toasts", kind.values.same)
        assert.are.equal("same", kind.get())
        kind.set({}, "splash")
        assert.are.equal("splash", Kennel.db.profile.toast.skins["AutocastCheck:problem"])
        assert.are.equal("splash", kind.get())
        kind.set({}, "same")
        assert.is_nil(Kennel.db.profile.toast.skins["AutocastCheck:problem"])
    end)

    it("lists the kinds of every module in order", function()
        local client2 = NewClient({
            modules = function(K)
                local m = K:NewModule("Aardvark")
                m.toastTypes = { b = "second", a = "first" }
            end,
        })
        client2.pet = nil
        client2:login()
        local all = client2.Kennel:GetOptionsTable().args.modules.args.toast.args
        assert.are.equal("Aardvark: first", all["skin:Aardvark:a"].name)
        assert.is_true(all["skin:Aardvark:a"].order < all["skin:Aardvark:b"].order)
        assert.is_true(all["skin:Aardvark:b"].order < all["skin:AutocastCheck:problem"].order)
    end)

    it("draws AutocastCheck's toasts with the splash when chosen", function()
        local hunter = NewClient():login()
        hunter.Kennel.db.profile.toast.skins["AutocastCheck:problem"] = "splash"
        hunter:autocast(GROWL, false)
        assert.are.equal("Autocast Check", hunter:toast().Source.text)
        assert.are.equal("Growl is not on autocast", hunter:toastTitle())
    end)
end)
