# Layout

```
Beastkeeper_<Client>.toc  one per client, the same files but for the client's own Data\ folder:
                  _Vanilla (Classic Era, Data\Era), _Forever (WoW: Forever,
                  Data\Forever), _TBC, _Mists and _Mainline (retail) without
                  data; Beastkeeper.toc for any other client. Each loads embeds.xml,
                  then the folders' xml files and its data
embeds.xml        Ace3, loaded from Libs\ (not in the repository, see 06-libraries.md)
Bindings.xml      the key bindings; each clicks a module's secure button
Locales\          AceLocale strings: Locales.xml, enUS.lua as the source,
                  the other languages filled in by the packager (README.md there)
Core\Core.xml     the core, in this order:
  Addon.lua       the AceAddon object, BeastkeeperDB, the module switches, Print,
                  Beastkeeper.data's empty tables
  Constants\      names for the game's bare values (Enums.lua) and the pet
                  families with their specialization and diet (Families.lua)
  Compat.lua      Beastkeeper.C: the modern pet, spellbook and tooltip API on every
                  client (the classic way where the client lacks it)
  Families.lua    a family's ID, name and specialization
  Features.lua    what the client's game has (happiness, ammo, beast training,
                  beast data); a module's `requires` keeps it off without it
  Sounds.lua      pet sounds per family (Beastkeeper.sounds.*_PER_FAMILY)
  Pet.lua         spells (name, icon, rank), the pet's spellbook, family, sound,
                  training points and stable number, on every client
  World.lua       places in the world, to measure across zone borders
  Tooltip.lua     lines in unit tooltips, the same way on every client
  Combat.lua      what waits for combat to end
  Chat.lua        chat sent on the player's next key press or click
  Toast\          the toast (Toast.xml):
    Skins.lua     the skin register, its contract, which skin draws which kind
    Frame.lua     what every skin's frame does alike; NewToastFrame, NewToastSkin
    Engine.lua    queue, clock, sound, the card taking over from a failing skin
    Skins\        the card, the splash and the raid warning
  Buttons.lua     button and holder skins: register, choice, Beastkeeper's own
  Macro.lua       macros a module makes for the player
  Options.lua     the AceConfig options and the pages in the settings window
  Commands.lua    /beastkeeper
Data\<Client>\    generated, per client (Forever, Era); the pet ability ranks, the
                  beasts that teach them and (Era, TBC) each food's kind are
                  LibTameable-1.0's (Libs\), each .toc loading its client's file:
  Trainers.lua    pet trainers and stable masters, with faction and spots
  Ammo.lua        arrows and bullets, and the vendors that sell them
Integrations\     what Beastkeeper does with other addons, a folder per addon; each
                  file does nothing unless its addon is loaded (OptionalDeps)
  EllesmereUI\Look.lua    the card, the splash, button and holder skins in
                          EllesmereUI's look
  ElvUI\Look.lua          the card, the splash, button and holder skins in
                          ElvUI's look
  Masque\Button.lua       a button skin putting Beastkeeper's buttons in Masque
  LibSink\Toast.lua       a look that hands toasts to LibSink's outputs
  MessageQueue\Sink.lua   a LibSink output that says toasts in a chat channel
                          through MessageQueue (Forever sends say, yell and
                          channels only on the player's next input)
Modules\Modules.xml   one Include per module
Modules\<Name>\   a module: <Name>.xml, Locale.lua, <Name>.lua, Options.lua
                  (FeedEmotes adds Lines\<locale>.lua: its emote lines with
                  each language's grammar, kept out of the translation page;
                  DevScreenshots is one --@debug@ block, absent from releases)
docs\             this documentation, and BeastkeeperMessages.lua: the types of the
                  messages for other addons (shipped, never loaded in game)
annotations\      editor-only types (not in the .toc, not in releases)
tests\            the specs, the simulated client and the tooling (check.lua)
.busted, .luacov  test and coverage settings
beastkeeper-dev-1.rockspec  the pinned test tools (not a rock of Beastkeeper itself)
```
