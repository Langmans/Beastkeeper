---@meta
-- Editor-only types for Beastkeeper's own tables: the addon object and the module contract. Not
-- listed in the .toc, so the game never loads this file. The Ace3 types (AceModule,
-- AceDBObject-3.0, AceConfig.OptionsTable, ...) come with WoW Lua LS.

---One slash command of a module: `/beastkeeper <module.command> <name> <args>`.
---@class BeastkeeperCommand
---@field desc string one line for /beastkeeper help
---@field func fun(module: BeastkeeperModule, args: string) gets the rest of the line, "" when there is none

---What a module may declare, besides AceAddon's OnInitialize/OnEnable/OnDisable. OnDisable must
---undo everything OnEnable did: it also runs on every profile change (see Core\Addon.lua).
---@class BeastkeeperModule: AceModule, AceEvent-3.0
---@field title string? shown on its switch and its options page; the module name otherwise
---@field description string? the tooltip of its switch
---@field enabledByDefault boolean? false keeps it off until switched on; on otherwise
---@field requires string[]? the parts of the game it needs (Addon.features' keys); off without one
---@field defaults AceDB.Schema? AceDB defaults; the module then has db, its own namespace
---@field db AceDBObject-3.0? set by the core before the module's OnInitialize, when it has defaults
---@field command string? the word after /beastkeeper that reaches its commands
---@field commands table<string, BeastkeeperCommand>? by the word after `command`, lowercase
---@field toastTypes table<string, string>? the kinds of toast it shows, by kind with a localized name; each can have a look of its own
---@field toastSkins table<string, string>? the look a kind starts on (a skin id), until the player picks another
---@field GetOptions (fun(self: BeastkeeperModule): table)? an AceConfig group (args, and name if not title); the core adds type and disabled
---@field Print fun(self: BeastkeeperModule, ...: any) a line in chat, sent on as BEASTKEEPER_PRINT with the module's name

---A module whose settings Beastkeeper:Setting reads and writes.
---@class BeastkeeperSettingsModule: BeastkeeperModule
---@field Settings fun(self: BeastkeeperSettingsModule): table

---A module that offers macros (Beastkeeper:OfferMacros, Beastkeeper:CreateMacros).
---@class BeastkeeperMacroModule: BeastkeeperModule
---@field Macros fun(self: BeastkeeperMacroModule): BeastkeeperMacro[]

---A macro a module makes for the player.
---@class BeastkeeperMacro
---@field name string at most 16 characters
---@field icon number|string FileDataID or texture path
---@field body string the macro text
---@field desc string? what it does, shown in the tooltip of an action button that holds it

-- BeastkeeperToastInfo, BeastkeeperSound and the message tables (BeastkeeperToastEvent and the rest) are public:
-- they are in docs\BeastkeeperMessages.lua, which ships with the addon.

---A skin frame with a portrait badge (Beastkeeper:AddToastPortrait).
---A toast skin's frame (Beastkeeper:NewToastFrame).
---@class BeastkeeperToastFrame: Frame
---@field dragging boolean? the mouse drags it: nothing places it meanwhile
---@field placed boolean? the card has slid in and is left where it is

---@class BeastkeeperPortraitFrame: BeastkeeperToastFrame
---@field Portrait Texture
---@field PortraitRing Texture

---The toast's saved settings, profile.toast.
---@class BeastkeeperToastSettings
---@field duration number seconds it stays before it fades
---@field scale number
---@field pos [string, string, number, number]? point, relativePoint, x, y, once dragged
---@field skin string the skin id for every toast
---@field skins table<string, string> a skin id per kind of toast ("<module>:<kind>"), where chosen
---@field sink table LibSink's output choice, kept by LibSink itself

---What draws a toast (Core\Toast\). Beastkeeper brings "card" and "splash"; another addon adds its
---own with Beastkeeper:RegisterToastSkin(id, skin), to draw in its own style or to hand the toast to
---something else. The engine keeps the queue and the clock and calls, for one toast: Show once,
---Update every frame until the fade is done, then Hide. Beastkeeper:NewToastFrame gives a frame that
---drags and closes like the others, Beastkeeper:PlaceToast puts it where the player dragged it.
---@class BeastkeeperToastSkin
---@field name string shown in the look choice; localized
---@field Show fun(self: BeastkeeperToastSkin, info: BeastkeeperToastInfo, settings: BeastkeeperToastSettings) fill it in and show it; Update follows at once
---@field Update (fun(self: BeastkeeperToastSkin, intro: number, fade: number, left: number))? each 0 to 1: how far the intro is, how far the fade is (1 = gone), how much of its stay is left; required unless instant
---@field Hide (fun(self: BeastkeeperToastSkin))? required unless instant
---@field IsMouseOver (fun(self: BeastkeeperToastSkin): boolean)? while true, its stay does not count down; required unless instant
---@field Frame (fun(self: BeastkeeperToastSkin): Frame?)? its frame, when it has one
---@field instant boolean? it hands the toast on in Show and is done: the next toast follows at once
---@field GetOptions (fun(self: BeastkeeperToastSkin): table)? an AceConfig group of its own on Addon's page

---A skin from Beastkeeper:NewToastSkin: it draws in self.frame, and Hide, IsMouseOver and Frame are
---done; it adds Show and Update.
---@class BeastkeeperFrameSkin: BeastkeeperToastSkin
---@field frame Frame? made by its Show, with Addon:NewToastFrame

---The card skin's frame, with its parts as fields like a template's parentKeys.
---@class BeastkeeperCardFrame: BeastkeeperPortraitFrame
---@field Accent Texture the coloured side bar
---@field Icon Texture
---@field Title FontString
---@field Text FontString
---@field Hint FontString
---@field Timer Texture the bar along the bottom that runs down

---How a card or splash skin looks (Beastkeeper:NewCardSkin, Beastkeeper:NewSplashSkin).
---@class BeastkeeperSkinStyle
---@field frameName string the frame's global name
---@field accent fun(): number[] { r, g, b } for a toast that brings no accent
---@field panel number[]? { r, g, b, a } of the panel; the splash fades its own black one without
---@field edge number[]? { r, g, b, a } of a 1-pixel edge (card only)
---@field Border fun(frame: Frame)? draws an edge itself
---@field Font fun(text: FontString, size: number)? sets a font; the game's fonts without

---@class BeastkeeperCardSkin: BeastkeeperFrameSkin
---@field style BeastkeeperSkinStyle
---@field frame BeastkeeperCardFrame? made on its first toast

---The splash skin's frame.
---@class BeastkeeperSplashFrame: BeastkeeperPortraitFrame
---@field Source FontString the module's name at the top
---@field Divider Texture the line under it
---@field Diamond Texture the accent square turned 45 degrees
---@field Inner Texture the dark square inside it
---@field Icon Texture
---@field Title FontString
---@field Text FontString
---@field Hint FontString
---@field Timer Texture

---@class BeastkeeperSplashSkin: BeastkeeperFrameSkin
---@field style BeastkeeperSkinStyle
---@field frame BeastkeeperSplashFrame?

---AutocastCheck's saved settings, its namespace's profile.
---@class BeastkeeperAutocastSettings
---@field growl boolean watch Growl
---@field cower boolean watch Cower
---@field remind boolean toast what is still wrong when combat starts
---@field sound "family"|"warning"|"off"

---@class BeastkeeperAutocastCheck: BeastkeeperMacroModule, BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field active table<string, true> the problems the last check found, by problem key
---@field checkPending boolean? a check is on its way (CheckAfter)
---@field choice ("growl"|"cower")? what the player chose (BeastkeeperKite, BeastkeeperGrowl)
---@field choiceInDungeon boolean? whether the player was in a dungeon group then
---@field lastWanted ("growl"|"cower")? what fitted at the last check (BEASTKEEPER_AUTOCAST_WANTED)
---@field lastWhy ("solo"|"dungeon"|"chosen")? what decided it then
---@field TellWanted fun(self: BeastkeeperAutocastCheck)
---@field SPELLS table<"growl"|"cower", number>
---@field Spell fun(id: number): string, (number|string)?
---@field Settings fun(self: BeastkeeperAutocastCheck): BeastkeeperAutocastSettings used by Options.lua too
---@field Check fun(self: BeastkeeperAutocastCheck, remindAll: boolean?) used by Options.lua too
---@field TestToast fun(self: BeastkeeperAutocastCheck) used by Options.lua too
---@field Wanted fun(self: BeastkeeperAutocastCheck): "growl"|"cower", "solo"|"dungeon"|"chosen"
---@field Choose fun(self: BeastkeeperAutocastCheck, ability: "growl"|"cower")
---@field AutocastLines fun(on: "growl"|"cower"): string
---@field ApplyButton fun(self: BeastkeeperAutocastCheck)

---An ability that can autocast, as AutocastCheck reads it from the pet.
---@class BeastkeeperAutocastState
---@field on boolean
---@field icon (number|string)? from the pet bar; nil for one only in the spellbook

---Feeding's saved settings, its namespace's profile.
---@class BeastkeeperFeedingSettings
---@field content boolean toast when the pet becomes content
---@field unhappy boolean toast when the pet becomes unhappy
---@field noFood boolean toast when the last food the pet eats leaves the bags
---@field position [string, string, number, number]? the button's point, UIParent's point, x, y; nil beside the pet frame

---A food in the bags the pet eats, as Feeding orders it.
---@class BeastkeeperFood
---@field bag number
---@field slot number
---@field itemID number
---@field count number
---@field level number its item level
---@field bite number happiness a bite gives the pet out: 35, 17 or 8
---@field wellFed boolean it also makes the hunter Well Fed: fed last

---What a button skin is handed besides the button.
---@class BeastkeeperButtonParts
---@field icon Texture the button's icon
---@field group string the module the button belongs to, such as "Feeding" (Masque's group)

---The look of one of Beastkeeper's buttons (Core\Buttons.lua, docs\09-button-skins.md).
---@class BeastkeeperButtonSkin
---@field name string shown in the choice on Addon's page
---@field priority number? "auto" takes the highest; Addon's own is 0
---@field Style fun(button: Button, parts: BeastkeeperButtonParts): (fun(r: number, g: number, b: number))? styles it once; gives how to colour its border, or nil when it has none to colour

---The look of what holds Beastkeeper's buttons, and of the text and icons in its rows.
---@class BeastkeeperButtonHolderSkin
---@field name string
---@field priority number?
---@field Style fun(frame: Frame) styles the panel once (a frame made with BackdropTemplate)
---@field Font fun(text: FontString, size: number) a row's text
---@field CropIcon (fun(icon: Texture))? a row's icon, as the UI trims its own
---@field CropsIcons (fun(): boolean)? whether the UI's own setting crops icons; Addon's switch follows it, greyed
---@field Accent (fun(): number[])? the colour that marks what is chosen (the tab that shows); the game's gold without one
---@field Close (fun(button: Button))? a close button (UIPanelCloseButton), in the UI's own look

---The button skin choices in the profile.
---@class BeastkeeperButtonSettings
---@field skin string a button skin id, or "auto"
---@field holder string a holder skin id, or "auto"
---@field crop boolean icons lose their border, unless the look's UI decides (CropsIcons)

---The Data Broker module: Beastkeeper's LibDataBroker-1.1 data source.
---@class BeastkeeperBroker: BeastkeeperModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field object table? the data object ("Addon"), made for a hunter on the first enable
---@field Update fun(self: BeastkeeperBroker)
---@field ApplyMinimapButton fun(self: BeastkeeperBroker)
---@field GetOptions fun(self: BeastkeeperBroker): table

---Where and when a pet came to the journal.
---@class BeastkeeperJournalFirst
---@field t number server time
---@field zone string?
---@field tamed boolean? seen tamed (a Tame Beast cast before it came out)
---@field npc number? the NPC ID it was tamed as

---One pet's journal (PetJournal), per character.
---@class BeastkeeperJournalEntry
---@field first BeastkeeperJournalFirst
---@field name string?
---@field family string? its family, in the client's language
---@field level number?
---@field loyalty number?
---@field loyaltyName string?
---@field out number seconds out, before the current stretch
---@field deaths number
---@field rises table<number, number> per loyalty level reached while seen, the seconds out then
---@field abilities string[] "Claw (Rank 2)", sorted, as of the last time out
---@field ranks table<string, string>? each ability's rank text by name ("" without ranks)
---@field displayID number? its model, as the stable's lists gave it

---PetJournal's saved settings, its namespace's profile.
---@class BeastkeeperPetJournalSettings
---@field tooltip boolean the journal in the pet's tooltip

---@class BeastkeeperPetJournal: BeastkeeperModule, BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field current string? the pet out's key
---@field outSince number? GetTime() when it came out
---@field picked string? the pet chosen on the page
---@field Pets fun(self: BeastkeeperPetJournal): table<string, BeastkeeperJournalEntry>
---@field Entry fun(self: BeastkeeperPetJournal, key: string, npc: number?): BeastkeeperJournalEntry
---@field ReadStableList fun(self: BeastkeeperPetJournal, list: fun(): table[])
---@field LevelLine fun(entry: BeastkeeperJournalEntry): string
---@field AbilitiesLine fun(entry: BeastkeeperJournalEntry, highlight: boolean?): string?
---@field TeachCount fun(entry: BeastkeeperJournalEntry): number
---@field PetOrder fun(): string[] the journal's pets, the pet out first, then by name
---@field ShowModel fun(model: PlayerModel, key: string, entry: BeastkeeperJournalEntry)
---@field OnDied fun(self: BeastkeeperPetJournal)
---@field OnTamed fun(self: BeastkeeperPetJournal, message: string, event: BeastkeeperPetTamedEvent)
---@field OnGrowth fun(self: BeastkeeperPetJournal)
---@field ReadStable fun(self: BeastkeeperPetJournal)
---@field Out fun(self: BeastkeeperPetJournal, key: string): number
---@field Record fun(self: BeastkeeperPetJournal)
---@field Snapshot fun(self: BeastkeeperPetJournal)
---@field Close fun(self: BeastkeeperPetJournal)
---@field Open fun(self: BeastkeeperPetJournal, key: string)
---@field Settings fun(self: BeastkeeperPetJournal): BeastkeeperPetJournalSettings
---@field JournalLines fun(self: BeastkeeperPetJournal, key: string, brief: boolean?): string[]
---@field JournalText fun(self: BeastkeeperPetJournal, key: string): string
---@field Chosen fun(self: BeastkeeperPetJournal): string?
---@field GetOptions fun(self: BeastkeeperPetJournal): table

---A row of Feeding's food list: a secure button that feeds one food.
---@class BeastkeeperFoodRow: Button
---@field icon Texture
---@field label FontString

---@class BeastkeeperFeeding: BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field happiness number? the pet's happiness at the last check; nil for a new pet
---@field canFeed boolean? whether the hunter knew Feed Pet at the last look
---@field SPELLS_CHANGED fun(self: BeastkeeperFeeding)
---@field button Button the feed button (BeastkeeperFeedButton)
---@field FEED_PET number
---@field FeedMacro fun(food: BeastkeeperFood): string
---@field FoodColor fun(food: BeastkeeperFood): number, number, number
---@field ToggleFoodList fun(self: BeastkeeperFeeding)
---@field CloseFoodList fun(self: BeastkeeperFeeding)
---@field Settings fun(self: BeastkeeperFeeding): BeastkeeperFeedingSettings
---@field FeedPetName fun(): string
---@field FoodName fun(food: BeastkeeperFood): string
---@field Happiness fun(): number?
---@field Scan fun(self: BeastkeeperFeeding): BeastkeeperFood[]
---@field Foods fun(self: BeastkeeperFeeding): BeastkeeperFood[]
---@field Toast fun(self: BeastkeeperFeeding, kind: "content"|"unhappy"|"nofood"): BeastkeeperToastInfo
---@field CheckHappiness fun(self: BeastkeeperFeeding)
---@field Update fun(self: BeastkeeperFeeding)
---@field PlaceButton fun(self: BeastkeeperFeeding)
---@field ApplyButton fun(self: BeastkeeperFeeding)
---@field GetOptions fun(self: BeastkeeperFeeding): table

---CareButton's saved settings, its namespace's profile.
---@class BeastkeeperCareButtonSettings
---@field died boolean toast when the pet dies
---@field nopet boolean toast when combat starts without a pet
---@field passive boolean toast when combat starts with the pet on Passive
---@field low number the health percentage for the low toast; 0 is never
---@field marker boolean the low health marker beside the pet frame
---@field visible boolean the button shown on screen
---@field position [string, string, number, number]? its point, UIParent's point, x, y; nil below the pet frame
---@field sound "family"|"warning"|"off"

---@class BeastkeeperCareButton: BeastkeeperMacroModule, BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field ApplyMacroTexts fun(self: BeastkeeperCareButton) the button's macro texts again, for the spells known now
---@field IsCareLine fun(self: BeastkeeperCareButton, line: string): boolean a /use line of the care spells alone
---@field lowShown boolean the low toast was given and health has not been above the line since
---@field deadAfterCombat boolean a failed cast in combat showed the pet is dead
---@field reviveCasts table<string, true> Revive Pet casts that started, by cast GUID
---@field MEND_PET number
---@field REVIVE_PET number
---@field CALL_PET number
---@field PET_STATES string
---@field Settings fun(self: BeastkeeperCareButton): BeastkeeperCareButtonSettings
---@field SpellName fun(id: number): string
---@field Toast fun(self: BeastkeeperCareButton, kind: "dead"|"nopet"|"low"|"passive", reason: string?, percent: number?): BeastkeeperToastInfo
---@field CheckHealth fun(self: BeastkeeperCareButton)
---@field UpdateMarker fun(self: BeastkeeperCareButton)
---@field button Button the secure button (BeastkeeperCareButton)
---@field NextCast fun(self: BeastkeeperCareButton): number
---@field UpdateLook fun(self: BeastkeeperCareButton)
---@field PlaceButton fun(self: BeastkeeperCareButton)
---@field ShowOnScreen fun(self: BeastkeeperCareButton)
---@field OnPetState fun(self: BeastkeeperCareButton, state: string)
---@field MacroText fun(self: BeastkeeperCareButton, petDead: boolean): string
---@field PetDead fun(self: BeastkeeperCareButton): boolean
---@field SetPetDead fun(self: BeastkeeperCareButton, dead: boolean): boolean
---@field ApplyButton fun(self: BeastkeeperCareButton)
---@field UpdateMacro fun(self: BeastkeeperCareButton)

---A spell in the active pet's spellbook (Beastkeeper.PetSpells).
---@class BeastkeeperPetSpell
---@field id number
---@field rank string? "Rank 2"; nil for a spell without ranks
---@field icon (number|string)?

---AbilityLearned's saved settings, its namespace's profile.
---@class BeastkeeperAbilityLearnedSettings
---@field sound "family"|"levelup"|"off"
---@field screenshot boolean
---@field hints boolean say in chat what a summoned pet can teach
---@field points boolean toast when the pet gains training points
---@field pointsSound "family"|"levelup"|"off" that toast's sound
---@field loyalty boolean toast when the pet's loyalty level drops
---@field loyaltySound "family"|"levelup"|"off" that toast's sound

---AbilityLearned's per-character data, its namespace's char.
---@class BeastkeeperAbilityLearnedChar
---@field history BeastkeeperLearnEntry[] oldest first, the last 200
---@field known table<string, number> the highest rank known per ability name
---@field ranks table<string, table<number, true>> every rank known per ability name
---@field trainingRead boolean Beast Training has been read once

---How a pet stood when the core last saw it (BeastkeeperDB char.growth, by pet name).
---@class BeastkeeperGrowthSeen
---@field total number its training points total
---@field level number
---@field loyalty number? its loyalty level; nil on a client without GetPetLoyalty

---A learn as AbilityLearned shows it.
---@class BeastkeeperLearn
---@field name string
---@field rank string?
---@field icon (number|string)?
---@field teacher string? the name of the pet out, when it has the ability
---@field simulated boolean? from the page's simulation: shown, not kept

---A learn as the history keeps it.
---@class BeastkeeperLearnEntry
---@field name string
---@field rank string?
---@field pet string?
---@field npc number? the NPC ID the pet was tamed as (Addon.PetNPC)
---@field familyID number?
---@field zone string?
---@field t number GetServerTime()

---@class BeastkeeperAbilityLearned: BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field ready boolean the login wait is over
---@field atTrainer boolean a trainer window was opened and not closed
---@field Settings fun(self: BeastkeeperAbilityLearned): BeastkeeperAbilityLearnedSettings
---@field Toast fun(self: BeastkeeperAbilityLearned, learn: BeastkeeperLearn): BeastkeeperToastInfo
---@field ShowLearn fun(self: BeastkeeperAbilityLearned, learn: BeastkeeperLearn)
---@field TrainerOpen fun(self: BeastkeeperAbilityLearned): boolean
---@field IsWildAbility fun(name: string): boolean
---@field OnChat fun(self: BeastkeeperAbilityLearned, line: GameValue): boolean
---@field SpellLearned fun(self: BeastkeeperAbilityLearned, spellID: number)
---@field Example fun(): string, string, number|string|nil, BeastkeeperPetSpell?
---@field Simulate fun(self: BeastkeeperAbilityLearned)
---@field MarkKnown fun(self: BeastkeeperAbilityLearned, name: string, rank: number): boolean
---@field HighestRank fun(self: BeastkeeperAbilityLearned, name: string): number?
---@field CanTeach fun(self: BeastkeeperAbilityLearned, name: string, rank: string?): boolean
---@field HasRank fun(self: BeastkeeperAbilityLearned, name: string, rank: number): boolean
---@field RecordLearn fun(self: BeastkeeperAbilityLearned, entry: BeastkeeperLearnEntry)
---@field HistoryText fun(self: BeastkeeperAbilityLearned): string
---@field ReportMissingTeachers fun(self: BeastkeeperAbilityLearned)
---@field ReadBeastTraining fun(self: BeastkeeperAbilityLearned)
---@field CheckHints fun(self: BeastkeeperAbilityLearned)
---@field OnGrowth fun(self: BeastkeeperAbilityLearned, message: string, event: BeastkeeperPetGrowthEvent)
---@field Sound fun(self: BeastkeeperAbilityLearned, key: "sound"|"pointsSound"|"loyaltySound", petSound: "AGGRO"|"WOUND"|nil): BeastkeeperSound?
---@field ReportTeachable fun(self: BeastkeeperAbilityLearned)

---FeedEmotes' saved settings, its namespace's profile.
---@class BeastkeeperFeedEmotesSettings
---@field petName boolean always the pet's name, never he/she
---@field customChance number 0: every fitting line counts the same; else the share of emotes that wants an own line
---@field customFallback boolean a built-in line when an own one is wanted but none fits

---FeedEmotes' per-character data, its namespace's char.
---@class BeastkeeperFeedEmotesChar
---@field sharedLines boolean use the account-wide own lines (global.customLines)
---@field customLines string[] this character's own lines
---@field petSex table<number, number> pet number -> 2 male or 3 female

---What a pronoun placeholder becomes: by the pet's sex, and with the sex unknown a format with %s
---for the name or a function of it (the pet's name when there is neither).
---@class BeastkeeperPronoun
---@field male string
---@field female string
---@field unknown (string|fun(name: string): string)?

---The built-in lines of one language (FeedEmotes\Lines\<locale>.lua).
---@class BeastkeeperEmoteLines
---@field feed string|fun(pet: string, food: string): string the sentence in front: a format of the pet and the food, or a function
---@field feedNoFood string the same without a known food
---@field article (fun(name: string): string)? the article for {a}
---@field pronouns table<string, BeastkeeperPronoun>?
---@field emotes BeastkeeperEmoteLists

---@class BeastkeeperEmoteLists
---@field any string[]
---@field male string[]?
---@field female string[]?
---@field openings string[]? sentences in front, in place of feed now and then
---@field whole string[]? emotes on their own, no sentence in front
---@field wholeFamily table<number, string[]>? the same per family ID
---@field food table<string, string[]> per food group (FoodGroups)
---@field foodType table<string, string[]>? per food type (FoodTypes)
---@field family table<number, string[]> per family ID

---The conditions of an own line, by tag. An alias, so a function type can return it next to
---another value (a comma inside table<...> would end the first return).
---@alias BeastkeeperTagSet table<string, true>

---A condition an own line can start with.
---@class BeastkeeperFeedCondition
---@field tag string what is typed between the brackets
---@field group "sex"|"foodType"|"family"
---@field value number|string what the feeding must hold for that group

---What the lines are picked by for one feeding.
---@class BeastkeeperFeedSituation
---@field sex number?
---@field foodType string?
---@field family number?

---@class BeastkeeperFeedEmotes: BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field watching boolean? on a hunter, where there is a pet to feed
---@field FEED_PET number
---@field CUSTOM_LINE_MAX number
---@field Lines table<string, BeastkeeperEmoteLines>
---@field FoodGroups table<number, string>
---@field FoodTypes table<number, string>
---@field Family table<string, number>
---@field ExoticFamily table<number, true>
---@field Conditions BeastkeeperFeedCondition[]
---@field ConditionByTag table<string, BeastkeeperFeedCondition>
---@field Tracker BeastkeeperFoodTracker
---@field Settings fun(self: BeastkeeperFeedEmotes): BeastkeeperFeedEmotesSettings
---@field Char fun(self: BeastkeeperFeedEmotes): BeastkeeperFeedEmotesChar
---@field LinesInUse fun(self: BeastkeeperFeedEmotes): BeastkeeperEmoteLines
---@field CustomLines fun(self: BeastkeeperFeedEmotes): string[]
---@field PetSex fun(self: BeastkeeperFeedEmotes): number?
---@field ChoosePetSex fun(self: BeastkeeperFeedEmotes, sex: number?): boolean
---@field PrunePetSex fun(self: BeastkeeperFeedEmotes)
---@field Feed fun(self: BeastkeeperFeedEmotes, itemID: number?)
---@field ParseCustomLine fun(line: string): BeastkeeperTagSet?, string
---@field FormatCustomLine fun(tags: table<string, true>, text: string): string
---@field ConditionsHold fun(tags: table<string, true>, situation: BeastkeeperFeedSituation): boolean
---@field AddCustomLine fun(self: BeastkeeperFeedEmotes, text: string?, extraTags: table<string, true>?): boolean, string
---@field ReplaceCustomLine fun(self: BeastkeeperFeedEmotes, index: number, text: string?): boolean, string
---@field RemoveCustomLine fun(self: BeastkeeperFeedEmotes, index: number): string?
---@field PlaceholderList fun(self: BeastkeeperFeedEmotes): string
---@field LinePools fun(self: BeastkeeperFeedEmotes, itemID: number?, foodName: string?): string[], string[]
---@field EmotePool fun(self: BeastkeeperFeedEmotes, itemID: number?, foodName: string?): string[]
---@field PickLine fun(self: BeastkeeperFeedEmotes, itemID: number?, foodName: string?): string?
---@field FillPlaceholders fun(self: BeastkeeperFeedEmotes, line: string, pet: string, food: string?, article: string?): string
---@field BuildEmote fun(self: BeastkeeperFeedEmotes, itemID: number?): string?

---The sound tables, Beastkeeper.sounds.<KIND>_PER_FAMILY (Core\Sounds.lua).
---@class BeastkeeperSounds
---@field AGGRO_PER_FAMILY table<number, number>
---@field DEATH_PER_FAMILY table<number, number>
---@field WOUND_PER_FAMILY table<number, number>

---DevScreenshots: screenshots for development, only in a copy from the repository.
---@class BeastkeeperDevScreenshots: BeastkeeperModule
---@field db AceDBObject-3.0 global.shots: what has a screenshot, by kind
---@field BEASTKEEPER_TOAST fun(self: BeastkeeperDevScreenshots, message: string, event: BeastkeeperToastEvent)
---@field BEASTKEEPER_PRINT fun(self: BeastkeeperDevScreenshots, message: string, event: BeastkeeperPrintEvent)

---BeastMap: a HandyNotes plugin with a pin for every beast that can teach the hunter a rank.
---@class BeastkeeperBeastMap: BeastkeeperSettingsModule
---@field db AceDBObject-3.0
---@field level number? the level PLAYER_LEVEL_UP gave, until UnitLevel catches up
---@field canTame boolean? whether the hunter knows Tame Beast, as SPELLS_CHANGED last found
---@field SPELLS_CHANGED fun(self: BeastkeeperBeastMap)
---@field Settings fun(self: BeastkeeperBeastMap): BeastkeeperBeastMapSettings
---@field PlayerLevel fun(self: BeastkeeperBeastMap): number
---@field Refresh fun(self: BeastkeeperBeastMap)
---@field TeachesOf fun(npc: number): number[]?
---@field RankText fun(spellID: number): string?
---@field Lacking fun(spellID: number): "above"|"gap"|nil
---@field LevelText fun(beast: BeastkeeperBeast): string
---@field BeastName fun(npc: number): string
---@field SeeCreature fun(self: BeastkeeperBeastMap, guid: GameValue)
---@field tameTarget string? the beast the tame key goes for
---@field SetTameTarget fun(self: BeastkeeperBeastMap, name: string)
---@field OnRareSeen fun(self: BeastkeeperBeastMap, message: string, event: BeastkeeperRareSeenEvent)
---@field Place fun(npc: number): string the beast and its zone, "Rare Cat in Tirisfal Glades"
---@field Nearest fun(teachers: number[]): number[] the window's order, a new list
---@field TravelTimeTo fun(npc: number): number? seconds, when a route addon gives travel times
---@field GoToBeast fun(self: BeastkeeperBeastMap, npc: number, pinMap: number?, pinX: number?, pinY: number?): boolean
---@field PinSpell fun(npc: number): number? the rank a beast's pin shows
---@field Hunt fun(self: BeastkeeperBeastMap): BeastkeeperHunt? the hunt on (Hunt.lua)
---@field IsHunting fun(self: BeastkeeperBeastMap, npc: number?, spellID: number?): boolean
---@field StartHunt fun(self: BeastkeeperBeastMap, npc: number, spellID: number, map: number?, x: number?, y: number?)
---@field StopHunt fun(self: BeastkeeperBeastMap, reason: "learned"|"stopped"?)
---@field OnRanksKnown fun(self: BeastkeeperBeastMap)
---@field ShowHunt fun(self: BeastkeeperBeastMap) the hunted beast's areas (Areas.lua)
---@field DrawWorldAreas fun(self: BeastkeeperBeastMap)
---@field DrawMinimapAreas fun(self: BeastkeeperBeastMap)
---@field worldAreas Texture[] the discs on the world map
---@field minimapAreas Texture[] the discs on the minimap
---@field ApplyTameButton fun(self: BeastkeeperBeastMap)
---@field WatchRares fun(self: BeastkeeperBeastMap)
---@field CreateMapButton fun(self: BeastkeeperBeastMap)
---@field UpdateMapButton fun(self: BeastkeeperBeastMap)
---@field ToastReach fun(self: BeastkeeperBeastMap, level: number)
---@field GetOptions fun(self: BeastkeeperBeastMap): table

---The beast the hunter hunts, to tame it for one rank (Beast Map's db.char.hunt).
---@class BeastkeeperHunt
---@field npc number
---@field spellID number the rank

---@class BeastkeeperBeastMapSettings
---@field tooltip boolean a beast's tooltip says what it teaches
---@field rareToast boolean a toast when a rare beast worth taming comes in sight
---@field trainers boolean pins for pet trainers
---@field stables boolean pins for stable masters
---@field pins boolean the pins shown at all (the map button switches this)
---@field mapButton boolean the button on the world map
---@field usefulOnly boolean only beasts that teach a rank the hunter lacks
---@field gaps boolean a missing rank below the highest counts as lacking
---@field aboveLevel boolean beasts above the hunter's level too
---@field untilTame boolean with usefulOnly: no beast pins before the hunter knows Tame Beast
---@field levelToast boolean a toast when a level-up brings a teaching beast in reach
---@field levelChat boolean that toast's ranks and beasts in chat too

---A map's pins as npc, coord pairs, with the position of each coord's npc.
---@class BeastkeeperBeastMapPins
---@field [integer] number
---@field at table<number, integer>

---A spellbook entry, as C_SpellBook gives it (Beastkeeper.C.SpellBook.GetSpellBookItemInfo).
---@class BeastkeeperBookItem
---@field name GameValue
---@field subName GameValue the rank text, "" without one
---@field spellID GameValue none for a command

---An item's or a link's tooltip data, as C_TooltipInfo gives it (Beastkeeper.C.TooltipInfo).
---@class BeastkeeperTooltipData
---@field lines {leftText: GameValue}[]

---@class BeastkeeperCompatPetInfo
---@field GetPetHappiness fun(): GameValue
---@field GetPetTrainingPoints fun(): GameValue, GameValue total and used
---@field GetPetLoyalty fun(): GameValue
---@field GetPetFoodTypes fun(): string[]
---@field CanPetEatItem fun(itemID: number): boolean

---@class BeastkeeperCompatSpellBook
---@field HasPetSpells fun(): GameValue the entry count
---@field IsSpellKnown fun(spellID: number): boolean? nil on a client that cannot tell
---@field GetSpellBookItemInfo fun(index: number, bank: number): BeastkeeperBookItem?
---@field GetSpellBookItemAutoCast fun(index: number, bank: number): GameValue, GameValue allowed and enabled

---@class BeastkeeperCompatTooltipInfo
---@field GetItemByID fun(itemID: number): BeastkeeperTooltipData
---@field GetHyperlink fun(link: string): BeastkeeperTooltipData?

---A pet in the stable's lists, as C_StableInfo gives it; Classic Era gives no petNumber,
---creatureID or displayID, and its loyalty as loyaltyText ("Loyalty Level 6 (Best Friend)").
---@class BeastkeeperStablePet
---@field slotID number?
---@field petNumber GameValue
---@field name string?
---@field level number?
---@field familyName string?
---@field icon (number|string)?
---@field creatureID number?
---@field displayID number?
---@field loyaltyLevel number?
---@field loyaltyName string?
---@field loyaltyText string?

---@class BeastkeeperCompatStableInfo
---@field GetActivePetList fun(): BeastkeeperStablePet[]
---@field GetStabledPetList fun(): BeastkeeperStablePet[]

---Beastkeeper.C (Core\Compat.lua): the modern API on every client, the classic way where it is missing.
---@class BeastkeeperCompat
---@field PetInfo BeastkeeperCompatPetInfo
---@field SpellBook BeastkeeperCompatSpellBook
---@field TooltipInfo BeastkeeperCompatTooltipInfo
---@field StableInfo BeastkeeperCompatStableInfo
---@field Has fun(namespace: "PetInfo", name: string): boolean

---Generated game data (Data\*.lua).
---@class BeastkeeperData
---@field petAbilityRanks table<number, BeastkeeperPetAbilityRank> by the rank's spell ID
---@field beasts table<number, BeastkeeperBeast> by NPC ID
---@field trainers table<number, BeastkeeperTrainer>? pet trainers and stable masters by NPC ID (Data\Trainers.lua)
---@field ammo table<number, BeastkeeperAmmoItem> the arrows and bullets vendors sell, by item ID (Data\Ammo.lua)
---@field ammoVendors table<number, BeastkeeperAmmoVendor> the vendors that sell them, by NPC ID
---A kind of ammo: its Projectile item subclass, a Beastkeeper.ammoKinds value (arrow 2, bullet 3).
---@alias BeastkeeperAmmoKind number

---Ammo a vendor sells.
---@class BeastkeeperAmmoItem
---@field name string English, from the data
---@field kind BeastkeeperAmmoKind
---@field level number the level it needs

---A vendor that sells ammo.
---@class BeastkeeperAmmoVendor
---@field name string English, from the data
---@field sells number[] the ammo it sells, item IDs
---@field side ("Alliance"|"Horde")? the one faction it serves; both without
---@field pins table<number, number[]> per uiMapID its spots, flattened x1, y1, x2, y2 in percent

---Ammo's saved settings, its namespace's profile.
---@class BeastkeeperAmmoSettings
---@field low number the count turns orange, with a toast, below this
---@field critical number red, with a toast, below this
---@field toasts boolean
---@field buy boolean buy at a vendor
---@field stacks number stacks to keep without an ammo bag

---@class BeastkeeperAmmo: BeastkeeperModule, BeastkeeperSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field object table? the data object ("Addon Ammo"), made for a hunter on the first enable
---@field state ("ok"|"low"|"critical")? where the count stood at the last update
---@field Settings fun(self: BeastkeeperAmmo): BeastkeeperAmmoSettings
---@field Kind fun(): BeastkeeperAmmoKind?
---@field AmmoName fun(itemID: number): string
---@field State fun(self: BeastkeeperAmmo, count: number): "ok"|"low"|"critical"
---@field NearestVendor fun(self: BeastkeeperAmmo): LibGoTherePoint?, number?
---@field Update fun(self: BeastkeeperAmmo)
---@field MERCHANT_SHOW fun(self: BeastkeeperAmmo)
---@field GetOptions fun(self: BeastkeeperAmmo): table

---A hunter pet trainer or a stable master.
---@class BeastkeeperTrainer
---@field name string in English, from the data
---@field kind "trainer"|"stable"
---@field side ("Alliance"|"Horde")? the one faction it serves; both without
---@field pins table<number, number[]> per uiMapID its spots, flattened x1, y1, x2, y2 in percent

---One rank of a pet ability learned from beasts in the wild.
---@class BeastkeeperPetAbilityRank
---@field ability number the spell ID of the ability's rank 1
---@field rank number
---@field level number the pet level it needs
---@field families number[] the pet families (CreatureFamily IDs) that can learn it
---@field teachers number[] NPC IDs of the tameable beasts that teach it

---A tameable beast that teaches a pet ability rank.
---@class BeastkeeperBeast
---@field name string English, as Wowhead names it
---@field family number CreatureFamily ID
---@field minLevel number
---@field maxLevel number
---@field elite true?
---@field rare true?
---@field display number? its display ID (model), shown without the creature in the client's cache
---@field pins table<number, number[]>? per uiMapID, pin positions as x1, y1, x2, y2, ... (percent)
---@field radii table<number, number[]>? per uiMapID, each pin's area radius (percent)
---@field zones number[]? AreaTable IDs, for a beast Wowhead has no map of (in an instance)

---The Dev Probe (Modules\DevProbe, repository copies only).
---@class BeastkeeperDevProbe: BeastkeeperModule
---@field db AceDBObject-3.0
---@field ReadStable fun(self: BeastkeeperDevProbe)
---@field CompareSpells fun(self: BeastkeeperDevProbe)
---@field OnLearned fun(self: BeastkeeperDevProbe, message: string, event: BeastkeeperAbilityLearnedEvent)
---@field GetOptions fun(self: BeastkeeperDevProbe): table

---The Dev Probe's findings, its global namespace.
---@class BeastkeeperProbeData
---@field stable table<string, table> C_StableInfo's entry per pet number
---@field petSpells table[] { spell, rank, before, level, family, how, t }
---@field foods table<number, string[]> food types per family ID
---@field families table<number, string> the client's family names
---@field lowerRanks table[] { name, rank, highest, t }
---@field guids table[] { event, guid, name, t }
---@field client table at each login: build, project, season, tameable, api, unitPosition, mapPosition, ammo, rangedSpeed, bags
---@field combat table? the first fight's: petHealth, unitPosition, mapPosition
---@field pet table happiness, loyalty, trainingPoints, each { modern, old }
---@field trainer (table|string)[] the trainer's first rows, raw
---@field tames table[] { npc, family, knows, expected, match, t }
---@field beasts table<number, table> per NPC its first sighting: { name, map, x, y, onDataMap, dataMaps, t }

---A tab of Beastkeeper's window (Core\Window.lua), added by Beastkeeper:RegisterWindowTab.
---@class BeastkeeperWindowTab
---@field id string
---@field title string
---@field order number left to right
---@field module string? the module that adds it: the tab shows while that module is on
---@field Create fun(panel: Frame, skin: BeastkeeperButtonHolderSkin) builds the panel, once
---@field Refresh fun(panel: Frame) fills it, each time it shows and on Addon:RefreshWindow

---Beastkeeper's window frame.
---@class BeastkeeperWindow: Frame
---@field skin BeastkeeperButtonHolderSkin
---@field title FontString
---@field current string? the tab showing
---@field tabs table<string, BeastkeeperWindowTabButton>
---@field panels table<string, Frame>
---@field divider Texture the line under the tabs
---@field close Button

---Beastkeeper.petSpecs, a SelfKeyedEnum.
---Beastkeeper.petCategories, a SelfKeyedEnum: a family's category before Wrath.
---@class BeastkeeperPetCategories
---@field offense string
---@field defense string
---@field general string

---A family's category and modifiers to the pet's health, armor and damage, in percent, on the
---classic clients (Beastkeeper.familyMods).
---@class BeastkeeperFamilyMods
---@field category string a Addon.petCategories value
---@field health number
---@field armor number
---@field damage number

---@class BeastkeeperPetSpecs
---@field ferocity string
---@field cunning string
---@field tenacity string

---Beastkeeper.diets, a SelfKeyedEnum.
---@class BeastkeeperDiets
---@field meat string
---@field fish string
---@field cheese string
---@field bread string
---@field fungus string
---@field fruit string
---@field rawFish string

---What Beastkeeper knows of a pet family (Core\Constants\Families.lua).
---@class BeastkeeperFamilyInfo
---@field name string English, when the client gives no name
---@field spec string? a Addon.petSpecs value
---@field diet string[]? Addon.diets values
---@field client string? the only client it is on, as LibTameable names it ("tbc", "forever"); nil for every client

---Beastkeeper's window's settings (profile.window): where it was dragged to.
---@class BeastkeeperWindowSettings
---@field pos { point: string, relativePoint: string, x: number, y: number }?

---@class BeastkeeperWindowTabButton: Button
---@field label FontString
---@field selected Texture the underline of the tab that shows

---The Pets tab's panel (Modules\PetJournal\Window.lua).
---@class BeastkeeperPetsPanel: Frame
---@field skin BeastkeeperButtonHolderSkin
---@field rows BeastkeeperPetRow[]
---@field model BeastkeeperPetModel
---@field name FontString
---@field level FontString
---@field spec FontString
---@field journal FontString
---@field abilities FontString

---@class BeastkeeperPetRow: Button
---@field label FontString
---@field key string? the pet it shows

---The Abilities tab's panel (Modules\BeastMap\Abilities.lua).
---@class BeastkeeperAbilitiesPanel: Frame
---@field rows BeastkeeperAbilityRow[]
---@field ranks BeastkeeperRankRow[]
---@field title FontString
---@field titleIcon Texture the chosen ability's icon
---@field header BeastkeeperRankHeader
---@field chosen number? the ability shown, by its rank 1's spell ID
---@field shownAbility number? the ability the lines below were made for
---@field expanded table<number, true?> the ranks unfolded to their teachers
---@field offset number how many lines the list is scrolled down
---@field lineSpells number[] per line its rank
---@field lineBeasts (number|false)[] per line its teacher, false on a rank's own line

---A rank's button that sends the hunter to the beast.
---@class BeastkeeperGoButton: Button
---@field icon Texture
---@field active Texture lit while its rank is the one hunted

---The ranks' column heads.
---@class BeastkeeperRankHeader: Frame
---@field rank FontString
---@field level FontString
---@field text FontString

---@class BeastkeeperAbilityRow: Button
---@field icon Texture the ability's
---@field label FontString the ability
---@field count FontString how many of its ranks the hunter knows
---@field selected Texture the bar behind the chosen one
---@field ability number?

---@class BeastkeeperRankRow: Button
---@field rank FontString
---@field level FontString
---@field text FontString the nearest teacher, or known
---@field more FontString how many more teach it
---@field stripe Texture every other row's background
---@field toggle Texture plus or minus, on a rank that folds open to its teachers
---@field npc number? on a teacher's line, the beast
---@field go BeastkeeperGoButton
---@field spellID number?
---@field teachers number[]? the beasts that teach it, in the window's order; nil when known
---@field best number? the first of them

---The Stable tab's panel (Modules\PetJournal\Stable.lua).
---@class BeastkeeperStablePanel: Frame
---@field cards BeastkeeperStableCard[]

---@class BeastkeeperStableCard: Button
---@field key string? the pet it shows
---@field model PlayerModel
---@field name FontString
---@field level FontString
---@field spec FontString
---@field abilities FontString
---@field teach FontString

---The Families tab's panel (Modules\BeastMap\Families.lua).
---@class BeastkeeperFamiliesPanel: Frame
---@field rows BeastkeeperFamilyRow[]
---@field beasts BeastkeeperFamilyBeastRow[]
---@field model PlayerModel
---@field title FontString
---@field titleIcon Texture the chosen family's portrait
---@field spec FontString
---@field diet FontString
---@field abilities FontString
---@field none FontString
---@field chosen number? the family shown

---@class BeastkeeperFamilyRow: Button
---@field icon Texture the family's portrait
---@field label FontString
---@field familyID number?

---@class BeastkeeperFamilyBeastRow: Frame
---@field text FontString
---@field go Button
---@field npc number?

---@class BeastkeeperPetModel: PlayerModel
---@field dragX number? the cursor's x while the mouse drags it

---One of the core's sources (Core\Listen.lua): the game events it watches while its message has a
---listener, a method per event of the same name, and Start, which takes stock when it begins.
---@class BeastkeeperSource
---@field events string[]
---@field running boolean? watching now
---@field pending boolean? a check is on its way (the growth source)
---@field Start fun(self: BeastkeeperSource)
---@field [string] any its own state and event methods

---The names of the messages Beastkeeper sends: "<NAME>_TOAST" and so on (Core\Addon.lua).
---@class BeastkeeperMessages
---@field print string
---@field toast string
---@field ranksKnown string
---@field abilityLearned string
---@field petGrowth string
---@field autocastWanted string
---@field rareSeen string
---@field huntStarted string
---@field huntEnded string
---@field petHappiness string
---@field petDied string
---@field petTamed string
---@field ammo string

---Any value the game hands over, before the addon checks its type.
---@alias GameValue string|number|boolean|table|nil

---The addon object, which is also the files' namespace (`local _, ns = ...`).
---@class Addon: AceAddon, AceConsole-3.0, AceEvent-3.0
---@field NAME string the folder's name, which every name the game sees is made from (Core\Addon.lua)
---@field SLASH_ALIAS string the slash command's short form, beside NAME in lower case
---@field messages BeastkeeperMessages the messages Addon sends, by key
---@field L table<string, string> the AceLocale strings
---@field db AceDBObject-3.0 BeastkeeperDB; profile.modules[name] holds each module's switch
---@field modules table<string, BeastkeeperModule> AceAddon's own module table, by name
---@field features {happiness: boolean, ammo: boolean, beastTraining: boolean, beastData: boolean} what the client's game has (Core\Features.lua)
---@field C BeastkeeperCompat the modern pet, spellbook and tooltip API on every client (Core\Compat.lua)
---@field optionsCategoryID string|number the settings page, for Settings.OpenToCategory
---@field moduleCategoryIDs table<string, string|number> each module's page, by module name
---@field PROFILE_OPTIONS string[] the keys of AceDBOptions' own Profiles entries, see Core\Options.lua
---@field data BeastkeeperData
---@field window BeastkeeperWindow? made the first time it opens
---@field WINDOW_PANEL_WIDTH number a window tab's panel width
---@field families table<string, number> CreatureFamily IDs by key: families.cat is 2
---@field petSpecs BeastkeeperPetSpecs the families' specializations
---@field diets BeastkeeperDiets the kinds of food a family eats
---@field happiness {unhappy: number, content: number, happy: number} GetPetHappiness's values
---@field sex {unknown: number, male: number, female: number} UnitSex's values
---@field factions {alliance: string, horde: string} UnitFactionGroup's first return
---@field raidMarks {star: number, circle: number, diamond: number, triangle: number, moon: number, square: number, cross: number, skull: number} SetRaidTarget's and /tm's indexes
---@field ammoKinds {arrow: BeastkeeperAmmoKind, bullet: BeastkeeperAmmoKind} Projectile item subclasses (Data\Ammo.lua)
---@field familyInfo table<number, BeastkeeperFamilyInfo> by CreatureFamily ID
---@field petCategories BeastkeeperPetCategories the families' categories before Wrath
---@field familyMods table<number, BeastkeeperFamilyMods> by CreatureFamily ID, the classic clients'
---@field FamilyModsText fun(familyID: number?): string?
