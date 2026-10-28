-- Loaded once by busted before the spec files (see .busted). Reads Beastkeeper.toc the way the client
-- does, every .xml in it expanded to the Lua files it names, and defines NewClient (tests/wow.lua).
-- busted runs from the repository root, so paths are relative to it.

local sh = require("tests.sh")

---The Lua files an .xml loads, in order, following <Include>s. Comments are skipped.
---@param file string
---@return string[]
local function expandXml(file)
    local text = sh.read(file):gsub("<!%-%-.-%-%->", "")
    local dir = file:match("^(.*)/") or "."
    local files = {}
    for tag, path in text:gmatch('<(%a+)%s+file="([^"]+)"') do
        local target = dir .. "/" .. path:gsub("\\", "/")
        if tag == "Include" then
            for _, f in ipairs(expandXml(target)) do
                files[#files + 1] = f
            end
        elseif tag == "Script" then
            files[#files + 1] = target
        end
    end
    return files
end

---A .toc's load order (every file it names, .xml files expanded) and its "## Key: value" lines.
---@param name string
---@return string[] files
---@return table<string, string> metadata
local function readToc(name)
    local toc = sh.read(name)
    local files, metadata = {}, {}
    for line in toc:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            line = line:gsub("\\", "/")
            if line:match("%.xml$") then
                for _, file in ipairs(expandXml(line)) do
                    files[#files + 1] = file
                end
            else
                files[#files + 1] = line
            end
        end
    end
    for key, value in toc:gmatch("## ([^:\r\n]+):%s*([^\r\n]-)%s*\r?\n") do
        metadata[key] = value
    end
    return files, metadata
end

-- WoW: Forever's Beastkeeper_Forever.toc, and Classic Era's Beastkeeper_Vanilla.toc (NewClient's `era`
-- option). The other clients' tocs load the same files without data.
TOC_FILES, TOC_METADATA = readToc("Beastkeeper_Forever.toc")
ERA_TOC_FILES, ERA_TOC_METADATA = readToc("Beastkeeper_Vanilla.toc")
TOC_SAVED = TOC_METADATA.SavedVariables

dofile("tests/wow.lua")
