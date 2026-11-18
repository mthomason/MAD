# Windows engine licence texts

These are the licence texts for the runtime components the native Windows
engine (`Windows/`, `mad.exe`) redistributes. The C-library texts it also uses
(OpenSSL, FreeTDS, MariaDB Connector/C, libpq, SQLite, zlib, bzip2, libarchive)
live one directory up and are shared with the Apple app.

The texts are copied verbatim from the pinned upstream revisions recorded in
`Windows/Engine/toolchain.conf` and `Windows/Engine/libraries.conf`. The
provenance is also recorded in `ThirdParty/Licenses/README.md`; the register is
`docs/project/THIRD_PARTY_LICENSES.md` §10 (the native Windows engine).

| File | Component | Source at the pin |
|---|---|---|
| `LGPL-2.1.txt` | GNUstep Base, the libiconv library, gnustep-corebase | `COPYING.LIB` in `gnustep/libs-base`, `kiyolee/libiconv-win-build` and `gnustep/libs-corebase` at the pinned revisions. The GNUstep test programs and the libiconv `iconv` tools are GPL; only the libraries are linked. |
| `libobjc2-MIT.txt` | libobjc2 (including libBlocksRuntime) | `COPYING` in `gnustep/libobjc2` at the pinned revision. |
| `libdispatch-Apache-2.0-with-Swift-exception.txt` | libdispatch | `LICENSE` in `apple/swift-corelibs-libdispatch` at the pinned revision, including the Swift runtime exception. |
| `libffi-MIT.txt` | libffi | `LICENSE` at libffi v3.8.0. |

SHA-256 of the committed texts:

```
83b61e738c4c799faebed2d5504adde4d33d7b77a976f07e727098abdd922f41  LGPL-2.1.txt
56b923b1db99c7975c4e4ad4847381b32d3c9401fb2c8270b41fb6d31d6014fb  libobjc2-MIT.txt
0ca84095d1de77cad1a866ebbad28f8db98a0826c6055d92b0608c5baa1643e2  libdispatch-Apache-2.0-with-Swift-exception.txt
17b64dc60f3b6897a60f971e288b973f655c2edcdf08b25f3c3dd5549857881c  libffi-MIT.txt
```

The GNUstep Base command-line tools (`gdomap`, `gdnc`, `defaults`, `plutil`,
`gspath`) are GPL-3.0-or-later and are not part of `mad.exe`; do not package them
unless the GPL text and corresponding-source offer are added. The libraries are
LGPL-2.1-or-later. The GNUstep test programs and the libiconv `iconv` tools are
GPL and are not shipped.

The Windows distribution must copy `ThirdParty/Licenses/` and `NOTICE` beside
`mad.exe` (or into the app package). The WPF About window must render these
components and texts from the register; it is opened by the Phase 5 shell proof
and completed in Phase 6. The iOS/macOS About screens stay Apple-only because the
Apple app does not link the GNUstep runtime.

The written relink offer for the Windows engine is in
`ThirdParty/Licenses/README.md`.
