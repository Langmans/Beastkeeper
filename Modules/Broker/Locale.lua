-- Broker's English strings: the "Broker" namespace on the CurseForge translation page (see
-- Locales\README.md). Pet, family and loyalty names come from the client.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip. Titan Panel, ChocolateBar and ElvUI are addon names.
L.BROKER_TITLE = "Data Broker"
L.BROKER_DESC = "Kennel in Titan Panel, ChocolateBar, ElvUI's datatexts and other data broker displays: your pet's name, happiness and free training points, more when you hover, Kennel's settings on a click."

-- The text in a display. First %s: the pet's name; second: its happiness (Happy, Content, Unhappy); %d: its free training points.
L.BROKER_TEXT = "%s: %s, %d TP"
-- Without a pet's happiness or points: the name alone.
L.BROKER_NO_PET = "No pet out"
L.BROKER_OFF = "Off"

-- Tooltip. %s: the pet's name; %d: its level; second %s: its family (Cat).
L.BROKER_PET = "%s, level %d %s"
-- %s: the loyalty level, such as "4 (Dependable)".
L.BROKER_LOYALTY = "Loyalty %s"
-- First %d: free training points; second: the pet's total.
L.BROKER_POINTS = "%d of %d training points free"
L.BROKER_CLICK = "Click: Kennel's window. Right-click: settings."

-- stylua: ignore end
