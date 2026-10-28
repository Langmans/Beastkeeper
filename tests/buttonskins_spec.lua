-- Button skins: the look of Beastkeeper's buttons (Feeding's) and of what holds them (its food list),
-- registered like toast skins. Beastkeeper brings its own; EllesmereUI, ElvUI and Masque add theirs
-- when loaded. "Automatic" takes the registered one with the highest priority.

---A logged-in client whose pet is content, so the feed button is styled and shown.
---@param opts TestClientOptions?
---@return table
local function content(opts)
    return NewClient(opts):login():stock(12037, 2):setHappiness(2)
end

---A skin that records, per module, the button it styled and the colour last given its border.
---@param priority number
---@param calls table<string, {button: table, icon: table, color: number[]?}>
---@return AddonButtonSkin
local function recording(priority, calls)
    return {
        name = "Recording",
        priority = priority,
        Style = function(button, parts)
            local call = { button = button, icon = parts.icon }
            calls[parts.group] = call
            return function(r, g, b)
                call.color = { r, g, b }
            end
        end,
    }
end

---Whether one of the errors reported says `text`.
---@param client table
---@param text string
---@return boolean
local function reported(client, text)
    for _, err in ipairs(client.errors) do
        if err:find(text, 1, true) then return true end
    end
    return false
end

