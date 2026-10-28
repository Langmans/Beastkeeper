---@meta
-- Types for the messages Beastkeeper sends (docs\04-hooking.md), for the Lua language server of an addon
-- that listens: add Beastkeeper's docs folder to its library (in .luarc.json, "workspace.library":
-- ["<AddOns>/Beastkeeper/docs"]) and annotate a handler's table, e.g. `---@param event BeastkeeperToastEvent`.
-- Never loaded in game: not in the .toc. Beastkeeper's own code uses the same types.
--
-- Each message hands over one table. Fields may be added; the ones here keep their name and meaning.

---BEASTKEEPER_TOAST: a toast is about to show, or to wait for the one that is up.
---@class BeastkeeperToastEvent
---@field module string? the part of the toast's key before the colon
---@field toast BeastkeeperToastInfo Addon's own table: change it and the toast shows the change

---BEASTKEEPER_PRINT: Beastkeeper printed a line in chat.
---@class BeastkeeperPrintEvent
---@field module string? the module that said it; nil for Addon's core
---@field line string the line as printed, without Addon's chat prefix

---BEASTKEEPER_RANKS_KNOWN: Ability Learned learned of pet ability ranks the hunter knows that it did
---not know before; once per learn, once per opening of the Beast Training window.
---@class BeastkeeperRanksKnownEvent
---@field module string "AbilityLearned"
---@field source "learn"|"training" a learn it saw, or the Beast Training window
---@field ranks BeastkeeperKnownRank[] the ranks that were news

---BEASTKEEPER_ABILITY_LEARNED: the hunter learned a pet ability from a tamed beast (Ability Learned saw
---it; Beast Training's window is BEASTKEEPER_RANKS_KNOWN).
---@class BeastkeeperAbilityLearnedEvent
---@field module string "AbilityLearned"
---@field name string the ability's name in the client's language
---@field rank number 1 when the client named no rank
---@field pet string? the pet that taught it; nil when it was not out
---@field npc number? the NPC ID that pet was tamed as
---@field zone string? where it happened

---BEASTKEEPER_PET_GROWTH (core, through Beastkeeper:Listen): the pet out's training points total, level or
---loyalty level changed since it was last seen (kept per pet name, also across a relog).
---@class BeastkeeperPetGrowthEvent
---@field pet string
---@field level number
---@field loyalty number? nil when the client does not tell it
---@field loyaltyName string? the loyalty level's name, when the client gives one
---@field points number the training points total
---@field free number the points not spent
---@field before { level: number, loyalty: number?, points: number }

---BEASTKEEPER_AUTOCAST_WANTED: what Autocast Check wants on autocast changed, or what decided it.
---@class BeastkeeperAutocastWantedEvent
---@field module string "AutocastCheck"
---@field wanted "growl"|"cower"
---@field why "solo"|"dungeon"|"chosen" alone or in a group outside, in a dungeon group, or a macro chose
---@field before "growl"|"cower"

---BEASTKEEPER_RARE_SEEN: a rare beast that teaches a rank the hunter lacks came in sight; once per spawn.
---@class BeastkeeperRareSeenEvent
---@field module string "BeastMap"
---@field npc number
---@field name string in the client's language once it knows the beast, else English
---@field guid string the creature's GUID
---@field ranks number[] the spell IDs of the ranks it would teach

---BEASTKEEPER_HUNT_STARTED: the hunter picked a beast to tame for a rank (Beast Map's hunt).
---@class BeastkeeperHuntStartedEvent
---@field module string "BeastMap"
---@field npc number
---@field spellID number the rank hunted for
---@field name string in the client's language once it knows the beast, else English

---BEASTKEEPER_HUNT_ENDED: that hunt is over.
---@class BeastkeeperHuntEndedEvent: BeastkeeperHuntStartedEvent
---@field reason "learned"|"stopped" the hunter knows the rank now, or stopped the hunt

---BEASTKEEPER_AMMO: the hunter's ammo count crossed a line: low, critically low, or back to enough.
---@class BeastkeeperAmmoEvent
---@field module string "Ammo"
---@field count number
---@field state "ok"|"low"|"critical"
---@field kind number what the hunter's ranged weapon shoots: Addon.ammoKinds.arrow (2) or .bullet (3)

---BEASTKEEPER_PET_HAPPINESS (core, through Beastkeeper:Listen): the pet out's happiness changed.
---@class BeastkeeperPetHappinessEvent
---@field happiness number Addon.happiness.unhappy (1), .content (2) or .happy (3)
---@field before number? nil for a pet just out

---BEASTKEEPER_PET_DIED (core, through Beastkeeper:Listen): the pet out died.
---@class BeastkeeperPetDiedEvent
---@field pet string?

---BEASTKEEPER_PET_TAMED (core, through Beastkeeper:Listen): the pet that came out after a Tame Beast cast.
---@class BeastkeeperPetTamedEvent
---@field pet string?
---@field npc number? the NPC ID it was tamed as
---@field petNumber number? the number the pet keeps through renames and the stable; nil until the next relog, while its GUID is still the beast's

---@class BeastkeeperKnownRank
---@field name string the ability's name in the client's language
---@field rank number

---A toast, as Beastkeeper:ShowToast takes it and BEASTKEEPER_TOAST hands it over.
---@class BeastkeeperToastInfo
---@field key string one toast per key; "<module>:<what>", so the module can drop its own
---@field type string? "<module>:<kind>", one of the module's toastTypes: picks the skin
---@field source string? who it comes from, such as the module's title (the splash shows it)
---@field title string
---@field text string?
---@field hint string? shown in grey below the text
---@field icon (number|string)? FileDataID or texture path; a question mark without
---@field accent number[]? { r, g, b } for the side bar, the title and the timer; amber without
---@field sound BeastkeeperSound?
---@field portrait string? a unit ("pet") whose portrait shows as a badge on the icon while it exists
---@field screenshot boolean? take a screenshot once the toast has faded in

---A toast sound: a sound file, or a sound kit.
---@class BeastkeeperSound
---@field file number? FileDataID for PlaySoundFile
---@field kit number? SoundKit ID for PlaySound
