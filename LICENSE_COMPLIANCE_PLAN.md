# License Compliance Plan

The remediation plan for the findings in `THIRD_PARTY_LICENSES.md`. That document
records *what is*; this one records *what we do about it*, in order, with the
decisions it depends on named.

**Standing constraint:** the app as currently configured cannot lawfully be
distributed, because it statically links `libmysqlclient` (GPLv2) into a
proprietary product. Until Workstream A lands, do not submit a build.

---

## 1. The question that shapes everything: GPL, LGPL and frameworks

> *"Can GPL licenses be used if they are wrapped in a framework? Is that what
> LGPL requires?"*

**No, and no.**

**Wrapping does not change GPL's reach.** A framework — static or dynamic — is
just a container for a binary. Copyright law looks at whether the GPL'd code and
your code form a single combined work, and linking them into one process does
that regardless of the packaging. A static `.a` in an xcframework, a dynamic
`.framework` embedded in the bundle, and a loose `.dylib` are all the same act:
the GPL covers the whole combined binary, and distributing it obliges you to
license your own code under the GPL. That is why Oracle's FOSS exception exists
at all — without a permission, GPL'd library code cannot go into a proprietary
app by any linking method.

The three real escape hatches are: the code is itself FOSS under a compatible
license, you hold a commercial license from the copyright holder, or you don't
ship the library.

**LGPL does not require a framework either.** LGPL *is* the permission that
allows proprietary linking — that is its entire purpose, and it is the difference
between it and the GPL. The price is a condition: the recipient must be able to
modify the library and relink your app with the modified version. There are two
ways to satisfy that condition, and a framework is only one of them:

* a **shared library** the recipient can substitute (that is what a framework
  gives you on the macOS desktop); or
* the **object files and build materials** for your app, so they can relink.

On iOS the first route does not really work: an app bundle is signed, so a
purchaser cannot drop in a modified framework and run it. That leaves the second
route, which is what this plan adopts for FreeTDS and for the MariaDB connector
alike — one mechanism covering both. See Workstream B.

---

## 2. Decisions this plan depends on

| # | Decision | Who | Blocks |
|---|---|---|---|
| D1 | MySQL client: MariaDB Connector/C (recommended), Oracle commercial license, or drop MySQL | Owner — **delayed 2026-10-17: the CLI deliverable comes first** | Workstream A |
| D2 | Confirm the ClickBits purchase tier covers *application embedding*, if those faces are ever to ship | Owner | Workstream E |

Everything in Workstreams B, D and E is independent of D1 and can proceed in
parallel with it.

---

## 3. Workstream A — replace the MySQL client library

**Goal:** `MADMySQL` no longer links GPL code, and neither does the app.

### A0. Recommend MariaDB Connector/C (decision D1)

