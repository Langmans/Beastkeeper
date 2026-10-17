---@meta
-- Types for the messages Kennel sends (docs\hooking.md), for the Lua language server of an addon
-- that listens: add Kennel's docs folder to its library (in .luarc.json, "workspace.library":
-- ["<AddOns>/Kennel/docs"]) and annotate a handler's table, e.g. `---@param event KennelToastEvent`.
-- Never loaded in game: not in the .toc. Kennel's own code uses the same types.
--
-- Each message hands over one table. Fields may be added; the ones here keep their name and meaning.

---KENNEL_TOAST: a toast is about to show, or to wait for the one that is up.
---@class KennelToastEvent
---@field module string? the part of the toast's key before the colon
---@field toast KennelToastInfo Kennel's own table: change it and the toast shows the change

---KENNEL_PRINT: Kennel printed a line in chat.
---@class KennelPrintEvent
---@field module string? the module that said it; nil for Kennel's core
---@field line string the line as printed, without Kennel's chat prefix

---KENNEL_RANKS_KNOWN: Ability Learned learned of pet ability ranks the hunter knows that it did
---not know before; once per learn, once per opening of the Beast Training window.
---@class KennelRanksKnownEvent
---@field module string "AbilityLearned"
---@field source "learn"|"training" a learn it saw, or the Beast Training window
---@field ranks KennelKnownRank[] the ranks that were news

---@class KennelKnownRank
---@field name string the ability's name in the client's language
---@field rank number

---A toast, as Kennel:ShowToast takes it and KENNEL_TOAST hands it over.
---@class KennelToastInfo
---@field key string one toast per key; "<module>:<what>", so the module can drop its own
---@field type string? "<module>:<kind>", one of the module's toastTypes: picks the skin
---@field source string? who it comes from, such as the module's title (the splash shows it)
---@field title string
---@field text string?
---@field hint string? shown in grey below the text
---@field icon (number|string)? FileDataID or texture path; a question mark without
---@field accent number[]? { r, g, b } for the side bar, the title and the timer; amber without
---@field sound KennelSound?
---@field portrait string? a unit ("pet") whose portrait shows as a badge on the icon while it exists
---@field screenshot boolean? take a screenshot once the toast has faded in

---A toast sound: a sound file, or a sound kit.
---@class KennelSound
---@field file number? FileDataID for PlaySoundFile
---@field kit number? SoundKit ID for PlaySound
