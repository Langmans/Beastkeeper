-- English strings, also the fallback for every other client language. Every string has a
-- comment saying where it appears and what each placeholder holds, for translators; see
-- Locales\README.md. These are the core's strings (the base namespace on CurseForge); a module
-- keeps its own in its own file and namespace.
local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: title of the page with the on/off switch for each module.
L.MODULES = "Modules"
-- Settings window: the text above the module switches.
L.MODULES_DESC = "Turn each part of Beastkeeper on or off. A module that is off does nothing at all."
-- Chat, after a /beastkeeper command of a module that is switched off. %s: the module's title.
L.MODULE_OFF = "%s is off. Turn it on in the options: /beastkeeper config"
-- Chat, after a /beastkeeper line that matches no command. %s: what the player typed after /beastkeeper.
L.UNKNOWN_COMMAND = "Unknown command: %s"
-- Chat, /beastkeeper help: the heading above the list of commands.
L.HELP_HEADER = "Commands:"
-- Chat, /beastkeeper help: the first lines of the list. "/beastkeeper" and "config" are typed as they are.
L.HELP_WINDOW = "/beastkeeper - open or close Beastkeeper's window"
L.HELP_OPTIONS = "/beastkeeper config - open the options"

-- Settings window, Beastkeeper's page: the box for the debug addons OAP Debug and DebugLog (addons'
-- names, each a debug window): how much Beastkeeper sends to them.
L.DEBUG = "Debug"
L.DEBUG_LEVEL = "Send to OAP Debug and DebugLog"
L.DEBUG_DESC = "How much goes to OAP Debug and DebugLog (metrics: timings and counts, OAP Debug only)."
L.DEBUG_MISSING = "Neither is installed: nothing is sent."
L.DEBUG_ERRORS = "Errors only"
L.DEBUG_NORMAL = "Normal"
L.DEBUG_METRICS = "Normal + metrics"
L.DEBUG_DETAILED = "Detailed"

-- A pet family's specialization, as Wowhead sorts the families: on a pet's card and the Families tab.
L.FAMILY_FEROCITY = "Ferocity"
L.FAMILY_CUNNING = "Cunning"
L.FAMILY_TENACITY = "Tenacity"
-- Before Wrath instead: a family's category, then its modifiers, such as "Offense: +10% damage, -2%
-- health" (%s the category, then the modifiers joined by ", "; each %+d a signed percentage).
L.FAMILY_OFFENSE = "Offense"
L.FAMILY_DEFENSE = "Defense"
L.FAMILY_GENERAL = "General"
L.FAMILY_MODS = "%s: %s"
L.FAMILY_DAMAGE = "%+d%% damage"
L.FAMILY_HEALTH = "%+d%% health"
L.FAMILY_ARMOR = "%+d%% armor"

-- Beastkeeper's window: its title, and the name of its key binding (Esc > Options > Keybindings > AddOns).
L.WINDOW_TITLE = "Beastkeeper"
L.WINDOW_BINDING = "Beastkeeper: open or close the window"
-- Chat, /beastkeeper help: one line per command. First %s: the module's command word, second %s:
-- the command (both typed as they are, not translated), third %s: what the command does.
L.HELP_COMMAND = "/beastkeeper %s %s - %s"

-- Settings window, Beastkeeper's page: the toast every module shows (a small card near the top of the
-- screen with an icon and a few lines of text).
L.TOAST = "Toast"
L.TOAST_DESC = "Drag a toast to move it, right-click to close it, hover over it to keep it up."
-- Slider: how many seconds a toast stays before it fades.
L.TOAST_DURATION = "Stays for (seconds)"
-- Slider: the toast's size, 1 is normal.
L.TOAST_SCALE = "Size"
-- Button: puts the toast back in its standard spot.
L.TOAST_RESET = "Reset position"
-- Select: the look of every toast. Its choices are skin names, such as "Card" and "Splash".
L.TOAST_SKIN = "Look"
L.TOAST_SKIN_DESC = "How toasts look. Below it, each kind of toast can have a look of its own."
-- The looks Beastkeeper brings: a small card near the top, or a large splash in the middle.
L.TOAST_SKIN_CARD = "Card: small, near the top"
L.TOAST_SKIN_SPLASH = "Splash: large, in the middle"
-- The look that shows a toast as the game's raid warning: one line of big text in the middle.
L.TOAST_SKIN_RAIDWARNING = "Raid warning: big text in the middle"
-- The look that sends a toast as one line of text where LibSink sends it (floating combat text, chat, raid warning, ...). "LibSink" is a library's name and stays as it is.
L.TOAST_SKIN_LIBSINK = "Floating text and more (LibSink)"
-- An output in LibSink's list (with the MessageQueue addon): say the toast in a chat channel. "MessageQueue" is an addon's name and stays as it is.
-- The look that hands the toast to the LS: Toasts addon, which shows it with its own toasts. "LS: Toasts" is an addon's name and stays as it is.
L.TOAST_SKIN_LSTOASTS = "LS: Toasts"
L.SINK_MESSAGEQUEUE ="Chat channel (MessageQueue)"
L.SINK_MESSAGEQUEUE_DESC = "Says it in a chat channel. Say, yell and channels are sent on your next key press or click, as WoW: Forever requires."
-- Choice in the select of one kind of toast: use the look chosen for every toast.
L.TOAST_SKIN_SAME = "Same as all toasts"
-- Settings window, Beastkeeper's page: the look of Beastkeeper's buttons (the feed button) and of the
-- lists that hold buttons (its food list). Choices: "Automatic" and skin names such as "Masque".
L.BUTTONS = "Buttons"
L.BUTTONS_DESC = "The look of Beastkeeper's buttons, such as the feed button, and of its lists. Automatic takes Masque, ElvUI or EllesmereUI when one is loaded. Takes effect after /reload."
L.BUTTONS_SKIN = "Button look"
L.BUTTONS_HOLDER = "List look"
L.BUTTONS_CROP = "Crop icons of their border"
L.BUTTONS_CROP_DESC = "Trim the border off the game's icons in Beastkeeper's window, lists and toasts. Switch it off for an icon pack whose icons have none, such as Clean Icons. With ElvUI's look, ElvUI's own Crop Icons setting decides."
L.BUTTONS_AUTO = "Automatic"
-- Button: shows an example toast.
L.TOAST_TEST = "Show an example"
-- The example toast: its title and text.
L.TOAST_TEST_TITLE = "This is a toast"
L.TOAST_TEST_TEXT = "Beastkeeper's modules show a toast like this when something needs your attention."

-- Chat, after a module made its macros. %s: a list of macro names (BeastkeeperKite, ...).
L.MACROS_MADE = "Made the macros %s for this character: drag them from the macro window (/macro) onto an action bar."
-- Chat, when the character's macros were full. %s: a list of macro names.
L.MACROS_MADE_ACCOUNT = "Made %s among the account-wide macros, since this character's are full."
-- Chat, when there was no room at all. %s: a list of macro names.
L.MACROS_FULL = "No room for %s: your character and account-wide macros are both full."
-- Chat, after "Make the macros" when every macro was there already.
L.MACROS_THERE = "The macros are there already."
-- Chat, after "Make the macros" in combat.
L.MACROS_COMBAT = "Macros cannot be made in combat; try again after the fight."

-- stylua: ignore end
