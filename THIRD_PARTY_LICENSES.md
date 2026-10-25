# Third-Party Software: Use and License Compliance

This document records every third-party component in _MAD Designer_, how each one
reaches the shipped app, and what its license requires. It is the compliance
register for the project: when a library is added, removed or version-bumped, the
entry here changes with it. The remediation plan that works through the findings
below is `LICENSE_COMPLIANCE_PLAN.md`.

**This is an engineering-level compliance review, not legal advice.** The
conclusions below follow the plain text of each license and the standard
interpretations published by its steward (FSF, Apache Foundation, Oracle). Items
marked **unresolved** need either a written grant or a decision from the owner.

Scope: the `Compressor` library matrix (`Compressor/matrix.conf`), and the
third-party source committed to the git tree. It does not cover Apple SDK
frameworks, which carry no redistribution obligation.

---

## 1. Summary of findings

**Answer to "must anything be excluded or removed?" — yes, one thing, and
possibly three more.**

| # | Component | License | Verdict |
|---|---|---|---|
| 1 | **mysqlclient 8.4.10** | **GPL-2.0-only** + Universal FOSS Exception | **BLOCKER — must not ship in a proprietary app without an Oracle commercial license.** |
| 2 | **Karl Kraft MySQL connector** | none — "All rights reserved" | **Unresolved — no license grant found. Obtain one or replace the code.** |
| 3 | **NSOperation+Advanced** | none — "All rights reserved" | **Unresolved — upstream has no license file. Two small methods; rewrite.** |
| 4 | **NSData+AES256** | ~~unknown — pastie snippet~~ | **Resolved 2026-10-24 — rewritten as first-party code, format pinned by golden vectors.** |
| 5 | FreeTDS 1.4.27 | LGPL-2.0-or-later, **elected LGPL-3.0** | Permitted; **notice, marked header, LGPL text and written relink offer landed 2026-10-24** (kit script deferred to the MariaDB prompt). |
| 6 | OpenSSL 3.5.9 | Apache-2.0 | Permitted; **license text must ship**. |
| 7 | libarchive 3.8.9 | BSD-2-Clause | Permitted; **notice must ship**. |
| 8 | zint 2.16.0 (backend) | BSD-3-Clause | Permitted; **notice must ship**. |
| 9 | bzip2 1.0.8 | bzip2 (BSD-like) | Permitted; notice recommended. |
| 10 | libpng 1.6.59 | PNG Reference Library v2 | Permitted; notice recommended. |
| 11 | zlib 1.3.2 | Zlib | Permitted; acknowledgment appreciated. |
| 12 | SQLite 3.53.3 | Public domain | No obligation. |
| 13 | asn1c runtime | BSD | Permitted; notice must ship. |
| 14 | pngquant `rwpng` | BSD-2-Clause | Permitted; notice must ship. |
| 15 | miniz | Public domain (Unlicense) | No obligation. Header corrected 2026-10-04. |
| 16 | NSData+Base64 (Matt Gallagher) | permissive, notice-retained | OK. |
| 17 | Fonts | mixed | **OFL text and Larabie readme committed 2026-10-24; ClickBits/InfoBits are commercial and stay out of the bundle and any public mirror.** |

**Answer to "must some be compiled as frameworks instead of `.a`?" — no.**

* For a **GPL** library, the linking mode is irrelevant. Dynamic linking does not
  cure GPL copyleft; only a commercial license or removal does. Building
  `libmysqlclient` as a `.framework` instead of a `.a` changes nothing.
* For an **LGPL** library, a shared library *is* the textbook route to §6(b) — but
  on iOS the user cannot substitute a library inside a signed app bundle, so a
  dynamic framework does not cleanly discharge the obligation either. The route
  that works on iOS is §6(a): notices plus a relink offer. See §3.3.
* For **permissive** libraries, linking mode is irrelevant; only the notices matter.

---

## 2. How third-party code reaches the app

The link model matters for which obligations attach, so it is worth stating once.

