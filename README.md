# Kennel

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

A toast when your pet's Growl or Cower autocast does not fit what you are
doing:

| Mode | Growl | Cower | When |
| --- | --- | --- | --- |
| **Solo** | on | off | by itself, anywhere but a dungeon group |
| **Dungeon** | off | on | by itself, in a dungeon or raid instance while in a group |
| **Kite** | off | on | chosen by you: the mob is on you, not on your pet |
| **Tank** | on | off | chosen by you: your pet tanks for a group without a tank |

A toast shows when something stops fitting (you zone into a dungeon with Growl
on, summon a pet with Cower on, switch to kite mode) and goes away by itself
once you fix it. When combat starts, whatever is still wrong toasts again.
Growl and Cower are seen whether they are on the pet bar or only in the pet's
spellbook. It plays your pet's call (the raid warning for a pet without one),
or nothing.

Kite and tank mode are switched by

- `/kennel autocast kite [on|off]` and `/kennel autocast tank [on|off]`
  (without a word they toggle; pressed again with `on` they say nothing, so
  they fit a macro you press over and over);
- a key binding each, under Esc > Options > Keybindings > AddOns > Kennel;
- three macros Kennel makes for each hunter the first time, in the macro
  window (`/macro`): **KennelKite** casts Distracting Shot and switches kite
  mode on, **KennelKiteOff** switches it off, **KennelTank** switches tank
  mode. Deleted ones stay gone; **Make the macros** on the module's page makes
  them again.

The module's page has the mode, which of Growl and Cower are watched, the
combat reminder, the sound, and a button for an example toast. On other
classes it does nothing.

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
  dead), when **combat starts without a pet**, and when its **health drops**
  to a set line (40% by default, 0 for never). Each kind can have a look of
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

