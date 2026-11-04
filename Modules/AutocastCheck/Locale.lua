-- AutocastCheck's English strings: the "AutocastCheck" namespace on the CurseForge translation
-- page (see Locales\README.md). Each says where it appears and what its placeholders hold. Ability
-- names come from the game and need nothing here; slash commands stay English.
local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title.
L.AUTOCAST_TITLE = "Autocast Check"
-- Settings window: the tooltip of the module's switch.
L.AUTOCAST_DESC = "Growl or Cower on autocast, as fits: Cower in a dungeon group, Growl elsewhere, unless you chose with the HuntswornKite or HuntswornGrowl macro. A toast when it does not fit, and one key that sets it right."

-- Settings window, Huntsworn's page: the kind of toast this module shows, for choosing its look.
-- Shown after "Autocast Check: ".
L.AUTOCAST_TOASTTYPE_PROBLEM = "autocast does not fit"
-- Toast title when an ability is on autocast but should not be. %s: the ability's name.
L.AUTOCAST_TOAST_ON = "%s is on autocast"
-- Toast title when an ability is not on autocast but should be. %s: the ability's name.
L.AUTOCAST_TOAST_OFF = "%s is not on autocast"
-- Toast text, solo (the pet holds the mobs). Growl and Cower are pet abilities; translate them as
-- the game does in your language.
L.AUTOCAST_REASON_SOLO = "Solo your pet holds the mobs: Growl on, Cower off."
-- Toast text, in a dungeon or raid group (the tank holds the mobs).
L.AUTOCAST_REASON_DUNGEON = "In a dungeon group the tank holds the mobs: Growl off, Cower on."
-- Toast text, after the player chose Cower with the HuntswornKite macro (the mob chases the hunter).
L.AUTOCAST_REASON_CHOSEN_COWER = "You chose Cower: the mob is on you, not on your pet. Growl off, Cower on."
-- Toast text, after the player chose Growl with the HuntswornGrowl macro (the pet tanks).
L.AUTOCAST_REASON_CHOSEN_GROWL = "You chose Growl: your pet holds the mobs. Growl on, Cower off."
-- Toast text, while the pet has a Cower rank the hunter does not know (it is learned from the pet's use).
L.AUTOCAST_REASON_LEARNING = "Your pet has a rank of Cower you do not know yet: you learn it only once your pet uses it. Growl on, Cower on."
-- Toast hint: how to set it right. %s: the key bound to it, such as "G". HuntswornAutocast is a macro name and stays as it is.
L.AUTOCAST_HINT_KEY = "Press %s."
L.AUTOCAST_HINT_MACRO = "Press your HuntswornAutocast macro."

-- Chat, after the HuntswornAutocast macro or its key. First %s: the ability put on autocast (Growl
-- or Cower, the client's name); second: the one put off.
L.AUTOCAST_SET = "Autocast: %s on, %s off."
-- The same, with both put on (Growl, and Cower while learning it from the pet).
L.AUTOCAST_SET_BOTH = "Autocast: %s on, %s on."

-- Chat, after the HuntswornKite or HuntswornGrowl macro chose.
L.AUTOCAST_CHOSE_COWER = "Cower from now on, until you enter or leave a dungeon group."
L.AUTOCAST_CHOSE_GROWL = "Growl from now on, until you enter or leave a dungeon group."

-- /huntsworn help: what the commands do. Shown after "/huntsworn autocast cower" and "... growl".
L.AUTOCAST_CMD_COWER = "Cower is what fits, until a dungeon group is entered or left (the HuntswornKite macro)"
L.AUTOCAST_CMD_GROWL = "Growl is what fits, until a dungeon group is entered or left (the HuntswornGrowl macro)"

-- The tooltip of an action button holding one of the macros: what it does.
L.AUTOCAST_MACRO_KITE = "Huntsworn: puts Cower on and Growl off, then casts Distracting Shot. Holds until you enter or leave a dungeon group."
L.AUTOCAST_MACRO_GROWL = "Huntsworn: puts Growl on and Cower off, to stop kiting or when your pet tanks a group. Holds until you enter or leave a dungeon group."
L.AUTOCAST_MACRO_AUTOCAST = "Huntsworn: sets Growl and Cower as fits: Cower in a dungeon group, Growl elsewhere, or what you chose with HuntswornKite or HuntswornGrowl."

-- Esc > Options > Keybindings > AddOns > Huntsworn: the key that sets Growl and Cower right.
L.AUTOCAST_BINDING = "Autocast Check: set Growl and Cower as fits"

-- Settings page.
L.AUTOCAST_OPTION_GROWL = "Watch Growl"
L.AUTOCAST_OPTION_GROWL_DESC = "A toast when Growl's autocast does not fit."
L.AUTOCAST_OPTION_COWER = "Watch Cower"
L.AUTOCAST_OPTION_COWER_DESC = "A toast when Cower's autocast does not fit."
L.AUTOCAST_OPTION_LEARN_COWER = "Cower on while learning it from your pet"
L.AUTOCAST_OPTION_LEARN_COWER_DESC = "Your hunter learns a rank from a tamed beast only when the pet uses it. While your pet has a Cower rank you do not know yet, Cower belongs on autocast beside Growl, and the key and the HuntswornAutocast macro put it on."
L.AUTOCAST_OPTION_REMIND = "Remind me when combat starts"
L.AUTOCAST_OPTION_REMIND_DESC = "Whatever is still wrong toasts again at the pull."
-- A slider under it, in minutes.
L.AUTOCAST_OPTION_REMIND_EVERY = "At most every (minutes)"
L.AUTOCAST_OPTION_REMIND_EVERY_DESC = "A problem toasts again at a pull only when its last toast is at least this many minutes ago. 0: at every pull."
L.AUTOCAST_OPTION_SOUND = "Sound"
-- Settings page: the sound choices.
L.AUTOCAST_OPTION_SOUND_FAMILY = "Your pet's call, as when you send it to attack (raid warning when it has none)"
L.AUTOCAST_OPTION_SOUND_WARNING = "The raid warning"
L.AUTOCAST_OPTION_SOUND_OFF = "No sound"
-- Settings page: button that shows an example toast.
L.AUTOCAST_OPTION_TEST = "Show a toast"
-- Settings page: button that makes the macros; its tooltip names them. HuntswornKite, HuntswornGrowl
-- and HuntswornAutocast are macro names and stay as they are.
L.AUTOCAST_OPTION_MACROS = "Make the macros"
L.AUTOCAST_OPTION_MACROS_DESC = "HuntswornKite puts Cower on, Growl off and casts Distracting Shot; HuntswornGrowl puts Growl on and Cower off (to stop kiting, or when your pet tanks); HuntswornAutocast sets them as fits. Made once by themselves for each hunter; this makes the missing ones again."

-- stylua: ignore end
