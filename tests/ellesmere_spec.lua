-- The EllesmereUI skin: a card in EllesmereUI's look, there only when EllesmereUI is loaded.

---A logged-in client without a pet, with or without EllesmereUI.
local function quiet(ellesmere)
    local client = NewClient({ ellesmere = ellesmere })
    client.pet = nil
    return client:login()
end

---The borders EllesmereUI made around `frame`, as { frame, r, g, b, a }.
---@param client table
---@param frame table
---@return table[]
local function bordersOf(client, frame)
    local found = {}
    for _, border in ipairs(client.eui.borders) do
        if border[1] == frame then found[#found + 1] = border end
    end
    return found
end

describe("the EllesmereUI skin", function()
    it("is not there without EllesmereUI", function()
        assert.is_nil(quiet().Kennel:ToastSkins().ellesmere)
    end)

    it("is there with EllesmereUI, named after it", function()
        local skin = quiet(true).Kennel:ToastSkins().ellesmere
        assert.is_table(skin)
        assert.are.equal("EllesmereUI", skin.name)
    end)

    describe("drawing a toast", function()
        local client, frame

        before_each(function()
            client = quiet(true)
            client.Kennel:ToastSettings().skin = "ellesmere"
        end)

        local function show(info)
            client.Kennel:ShowToast(info)
            frame = client:toast()
        end

        it("uses EllesmereUI's font, outline and shadow for every line", function()
            show({ key = "a", title = "Title", text = "Text", hint = "Hint" })
            for _, line in ipairs({ frame.Title, frame.Text, frame.Hint }) do
                assert.are.equal("Fonts\\Expressway.ttf", line.font[1])
                assert.are.equal("OUTLINE", line.font[3])
            end
            assert.is_true(frame.Title.font[2] > frame.Text.font[2], "the title is bigger")
            assert.are.equal(3, #client.eui.shadows)
            assert.is_true(client.eui.shadows[1][2])
        end)

        it("has EllesmereUI's border and dark panel", function()
            show({ key = "a", title = "t" })
            assert.are.same({ { frame, 0, 0, 0, 1 } }, bordersOf(client, frame), "made once")
            client.Kennel:HideToast()
            show({ key = "b", title = "t" })
            assert.are.equal(1, #bordersOf(client, frame))
        end)

        it("takes EllesmereUI's accent when the toast brings none", function()
            show({ key = "a", title = "t" })
            assert.are.same({ 0.05, 0.82, 0.62, 1 }, frame.Accent.color)
            client.Kennel:HideToast()
            show({ key = "b", title = "t", accent = { 1, 0, 0 } })
            assert.are.same({ 1, 0, 0, 1 }, frame.Accent.color)
        end)

        it("is a frame of its own, next to Kennel's card", function()
            show({ key = "a", title = "t" })
            assert.are.equal("KennelToastEllesmere", frame.name)
            client.Kennel:ToastSettings().skin = "card"
            client.Kennel:HideToast()
            show({ key = "b", title = "t" })
            assert.are.equal("KennelToastCard", frame.name)
            assert.is_nil(frame.font, "the card keeps the game's fonts")
        end)
    end)

    describe("as a splash", function()
        local client, frame

        before_each(function()
            client = quiet(true)
            client.Kennel:ToastSettings().skin = "ellesmeresplash"
            client.Kennel:ShowToast({ key = "a", source = "Autocast Check", title = "Title", text = "Text" })
            frame = client:toast()
        end)

        it("is a skin of its own, named after EllesmereUI", function()
            assert.are.equal("EllesmereUI (splash)", client.Kennel:ToastSkins().ellesmeresplash.name)
            assert.are.equal("KennelToastEllesmereSplash", frame.name)
        end)

        it("uses EllesmereUI's font for every line, its border, panel and accent", function()
            for _, line in ipairs({ frame.Source, frame.Title, frame.Text, frame.Hint }) do
                assert.are.equal("Fonts\\Expressway.ttf", line.font[1])
            end
            assert.are.same({ { frame, 0, 0, 0, 1 } }, bordersOf(client, frame))
            assert.are.same({ 0.05, 0.82, 0.62, 1 }, frame.Diamond.color)
            assert.are.equal("Title", client:toastTitle())
        end)
    end)

    it("leaves Kennel's splash in its own look", function()
        local client = quiet(true)
        client.Kennel:ToastSettings().skin = "splash"
        client.Kennel:ShowToast({ key = "a", title = "t" })
        assert.are.equal("KennelToastSplash", client:toast().name)
        assert.is_nil(client:toast().Title.font)
        assert.are.same({}, bordersOf(client, client:toast()))
    end)

    describe("Feeding's button and food list", function()
        it("have EllesmereUI's border, the button's coloured by happiness, beside its pet frame", function()
            local client = NewClient({ ellesmere = true }):login():stock(12037, 2):setHappiness(2)
            local button = _G.KennelFeedButton
            assert.are.same({ { button, 1, 1, 0, 1 } }, bordersOf(client, button), "content: yellow")
            assert.are.equal(EllesmereUIUnitFrames_Pet, select(2, button:GetPoint()))
            rawget(button, "foodlist")(button)
            assert.are.equal(1, #bordersOf(client, _G.KennelFeedList))
            assert.are.equal("Fonts\\Expressway.ttf", _G.KennelFeedChoice1.label.font[1])
        end)

        it("keep Kennel's own look without EllesmereUI's border helper", function()
            local client = NewClient({ ellesmere = { MakeBorder = false } }):login():setHappiness(2)
            assert.are.same({}, client.eui.borders)
            assert.is_true(_G.KennelFeedButton:IsShown())
        end)
    end)

    it("still draws with an EllesmereUI that has no border or shadow helper", function()
        local client = quiet({ MakeBorder = false, PrimeFontShadow = false })
        client.Kennel:ToastSettings().skin = "ellesmere"
        client.Kennel:ShowToast({ key = "a", title = "Still here" })
        assert.are.equal("Still here", client:toastTitle())
        assert.are.same({}, client.errors)
    end)
end)
