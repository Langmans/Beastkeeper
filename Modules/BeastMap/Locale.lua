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

-- Settings: which beasts get a pin.
L.BEASTMAP_OPTION_USEFUL = "Only beasts that teach a rank I lack"
L.BEASTMAP_OPTION_USEFUL_DESC = "Leave out a beast whose ranks you know already, or know a higher rank of. What you know comes from Ability Learned: your learns, and Beast Training once you have opened it."
L.BEASTMAP_OPTION_GAPS = "Also a missing lower rank"
L.BEASTMAP_OPTION_GAPS_DESC = "Count a rank below your highest that you never learned (Claw 2 when you know Claw 1, 3 and 4): a lower rank suits a young pet and costs fewer training points."
L.BEASTMAP_OPTION_ABOVE = "Also beasts above my level"
L.BEASTMAP_OPTION_ABOVE_DESC = "A hunter can only tame a beast up to its own level. Turn this on to see the ones for later too."

-- Pin tooltip, under the beast's name. %s: its level or level range, such as "5-6".
L.BEASTMAP_LEVEL = "Level %s"
-- Added after the level for a rare, elite or rare elite beast.
L.BEASTMAP_RARE = ", rare"
L.BEASTMAP_ELITE = ", elite"
L.BEASTMAP_RARE_ELITE = ", rare elite"

-- stylua: ignore end
