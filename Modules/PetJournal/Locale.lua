-- PetJournal's English strings: the "PetJournal" namespace on the CurseForge translation page (see
-- Locales\README.md). Ability names, ranks, families and loyalty names come from the client.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip.
L.PETJOURNAL_TITLE = "Pet Journal"
L.PETJOURNAL_DESC = "A page for every pet your hunter had out: when and where you tamed it, its level and loyalty, how long you were out together, how often it died, when its next loyalty level may come, and the abilities it had."

-- The page: the switch for the pet's tooltip.
L.PETJOURNAL_OPTION_TOOLTIP = "Show the journal in my pet's tooltip"
L.PETJOURNAL_OPTION_TOOLTIP_DESC = "Hover your pet or its portrait: when it came, the time out together, its deaths, the next loyalty level and what it could still teach you."

-- The page: the choice of pet. A choice: %s the pet's name, %d its level, second %s its family.
L.PETJOURNAL_PET = "Pet"
L.PETJOURNAL_PET_ENTRY = "%s (level %d %s)"

-- Kennel's window: the tab's name; a pet in its list (%s the name, %d the level, second %s the
-- family); the card when there is no pet in the journal yet.
L.PETJOURNAL_TAB = "Pets"
L.PETJOURNAL_ROW = "%s, %d %s"
L.PETJOURNAL_NONE = "No pets yet: summon one."
-- Kennel's window, the Stable tab: its name; under a pet's card how many ranks it could still
-- teach the hunter (%d; |4rank:ranks; is WoW's own plural), or that it has none.
L.PETJOURNAL_TAB_STABLE = "Stable"
L.PETJOURNAL_TEACHES = "Can teach you %d |4rank:ranks;"
L.PETJOURNAL_TEACHES_NONE = "Nothing new for you"

-- The journal. %s: a date and time such as "2026-10-17 21:05"; second %s: the zone; %d: the NPC ID it was tamed as.
L.PETJOURNAL_TAMED = "Tamed %s in %s, as NPC %d."
-- For a pet Kennel did not see tamed: when it was first out with Kennel loaded.
L.PETJOURNAL_FIRST = "First seen %s in %s."
-- %d: its level; first %s: its family (Cat); second %s: its loyalty level, such as "4 (Dependable)".
L.PETJOURNAL_LEVEL = "Level %d %s, loyalty %s."
-- %s: a duration, PETJOURNAL_HOURS or PETJOURNAL_MINUTES.
L.PETJOURNAL_OUT = "Out together: %s."
L.PETJOURNAL_HOURS = "%d h %d min"
L.PETJOURNAL_MINUTES = "%d min"
-- %d: how often. |4time:times; is WoW's own plural (singular:plural).
L.PETJOURNAL_DIED = "Died %d |4time:times;."
-- The next loyalty level, from how long the rises it saw took while out. %s: a duration.
L.PETJOURNAL_NEXT_IN = "Next loyalty level in about %s out."
L.PETJOURNAL_NEXT_NOW = "Next loyalty level any moment now."
L.PETJOURNAL_NEXT_UNKNOWN = "Next loyalty level: not enough seen yet."
-- %s: a list like "Bite (Rank 1), Claw (Rank 2)".
L.PETJOURNAL_ABILITIES = "Abilities: %s."
-- The ranks of those it could still teach the hunter (above the highest the hunter knows). %s: a list as above.
L.PETJOURNAL_TEACH = "Can teach you: %s."

-- stylua: ignore end
