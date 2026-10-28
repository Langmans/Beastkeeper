---@meta
-- Editor-only types for the part of LS: Toasts that Integrations\LSToasts\ uses, as its own code
-- defines it (core\toast.lua, core\core.lua). Not listed in the .toc, not in releases.

---Its global: { E, C, L }.
---@class LSToastsGlobal
---@field [1] LSToastsEngine
---@field [2] LSToastsConfig

---@class LSToastsEngine
---@field GetToast fun(self: LSToastsEngine, event: string?, dataType: string, dataValue: any): LSToast, boolean, boolean the toast, whether it is new, whether it is queued

---@class LSToastsConfig
---@field db {profile: {colors: {border: boolean, icon_border: boolean}}}

---A toast frame from E:GetToast, the parts Beastkeeper fills.
---@class LSToast: Frame
---@field _data table its data, which GetToast matches on
---@field Title FontString
---@field Text FontString
---@field Icon Texture
---@field Border Texture
---@field IconBorder Texture
---@field Spawn fun(self: LSToast, anchor: number, dnd: boolean)

---LS: Toasts on the classic clients; nil when it is not loaded.
---@type LSToastsGlobal?
ls_Toasts_Classic = nil

---LS: Toasts on retail; nil when it is not loaded.
---@type LSToastsGlobal?
ls_Toasts = nil
