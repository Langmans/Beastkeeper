---@meta
-- Types for the messages Kennel sends (docs\04-hooking.md), for the Lua language server of an addon
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

---KENNEL_ABILITY_LEARNED: the hunter learned a pet ability from a tamed beast (Ability Learned saw
---it; Beast Training's window is KENNEL_RANKS_KNOWN).
---@class KennelAbilityLearnedEvent
---@field module string "AbilityLearned"
---@field name string the ability's name in the client's language
---@field rank number 1 when the client named no rank
---@field pet string? the pet that taught it; nil when it was not out
---@field npc number? the NPC ID that pet was tamed as
---@field zone string? where it happened

---KENNEL_PET_GROWTH (core, through Kennel:Listen): the pet out's training points total, level or
---loyalty level changed since it was last seen (kept per pet name, also across a relog).
---@class KennelPetGrowthEvent
---@field pet string
---@field level number
---@field loyalty number? nil when the client does not tell it
---@field loyaltyName string? the loyalty level's name, when the client gives one
---@field points number the training points total
---@field free number the points not spent
---@field before { level: number, loyalty: number?, points: number }

---KENNEL_AUTOCAST_WANTED: what Autocast Check wants on autocast changed, or what decided it.
---@class KennelAutocastWantedEvent
---@field module string "AutocastCheck"
---@field wanted "growl"|"cower"
---@field why "solo"|"dungeon"|"chosen" alone or in a group outside, in a dungeon group, or a macro chose
---@field before "growl"|"cower"

---KENNEL_RARE_SEEN: a rare beast that teaches a rank the hunter lacks came in sight; once per spawn.
---@class KennelRareSeenEvent
---@field module string "BeastMap"
---@field npc number
---@field name string in the client's language once it knows the beast, else English
---@field guid string the creature's GUID
---@field ranks number[] the spell IDs of the ranks it would teach

---KENNEL_AMMO: the hunter's ammo count crossed a line: low, critically low, or back to enough.
---@class KennelAmmoEvent
---@field module string "Ammo"
---@field count number
---@field state "ok"|"low"|"critical"
---@field kind number what the hunter's ranged weapon shoots: Kennel.ammoKinds.arrow (2) or .bullet (3)

---KENNEL_PET_HAPPINESS (core, through Kennel:Listen): the pet out's happiness changed.
---@class KennelPetHappinessEvent
---@field happiness number 1 unhappy, 2 content, 3 happy
---@field before number? nil for a pet just out

---KENNEL_PET_DIED (core, through Kennel:Listen): the pet out died.
---@class KennelPetDiedEvent
---@field pet string?

---KENNEL_PET_TAMED (core, through Kennel:Listen): the pet that came out after a Tame Beast cast.
---@class KennelPetTamedEvent
---@field pet string?
---@field npc number? the NPC ID it was tamed as
---@field petNumber number? the number the pet keeps through renames and the stable; nil until the next relog, while its GUID is still the beast's

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
