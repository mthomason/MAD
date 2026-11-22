---
layout: default
lang: de-DE
title: "Der Compressor-Build der statischen Bibliotheken"
description: "Die C-Bibliotheken von Drittanbietern, wie sie gebaut werden und wie Xcode sie erreicht."
---

# Statische Bibliotheken: das Compressor-Buildsystem

Diese Seite beschreibt die C-Bibliotheken von Drittanbietern, die die Anwendung linkt, und das Buildsystem `Compressor`, das sie erzeugt.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

Dieses Dokument beschreibt die statischen Bibliotheken von Drittanbietern, die die Anwendung linkt, und das Buildsystem, das sie erzeugt — wie gebaut, nicht wie geplant. Der Zustand vor der Überarbeitung (zwei überlappende Skriptgenerationen, eingecheckte Binärdateien, Verzeichnisse pro Plattform) ist im Anhang am Ende zusammengefasst.

**Bestehende Einschränkung:** Nichts in `Compressor/library`, das älter ist als diese Überarbeitung, wird gelöscht, bis das neue System jede Kombination gebaut hat und die App baut und ihre Tests gegen die neuen Artefakte bestehen. Aufgeräumt wird zuletzt, ein Commit pro Element.

---

## 1. Was das System ist

Eine deklarative Matrix, ein Treiber, ein Rezept pro Bibliothek, ein Manifest pro Build.

```
Compressor/
  matrix.conf                  # the single place version/source/platforms/deps live
  build.sh                     # the driver: ensure (default) / --all / --rebuild /
                               #   --verify / --platforms ios,simulator,macosx
  sqlite3.xcconfig             # the single place SQLite compile options live
  lib/common.sh                # download cache, per-arch compile helpers, lipo,
                               #   xcframework creation, manifest writer, lock
  lib/recipes/<lib>.sh         # one recipe per library (configure/cmake + install)
  lib/verify/<lib>.sh          # optional per-library artifact checks
  patches/                     # local modifications to upstream sources, captured
                               #   as diffs (none current; zint's 2.4.2 patch retired)
  media/<sha256>-<archive>     # content-addressed download cache (gitignored)
  src/  build/                 # extracted sources and build trees (gitignored)
  library/
    <lib>.xcframework/         # the single artifact Xcode links (gitignored)
    <lib>/include/             # the canonical header dir consumers name (gitignored)
    manifests/<lib>.json       # version, source hash, flags, slice SHAs (gitignored)
```

### Die Matrix (`matrix.conf`)