* `Compressor/` builds nine libraries as **static `.a`** archives inside
  xcframeworks. Nothing from `Compressor/` is embedded or copied into the bundle.
* Each `.a` is linked into a **first-party dynamic `MAD*.framework`**:
  MAD (libarchive, bzip2, zlib), MADBarcodes (libpng, zlib, zint),
  MADMySQL (mysqlclient, openssl), MADSqlite3 (sqlite3), MADTds (freetds, openssl).
* The app embeds and codesigns 12 `MAD*.framework` bundles. **No third-party dylib
  ships.** At runtime the app links only Apple libraries (`libc++`, `libxml2`,
  `liblzma`, `libiconv`, `libobjc`, `libSystem`).
* Consequence: every third-party library above is **statically linked into a
  binary we distribute**, and there is **no third-party attribution surface in the
  app at all** — the About screen
  (`MADDesigner/Source/MADAboutTableViewController.m`, 6 rows) is entirely
  first-party, and no `Acknowledgements` file exists in the repo or the bundle.

---

## 3. The Compressor libraries

Versions are from `Compressor/matrix.conf`; license texts were read from the
downloaded sources under `Compressor/build/<lib>/source/`.

### 3.1 The permissive majority

| Library | Version | License | What it requires of a binary-only distribution |
|---|---|---|---|
| sqlite3 | 3.53.3 | Public domain | Nothing. (`LICENSE.md`: none of the non-public-domain build scripts reach `sqlite3.c`.) |
| zlib | 1.3.2 | Zlib | Do not misrepresent origin. Acknowledgment appreciated, not required. |
| bzip2 | 1.0.8 | bzip2 license | Do not misrepresent origin; do not use the author's name to endorse. Acknowledgment appreciated. |
| libpng | 1.6.59 | PNG Reference Library v2 | Copyright notice may not be removed or altered; do not misrepresent origin. |
| libarchive | 3.8.9 | BSD-2-Clause | **Copyright notice, conditions and disclaimer must be reproduced in the documentation or materials.** |
| zint (backend) | 2.16.0 | BSD-3-Clause | **Copyright notice, conditions and disclaimer must be reproduced in the documentation or materials.** |
| openssl | 3.5.9 | Apache-2.0 | **A copy of the license must be given to recipients** (§4(a)); retain notices. No `NOTICE` file is shipped. |

Note on zint: the upstream `LICENSE` says the *backend* (which is all we build —
`ZINT_FRONTEND=OFF`) is BSD-3-Clause while the Qt frontends remain GPL. Only the
BSD backend is compiled, so no GPL code ships. `zint.h` and the backend sources
confirm BSD-3-Clause in their own headers.

Bundled *inside* the shipped `libmysqlclient.a` (see §3.2) are three more
permissive components — **zstd** (BSD-3-Clause), **zlib** (Zlib) and
**libdivsufsort** (MIT). None of them changes the analysis; the archive as a whole
is governed by Oracle's GPLv2.

### 3.2 libmysqlclient — the blocker

**License.** `Compressor/build/mysqlclient/source/src/LICENSE` states the release
is "under version 2 of the GNU General Public License (GPLv2)" and Oracle
"elects to use only the General Public License version 2 (GPLv2) at this time" —
i.e. **GPL-2.0-only**, not "or later". The same file grants an additional
permission to link with separately licensed software (which is what makes the
OpenSSL 3 dependency permissible), and places the C client library under the
**Universal FOSS Exception, version 1.0**.

**Why the FOSS Exception does not help.** The Universal FOSS Exception grants
rights only for distributing MySQL with software that is itself "distributed with
complete corresponding source under a license that is OSI-approved and/or
categorized by the FSF as free" ("Other FOSS"). It closes with: *"Nothing in this
additional permission ... grants any additional permission of any kind for use or
distribution of the Software in conjunction with software other than Other FOSS."*

