-- CareButton's English strings: the "CareButton" namespace on the CurseForge translation page (see
-- Locales\README.md). Mend Pet, Revive Pet and Call Pet are hunter spells: translate them as the
-- game does in your language. KennelCare is a macro name and stays as it is.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip.
L.CAREBUTTON_TITLE = "Care Button"
L.CAREBUTTON_DESC = "One key for your pet: Mend Pet while it lives, Revive Pet when it is dead (also once the body is gone), Call Pet when it is not out. And a toast when your pet dies, is missing at the pull or runs low."

-- Settings window, Kennel's page: the kinds of toast, for choosing their look. Shown after "Care Button: ".
L.CAREBUTTON_TOASTTYPE_DEAD = "pet died"
L.CAREBUTTON_TOASTTYPE_NOPET = "no pet at the pull"
L.CAREBUTTON_TOASTTYPE_LOW = "low health"
L.CAREBUTTON_TOASTTYPE_PASSIVE = "pet on Passive at the pull"

-- Toast titles. %d: the pet's health in percent.
L.CAREBUTTON_TOAST_DEAD = "Your pet is dead"
L.CAREBUTTON_TOAST_NOPET = "You have no pet out"
L.CAREBUTTON_TOAST_LOW = "Your pet is at %d%% health"
-- Passive, Defensive and Aggressive: the pet's stances, as the pet bar names them.
L.CAREBUTTON_TOAST_PASSIVE = "Your pet is on Passive"
-- Toast text: what the button does now.
L.CAREBUTTON_REASON_DEAD = "The button casts Revive Pet now, also once the body is gone."
L.CAREBUTTON_REASON_NOPET = "Combat started without your pet."
L.CAREBUTTON_REASON_LOW = "The button casts Mend Pet while your pet lives."
L.CAREBUTTON_REASON_PASSIVE = "It will not attack: set it to Defensive or Aggressive on the pet bar."
-- Toast text when a failed Call Pet showed the pet is dead; in combat the button cannot change, so Shift forces Revive Pet.
L.CAREBUTTON_REASON_LEARNED = "Call Pet failed: the button casts Revive Pet now."
L.CAREBUTTON_REASON_LEARNED_COMBAT = "Call Pet failed. In combat the button cannot switch: hold Shift for Revive Pet."
-- Toast hint: how to press the button. %s: its key binding, such as "F".
L.CAREBUTTON_HINT_KEY = "Press %s."
L.CAREBUTTON_HINT_MACRO = "Press your KennelCare macro."

-- Chat, after Revive Pet failed at once: there was no dead pet.
L.CAREBUTTON_REVIVE_FAILED = "Revive Pet failed, so there is no dead pet: the button casts Call Pet again."
-- Chat, after a button on the settings page that cannot work in combat.
L.CAREBUTTON_IN_COMBAT = "Not in combat; try again when it ends."

-- The tooltip of an action button holding the KennelCare macro: what it does.
L.CAREBUTTON_MACRO = "Kennel: Mend Pet while your pet lives, Revive Pet when it is dead (also once the body is gone), Call Pet when it is not out. Shift: Revive Pet. Ctrl: Call Pet."

-- Esc > Options > Keybindings > AddOns > Kennel.
L.CAREBUTTON_BINDING = "Care Button: mend, revive or call pet"

-- Settings page.
L.CAREBUTTON_OPTION_DIED = "Toast when my pet dies"
L.CAREBUTTON_OPTION_DIED_DESC = "Also when a failed Call Pet shows that it is dead, and again at the pull."
L.CAREBUTTON_OPTION_NOPET = "Toast when combat starts without a pet"
L.CAREBUTTON_OPTION_PASSIVE = "Toast when combat starts with my pet on Passive"
-- Slider: the pet health in percent at which the low toast shows; 0 switches it off.
L.CAREBUTTON_OPTION_LOW = "Toast at this pet health (0: never)"
L.CAREBUTTON_OPTION_MARKER = "Mark low health beside the pet frame"
L.CAREBUTTON_OPTION_MARKER_DESC = "Mend Pet's icon lights up left of your pet's portrait while its health is below the line above. WoW: Forever may hide your pet's health in combat, so the toast cannot tell then; the marker still can."
L.CAREBUTTON_OPTION_SOUND = "Sound"
L.CAREBUTTON_OPTION_SOUND_FAMILY = "Your pet's own: death sound, wound cry, attack call (raid warning when it has none)"
L.CAREBUTTON_OPTION_SOUND_WARNING = "The raid warning"
L.CAREBUTTON_OPTION_SOUND_OFF = "No sound"
-- Buttons that tell the button by hand whether the pet is dead, for when it guessed wrong.
L.CAREBUTTON_OPTION_DEAD = "My pet is dead"
L.CAREBUTTON_OPTION_DEAD_DESC = "Without a pet, the button casts Revive Pet."
L.CAREBUTTON_OPTION_ALIVE = "My pet is alive"
L.CAREBUTTON_OPTION_ALIVE_DESC = "Without a pet, the button casts Call Pet."
L.CAREBUTTON_OPTION_TEST = "Show a toast"
L.CAREBUTTON_OPTION_MACRO = "Make the macro"
L.CAREBUTTON_OPTION_MACRO_DESC = "Makes the KennelCare macro again: it casts what the button casts, for an action bar."

-- stylua: ignore end