- **Training points**: a toast when your pet gains training points ("Fluffy
  gained 3 training points", and how many are free for Beast Training), on the
  look for every toast. Kennel keeps each pet's total, so a pet you summon
  again is told what it gained while it was away; spending points says
  nothing.
- **Sound**, chosen apart for a learn and for training points: your pet
  family's call (the level-up sound for a family without one), the level-up
  sound, or none. Optionally a **screenshot** of each learn.
- **History**: every learn, per character, with pet, zone and time; on the
  module's page, newest first.
- **Hints**: when you summon or tame a pet, chat says which of its abilities it
  has at a higher rank than you know ("Fluffy can teach you: Claw (Rank 3).").
  Kennel knows your ranks from what it saw you learn and from the **Beast
  Training** window: open that once and the hints are complete.
- The module's page has the sound, screenshot, hints and training points
  switches, an example toast, a
  simulated learn (the game's own chat line through the detection, kept out of
  the history), a "What can my pet teach?" button and the history. On other
  classes it does nothing.

## Technical

### Layout

```
Kennel.toc        loads embeds.xml, then the three folders' xml files
embeds.xml        Ace3, loaded from Libs\ (not in the repository, see below)
Bindings.xml      the key bindings; each runs a /kennel command
Locales\          AceLocale strings: Locales.xml, enUS.lua as the source,
                  the other languages filled in by the packager (README.md there)
Core\Core.xml     the core, in this order:
  Addon.lua       the AceAddon object, KennelDB, the module switches
  Sounds.lua      pet sounds per family (Kennel.sounds.*_PER_FAMILY)
  Pet.lua         spells (name, icon, rank), the pet's spellbook, family, sound
                  and training points
  Toast\          the toast (Toast.xml):
    Skins.lua     the skin register, its contract, which skin draws which kind
    Frame.lua     what every skin's frame does alike; NewToastFrame, NewToastSkin
    Engine.lua    queue, clock, sound, the card taking over from a failing skin
    Skins\        the card and the splash
  Macro.lua       macros a module makes for the player
  Options.lua     the AceConfig options and the pages in the settings window
  Commands.lua    /kennel
Integrations\     what Kennel does with other addons, a folder per addon; each
                  file does nothing unless its addon is loaded (OptionalDeps)
  EllesmereUI\Toast.lua   the card and the splash in EllesmereUI's look
  LibSink\Toast.lua       a look that hands toasts to LibSink's outputs
  MessageQueue\Sink.lua   a LibSink output that says toasts in a chat channel
                          through MessageQueue (Forever sends say, yell and
                          channels only on the player's next input)
Modules\Modules.xml   one Include per module
Modules\<Name>\   a module: <Name>.xml, Locale.lua, <Name>.lua, Options.lua
annotations\      editor-only types (not in the .toc)
tests\            the specs, the simulated client and the tooling (check.lua)
.busted, .luacov  test and coverage settings
kennel-dev-1.rockspec  the pinned test tools (not a rock of Kennel itself)
```

### Modules

A module is a folder under `Modules\` with an `.xml` that loads its files, and
a line in `Modules\Modules.xml`:

```
Modules\PetCare\PetCare.xml   Locale.lua, PetCare.lua, Options.lua, in that order
Modules\PetCare\Locale.lua    its English strings (Locales\README.md)
Modules\PetCare\PetCare.lua   the module
Modules\PetCare\Options.lua   its settings page (GetOptions)
```

Plus a `namespace="PetCare"` keyword line in every `Locales\<lang>.lua`, and
its tests in `tests\<name>_spec.lua`. The module itself:

```lua
local _, Kennel = ...
local L = Kennel.L

---@type KennelPetCare -- a class in annotations\Kennel.lua
local M = Kennel:NewModule("PetCare", "AceTimer-3.0")
M.title = L.PETCARE_TITLE
M.description = L.PETCARE_DESC
M.defaults = { profile = { threshold = 40 } }
M.command = "care"
M.commands = {
    revive = { desc = L.PETCARE_CMD_REVIVE, func = Revive }, -- Revive(module, args)
}

function M:OnEnable()
    self:RegisterEvent("UNIT_HEALTH")
end

function M:OnDisable()
    -- undo everything OnEnable did that AceEvent/AceTimer do not undo themselves
    Kennel:DropToasts(self.moduleName .. ":")
end
```

`Modules\AutocastCheck\` is a complete example. What each field means is in
`annotations/Kennel.lua` (`KennelModule`). The rules the core relies on:

- **The core owns the switch.** `profile.modules[name]` in `KennelDB` says
  whether a module runs; a module never calls `Enable`/`Disable` on itself.
  A module is on unless it sets `enabledByDefault = false`.
- **`OnDisable` undoes `OnEnable`.** A profile change disables every running
  module and enables the ones the new profile has on, so this is also how a
  module sees new settings. Read `self.db.profile` in `OnEnable` (or when
  needed), never keep a copy across a disable.
- **`defaults`** gives the module its own AceDB namespace as `self.db`, set
  before the module's `OnInitialize`.
- **`GetOptions`** returns an AceConfig group. It becomes a page of its own
  under Kennel, greyed out while the module is off. The core sets `type`,
  `disabled`, and `name` when the group has none (the module's `title`).
  `Kennel:Setting(module, key, changed)` gives an option's `get` and `set` for
  `module:Settings()[key]`; `changed` runs after a set while the module is on.
- Every module embeds AceEvent-3.0; anything else it lists in `NewModule`
  and in `embeds.xml` / `.pkgmeta`.

### What the core offers modules

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
  (one screenshot once it has faded in).

### Toast skins

The toast is an engine and a skin. The engine (`Core\Toast\Engine.lua`) keeps
the queue, the clock (intro, stay, fade; the stay stands still while the mouse
is over the toast), the sound and the settings. A skin draws: Kennel brings
`card` and `splash` (`Core\Toast\Skins\`), and another addon can register its own,
either to draw in its own style (an ElvUI look, say) or as an adapter that
hands the toast to something else.

A skin is a table with a localized `name` and four methods
(`KennelToastSkin` in `annotations\Kennel.lua`). The engine calls `Show` once,
`Update` every frame until the fade is done, then `Hide`:

```lua
local Kennel = LibStub("AceAddon-3.0"):GetAddon("Kennel", true)
if Kennel then
    -- A skin drawing in one frame (self.frame): Hide, IsMouseOver and Frame come with it.
    local skin = Kennel:NewToastSkin("My look")
    function skin:Show(info, settings)
        -- info: key, type, source, title, text, hint, icon, accent, portrait; settings: scale, pos, ...
        self.frame = self.frame or Kennel:NewToastFrame("MyAddonToast") -- drags and closes like Kennel's
        -- fill in self.frame from info
        Kennel:PlaceToast(self.frame, "TOP", 0, -150) -- or where the player dragged the toast
        self.frame:Show()
        -- For info.portrait: Kennel:AddToastPortrait(frame, icon, size) once when building,
        -- then Kennel:ShowToastPortrait(frame, info.portrait, accent) here.
    end
    function skin:Update(intro, fade, left) -- each 0 to 1
        self.frame:SetAlpha(intro * (1 - fade))
    end
    Kennel:RegisterToastSkin("mylook", skin)
end
```

An adapter that hands toasts to something else sets `instant = true` and
needs only `name` and `Show`: the engine plays the sound and moves on to the
next toast at once. A skin with settings of its own adds `GetOptions()`,
returning an AceConfig group that appears in the toast box under its id.
`Integrations\LibSink\Toast.lua` is such an adapter: it pours the toast as one
line through LibSink, where the player picks the output (Blizzard's floating
text by default, chat, raid warning, MikSBT, ...).

To restyle the card or the splash rather than draw anew,
`Kennel:NewCardSkin(name, style)` and `Kennel:NewSplashSkin(name, style)` take
a `KennelSkinStyle`: the frame's name, a panel colour, an edge colour or a
`Border(frame)` function, an `accent()` function and a `Font(text, size)`
function. `Integrations\EllesmereUI\Toast.lua` does exactly that with
EllesmereUI's font, border, panel and theme colour, registering "EllesmereUI"
and "EllesmereUI (splash)" only when EllesmereUI is loaded.

The player then picks "My look" on Kennel's page. A saved choice whose skin
is gone (its addon disabled) falls back to the card.

The contract is enforced in the game, not only in the editor types:
`RegisterToastSkin` raises an error naming what is missing (an id, a `name`
string, or one of the four methods) and does not register the skin. When a
registered skin errors while it draws, the error goes to the error handler
(BugSack shows it) and the card takes over that toast, so a broken skin
cannot stop Kennel's toasts. An error in `Hide` only lets the toast go.
- **Macros** (`Core\Macro.lua`): a module with a `Macros()` method returning
  `{ name, icon, body }` entries calls `Kennel:OfferMacros(self)` from
  `OnEnable`. They are made once per character (per character, or
  account-wide when those are full; never in combat; an existing macro of the
  same name is left alone), and `Kennel:CreateMacros(module, true)` makes the
  missing ones again by hand.
- **Pet** (`Core\Pet.lua`, `Core\Sounds.lua`): `Kennel.SpellInfo(id)` (name,
  icon and rank text) across client generations, `Kennel.PetSpells()` (the
  pet's spellbook by name), `Kennel.PetTrainingPoints()` (free and total),
  `Kennel.PetFamilyID()`, `Kennel.PetSound(kind)` (the
  family's `"AGGRO"` call, `"DEATH"` sound or `"WOUND"` cry, from
  `Kennel.sounds.<KIND>_PER_FAMILY`), and `Kennel.Readable(value)` for values
  Forever may hide in combat.
- **Out of combat** (`Core\Combat.lua`): `Kennel:OutOfCombat(key, fn)` runs
  `fn` now, or once combat ends (the last one asked per key). For what the
  client blocks in combat: secure frames, macro edits. It lives on the core
  because a module's own events are dropped when it is switched off.
- **Key bindings**: `Bindings.xml` at the top (the client reads only that
  one); a binding calls a global function that runs a `/kennel` command, so a
  module that is off says so instead of acting. A secure button's binding
  (`CLICK KennelCareButton:LeftButton`) clicks the button itself; a module
  that is off takes the button's macro away.

### Libraries

Ace3 is not committed. `.pkgmeta` lists each library as an external, pinned
to a commit of the Ace3 GitHub mirror (its tags stop in 2010). The packager
fetches them for a release; `tests/libs.lua` reads the same `.pkgmeta` block
and fetches the same commits into `Libs\` before the tests. To move to a
newer Ace3, change the commit in `.pkgmeta` (all entries) and run the tests:
the libraries are fetched again when the block changes.

LibSink-2.0 lives only in CurseForge's svn, so its external is `type: svn`
with a release tag. `tests/libs.lua` needs no svn client for it: the svn
server lists each directory as a page of links and serves each file at its own
address, which curl downloads.

The `.toc` lists Ace3 and LibStub as `OptionalDeps`, so a separately
installed Ace3 loads first and LibStub keeps the newest copy of each library.

### Development

The tests run on Lua 5.1, the version WoW runs, with
[busted](https://lunarmodules.github.io/busted/) and
[luacov](https://lunarmodules.github.io/luacov/). The tool versions are
pinned in `kennel-dev-1.rockspec`.

**Setup on Windows**, once: `tests\setup-lua.ps1` builds Lua 5.1.5 with
Visual Studio's C compiler (needs the C++ build tools and Python), and puts
LuaRocks, the test rocks and StyLua next to it, all inside `.lua\`
(gitignored). Nothing outside the repository changes. On Linux or macOS,
install Lua 5.1 and LuaRocks, then
`luarocks install --only-deps kennel-dev-1.rockspec` and StyLua.

Everything runs through `tests/check.lua`, from the repository root
(`.lua\bin\lua.exe tests\check.lua` on Windows, or `lua tests/check.lua`
after `.lua\bin\activate.ps1`):

- `lua tests/check.lua` runs lint, then the tests with the coverage check.
- `lua tests/check.lua test` fetches `Libs\` if needed and runs the
  `tests/*_spec.lua` files with busted, then prints line coverage of
  Kennel's own files (not `Libs\`). Extra arguments go to busted, such as
  `test --filter=options`. `coverage/lcov.info` is written for editor
  plugins and `coverage/junit.xml` for CI.
- `lua tests/check.lua lint` runs the StyLua format check, then WoW Lua LS
  diagnostics.
- `lua tests/check.lua format` formats all Lua with StyLua.

Both coverages are held at 100%: a full test run fails below 100% line
coverage (a file no test loads counts as 0%), and lint fails below 100% WoW
Lua LS type coverage. A partial run (`test --filter=...`) is not held to
the line coverage.

WoW Lua LS is the binary in the `WOWLUA_LS` environment variable, else the
newest installed copy of the `tradeskillmaster.wowlua-ls` VS Code extension.
Without either, lint skips it with a warning, except under CI, where it
fails. It knows the Ace3 types (`AceModule`, `AceDBObject-3.0`,
`AceConfig.OptionsTable`, ...). To find a symbol it cannot resolve,
`wowlua_ls dump-types --with-stubs .` lists every name with its type.

**How the tests work.** `tests/helper.lua` reads `Kennel.toc` the way the
client does, with every `.xml` in it expanded to the files it loads.
`NewClient()` (`tests/wow.lua`) is a simulated client: it resets the WoW
API globals and loads every file in that order, the real Ace3 included,
into a fresh namespace. A spec creates one per test, so tests never share
state:

```lua
describe("/kennel", function()
    local client
    before_each(function()
        client = NewClient({ modules = function(Kennel) ... end }):login()
    end)

    it("alone opens the options page", function()
        client:slash("")
        assert.are.same({ client.Kennel.optionsCategoryID }, client.opened)
    end)
end)
```

The simulated client keeps what tests read back: frames and their events,
chat lines, settings pages opened, timers (`client:advance(seconds)`), and
errors Ace3 reports through `geterrorhandler` (`client.errors`). Any frame
method it does not define is a no-op, so the Ace3 GUI can draw the options
pages: the options specs open every page in AceConfigDialog and show every
settings page, and fail on any error. It also has WoW's own changes to Lua
5.1 that Ace3 relies on, such as `xpcall` passing its extra arguments on.

busted's spies (`spy.new`, `assert.spy(...).was.called_with(...)`) check
callbacks. AceAddon only calls handlers that are functions, so a spy goes
inside the handler rather than in its place (see `tests/core_spec.lua`).

### CI and releases

`.github/workflows/ci.yml` runs `lua tests/check.lua` on every push and pull
request. Lua 5.1.5 and LuaRocks come from `leafo/gh-actions-lua` and
`leafo/gh-actions-luarocks`, the rocks from the rockspec, StyLua from its
action, and WoW Lua LS from its GitHub release (version and checksum pinned
in the workflow). The JUnit report becomes a "Tests" check on the commit,
with failed tests annotated on the run and on pull requests.

Pushing a tag runs `.github/workflows/release.yml`: the CI job, then
BigWigsMods/packager. The packager builds the zip with Ace3 embedded
(leaving out what `.pkgmeta` lists) and attaches it to a GitHub release. It
uploads to CurseForge and fills in the translations once the `.toc` has an
`## X-Curse-Project-ID` and the repository a `CF_API_KEY` secret. The
release notes are `CHANGELOG.md`; the version is the tag (`@project-version@`
in the `.toc`).

To play with it while working on it, give the client's AddOns folder a git
worktree of its own on a local branch, so the game loads a clean checkout:

```bash
git branch wow main
```

```bash
git worktree add "<WoW>/Interface/AddOns/Kennel" wow
```

`wow` has no upstream and is never pushed. A worktree has no `Libs\`, so
copy it in once (and again after an Ace3 update):

```bash
cp -r Libs "<WoW>/Interface/AddOns/Kennel/"
```

To give the game a newer version, fast-forward it to `main`, then `/reload`:

```bash
git -C "<WoW>/Interface/AddOns/Kennel" merge --ff-only main
```

## License

MIT, see `LICENSE`.