MariaDB Connector/C is the MySQL C API reimplemented from the last LGPL'd MySQL
client, maintained by the MariaDB Foundation, under **LGPL-2.0-or-later** (its
files carry the "either version 2 of the License, or (at your option) any later
version" notice). It is a drop-in at the API level: all 27 `mysql_*` calls
`MADMySQL` makes are in its surface, including the prepared-statement family
(`mysql_stmt_init` … `mysql_stmt_fetch_column`), `mysql_real_escape_string`,
`mysql_use_result` and `CLIENT_FOUND_ROWS`.

It is *not* a drop-in at the license level — it is still LGPL. But LGPL is a
conditioned permission where GPL is a wall, and the condition is one we must
already satisfy for FreeTDS. That is the trade: one compliance mechanism instead
of one blocker.

Pin **3.4.11** (released 2026-09-29).

### A1. Build it in Compressor

1. Add a `mariadb` row to `matrix.conf` — version `3.4.11`, the release tarball
   from the MariaDB Connector/C GitHub releases, `deps: openssl`, same platform
   and deployment-target columns as the other rows.
2. Write `Compressor/lib/recipes/mariadb.sh` modelled on `freetds.sh`:
   * cmake per platform/arch, `-DWITH_SSL=OPENSSL` pointed at our per-platform
     openssl install (the mysqlclient and freetds recipes already do this);
   * `-DWITH_EXTERNAL_ZLIB=ON` against our zlib install, so we are not carrying a
     second zlib;
   * `-DWITH_CURL=OFF` and `-DWITH_UNIT_TESTS=OFF` — neither is needed and curl
     would add a dependency we do not otherwise have;
   * build the static target (`libmariadb.a`) and `finish_library` it, as the
     other recipes do.
3. Add a `lib/verify/mariadb.sh` that checks the slice architectures and that the
   auth plugins we depend on are compiled in — `caching_sha2_password` is the one
   that matters, since MySQL 8.4 no longer enables `mysql_native_password` by
   default.

The recipe is much simpler than the mysqlclient one: no host-tool two-stage
build, no try_run preset, no bundled boost. That whole apparatus exists because
of MySQL's build system, and it goes away with it.

### A2. Swap the link

* `MADMySQL` links `mariadb.xcframework` instead of `mysqlclient.xcframework`
  and `openssl.xcframework` (openssl comes in through the mariadb build, so the
  direct link may become unnecessary — verify, then remove if so).
* Header search path moves to `Compressor/library/mariadb/include`. `#import
  <mysql.h>` keeps working: Connector/C installs `mysql.h` at the include root.
* Drop the mysqlclient Ensure-Libraries phase invocation.

### A3. Rewrite the Objective-C layer as first-party code

This is where the Karl Kraft question is settled by construction.

The download in `Objc_Mysql_iPhone_OSX/` (since deleted) was examined: the
original distribution carries **no license file and no grant** — only "Copyright
2008–2010 Karl Kraft. All rights reserved." headers. Publication on a public blog
does not place a work in the public domain; absent a grant, the default is
all-rights-reserved. The `notes.txt` in the distribution is empty boilerplate.

The code in `MADMySQL/Source/` is already substantially modified from that
original, and the wrapper is thin — `MysqlConnection`, `MysqlFetch`,
`MysqlFetchField`, the exception classes, and the four statement helpers. Since
the MariaDB swap means touching this layer anyway, rewrite it rather than
rehabilitating it:

* keep the class structure and the `MADMySQL`-facing API, so nothing above it
  changes;
* write the bodies fresh against the MySQL C API — `mysql_real_connect` /
  `mysql_query` / `mysql_use_result` / `mysql_fetch_fields` / the `mysql_stmt_*`
  family — which is a small, well-documented surface;
* keep the existing `<MADMySQL/...>` public headers and the
  `MADDatabaseConnectionMySql` / `MADDataTypeMySQL` glue untouched where possible.

`MysqlServer` and `MADDatabaseMySQL` are already first-party and stay.

### A4. Verify

The live suite is `MADMySQL/MADMySQLTests/MADMySQLLiveTests.m`; it skips when no
server is reachable, so the offline suite stays green either way. Point it at the
local **MySQL 8.0.42** on `127.0.0.1:3306` (the Oracle installer's launchd
service) or at the pinned **`mad-mysql`** container on `13306` — the scheme's
default, both documented in `DEVELOPER.md` — and check:

1. **Authentication.** That server currently uses `mysql_native_password` for
   `root@localhost`, which exercises the easy path — the *risky* path is a modern
   server defaulting to `caching_sha2_password`. Test against a user configured
   with it before trusting the swap, because a connector that cannot authenticate
   against MySQL 8.4 is not a replacement.
2. **Result types.** `MADDataTypeMySQL` maps `MYSQL_TYPE_*` values to MAD types.
   Re-run the type coverage against the same schema and diff.
3. **Error text.** Anything asserting on `mysql_error()` strings will need
   updating — the two libraries word errors differently.
4. **TLS**, since MySQL 8 servers increasingly require it.
5. `Compressor/build.sh --verify --all` for the new artifact.

### A5. Retire mysqlclient

Only once A4 passes: remove the `mysqlclient` row from `matrix.conf`, delete
`lib/recipes/mysqlclient.sh`, and let the prune remove the built artifacts. That
removes GPLv2 from the product entirely.

**If D1 instead selects the Oracle commercial license**, Workstream A collapses to
"A0–A1 deleted, A2–A3 kept" — the Karl Kraft rewrite is still wanted, because the
commercial license only answers the *library* question, not the unlicensed
*Objective-C* question. If D1 selects dropping MySQL, A3's rewrite is moot and
`MADMySQL` is removed from the app target and the workspace.

---

## 4. Workstream B — LGPL compliance for FreeTDS and MariaDB

One mechanism, two libraries. LGPL §6 (v2) / §4 (v3) permits the proprietary link
provided the recipient can modify the library and relink.

**B1. Elect LGPL-3.0, and record why.** Both libraries are "version 2 or later",
so the version is ours to choose. Both link OpenSSL 3, which is Apache-2.0, and
Apache-2.0 is compatible with GPLv3/LGPLv3 but not with the v2 terms. Electing
v3 is what makes the combination license-compatible. Record the election in
`THIRD_PARTY_LICENSES.md` so a future version bump does not silently undo it.

**B2. Ship the notices.** Prominent notice, a copy of the LGPL-3.0 text, and a
pointer to where the source can be obtained — in the app's Acknowledgements
screen (Workstream C).

**B3. Publish the source position.** Both libraries are unmodified upstream
builds, pinned by hash in `matrix.conf`, so the source is simply upstream at that
version. The one exception is the FreeTDS *installed header* edit — see B4.

**B4. Mark the modified FreeTDS header.** `sybdb.h` has `typedef int BOOL;`
commented out by `Compressor/lib/recipes/freetds.sh`, and the edited file ships
in all three xcframework slices. LGPL §2 requires modified files to carry a
prominent notice of the change and its date. Add that comment at the edit site in
the recipe, so it lands in every copy (and so the modification is described in
the recipe that makes it, next to its explanation).

**B5. Provide the relink facility.** This is the substantive obligation and the
one thing not yet built. Deliver it as a script plus a written offer:

* a `Compressor/relink-kit.sh` (name to taste) that produces a tarball of the
  app's object files — the `MAD Designer` app target and the `MAD*.framework`
  binaries' objects — together with the pinned FreeTDS and MariaDB sources, the
  Compressor recipes, and a short README saying how to relink;
* the written offer in the Acknowledgements text: how to request it, and the
  statement that it is available for at least three years from the last
  distribution of the app.

Note honestly in the documentation that an iOS recipient will also need a
developer account to install a relinked build; the obligation is to make the
relink *possible*, and this does.

---

## 5. Workstream C — notices and license texts

**C1. A committed home for the texts.** Create `ThirdParty/Licenses/` holding the
license text for every component in `THIRD_PARTY_LICENSES.md` §7, copied from the
pinned sources. This is the deliberate exception to "nothing third-party in the
repository": we are not committing their code, only the notices we are obliged to
redistribute. Add a short `README` saying why the directory exists, so a future
cleanup does not remove it.

**C2. An Acknowledgements surface in the app.** The natural home is the existing
About screen (`MADDesigner/Source/MADAboutTableViewController.m`, currently six
rows) — add a seventh row pushing a text view rendering the notices. The draft
text is in `THIRD_PARTY_LICENSES.md` §7 and is ready to use.

**C3. Bundle the texts.** Copy `ThirdParty/Licenses/` into the app's resources so
the license texts travel with the binary, which is what Apache-2.0 §4(a) and the
BSD conditions actually require.

Hold C2 until Workstream A's decision is settled: the notice text differs
depending on whether MySQL is replaced, licensed, or dropped.

---

## 6. Workstream D — the two unlicensed leftovers

Both are small and both are rewrites rather than negotiations.

* ~~**`NSOperation+Advanced.{h,m}`**~~ **Done 2026-10-24 — rewritten as first-party
  code and renamed `NSOperation+CompletionBlock.{h,m}`.** The two methods were
  reimplemented from `NSOperation`'s documented semantics and the attribution
  deleted.
* **`NSData+AES256.{h,m}`** (`MADDesigner/Source/`) — AES-256-CBC over CommonCrypto.
  Rewrite from Apple's documented `CCCrypt` usage; it is a well-trodden 30 lines.

Neither blocks anything else.

---

## 7. Workstream E — fonts

* **FontAwesome** ships and is used in three files. Bundle the **SIL OFL 1.1**
  text alongside it (`ThirdParty/Licenses/`), which is what the OFL requires of a
  distributed font. No attribution is required by Font Awesome's own terms, but
  the license text must travel with the font.
* **CarbonBlock** ships. Recover the "attached text file" its name table refers
  to — Larabie's freeware terms — and keep it with the font, so the freeware
  conditions are on record rather than inferred.
* **ClickBits / InfoBits** are commercial fonts (Fonthead Design Inc.), purchased
  — keep the purchase record with the license texts. They do **not** ship today
  and should stay out of the bundle unless D2 confirms the purchased tier covers
  application embedding. Keep them out of any public mirror if the repository is
  ever opened up.

---

## 8. Sequencing

| Step | Work | Depends on |
|---|---|---|
| 1 | ~~Correct the miniz headers~~ | **done 2026-10-04** |
| 2 | FreeTDS: modified-header notice (B4); elect LGPL-3.0 and record it (B1) | — |
| 3 | `ThirdParty/Licenses/` and the license texts (C1) | — |
| 4 | MariaDB: recipe, matrix row, verify script (A1) | D1 |
| 5 | MariaDB: swap the link (A2) | step 4 |
| 6 | Rewrite the Objective-C layer (A3) | step 4 |
| 7 | Live-test against the local server, including `caching_sha2_password` (A4) | steps 5, 6 |
| 8 | Retire mysqlclient (A5) | step 7 |
| 9 | Acknowledgements screen and bundled texts (C2, C3) | step 8 |
| 10 | Relink kit and written offer (B5) | steps 2, 9 |
| 11 | ~~Rewrite `NSOperation+Advanced` and `NSData+AES256` (D)~~ | done 2026-10-24 |
| 12 | Fonts: OFL text, Larabie readme (E) | — |
| 13 | Hygiene: `DEVELOPER.md` sentence, stale patch references | — |

Steps 2, 3, 11 and 12 are independent and can be done in any order, at any time.
Steps 4–8 are the critical path. Step 9 is the point at which the app becomes
compliant enough to submit, assuming D1 goes to MariaDB.

**Why step 2 before step 9 matters:** the LGPL obligation is not satisfied by the
notice alone — it is satisfied by the notice *plus* the relink facility. Landing
the notice without B5 would look like compliance while missing the operative part.

---

## 9. What this plan needs from the owner

1. **D1 — the MySQL decision.** Recommended: MariaDB Connector/C. The rewrite is
   contained (one class cluster), the build is simpler than what it replaces, and
   it removes GPL from the product. The alternative is an Oracle commercial
   license; the third option is dropping MySQL.
2. **D2 — the ClickBits license tier**, only if those faces are ever to ship.
3. **A decision on B5's shape**: whether the relink kit is a script in this repo
   that anyone can run, or a written offer to supply it on request. Both satisfy
   the license; the first is more work and more defensible.
