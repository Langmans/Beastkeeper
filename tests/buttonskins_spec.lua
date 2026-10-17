-- Button skins: the look of Kennel's buttons (Feeding's) and of what holds them (its food list),
-- registered like toast skins. Kennel brings its own; EllesmereUI, ElvUI and Masque add theirs
-- when loaded. "Automatic" takes the registered one with the highest priority.

---A logged-in client whose pet is content, so the feed button is styled and shown.
---@param opts TestClientOptions?
---@return table
local function content(opts)
    return NewClient(opts):login():stock(12037, 2):setHappiness(2)
end

---A skin that records what it was asked, with this priority.
---@param priority number
---@param calls table
---@return KennelButtonSkin
local function recording(priority, calls)
    return {
        name = "Recording",
        priority = priority,
        Style = function(button, parts)
            calls[#calls + 1] = { button, parts.icon, parts.group }
            return function(r, g, b)
                calls.color = { r, g, b }
            end
        end,
    }
end

describe("button skins", function()
    it("refuse a skin without a name or Style, naming what is missing", function()
        local Kennel = NewClient():login().Kennel
        assert.has_error(function()
            Kennel:RegisterButtonSkin("x", {})
        end, "Kennel:RegisterButtonSkin(x): the skin has no name (a string), Style")
        assert.has_error(function()
            Kennel:RegisterButtonHolderSkin("x", { name = "X", Style = function() end })
        end, "Kennel:RegisterButtonHolderSkin(x): the skin has no Font")
        assert.has_error(function()
            Kennel:RegisterButtonSkin("", {})
        end, "Kennel:RegisterButtonSkin: id must be a non-empty string")
    end)

    it("bring Kennel's own, with its border coloured by the pet's happiness", function()
        local client = content()
        assert.are.equal("kennel", client.Kennel:ButtonSkinFor())
        assert.are.equal("kennel", client.Kennel:ButtonHolderSkinFor())
        assert.is_true(_G.KennelFeedButton:IsShown())
    end)

    it("take the one with the highest priority by default, or the one chosen", function()
        local client = NewClient()
        local calls = {}
        client.Kennel:RegisterButtonSkin("mine", recording(100, calls))
        client:login():stock(12037, 2):setHappiness(2)
        assert.are.equal("mine", client.Kennel:ButtonSkinFor())
        assert.are.same({ _G.KennelFeedButton, calls[1][2], "Feeding" }, calls[1])
        assert.are.same({ 1, 1, 0 }, calls.color, "content: yellow")
        local args = client.Kennel:GetOptionsTable().args.modules.args.buttons.args
        args.skin.set(nil, "kennel")
        assert.are.equal("kennel", client.Kennel:ButtonSkinFor())
        assert.are.equal("kennel", args.skin.get())
        assert.are.equal("Automatic", args.skin.values().auto)
        args.skin.set(nil, "gone")
        assert.are.equal("mine", client.Kennel:ButtonSkinFor(), "a skin no longer there: automatic")
        args.holder.set(nil, "kennel")
        assert.are.equal("kennel", args.holder.get())
    end)

    it("fall back to Kennel's own when a skin errors, and report it", function()
        local client = NewClient()
        client.Kennel:RegisterButtonSkin("broken", {
            name = "Broken",
            priority = 100,
            Style = function()
                error("broken Style")
            end,
        })
        client.Kennel:RegisterButtonHolderSkin("broken", {
            name = "Broken",
            priority = 100,
            Style = function()
                error("broken holder")
            end,
            Font = function() end,
        })
        client:login():stock(12037, 2):setHappiness(2)
        assert.truthy(client.errors[1]:find("broken Style", 1, true))
        assert.is_true(_G.KennelFeedButton:IsShown())
        rawget(_G.KennelFeedButton, "foodlist")(_G.KennelFeedButton)
        assert.truthy(client.errors[2]:find("broken holder", 1, true))
        assert.is_true(_G.KennelFeedList:IsShown())
    end)

    describe("with Masque", function()
        it("put the feed button in Masque's Kennel group, with its icon and border", function()
            local client = content({ masque = true })
            assert.are.equal("masque", client.Kennel:ButtonSkinFor())
            local added = client.masque.groups["Kennel/Feeding"][1]
            assert.are.equal(_G.KennelFeedButton, added.button)
            assert.is_not_nil(added.regions.Icon)
            assert.are.same({ 1, 1, 0 }, added.regions.Border.vertexColor, "content: yellow")
            assert.are.equal("kennel", client.Kennel:ButtonHolderSkinFor(), "Masque skins no panels")
        end)
    end)

    describe("with ElvUI", function()
        it("give the button and the list ElvUI's template, font and icon crop", function()
            local client = content({ elvui = true })
            assert.are.equal("elvui", client.Kennel:ButtonSkinFor())
            assert.are.equal("elvui", client.Kennel:ButtonHolderSkinFor())
            local button = _G.KennelFeedButton
            assert.are.equal("Default", button.template)
            assert.are.same({ 1, 1, 0 }, button.backdropBorderColor, "content: yellow")
            assert.is_true(button.styled)
            rawget(button, "foodlist")(button)
            assert.are.equal("Transparent", _G.KennelFeedList.template)
            assert.is_true(_G.KennelFeedChoice1.label.fontTemplate)
            assert.is_true(_G.KennelFeedChoice1.icon.texCoordsSet)
        end)

        it("rank above EllesmereUI, below Masque", function()
            assert.are.equal("elvui", content({ elvui = true, ellesmere = true }).Kennel:ButtonSkinFor())
            assert.are.equal("masque", content({ elvui = true, masque = true }).Kennel:ButtonSkinFor())
        end)
    end)
end)
