-- The .toc per client: each client loads the one with its suffix (Kennel_Vanilla.toc on Classic Era,
-- Kennel_Forever.toc on WoW: Forever, ...), Kennel.toc where none fits. They differ only in the
-- Interface line and in the client's own Data files.

local sh = require("tests.sh")

local TOCS = {
    ["Kennel.toc"] = { "40402", "38002" },
    ["Kennel_Vanilla.toc"] = { "11509" },
    ["Kennel_TBC.toc"] = { "20506" },
    ["Kennel_Mists.toc"] = { "50504" },
    ["Kennel_Mainline.toc"] = { "120105" },
    ["Kennel_Forever.toc"] = { "16001" },
}

---A .toc's metadata lines (Interface left out) and its files (Data files left out), and its
---interface numbers and Data files.
local function read(name)
    local meta, files, interfaces, data = {}, {}, {}, {}
    for line in sh.read(name):gmatch("[^\r\n]+") do
        local interface = line:match("^## Interface:%s*(.+)$")
        if interface then
            for number in interface:gmatch("%d+") do
                interfaces[#interfaces + 1] = number
            end
        elseif line:match("^##") then
            meta[#meta + 1] = line
        elseif line:match("^Data\\") then
            data[#data + 1] = line
        elseif line ~= "" then
            files[#files + 1] = line
        end
    end
    return meta, files, interfaces, data
end

describe("The .toc files", function()
    it("are one per client, each with its interface numbers", function()
        for name, interfaces in pairs(TOCS) do
            local _, _, found = read(name)
            assert.are.same(interfaces, found, name)
        end
    end)

    it("load the same files with the same metadata, but for each client's own data", function()
        local meta, files = read("Kennel_Forever.toc")
        for name in pairs(TOCS) do
            local otherMeta, otherFiles = read(name)
            assert.are.same(meta, otherMeta, name)
            assert.are.same(files, otherFiles, name)
        end
        local _, _, _, forever = read("Kennel_Forever.toc")
        local _, _, _, era = read("Kennel_Vanilla.toc")
        assert.are.same(
            { "Data\\Forever\\Beasts.lua", "Data\\Forever\\Trainers.lua", "Data\\Forever\\Ammo.lua" },
            forever
        )
        assert.are.same(
            { "Data\\Era\\Beasts.lua", "Data\\Era\\Trainers.lua", "Data\\Era\\Ammo.lua", "Data\\Era\\Food.lua" },
            era
        )
        for _, name in ipairs({ "Kennel.toc", "Kennel_TBC.toc", "Kennel_Mists.toc", "Kennel_Mainline.toc" }) do
            assert.are.same({}, select(4, read(name)), name .. " has no data")
        end
    end)
end)