Zeilenorientiert und von Bash parsebar:

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```

`sha256` ist der Hash des heruntergeladenen Archivs — für jede Bibliothek festgeschrieben. `deps` benennt andere Matrixzeilen, die der Treiber zuerst baut. Nichts über den Build einer Bibliothek lebt irgendwo sonst: Flags pro Bibliothek leben im Rezept und werden ins Manifest gespiegelt, sodass sich „welche Flags haben das gebaut?“ allein aus dem Manifest beantworten lässt.

### Der Treiber (`build.sh`)

* `build.sh <lib>…` — jede Bibliothek sicherstellen (Abhängigkeiten zuerst); ein schneller No-op, wenn das Manifest zur Matrixzeile passt und jeder Slice existiert.
* `--all` — jede Bibliothek in der Matrix.
* `--rebuild` — die **benannten** Bibliotheken erzwingen; ihre Abhängigkeiten behalten die normale Frischeprüfung, sodass das Iterieren an einem Rezept nicht dessen Kette neu baut.
* `--verify` — Artefakte gegen die Matrix + Manifeste prüfen: Version und Quell-Hash, Slice-Architekturen, Vorhandensein der Header, den eingebetteten Versionsstring jeder Bibliothek sowie die Prüfungen pro Bibliothek in `lib/verify/`.
* `--platforms ios,simulator,macosx` — begrenzen, welche Plattformen gebaut werden (Standard: alle drei).

Builds werden durch eine Sperre auf `build/.ensure.lock.d` serialisiert (eine `mkdir`-Sperre mit Wiederherstellung bei veraltetem Besitzer — `flock` gibt es unter macOS nicht), weil mehrere Xcode-Targets während eines Workspace-Builds parallel Ensure-Phasen ausführen können.

Downloads landen im inhaltsadressierten Cache `media/`, sodass eine festgeschriebene Quelle einmal heruntergeladen und bei jeder Verwendung per Hash geprüft wird. Ein erster Build braucht Netzwerkzugriff; die Fehlermeldung sagt das und nennt das Tarball.

### Rezepte

Jedes Rezept entpackt die festgeschriebene Quelle nach `build/<lib>/source`, baut pro Architektur, führt lipo pro Plattform aus und ruft `finish_library` auf, das das xcframework erzeugt, das kanonische Include-Verzeichnis installiert und das Manifest schreibt. Eine Bibliothek pro xcframework-Slice-Kennung ist eine harte Einschränkung von `-create-xcframework`, also verschmelzen Bibliotheken mit mehreren Komponenten: openssl führt crypto+ssl zu `libopenssl.a` zusammen, freetds führt ct+sybdb+tds zu `libfreetds.a` zusammen, und mariadb ist ein einziges `libmariadbclient.a` (das Ziel `libmariadb` von Connector/C ist unter UNIX hart auf shared gesetzt, also baut das Rezept das statische Ziel `mariadbclient`). Slices werden aus den Mach-O-Load-Commands der Bibliotheken abgeleitet (den `-m*-version-min`-Flags pro Plattform), weshalb keine `-platform`-Hinweise nötig sind.

Hinweise, die man beim Anfassen eines Rezepts kennen sollte:

* **sqlite3** erzeugt die Amalgamation auf dem Host und kompiliert sie dann pro Slice mit der Optionsliste, die aus `sqlite3.xcconfig` geparst wird — das Rezept ist der *einzige* Konsument dieser Liste (das MADSqlite3-Target war früher der zweite, was Gefahr H7 in `BUGS.md` ist). Die Optionen legen das Cache-Format `.maddb` fest (Seitengröße 8192, `DQS=0`, FTS5, STAT4, …); behandeln Sie Änderungen als Formatentscheidungen.
* **mariadb** baut das statische Ziel `mariadbclient` pro Slice mit `WITH_SSL=OPENSSL` gegen die openssl-Installation pro Plattform und `WITH_EXTERNAL_ZLIB=ON` gegen die zlib-Installation, wobei die Auth-Plugins `caching_sha2_password` und `sha256_password` statisch einkompiliert und alle anderen Plugins deaktiviert sind (kein Plugin-`.so` wird ausgeliefert). Das DEFAULT-Installationslayout verschachtelt Header unter `include/mariadb`; das Rezept flacht sie ab, sodass `mysql.h` aus dem kanonischen Include-Wurzelverzeichnis aufgelöst wird, und seine Cross-Preset beantwortet die eine laufbasierte cmake-Probe (die LibreSSL-Prüfung) mit dem Ergebnis von OpenSSL.
* **zint** ist das unveränderte 2.16.0, gebaut von `lib/recipes/zint.sh` mit cmake (`ZINT_SHARED=OFF`, `ZINT_STATIC=ON`, `ZINT_FRONTEND=OFF`, `ZINT_USE_PNG=ON`, gelinkt gegen das libpng und zlib des Rezepts) nach `library/zint.xcframework`. Die Direktkompilierung aus der 2.4.2-Ära und ihr lokaler Patch (`patches/zint-2.4.2-mad.patch`) sind ausgemustert: `ZBarcode_Encode_and_Buffer`, das der Patch zurückportiert hatte, ist in 2.16 Upstream-API, und die `BARCODE_*`-Namen des Wrappers überleben als Aliase.
* **freetds** patcht die *installierten* Header, nicht die Quellen: `typedef int BOOL;` wird nach jeder Installation aus `sybdb.h` auskommentiert, weil Objective-C `BOOL` bereits typedefiert — die Bibliothek selbst muss das Typedef aber behalten, da die C-Quellen von dblib es verwenden.
* **postgres** baut nur die Client-Schnittstellen (`src/common`, `src/port`, `src/interfaces/libpq`, `src/bin/pg_config` und `src/include`) gegen die `openssl`-Installation pro Plattform (`--with-ssl=openssl` und die expliziten Modul-Flags aus), und führt dann `libpq.a`, `libpgcommon.a` und `libpgport.a` zu einem einzigen `libpostgres.a` für `postgres.xcframework` zusammen.

### Das Manifest (`library/manifests/<lib>.json`)

```json
{
  "library": "openssl", "version": "3.5.0",
  "source": { "url": "…", "sha256": "…" },
  "toolchain": { "xcode": "…", "clang": "…" },
  "headers": "ios",
  "flags": "configure: no-shared no-asm no-async; opt: -O3",
  "built": "…",
  "slices": { "ios": { "archs": "…", "sha256": "…" }, … }
}
```

`headers` hält fest, welche Plattform die generierten Header für das kanonische Include-Verzeichnis geliefert hat (freetds erzeugt `tds_sysdep_public.h` pro Plattform; die ios-Kopie ist die kanonische, wie das alte Layout es wählte).

---

## 2. Wie Xcode die Bibliotheken konsumiert

Jedes konsumierende Target linkt ein oder mehrere xcframeworks per Dateiverweis, nennt das kanonische `Compressor/library/<lib>/include` in seinen Header-Suchpfaden und führt eine Shell-Phase **Ensure Libraries** zuerst in seinen Build-Phasen aus:

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```

