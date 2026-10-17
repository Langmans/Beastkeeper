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
---@field toastTypes table<string, string>? the kinds of toast it shows, by kind with a localized name; each can have a look of its own
---@field toastSkins table<string, string>? the look a kind starts on (a skin id), until the player picks another
---@field GetOptions (fun(self: KennelModule): table)? an AceConfig group (args, and name if not title); the core adds type and disabled

---A module whose settings Kennel:Setting reads and writes.
---@class KennelSettingsModule: KennelModule
---@field Settings fun(self: KennelSettingsModule): table

---A module that offers macros (Kennel:OfferMacros, Kennel:CreateMacros).
---@class KennelMacroModule: KennelModule
---@field Macros fun(self: KennelMacroModule): KennelMacro[]

---A macro a module makes for the player.
---@class KennelMacro
---@field name string at most 16 characters
---@field icon number|string FileDataID or texture path
---@field body string the macro text
---@field desc string? what it does, shown in the tooltip of an action button that holds it

---A toast sound: a sound file, or a sound kit.
---@class KennelSound
---@field file number? FileDataID for PlaySoundFile
---@field kit number? SoundKit ID for PlaySound

---What Kennel:ShowToast shows.
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

---A skin frame with a portrait badge (Kennel:AddToastPortrait).
---@class KennelPortraitFrame: Frame
---@field Portrait Texture
---@field PortraitRing Texture

---The toast's saved settings, profile.toast.
---@class KennelToastSettings
---@field duration number seconds it stays before it fades
---@field scale number
---@field pos [string, string, number, number]? point, relativePoint, x, y, once dragged
---@field skin string the skin id for every toast
---@field skins table<string, string> a skin id per kind of toast ("<module>:<kind>"), where chosen
---@field sink table LibSink's output choice, kept by LibSink itself

---What draws a toast (Core\Toast\). Kennel brings "card" and "splash"; another addon adds its
---own with Kennel:RegisterToastSkin(id, skin), to draw in its own style or to hand the toast to
---something else. The engine keeps the queue and the clock and calls, for one toast: Show once,
---Update every frame until the fade is done, then Hide. Kennel:NewToastFrame gives a frame that
---drags and closes like the others, Kennel:PlaceToast puts it where the player dragged it.
---@class KennelToastSkin
---@field name string shown in the look choice; localized
---@field Show fun(self: KennelToastSkin, info: KennelToastInfo, settings: KennelToastSettings) fill it in and show it; Update follows at once
---@field Update (fun(self: KennelToastSkin, intro: number, fade: number, left: number))? each 0 to 1: how far the intro is, how far the fade is (1 = gone), how much of its stay is left; required unless instant
---@field Hide (fun(self: KennelToastSkin))? required unless instant
---@field IsMouseOver (fun(self: KennelToastSkin): boolean)? while true, its stay does not count down; required unless instant
---@field Frame (fun(self: KennelToastSkin): Frame?)? its frame, when it has one
---@field instant boolean? it hands the toast on in Show and is done: the next toast follows at once
---@field GetOptions (fun(self: KennelToastSkin): table)? an AceConfig group of its own on Kennel's page

---A skin from Kennel:NewToastSkin: it draws in self.frame, and Hide, IsMouseOver and Frame are
---done; it adds Show and Update.
---@class KennelFrameSkin: KennelToastSkin
---@field frame Frame? made by its Show, with Kennel:NewToastFrame

---The card skin's frame, with its parts as fields like a template's parentKeys.
---@class KennelCardFrame: KennelPortraitFrame
---@field Accent Texture the coloured side bar
---@field Icon Texture
---@field Title FontString
---@field Text FontString
---@field Hint FontString
---@field Timer Texture the bar along the bottom that runs down

---How a card or splash skin looks (Kennel:NewCardSkin, Kennel:NewSplashSkin).
---@class KennelSkinStyle
---@field frameName string the frame's global name
---@field accent fun(): number[] { r, g, b } for a toast that brings no accent
---@field panel number[]? { r, g, b, a } of the panel; the splash fades its own black one without
---@field edge number[]? { r, g, b, a } of a 1-pixel edge (card only)
---@field Border fun(frame: Frame)? draws an edge itself
---@field Font fun(text: FontString, size: number)? sets a font; the game's fonts without

