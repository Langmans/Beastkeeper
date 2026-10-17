-- Feeding's English strings: the "Feeding" namespace on the CurseForge translation page (see
-- Locales\README.md). Feed Pet is the hunter spell and Well Fed the buff: translate them as the
-- game does in your language. Food names come from the client.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip.
L.FEEDING_TITLE = "Feeding"
L.FEEDING_DESC = "A button beside your pet's portrait that feeds it the next food from your bags: the cheapest that still makes it happy, Well Fed food last. Its tooltip shows the order. And a toast when your pet is no longer happy, or when your bags run out of food it eats."

-- Settings window, Kennel's page: the kind of toast, for choosing its look. Shown after "Feeding: ".
L.FEEDING_TOASTTYPE_CONTENT = "pet content"
L.FEEDING_TOASTTYPE_UNHAPPY = "pet unhappy"
L.FEEDING_TOASTTYPE_NOFOOD = "no food left"

-- The pet's happiness, as the game names its three levels.
L.FEEDING_HAPPY = "Happy"
L.FEEDING_CONTENT = "Content"
L.FEEDING_UNHAPPY = "Unhappy"

-- Button tooltip. Title, %s: the pet's name.
L.FEEDING_TOOLTIP = "Feed %s"
-- One line per food. %s: its name; %d: how many you carry.
L.FEEDING_FOOD = "%s x%d"
-- Added after a food that also makes the hunter Well Fed, which is fed last.
L.FEEDING_WELL_FED = " (makes you Well Fed: last)"
-- Instead of the food lines. %s: the pet's name.
L.FEEDING_NO_FOOD = "Nothing in your bags that %s eats."
L.FEEDING_CLICK = "Click to feed the first. Shift-drag to move."

-- Toast titles. %s: the pet's name.
L.FEEDING_TOAST_CONTENT = "%s is content"
L.FEEDING_TOAST_UNHAPPY = "%s is unhappy"
L.FEEDING_TOAST_NOFOOD = "Nothing for %s to eat"
-- Toast texts.
L.FEEDING_REASON_CONTENT = "Feed it: a happy pet does 125% damage."
L.FEEDING_REASON_UNHAPPY = "It does 75% damage, and its loyalty drops."
L.FEEDING_REASON_NOFOOD = "Your bags hold no food it eats. Buy some before you go."
-- Toast hint: the food the button feeds next. %s: its name.
L.FEEDING_NEXT = "Next: %s"
L.FEEDING_HINT_NO_FOOD = "Your bags hold nothing it eats."

-- Settings page.
L.FEEDING_OPTION_CONTENT = "Toast when my pet is content"
L.FEEDING_OPTION_UNHAPPY = "Toast when my pet is unhappy"
L.FEEDING_OPTION_NOFOOD = "Toast when the last food it eats is gone"
L.FEEDING_OPTION_RESET = "Put the button back beside the pet"

-- stylua: ignore end
