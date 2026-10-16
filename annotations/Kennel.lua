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

---CareButton's saved settings, its namespace's profile.
---@class KennelCareButtonSettings
---@field died boolean toast when the pet dies
---@field nopet boolean toast when combat starts without a pet
---@field low number the health percentage for the low toast; 0 is never
---@field sound "family"|"warning"|"off"

---@class KennelCareButton: KennelMacroModule
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

---AbilityLearned's per-character data, its namespace's char.
---@class KennelAbilityLearnedChar
---@field history KennelLearnEntry[] oldest first, the last 200
---@field known table<string, number> the highest rank known per ability name
---@field trainingRead boolean Beast Training has been read once
---@field points table<string, number> each pet's training points total when last seen, by pet name

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

---@class KennelAbilityLearned: KennelModule
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
---@field CheckPoints fun(self: KennelAbilityLearned)
---@field CheckPet fun(self: KennelAbilityLearned)
---@field Sound fun(self: KennelAbilityLearned, fromPet: boolean): KennelSound?
---@field ReportTeachable fun(self: KennelAbilityLearned)

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
