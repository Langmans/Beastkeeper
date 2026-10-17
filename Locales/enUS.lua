-- English strings, also the fallback for every other client language. Every string has a
-- comment saying where it appears and what each placeholder holds, for translators; see
-- Locales\README.md. These are the core's strings (the base namespace on CurseForge); a module
-- keeps its own in its own file and namespace.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: title of the page with the on/off switch for each module.
L.MODULES = "Modules"
-- Settings window: the text above the module switches.
L.MODULES_DESC = "Turn each part of Kennel on or off. A module that is off does nothing at all."
-- Chat, after a /kennel command of a module that is switched off. %s: the module's title.
L.MODULE_OFF = "%s is off. Turn it on in the options: /kennel"
-- Chat, after a /kennel line that matches no command. %s: what the player typed after /kennel.
L.UNKNOWN_COMMAND = "Unknown command: %s"
-- Chat, /kennel help: the heading above the list of commands.
L.HELP_HEADER = "Commands:"
-- Chat, /kennel help: the first line of the list. "/kennel" is the command and stays as it is.
L.HELP_OPTIONS = "/kennel - open the options"
-- Chat, /kennel help: one line per command. First %s: the module's command word, second %s:
-- the command (both typed as they are, not translated), third %s: what the command does.
L.HELP_COMMAND = "/kennel %s %s - %s"

-- Settings window, Kennel's page: the toast every module shows (a small card near the top of the
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
-- The looks Kennel brings: a small card near the top, or a large splash in the middle.
L.TOAST_SKIN_CARD = "Card: small, near the top"
L.TOAST_SKIN_SPLASH = "Splash: large, in the middle"
-- The look that sends a toast as one line of text where LibSink sends it (floating combat text, chat, raid warning, ...). "LibSink" is a library's name and stays as it is.
L.TOAST_SKIN_LIBSINK = "Floating text and more (LibSink)"
-- An output in LibSink's list (with the MessageQueue addon): say the toast in a chat channel. "MessageQueue" is an addon's name and stays as it is.
L.SINK_MESSAGEQUEUE = "Chat channel (MessageQueue)"
L.SINK_MESSAGEQUEUE_DESC = "Says it in a chat channel. Say, yell and channels are sent on your next key press or click, as WoW: Forever requires."
-- Choice in the select of one kind of toast: use the look chosen for every toast.
L.TOAST_SKIN_SAME = "Same as all toasts"
-- Settings window, Kennel's page: the look of Kennel's buttons (the feed button) and of the
-- lists that hold buttons (its food list). Choices: "Automatic" and skin names such as "Masque".
L.BUTTONS = "Buttons"
L.BUTTONS_DESC = "The look of Kennel's buttons, such as the feed button, and of its lists. Automatic takes Masque, ElvUI or EllesmereUI when one is loaded. Takes effect after /reload."
L.BUTTONS_SKIN = "Button look"
L.BUTTONS_HOLDER = "List look"
L.BUTTONS_AUTO = "Automatic"
-- Button: shows an example toast.
L.TOAST_TEST = "Show an example"
-- The example toast: its title and text.
L.TOAST_TEST_TITLE = "This is a toast"
L.TOAST_TEST_TEXT = "Kennel's modules show a toast like this when something needs your attention."

-- Chat, after a module made its macros. %s: a list of macro names (KennelKite, ...).
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
