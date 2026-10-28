# Development

## Screenshots while testing in game

`Modules\DevScreenshots`: in a copy straight from the repository there is a
module "Dev Screenshots", off until switched on. On, each kind of toast (once
faded in) and each Beastkeeper chat line (numbers ignored, at most one every two
seconds) gets one screenshot in the game's `Screenshots` folder, the first
time it shows, after a grey `[Beastkeeper dev] ...` chat line saying what it was
for. What has a screenshot is kept across sessions; a button on its page
forgets it. It listens to `BEASTKEEPER_TOAST` and `BEASTKEEPER_PRINT` like any addon
could ([04-hooking.md](04-hooking.md)). The whole file is a `--@debug@` block,
which the packager comments out of every release; the specs load the files
the same way unless a client asks for `dev`.

## Facts from the client while playing

`Modules\DevProbe`, also a `--@debug@` module, off until switched on, keeps
in BeastkeeperDB (`BeastkeeperDB.namespaces.DevProbe.global`) what the API
documentation does not tell, for reading the SavedVariables back after
playing:

- `stable`: C_StableInfo's entry of each pet, every field the lists give.
- `petSpells`: each spell or rank a pet gets, with the rank before, its level
  and family, and how (`level` right after a level-up, `training` with the
  trainer window open, else `other`).
- `foods`: C_PetInfo.GetPetFoodTypes per family; `families`: the client's
  family names by ID.
- `lowerRanks`: a rank learned below the highest the hunter knew.
- `guids`: the pet's GUID at UNIT_PET and LOCALPLAYER_PET_RENAMED.

Each list keeps its last 200; a button on its page empties them. Each finding
also goes to OAP Debug and DebugLog through `Beastkeeper:Log`.

## Tests

The tests run on Lua 5.1, the version WoW runs, with
[busted](https://lunarmodules.github.io/busted/) and
[luacov](https://lunarmodules.github.io/luacov/). The tool versions are
pinned in `beastkeeper-dev-1.rockspec`.

**Setup on Windows**, once: `tests\setup-lua.ps1` builds Lua 5.1.5 with
Visual Studio's C compiler (needs the C++ build tools and Python), and puts
LuaRocks, the test rocks and StyLua next to it, all inside `.lua\`
(gitignored). Nothing outside the repository changes. On Linux or macOS,
install Lua 5.1 and LuaRocks, then
`luarocks install --only-deps beastkeeper-dev-1.rockspec` and StyLua.

Everything runs through `tests/check.lua`, from the repository root
(`.lua\bin\lua.exe tests\check.lua` on Windows, or `lua tests/check.lua`
after `.lua\bin\activate.ps1`):

- `lua tests/check.lua` runs lint, then the tests with the coverage check.
- `lua tests/check.lua test` fetches `Libs\` if needed and runs the
  `tests/*_spec.lua` files with busted, then prints line coverage of
  Beastkeeper's own files (not `Libs\`). Extra arguments go to busted, such as
  `test --filter=options`. `coverage/lcov.info` is written for editor
  plugins and `coverage/junit.xml` for CI, and `coverage/index.html`, every
  file with its lines marked hit or missed, where luacov's HTML reporter can
  find its files through LuaRocks' loader (in CI; a local setup without it
  skips the HTML). Each CI run has them as its "coverage" artifact.
- `lua tests/check.lua lint` runs the StyLua format check, then WoW Lua LS
  diagnostics.
- `lua tests/check.lua format` formats all Lua with StyLua.

Both coverages are held at 100%: a full test run fails below 100% line
coverage (a file no test loads counts as 0%), and lint fails below 100% WoW
Lua LS type coverage. A partial run (`test --filter=...`) is not held to
the line coverage.

The full covered run takes seconds rather than minutes:

- luacov's line hook runs in C (cluacov, pinned in the rockspec) instead of
  Lua, which on its own made a covered run dozens of times slower than a
  plain one;
- the spec files are split by size over up to eight busted processes at
  once (one per processor on a machine with fewer), each with its own luacov
  stats file and JUnit report; `check.lua` sums the stats, merges the
  reports and the counts, and prints each process's failures;
- a partial run (`test --filter=...`) stays one process, its output
  straight to the terminal.

`TEST_WORKERS` sets the number of processes (`TEST_WORKERS=1` runs
everything in one process). The default of eight comes from this table:
`check.lua test` on a 20-processor machine, three runs each:

| Processes | Seconds |
|---|---|
| 1 | 9.4 |
| 2 | 5.9 |
| 3 | 5.5 |
| 4 | 4.5 |
| 6 | 4.0 |
| 8 | 3.5 |
| 12 | 3.7 |
| 16 | 3.6 |
| 20 | 3.5 |

No spec file sets the pace: the slowest on its own (`abilitylearned_spec`,
`carebutton_spec`, `beastmap_spec`) takes about 1.1 s including busted's
start. What stays is about a second outside the tests (the lcov report
0.55 s, the HTML attempt 0.2 s, merging the stats), and each process's own
start of about 0.35 s, which past eight costs more than splitting further
saves.

With cluacov, luacov lists a file under its Windows path as well
(`Core\Addon.lua`, no hits) next to the record the tests produced
(`Core/Addon.lua`); the coverage report merges the two by name, a line hit
when either hit it.

WoW Lua LS is the binary in the `WOWLUA_LS` environment variable, else the
newest installed copy of the `tradeskillmaster.wowlua-ls` VS Code extension.
Without either, lint skips it with a warning, except under CI, where it
fails. It knows the Ace3 types (`AceModule`, `AceDBObject-3.0`,
`AceConfig.OptionsTable`, ...). To find a symbol it cannot resolve,
`wowlua_ls dump-types --with-stubs .` lists every name with its type.

## How the tests work

`tests/helper.lua` reads `Beastkeeper_Forever.toc` (and `Beastkeeper_Vanilla.toc` for
`NewClient({ era = true })`, a simulated Classic Era) the way the client does,
with every `.xml` in it expanded to the files it loads. `NewClient()`
(`tests/wow.lua`) is a simulated client: it resets the WoW API globals and loads
every file in that order, the real Ace3 included, into a fresh namespace. Each file is
compiled once per run and, unless the client asks for `dev`, has its
`--@debug@` blocks commented out as in a release. A spec creates one client
per test, so tests never share state:

```lua
describe("/beastkeeper", function()
    local client
    before_each(function()
        client = NewClient({ modules = function(Beastkeeper) ... end }):login()
    end)

    it("config opens the options page", function()
        client:slash("config")
        assert.are.same({ client.Beastkeeper.optionsCategoryID }, client.opened)
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
