-- AutocastCheck's English strings: the "AutocastCheck" namespace on the CurseForge translation
-- page (see Locales\README.md). Each says where it appears and what its placeholders hold. Ability
-- names come from the game and need nothing here; slash commands stay English.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title.
L.AUTOCAST_TITLE = "Autocast Check"
-- Settings window: the tooltip of the module's switch.
L.AUTOCAST_DESC = "A toast when your pet's Growl or Cower autocast does not fit what you are doing: solo, in a dungeon group, kiting or tanking."

-- Settings window, Kennel's page: the kind of toast this module shows, for choosing its look.
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
-- Toast text, kite mode (chosen by the player: the mob chases the hunter, not the pet).
L.AUTOCAST_REASON_KITE = "Kite mode: the mob is on you, not on your pet: Growl off, Cower on."
-- Toast text, tank mode (chosen by the player: the pet tanks for a group without a tank).
L.AUTOCAST_REASON_TANK = "Tank mode: your pet tanks for the group: Growl on, Cower off."
-- Toast hint: how to switch autocast off.
L.AUTOCAST_HINT_TURN_OFF = "Right-click it on the pet bar or in your pet's spellbook to turn autocast off."
-- Toast hint: how to switch autocast on.
L.AUTOCAST_HINT_TURN_ON = "Right-click it on the pet bar or in your pet's spellbook to turn autocast on."

-- Chat, after the kite or tank command or key binding changed the mode.
L.AUTOCAST_KITE_ON = "Kite mode on: Growl off, Cower on."
L.AUTOCAST_KITE_OFF = "Kite mode off: solo or dungeon mode again, as fits."
L.AUTOCAST_TANK_ON = "Tank mode on: Growl on, Cower off."
L.AUTOCAST_TANK_OFF = "Tank mode off: solo or dungeon mode again, as fits."

-- /kennel help: what the commands do. Shown after "/kennel autocast kite" and "... tank".
L.AUTOCAST_CMD_KITE = "kite mode on, off, or switched without a word (for macros)"
L.AUTOCAST_CMD_TANK = "tank mode on, off, or switched without a word (for macros)"

-- Esc > Options > Keybindings > AddOns > Kennel: the two key bindings.
L.AUTOCAST_BINDING_KITE = "Autocast Check: toggle kite mode"
L.AUTOCAST_BINDING_TANK = "Autocast Check: toggle tank mode"

-- Settings page.
L.AUTOCAST_OPTION_MODE = "Mode"
-- Settings page: the mode choices. Growl and Cower as above.
L.AUTOCAST_OPTION_MODE_AUTO = "Automatic: solo, or dungeon in a dungeon or raid group"
L.AUTOCAST_OPTION_MODE_KITE = "Kite: Growl off, Cower on"
L.AUTOCAST_OPTION_MODE_TANK = "Tank: Growl on, Cower off, in a dungeon too"
-- Settings page: under the mode choice. "/kennel autocast kite" and "... tank" stay as they are.
L.AUTOCAST_OPTION_MODE_NOTE = "Same as /kennel autocast kite and /kennel autocast tank; both have a key binding under Esc > Options > Keybindings, and fit in a macro."
L.AUTOCAST_OPTION_GROWL = "Watch Growl"
L.AUTOCAST_OPTION_GROWL_DESC = "A toast when Growl's autocast does not fit the mode."
L.AUTOCAST_OPTION_COWER = "Watch Cower"
L.AUTOCAST_OPTION_COWER_DESC = "A toast when Cower's autocast does not fit the mode."
L.AUTOCAST_OPTION_REMIND = "Remind me when combat starts"
L.AUTOCAST_OPTION_REMIND_DESC = "Whatever is still wrong toasts again at the pull."
L.AUTOCAST_OPTION_SOUND = "Sound"
-- Settings page: the sound choices.
L.AUTOCAST_OPTION_SOUND_FAMILY = "Your pet's call, as when you send it to attack (raid warning when it has none)"
L.AUTOCAST_OPTION_SOUND_WARNING = "The raid warning"
L.AUTOCAST_OPTION_SOUND_OFF = "No sound"
-- Settings page: button that shows an example toast.
L.AUTOCAST_OPTION_TEST = "Show a toast"
-- Settings page: button that makes the macros; its tooltip names them. KennelKite, KennelKiteOff
-- and KennelTank are macro names and stay as they are.
L.AUTOCAST_OPTION_MACROS = "Make the macros"
L.AUTOCAST_OPTION_MACROS_DESC = "KennelKite casts Distracting Shot and switches kite mode on, KennelKiteOff switches it off, KennelTank switches tank mode. Made once by themselves for each hunter; this makes the missing ones again."

-- stylua: ignore end