Die Phase ist ein No-op in Millisekunden, wenn das Manifest frisch ist, und baut sonst nur das Fehlende; `ENABLE_USER_SCRIPT_SANDBOXING = NO` ist auf jedem Target mit einer solchen Phase festgeschrieben. Die Plattformen sind auf `ios,simulator` festgeschrieben, weil noch kein Target für macOS baut — die macOS-Slices der Matrix sind bereit, sobald die UIKit-Entkopplung landet (siehe `ROADMAP.md` Track 2).

| Target | Linkt | Ensure-Phase |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`, `bzip2.xcframework`, `zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`, `openssl.xcframework`, `zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`, `openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`, `openssl.xcframework` | `freetds` |
| MADTdsClient | nichts aus Compressor (tds-Symbole kommen über MADTds) | — |
| MADBarcodes | `libpng.xcframework`, `zlib.xcframework`, `zint.xcframework` | `zint` |
| MAD Designer app | `openssl.xcframework` | `openssl` |

Header-Fakten, die man sich merken sollte: xcframeworks statischer Bibliotheken legen ihre Header **nicht** zuverlässig offen, also nennt jeder Konsument das kanonische Include-Verzeichnis ausdrücklich (Header werden zur Vollständigkeit des Archivs auch ins xcframework gebündelt). `zint.h`, `sqlite3.h` und `libpq-fe.h` (mit ihren Begleitheadern) sind öffentliche Framework-Header, deren Dateiverweise in die kanonischen Include-Verzeichnisse zeigen, weil öffentliche MAD-Header `<MADBarcodes/zint.h>` importieren, `MADSqlite3` `sqlite3.h` exportiert und `MADPostgres` `libpq-fe.h` exportiert.

Die alte `LIBRARY_SEARCH_PATHS`-Liste des MAD Viewer-Targets und Scrimpter (außerhalb des Workspace) bleiben bewusst unberührt: der Linkfehler des Viewers ist eine Produktentscheidung (siehe `BUGS.md`), keine Build-Verdrahtung.

---

## 3. Erster Lauf, Alltag und Versionsanhebungen

**Erster Lauf auf einem frischen Checkout** (oder nach dem Löschen von `Compressor/library/`): bauen Sie die Bibliotheken einmal, vor oder während des ersten Xcode-Builds:

```
Compressor/build.sh --all --platforms ios,simulator
```

Braucht Netzwerkzugriff für die Downloads und 30–90 Minuten beim ersten Build, größtenteils für die größeren Quell-Tarballs. Danach sind die Ensure-Phasen von Xcode No-ops und ein normaler Build läuft durch.

**Die Artefakte prüfen:**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**Eine Bibliothek anheben:** bearbeiten Sie ihre Zeile in `matrix.conf` (Version, URL, sha256 des neuen Archivs), dann `Compressor/build.sh --rebuild <lib>` und führen Sie die Testsuite des konsumierenden Frameworks plus `--verify` aus. Eine Bibliothek pro Commit. Wenn die neue Version eine cmake-Laufzeitprobe hinzufügt, scheitert das mariadb-Preset laut und benennt sie — beantworten Sie sie ausdrücklich, niemals durch Raten.

**Die Rezepte für zint/freetds/mariadb/postgres tragen Wissen pro Version** (Patches, Bearbeitungen installierter Header, Antworten auf Proben, Plugin-Typnamen, Installationslayout, Client-only-Teilbaumlisten). Wenn eine Version angehoben wird, sind das die Stellen, die erneut geprüft werden müssen.

---

## 4. Verifikationsbefehle

```sh
# slice inventory
for f in Compressor/library/*.xcframework/*/lib*.a; do lipo -archs "$f"; done

