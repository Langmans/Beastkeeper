-- Fetches the libraries listed under `externals:` in .pkgmeta into Libs/, at the same commits the
-- packager uses for a release. tests/check.lua runs it before the tests; a library already at its
-- pinned commit is left alone, so after the first fetch this needs no network.
--
-- Only the shape .pkgmeta uses here is understood: a git url, a commit and a path inside the
-- repository. Each repository is fetched once into .cache/ and the paths are copied out of it.

local lfs = require("lfs")
local sh = require("tests.sh")

local M = {}

---The externals block of .pkgmeta: { dir, url, commit, path } per entry, in file order.
---@param text string
---@return table[]
function M.readExternals(text)
    local externals, inBlock, current = {}, false, nil
    for line in (text .. "\n"):gmatch("([^\r\n]*)\r?\n") do
        if line:match("^%S") then
            inBlock = line:match("^externals:") ~= nil
        elseif inBlock then
            local entry = line:match("^  (%S[^:]*):%s*$")
            local key, value = line:match("^    (%w+):%s*(%S+)%s*$")
            if entry then
                current = { dir = entry }
                externals[#externals + 1] = current
            elseif key and current then
                current[key] = value
            end
        end
    end
    for _, ext in ipairs(externals) do
        assert(ext.url and ext.commit, ".pkgmeta external " .. ext.dir .. " needs a url and a commit")
    end
    return externals
end

local function copyTree(from, to)
    if lfs.attributes(from, "mode") == "directory" then
        sh.mkdir(to)
        for name in lfs.dir(from) do
            if name ~= "." and name ~= ".." and name ~= ".git" then copyTree(from .. "/" .. name, to .. "/" .. name) end
        end
    else
        local source = assert(io.open(from, "rb"))
        local target = assert(io.open(to, "wb"))
        target:write(source:read("*a"))
        source:close()
        target:close()
    end
end

---A checkout of url at commit, cached under .cache/libs/.
local function checkout(url, commit)
    local name = url:match("([^/]+)$"):gsub("%.git$", "")
    local dir = ".cache/libs/" .. name .. "-" .. commit
    if not sh.exists(dir .. "/.done") then
        sh.rmtree(dir)
        sh.mkdir(dir)
        -- Fetching one commit by hash keeps the download to that commit's files.
        sh.run({ "git", "-C", dir, "init", "-q" })
        sh.run({ "git", "-C", dir, "fetch", "-q", "--depth", "1", url, commit })
        sh.run({ "git", "-C", dir, "-c", "advice.detachedHead=false", "checkout", "-q", "FETCH_HEAD" })
        sh.write(dir .. "/.done", "")
    end
    return dir
end

---Brings Libs/ in line with .pkgmeta. Returns true when it fetched anything.
---@return boolean
function M.fetch()
    local externals = M.readExternals(sh.read(".pkgmeta"))
    local stamp = {}
    for _, ext in ipairs(externals) do
        stamp[#stamp + 1] = table.concat({ ext.dir, ext.url, ext.commit, ext.path or "" }, " ")
    end
    stamp = table.concat(stamp, "\n")
    if sh.exists("Libs/.externals") and sh.read("Libs/.externals") == stamp then return false end
    sh.rmtree("Libs")
    sh.mkdir("Libs")
    for _, ext in ipairs(externals) do
        local source = checkout(ext.url, ext.commit) .. (ext.path and "/" .. ext.path or "")
        copyTree(source, ext.dir)
    end
    sh.write("Libs/.externals", stamp)
    return true
end

return M
