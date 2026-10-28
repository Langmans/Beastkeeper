-- Ammo's English strings: the "Ammo" namespace on the CurseForge translation page (see
-- Locales\README.md). Ammo, vendor and zone names come from the client or the data.
local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip. EllesmereUI and Titan Panel are addon names.
L.AMMO_TITLE = "Ammo"
L.AMMO_DESC = "Your ammo count in data broker displays (EllesmereUI's data bars, Titan Panel), orange when low and red when critically low, with a toast at each; a click shows the way to the nearest ammo vendor, and at a vendor it buys ammo for your ammo bag."

-- The data broker display: its label, and its text without a bow, gun or crossbow, or while the module is off.
L.AMMO_LABEL = "Ammo"
L.AMMO_NO_WEAPON = "No bow or gun"
L.AMMO_OFF = "Off"

-- Its tooltip. First %s: the ammo's name; %d: how many. Then the nearest vendor (%s: AMMO_PLACE), or that none is known.
L.AMMO_COUNT = "%s: %d"
L.AMMO_NEAREST = "Nearest ammo vendor: %s"
-- The vendor and where. First %s: its name; second: its zone.
L.AMMO_PLACE = "%s in %s"
-- After AMMO_NEAREST when a route addon knows the travel time. %d: minutes.
L.AMMO_TRAVEL = " (~%d min)"
L.AMMO_NO_VENDOR = "No ammo vendor known."
L.AMMO_CLICK = "Click: the way to it. Right-click: settings."

-- The toasts. %d: how many are left.
L.AMMO_LOW = "Ammo low: %d left"
L.AMMO_CRITICAL = "Ammo critically low: %d left"
L.AMMO_TOAST_TEXT = "Click the ammo counter for the nearest ammo vendor."
-- How long the ammo lasts at this fight's pace (else the last fight's, else one Auto Shot per weapon
-- swing): in the toast before AMMO_TOAST_TEXT
-- (%s: AMMO_MINUTES or AMMO_SECONDS), and after the tooltip's count (AMMO_LASTS).
L.AMMO_ENOUGH = "Enough for %s of Auto Shot."
L.AMMO_LASTS = " (%s of Auto Shot)"
L.AMMO_MINUTES = "~%d min"
L.AMMO_SECONDS = "~%d s"
-- Beastkeeper's page: the kinds of toast, for a look of their own.
L.AMMO_TOASTTYPE_LOW = "Ammo low"
L.AMMO_TOASTTYPE_CRITICAL = "Ammo critically low"

-- Chat, after buying at a vendor. %d: how many; %s: the ammo.
L.AMMO_BOUGHT = "Bought %d %s."

-- The module's page.
L.AMMO_OPTION_LOW = "Low below"
L.AMMO_OPTION_LOW_DESC = "The count turns orange, with a toast, below this many."
L.AMMO_OPTION_CRITICAL = "Critically low below"
L.AMMO_OPTION_CRITICAL_DESC = "The count turns red, with a toast, below this many."
L.AMMO_OPTION_TOASTS = "Toast when ammo gets low"
L.AMMO_OPTION_BUY = "Buy ammo at a vendor"
L.AMMO_OPTION_BUY_DESC = "At a vendor that sells your kind of ammo, buy the best for your level: enough to fill your quiver or ammo pouch, or the stacks below without one."
L.AMMO_OPTION_STACKS = "Stacks without an ammo bag"
L.AMMO_OPTION_STACKS_DESC = "How many stacks of 200 to keep when you carry no quiver or ammo pouch."

-- stylua: ignore end
