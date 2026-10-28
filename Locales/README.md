# Locales

Beastkeeper uses AceLocale-3.0 with one locale, `"Beastkeeper"`, shared by the core and
every module. On the CurseForge translation page the strings are split into
namespaces: the core's strings sit in the base namespace, each module's in a
namespace named after the module (`AutocastCheck`, `CareButton`, ...), so a
translator sees one module's strings together.

## English: the source

- The core's strings are in `Locales/enUS.lua`. A module's strings are in its
  own file, loaded right after `enUS.lua`, adding to the same locale:

  ```lua
  local L = LibStub("AceLocale-3.0"):NewLocale("Beastkeeper", "enUS", true)
  ```

- Keys start with the module's prefix (`AUTOCAST_...`), so two modules never
  share a key in the one runtime table.
- **One string per line, however long.** The strings sit between
  `-- stylua: ignore start` and `-- stylua: ignore end`, so StyLua does not
  wrap a long one onto the next line. A wrapped assignment is reported by Lua
  on its second line and by luacov as missed on its first, which would break
  the 100% line coverage; one line per string is also easier to read and to
  import.
- **Every string gets a comment** right above it saying where it appears
  (chat, toast, settings page, tooltip), what the player is doing at that
  moment, and what each `%s`/`%d` holds. Words that must stay as they are
  (slash commands, typed arguments) are named. A translator sees only the
  string; the comment is what tells them `%s is off` is about a module and
  not a pet.

## Other languages: filled in by the packager

Every other language has one file holding only keywords, one line per
namespace:

```lua
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore", namespace="AutocastCheck")@
```

When BigWigs packager builds a release with a CurseForge API key and the
project ID, it replaces each line with the translations entered on the
translation page. In the repository, in tests and in a build without the key
the lines stay comments: the language then gets no strings of its own and
AceLocale shows the English ones.

`handle-unlocalized="ignore"` leaves out phrases nobody has translated yet, so
AceLocale falls back to English for them instead of the file repeating the
English text.

A module that moves in adds its namespace line to every language file.

Plurals: AceLocale has none, but WoW draws `|4singular:plural;` after a
number in the right form ("%d training |4point:points;"); languages with more
forms list them all (`|4one:few:many;` in Russian).

## Getting strings onto the translation page

The translation page only knows the phrases it has been given. After adding
or changing English strings, import them on CurseForge (project →
Localization → Import), language English, as a Lua additive table, into the
matching namespace. The import API can do the same from a script.

## Adding a language

Copy one of the keyword files, change the locale code on every line and in
`NewLocale`, and add it to `Beastkeeper.toc` after `enUS.lua`.
