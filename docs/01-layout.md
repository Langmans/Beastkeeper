# Layout

```
Kennel.toc        loads embeds.xml, then the folders' xml files and Data\Beasts.lua
embeds.xml        Ace3, loaded from Libs\ (not in the repository, see 06-libraries.md)
Bindings.xml      the key bindings; each clicks a module's secure button
Locales\          AceLocale strings: Locales.xml, enUS.lua as the source,
                  the other languages filled in by the packager (README.md there)
Core\Core.xml     the core, in this order:
  Addon.lua       the AceAddon object, KennelDB, the module switches, Print
  Sounds.lua      pet sounds per family (Kennel.sounds.*_PER_FAMILY)
  Pet.lua         spells (name, icon, rank), the pet's spellbook, family, sound,
                  training points and stable number
  Combat.lua      what waits for combat to end
  Chat.lua        chat sent on the player's next key press or click
  Toast\          the toast (Toast.xml):
    Skins.lua     the skin register, its contract, which skin draws which kind
    Frame.lua     what every skin's frame does alike; NewToastFrame, NewToastSkin
    Engine.lua    queue, clock, sound, the card taking over from a failing skin
    Skins\        the card and the splash
  Buttons.lua     button and holder skins: register, choice, Kennel's own
  Macro.lua       macros a module makes for the player
  Options.lua     the AceConfig options and the pages in the settings window
  Commands.lua    /kennel
Data\Beasts.lua   generated: pet ability ranks and the beasts that teach them
                  (Tamed-LICENSE.txt next to it for the part from Tamed)
Integrations\     what Kennel does with other addons, a folder per addon; each
                  file does nothing unless its addon is loaded (OptionalDeps)
  EllesmereUI\Look.lua    the card, the splash, button and holder skins in
                          EllesmereUI's look
  ElvUI\Look.lua          the card, the splash, button and holder skins in
                          ElvUI's look
  Masque\Button.lua       a button skin putting Kennel's buttons in Masque
  LibSink\Toast.lua       a look that hands toasts to LibSink's outputs
  MessageQueue\Sink.lua   a LibSink output that says toasts in a chat channel
                          through MessageQueue (Forever sends say, yell and
                          channels only on the player's next input)
Modules\Modules.xml   one Include per module
Modules\<Name>\   a module: <Name>.xml, Locale.lua, <Name>.lua, Options.lua
                  (FeedEmotes adds Lines\<locale>.lua: its emote lines with
                  each language's grammar, kept out of the translation page;
                  DevScreenshots is one --@debug@ block, absent from releases)
docs\             this documentation, and KennelMessages.lua: the types of the
                  messages for other addons (shipped, never loaded in game)
annotations\      editor-only types (not in the .toc, not in releases)
tests\            the specs, the simulated client and the tooling (check.lua)
.busted, .luacov  test and coverage settings
kennel-dev-1.rockspec  the pinned test tools (not a rock of Kennel itself)
```