_MAD Designer_ was `LICENSE.md`: "Copyright © Michael Thomason 2025. All rights
reserved." It was not Other FOSS, so **no exception applied**: distributing the app
with `libmysqlclient` linked in meant the GPLv2's copyleft reached the whole work,
and the app's source would have had to be released under the GPLv2. Building the
library as a dynamic framework does not change this.

**Changed 2026-10-24 by the open-source launch:** the repository is now
licensed under the MIT (see `LICENSE`), an OSI-approved licence. Recorded for
the MariaDB decision (Prompt 2 of the launch plan): as MIT software _MAD
Designer_ now arguably falls within the Universal FOSS Exception's "Other
FOSS" definition, which would change this analysis. That is for the owner to
weigh; the MariaDB swap remains the plan's recommendation.

**Options, best first:**

1. **Replace it with MariaDB Connector/C.** It is the same C API (`mysql_init`,
   `mysql_real_connect`, `mysql_stmt_*`, …, all 27 of the API calls `MADMySQL`
   makes are in its surface) under **LGPL-2.1**, which expressly permits distribution
   with proprietary applications. This converts the problem into the same class of
   problem as FreeTDS, which we have to solve anyway (§3.3), and it removes the
   blocker entirely.
2. **Buy an Oracle commercial (OEM/ISV) license.** The only way to keep stock
   `libmysqlclient` in a closed-source product. Budget and terms are a business
   decision.
3. **Drop MySQL support** and ship SQL Server only.
4. Relicensing _MAD Designer_ under the GPLv2 is not compatible with App Store
   distribution of a commercial product and is listed only for completeness.

**Also worth cleaning up regardless of which option is chosen:** the app target
links `openssl.xcframework` directly, but the shipped app binary defines no
OpenSSL symbols — it is dead-stripped. That link can simply be removed.

### 3.3 FreeTDS — LGPL, which is permitted but has conditions

**License.** Every source file in the shipping libraries (`tds/`, `ctlib/`,
`dblib/`, `replacements/`) carries the same grant:

> This library is free software; you can redistribute it and/or modify it under
> the terms of the GNU Library General Public License as published by the Free
> Software Foundation; **either version 2 of the License, or (at your option) any
> later version.**

So it is **LGPL-2.0-or-later**, and the distributor may choose the version to
comply under. (The GPL text in `COPYING.txt` covers the applications and server,
which `--disable-apps --disable-server` excludes from the build; the `replacements/`
files without headers are permissive public-domain/BSD stand-ins.)

**The §6 obligation.** LGPL sections 6 (v2) / 4 (v3) permit linking a proprietary
work against the library, provided the recipient can still modify the library and
relink. Concretely, shipping FreeTDS statically inside the app requires all of:

* a prominent notice that FreeTDS is used and is covered by the LGPL;
* a copy of the LGPL;
* the FreeTDS source (available from upstream — the version is pinned in
  `matrix.conf`);
* **a way to relink** — the "Corresponding Application Code": the app's object
  files and build materials, offered to any recipient, so they can link a
  modified FreeTDS into a working app.

**A dynamic framework does not solve this on iOS.** §6(b)'s "suitable shared
library mechanism" presumes a library the user can replace on their own system;
inside a signed, App Store–distributed bundle they cannot. The §6(a) route above
is the one that applies here, and it is what most iOS shippers of LGPL code do.

**Which version to elect, and why it matters.** FreeTDS links OpenSSL 3, which is
Apache-2.0. Apache-2.0 is compatible with GPLv3/LGPLv3 but **not** with
GPLv2/LGPLv2. So FreeTDS must be taken under **LGPL-3.0** for the OpenSSL
combination to be license-compatible — the "or later" wording is what makes this
available. This is worth recording explicitly, because it also means the LGPLv3
notice and source-offer wording is the one that must ship.

**The LGPL-3.0 election is recorded.** 2026-10-24: this project elects
**LGPL-3.0** for FreeTDS, for the compatibility reason above. The election is
also recorded in `ThirdParty/Licenses/README.md` and `NOTICE`; the LGPL-3.0
text is committed at `ThirdParty/Licenses/LGPL-3.0.txt`.