---@class KennelCardSkin: KennelFrameSkin
---@field style KennelSkinStyle
---@field frame KennelCardFrame? made on its first toast

---The splash skin's frame.
---@class KennelSplashFrame: KennelPortraitFrame
---@field Source FontString the module's name at the top
---@field Divider Texture the line under it
---@field Diamond Texture the accent square turned 45 degrees
---@field Inner Texture the dark square inside it
---@field Icon Texture
---@field Title FontString
---@field Text FontString
---@field Hint FontString
---@field Timer Texture

---@class KennelSplashSkin: KennelFrameSkin
---@field style KennelSkinStyle
---@field frame KennelSplashFrame?

---AutocastCheck's saved settings, its namespace's profile.
---@class KennelAutocastSettings
---@field growl boolean watch Growl
---@field cower boolean watch Cower
---@field remind boolean toast what is still wrong when combat starts
---@field sound "family"|"warning"|"off"

---@class KennelAutocastCheck: KennelMacroModule, KennelSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field active table<string, true> the problems the last check found, by problem key
---@field checkPending boolean? a check is on its way (ScheduleCheck)
---@field choice ("growl"|"cower")? what the player chose (KennelKite, KennelGrowl)
---@field choiceInDungeon boolean? whether the player was in a dungeon group then
---@field SPELLS table<"growl"|"cower", number>
---@field Spell fun(id: number): string, (number|string)?
---@field Settings fun(self: KennelAutocastCheck): KennelAutocastSettings used by Options.lua too
---@field Check fun(self: KennelAutocastCheck, remindAll: boolean?) used by Options.lua too
---@field TestToast fun(self: KennelAutocastCheck) used by Options.lua too
---@field Wanted fun(self: KennelAutocastCheck): "growl"|"cower", "solo"|"dungeon"|"chosen"
---@field Choose fun(self: KennelAutocastCheck, ability: "growl"|"cower")
---@field AutocastLines fun(on: "growl"|"cower"): string
---@field ApplyButton fun(self: KennelAutocastCheck)

---An ability that can autocast, as AutocastCheck reads it from the pet.
---@class KennelAutocastState
---@field on boolean
---@field icon (number|string)? from the pet bar; nil for one only in the spellbook

---CareButton's saved settings, its namespace's profile.
---@class KennelCareButtonSettings
---@field died boolean toast when the pet dies
---@field nopet boolean toast when combat starts without a pet
---@field low number the health percentage for the low toast; 0 is never
---@field sound "family"|"warning"|"off"

---@class KennelCareButton: KennelMacroModule, KennelSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field lowShown boolean the low toast was given and health has not been above the line since
---@field deadAfterCombat boolean a failed cast in combat showed the pet is dead
---@field reviveCasts table<string, true> Revive Pet casts that started, by cast GUID
---@field MEND_PET number
---@field REVIVE_PET number
---@field CALL_PET number
---@field PET_STATES string
---@field Settings fun(self: KennelCareButton): KennelCareButtonSettings
---@field SpellName fun(id: number): string
---@field Toast fun(self: KennelCareButton, kind: "dead"|"nopet"|"low", reason: string?, percent: number?): KennelToastInfo
---@field CheckHealth fun(self: KennelCareButton)
---@field OnPetState fun(self: KennelCareButton, state: string)
---@field MacroText fun(self: KennelCareButton, petDead: boolean): string
---@field PetDead fun(self: KennelCareButton): boolean
---@field SetPetDead fun(self: KennelCareButton, dead: boolean): boolean
---@field ApplyButton fun(self: KennelCareButton)
---@field UpdateMacro fun(self: KennelCareButton)

---A spell in the active pet's spellbook (Kennel.PetSpells).
---@class KennelPetSpell
---@field id number
---@field rank string? "Rank 2"; nil for a spell without ranks
---@field icon (number|string)?

