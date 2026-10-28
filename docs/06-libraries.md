# Libraries

Ace3, LibSink-2.0, LibDataBroker-1.1, LibDBIcon-1.0 and LibGoThere-1.0.

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
Beastkeeper stays on a commit that has them until a release does.

LibSink-2.0 and LibDBIcon-1.0 (the Data Broker module's minimap button) live
only in CurseForge's svn, so their externals are `type: svn` with a release
tag. `tests/libs.lua` needs no svn client for it: the svn
server lists each directory as a page of links and serves each file at its own
address, which curl downloads.

LibDataBroker-1.1 (tekkub's GitHub repository) has no release tags; its
external is pinned to its last commit. The Data Broker module makes Beastkeeper's
data object with it.

LibGoThere-1.0 is Beastkeeper's own route library, in a repository of its own
([github.com/Langmans/LibGoThere-1.0](https://github.com/Langmans/LibGoThere-1.0)),
an external pinned to a commit like Ace3. Beast Map sends the hunter to a
beast through it. To move to a newer version, change the commit in `.pkgmeta`.
ReagentRecipeVendorTooltips embeds it too: until the library's first release
every copy has MINOR 1 and LibStub keeps whichever loads first, so both
addons must pin the same commit.

The `.toc` lists Ace3 and LibStub as `OptionalDeps`, so a separately
installed Ace3 loads first and LibStub keeps the newest copy of each library.
