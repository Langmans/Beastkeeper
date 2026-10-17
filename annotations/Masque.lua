---@meta
-- Editor-only types for the part of Masque that Integrations\Masque\ uses (Masque's Core\Groups.lua
-- and Core\Group.lua). Not listed in the .toc.

---@class MasqueApi
---@field Group fun(self: MasqueApi, addon: string, group: string?, staticID: string?): MasqueGroup

---@class MasqueGroup
---@field AddButton fun(self: MasqueGroup, button: Button, regions: table<string, Region>?, type: string?, strict: boolean?)
