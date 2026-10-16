# Kennel

Hunter pet tools in one addon. Each tool is a module that can be turned on or
off on its own, in the game's settings window under **AddOns → Kennel**.

Kennel is being put together from separate addons by the same author; the
modules move in one at a time. This version is the framework: the settings
page with a switch per module, profiles, and the `/kennel` command.

## Use

- `/kennel` opens the settings page.
- `/kennel help` lists the commands the modules offer. Commands exist for what
  a macro needs; everything else is on the settings page.
- **Profiles** (a page under Kennel): every character uses the `Default`
  profile until you pick another. The module switches are part of the
  profile, so a profile can, for instance, turn a module off on one character
  only.

## Technical

### Layout

```
Kennel.toc
embeds.xml        Ace3, loaded from Libs\ (not in the repository, see below)
Locales\          AceLocale strings; enUS.lua is the source, see Locales\README.md
Core\Addon.lua    the AceAddon object, KennelDB, the module switches
Core\Options.lua  the AceConfig options and the pages in the settings window
Core\Commands.lua /kennel
annotations\      editor-only types (not in the .toc)
tests\            the specs, the simulated client and the tooling (check.lua)
.busted, .luacov  test and coverage settings
kennel-dev-1.rockspec  the pinned test tools (not a rock of Kennel itself)
```

### Modules

A module is an AceAddon module of Kennel, in its own file after the core in
the `.toc`:

```lua
local _, Kennel = ...
local L = Kennel.L

---@class KennelPetCare: KennelModule
local M = Kennel:NewModule("PetCare", "AceTimer-3.0")
M.title = L.PETCARE_TITLE
M.description = L.PETCARE_DESC
M.defaults = { profile = { threshold = 40 } }
M.command = "care"
M.commands = {
    revive = { desc = L.PETCARE_REVIVE_DESC, func = function(self, args) end },
}

function M:GetOptions()
    return { args = { ... } } -- an AceConfig group
end

function M:OnEnable()
    self:RegisterEvent("UNIT_HEALTH")
end

function M:OnDisable()
    -- undo everything OnEnable did that AceEvent/AceTimer do not undo themselves
end
```

What each field means is in `annotations/Kennel.lua` (`KennelModule`). The
rules the core relies on:

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
- Every module embeds AceEvent-3.0; anything else it lists in `NewModule`
  and in `embeds.xml` / `.pkgmeta`.

### Libraries

Ace3 is not committed. `.pkgmeta` lists each library as an external, pinned
to a commit of the Ace3 GitHub mirror (its tags stop in 2010). The packager
fetches them for a release; `tests/libs.lua` reads the same `.pkgmeta` block
and fetches the same commits into `Libs\` before the tests. To move to a
newer Ace3, change the commit in `.pkgmeta` (all entries) and run the tests:
the libraries are fetched again when the block changes.

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
