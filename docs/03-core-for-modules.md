# What the core offers modules

- **One API on every client** (`Core\Compat.lua`): `Beastkeeper.C.PetInfo`,
  `Beastkeeper.C.SpellBook` and `Beastkeeper.C.TooltipInfo` have the modern names and
  returns (`GetPetHappiness`, `CanPetEatItem`, `GetSpellBookItemInfo`,
  `GetItemByID`, ...). Each calls the client's own `C_` function where it has
  one, else the classic way: Classic Era's globals, a hidden tooltip read
  line by line, the pet family's diet. Call these, never `C_PetInfo` and the
  like directly; `Beastkeeper.C.Has("PetInfo", name)` says whether a part exists.
  Beastkeeper never writes into the game's own `C_` tables.
- **Items the client has not loaded**: `Beastkeeper.WhenItemLoaded(itemID, fn)`
  runs `fn` now when the client has the item's data, else once it has loaded
  it (`Item:ContinueOnItemLoad`, on every client). Use it before showing an
  item's name or judging it by its level.
- **What the game has** (`Core\Features.lua`): `Beastkeeper.features` (happiness,
  ammo, beast training, beast data). A module that needs one names it in
  `requires`; without it, it stays off and off the settings page.
- **Toast** (`Core\Toast\`): `Beastkeeper:ShowToast(info)` with a key, kind,
  source, title, text, hint, icon, accent colour and sound
  (`BeastkeeperToastInfo`). One toast per key is up or waiting; toasts for
  different keys show one after the other. Keys are `"<Module>:<what>"`:
  `Beastkeeper:DropToast(key)` takes one away when it is solved,
  `Beastkeeper:DropToasts("<Module>:")` all of a module's when it is switched off.
  A module lists its kinds of toast in `toastTypes` (`{ problem = L.X }`) and
  sets `type = "<Module>:problem"` on each toast, so the player can give that
  kind a look of its own; `toastSkins` (`{ problem = "splash" }`) gives a kind
  the look it starts on. Duration, size, position and looks are core
  settings. A toast can also bring `portrait` (a unit such as `"pet"`, drawn
  as a round badge on the icon while the unit exists) and `screenshot = true`
  (one screenshot once it has faded in). How it is drawn:
  [05-toast-skins.md](05-toast-skins.md).
- **Buttons**: `Beastkeeper:StyleButton` and `Beastkeeper:StyleButtonHolder` give a
  button or a list the chosen skin's look; see
  [09-button-skins.md](09-button-skins.md).
- **Window** (`Core\Window.lua`): `Beastkeeper:RegisterWindowTab({ id, title,
  order, module, Create, Refresh })` adds a tab to Beastkeeper's window, shown
  while `module` is on. `Create(panel, skin)` builds the panel once (use the
  holder skin's `Font`); `Refresh(panel)` fills it each time it shows. A
  module whose data changed calls `Beastkeeper:RefreshWindow(id)`.
  `Beastkeeper:OpenWindow(id)` and `ToggleWindow(id)` open it; without any tab
  they open the options.
- **OAP Debug and DebugLog** (`Core\Debug.lua`, the only file that talks to
  them; each one installed gets the lines): `Beastkeeper:Log(kind, msg, ...)`
  ("error", "warn", "info", "debug"; values fill `{1}`, `{2}`; OAP Debug makes
  tables links, DebugLog gets them written out; start the message with a word
  and a colon, `"probe: ..."`, for DebugLog's category column),
  `Beastkeeper:Count(name)` and `Beastkeeper:Time(name, fn, ...)` (OAP Debug only). Each
  is one comparison when the level leaves it out, and nothing without either
  addon. Beastkeeper's own BEASTKEEPER_* messages and chat lines go there already; log
  what a message does not show.
- **Macros** (`Core\Macro.lua`): a module with a `Macros()` method returning
  `{ name, icon, body, desc }` entries calls `Beastkeeper:OfferMacros(self)` from
  `OnEnable`. They are made once per character (per character, or
  account-wide when those are full; never in combat; an existing macro of the
  same name is left alone), and `Beastkeeper:CreateMacros(module, true)` makes the
  missing ones again by hand. `desc` says what the macro does: it shows under
  the tooltip of an action button holding the macro, while its module is on.
  Macro bodies use `/use` rather than `/cast` (the same for a spell, and
  shorter, leaving the player more of the 255 characters).
- **Pet** (`Core\Pet.lua`, `Core\Sounds.lua`): `Beastkeeper.SpellInfo(id)` (name,
  icon and rank text) across client generations, `Beastkeeper.PetSpells()` (the
  pet's spellbook by name), `Beastkeeper.PetTrainingPoints()` (free and total),
  `Beastkeeper.PetFamilyID()`, `Beastkeeper.PetSound(kind)` (the
  family's `"AGGRO"` call, `"DEATH"` sound or `"WOUND"` cry, from
  `Beastkeeper.sounds.<KIND>_PER_FAMILY`), `Beastkeeper.CreatureName(npcID)` (a
  creature's name in the client's language, through a creature link's
  tooltip; nil until the client has it, kept once it does), and
  `Beastkeeper.Readable(value)` for values Forever may hide in combat.
- **Chat on input** (`Core\Chat.lua`): `Beastkeeper:SendOnInput(text, kind)` sends
  on the player's next key press or click, as WoW: Forever requires for an
  addon's chat (through MessageQueue when it is loaded). One message waits at
  a time, for at most ten seconds. `Beastkeeper.PetNumber()` (`Core\Pet.lua`) gives
  the pet's stable number, for settings kept per pet.
- **Out of combat** (`Core\Combat.lua`): `Beastkeeper:OutOfCombat(key, fn)` runs
  `fn` now, or once combat ends (the last one asked per key). For what the
  client blocks in combat: secure frames, macro edits. It lives on the core
  because a module's own events are dropped when it is switched off.
- **Key bindings**: `Bindings.xml` at the top (the client reads only that
  one). A binding clicks a module's secure button itself
  (`CLICK BeastkeeperCareButton:LeftButton`); a module that is off takes the
  button's macro away, so the key does nothing.
- **Beast data** (LibTameable-1.0, in `Libs\`): `Beastkeeper.data.petAbilityRanks`
  (per rank spell: ability, rank, pet level, families, teaching beasts) and
  `Beastkeeper.data.beasts` (per NPC ID: name, family, levels, rare/elite, pins per
  uiMapID or the zone of an instance) are the library's own tables: read them,
  never change them. Its API (`GetTeachers` with only rares or only the rest,
  `GetTeaches`, `GetAbilityRanks`, ...) is in its README; `BeastkeeperData` in
  `annotations/Beastkeeper.lua`.
- **Messages**: the core and the modules tell each other and other addons
  what happens through BEASTKEEPER_* messages ([04-hooking.md](04-hooking.md)). A
  module listens with `Beastkeeper:Listen(self, message, method)` in OnEnable and
  `Beastkeeper:StopListening(self)` in OnDisable; that is also what starts and stops
  the core's sources (pet happiness, death, tame, growth). A new module sends a
  message where another addon may want to hook in, whether or not its toast
  for that moment is on.
