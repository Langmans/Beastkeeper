-- AbilityLearned's English strings: the "AbilityLearned" namespace on the CurseForge translation
-- page (see Locales\README.md). Ability names, ranks ("Rank 2") and the game's "You have learned"
-- line come from the client and need nothing here; Beast Training is the hunter spell, named as the
-- game does in your language.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip.
L.ABILITYLEARNED_TITLE = "Ability Learned"
L.ABILITYLEARNED_DESC = "A toast when your hunter learns a pet ability from a tamed beast (Claw rank 2 from a Nightstalker, say) and when your pet gains training points, a history of learns per character, and what a pet you summon can still teach you. Abilities bought from a pet trainer do not count."

-- Settings window, Kennel's page: the kind of toast, for choosing its look. Shown after "Ability Learned: ".
L.ABILITYLEARNED_TOASTTYPE_LEARNED = "pet ability learned"
L.ABILITYLEARNED_TOASTTYPE_POINTS = "training points gained"

-- Toast title. %s: the ability with its rank, such as "Claw (Rank 2)".
L.ABILITYLEARNED_TOAST = "New pet ability: %s"
-- Toast text. First %s: the pet's name; second %s: the ability's name.
L.ABILITYLEARNED_FROM_PET = "%s has taught you %s."
-- Toast text when no pet out has the ability.
L.ABILITYLEARNED_TEACH = "Teach it to your pet from the Beast Training window."
-- Toast hint. %s: the pet's name; %d: its free training points.
L.ABILITYLEARNED_POINTS = "%s has %d training points free."

-- Toast title when the pet got training points. %s: the pet's name; %d: how many.
L.ABILITYLEARNED_POINTS_GAINED = "%s gained %d training points"
-- Toast text under it. %d: the pet's free training points.
L.ABILITYLEARNED_POINTS_FREE = "%d free to spend at Beast Training."

-- Chat, when a pet is summoned or tamed. %s: the pet's name; second %s: a list like "Claw (Rank 3), Dash (Rank 1)".
L.ABILITYLEARNED_TEACHES = "%s can teach you: %s."
L.ABILITYLEARNED_OPEN_TRAINING = "Open Beast Training once so Kennel knows your ranks."
-- Chat, after the "What can my pet teach?" button. %s: the pet's name.
L.ABILITYLEARNED_NOTHING = "%s has nothing left to teach you."
L.ABILITYLEARNED_NO_PET = "No pet out to check."
-- Chat, after the "Simulate a learn" button. %s: the chat line imitated.
L.ABILITYLEARNED_SIMULATING = "Simulating: %s"
L.ABILITYLEARNED_NO_LINE = "This client has no learn message to imitate."
-- Chat, when the simulated ability does not count. %s: its name.
L.ABILITYLEARNED_NOT_WILD = "%s is not a pet ability learned in the wild."
-- For the example toast when the client cannot name Claw rank 2 itself.
L.ABILITYLEARNED_TEST_SPELL = "Claw"
L.ABILITYLEARNED_TEST_RANK = "Rank 2"

-- History, one line per learn after the date. %s: the pet's name.
L.ABILITYLEARNED_HISTORY_FROM = "from %s"
L.ABILITYLEARNED_HISTORY_EMPTY = "Nothing learned on this character yet."

-- Settings page.
L.ABILITYLEARNED_OPTION_SOUND = "Sound"
L.ABILITYLEARNED_OPTION_SOUND_FAMILY = "The call of the pet's family (level-up when it has none)"
L.ABILITYLEARNED_OPTION_SOUND_LEVELUP = "The level-up sound"
L.ABILITYLEARNED_OPTION_SOUND_OFF = "No sound"
L.ABILITYLEARNED_OPTION_SCREENSHOT = "Take a screenshot of each toast"
L.ABILITYLEARNED_OPTION_SCREENSHOT_DESC = "Saved in the game's Screenshots folder."
L.ABILITYLEARNED_OPTION_HINTS = "Say what a new pet can teach"
L.ABILITYLEARNED_OPTION_HINTS_DESC = "When you summon or tame a pet, chat names the abilities it has at a higher rank than you."
L.ABILITYLEARNED_OPTION_POINTS = "Toast when my pet gains training points"
L.ABILITYLEARNED_OPTION_POINTS_DESC = "Counted per pet, so a pet you summon again is told what it gained while it was away."
L.ABILITYLEARNED_OPTION_TEST = "Show a toast"
L.ABILITYLEARNED_OPTION_SIMULATE = "Simulate a learn"
L.ABILITYLEARNED_OPTION_SIMULATE_DESC = "Feeds the game's learn line for one of your pet's abilities through the detection; not kept in the history."
L.ABILITYLEARNED_OPTION_CHECK = "What can my pet teach?"
L.ABILITYLEARNED_OPTION_HISTORY = "Learned on this character, newest first"

-- stylua: ignore end
