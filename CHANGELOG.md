# Changelog

## Unreleased

- The framework: a settings page under AddOns → Kennel with a switch per
  module, a page per module with options, and profiles.
- `/kennel` opens Kennel's window, `/kennel config` the settings page;
  `/kennel help` lists the module commands. The window has a tab per part,
  takes the button skin's look, moves by dragging, and opens from the data
  broker and a key binding too.
- With OAP Debug installed: Kennel's messages, chat lines, counts, the
  window's timings and its Lua errors in OAP Debug's window, as much as the
  "OAP Debug" setting on Kennel's page says.
- Kennel's macros say what they do in the tooltip of the action button they
  are on.
- A toast for every module, in two looks: a small card near the top of the
  screen, or a large splash in the middle. Both have a timer bar; drag to
  move, right-click to close, hover to keep it up. Duration, size and look on
  Kennel's page, and a look per kind of toast. Other addons can add looks.
- Care Button (from Pet Care Button): one key and the KennelCare macro for
  Mend Pet, Revive Pet and Call Pet that remember a dead pet, also once the
  body is gone; toasts when the pet dies, is missing at the pull or runs low;
  a low health marker beside the pet frame that works while the game hides
  the pet's health; the button on screen too, showing what a click casts.
- With EllesmereUI loaded: the card and the splash in EllesmereUI's look;
  with ElvUI loaded, in ElvUI's. A look that shows toasts as the game's raid
  warning.
- A look that sends toasts through LibSink: Blizzard's floating text, chat,
  raid warning, MikSBT and the other outputs LibSink knows.
- With MessageQueue loaded: a LibSink output that says toasts in a chat
  channel (say, party, group, a custom channel); say, yell and channels go out
  on your next key press or click, as WoW: Forever requires.
- Ability Learned (from Pet Ability Learned): a toast, on the splash by
  default, when your hunter learns a pet ability from a tamed beast, with the
  pet's portrait and free training points; a history per character; hints on
  what a summoned pet can still teach, from what Beast Training shows; a toast
  when your pet gains training points, naming the level-up or loyalty level
  behind them, and one when its loyalty drops; a sound choice for each.
- A kind of toast can start on a look its module picks; the pet's portrait on
  the icon; an optional screenshot per toast.
- Feed Emotes (from Feed Pet Emotes, which it replaces): a random /emote
  every time you feed your pet, with your own lines, conditions and the pet's
  sex per pet. Off until switched on. Lines for Forever's foxes in all six
  languages.
- Autocast Check (from Pet Autocast Check): Growl or Cower on autocast as
  fits, Cower in a dungeon group and Growl elsewhere; the KennelKite macro
  (Cower, Distracting Shot) and KennelGrowl macro choose until a dungeon group
  is entered or left. A toast when it does not fit, and one key or the
  KennelAutocast macro that sets it right.
- Feeding: a button beside the pet frame while the pet is not happy, feeding
  the food that keeps it happy cheapest (Well Fed food last), the order in
  its tooltip, a list to pick another food on a right-click; toasts when the
  pet becomes content or unhappy and when the last food it eats is gone.
- Button skins: Kennel's buttons and lists in the look of Masque, ElvUI or
  EllesmereUI, chosen on Kennel's page (Automatic by default). Other addons
  add theirs with Kennel:RegisterButtonSkin and RegisterButtonHolderSkin.
- Data Broker: Kennel as a LibDataBroker source (Titan Panel, ChocolateBar,
  ElvUI datatexts): the pet's name, happiness and free training points, more
  in its tooltip, Kennel's window on a click; and as a minimap button.
- Pet Journal: a page per pet with when and where it was tamed, its level and
  loyalty, the time out together, its deaths, a forecast of the next loyalty
  level and its abilities, stabled pets included, with what each could still
  teach you; the short version in the pet's tooltip. In Kennel's window a
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
  masters of your faction. In Kennel's window an Abilities tab (every rank,
  known or the nearest beast that teaches it) and a Families tab
  (specialization, diet, what each family learns, where to tame one).
- Ability Learned keeps every rank you learned, not only the highest.
- Ability Learned keeps which beast your pet was tamed as with each learn, and
  a button lists the learns from beasts Kennel's beast data does not know as
  teachers.
- Care Button: a toast when combat starts with your pet on Passive.
- For other addons: messages with a table of details, heard through
  Kennel:Listen: KENNEL_TOAST, KENNEL_PRINT, KENNEL_RANKS_KNOWN,
  KENNEL_ABILITY_LEARNED, KENNEL_PET_GROWTH (training points, level and
  loyalty, up or down), KENNEL_AUTOCAST_WANTED, KENNEL_RARE_SEEN, and from the
  core KENNEL_PET_HAPPINESS, KENNEL_PET_DIED and KENNEL_PET_TAMED, which it
  works out only while something listens. Kennel's own modules listen the
  same way. See docs/04-hooking.md, with an example addon, and
  docs/KennelMessages.lua for their types.
