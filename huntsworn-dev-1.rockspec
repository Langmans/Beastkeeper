-- Development dependencies only: the test tools, pinned. Huntsworn itself is not a rock.
-- `luarocks install --only-deps huntsworn-dev-1.rockspec` installs them, locally
-- (tests/setup-lua.ps1) and in CI alike.
rockspec_format = "3.0"
package = "huntsworn"
version = "dev-1"
source = { url = "git+https://github.com/Langmans/Huntsworn.git" }
description = { summary = "Huntsworn's test tooling", license = "MIT" }
dependencies = {
    "lua ~> 5.1",
    "busted == 2.2.0",
    "luacov == 0.17.0",
    "luacov-reporter-lcov == 0.2",
    -- luacov's line hook in C: the covered test run takes seconds instead of minutes.
    "cluacov == 1.0.0",
}
build = { type = "builtin", modules = {} }
