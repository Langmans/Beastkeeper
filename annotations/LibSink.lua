---@meta
-- Editor-only types for the part of LibSink-2.0 that Integrations\LibSink\ uses, as its own code
-- defines it (Libs\LibSink-2.0\LibSink-2.0.lua). Not listed in the .toc.

---A table LibSink:Embed gave its methods; LibSink keeps the output choice by that table.
---@class LibSinkOutput
---@field Pour fun(self: LibSinkOutput, text: string, r: number?, g: number?, b: number?, font: string?, size: number?, outline: string?, sticky: boolean?, location: string?, icon: (number|string)?)
---@field GetSinkAce3OptionsDataTable fun(self: LibSinkOutput): table

---@class LibSinkLibrary
---@field Embed fun(self: LibSinkLibrary, target: table): LibSinkOutput
---@field SetSinkStorage fun(addon: table, storage: table)
