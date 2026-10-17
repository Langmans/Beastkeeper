-- BeastMap's English strings: the "BeastMap" namespace on the CurseForge translation page (see
-- Locales\README.md). Beast names come from the data in English; ability names and ranks come
-- from the client.
local L = LibStub("AceLocale-3.0"):NewLocale("Kennel", "enUS", true)

-- One string per line, however long: see Locales\README.md.
-- stylua: ignore start

-- Settings window: the module's switch and page title, and its tooltip. The title also names the
-- plugin in HandyNotes' list.
L.BEASTMAP_TITLE = "Beast Map"
L.BEASTMAP_DESC = "With HandyNotes: a pin on the world map and the minimap for every beast that can teach your hunter a pet ability rank, with the ability's icon. Hover a pin for the beast's level and the ranks it teaches."

-- The module's page when HandyNotes is not loaded.
L.BEASTMAP_NO_HANDYNOTES = "Beast Map shows its pins through the HandyNotes addon, which is not loaded."

-- Settings: the pins at all, and the round button in the world map's top-right corner that switches them.
L.BEASTMAP_OPTION_PINS = "Show the pins"
L.BEASTMAP_OPTION_PINS_DESC = "On the world map and the minimap. The button on the world map switches this too."
L.BEASTMAP_OPTION_BUTTON = "Button on the world map"
L.BEASTMAP_OPTION_BUTTON_DESC = "A round button in the map's top-right corner that shows or hides the pins."
-- The map button's tooltip, under BEASTMAP_TITLE.
L.BEASTMAP_PINS_SHOWN = "Pins shown. Click to hide them."
L.BEASTMAP_PINS_HIDDEN = "Pins hidden. Click to show them."

-- Settings: which beasts get a pin.
L.BEASTMAP_OPTION_USEFUL = "Only beasts that teach a rank I lack"
L.BEASTMAP_OPTION_USEFUL_DESC = "Leave out a beast whose ranks you know already, or know a higher rank of. What you know comes from Ability Learned: your learns, and Beast Training once you have opened it."
L.BEASTMAP_OPTION_GAPS = "Also a missing lower rank"
L.BEASTMAP_OPTION_GAPS_DESC = "Count a rank below your highest that you never learned (Claw 2 when you know Claw 1, 3 and 4): a lower rank suits a young pet and costs fewer training points."
L.BEASTMAP_OPTION_ABOVE = "Also beasts above my level"
L.BEASTMAP_OPTION_ABOVE_DESC = "A hunter can only tame a beast up to its own level. Turn this on to see the ones for later too."

-- Settings: the level-up toast.
L.BEASTMAP_OPTION_TOAST = "Toast at a level-up"
L.BEASTMAP_OPTION_TOAST_DESC = "When a new level brings a beast in reach that teaches a rank you lack, and no lower beast taught it, say which rank and where. Works without HandyNotes."

-- Settings: the lines on a beast's tooltip.
L.BEASTMAP_OPTION_TOOLTIP = "Say on a beast's tooltip what it teaches"
L.BEASTMAP_OPTION_TOOLTIP_DESC = "Hover a beast: a line per pet ability rank it teaches, green when you lack it, yellow for a lower rank you never learned, grey when you know it. Works without HandyNotes."

-- A beast's tooltip, a line per rank it teaches. First %s: the ability with its rank, such as
-- "Claw (Rank 3)"; second: one of the three endings below.
L.BEASTMAP_TOOLTIP_TEACHES = "Teaches %s: %s"
L.BEASTMAP_TOOLTIP_NEW = "new for you"
L.BEASTMAP_TOOLTIP_GAP = "below your highest, never learned"
L.BEASTMAP_TOOLTIP_KNOWN = "you know it"

-- Settings: pins for the hunter's other NPCs.
L.BEASTMAP_OPTION_TRAINERS = "Pet trainers"
L.BEASTMAP_OPTION_TRAINERS_DESC = "A pin for every pet trainer of your faction, where your pet learns the abilities beasts do not teach."
L.BEASTMAP_OPTION_STABLES = "Stable masters"
L.BEASTMAP_OPTION_STABLES_DESC = "A pin for every stable master of your faction."
-- Their pins' tooltips, under the NPC's name.
L.BEASTMAP_PET_TRAINER = "Pet Trainer"
L.BEASTMAP_STABLE_MASTER = "Stable Master"

-- Settings: the rare alarm.
L.BEASTMAP_OPTION_RARE = "Toast when a rare beast I could learn from is near"
L.BEASTMAP_OPTION_RARE_DESC = "Once per spawn, when a rare beast that teaches a rank you lack shows on the minimap, as a nameplate, as your target or under the mouse. Follows the choices above (lower ranks, beasts above your level). Works without HandyNotes."

-- Settings window, Kennel's page: the kind of toast, for choosing its look. Shown after "Beast Map: ".
L.BEASTMAP_TOASTTYPE_REACH = "pet ability rank in reach"
L.BEASTMAP_TOASTTYPE_RARE = "rare beast nearby"

-- Rare alarm toast. Title, %s: the beast's name. Text, a line per rank; %s: the ability with its rank.
L.BEASTMAP_RARE_TOAST = "Rare beast nearby: %s"
L.BEASTMAP_RARE_TEACHES = "Teaches %s"

-- Toast title for one rank. %s: the ability with its rank, such as "Claw (Rank 3)".
L.BEASTMAP_REACH_ONE = "Now in reach: %s"
-- Toast text under it. %s: the beast and its place, BEASTMAP_REACH_PLACE, or the beast alone.
L.BEASTMAP_REACH_TEACHES = "%s teaches it."
-- Toast title for several ranks. %d: how many.
L.BEASTMAP_REACH_MANY = "%d pet ability ranks now in reach"
-- Toast text, one line per rank. First %s: the ability with its rank; second: the beast and place.
L.BEASTMAP_REACH_LINE = "%s: %s"
-- A beast and where it lives. First %s: the beast's name (English); second: the zone or instance.
L.BEASTMAP_REACH_PLACE = "%s in %s"

-- Pin tooltip, under the beast's name. %s: its level or level range, such as "5-6".
L.BEASTMAP_LEVEL = "Level %s"
-- Tooltip of a dungeon entrance's pin, under the instance's name: a line per beast inside, its ranks
-- under it. First %s: the beast's name; second: BEASTMAP_LEVEL with the rare/elite addition.
L.BEASTMAP_INSIDE = "%s: %s"
-- Pin tooltip, last line, in grey.
L.BEASTMAP_CLICK = "Click to go there."
-- Added after the level for a rare, elite or rare elite beast.
L.BEASTMAP_RARE = ", rare"
L.BEASTMAP_ELITE = ", elite"
L.BEASTMAP_RARE_ELITE = ", rare elite"

-- stylua: ignore end