---AbilityLearned's saved settings, its namespace's profile.
---@class KennelAbilityLearnedSettings
---@field sound "family"|"levelup"|"off"
---@field screenshot boolean
---@field hints boolean say in chat what a summoned pet can teach
---@field points boolean toast when the pet gains training points
---@field pointsSound "family"|"levelup"|"off" that toast's sound
---@field loyalty boolean toast when the pet's loyalty level drops
---@field loyaltySound "family"|"levelup"|"off" that toast's sound

---AbilityLearned's per-character data, its namespace's char.
---@class KennelAbilityLearnedChar
---@field history KennelLearnEntry[] oldest first, the last 200
---@field known table<string, number> the highest rank known per ability name
---@field trainingRead boolean Beast Training has been read once
---@field pets table<string, KennelPetGrowth> how each pet stood when last seen, by pet name

---How a pet stood when AbilityLearned last saw it.
---@class KennelPetGrowth
---@field total number its training points total
---@field level number
---@field loyalty number? its loyalty level; nil on a client without GetPetLoyalty

---A learn as AbilityLearned shows it.
---@class KennelLearn
---@field name string
---@field rank string?
---@field icon (number|string)?
---@field teacher string? the name of the pet out, when it has the ability
---@field simulated boolean? from the page's simulation: shown, not kept

---A learn as the history keeps it.
---@class KennelLearnEntry
---@field name string
---@field rank string?
---@field pet string?
---@field familyID number?
---@field zone string?
---@field t number GetServerTime()

---@class KennelAbilityLearned: KennelSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field ready boolean the login wait is over
---@field atTrainer boolean a trainer window was opened and not closed
---@field Settings fun(self: KennelAbilityLearned): KennelAbilityLearnedSettings
---@field Toast fun(self: KennelAbilityLearned, learn: KennelLearn): KennelToastInfo
---@field ShowLearn fun(self: KennelAbilityLearned, learn: KennelLearn)
---@field TrainerOpen fun(self: KennelAbilityLearned): boolean
---@field IsWildAbility fun(name: string): boolean
---@field OnChat fun(self: KennelAbilityLearned, line: GameValue): boolean
---@field SpellLearned fun(self: KennelAbilityLearned, spellID: number)
---@field Example fun(): string, string, number|string|nil, KennelPetSpell?
---@field Simulate fun(self: KennelAbilityLearned)
---@field MarkKnown fun(self: KennelAbilityLearned, name: string, rank: number)
---@field RecordLearn fun(self: KennelAbilityLearned, entry: KennelLearnEntry)
---@field HistoryText fun(self: KennelAbilityLearned): string
---@field ReadBeastTraining fun(self: KennelAbilityLearned)
---@field CheckHints fun(self: KennelAbilityLearned)
---@field CheckGrowth fun(self: KennelAbilityLearned)
---@field CheckPet fun(self: KennelAbilityLearned)
---@field Sound fun(self: KennelAbilityLearned, key: "sound"|"pointsSound"|"loyaltySound", petSound: "AGGRO"|"WOUND"|nil): KennelSound?
---@field ReportTeachable fun(self: KennelAbilityLearned)

---FeedEmotes' saved settings, its namespace's profile.
---@class KennelFeedEmotesSettings
---@field petName boolean always the pet's name, never he/she
---@field customChance number 0: every fitting line counts the same; else the share of emotes that wants an own line
---@field customFallback boolean a built-in line when an own one is wanted but none fits

---FeedEmotes' per-character data, its namespace's char.
---@class KennelFeedEmotesChar
---@field sharedLines boolean use the account-wide own lines (global.customLines)
---@field customLines string[] this character's own lines
---@field petSex table<number, number> pet number -> 2 male or 3 female

