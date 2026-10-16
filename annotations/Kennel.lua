---@meta
-- Editor-only types for Kennel's own tables: the addon object and the module contract. Not
-- listed in the .toc, so the game never loads this file. The Ace3 types (AceModule,
-- AceDBObject-3.0, AceConfig.OptionsTable, ...) come with WoW Lua LS.

---One slash command of a module: `/kennel <module.command> <name> <args>`.
---@class KennelCommand
---@field desc string one line for /kennel help
---@field func fun(module: KennelModule, args: string) gets the rest of the line, "" when there is none

---What a module may declare, besides AceAddon's OnInitialize/OnEnable/OnDisable. OnDisable must
---undo everything OnEnable did: it also runs on every profile change (see Core\Addon.lua).
---@class KennelModule: AceModule, AceEvent-3.0
---@field title string? shown on its switch and its options page; the module name otherwise
---@field description string? the tooltip of its switch
---@field enabledByDefault boolean? false keeps it off until switched on; on otherwise
---@field defaults AceDB.Schema? AceDB defaults; the module then has db, its own namespace
---@field db AceDBObject-3.0? set by the core before the module's OnInitialize, when it has defaults
---@field command string? the word after /kennel that reaches its commands
---@field commands table<string, KennelCommand>? by the word after `command`, lowercase
---@field GetOptions (fun(self: KennelModule): table)? an AceConfig group (args, and name if not title); the core adds type and disabled

---A module that offers macros (Kennel:OfferMacros, Kennel:CreateMacros).
---@class KennelMacroModule: KennelModule
---@field Macros fun(self: KennelMacroModule): KennelMacro[]

---A macro a module makes for the player.
---@class KennelMacro
---@field name string at most 16 characters
---@field icon number|string FileDataID or texture path
---@field body string the macro text

---A toast sound: a sound file, or a sound kit.
---@class KennelSound
---@field file number? FileDataID for PlaySoundFile
---@field kit number? SoundKit ID for PlaySound

---What Kennel:ShowToast shows.
---@class KennelToastInfo
---@field key string one toast per key; "<module>:<what>", so the module can drop its own
---@field title string
---@field text string?
---@field hint string? shown in grey below the text
---@field icon (number|string)? FileDataID or texture path; a question mark without
---@field accent number[]? { r, g, b } for the side bar, the title and the timer; amber without
---@field sound KennelSound?

---The toast's saved settings, profile.toast.
---@class KennelToastSettings
---@field duration number seconds it stays before it fades
---@field scale number
---@field pos [string, string, number, number]? point, relativePoint, x, y, once dragged

---The toast frame, with its parts as fields like a template's parentKeys.
---@class KennelToastFrame: Frame
---@field Accent Texture the coloured side bar
---@field Icon Texture
---@field Title FontString
---@field Text FontString
---@field Hint FontString
---@field Timer Texture the bar along the bottom that runs down

---The mode in force: solo or dungeon as AutocastCheck picks it, kite or tank as the player chose.
---@alias KennelAutocastMode "solo"|"dungeon"|"kite"|"tank"

---AutocastCheck's saved settings, its namespace's profile.
---@class KennelAutocastSettings
---@field mode "auto"|"kite"|"tank" auto lets the module pick solo or dungeon
---@field growl boolean watch Growl
---@field cower boolean watch Cower
---@field remind boolean toast what is still wrong when combat starts
---@field sound "family"|"warning"|"off"

---@class KennelAutocastCheck: KennelMacroModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field active table<string, KennelToastInfo> the problems the last check found
---@field checkPending boolean? a check is on its way (ScheduleCheck)
---@field Settings fun(self: KennelAutocastCheck): KennelAutocastSettings used by Options.lua too
---@field Check fun(self: KennelAutocastCheck, remindAll: boolean?) used by Options.lua too
---@field TestToast fun(self: KennelAutocastCheck) used by Options.lua too

---An ability that can autocast, as AutocastCheck reads it from the pet.
---@class KennelAutocastState
---@field on boolean
---@field icon (number|string)? from the pet bar; nil for one only in the spellbook

---Any value the game hands over, before the addon checks its type.
---@alias GameValue string|number|boolean|table|nil

---The addon object, which is also the files' namespace (`local _, ns = ...`).
---@class Kennel: AceAddon, AceConsole-3.0, AceEvent-3.0
---@field L table<string, string> the AceLocale strings
---@field db AceDBObject-3.0 KennelDB; profile.modules[name] holds each module's switch
---@field modules table<string, KennelModule> AceAddon's own module table, by name
---@field optionsCategoryID string|number the settings page, for Settings.OpenToCategory
---@field PROFILE_OPTIONS string[] the keys of AceDBOptions' own Profiles entries, see Core\Options.lua