# version strings (each library embeds its matrix version)
strings Compressor/library/openssl.xcframework/*/libopenssl.a | grep -m1 "OpenSSL 3.5.0"

# sqlite correctness, against the BUILT framework (the H7 gate)
nm MADSqlite3.framework/MADSqlite3 | grep -c sqlite3Fts5Init     # present
strings MADSqlite3.framework/MADSqlite3 | grep -x 'DEFAULT_PAGE_SIZE=8192\|DQS=0'

# wiring cleanliness -- expect "" bases plus the MAD Viewer legacy list only
grep -rn 'LIBRARY_SEARCH_PATHS' --include='*.pbxproj' .

# the fresh-clone simulation (proves portability + on-demand building)
git archive HEAD | tar -x -C /tmp/fresh
cd /tmp/fresh
Compressor/build.sh --all --platforms ios,simulator     # bootstrap path (a)
xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Designer" -destination …
Compressor/build.sh --verify --all --platforms ios,simulator
# path (b): wipe library/ xcframeworks and build in Xcode only -- the ensure
# phases rebuild everything
```

---

## Anhang: der Zustand vor der Überarbeitung (zur Referenz)

Vor dem 2026-10-04 wurden die Bibliotheken von zwei überlappenden Generationen von Werkzeugen gebaut — `Compressor/build_*.sh`-Skripte pro Bibliothek und ein 1.293-zeiliger Treiber `compressor.sh` (nicht lauffähig: undefinierte Variablen verursachten 404-Downloads unter `set -e`; seine deklarierten Versionen waren jahrelang veraltet) — und die Ergebnisse wurden **eingecheckt**: 99 `.a`-Dateien (~350 MB), alle Header und die 9,2 MB große Amalgamation `sqlite3.c` unter `Compressor/library/`, plus 53 mitgelieferte Zint-Quelldateien in MADBarcodes. Xcode konsumierte sie rein per Dateiverweis mit SDK-abhängigen Suchpfaden, weshalb macOS nie verdrahtet werden konnte (`PBXFileReference.path` ist nicht SDK-abhängig — der Eintrag in `BUGS.md` ist durch die xcframework-Neuverdrahtung geschlossen). Die alten Skripte und die eingecheckten Bäume werden in der Aufräumphase entfernt, erst nachdem das neue System jede Kombination gebaut hat und die App baut und ihre Tests gegen die neuen Artefakte bestehen.

Die Ausgangsversionen, von denen die Matrix startete, und ihre Zielaktualisierungen sind in `TASKS.md` §6 festgehalten.
