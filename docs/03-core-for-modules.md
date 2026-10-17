# What the core offers modules

- **Toast** (`Core\Toast\`): `Kennel:ShowToast(info)` with a key, kind,
  source, title, text, hint, icon, accent colour and sound
  (`KennelToastInfo`). One toast per key is up or waiting; toasts for
  different keys show one after the other. Keys are `"<Module>:<what>"`:
  `Kennel:DropToast(key)` takes one away when it is solved,
  `Kennel:DropToasts("<Module>:")` all of a module's when it is switched off.
  A module lists its kinds of toast in `toastTypes` (`{ problem = L.X }`) and
  sets `type = "<Module>:problem"` on each toast, so the player can give that
  kind a look of its own; `toastSkins` (`{ problem = "splash" }`) gives a kind
  the look it starts on. Duration, size, position and looks are core
  settings. A toast can also bring `portrait` (a unit such as `"pet"`, drawn
  as a round badge on the icon while the unit exists) and `screenshot = true`
  (one screenshot once it has faded in). How it is drawn:
  [05-toast-skins.md](05-toast-skins.md).
- **Macros** (`Core\Macro.lua`): a module with a `Macros()` method returning
  `{ name, icon, body, desc }` entries calls `Kennel:OfferMacros(self)` from
  `OnEnable`. They are made once per character (per character, or
  account-wide when those are full; never in combat; an existing macro of the
  same name is left alone), and `Kennel:CreateMacros(module, true)` makes the
  missing ones again by hand. `desc` says what the macro does: it shows under
  the tooltip of an action button holding the macro, while its module is on.
  Macro bodies use `/use` rather than `/cast` (the same for a spell, and
  shorter, leaving the player more of the 255 characters).
- **Pet** (`Core\Pet.lua`, `Core\Sounds.lua`): `Kennel.SpellInfo(id)` (name,
  icon and rank text) across client generations, `Kennel.PetSpells()` (the
  pet's spellbook by name), `Kennel.PetTrainingPoints()` (free and total),
  `Kennel.PetFamilyID()`, `Kennel.PetSound(kind)` (the
  family's `"AGGRO"` call, `"DEATH"` sound or `"WOUND"` cry, from
  `Kennel.sounds.<KIND>_PER_FAMILY`), `Kennel.CreatureName(npcID)` (a
  creature's name in the client's language, through a creature link's
  tooltip; nil until the client has it, kept once it does), and
  `Kennel.Readable(value)` for values Forever may hide in combat.
- **Chat on input** (`Core\Chat.lua`): `Kennel:SendOnInput(text, kind)` sends
  on the player's next key press or click, as WoW: Forever requires for an
  addon's chat (through MessageQueue when it is loaded). One message waits at
  a time, for at most ten seconds. `Kennel.PetNumber()` (`Core\Pet.lua`) gives
  the pet's stable number, for settings kept per pet.
- **Out of combat** (`Core\Combat.lua`): `Kennel:OutOfCombat(key, fn)` runs
  `fn` now, or once combat ends (the last one asked per key). For what the
  client blocks in combat: secure frames, macro edits. It lives on the core
  because a module's own events are dropped when it is switched off.
- **Key bindings**: `Bindings.xml` at the top (the client reads only that
  one). A binding clicks a module's secure button itself
  (`CLICK KennelCareButton:LeftButton`); a module that is off takes the
  button's macro away, so the key does nothing.
- **Beast data** (`Data\Beasts.lua`): `Kennel.data.petAbilityRanks` (per rank
  spell: ability, rank, pet level, families, teaching beasts) and
  `Kennel.data.beasts` (per NPC ID: name, family, levels, rare/elite, pins per
  uiMapID or the zone of an instance). Generated; `KennelData` in
  `annotations/Kennel.lua`.
- **Messages**: the core and the modules tell other addons what happens
  through AceEvent messages: [04-hooking.md](04-hooking.md).
