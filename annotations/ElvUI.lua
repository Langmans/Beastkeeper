---@meta
-- Editor-only types for the part of ElvUI that Integrations\ElvUI\ uses: the methods its Toolkit
-- (ElvUI\Game\Shared\General\Toolkit.lua) adds to every frame, texture and font string. Not
-- listed in the .toc.

---@class ElvUIFrame: Button
---@field SetTemplate fun(self: ElvUIFrame, template: "Default"|"Transparent"?)
---@field SetBackdropBorderColor fun(self: ElvUIFrame, r: number, g: number, b: number, a: number?)
---@field StyleButton fun(self: ElvUIFrame, noHover: boolean?, noPushed: boolean?, noChecked: boolean?)

---@class ElvUITexture: Texture
---@field SetTexCoords fun(self: ElvUITexture) ElvUI's icon crop

---@class ElvUIFontString: FontString
---@field FontTemplate fun(self: ElvUIFontString, font: string?, size: number?, style: string?)

---ElvUI's media (E.media), as far as Kennel reads it.
---@class ElvUIMedia
---@field rgbvaluecolor number[]? its "value color": { r, g, b }

---ElvUI's engine (E), ElvUI[1].
---@class ElvUIEngine
---@field media ElvUIMedia?

---ElvUI's global: its engine in [1]; nil when it is not loaded.
---@type ElvUIEngine[]?
ElvUI = nil
