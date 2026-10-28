-- Every name the game and other addons see is made from the addon's folder name, so a rename is the
-- folder, the .tocs and Bindings.xml (docs\10-renaming.md). Loaded here as "Tester" to prove it.

local sh = require("tests.sh")

---A logged-in client whose folder is called Tester, with a pet out.
---@return table
local function tester()
    return NewClient({ addonName = "Tester" }):login()
end

describe("the addon's names", function()
    it("start from the folder's name", function()
        local addon = tester().Addon
        assert.are.equal("Tester", addon.NAME)
        assert.are.equal("TESTER_TOAST", addon.messages.toast)
        assert.are.equal("TESTER_PET_GROWTH", addon.messages.petGrowth)
    end)

    it("name the saved settings, the window, the toast frames and the secure buttons", function()
        local client = tester()
        assert.is_table(_G.TesterDB)
        client.Addon:OpenWindow()
        assert.is_table(_G.TesterWindow)
        client.Addon:ShowToast({ key = "a", title = "t" })
        assert.is_table(_G.TesterToastCard)
        for _, button in ipairs({ "TesterWindowButton", "TesterAutocastButton", "TesterTameButton" }) do
            assert.is_table(_G[button], button)
        end
    end)

    it("name the messages it sends", function()
        local client = tester()
        local heard
        client.Addon:Listen({}, "TESTER_TOAST", function(_, event)
            heard = event.toast.title
        end)
        client.Addon:ShowToast({ key = "a", title = "Hello" })
        assert.are.equal("Hello", heard)
    end)

    it("name the macros, which call the slash command by that name", function()
        local client = tester()
        for _, macro in ipairs(client.Addon:GetModule("AutocastCheck"):Macros()) do
            assert.truthy(macro.name:find("^Tester"), macro.name)
            assert.is_nil(macro.body:lower():find("/beastkeeper", 1, true), macro.body)
        end
    end)

    it("answer to the slash command by the folder's name and to its short alias", function()
        local client = tester()
        client:slash("config")
        client:slash("config", "bk")
        assert.are.equal(2, #client.opened)
    end)
end)

describe("the names that cannot be made from the folder", function()
    it("match it in the .toc: the saved settings", function()
        assert.are.equal("BeastkeeperDB", TOC_SAVED)
    end)

    it("match it in Bindings.xml: its header and every button it clicks", function()
        local client = NewClient():login()
        local bindings = sh.read("Bindings.xml")
        assert.truthy(bindings:find('header="' .. client.Addon.NAME:upper() .. '"', 1, true))
        for button in bindings:gmatch('name="CLICK ([%w_]+):') do
            assert.truthy(button:find("^" .. client.Addon.NAME), button)
        end
    end)
end)
