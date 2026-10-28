# CI and releases

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

## Playing the repository's copy

To play with it while working on it, give the client's AddOns folder a git
worktree of its own on a local branch, so the game loads a clean checkout:

```bash
git branch wow main
```

```bash
git worktree add "<WoW>/Interface/AddOns/Beastkeeper" wow
```

`wow` has no upstream and is never pushed. A worktree has no `Libs\`, so
copy it in once (and again after an Ace3 update):

```bash
cp -r Libs "<WoW>/Interface/AddOns/Beastkeeper/"
```

To give the game a newer version, fast-forward it to `main`, then `/reload`:

```bash
git -C "<WoW>/Interface/AddOns/Beastkeeper" merge --ff-only main
```
