# Third-party licence texts

This directory is the deliberate exception to the repository's "nothing
third-party in the repository" rule. No third-party *code* is committed; what
is committed here are the licence texts and notices the app is obliged to
redistribute alongside the binaries that link or embed these components. Do
not remove this directory during a cleanup without first reading
`docs/project/THIRD_PARTY_LICENSES.md` — several of these licences (Apache-2.0, the BSD
family, the SIL OFL, the LGPL) require the text to travel with the distributed
software, and the LGPL additionally requires the written offer below.

## Where each text came from

| File | Component | Source |
|---|---|---|
| `LGPL-3.0.txt` | FreeTDS, MariaDB Connector/C | Canonical FSF text from gnu.org. Both libraries are LGPL-2.0-or-later; this project **elects LGPL-3.0** for both, because both link OpenSSL 3 (Apache-2.0), and Apache-2.0 is compatible with the v3 terms but not the v2 terms. The election is recorded in `docs/project/THIRD_PARTY_LICENSES.md` §3.3–§3.4. |
| `openssl-Apache-2.0.txt` | OpenSSL | `Compressor/build/openssl/source/src/LICENSE.txt` (pinned 3.5.9). |
| `libarchive-BSD-2-Clause.txt` | libarchive | `Compressor/build/libarchive/source/src/COPYING` (pinned 3.8.9). |
| `zint-BSD-3-Clause.txt` | zint backend | `Compressor/build/zint/source/src/LICENSE` (pinned 2.16.0). |
| `libpng-LICENSE.txt` | libpng | `Compressor/build/libpng/source/src/LICENSE` (pinned 1.6.59). |
| `bzip2-LICENSE.txt` | bzip2 | `Compressor/build/bzip2/source/src/LICENSE` (pinned 1.0.8). |
| `zlib-LICENSE.txt` | zlib | `Compressor/build/zlib/source/src/LICENSE` (pinned 1.3.2). |
| `sqlite3-LICENSE.md` | SQLite | `Compressor/build/sqlite3/source/src/LICENSE.md` (pinned 3.53.3). |
| `asn1c-BSD.txt` | asn1c runtime | The header comment in `MADDesigner/Source/ReceiptModuleAsn1c/asn_application.h`. |
| `rwpng-BSD-2-Clause.txt` | pngquant `rwpng` | The header comment in `MADDesigner/Source/rwpng/rwpng.c`. |
| `FontAwesome-OFL-1.1.txt` | FontAwesome.ttf (v4.3.0) | The canonical SIL OFL 1.1 text from openfontlicense.org. The 4.3.0 distribution carried no licence file, and the copyright line FA declared for that version was "Font Awesome by Dave Gandy - http://fontawesome.io". |
| `CarbonBlock-Larabie-read_me.html` | CarbonBlock.ttf | The "attached text file" the font's name table refers to. The 1999–2004 larabiefonts.com `carbonbl.zip` was never archived; this is the same generic `read_me.html` that shipped in every Larabie freeware zip of that era, recovered from the archived `bluehigh.zip` (Wayback Machine, 2005-02-24 snapshot). It contains the freeware terms and the software-product EULA. |

## The relink offer (FreeTDS and MariaDB Connector/C)

MAD Designer links FreeTDS and MariaDB Connector/C statically. Both are
LGPL-2.0-or-later, taken here under **LGPL-3.0**, whose section 4 requires
that a recipient be able to modify the library and relink the application.
To exercise that right, contact the copyright holder at
**mthomason [at] gmail [dot] com** to receive the
application's object files and the build materials needed to relink against a
modified FreeTDS or MariaDB Connector/C: the pinned upstream sources (see
`Compressor/matrix.conf`) and the `Compressor` recipes. This offer stands for
at least three years from the last distribution of the application.

Note honestly: a relinked iOS build still needs an Apple developer account to
install. The obligation is to make the relink *possible*, and this offer does.

## The relink offer (the published container image)

The published container image (`ghcr.io/mthomason/mad`, the `mad` CLI's Linux
runtime) distributes GNUstep Base (LGPL-2.1-or-later, as a shared object), and
the statically linked MariaDB Connector/C and FreeTDS (both
LGPL-2.0-or-later, taken here under **LGPL-3.0** for the OpenSSL reason in
the section above). The LGPL requires that a recipient be able to modify
each library and relink the distributed work. To exercise that right,
contact the copyright holder at **mthomason [at] gmail [dot] com** to
receive the image's object files and the build materials needed to relink
against a modified GNUstep Base, MariaDB Connector/C or FreeTDS. The pinned
upstream sources are public in `Linux/toolchain.conf` and
`Linux/libraries.conf`, and the image rebuilds from them with
`./Linux/build.sh --runtime`. This offer stands for at least three years from
the last distribution of the image.

gnustep-make (GPL-3.0-or-later) is build tooling and is **not** in the
runtime image.
