---@meta
-- Editor-only types for the parts of HandyNotes that Modules\BeastMap uses, as its own code
-- (HandyNotes.lua) defines them. Not listed in the .toc.

---@class HandyNotesApi
---@field plugins table<string, table> registered plugin handlers, by plugin name
---@field RegisterPluginDB fun(self: HandyNotesApi, name: string, handler: table, options: table?)
---@field getCoord fun(self: HandyNotesApi, x: number, y: number): number x and y from 0 to 1
---@field getXY fun(self: HandyNotesApi, coord: number): number, number
---@field UpdateWorldMapPlugin fun(self: HandyNotesApi, name: string)
---@field UpdateMinimapPlugin fun(self: HandyNotesApi, name: string)

---HandyNotes' addon object; nil when it is not loaded.
---@type HandyNotesApi?
HandyNotes = nil
