-- English strings, also the fallback for every other client language. Every string has a
-- comment saying where it appears and what each placeholder holds, for translators; see
-- Locales\README.md. These are the core's strings (the base namespace on CurseForge); a module
-- keeps its own in its own file and namespace.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

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
