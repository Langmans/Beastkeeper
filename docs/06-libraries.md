# Libraries

Ace3, LibSink-2.0 and LibGoThere-1.0.

Ace3 is not committed. `.pkgmeta` lists each library as an external, pinned
to a commit of the Ace3 GitHub mirror. The packager fetches them for a
release; `tests/libs.lua` reads the same `.pkgmeta` block and fetches the
same commits into `Libs\` before the tests. To move to a newer Ace3, change
the commit in `.pkgmeta` (all entries) and run the tests: the libraries are
fetched again when the block changes.

A stable release would be the better pin, and the mirror has release tags
(`Release-r1403`, ...). But the latest, r1403 of 12 August 2026, came before
AceDB's WoW: Forever fixes of September (character keys without the
surname, profile name limits) and AceGUI's ColorPicker fix for Forever, so
Kennel stays on a commit that has them until a release does.

LibSink-2.0 lives only in CurseForge's svn, so its external is `type: svn`
with a release tag. `tests/libs.lua` needs no svn client for it: the svn
server lists each directory as a page of links and serves each file at its own
address, which curl downloads.

LibGoThere-1.0 is Kennel's own route library, in a repository of its own
([github.com/Langmans/LibGoThere-1.0](https://github.com/Langmans/LibGoThere-1.0)),
an external pinned to a commit like Ace3. Beast Map sends the hunter to a
beast through it. To move to a newer version, change the commit in `.pkgmeta`.

The `.toc` lists Ace3 and LibStub as `OptionalDeps`, so a separately
installed Ace3 loads first and LibStub keeps the newest copy of each library.
