# Renaming the addon

Every name the game and other addons see is made from the addon's folder name,
`Beastkeeper.NAME` (`Core\Addon.lua`):

- the saved variables (`<NAME>DB`), frame and macro names (`Beastkeeper.Global`);
- the slash command (`/<name>` in lower case, plus `SLASH_ALIAS`);
- the messages (`Beastkeeper.messages`, `<NAME>_TOAST` and so on);
- the locale, the binding header, Masque's group, the data broker objects,
  LibGoThere's owner, LibSink's sink and LS: Toasts' key.

`tests\names_spec.lua` loads the addon as "Tester" and checks that all of these
follow.

## What cannot follow the folder

These must be changed by hand to the new name:

- the folder itself, and the repository's name;
- every `.toc`: its file name, `## Title`, `## SavedVariables: <NAME>DB`;
- `Bindings.xml`: the `header` (`<NAME>` in upper case) and every
  `CLICK <NAME>...Button` (`names_spec` checks both against `NAME`).

## The code's own names

The code does not carry the name: the addon object is `Addon` (`local Addon =
ns`), its types are `Addon...` (`AddonModule`, `AddonBeastMap`), the files
are `annotations\Addon.lua` and `docs\AddonMessages.lua`. Only what a player
or the game sees carries it: the texts (locales, README, docs), the `.toc`s,
`Bindings.xml`, the repository's name and the rockspec. Rename those with a
search and replace over the tracked files, on a branch, in one commit, then
run `tests\check.lua`:

- `Beastkeeper` → `<New>`, `beastkeeper` → `<new>`, `BEASTKEEPER` → `<NEW>`;
- `git mv` the files with the name in theirs (the `.toc`s, the rockspec).

A player's saved settings live under the old `<NAME>DB` and do not move with
it: copy `WTF\Account\<account>\SavedVariables\<Old>.lua` to `<New>.lua` and
rename the table inside.