---What a pronoun placeholder becomes: by the pet's sex, and with the sex unknown a format with %s
---for the name or a function of it (the pet's name when there is neither).
---@class KennelPronoun
---@field male string
---@field female string
---@field unknown (string|fun(name: string): string)?

---The built-in lines of one language (FeedEmotes\Lines\<locale>.lua).
---@class KennelEmoteLines
---@field feed string|fun(pet: string, food: string): string the sentence in front: a format of the pet and the food, or a function
---@field feedNoFood string the same without a known food
---@field article (fun(name: string): string)? the article for {a}
---@field pronouns table<string, KennelPronoun>?
---@field emotes KennelEmoteLists

---@class KennelEmoteLists
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
---@alias KennelTagSet table<string, true>

---A condition an own line can start with.
---@class KennelFeedCondition
---@field tag string what is typed between the brackets
---@field group "sex"|"foodType"|"family"
---@field value number|string what the feeding must hold for that group

---What the lines are picked by for one feeding.
---@class KennelFeedSituation
---@field sex number?
---@field foodType string?
---@field family number?

---@class KennelFeedEmotes: KennelSettingsModule
---@field db AceDBObject-3.0 always set: the module has defaults
---@field watching boolean? on a hunter, where there is a pet to feed
---@field FEED_PET number
---@field CUSTOM_LINE_MAX number
---@field Lines table<string, KennelEmoteLines>
---@field FoodGroups table<number, string>
---@field FoodTypes table<number, string>
---@field Family table<string, number>
---@field ExoticFamily table<number, true>
---@field Conditions KennelFeedCondition[]
---@field ConditionByTag table<string, KennelFeedCondition>
---@field Tracker KennelFoodTracker
---@field Settings fun(self: KennelFeedEmotes): KennelFeedEmotesSettings
---@field Char fun(self: KennelFeedEmotes): KennelFeedEmotesChar
---@field LinesInUse fun(self: KennelFeedEmotes): KennelEmoteLines
---@field CustomLines fun(self: KennelFeedEmotes): string[]
---@field PetSex fun(self: KennelFeedEmotes): number?
---@field ChoosePetSex fun(self: KennelFeedEmotes, sex: number?): boolean
---@field PrunePetSex fun(self: KennelFeedEmotes)
---@field Feed fun(self: KennelFeedEmotes, itemID: number?)
---@field ParseCustomLine fun(line: string): KennelTagSet?, string
---@field FormatCustomLine fun(tags: table<string, true>, text: string): string
---@field ConditionsHold fun(tags: table<string, true>, situation: KennelFeedSituation): boolean
---@field AddCustomLine fun(self: KennelFeedEmotes, text: string?, extraTags: table<string, true>?): boolean, string
---@field ReplaceCustomLine fun(self: KennelFeedEmotes, index: number, text: string?): boolean, string
---@field RemoveCustomLine fun(self: KennelFeedEmotes, index: number): string?
---@field PlaceholderList fun(self: KennelFeedEmotes): string
---@field LinePools fun(self: KennelFeedEmotes, itemID: number?, foodName: string?): string[], string[]
---@field EmotePool fun(self: KennelFeedEmotes, itemID: number?, foodName: string?): string[]
---@field PickLine fun(self: KennelFeedEmotes, itemID: number?, foodName: string?): string?
---@field FillPlaceholders fun(self: KennelFeedEmotes, line: string, pet: string, food: string?, article: string?): string
---@field BuildEmote fun(self: KennelFeedEmotes, itemID: number?): string?

---The sound tables, Kennel.sounds.<KIND>_PER_FAMILY (Core\Sounds.lua).
---@class KennelSounds
---@field AGGRO_PER_FAMILY table<number, number>
---@field DEATH_PER_FAMILY table<number, number>
---@field WOUND_PER_FAMILY table<number, number>

---Any value the game hands over, before the addon checks its type.
---@alias GameValue string|number|boolean|table|nil

---The addon object, which is also the files' namespace (`local _, ns = ...`).
---@class Kennel: AceAddon, AceConsole-3.0, AceEvent-3.0
---@field L table<string, string> the AceLocale strings
---@field db AceDBObject-3.0 KennelDB; profile.modules[name] holds each module's switch
---@field modules table<string, KennelModule> AceAddon's own module table, by name
---@field optionsCategoryID string|number the settings page, for Settings.OpenToCategory
---@field PROFILE_OPTIONS string[] the keys of AceDBOptions' own Profiles entries, see Core\Options.lua
