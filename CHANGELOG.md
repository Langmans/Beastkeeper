# Changelog

## Unreleased

- Renamed from Kennel to Beastkeeper (a 2008 addon already has the name on
  CurseForge). The slash command is /beastkeeper, or /bk; the macros, the
  messages (BEASTKEEPER_TOAST, ...) and the saved settings (BeastkeeperDB)
  carry the new name.

### Clients

- WoW: Forever and Classic Era (Season of Discovery, Hardcore too), each with
  its own data: the beasts that teach pet abilities, pet trainers, ammo
  vendors, and on Classic Era each food's kind. Burning Crusade, Mists of
  Pandaria Classic and retail load too, with the modules their game has.
- The beasts that teach pet abilities come from LibTameable-1.0, for Classic
  Era, Burning Crusade and WoW: Forever; Burning Crusade gets Beast Map and
  its families (Dragonhawk, Ravager, Warp Stalker, Sporebat, Nether Ray,
  Serpent). Each client loads only its own beast data.
- What a pet eats on Classic Era and Burning Crusade comes from LibTameable
  too, each family's diet from the client's own tables.

### Beastkeeper itself

- A settings page under AddOns → Beastkeeper with a switch per module, a page per
  module with options, and profiles.
- `/beastkeeper` opens Beastkeeper's window, `/beastkeeper config` the settings page;
  `/beastkeeper help` lists the module commands. The window has a tab per part,
  takes the button skin's look, moves by dragging, and opens from the data
  broker and a key binding too.
- Beastkeeper's macros say what they do in the tooltip of the action button they
  are on.

### Toasts

- A toast for every module, in two looks: a small card near the top of the
  screen, or a large splash in the middle. Both have a timer bar; drag to
  move, right-click to close, hover to keep it up. Duration, size and look on
  Beastkeeper's page, and a look per kind of toast. Other addons can add looks.
- A kind of toast can start on a look its module picks; the pet's portrait on
  the icon; an optional screenshot per toast.
- A look that shows toasts as the game's raid warning, and one that sends
  them through LibSink: Blizzard's floating text, chat, raid warning, MikSBT
  and the other outputs LibSink knows.

### Modules

- Care Button (from Pet Care Button): one key and the BeastkeeperCare macro for
  Mend Pet, Revive Pet and Call Pet that remember a dead pet, also once the
  body is gone; toasts when the pet dies, is missing at the pull or runs low,
  or combat starts with it on Passive; a low health marker beside the pet
  frame that works while the game hides the pet's health; the button on
  screen too, showing what a click casts.
- Ability Learned (from Pet Ability Learned): a toast, on the splash by
  default, when your hunter learns a pet ability from a tamed beast, with the
  pet's portrait and free training points; a history per character of every
  rank learned and the beast it came from, with a list of learns from beasts
  Beastkeeper's data does not know as teachers; hints on what a summoned pet can
  still teach, from what Beast Training shows; a toast when your pet gains
  training points, naming the level-up or loyalty level behind them, and one
  when its loyalty drops; a sound choice for each.
- Feed Emotes (from Feed Pet Emotes, which it replaces): a random /emote
  every time you feed your pet, with your own lines, conditions and the pet's
  sex per pet. Off until switched on. Lines for Forever's foxes in all six
  languages.
- Autocast Check (from Pet Autocast Check): Growl or Cower on autocast as
  fits, Cower in a dungeon group and Growl elsewhere; the BeastkeeperKite macro
  (Cower, Distracting Shot) and BeastkeeperGrowl macro choose until a dungeon group
  is entered or left. A toast when it does not fit, and one key or the
  BeastkeeperAutocast macro that sets it right.
- Feeding: a button beside the pet frame while the pet is not happy, feeding
  the food that keeps it happy cheapest (Well Fed food last), the order in
  its tooltip, a list to pick another food on a right-click; toasts when the
  pet becomes content or unhappy and when the last food it eats is gone.
- Data Broker: Beastkeeper as a LibDataBroker source (Titan Panel, ChocolateBar,
  ElvUI datatexts): the pet's name, happiness and free training points, more
  in its tooltip, Beastkeeper's window on a click; and as a minimap button.
- Pet Journal: a page per pet with when and where it was tamed, its level and
  loyalty, the time out together, its deaths, a forecast of the next loyalty
  level and its abilities, stabled pets included, with what each could still
  teach you; the short version in the pet's tooltip. In Beastkeeper's window a
  Pets tab with a card per pet: its model, specialization, journal and
  abilities, and a Stable tab with every pet side by side. Stabled pets'
  models and names come from the stable master.
