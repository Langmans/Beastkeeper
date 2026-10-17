# Libraries

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