**Two concrete defects, both addressed:**

1. ~~**The shipped header is modified without a notice.**~~ **Fixed 2026-10-24.**
   `sybdb.h` has `typedef int BOOL;` commented out by the recipe
   (`Compressor/lib/recipes/freetds.sh`), and that edited file ships in all three
   slices of `freetds.xcframework` and in the canonical include dir. The recipe
   now inserts a prominent notice of the change and its date (2026-10-24)
   directly above the commented line, so every shipped copy of the modified
   header carries it.
2. ~~**The relink materials do not exist yet.**~~ **Partially addressed
   2026-10-24.** The written relink offer exists
   (`ThirdParty/Licenses/README.md`: how to request the object files and build
   materials, the three-year statement, and the honest note that an iOS
   recipient needs a developer account). The `Compressor/relink-kit.sh` script
   is deferred by the owner's decision (plan §9.3); it will serve FreeTDS and
   MariaDB alike and is Prompt 2's work.

---

## 4. Committed third-party source inside the app targets

`DEVELOPER.md` says "nothing third-party is in revision control." That is not
true, and it is worth correcting: the following components are committed and
compile into the shipped app.

### 4.1 Unresolved — no license grant

**Karl Kraft MySQL connector** — `MADMySQL/Source/` (30 files). Headers read
"Created by Karl Kraft on 5/21/08. Copyright 2008-2012 Karl Kraft. All rights
reserved." There is **no license text anywhere in the repo**, and the upstream
project (formerly `svn.karlkraft.com/mysql_connector`, described in his 2010–2011
blog posts) is no longer reachable; no mirror or license statement could be
located. Absent a grant, "all rights reserved" means there is no permission to
copy and distribute it. Note this sits directly on top of the GPL problem of
§3.2 — the MySQL support would need attention on this axis even if the client
library were replaced.

*Action: obtain a written grant from Karl Kraft, or replace these classes with
first-party code (the API surface used is small: connect, query, fetch, escape).*

**`NSOperation+Advanced.{h,m}`** — `MADFoundation/Source/`. Headers read
"Copyright (c) 2015 Andrey K. All rights reserved." The project name and date
match the GitHub project `kas-kad/AdvancedNSOperations` (created 2015-07-05,
Objective-C, same class names) — which **has no LICENSE file** and reports
`license: null`. The two methods (`addCompletionBlock:`, `addDependencies:`) are
a handful of lines each.

*Action: rewrite them in-house. This is cheaper than resolving provenance.*

