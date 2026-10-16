---@meta
-- Editor-only types for the parts of LibSink-2.0 and MessageQueue that Integrations\ uses, as
-- their own code defines them. Not listed in the .toc.

---A table LibSink:Embed gave its methods; LibSink keeps the output choice by that table.
---@class LibSinkOutput
---@field Pour fun(self: LibSinkOutput, text: string, r: number?, g: number?, b: number?, font: string?, size: number?, outline: string?, sticky: boolean?, location: string?, icon: (number|string)?)
---@field GetSinkAce3OptionsDataTable fun(self: LibSinkOutput): table

---@class LibSinkLibrary
---@field Embed fun(self: LibSinkLibrary, target: table): LibSinkOutput
---@field SetSinkStorage fun(addon: table, storage: table)
---@field RegisterSink fun(self: LibSinkLibrary, shortName: string, name: string, desc: string?, func: fun(addon: table, text: string), scrollAreaFunc: (fun(): string[])?)
---@field channelMapping table<string, string> channel name -> chat type ("SAY", "GROUP", "CHANNEL", ...)
---@field channelMappingIds table<string, number> custom channel name -> its number
---@field storageForAddon table<table, {sink20OutputSink: string?, sink20ScrollArea: string?}>

---@class MessageQueueApi
---@field SendChatMessage fun(text: string, chatType: string, languageID: string?, target: (string|number)?) like the game's; SAY, YELL and CHANNEL wait for the next hardware event

---MessageQueue's global table; nil when it is not loaded.
---@type MessageQueueApi?
MessageQueue = nil