describe("button skins", function()
    it("refuse a skin without a name or Style, naming what is missing", function()
        local Addon = NewClient():login().Addon
        assert.has_error(function()
            Addon:RegisterButtonSkin("x", {})
        end, "Beastkeeper:RegisterButtonSkin(x): the skin has no name (a string), Style")
        assert.has_error(function()
            Addon:RegisterButtonHolderSkin("x", { name = "X", Style = function() end })
        end, "Beastkeeper:RegisterButtonHolderSkin(x): the skin has no Font")
        assert.has_error(function()
            Addon:RegisterButtonSkin("", {})
        end, "Beastkeeper:RegisterButtonSkin: id must be a non-empty string")
    end)

    it("bring Beastkeeper's own, with its border coloured by the pet's happiness", function()
        local client = content()
        assert.are.equal("beastkeeper", client.Addon:ButtonSkinFor())
        assert.are.equal("beastkeeper", client.Addon:ButtonHolderSkinFor())
        assert.is_true(_G.BeastkeeperFeedButton:IsShown())
    end)

    it("take the one with the highest priority by default, or the one chosen", function()
        local client = NewClient()
        local calls = {}
        client.Addon:RegisterButtonSkin("mine", recording(100, calls))
        client:login():stock(12037, 2):setHappiness(2)
        assert.are.equal("mine", client.Addon:ButtonSkinFor())
        assert.are.equal(_G.BeastkeeperFeedButton, calls.Feeding.button)
        assert.are.same({ 1, 1, 0 }, calls.Feeding.color, "content: yellow")
        assert.are.equal(_G.BeastkeeperLowHealthMarker, calls.CareButton.button)
        assert.are.same({ 1, 0, 0 }, calls.CareButton.color, "the low health marker: red")
        local args = client.Addon:GetOptionsTable().args.modules.args.buttons.args
        args.skin.set(nil, "beastkeeper")
        assert.are.equal("beastkeeper", client.Addon:ButtonSkinFor())
        assert.are.equal("beastkeeper", args.skin.get())
        assert.are.equal("Automatic", args.skin.values().auto)
        args.skin.set(nil, "gone")
        assert.are.equal("mine", client.Addon:ButtonSkinFor(), "a skin no longer there: automatic")
        args.holder.set(nil, "beastkeeper")
        assert.are.equal("beastkeeper", args.holder.get())
    end)

    it("fall back to Beastkeeper's own when a skin errors, and report it", function()
        local client = NewClient()
        client.Addon:RegisterButtonSkin("broken", {
            name = "Broken",
            priority = 100,
            Style = function()
                error("broken Style")
            end,
        })
        client.Addon:RegisterButtonHolderSkin("broken", {
            name = "Broken",
            priority = 100,
            Style = function()
                error("broken holder")
            end,
            Font = function() end,
        })
        client:login():stock(12037, 2):setHappiness(2)
        assert.is_true(reported(client, "broken Style"))
        assert.is_true(_G.BeastkeeperFeedButton:IsShown())
        rawget(_G.BeastkeeperFeedButton, "foodlist")(_G.BeastkeeperFeedButton)
        assert.is_true(reported(client, "broken holder"))
        assert.is_true(_G.BeastkeeperFeedList:IsShown())
    end)

    it("crop icons of their border, or leave them whole for an icon pack without borders", function()
        local client = NewClient():login()
        local option = client.Addon:GetButtonOptions().args.crop
        assert.is_false(option.disabled())
        assert.is_true(option.get(), "cropped by default")
        client.Addon:OpenWindow("abilities")
        local panel = client.Addon.window.panels.abilities
        assert.are.same({ 0.08, 0.92, 0.08, 0.92 }, panel.rows[1].icon.texCoord)
        client = NewClient():login()
        client.Addon:GetButtonOptions().args.crop.set(nil, false)
        client.Addon:OpenWindow("abilities")
        assert.are.same({ 0, 1, 0, 1 }, client.Addon.window.panels.abilities.rows[1].icon.texCoord)
    end)

    describe("with Masque", function()
        it("put the feed button in Masque's Beastkeeper group, with its icon and border", function()
            local client = content({ masque = true })
            assert.are.equal("masque", client.Addon:ButtonSkinFor())
            local added = client.masque.groups["Beastkeeper/Feeding"][1]
            assert.are.equal(_G.BeastkeeperFeedButton, added.button)
            assert.is_not_nil(added.regions.Icon)
            assert.are.same({ 1, 1, 0 }, added.regions.Border.vertexColor, "content: yellow")
            assert.are.equal("beastkeeper", client.Addon:ButtonHolderSkinFor(), "Masque skins no panels")
        end)
    end)

    describe("with ElvUI", function()
        it("give the button and the list ElvUI's template, font and icon crop", function()
            local client = content({ elvui = true })
            assert.are.equal("elvui", client.Addon:ButtonSkinFor())
            assert.are.equal("elvui", client.Addon:ButtonHolderSkinFor())
            local button = _G.BeastkeeperFeedButton
            assert.are.equal("Default", button.template)
            assert.are.same({ 1, 1, 0 }, button.backdropBorderColor, "content: yellow")
            assert.is_true(button.styled)
            rawget(button, "foodlist")(button)
            assert.are.equal("Transparent", _G.BeastkeeperFeedList.template)
            assert.is_true(_G.BeastkeeperFeedChoice1.label.fontTemplate)
            assert.is_true(_G.BeastkeeperFeedChoice1.icon.texCoordsSet)
        end)

        it("draw the toast in ElvUI's look too: its backdrop, font and value colour", function()
            local client = NewClient({ elvui = true, noPet = true }):login()
            for _, id in ipairs({ "elvui", "elvuisplash" }) do
                client.Addon:ToastSettings().skin = id
                client.Addon:ShowToast({ key = id .. ":a", title = "Title", text = "Text" })
                local frame = client:toast()
                assert.are.equal("Transparent", frame.template)
                assert.is_true(frame.Title.fontTemplate)
                assert.is_true(frame.Title.fontSize > frame.Text.fontSize, "the title is bigger")
                assert.are.equal("Title", client:toastTitle())
                client.Addon:HideToast()
            end
            assert.are.equal("ElvUI", client.Addon:ToastSkins().elvui.name)
            client.Addon:ToastSettings().skin = "elvui"
            client.Addon:ShowToast({ key = "b", title = "t" })
            assert.are.same({ 0.1, 0.7, 1, 1 }, client:toast().Accent.color)
        end)

        it("draw Beastkeeper's window in ElvUI's look: its backdrop, close button and value colour", function()
            local client = NewClient({ elvui = true }):login()
            client:slash("")
            local window = _G.BeastkeeperWindow
            assert.are.equal("Transparent", window.template)
            assert.is_true(window.close.elvSkinned, "ElvUI's Skins module styles the close button")
            assert.are.same({ 0.1, 0.7, 1, 1 }, client.Addon.window.tabs.pets.selected.color)
            client.Addon:ShowWindowTab("abilities")
            local row = client.Addon.window.panels.abilities.ranks[1]
            assert.is_true(row.go.icon.texCoordsSet, "ElvUI's icon crop")
        end)

        it("with Eltruism's shadows on, put its shadow around the window and the toast", function()
            local client = NewClient({ elvui = true, eltruism = { enable = true, length = 4 } }):login()
            client:slash("")
            local shadow = _G.BeastkeeperWindow.shadow
            assert.are.equal(4, shadow.length)
            assert.is_true(shadow.eltruismColoured, "in Eltruism's shadow colour")
            client.Addon:ToastSettings().skin = "elvui"
            client.Addon:ShowToast({ key = "a", title = "t" })
            assert.is_not_nil(client:toast().shadow)
        end)

        it("without Eltruism, or with its shadows off, put no shadow", function()
            for _, eltruism in ipairs({ false, { enable = false, length = 4 } }) do
                local client = NewClient({ elvui = true, eltruism = eltruism or nil }):login()
                client:slash("")
                assert.is_nil(rawget(_G.BeastkeeperWindow, "shadow"))
            end
        end)

        it("crop icons as ElvUI's own Crop Icons setting says, shown greyed on Beastkeeper's page", function()
            local client = NewClient({ elvui = true }):login()
            local option = client.Addon:GetButtonOptions().args.crop
            assert.is_true(option.disabled(), "ElvUI's setting decides")
            assert.is_true(option.get(), "ElvUI crops by default")
            client.Addon:OpenWindow("abilities")
            assert.is_true(client.Addon.window.panels.abilities.rows[1].icon.texCoordsSet)
            client = NewClient({ elvui = true }):login()
            ElvUI[1].db.general.cropIcon = 0
            option = client.Addon:GetButtonOptions().args.crop
            assert.is_false(option.get())
            client.Addon:OpenWindow("abilities")
            local icon = client.Addon.window.panels.abilities.rows[1].icon
            assert.is_nil(icon.texCoordsSet)
            assert.are.same({ 0, 1, 0, 1 }, icon.texCoord, "whole")
        end)

        it("rank above EllesmereUI, below Masque", function()
            assert.are.equal("elvui", content({ elvui = true, ellesmere = true }).Addon:ButtonSkinFor())
            assert.are.equal("masque", content({ elvui = true, masque = true }).Addon:ButtonSkinFor())
        end)
    end)
end)
