# Kennel

[![CI](https://github.com/Langmans/Kennel/actions/workflows/ci.yml/badge.svg)](https://github.com/Langmans/Kennel/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Langmans/Kennel?include_prereleases)](https://github.com/Langmans/Kennel/releases)
![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
![WoW: Forever](https://img.shields.io/badge/WoW-Forever%20%2816001%29-c79c6e)
![Ace3](https://img.shields.io/badge/Ace3-yes-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow)](https://github.com/Langmans/Kennel/blob/main/LICENSE)

Hunter pet tools in one addon. Each tool is a module that can be turned on or
off on its own, in the game's settings window under **AddOns → Kennel**.

Kennel is being put together from separate addons by the same author; the
modules move in one at a time.

## Use

- `/kennel` opens the settings page: a switch per module, and the toast's
  settings. Each module with settings has a page of its own below it.
- `/kennel help` lists the commands the modules offer. Commands exist for what
  a macro needs; everything else is on the settings page.
- **Profiles** (a page under Kennel): every character uses the `Default`
  profile until you pick another. The module switches are part of the
  profile, so a profile can, for instance, turn a module off on one character
  only.
- **The toast**: modules tell you things with a toast. Drag it to move it,
  right-click to close it, hover over it to keep it up. On Kennel's page you
  choose how long it stays, how big it is, and its look: a small **card** near
  the top, or a large **splash** in the middle. Every kind of toast (such as
  Autocast Check's) can have a look of its own; other addons can add looks.
  With EllesmereUI loaded, both also come in EllesmereUI's look (its font,
  border and theme colour).

### Autocast Check

Growl or Cower on autocast, as fits what you are doing:

| When | Growl | Cower |
| --- | --- | --- |
| In a dungeon or raid group: the tank holds the mobs | off | on |
| Anywhere else: your pet holds the mobs | on | off |
| You pressed **KennelKite** (kiting: the mob is on you) | off | on |
| You pressed **KennelGrowl** (stop kiting, or your pet tanks the group) | on | off |

Your choice holds until you enter or leave a dungeon group. A toast shows when
something stops fitting (you zone into a dungeon with Growl on, summon a pet
with Cower on) and goes away by itself once it fits again. When combat starts,
whatever is still wrong toasts again. Growl and Cower are seen whether they are
on the pet bar or only in the pet's spellbook. It plays your pet's call (the
raid warning for a pet without one), or nothing.

The game lets only a macro or a button you press change autocast, so:

- **One key sets it right**: Esc > Options > Keybindings > AddOns > Kennel >
  "Autocast Check: set Growl and Cower as fits", or the **KennelAutocast**
  macro. The toast says which to press.
- **KennelKite** puts Cower on and Growl off, and casts Distracting Shot.
- **KennelGrowl** puts Growl on and Cower off.

Kennel makes the three macros for each hunter the first time (`/macro`).
Deleted ones stay gone; **Make the macros** on the module's page makes them
again. The page also has which of Growl and Cower are watched, the combat
reminder, the sound, and a button for an example toast. On other classes it
does nothing.

### Care Button

One key for your pet: **Mend Pet** while it lives, **Revive Pet** when it is
dead, **Call Pet** when it is not out. The usual macro for this,
`/cast [mod:shift][@pet,dead] Revive Pet; [@pet,nodead] Mend Pet; Call Pet`,
has one hole: once a dead pet's body is gone, the game no longer sees a dead
pet and the macro picks Call Pet. The button remembers that the pet died, in
combat too and across a relog, and casts Revive Pet until the pet lives again.
Shift still forces Revive Pet and Ctrl Call Pet.

- Press it with the key binding (Esc > Options > Keybindings > AddOns >
  Kennel > "Care Button: mend, revive or call pet"), or with the **KennelCare**
  macro Kennel makes for each hunter the first time. The macro's cast line
  follows the button (outside combat); lines you add to it stay.
- It also learns from failed casts: Call Pet failing (or "Your pet is dead")
  means the pet is dead; Revive Pet failing at once means there is none to
  revive. In combat the button cannot switch: the toast says to hold Shift,
  and it switches when combat ends.
- Toasts when your pet **dies** (and again at the pull while it is still
  dead), when **combat starts without a pet** or **with your pet on Passive**
  (it will not attack; the toast goes once you change its stance), and when
  its **health drops** to a set line (40% by default, 0 for never). Each kind can have a look of
  its own on Kennel's page; each goes away once solved. They play your pet's
  own death sound, wound cry or attack call, the raid warning, or nothing.
- The module's page has those switches, the sound, buttons to tell the button
  your pet is dead or alive when it guessed wrong, an example toast and the
  macro. Switched off, the key and the macro do nothing.

### Ability Learned

A toast when your hunter learns a pet ability from a tamed beast (Claw rank 2
from a Nightstalker, say): the ability and its rank, the pet that taught it
with its portrait on the icon, and that pet's free training points. It starts
on the splash look. Only abilities learned in the wild count: Bite, Charge,
Claw, Cower, Dash, Demoralizing Screech, Dive, Furious Howl, Lightning Breath,
Prowl, Scorpid Poison, Shell Shield, Thunderstomp, and Forever's Dismember,
Dust Cloud, Mine!, Pinch, Savage Rend, Sonic Blast, Swipe, Tendon Rip and Web.
What a pet trainer sells, and anything learned while a trainer window is open,
does not.

- **Training points**: a toast when your pet gains training points, naming
  why: "Fluffy reached level 16" or "Fluffy now has loyalty level 5
  (Faithful)", with the points gained and how many are free for Beast
  Training; "Fluffy gained 19 training points" when both happened, or while
  it was away. Kennel keeps each pet's points, level and loyalty, so a pet you
  summon again is told what changed. Spending points says nothing, and so does
  a level-up at loyalty level 1, which brings none.
- **Loyalty**: a toast when your pet's loyalty level drops, with the new level
  and the training points that cost. The loyalty name is coloured from
  friendly green (level 1) to exalted teal (level 6).
- The points and loyalty toasts use the look for every toast, and each has
  its own sound choice.
- **Sound**, chosen apart for a learn, training points and loyalty: your pet's
  own (its call; its wound cry when loyalty drops; the level-up sound for a
  family without one), the level-up sound, or none. Optionally a **screenshot** of each learn.
- **History**: every learn, per character, with pet, zone and time; on the
  module's page, newest first. A learn from your pet also keeps the beast it
  was tamed as, and a button lists the learns whose beast Kennel's beast data
  does not have as a teacher yet: tell us, and Beast Map shows them too.
- **Hints**: when you summon or tame a pet, chat says which of its abilities it
  has at a higher rank than you know ("Fluffy can teach you: Claw (Rank 3).").
  Kennel knows your ranks from what it saw you learn and from the **Beast
  Training** window: open that once and the hints are complete.
- The module's page has the sounds, the screenshot, and the hints, training
  points and loyalty switches, an example toast, a
  simulated learn (the game's own chat line through the detection, kept out of
  the history), a "What can my pet teach?" button and the history. On other
  classes it does nothing.

### Feed Emotes

A random `/emote` every time you feed your pet, the way Feed-O-Matic did in
2008: "Langmans feeds Fluffy some Mystery Meat. Tastes like well-aged gnome."
**Off until you switch it on**: others in range see the emotes.

- It works with any way of feeding (Feed Pet: Forever's button, a macro, the
  spellbook and a click on food, dragging food onto the pet) and names the
  food as a clickable item link.
- Lines fit the pet and the food: some for every pet, for males or females,
  for the kind of food and for each of the 17 tameable families; in English
  and German the opening sentence varies too, and now and then the whole
  emote is a small scene. English, German, Spanish, French, Korean and
  Russian lines; other languages get the English ones.
- The emote goes out on your next key press or click, as WoW: Forever only
  lets an addon send chat then; with the MessageQueue addon, any input counts.
- WoW: Forever does not tell a hunter pet's sex: pick it on the module's page
  (kept per pet, through renames and stable swaps), or tick "Always use the
  pet's name".
- Your own lines, on the module's page: placeholders `{pet}`, `{food}` and the
  language's own (`{he}`, `{boy}`, `{his}` in English), conditions in front
  (`[cat,fish] Good hunter!`, or the boxes above the new line), a chance of an
  own line, a fallback when none fits, and one list shared by all characters
  if you want. An example button prints an emote only to you.

### Feeding

A button beside your pet's portrait, there while your pet is not happy: click
it to feed the next food from your bags.

- **The order**, in its tooltip: food that gives the most happiness first
  (food far below your pet's level gives less, or nothing, and is left out),
  then the lowest level, so the better food lasts; then the smallest stack.
  Food that also makes you Well Fed comes last. What your pet eats, the game
  says itself.
- **Right-click** for a list of all that food: click a row to feed that one
  instead (bags full: feed what you carry least of).
- The border shows the happiness: yellow content, red unhappy. Shift-drag to
  move the button; the page puts it back. It takes the look of Masque, ElvUI
  or EllesmereUI when one is loaded (choose under Buttons on Kennel's page),
  and sits beside EllesmereUI's pet frame.
- **Toasts** when your pet becomes content or unhappy, with the food that is
  next, and when the last food it eats leaves your bags. Each has a switch.

### Beast Map

With [HandyNotes](https://www.curseforge.com/wow/addons/handynotes): a pin on
the world map and the minimap for every beast that can teach your hunter a pet
ability rank, with that ability's icon. Hover a pin for the beast's level
(rare, elite) and the ranks it teaches, green for the ones you lack; click it
to go there, through the route or waypoint addon you have (Shortest Path
Forever, Move Fast, TomTom, the game's own map pin, or a map pin link in chat).

- By default only beasts you can tame now (at most your level) that teach a
  rank above the highest you know. What you know comes from Ability Learned:
  the learns it saw and the Beast Training window, so open that once.
- Switches on the module's page, also under HandyNotes' plugins: a missing
  lower rank too (Claw 2 when you know Claw 1, 3 and 4: it suits a young pet
  and costs fewer points), every beast in reach whatever it teaches, beasts
  above your level.
- **A round button** in the world map's top-right corner shows or hides the
  pins (greyed while they are off). The button itself can be switched off on
  the page.
- **At a level-up**, also without HandyNotes: a toast when the new level
  brings a beast in reach that teaches a rank you lack and no lower beast
  taught ("Now in reach: Charge (Rank 1)", "Cave Boar in Wailing Caverns
  teaches it"), several ranks in one toast. It has its own switch.
- 106 ranks and 423 beasts, from Wowhead's WoW: Forever database and the
  Tamed addon's list (MIT, notice in `Data/Tamed-LICENSE.txt`), kept only
  where Wowhead has the beast as tameable on Forever. Beast names come from
  your game, in its language, once it knows the beast; English before that.
  Beasts in a dungeon share one pin at its entrance; hover it for which
  beasts are inside.

## For developers

How Kennel is built, how to add to it, and how other addons can hook into it:

1. [Layout](https://github.com/Langmans/Kennel/blob/main/docs/01-layout.md):
   what each file and folder is.
2. [Modules](https://github.com/Langmans/Kennel/blob/main/docs/02-modules.md):
   writing a module, and the rules the core relies on.
3. [What the core offers modules](https://github.com/Langmans/Kennel/blob/main/docs/03-core-for-modules.md):
   toast, macros, pet helpers, chat, combat, key bindings, the beast data.
4. [Hooking into Kennel](https://github.com/Langmans/Kennel/blob/main/docs/04-hooking.md):
   the AceEvent messages other addons can listen to, with an example addon
   and [their types](https://github.com/Langmans/Kennel/blob/main/docs/KennelMessages.lua)
   for a language server.
5. [Toast skins](https://github.com/Langmans/Kennel/blob/main/docs/05-toast-skins.md):
   drawing Kennel's toast in your own look.
6. [Libraries](https://github.com/Langmans/Kennel/blob/main/docs/06-libraries.md):
   Ace3, LibSink and LibGoThere, pinned through `.pkgmeta`.
7. [Development](https://github.com/Langmans/Kennel/blob/main/docs/07-development.md):
   tests, lint, coverage, and screenshots while testing in game.
8. [CI and releases](https://github.com/Langmans/Kennel/blob/main/docs/08-ci-and-releases.md):
   the workflows, the packager, and playing the repository's copy.
9. [Button skins](https://github.com/Langmans/Kennel/blob/main/docs/09-button-skins.md):
   Kennel's buttons and lists in your own look; Masque, ElvUI, EllesmereUI.

## License

MIT, see [LICENSE](https://github.com/Langmans/Kennel/blob/main/LICENSE).
