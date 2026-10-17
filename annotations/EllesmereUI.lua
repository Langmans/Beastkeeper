---@meta
-- Editor-only types for the part of EllesmereUI that Integrations\EllesmereUI\ uses, as its own
-- code defines it (EllesmereUI.lua, EllesmereUI_Fonts.lua). Not listed in the .toc.

---@class EllesmereUIColor
---@field r number
---@field g number
---@field b number

---@class EllesmereUIApi
---@field ELLESMERE_GREEN EllesmereUIColor? the theme colour the player chose
---@field GetFontPath fun(addonKey: string?): string the global font without a key
---@field GetFontOutlineFlag fun(addonKey: string?): string
---@field GetFontUseShadow fun(addonKey: string?): boolean
---@field PrimeFontShadow (fun(text: FontString, useShadow: boolean))?
---@field MakeBorder (fun(parent: Frame, r: number, g: number, b: number, a: number): EllesmereUIBorder)?

---A border MakeBorder drew.
---@class EllesmereUIBorder
---@field SetColor fun(self: EllesmereUIBorder, r: number, g: number, b: number, a: number?)

---EllesmereUI's global table; nil when it is not loaded.
---@type EllesmereUIApi?
EllesmereUI = nil