**`NSData+AES256.{h,m}`** — `MADDesigner/Source/`. **Resolved 2026-10-24:
rewritten as first-party code.** The ciphertext format was pinned first by
golden vectors in `MADAppLogicTests.m` computed independently with
`openssl enc -aes-256-cbc` and verified green against the pre-rewrite
implementation, then the bodies were rewritten from the AES-256-CBC
specification (CommonCrypto's documented `CCCrypt` usage, PKCS#7) with the same
key derivation (UTF-8, zero-padded to 32 bytes, refused when longer) and the
same IV handling (random IV prepended to the ciphertext). The golden vectors
pass unchanged after the rewrite. Was: the header credited Michael Thomason but
carried "Found at http://pastie.org/426530#44" — a public snippet paste with no
author and no license, since removed.

### 4.2 Permissive, with notices to carry

| Component | Where | License | Obligation |
|---|---|---|---|
| asn1c runtime (Lev Walkin) | `MADDesigner/Source/ReceiptModuleAsn1c/` (~50 runtime files plus generated receipt code) | BSD, per `asn_application.h`: "Redistribution and modifications are permitted subject to BSD license" | Copyright notice, conditions and disclaimer in materials. |
| pngquant `rwpng` | `MADDesigner/Source/rwpng/` (2 files) | BSD-2-Clause, per `rwpng.c` | Copyright notice, conditions and disclaimer in materials. |
| NSData+Base64 (Matt Gallagher) | `MADDesigner/Source/` (2 files) | Custom permissive: notice must be retained in source redistribution; binary use is permitted | Notice retained — OK as shipped. |
| miniz (Rich Geldreich) | `MAD/Source/miniz.c`, `miniz.h` | Public domain / Unlicense, stated at the end of `miniz.c` | None — **but see below**. |

**The miniz header** — **fixed 2026-10-04.** Both files carried a first-party
header ("Created by Michael Thomason on 5/13/16. Copyright © 2017 Michael
Thomason. All rights reserved.") and `miniz.h` was rebranded outright as
`madmini.h` with no attribution at all. miniz is Rich Geldreich's public-domain
code, so both headers now credit him and record the vendoring; the Unlicense
statement at the end of `miniz.c` was never altered, so no obligation was ever
at stake — it was a misstatement of authorship, and it is corrected. No further
action.

### 4.3 Fonts

| Font | Status | Notes |
|---|---|---|
| `FontAwesome.ttf` | **Ships** (`UIAppFonts`; used in `MADAttributedStringCommon.m:31`, `MADToolboxStyleViewController.m:157`, `MADStoreViewController.m:151`) | The font files are **SIL OFL 1.1**; the OFL requires the copyright notice and license text to accompany the font. Attribution is not required by Font Awesome's own terms. The OFL text is not currently in the repo or the bundle — add it. |
| `CarbonBlock.ttf` | **Ships** (copied as a resource) | Name table: "© 1999 Ray Larabie. This font is freeware. Read attached text file for details." Larabie's freeware terms travel in that attached text file, which is **not** in the repo. Retrieve and keep it, so the freeware conditions are on record. |
| `ClickBits*.otf`, `InfoBits*.otf` (13 files) | In `StaticResources/Fonts/`, **do not ship** | Commercial retail fonts: name tables read "Copyright (c) Ethan Dunham / Fonthead Design Inc. All rights reserved", trademarked, sold through Fontspring/Linotype. They are not in the app bundle and not referenced by the project. They are committed to a **private** repository, so nothing is publicly redistributed today. |

*Action: if the app ever embeds a ClickBits/InfoBits face, an application-embedding
licence must be purchased first. Keep them out of the built product and be aware of
them if the repository is ever made public.*

---

## 5. The gaps, stated plainly

1. The app ships **no third-party notices at all**, while shipping code whose
   licenses require them (libarchive BSD-2, zint BSD-3, OpenSSL Apache-2.0, asn1c
   BSD, rwpng BSD-2, FreeTDS LGPL). **The repository now carries the notices**
   (`NOTICE`, `ThirdParty/Licenses/`, 2026-10-24); the in-app Acknowledgements
   screen remains open (plan C2, after the MariaDB decision).
2. ~~**No license texts are committed anywhere.**~~ **Fixed 2026-10-24:**
   `ThirdParty/Licenses/` holds every text from §7's table. `Compressor`
   deliberately commits nothing third-party, and that is the right default for
   *code* — the notices and license texts are exactly the part that must be
   distributed, so they have a committed home of their own.
3. **FreeTDS's relink obligation** — header marked and written offer landed
   2026-10-24; the relink-kit script is deferred by the owner's decision (plan
   §9.3) to the MariaDB prompt, where the mechanism serves both libraries.
4. **`libmysqlclient` cannot lawfully ship** in this product as configured —
   unchanged; the owner's decision (D1) remains open, and the 2026-10-24 MIT
   relicensing is recorded in §3.2 as a fact the decision should weigh.
5. ~~**Three components have no license grant.**~~ Two of three resolved
   2026-10-24: `NSOperation+Advanced` and `NSData+AES256` are rewritten as
   first-party code. The Karl Kraft connector remains (Prompt 2, with the
   MariaDB swap).
6. `DEVELOPER.md`'s claim that nothing third-party is in revision control is
   inaccurate. The stale `patches/zint-2.4.2-mad.patch` references are corrected:
   `LIBRARIES.md` (§1) now describes the zint 2.16.0 recipe, and
   `Compressor/lib/recipes/zint.sh` mentions the patch only to record that it is
   retired (the file was deleted in `f7526ba04`).

---

## 6. Required actions, in order

**P0 — blocking, decide before the next submission**

1. Decide the `libmysqlclient` question: Oracle commercial license, MariaDB
   Connector/C (LGPL-2.1), or drop MySQL. Nothing else on this list is as
   consequential. **Open — the owner's decision (D1); the MIT relicensing of
   2026-10-24 is recorded in §3.2 as a fact the decision should weigh.**
2. Resolve the three unlicensed components. Two of them are small enough to
   rewrite in an afternoon; the Karl Kraft connector is the real decision.
   **Two of three done 2026-10-24: `NSOperation+Advanced` and `NSData+AES256`
   are rewritten as first-party code. The Karl Kraft connector is Prompt 2's
   work, with the MariaDB swap.**
3. Remove the dead `openssl.xcframework` link from the app target. **Open.**

**P1 — compliance, should be done before shipping**

4. Add a third-party notices surface to the app (About → Acknowledgements is the
   natural home) and commit the license texts it displays. Draft text in §7.
   **Open — plan C2, held until the MariaDB decision.**
5. FreeTDS: add the LGPL notice and license text; mark the modified `sybdb.h`;
   elect LGPL-3.0 and record why; write the relink offer and make the build able
   to produce the corresponding object files. **Mostly done 2026-10-24: the
   election is recorded, the LGPL-3.0 text is committed, the recipe now marks
   the shipped header, and the written relink offer is in
   `ThirdParty/Licenses/README.md`. The relink-kit script is deferred by the
   owner's decision (plan §9.3) to the MariaDB prompt.**
6. ~~Correct the miniz copyright header.~~ Done 2026-10-04.
7. Add the OFL text alongside FontAwesome, and the Larabie readme alongside
   CarbonBlock. **Done 2026-10-24 — both texts are committed in
   `ThirdParty/Licenses/`, with provenance recorded there.**

---

## 7. Draft notices text

The following is the attribution block the app needs to carry. It is written to
be dropped into an Acknowledgements screen verbatim. **It is deliberately
incomplete for `libmysqlclient`,** because that component must not ship as
configured — add Oracle's notice only if a commercial licence is obtained, in
which case add the GPLv2 text and a written offer of the corresponding source.

> ### Open source components
>
> This application includes the following open source software.
>
> **SQLite** — Public domain. <https://sqlite.org>
>
> **zlib** — © 1995–2026 Jean-loup Gailly and Mark Adler. Provided under the zlib
> licence.
>
> **bzip2** — © 1996–2019 Julian R Seward. Provided under the bzip2 licence.
>
> **libpng** — © 1995–2026 The PNG Reference Library Authors, © 2018–2026 Cosmin
> Truta and contributors. Provided under the PNG Reference Library License
> version 2.
>
> **libarchive** — © 2003–2018 Tim Kientzle and contributors. Provided under the
> BSD 2-Clause licence.
>
> **zint** — © 2008–2025 Robin Stuart and contributors. Provided under the BSD
> 3-Clause licence.
>
> **OpenSSL** — © 1998–2026 The OpenSSL Project Authors. Provided under the
> Apache License 2.0. A copy of the licence is included below.
>
> **asn1c runtime** — © 2004, 2006 Lev Walkin. Redistribution and modification
> permitted subject to the BSD licence.
>
> **pngquant `rwpng`** — © 1998–2000 Greg Roelofs, © 2009–2014 Kornel Lesiński.
> Provided under the BSD 2-Clause licence.
>
> **miniz** — Rich Geldreich. Released into the public domain (Unlicense).
>
> **FreeTDS** — © 1998–2015 Brian Bruns, Frediano Ziglio and contributors.
> This library is free software; you can redistribute it and/or modify it under
> the terms of the GNU Lesser General Public License as published by the Free
> Software Foundation, either version 3 of the Licence, or (at your option) any
> later version. A copy of the licence and the complete corresponding source for
> FreeTDS are available at <https://www.freetds.org>. **To exercise your right to
> relink this application against a modified FreeTDS, contact [address] to
> receive the object files and build materials needed to do so.**
>
> **Font Awesome** — © Dave Gandy. The font is provided under the SIL Open Font
> Licence 1.1.
>
> **Carbon Block** — © 1999 Ray Larabie. Freeware, used under the terms
> accompanying the font.

Plus, in the repository, the full licence texts for each of the above, which are
the ones read for this review. **Committed 2026-10-24 in `ThirdParty/Licenses/`,**
one file per component; the provenance of each committed file (including the
LGPL-3.0 election, the OFL provenance and the recovered Larabie readme) is
recorded in `ThirdParty/Licenses/README.md`. The paths each text was read from:

| Component | Licence text source (as read for this review) |
|---|---|
| libarchive | `Compressor/build/libarchive/source/src/COPYING` |
| zint | `Compressor/build/zint/source/src/LICENSE` |
| openssl | `Compressor/build/openssl/source/src/LICENSE.txt` |
| freetds | `Compressor/build/freetds/source/src/COPYING_LIB.txt` |
| libpng | `Compressor/build/libpng/source/src/LICENSE` |
| bzip2 | `Compressor/build/bzip2/source/src/LICENSE` |
| zlib | `Compressor/build/zlib/source/src/LICENSE` |
| sqlite3 | `Compressor/build/sqlite3/source/src/LICENSE.md` |
| asn1c | BSD text in `MADDesigner/Source/ReceiptModuleAsn1c/asn_application.h` |
| rwpng | BSD text in `MADDesigner/Source/rwpng/rwpng.c` |
| FontAwesome | SIL OFL 1.1 text |

These paths live under gitignored build trees, so the texts must be **copied into
a committed directory** (for example `ThirdParty/Licenses/`) — this is the one
legitimate exception to "nothing third-party in the repository": we are not
committing their code, only the notices we are obliged to redistribute.

---

## 8. Incidental findings

Not licensing, found while tracing the link graph — recorded here so they are not
lost:

* **OpenSSL bakes a build-machine path into the shipped binary.** The string
  `/Users/michael/Desktop/Reports/Compressor/build/openssl/ios/arm64/install/ct_log_list.cnf`
  appears in `MAD Designer.app/MAD Designer` — OpenSSL's configured `OPENSSLDIR`.
  It leaks a local absolute path into the release artifact and points at a
  certificate-transparency list that does not exist on-device. The OpenSSL recipe
  should set an install-relative or system `OPENSSLDIR`.
* **MAD links Apple's `libsqlite3.tbd`** (`MAD.xcodeproj:29, :525`) alongside the
  Compressor-built SQLite that `MADSqlite3` links. At runtime only the static
  copy is loaded, but two SQLite copies in one process is a latent hazard worth a
  look from the defect register, not this document.

---

## Appendix: re-running this review

```sh
# 1. the library inventory and pinned versions
cat Compressor/matrix.conf

# 2. license texts for the Compressor libraries
find Compressor/build -maxdepth 4 \( -name 'COPYING*' -o -name 'LICENSE*' \) -print

# 3. what actually ships in the app binary
nm -g "…/MAD Designer.app/Frameworks/MADTds.framework/MADTds" | grep ' T _SSL_'

# 4. third-party source committed to the tree (the ones that are not gitignored)
git grep -l -e 'Copyright' -e 'Redistribution and use' -- '*.c' '*.h' '*.m' \
  ':!Compressor/build' ':!Compressor/library'

# 5. attribution surface (expected: none, until §6 is done)
grep -rn -i 'acknowledg\|third.party\|open source' MADDesigner/Source \
  MADDesigner/Resources --include='*.m' --include='*.plist'
```
