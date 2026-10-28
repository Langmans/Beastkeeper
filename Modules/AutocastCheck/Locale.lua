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
L.AUTOCAST_DESC = "Growl or Cower on autocast, as fits: Cower in a dungeon group, Growl elsewhere, unless you chose with the BeastkeeperKite or BeastkeeperGrowl macro. A toast when it does not fit, and one key that sets it right."

-- Settings window, Beastkeeper's page: the kind of toast this module shows, for choosing its look.
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
-- Toast text, after the player chose Cower with the BeastkeeperKite macro (the mob chases the hunter).
L.AUTOCAST_REASON_CHOSEN_COWER = "You chose Cower: the mob is on you, not on your pet. Growl off, Cower on."
-- Toast text, after the player chose Growl with the BeastkeeperGrowl macro (the pet tanks).
L.AUTOCAST_REASON_CHOSEN_GROWL = "You chose Growl: your pet holds the mobs. Growl on, Cower off."
-- Toast hint: how to set it right. %s: the key bound to it, such as "G". BeastkeeperAutocast is a macro name and stays as it is.
L.AUTOCAST_HINT_KEY = "Press %s."
L.AUTOCAST_HINT_MACRO = "Press your BeastkeeperAutocast macro."

-- Chat, after the BeastkeeperAutocast macro or its key. First %s: the ability put on autocast (Growl
-- or Cower, the client's name); second: the one put off.
L.AUTOCAST_SET = "Autocast: %s on, %s off."

-- Chat, after the BeastkeeperKite or BeastkeeperGrowl macro chose.
L.AUTOCAST_CHOSE_COWER = "Cower from now on, until you enter or leave a dungeon group."
L.AUTOCAST_CHOSE_GROWL = "Growl from now on, until you enter or leave a dungeon group."

-- /beastkeeper help: what the commands do. Shown after "/beastkeeper autocast cower" and "... growl".
L.AUTOCAST_CMD_COWER = "Cower is what fits, until a dungeon group is entered or left (the BeastkeeperKite macro)"
L.AUTOCAST_CMD_GROWL = "Growl is what fits, until a dungeon group is entered or left (the BeastkeeperGrowl macro)"

-- The tooltip of an action button holding one of the macros: what it does.
L.AUTOCAST_MACRO_KITE = "Beastkeeper: puts Cower on and Growl off, then casts Distracting Shot. Holds until you enter or leave a dungeon group."
L.AUTOCAST_MACRO_GROWL = "Beastkeeper: puts Growl on and Cower off, to stop kiting or when your pet tanks a group. Holds until you enter or leave a dungeon group."
L.AUTOCAST_MACRO_AUTOCAST = "Beastkeeper: sets Growl and Cower as fits: Cower in a dungeon group, Growl elsewhere, or what you chose with BeastkeeperKite or BeastkeeperGrowl."

-- Esc > Options > Keybindings > AddOns > Beastkeeper: the key that sets Growl and Cower right.
L.AUTOCAST_BINDING = "Autocast Check: set Growl and Cower as fits"

-- Settings page.
L.AUTOCAST_OPTION_GROWL = "Watch Growl"
L.AUTOCAST_OPTION_GROWL_DESC = "A toast when Growl's autocast does not fit."
L.AUTOCAST_OPTION_COWER = "Watch Cower"
L.AUTOCAST_OPTION_COWER_DESC = "A toast when Cower's autocast does not fit."
L.AUTOCAST_OPTION_REMIND = "Remind me when combat starts"
L.AUTOCAST_OPTION_REMIND_DESC = "Whatever is still wrong toasts again at the pull."
L.AUTOCAST_OPTION_SOUND = "Sound"
-- Settings page: the sound choices.
L.AUTOCAST_OPTION_SOUND_FAMILY = "Your pet's call, as when you send it to attack (raid warning when it has none)"
L.AUTOCAST_OPTION_SOUND_WARNING = "The raid warning"
L.AUTOCAST_OPTION_SOUND_OFF = "No sound"
-- Settings page: button that shows an example toast.
L.AUTOCAST_OPTION_TEST = "Show a toast"
-- Settings page: button that makes the macros; its tooltip names them. BeastkeeperKite, BeastkeeperGrowl
-- and BeastkeeperAutocast are macro names and stay as they are.
L.AUTOCAST_OPTION_MACROS = "Make the macros"
L.AUTOCAST_OPTION_MACROS_DESC = "BeastkeeperKite puts Cower on, Growl off and casts Distracting Shot; BeastkeeperGrowl puts Growl on and Cower off (to stop kiting, or when your pet tanks); BeastkeeperAutocast sets them as fits. Made once by themselves for each hunter; this makes the missing ones again."

-- stylua: ignore end
