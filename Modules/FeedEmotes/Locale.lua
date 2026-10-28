-- FeedEmotes' English strings: the "FeedEmotes" namespace on the CurseForge translation page (see
-- Locales\README.md). The emote lines themselves are not here: they are in Lines\<locale>.lua,
-- with the grammar each language needs.
local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip.
L.FEEDEMOTES_TITLE = "Feed Emotes"
L.FEEDEMOTES_DESC = "Sends a silly /emote every time you feed your pet, Feed-O-Matic style: \"Langmans feeds Fluffy some Mystery Meat. Tastes like well-aged gnome.\" Others in range see it."

-- Settings page.
L.FEEDEMOTES_OPTION_PET_NAME = "Always use the pet's name"
L.FEEDEMOTES_OPTION_PET_NAME_DESC = "Name the pet instead of saying he or she."
L.FEEDEMOTES_OPTION_TEST = "Show an example"
L.FEEDEMOTES_OPTION_TEST_DESC = "Prints an emote about Mystery Meat in your own chat window only; nothing is sent."-- The pet's sex: the game does not tell it for a hunter pet, so the player picks it per pet.
L.FEEDEMOTES_OPTION_SEX = "Your pet's sex"
-- %s: the summoned pet's name.
L.FEEDEMOTES_OPTION_SEX_FOR = "Sex of %s"
L.FEEDEMOTES_OPTION_SEX_DESC = "Picks he or she and the lines for males or females. Kept for this pet through renames and stable swaps."
L.FEEDEMOTES_OPTION_SEX_NONE = "Summon your pet to choose its sex."
L.FEEDEMOTES_OPTION_SEX_GAME = "From the game"
L.FEEDEMOTES_OPTION_SEX_MALE = "Male"
L.FEEDEMOTES_OPTION_SEX_FEMALE = "Female"

-- Your own lines.
L.FEEDEMOTES_OPTION_OWN = "Your own lines"
-- %s: the placeholders a line can use, such as "{pet}, {food}, {he}".
L.FEEDEMOTES_OPTION_OWN_DESC = "Lines of your own, after the first sentence (\"feeds Fluffy some Mystery Meat.\"). Placeholders: %s. Start a line with conditions in brackets, such as [cat,fish], to use it only then."
-- A slider from 0 to 100.
L.FEEDEMOTES_OPTION_CHANCE = "Chance of an own line (0: even)"
L.FEEDEMOTES_OPTION_CHANCE_DESC = "0: every fitting line, yours or built-in, has the same chance. Otherwise this share of emotes wants one of your lines; 100 means only yours."
L.FEEDEMOTES_OPTION_FALLBACK = "Use a built-in line when none of mine fits"
L.FEEDEMOTES_OPTION_FALLBACK_DESC = "Unticked, such an emote only says who was fed what."
L.FEEDEMOTES_OPTION_SHARED = "Share my lines with all characters"
L.FEEDEMOTES_OPTION_SHARED_DESC = "One list for every character that ticks this; unticked, this character keeps its own."
L.FEEDEMOTES_OPTION_NEW = "New line"
L.FEEDEMOTES_OPTION_NEW_DESC = "Type the line and press Enter; the conditions ticked above are added to it."
-- Condition boxes above the new line: only use it for this pet, food or family.
L.FEEDEMOTES_OPTION_COND_SEX = "Only for"
L.FEEDEMOTES_OPTION_COND_FOODTYPE = "Only with"
L.FEEDEMOTES_OPTION_COND_FAMILY = "Only for these families"
-- Above the list. %d: the number of lines in it.
L.FEEDEMOTES_OPTION_LIST_OWN = "Lines for this character (%d)"
L.FEEDEMOTES_OPTION_LIST_SHARED = "Lines shared by all characters (%d)"
-- One line in the list, edited in place. %d: its number.
L.FEEDEMOTES_OPTION_LINE = "Line %d"
L.FEEDEMOTES_OPTION_REMOVE = "Remove"
L.FEEDEMOTES_OPTION_NONE = "No lines yet."

-- Condition names; the tag itself in brackets (such as [bird_of_prey]) stays English.
L.FEEDEMOTES_COND_MALE = "Male"
L.FEEDEMOTES_COND_FEMALE = "Female"
L.FEEDEMOTES_COND_BREAD = "Bread"
L.FEEDEMOTES_COND_MEAT = "Meat"
L.FEEDEMOTES_COND_FISH = "Fish"
L.FEEDEMOTES_COND_CHEESE = "Cheese"
L.FEEDEMOTES_COND_FRUIT = "Fruit"
L.FEEDEMOTES_COND_FUNGUS = "Mushrooms"
L.FEEDEMOTES_COND_WOLF = "Wolf"
L.FEEDEMOTES_COND_CAT = "Cat"
L.FEEDEMOTES_COND_SPIDER = "Spider"
L.FEEDEMOTES_COND_BEAR = "Bear"
L.FEEDEMOTES_COND_BOAR = "Boar"
L.FEEDEMOTES_COND_CROCOLISK = "Crocolisk"
L.FEEDEMOTES_COND_CARRION_BIRD = "Carrion Bird"
L.FEEDEMOTES_COND_CRAB = "Crab"
L.FEEDEMOTES_COND_GORILLA = "Gorilla"
L.FEEDEMOTES_COND_RAPTOR = "Raptor"
L.FEEDEMOTES_COND_TALLSTRIDER = "Tallstrider"
L.FEEDEMOTES_COND_SCORPID = "Scorpid"
L.FEEDEMOTES_COND_TURTLE = "Turtle"
L.FEEDEMOTES_COND_BAT = "Bat"
L.FEEDEMOTES_COND_HYENA = "Hyena"
L.FEEDEMOTES_COND_BIRD_OF_PREY = "Bird of Prey"
L.FEEDEMOTES_COND_WIND_SERPENT = "Wind Serpent"
L.FEEDEMOTES_COND_FOX = "Fox"

-- Chat, after adding or changing a line. %d: its number; %s: the line as saved.
L.FEEDEMOTES_ADDED = "Line %d added: %s"
-- Chat, when a line is refused.
L.FEEDEMOTES_EMPTY = "Type a line first, such as: {pet} wolfs it down."
-- %d: the most bytes a line may have.
L.FEEDEMOTES_TOO_LONG = "That line is too long for an emote: at most %d bytes (letters outside A-Z count double)."
L.FEEDEMOTES_BAR = "A line cannot contain the | character."
L.FEEDEMOTES_DUPLICATE = "You already have that line."
-- First %s: the unknown condition; second %s: all conditions, such as "male, female, bread, ...".
L.FEEDEMOTES_UNKNOWN_CONDITION = "Unknown condition [%s]. Conditions: %s."
-- %d: a line number.
L.FEEDEMOTES_NO_SUCH = "There is no line %d."
-- Chat, from the example button when no pet is out.
L.FEEDEMOTES_NO_PET = "Summon your pet first."

-- stylua: ignore end