- Beast Map: with HandyNotes, a pin for every beast your hunter can tame now
  that teaches a pet ability rank you lack, with the ability's icon and a
  tooltip of the ranks it teaches; switches for missing lower ranks, every
  beast in reach and beasts above your level. At a level-up, also without
  HandyNotes, a toast for the ranks a beast of the new level brings in reach.
  A click on a pin takes you there, through LibGoThere-1.0: Shortest Path
  Forever, Move Fast, TomTom, the game's map pin or a pin link. Beast names
  in your game's language once it knows the beast. A button on the world map
  shows or hides the pins. Beasts in a dungeon get a pin at its entrance. A
  beast's tooltip says which ranks it teaches and whether you lack them. A
  toast when a rare beast that teaches a rank you lack comes in sight, and a
  tame key that targets and marks that beast (or the one whose pin you
  clicked), Shift for Tame Beast. Pins for the pet trainers and stable
  masters of your faction. In Beastkeeper's window an Abilities tab (every rank,
  known or the nearest beast that teaches it) and a Families tab
  (specialization, diet, what each family learns, where to tame one).
- Ammo: your ammo count as a data broker source (EllesmereUI's data bars,
  Titan Panel), orange when low and red when critically low with a toast at
  each, both saying how long the ammo lasts at the pace of your fight; a click
  shows the way to the nearest ammo vendor of your faction for
  your kind of ammo; at a vendor it buys the best ammo for your level to fill
  your quiver or ammo pouch.

### Other addons

- Button skins: Beastkeeper's buttons and lists in the look of Masque, ElvUI or
  EllesmereUI, chosen on Beastkeeper's page (Automatic by default). Other addons
  add theirs with Beastkeeper:RegisterButtonSkin and RegisterButtonHolderSkin.
- With EllesmereUI loaded: the card and the splash in EllesmereUI's look;
  with ElvUI loaded, in ElvUI's.
- With MessageQueue loaded: a LibSink output that says toasts in a chat
  channel (say, party, group, a custom channel); say, yell and channels go out
  on your next key press or click, as WoW: Forever requires.
- With OAP Debug installed: Beastkeeper's messages, chat lines, counts, the
  window's timings and its Lua errors in OAP Debug's window; with DebugLog
  installed, the messages and chat lines in a Beastkeeper tab, sorted into
  categories. As much as the "Debug" setting on Beastkeeper's page says.
- With LS: Toasts loaded: a toast look that hands Beastkeeper's toasts to it.
- Care Button: Alt-click opens Beast Training while the pet has training
  points to spend; the tooltip says how many.
- Data Broker: a middle-click opens the window on the pet abilities.
- Ammo: "Count only the ammo in the ammo slot" (on by default); switched off,
  it counts every kind of ammo your weapon shoots and your level allows. The
  low-ammo toast names the ammo it counts ("Rough Arrow low: 400 left").
- Beast Training is read on Classic Era and Burning Crusade too (the craft
  window), and its training point costs are kept: the pet's journal says what
  its free points can buy ("Can buy with 43 free points: Bite rank 2 (10)").
- Beast Map: during a hunt the tame key shows as a button on screen: a click
  targets and marks the beast, Shift-click casts Tame Beast; Shift-drag moves it.
- Abilities tab: a quest giver's "!" on an ability with a rank you can learn
  now (from a beast at or below your level); its tooltip names the rank you
  know and those to learn.
- Pets tab: the pets you no longer have (released, or lost) under a Past pets
  heading; the Stable tab shows only the pets you have.
- An About page in the settings: title, notes, version, author, license and
  website (LibAboutPanel-2.0).
- Messages with a table of details, heard through Beastkeeper:Listen:
  BEASTKEEPER_TOAST, BEASTKEEPER_PRINT, BEASTKEEPER_RANKS_KNOWN, BEASTKEEPER_ABILITY_LEARNED,
  BEASTKEEPER_AUTOCAST_WANTED, BEASTKEEPER_RARE_SEEN, BEASTKEEPER_AMMO, and from the core
  BEASTKEEPER_PET_HAPPINESS, BEASTKEEPER_PET_DIED, BEASTKEEPER_PET_TAMED and
  BEASTKEEPER_PET_GROWTH (training points, level and loyalty, up or down), which
  it works out only while something listens. Beastkeeper's own modules listen the
  same way. See docs/04-hooking.md, with an example addon, and
  docs/AddonMessages.lua for their types.
