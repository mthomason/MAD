---
layout: default
lang: de-DE
title: "Die Engine unter Windows bauen"
description: "Die festgeschriebene Clang- und GNUstep-Toolchain und der native Windows-Engine-Build."
---

# Die MAD-Engine unter Windows kompilieren — Architektur und Entscheidungsaufzeichnung

Diese Seite hält den Windows-Engine-Build fest: die festgeschriebene Toolchain, den Framework-Port und seine Shims und den Einstiegspunkt `Windows/Engine/build.ps1`. Die Anwendungsanleitung steht unter `/windows.html`.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

Geschrieben am 2026-11-18 gegen `master` für den Branch `windows-engine` (Phase 2 des Windows-PoC). Der Windows-Build ist der Geschwisterbuild von `Linux/`: die Objective-C-Frameworks der headless Engine, nativ unter Windows mit Clang gegen GNUstep Base kompiliert, sodass dieselbe Engine, die die macOS-App und die Linux-CLI ausführt, unter Windows laufen kann. Dieses Dokument ist der technische Begleiter zu `Linux/README.md` / `docs/developers/build/linux.md`; es hält das Toolchain-Rezept, warum jedes Stück festgeschrieben ist und die Entscheidungen dieses Inkrements fest.

---

## 1. Was dies ist und was nicht

Das Ziel ist ein nativer Windows-MAD-Designer (WPF auf .NET 10 LTS), der die vorhandene headless Objective-C-Engine wiederverwendet, nativ für Windows kompiliert. Der Engine-Build landet unter `Windows/`, einem Geschwister von `Mac/` und `Linux/`; die WPF-App folgte in den Phasen 5–6f (`Windows/App`; §6e–§6i).

Das Inkrement Phase 2b bewies die Toolchain und den Framework-Port. Die erste Phase 2 baute **MADDataStructures** und **MADFoundation** und führte einen Smoke-Test aus. Phase 2b fügte **MADAPI** (die transitive Abhängigkeit, die MADSqlite3 hereinzieht) und **MADSqlite3** hinzu, kompilierte die festgeschriebene SQLite-Amalgamation in eine statische Bibliothek und portierte die Linux-Testsuiten für MADDataStructures, MADFoundation und MADSqlite3 (GNUstep `Testing.h` + `MADTestSupport.h`). Sie baute noch nicht die übrigen headless Frameworks, die CLI oder die App.

---

## 2. Das Toolchain-Rezept und warum jedes Stück festgeschrieben ist

Die Zusammenfassung (dieser Abschnitt steht für sich):

### 2.1 Compiler: Clang 20.1.8

Der Startabsturz von Phase 1 (`0xC0000005` in jeder Foundation-Binärdatei) war eine Laufzeitregression in den gleitenden Master-Komponenten von GNUstep — die sieben Festschreibungen in §2.3 beheben sie —, kein Codegen-Fehler von Clang 23. Clang 20.1.8 ist der CI-getestete Compiler und Teil des bewiesenen Rezepts; Clang 22/23 mit den Festschreibungen wurde nicht getestet. Das ist eine Festschreibung, keine Vorliebe; heben Sie LLVM nicht ohne einen neuen Machbarkeitstest an.

### 2.2 Die STL-Gate-Überschreibung

Diese Maschine liefert Visual Studio 2026 (18.12.0), dessen MSVC-STL hart „Clang 22 or newer“ verlangt (`_MSVC_STL_UPDATE 202609L`, `yvals_core.h:923`):

```c
#elif defined(__clang__)
#if __clang_major__ < 22
_EMIT_STL_ERROR(STL1000, "Unexpected compiler version, expected Clang 22 or newer.");
```

Die Überschreibung `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH` ist die eigene Notluke der STL. Sie ist als harmlos bewiesen: ein C++-Programm mit `<map>` kompiliert und läuft mit Clang 20.1.8 + der Überschreibung, ebenso die vollständige Toolchain und MADs `.mm`-Dateien (die `<map>`/`<vector>` einschließen). Sie wird auf den Toolchain-Build (`Engine/toolchain/stl-gate-override.patch`) und auf jede Objective-C++-Übersetzungseinheit im Framework-Build angewandt.

### 2.3 Die sieben festgeschriebenen GNUstep-Revisionen (die Regression des gleitenden Masters)

`gnustep/tools-windows-msvc` klont den neuesten Master jeder Komponente (`TAG=` ist in seinen Phasenskripten leer). Seine CI (`.github/workflows/ci.yml`) baut und paketiert die Toolchain, **führt aber nie eine Binärdatei aus**, also blieb eine Laufzeitregression unbemerkt. A/B-Tests isolierten sie:

| Komponente | 11-14 (läuft) | 11-17/18 master (stürzt ab) |
|---|---|---|
| libobjc2 | `a21ae931` | `762f9d7` |
| gnustep-base | `24654296` | `ff647838` |
| libdispatch | `22798930` | `20b4c8b2` |
| gnustep-make | `e7c0730d` | `8fa108c7` |
| libffi | v3.8.0 | v3.8.1 |
| libiconv | v1.19 (`a536e24a`) | v1.19.1 |

Die Behebung besteht darin, die sieben bekannt guten 11-14-Revisionen festzuschreiben (`Engine/toolchain/revision-pins.patch`). Der Treiber selbst ist ebenfalls auf Commit `54d08e57` festgeschrieben (sein Master gleitet und darf nicht verfolgt werden). Beide Fakten sind in `Windows/Engine/toolchain.conf` festgehalten.

### 2.4 Die drei nicht offensichtlichen Anforderungen des Build-Wrappers

Das `build.bat` der Toolchain muss aus der Entwicklerumgebung `vcvars64` laufen, mit `BASH` auf die Shell von MSYS2 gesetzt und mit **absolutem** `build.bat`-Pfad, ohne `PATH` zu bearbeiten (der `PATH` von vcvars64 ist ~2500 Zeichen lang und bricht die Namensauflösung von cmd). Von Git Bash aus rufen Sie `cmd` mit `cmd //c` auf (nicht `cmd /c`); von PowerShell aus ist `cmd /c` richtig. `Engine/toolchain/bootstrap.ps1` kapselt alle drei.

---

## 3. Der Build-Einstiegspunkt

`Windows/Engine/build.ps1` reproduziert das Rezept aus dem Repository:

1. **Voraussetzungsprüfung** — Clang 20.1.8, lld, CMake, Ninja, MSYS2, git, curl, tar, `llvm-lib`, VS 2026, das Windows SDK, NASM.
2. **Idempotenter Toolchain-Bootstrap** — `Engine/toolchain/bootstrap.ps1` klont den festgeschriebenen Treiber, wendet die beiden Patchdateien an und baut GNUstep aus dem Quellcode nach `C:\GNUstep` (konfigurierbar; ~20–30 min beim ersten Lauf).
3. **SQLite-Bibliotheksbuild** — die Amalgamation 3.53.3 aus `Engine/libraries.conf` herunterladen, ihre sha256 prüfen, entpacken, `sqlite3.c` mit der Optionsliste aus `Compressor/sqlite3.xcconfig` kompilieren und mit `llvm-lib` in ein COFF-`sqlite3.lib` archivieren.
4. **Framework-Build** — MADDataStructures, MADFoundation, MADAPI und MADSqlite3 kompilieren (plus die Shims in `Engine/Compat`).
5. **Test-Build** — ein Programm pro portierter Testdatei kompilieren und linken (plus den Smoke-Test).
6. **Testlauf** — den Smoke-Test und jede Suite ausführen; bei jedem Fehlschlag mit Nicht-Null beenden.

Die Kompilier-Flags der Frameworks entsprechen dem Debug-Profil des Linux-Builds: GNUsteps `gnustep-config --objc-flags` unter `--enable-debug-by-default` (das die Linux-Toolchain verwendet) trägt `-DDEBUG`, also übergibt `build.ps1` `-DDEBUG=1` an jede Übersetzungseinheit — Bibliothek wie Test — und definiert **nicht** `NS_BLOCK_ASSERTIONS`, sodass `NSAssert` genau wie unter Linux aktiv bleibt.

**Entscheidung — `build.ps1` treibt Clang direkt, nicht über CMake.** Die Objective-C-Sprachunterstützung von CMake unter Windows ist für die Kombination kaputt, die dieses Rezept erfordert (der GNU-Treiber `clang` mit Ziel `x86_64-pc-windows-msvc`): ihre Objective-C-Linkprobe übergibt GNU-ld-Flags (`--out-implib`, `-nostdlib`, `-nostartfiles`) an `lld-link` und hängt `.lib` an Bibliotheksnamen an, die bereits mit `-l` präfigiert sind, sodass das Linken scheitert (`undefined symbol: $_OBJC_CLASS_NSObject` und Abschnitts-GC-Fehler für ObjC-Metadaten). Das bewiesene Rezept sind direkte `clang`-Aufrufe — `compile-mad.sh` / `link-and-run.sh` der Machbarkeitsphase —, und `build.ps1` ist dieses Rezept, aufgeräumt und idempotent gemacht. Die Quelllisten pro Framework leben weiterhin in `Engine/cmake/<Name>Sources.cmake` (das kanonische, CMake-fähige Inventar mit Ausschlussgründen), und `build.ps1` liest sie zurück, sodass die beiden nicht driften können; ein echter CMake-Build kann sie unverändert konsumieren, sobald die Windows-Objective-C-Unterstützung von CMake landet.

---

## 4. Was kompiliert und die Windows-Shims

| Framework | Windows-Build | Ausgeschlossen und warum |
|---|---|---|
| MADFoundation | 26 von 27 (+ `madlib.c`) | `MADKeyChain` (Security.framework; unter Linux bereits ausgeschlossen) und `BDHost` (Reverse-DNS über POSIX-Sockets — `sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`; braucht einen Winsock2-Port). Der Umbrella geht mit `MADKeyChain`. |
| MADDataStructures | alle 17 | (`madmap.cpp` ist auch nicht im Xcode-Target) |
| MADAPI | 8 von 11 | die drei Verbindungs-View-Controller (`MADConnectionViewController`, `MADConnectionSQLGenericViewController`) — UIKit, nicht headless. Kein eigenes Deliverable von Phase 2b; die transitive Abhängigkeit von MADSqlite3. |
| MADSqlite3 | alle 26 | fünf verwaiste `.m`-Dateien, die auch nicht im Xcode-Target sind (benannt in `Engine/cmake/MADSqlite3Sources.cmake`) |

`Windows/Engine/Compat/` ist eine Kopie von `Linux/Compat`, für Windows angepasst:

* **`syslog.h`** — No-op-`syslog()` und die `LOG_*`-Konstanten für den Nicht-Apple-Zweig von `madlog` (`madlog.h` schließt `<syslog.h>` ein, wenn `__APPLE__` nicht definiert ist).
* **`pthread.h`** — `pthread_mutex_t` (rekursiv) über einer Windows-`CRITICAL_SECTION` für die Zustandssperre von `MADOperation.m`.
* **`NSData+ReadingOptions` entfällt** — der festgeschriebene GNUstep-Master trägt `NSDataReadingOptions` und `-options:error:` bereits; der Linux-Shim (der sie für gnustep-base 1.31.1 neu deklariert) wäre unter Windows eine doppelte Schnittstelle.
* **`NSPropertyListSerialization+Stream.m`** erhält einen ausdrücklichen `#import <Foundation/NSData.h>` — eine Windows-Abweichung der Header-Einschlussreihenfolge (Linux' Header erreichen NSData zufällig zuerst; Windows' tun es nicht).
* **`MADCompat.h`** (das force-included Prelude) lässt den Block `<endian.h>` + `htonll`/`ntohll` weg — weder MADFoundation noch MADDataStructures verwendet ihn (per grep geprüft), und `<endian.h>` existiert unter Windows nicht. Die Treiberschicht (`MAD`) wird einen Windows-Byte-Order-Shim brauchen, wenn sie portiert wird.
* **`MADCompat.h`** erhält zudem ein `static inline strlcat` — die Windows-UCRT hat kein `strlcat`/`strlcpy` (BSD-/Apple-Schreibweisen; glibc 2.38+ liefert sie, weshalb Linux keinen Shim braucht), und `MADQueryCacheAddRow.m` greift danach.
* **`NSURL+FileSystem.m`** beantwortet `-fileSystemRepresentation` mit `self.path.UTF8String` statt mit GNUsteps `GSNativeChar*`-Schreibweise (UTF-16 unter Windows), was den Pfad von `sqlite3_open_v2` brach, wenn er als `const char *` maskiert wurde.

Die anderen Linux-Shims werden unverändert übernommen, da die GNUstep-Base unter Windows und Linux dieselbe 1.31.x-Linie ist.

---

## 5. Die unvermeidlichen Änderungen an geteilten Quellen

Zwei Änderungen an geteilten Quellen waren nötig, beide minimal und portabel (die Linux-CI und die Apple-Suiten sind die Gates):

### 5.1 Die Umbenennung `itoa`/`ltoa`/`ultoa` in `madlib.c`

`MADFoundation/Source/madlib.c` definiert `itoa`/`ltoa`/`ultoa`, die mit den dreistelligen nicht-standardisierten Namen derselben Schreibweise in der Windows-UCRT kollidieren. Sie werden in `mad_itoa`/`mad_ltoa`/`mad_ultoa` umbenannt, und jeder Aufrufer aktualisiert:

* `MADFoundation/Source/madlib.{c,h}` — die Definitionen und Deklarationen; lässt zudem `#import <strings.h>` weg (ungenutzt und unter Windows abwesend).
* `MADFoundation/MADFoundationTests/madlibTests.m` und `Linux/Tests/madlibTests.m` — die Tests.
* `MAD/Source/model/MADModelQueryTable.m`, `MAD/Source/rptq/RptqQueryTable+Extras.m` (`ltoa`) und `MADSqlite3/Source/MADDataTableFast.m`, `MADSqlite3/Source/MADQueryCacheAddRow.m` (`ultoa`).

Dies ist eine rein mechanische Umbenennung, verhaltensneutral auf Apple und Linux. `uitoa`, `reverse`, `count_digits` und `count_digits_ul` bleiben unberührt (sie kollidieren nicht mit der UCRT). Der `itoa`-Verweis in `MADExplorer` steht in einem auskommentierten Block und ist kein Aufrufer.

### 5.2 Der Cursorzeiger der schnellen Aufzählung

`MTStack.m`, `MTQueue.m` und `MTLinkedList.m` speichern ihren Cursor-Knotenzeiger von `countByEnumerating…` in `NSFastEnumerationState.extra[0]`, gecastet über `unsigned long`. Das sind 32 Bit unter Windows (LLP64), aber 64 unter Linux/Apple (LP64), also wurde der Zeiger abgeschnitten, und die Aufzählung über mehrere Batches (jede Sammlung mit mehr als einem Stapelpuffer voller Elemente) stürzte ab oder lieferte Müll. Die drei Dateien kopieren den Zeiger jetzt mit `memcpy` in `extra` (korrekt auf LP64 und LLP64) und halten ihn in einem `__unsafe_unretained` lokalen Wert — die Sammlung besitzt die Knotenkette, die den Aufruf überlebt, also ist der geliehene Zeiger das ehrliche Besitzmodell auf jeder Plattform. Die Änderung ist auf Apple/Linux verhaltensneutral (dieselben Zeigerbytes wandern durch).

---

## 6. Bekannte Lücken und nächste Inkremente

> Dieser Abschnitt hält die Lücken der Phasen 1/2 fest, wie sie damals standen. Die Phasen 3a–6e schlossen alle außer den akzeptierten; siehe §6b–§6h und `Windows/README.md` für den aktuellen Stand.

* **`BDHost`** (Reverse-DNS) und **`MADKeyChain`** (Security.framework) sind ausgeschlossen; `BDHost` braucht einen Winsock2-Port, `MADKeyChain` hat noch kein Windows-Schlüsselbund-Äquivalent. `BDHostTests` ist aus demselben Grund nicht unter Windows registriert (es kann ohne `BDHost.m` nicht linken) — festgehalten, nicht übersprungen.
* **Die übrigen headless Frameworks** (`MAD`, die Treiber, `MADFileManager`, `MADCocoaExtensions`, …) und **die CLI** sind die nächsten Inkremente.
* **Die WPF-App** ist eine spätere Phase.

## 6b. Phase 3a — die Frameworks, der Archiv-Stack und die CLI

Phase 3a baut die übrigen headless Frameworks, die C-Bibliotheken des `.mad`-Containers und `mad.exe`:

* **Frameworks.** `MADCocoaExtensions` (7 Dateien), `MADFileManager` (10) und `MAD` (168) schließen sich dem Satz von Phase 2/2b an, aus denselben Linux-Quelllisten und mit denselben Ausschlussgründen (der UI-Schwanz, `MADocument`, die Schlüsselbundoperationen, `MADCloud`). `MADDirectoryMonitor` kompiliert gegen einen inerten `sys/inotify.h`-Shim — die CLI ist einmalig und braucht keine Änderungsereignisse.
* **C-Bibliotheken.** `zlib` 1.3.2, `bzip2` 1.0.8 und `libarchive` 3.8.9 (die Linux-Festschreibungen) bauen in `build.ps1`: zlib und bzip2 direkt mit clang + `llvm-lib`, libarchive über CMake + clang-cl (zlib/bzip2 hinein; xml2/lzma/zstd/lz4/openssl und die Werkzeuge hinaus), passend zu `Linux/lib/libraries.sh` / Compressor. Der Barcode-Stack — `libpng` 1.6.59 und `zint` 2.16.0 — baut auf dieselbe Weise (beide über CMake + clang-cl), sodass `MADBarcodes` auch hier kompiliert und rendert.
* **CLI.** `CLI/Source` → `mad.exe`, whole-linked. `inspect`, `schema`, `query` und `refresh` (76 Zeilen) laufen auf `London.portable.mad`; alle sechs Export-Digests passen byteweise zu den Mac-/Linux-Pins, und `write --reproducible` schreibt dasselbe 16261-Byte-Dokument (`09815b24…`), das der Mac und Linux schreiben.

### 6b.1 Die beiden Windows-only-Laufzeitbehebungen (Phase 3a final)

* **`write --reproducible` (das 116-Byte-Speicherlesen).** Das `open`/`read` des Archiv-Writers ging über `Windows/Engine/Compat/unistd.h`, dessen `open` auf die UCRT `_open` abbildete — die standardmäßig im *Text*-Modus arbeitet. Ein SQLite-Speicher enthält bei Offset 116 ein `0x1A`-Byte (Ctrl-Z); `_read` im Textmodus stoppt dort als EOF, also sah der Writer 116 von 663552 Bytes und gab ein 518-Byte-Archiv aus. Der Shim ORiert jetzt `_O_BINARY` in die Flags, sodass `open`/`read` das POSIX-Verhalten byteweise haben. Auf den Windows-Shim begrenzt; die Apple-/Linux-Bytes sind unverändert. Festgelegt durch `MADArchiveManagerTests` (5 Tests, 0 Bedarfe).
* **Wiederholter `export` in einem Benutzer (die `.mdcache`-Umbenennung).** Die Zeilen-Cache-`.mdcache` ist ein Plist, das über `NSInputStream` gelesen und dann atomar neu geschrieben wird. `Compat/NSPropertyListSerialization+Stream.m` öffnete den bereits offenen Stream ein zweites Mal; GNUsteps win32-`GSFileInputStream -open` ruft jedes Mal `CreateFileW` (`FILE_SHARE_READ`) auf und überschreibt `_loopID`, wodurch das erste Handle leckt. Dieses Handle blockierte das spätere `MoveFileEx` über die `.mdcache` (`"being used by another process"`), also scheiterte der zweite Export. Der Shim liest den offenen Stream jetzt, ohne ihn erneut zu öffnen (Apples Vertrag), und zwei Exporte in einem Benutzer gelingen beide.

### 6b.2 Das Testinventar

Die kopierten Suiten MAD/MADFileManager/MADCocoaExtensions/MADAPI sind in `build.ps1` verdrahtet (Fixture-Pfade für `Windows/Engine/Tests` angepasst): **107 portierte Suiten + der Smoke-Test, 966 Tests, 6 Bedarfe, 5 Übersprünge, 0 Fehlschläge**. Die sechs Bedarfe entsprechen den Plattformlücken des Linux-Images: `MADDirectoryMonitorTests` (3 — der Windows-Monitor ist inert), `MADStoreTests` (1 — Core Data + `MAD.momd`) und `RptqStoreContextTests` (2 — der Konverter-/Dokumentpfad). Vier MAD-Suiten, die die Treiber von Phase 3b brauchen, sind aufgeschoben und in `build.ps1` festgehalten: `MADDatabaseDriverDispatchTests`, `MADQueryFullTests`, `MADSQLParserTests` und `MADQueryMaxFieldLengthTests`. Die fünf Übersprünge sind der SQLite-Benchmark in seiner Standardgröße.

Die zusätzlichen Windows-`Compat`-Shims sind `unistd.h`, `dirent.h`, `libgen.h`, `sys/{unistd,fcntl,inotify}.h`, plus `MADCompat.h` erhält `strlcpy`, die Modusmakros `S_IS*`/`S_IR*`, `ssize_t`/`mode_t`, `M_PI`, `arc4random` und `gmtime_r`. Die zusätzlichen minimalen Änderungen an geteilten Quellen (alle `#if __APPLE__`-sicher oder byte-neutral unter Linux; die Linux-CI und die Apple-Suiten sind die Gates):

* `MADReportSectionRepresentation.m` lässt ein leeres `@finally` weg (Clang 20.1.8s GNUstep-2.2-+-ARC-Codegen stürzte darauf ab).
* `madtar.m` erhält einen `_WIN32`-mtime-Zweig (das `struct stat` der UCRT hat `st_mtime`, kein `st_mtim`).
* `MADArchiveManager.m`, `MADStore.m` und `MADCLIInspect.m` verwenden `NSString -UTF8String`, wo sie `-fileSystemRepresentation` nahmen (GNUsteps NSString-Schreibweise liefert unter Windows UTF-16).
* Das `+Identifier:` von `MADDatabaseConnection+Constructor.m` gibt die vier Dokumentformat-Konstanten direkt zurück, sodass ein Prozess, der nur Sqlite3 linkt, eine gespeicherte `driverID` trotzdem auf einen Typ abbilden kann. (Phase 3b entfernte diesen Guard — siehe §6c.)

## 6c. Phase 3b — die Treiber, BDHost und die Live-Fixtures

Phase 3b fügt die vier Datenbanktreiber und die C-Bibliotheken hinzu, die sie linken:

* **C-Bibliotheken** (`Windows/Engine/libraries.conf`, `build.ps1` §3c): OpenSSL 3.5.9 (Strawberry Perl + `VC-WIN64A` + `nmake`, statisch), FreeTDS 1.4.27 (CMake `db-lib`, `ENABLE_MSDBLIB`, `sybdb.h`-BOOL-Bearbeitung), MariaDB Connector/C 3.4.11 (CMake `mariadbclient`, Auth-Plugins statisch), libpq 17.11 (**Meson + MSVC `cl.exe`**, `libpq_st` + `libpgcommon_shlib` + `libpgport_shlib` zu einem COFF-`libpq.lib` verschmolzen). PostgreSQL 17 ließ den MSVC-Build fallen, also ist Meson sein Windows-Pfad; `cl.exe` (nicht `clang-cl`) wird verwendet, weil PostgreSQLs Meson `cc.get_id() == 'msvc'` prüft und `clang-cl` `clang-cl` meldet, wodurch `win32gettimeofday.c`/`dirent.c` und das Include-Verzeichnis `win32_msvc` still wegfallen. Meson und Strawberry Perl sind dokumentierte Voraussetzungen.
* **BDHost** — `MADFoundation/Source/BDHost.m` erhält einen `#elif defined(_WIN32)`-Zweig über `winsock2.h`/`ws2tcpip.h` (`WSAStartup` einmal, `getaddrinfo`/`getnameinfo`, nur IPv4); `+ipAddresses`/`+ethernetAddresses` werden unter Windows auskompiliert. `BDHostTests` besteht 3/3.
* **Treiber** — vier Listen `cmake/*Sources.cmake` (18/1/3/4 Dateien) und Header-Shims für `<MADTds/sybdb.h>`, `<MADTdsClient/MADTdsClient.h>` und `<MADPostgres/libpq-fe.h>` usw. `MADTdsDb.m` wird normal gelinkt (sein globales `err_handler` kollidiert mit dem von `MADDatabaseSQLServer.m`). Der `+Identifier:`-Guard aus Phase 3a wird entfernt — die Registratur-Suche funktioniert mit allen vier gelinkten Treibern, festgelegt durch `MADDatabaseDriverDispatchTests` (9/9).
* **Testinventar** — **130 Suiten, 1,313 Tests (einschließlich des Smoke-Tests), 6 Bedarfe, 5 Übersprünge (48, wenn die Live-Container nicht laufen), 0 Fehlschläge** (das Barcode-Inkrement fügte `MADBarcodesTests` und `MADBarcodeExportTests` hinzu; die Image-Schließung fügte `MADImageElementTests` und `MADImageExportTests` hinzu). Live-Suiten gegen die lokalen `127.0.0.1`-Container: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests` 29/29, `MADPostgresLiveTests` 14/14. CLI `mad refresh` liefert 50 MySQL / 20 TDS / 25 PostgreSQL-Zeilen.

## 6d. Phase 4 — der stdio-JSON-Prozessvertrag

Phase 4 fügt `mad serve` hinzu, die langlebige Prozessgrenze, die die WPF-Shell verwenden wird. Er liest zeilengetrenntes JSON auf der Standardeingabe und schreibt pro Anfrage eine zeilengetrennte JSON-Antwort auf der Standardausgabe; Diagnosen bleiben auf der Standardfehlerausgabe, sodass sich die beiden nie vermischen. Die Wire-Form verwendet den vorhandenen JSON-Vertrag des Projekts wieder, statt einen parallelen zu erfinden.

**Anfrage / Antwort** — ein JSON-Wert pro Zeile, UTF-8, `\n`-terminiert:

```text
request:   { "id": <int|string>, "method": "<name>", "params": { … } }
ok:        { "id": <id>, "ok": true,  "result": { … } }
error:     { "id": <id|null>, "ok": false, "error": { "code": <int>, "message": "…" } }
```

`id` wird vom Client gewählt und zur Korrelation zurückgegeben; eine fehlerhafte Anfrage antwortet mit `"id": null`. `error.code` ist der Exit-Code der CLI (MADCLI.h): 1 Nutzung/Protokoll, 2 schlechtes Dokument, 3 Datenbank nicht erreichbar, 4 Abfrage gescheitert, 5 Export gescheitert. Eine fehlerhafte Zeile, eine unbekannte Methode, ein fehlender Parameter und eine unerwartete Engine-Exception antworten alle mit `ok: false` und einer Meldung — nie mit einem Traceback —, und die Sitzung läuft weiter.

**Methoden:**

| Methode | Parameter | Ergebnis |
|---|---|---|
| `open` | `path`, optional `host`/`port`/`database` | `handle`, `filename`, `driver` |
| `create` | `path`, `driver` + Verbindungsfelder, optional `credentials` | `handle`, `filename`, `driver` (das erzeugte Dokument) |
| `test-connection` | `driver` + Verbindungsfelder, optional `credentials` | `tableCount` |
| `describe` | `handle` | `driver`, `columns` (key/name/table/type), `tables` (Name + Felder) |
| `connection` | `handle` | `driver` + `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`, `driver` + Verbindungsfelder, optional `credentials` | `{}` |
| `query` | `handle` | `sql` |
| `query-model` | `handle` | `driver`-Token, `sql`, `sqlSourceText`, `tables`/`links`/`predicates`/`groups` (mit Speicherkennungen) |
| `add-table` | `handle`, `table` (Schemaname) | das vollständige `query-model` |
| `remove-table` | `handle`, `table` (Abfragetabellen-ID) | das vollständige `query-model` |
| `add-link` | `handle`, `leftField`, `rightField` (Feld-IDs) | das vollständige `query-model` (Left Outer Join als Standard) |
| `set-link-type` | `handle`, `link`, `type` | das vollständige `query-model` |
| `swap-link` | `handle`, `link` | das vollständige `query-model` |
| `delete-link` | `handle`, `link` | das vollständige `query-model` |
| `add-predicate` | `handle`, `leftField`, `operator`, `value` | das vollständige `query-model` |
| `remove-predicate` | `handle`, `predicate` | das vollständige `query-model` |
| `add-group` | `handle`, `field`, `sort` | das vollständige `query-model` |
| `remove-group` | `handle`, `group` | das vollständige `query-model` |
| `validate-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` (die Zählungen des Plans) |
| `apply-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` |
| `refresh` | `handle`, optional `rows`/`credentials` | `rowCount`, `elapsed` |
| `export` | `handle`, `format`, optional `path`/`deterministic` | `format` + `data` (die Bytes des Exporters) oder `path` + `bytes` |
| `write` | `handle`, `out`, optional `reproducible` | `path`, `bytes` — serialisiert das lebende Dokument |
| `shutdown` | — | `{}`, dann beendet sich der Prozess mit 0 |

Die Verbindungsmethoden (`create`, `test-connection`, `connection`, `apply-connection`) nehmen ein `driver`-Token — `sqlite3` | `mysql` | `sqlserver` | `postgres` — und treiberspezifische Felder: SQLite nimmt `file`; die Server-Treiber nehmen `host`/`port`/`database` (SQL Server nimmt zudem eine optionale `server`-Instanz), plus den vorhandenen `credentials`-String (`user:password`). Sie verwenden `createDocumentAtURL:`, `MADDatabase` (connect/getTables/close) und `applyDatabaseConnection:` der Engine wieder — dieselben Aufrufe, die das Verbindungsfenster des Macs macht.

`export` ist die Exportnaht (`MADReportExporting` / `MADReportExporterRegistry`), kein neues Schema: `format: "json"` gibt die exakten `mad.report/1`-Bytes zurück, die `mad export --format json` schreibt (`MADReportExporterJSON` — `columns` und `rows`), und `format: "csv"` die RFC-4180-Bytes. Ein Format, das dieser Build nicht erzeugen kann (zum Beispiel `pdf` außerhalb Apples), antwortet mit `error.code` 5 und dem Grund des Exporters. Die `columns` von `describe` sind dieselben `mad.report/1`-Spalten (`MADReportExportSource`), und seine `tables` sind das gespeicherte Datenbankschema, das `mad schema` ausgibt. `open` wendet `host`/`port`/`database` so an, wie es die einmaligen Verben tun, sodass ein eingechecktes Dokument für die Sitzung gegen einen anderen Server laufen kann. `write` serialisiert jetzt das lebende Sitzungsdokument, statt `sourceURL` erneut zu öffnen, sodass eine in der Sitzung angewandte Verbindung persistiert wird. Das Dateiende auf der Standardeingabe ist ein sauberer Shutdown, ebenso `shutdown`.

Die Methoden `query-model`/`add-table`/…/`apply-sql` sind die Erweiterung des Query-Arbeitsbereichs aus Phase 6b. Der ursprüngliche `serve`-Vertrag legte die Abfrage nur als ihr erzeugtes `sql` offen, das der Mac durch Mutieren der `RptqQuery`-Objekte in-process ableitet; die WPF-App hat kein solches In-Process-Handle, also schließen diese Methoden diese Lücke. `query-model` liest das vollständige Abfragemodell — Tabellen/Felder/Links/Prädikate/Gruppen mit ihren Speicherkennungen, den eingegebenen `sqlSourceText` und das Treibertoken —, und jede Mutationsmethode antwortet in derselben Form, sodass der Client seinen Snapshot atomar ersetzt. Die Mutationen rufen dieselben Fabriken und `MADSQLQueryDocument`-Helfer auf, die `MADMacQueryViewController` des Macs verwendet (`newQueryTableForSchemaTable:`, `newQueryLinksWithLeftField:`, `addQueryGroupWithQueryField:`, `removeGroupWitObjectID:`, …), und `validate-sql`/`apply-sql` durchlaufen den vorhandenen Pfad `MADSQLParser` → `MADSQLStatementResolver` → `MADSQLQueryCompiler` unverändert. `query` gibt jetzt zuerst das SQL über alle Felder zurück und fällt auf das Select der aktiven Felder zurück, passend zu `generatedSQLString:` des Macs — sodass ein frisches Dokument ohne Berichtselemente trotzdem SQL liefert.

**Client und Tests.** `Windows/Client/` enthält den .NET-10-Konsolen-Abnahmeclient (`Mad.Client`) und die xunit-Suite (`Mad.Client.Tests`), beide durch `Windows/global.json` festgeschrieben. Der Client startet `mad serve` und deckt die sieben Methoden ab; die Tests üben den Erfolgspfad über `CLI/Fixtures/London.portable.mad` (open → describe → query → refresh 76 Zeilen → export json/csv → shutdown, Exit 0, kein Waisenprozess), fehlerhafte Anfragen, eine unbekannte Methode, ein schlechtes Dokument, ein nicht verfügbares Format und den Prozess-Shutdown.

## 6e. Phase 5 — der Beweis der WPF-Shell

Phase 5 fügt die erste WPF-App auf der Prozessgrenze von Phase 4 hinzu: eine `net10.0-windows`-Shell unter `Windows/App/`, die beweist, dass die Engine aus einer echten UI läuft. Sie verwendet `Mad.Client` unverändert wieder und fügt einen asynchronen `EngineService` hinzu (ein `SemaphoreSlim` serialisiert das einthreadige Zeilenprotokoll; jeder blockierende Aufruf läuft im Thread-Pool), eine handgebaute MVVM-Schicht (`ObservableObject`, `RelayCommand`, `AsyncRelayCommand`) und ein `DocumentViewModel`, das `MADMacDocument` des Macs für das erste Stück spiegelt: open → describe → query → refresh → export.

Die Shell hat den Rahmen mit drei Arbeitsbereichen (MAD Query / Designer / Viewer). Query zeigt das gespeicherte Schema und das erzeugte SQL; Viewer zeigt die aktualisierten Zeilen in einem `DataGrid` (gespeist durch Parsen von `mad.report/1` in eine `DataTable`) und exportiert CSV/JSON; Designer ist ein Platzhalter von Phase 6. Beim Start öffnet sie automatisch `CLI/Fixtures/London.portable.mad` (überschreibbar mit `MAD_DOCUMENT`), sodass sie mit null Klicks demonstriert. Das About-Fenster (Overview / License & Notice / Acknowledgements) rendert das Windows-Abhängigkeitsregister aus `ThirdParty/Licenses/Windows/` und das Relink-Angebot — den Windows-Komponentensatz, nie den Apple-Satz.

Die Abnahme wird headless durch `Windows/App/Mad.Designer.Windows.Tests` (xunit) verifiziert: London öffnen → describe (21 Spalten / 11 Tabellen / Treiber „Sqlite 3“) → refresh 76 Zeilen → export json (76 Zeilen) / csv (78 Zeilen) → sauberer Shutdown ohne Waise, plus der `mad.report/1`-Parser und die Prüfungen des Lizenzregisters. App und Tests bauen und laufen auf `net10.0-windows` (durch `Windows/global.json` festgeschrieben); die Linux-CI ist nicht betroffen (sie baut nie .NET).

## 6f. Phase 6c — das Berichtslayoutmodell (Designer)

Phase 6c erweitert `serve` um das Berichtslayoutmodell, das der Designer-Arbeitsbereich bearbeitet, mit demselben granularen Muster wie die query-model-Methoden von 6b. `layout-model` liest den vollständigen Snapshot; jede Mutationsmethode mutiert die vorhandenen `RptqDocumentSection`/`RptqDocumentElement`-Objekte und antwortet mit demselben Snapshot, sodass der Client seinen Zustand atomar ersetzt. Barcode ist Teil des Modells (das Barcode-Schließungs-Inkrement fügte die Elementart, ihre Inhaltsbearbeitungen, den Symbologiekatalog, eine engine-gerenderte Vorschau und den WPF-Composer hinzu — §6j; die Image-Schließung folgte mit PNG-Inhalt und dem WPF-Dateiwähler — §6k). Farben sind aufgeschoben (kein portabler Farbtyp im headless Modell). Undo/Redo ist clientseitig.

| Methode | Parameter | Ergebnis |
|---|---|---|
| `layout-model` | `handle` | `paperSize`, `sections[]`, `elements[]`, `fields[]` |
| `add-element` | `handle`, `kind` (`label`\|`data-field`\|`aggregate`\|`image`\|`line`\|`barcode`), `section`, `x`, `y`; `data` für ein Bild (base64 PNG) | der vollständige Snapshot |
| `remove-elements` | `handle`, `elements: [id…]` | der vollständige Snapshot |
| `duplicate-elements` | `handle`, `elements: [id…]` | der vollständige Snapshot |
| `move-elements` | `handle`, `elements: [id…]`, `section` | der vollständige Snapshot |
| `set-element-geometry` | `handle`, `elements: [{id,x,y,w,h}…]` | der vollständige Snapshot |
| `set-element-content` | `handle`, `element`, `content{text,field,function,scope,group,barcodeType,humanReadable,borderStyle,data}` (`data` ist das base64-PNG eines Bilds; leer löscht es) | der vollständige Snapshot |
| `set-element-typography` | `handle`, `elements: [id…]`, `style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | der vollständige Snapshot |
| `set-element-box-model` | `handle`, `elements: [id…]`, `box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | der vollständige Snapshot |
| `set-section` | `handle`, `section`, `{height,visible,pageBreak}` | der vollständige Snapshot |
| `set-paper-size` | `handle`, `paperSize` (`MTPaperType` int16: Letter 2 / Legal 7 / A4 19) | der vollständige Snapshot |

Der Snapshot trägt die Abschnitte in der kanonischen Reihenfolge des Designers (Report Header, Page Header, Group Headers, Detail, Group Footers, Page Footer, Report Footer), jeweils mit `id`, `type` (`MADocumentSectionType`), `title`, `height` (die Schnittstellenhöhe `layoutHeight`), `visible`, `pageBreak` und `groupField`. Jedes Element trägt `id`, `type` (`MADPrintPageElementType`), `section`, `x/y/w/h`, `text`, `field` (gebundene Abfragefeld-ID), `table`/`column`, `function`/`scope`/`group` (Aggregat), `fontname`/`fontsize`, `bold`/`italic`/`underline`/`strikethrough`, `hAlign`/`vAlign`, `borderTop`/`borderBottom`/`borderLeft`/`borderRight`, `padding` und `margin`. Ein Barcode-Element trägt zusätzlich das verschachtelte `barcode`-Objekt (§6j); ein Bildelement trägt `image{data}`, das gespeicherte Bild als base64-PNG (leer, wenn es keines hat — §6k). `fields[]` listet die Abfragefelder (mit Speicher-IDs) für den Seitenleisten-Browser und das Bindungspopup.

## 6g. Phase 6d — der Viewer-Arbeitsbereich (Rendern, Papiergröße, Export, Drucken)

Phase 6d vollendet den MAD Viewer auf der Shell von 6a–6c. Der Mac-Viewer rendert ein paginiertes PDF in `PDFView`; Windows hat kein PDFKit, also rendert die Vorschau stattdessen das HTML-Faksimile der Engine, und das PDF selbst wird vom eigenen Exporter der Engine zur Exportzeit geschrieben (§6l):

* **Renderansatz — WebView2 über den HTML-Exporter der Engine.** Die Vorschau zeigt die exakten `export --format html`-Bytes (ein `<div class="page" data-index="N">`-Kasten pro Seite, derselbe Formatierer, den das PDF und jeder andere Exporter verwenden), gehostet in einem WebView2. Die Seitenzahl auf der Statuszeile ist die Anzahl dieser Seitenkästen, sodass die Engine der einzige Paginator bleibt und kein Exporter in C# neu implementiert wird. Die Vorschau fügt nur Präsentations-Chrome hinzu (grauer Schreibtisch, Seitenlücken und -schatten) über einen eingefügten Stil; die exportierten Bytes sind unberührt. Das HTML wird in eine temporäre Datei geschrieben und per URL navigiert, weil `NavigateToString` eine 2-MB-Obergrenze hat, die ein großer Bericht erreichen würde. Zoom ist der `ZoomFactor` von WebView2; die Seitennavigation scrollt den angeforderten Seitenkasten ins Bild. **Print** verwendet `CoreWebView2.ShowPrintUI` — den vorläufigen HTML-Druckpfad. Der Browser wird bei `Loaded` erzeugt, nicht in XAML, sodass der Arbeitsbereich für seine Tests headless komponiert.
* **`ViewerViewModel`** besitzt die Papiergrößenauswahl und ihre gerenderte Sperre (US Letter Standard, US Legal, A4), die Zoomstufen (0,25–4,0, 1,25×, Rücksetzung auf 100 %), die Navigation vor/zurück, den Exportformat-Katalog und die Statuszeile. Die Statuszeile ist die des Macs: `Rendered N pages from M cached rows.` mit ihrer Singular-/Plural-Grammatik, grün bei Erfolg und rot bei Fehler. Die Auswahl einer Papiergröße ändert den gerenderten Bericht erst beim nächsten Refresh (die Trennung `selectedPaperType`/`renderedPaperType` des Macs); die Auswahl überlebt den Refresh, und der Export verwendet das gerenderte Papier.
* **Export** bietet die sieben Formate, die dieser Build erzeugt, in der Reihenfolge des Mac-Viewers — PDF Document, HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report und Plain Text —, jeweils mit eigener Dateiendung (`pdf`, `html`, `html`, `csv`, `json`, `json`, `txt`). Die Symbolleiste trägt den Formatwähler; Export öffnet den Speicherdialog gefiltert auf das gewählte Format. PDF geht über die Pfadform von `serve` (`export` mit `path`), sodass die Engine die Bytes des Exporters in die gewählte Datei schreibt und die Antwort nur die Bytezahl trägt; das `data`-Zurücklesen, das die Textformate verwenden, ist UTF-8 und würde ein binäres PDF beschädigen. Ein Export vor einem Refresh aktualisiert zuerst, wie der Export des Macs, und während ein Export läuft, zeigt die Statusleiste ihren unbestimmten Fortschrittsbalken mit einer Zeile „Exporting…“ (der Befehl ist deaktiviert; `serve` streamt keinen Fortschritt, und der Export ist eine einzige Anfrage).
* **Dokumentintegration.** `DocumentViewModel.RefreshAsync` führt die Abfrage aus und ruft dann `Viewer.RenderAsync`, das das gewählte Papier durch das Dokument anwendet (sodass der Snapshot des Designers folgt) und die HTML-Vorschau lädt. Die Buttons Refresh, Export und Print des Viewers laufen alle über denselben Dokumentpfad.
* **Engine-Korrektur.** `set-paper-size` mutierte das gespeicherte `RptqDocument`, aber nicht das Renderdokument, dessen `MTPaper` nach dem ersten Layout gecached ist, sodass die zweite Papieränderung nie einen Export erreichte. Es ruft jetzt auch `setPaperType:` am Renderdokument auf (der Aufruf, den der Mac-Viewer vor dem Refresh macht) und formatiert einen bereits layouteten Bericht neu, sodass die neue Größe einen folgenden Export ohne weiteren Refresh erreicht.

Der Viewer ersetzt das Platzhalter-Zeilenraster von Phase 5: der gerenderte Bericht ist der Arbeitsbereich, wie auf dem Mac, und die Zeilen bleiben über die CSV/JSON-Exporte verfügbar.

**Tests.** `ViewerViewModelTests` (Statusgrammatik, Formatkatalog, Seitenzählung, Zoom, Navigation, Druckanfrage), `ViewerSurfaceTests` (der Arbeitsbereich auf einem STA-Thread materialisiert — die Symbolleiste, die sieben Formate, der Papiergrößenwähler, die Statusfarbe und die Seitenbeschriftung) und `ViewerAcceptanceTests` gegen die Engine (London → 5 Seiten / 76 gecachte Zeilen, Papiergrößensperre und Persistenz durch A4 mit dem exportierten Seitenkasten bei 595 × 842, jedes Exportformat mit seiner Endung und das PDF geprüft an seiner `%PDF-`-Signatur, ein Export in einen Pfad mit Leerzeichen und einem Nicht-ASCII-Zeichen, der Exportzustand gesetzt, während das PDF geschrieben wird, und danach gelöscht, und der Papiergrößenwechsel A4 → Legal → Letter, der jeden Export erreicht).

## 6h. Phase 6e — About, Lokalisierung und der WPF-Smoke-Test

Phase 6e schließt das Merge-Gate, ohne die Engine zu ändern: es vollendet das Abhängigkeitsregister des About-Fensters, lokalisiert die WPF-App in den Sprachsatz der Mac-App, fügt das WPF-Pendant zu `MADMacSmokeTest.m` hinzu und bringt diese Aufzeichnung und `Windows/README.md` auf den neuesten Stand. Die öffentliche `docs/windows.md` und ihre Übersetzungen sind bewusst aufgeschoben.

**About und der WebView2-Hinweis.** Die Viewer-Vorschau läuft im Steuerelement **Microsoft Edge WebView2** (NuGet `Microsoft.Web.WebView2` 1.0.4314.35). Das SDK, das mit der App ausgeliefert wird, ist BSD-3-Clause und trägt Microsofts Drittanbieterhinweise; die Evergreen WebView2 Runtime ist ein Microsoft-Redistributable, keine Open-Source-Software. Das About-Fenster listet daher `Microsoft Edge WebView2` mit beiden Bedingungen und der Laufzeitnennung, alles in `ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`. Das Register ist `docs/project/THIRD_PARTY_LICENSES.md` §10. Der Rest der Komponentenliste ist unverändert (GNUstep Base, gnustep-corebase, libiconv, libobjc2, libdispatch/BlocksRuntime, libffi und die C-Bibliotheken), und das LGPL-Relink-Angebot nennt weiterhin die Windows-Engine; die WPF-App zeigt nie den Apple-Satz.

**Lokalisierung.** Jeder benutzerseitige String lebt in einem WPF-`ResourceDictionary` unter `Windows/App/Mad.Designer.Windows/Resources/`: `Strings-en.xaml` ist die maßgebliche Quelle, und `Strings-de.xaml`, `Strings-es.xaml`, `Strings-ja.xaml`, `Strings-pt-BR.xaml` und `Strings-zh-Hans.xaml` spiegeln den Sprachsatz der Mac-App (`MAD_APP_LOCALIZATION.md` D1/D9). Die Wörterbücher sind in die Hauptassembly eingebettet (nicht als kompilierte `Page`-Elemente und nicht als Satelliten-Assemblies — der Bindestrich in `Strings-de.xaml` hält MSBuild davon ab, den Sprachcode als Kultur-Suffix zu lesen), und `Infrastructure/Localizer.cs` lädt sie mit `XamlReader` und bietet `Get`/`Format`. XAML konsumiert sie über die Markup-Erweiterung `{infra:Loc Key}`, die zur Ladezeit auflöst; Code-Behind und View-Modelle rufen `Localizer` auf. Die Sprache folgt beim Start der UI-Kultur des OS (`de`, `es`, `ja`, `pt-BR`, `zh-Hans`; alles andere ist Englisch), und `MAD_LANGUAGE` überschreibt sie zur Inspektion:

```powershell
$env:MAD_LANGUAGE = "de"
dotnet run --project .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj
```

Die Übersetzungen verwenden `Localizable.xcstrings` des Macs wieder, wo die englische Quelle übereinstimmt, und folgen dann der maschinenunterstützten Richtlinie (MAD_APP_LOCALIZATION.md D14): die About-Overview endet mit dem Hinweis, dass die Übersetzungen maschinenunterstützt sind und Fehler enthalten können, in jeder Sprache. Das About-Chrome, der Verbindungsassistent, die Symbolleisten und Statuszeilen von Query/Designer/Viewer, Dialoge und die Bandnamen sind übersetzt; Lizenzkörper, Komponentenhinweise, das LGPL-Relink-Angebot, Copyright und Markennamen bleiben wörtlich Englisch (D6/§8), mit einem lokalisierten Satz, der sagt, dass die Lizenztexte in ihrem ursprünglichen Englisch wiedergegeben werden. SQL-Schlüsselwörter, Datentypnamen und Feld-/Tabellenkennungen werden nicht übersetzt, und Fehlertexte, die die Engine selbst zurückgibt (Treiberfehler, Meldungen des SQL-Parsers), bleiben Englisch, wie es die Treibermeldungen des Macs tun.

**Der Smoke-Test.** `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs` ist das Pendant auf View-Modell-/Service-Ebene zu `MADMacSmokeTest.m`, kein Pixeltest:

1. **London.** `CLI/Fixtures/London.portable.mad` öffnen, 76 Zeilen (5 Seiten) aktualisieren und dann HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report und Plain Text über den eigenen Pfad des Viewers exportieren. Die Bytezahl und SHA-256 jeder Datei werden gegen die Mac-/Linux-Pins in `Linux/README.md` geprüft (`html` `285541ed…`, `html-flow` `0565204a…`, `csv` `773f6215…`, `json` `569c6ee2…`, `json-report` `9d01d0da…`, `text` `7dcee96c…`).
2. **Ein neues Dokument.** Ein `.mad` aus `chinook.sqlite3` erstellen, die SQL-Anweisung des Macs anwenden (`SELECT Customer.FirstName, Customer.LastName, Customer.City
   FROM Customer WHERE Customer.Country = 'United Kingdom';`), eine statische Beschriftung, ein an `LastName` gebundenes Datenfeld und ein COUNT-Aggregat auf Berichtsebene hinzufügen, aktualisieren und dann jedes verfügbare Format exportieren und die JSON-Zeilenzahl und die HTML-Seitenzahl prüfen.

Der Viewer exportiert in beiden Tests PDF über den Pfad-Export der Engine; der Smoke-Test prüft dessen `%PDF-`-Signatur, statt es als Text zu lesen. Die Suite läuft headless mit den übrigen App-Tests; siehe `Windows/README.md`.

## 6i. Phase 6f — das Theme, die Shell und der Durchgang zur Benutzbarkeit

Phase 6f ist rein präsentational: keine Änderung an Engine, Protokoll, Dokument oder Workflow. Es behebt die beiden funktionalen Defekte, die die Designprüfung meldete, und wendet ein von Fluent inspiriertes Designsystem und eine Shell über die bestehende Architektur mit drei Arbeitsbereichen an. (Der Theme-Durchgang war nicht Teil des Merge-Gates; er folgt ihm.)

**Behobene Defekte.** Help ▸ About beendete den Prozess: die schreibgeschützten `Overview`, `LicenseNotice` und `SelectedAcknowledgement` des About-Fensters waren an `TextBox.Text` gebunden, dessen Standardbindungsmodus TwoWay ist, und die Bindung warf beim ersten Layout des Fensters eine `InvalidOperationException`. Die Bindungen sind jetzt OneWay, und `AboutWindowTests` zeigt das Fenster, um es festzulegen. Der Zieh-Defekt des Designers war die Z-Reihenfolge: der undurchsichtige Hintergrund jedes Bands wurde mit seinen Elementen hinzugefügt, sodass ein in ein späteres Band gezogenes Element unter diesem Band gezeichnet wurde und verschwand, bis das Ablegen die Leinwand neu baute; auch seine Größengriffe blieben an der alten Position. Das gezogene Element zeichnet jetzt über jedem Band, die Griffe sind während des Ziehens verborgen, das Auswahl-Chrome aktualisiert sich an Ort und Stelle statt neu zu bauen, der Offset des ScrollViewers bleibt über einen Neuaufbau erhalten, und die Zieh-Mathematik ist bei Zoom 2 mit gescrollter Ansicht festgelegt.

**Das Designsystem.** `Themes/Theme.xaml` ist der eine Ressourcensatz: Typografie (Segoe UI Variable Text/Display, Fluent-Größen), Abstände, Eckenradien, Oberflächen, Befehls- und Navigationsstile, primäre/sekundäre Buttons, segmentierte Umschalter, Formular- und Kartenstile und semantische Statusfarben. Chrome-Pinsel sind Fluent-Dynamic-Resource-Schlüssel, sodass hell/dunkel, die Akzentfarbe des Benutzers und hoher Kontrast dem System folgen; `App.xaml` aktiviert das native Fluent-Theme mit `ThemeMode="System"` (das `WPF0001` der experimentellen API ist unterdrückt). Berichtsdokumente behalten ihre eigene feste Palette: `Infrastructure/DesignPalette.cs` ist die eine eingefrorene Quelle für Papier, Elementtönungen, den Auswahlakzent, Joins und die Minimap. `MAD_THEME=Light|Dark` ist eine Inspektionsüberschreibung wie `MAD_LANGUAGE`, und der WebView2-Schreibtisch des Viewers folgt ihr (oder der Einstellung `AppsUseLightTheme` von Windows).

**Die Shell.** Das Anwendungssymbol wird aus dem vorhandenen MAD-Artwork erzeugt (`Assets/AppIcon.png` und das mehrgrößige `AppIcon.ico`) und ist die Identität von Fenster, Taskleiste und About. Der Start ohne Bericht zeigt einen Willkommens-/Home-Bildschirm (Neuer Bericht, Bericht öffnen, zuletzt verwendete Berichte, eine kurze Einführung) statt eines leeren Viewers. Die drei Arbeitsbereiche sind eine linke Schiene im Stil von NavigationView mit Symbol + Beschriftung, einem klaren ausgewählten Zustand und Ctrl+1/Ctrl+2/Ctrl+3; sie sind deaktiviert, solange der Willkommensbildschirm gezeigt wird. Ein neu erstellter Bericht öffnet sich im Designer; ein bestehender Bericht öffnet sich im Viewer. Es gibt kein Home-Ziel: die drei Arbeitsbereiche bleiben der erstklassige Gleichrangigensatz. Das Datei-Menü behält Neu/Öffnen/Speichern/Speichern unter/Zuletzt/Verbindung/Beenden; die Befehlsleiste behält Neu und Öffnen (About bleibt in Help).

**Arbeitsbereichsorganisation.** Der Verbindungsassistent ist ein festes Fenster von 640 × 660 (größenveränderbar, mit scrollendem Körper), dessen gruppierte Karten das treiberspezifische Formular im selben Rahmen halten; der Wechsel SQLite → MySQL/SQL Server/PostgreSQL ändert seine Größe nicht. Query hat einen segmentierten Designer/SQL-Umschalter, gruppierte Befehle, einen normal großen Befehl Add table im Kopf des Tabellenpanels und eine untere Zoomleiste mit Hinein/Hinaus, Prozent und Fit. Der Designer gruppiert Einfüge- und Bearbeitungsbefehle, verschiebt die Minimap aus der oberen linken Ecke in einen eingeklappten Expander oben im Inspector und legt Zoom/Raster/Snap/Lineale auf die untere Ansichtsleiste. Der Viewer legt Dokument-/Seiten-/Ausgabebefehle oben und Zoom, Seitennavigation und die Status-/Papierzeile unten ab und gibt dem Bericht die maximale Fläche.

**About.** Das Fenster berichtet jetzt zwei getrennte Identitäten: die Engine (`v9.0 (r4433)`) und die Windows-Anwendung (`v0.7`). Die geklärte Entscheidung ist, dass die Windows-Anwendung vor 1.0 steht, während die Engine ausgereift ist.

**Barrierefreiheit und Lokalisierung.** Die Navigations- und Befehlsflächen haben Tooltips, Textbeschriftungen, wo ein Symbol mehrdeutig ist, UI-Automation-Namen (einschließlich der reinen Symbol-Buttons für Zoom und Seiten), Tastaturkürzel und Fluent-Fokus- und Deaktiviert-Zustände. Jeder neue oder umbenannte String steht in allen sechs Wörterbüchern (`LocalizerTests` prüft Vollständigkeit und Platzhalter; Englisch bleibt die maßgebliche Quelle); Lizenzkörper, Hinweise, Copyright und Markennamen bleiben wörtlich Englisch. Die Suite umfasst 110 Tests, einschließlich der Tests für Willkommen/Navigation/ersten Arbeitsbereich, des Anzeigetests des About-Fensters, des Theme-Wörterbuch-Tests und der Zoom-/Fit-Tests der Abfrage.

**Ribbon-Abwägung.** Es wurde kein Ribbon eingeführt. Die Befehlsfläche des Designers sind zwei Gruppen (Einfügepalette, Bearbeiten) plus eine Ansichtsleiste; ein Ribbon würde Chrome hinzufügen und Leinwandfläche für keinen Entdeckbarkeitsgewinn bei dieser Befehlszahl nehmen. Ein Designer-only-Ribbon ist erst wieder zu erwägen, wenn der Element-/Befehlssatz erheblich wächst (zum Beispiel vollständige Typografie-, Ausrichtungs- und Tabellenlayout-Gruppen). Die drei Arbeitsbereiche haben wesentlich unterschiedliche Befehle, also wäre ein anwendungsweites Ribbon komplexer, nicht einfacher.

**Nicht erledigt (festgehalten, keine Defekte).** Kein viertes Home-Ziel; kein In-App-Schließen zum Willkommensbildschirm. Die Schreibtischfarbe des WebView2 im Viewer wird beim Erzeugen des Browsers gelesen, also braucht ein Theme-Wechsel mitten in der Sitzung einen Neustart. Die im Briefing genannte Referenz-WPF-Anwendung war auf der Workstation nicht vorhanden; die Richtung folgt Microsofts Designleitfaden für Windows 11, dem nativen Fluent-Theme und dem vorhandenen MAD-Artwork, mit zentralisierter Palette und Abständen zum leichten Nachjustieren. Die öffentliche `docs/windows.md` und ihre Übersetzungen bleiben aufgeschoben.

## 6j. Die Barcode-Schließung (2026-11-20)

Das Barcode-Element ist auf keiner Seite der Grenze mehr eine Lücke.

**Engine.** `MADBarcodes` kompiliert hier (jede Symbologie-Unterklasse; `MADBarcodeView` und `MADBarcodeCache` bleiben Apple-only), linkt libpng 1.6.59 und zint 2.16.0 aus `libraries.conf`. Der Kodierdurchlauf von `MADBarcode` ist geteilt, und `-renderedPNGData` schreibt zints RGB-Bitmap über libpng ohne Core Graphics, sodass die headless Engine dasselbe Symbol erzeugt. `MADPrintPageElementBarcode`, `RptqDocumentElementBarcode+Extras` und `MADDocumentObjectDataReferenceBarcode` sind im headless Build; der Seitendurchlauf legt das PNG auf `MADReportLineRepresentation.imageData`, das HTML-Faksimile bettet es als Daten-URI ein (die Eingabe ist der `alt`-Text), und der JSON-Bericht benennt es mit `"image": true`. Ein Barcode mit `useStaticInput1`/`inputStatic1` rendert diesen String; ein gebundener liest sein Abfragefeld.

**serve.** `add-element` akzeptiert `"kind": "barcode"` (Code 128, benutzerseitig lesbar, statisch `MAD-2026`, 160×48, die Standardwerte des Macs); `layout-model` trägt ein verschachteltes `"barcode"`-Objekt (Symbologie-ID und -Name, Optionen, Eingabebindung und ein base64-PNG-`preview` aus demselben Renderkern); `set-element-content` bearbeitet die Symbologie, das benutzerseitig lesbare Flag, den Rahmenstil und die statische-oder-Feld-Bindung; `duplicate-elements` kopiert die Barcode-Spalten; `barcode-types` gibt die Namenstabelle von MADBarcode als `{id, name}` nach Namen sortiert zurück.

**WPF.** Der Barcode-Button der Palette fügt einen ein; die Leinwand zeichnet die Vorschau der Engine (Text-Rückfall, wenn zint verweigert); der Inspector zeigt den Symbologie-Wähler, Show text, den Rahmenwähler und den Eingabewähler (statisch, den das Textfeld bearbeitet, oder ein Abfragefeld). `DesignerAcceptanceTests.Barcode_InsertEditBindAndUnbind` und der Smoke-Test des erstellten Dokuments legen es fest (die HTML-/JSON-Exporte tragen das Symbol und seinen Text), und die London-Byte-Pins sind unverändert, weil die Bytes eines barcodefreien Dokuments sich nicht bewegt haben.

**Lizenz.** zint (BSD-3-Clause) und libpng (PNG Reference Library v2) stehen in §10, in der Komponentenliste des About-Fensters und in `ThirdParty/Licenses/` (beide Texte existierten bereits).

## 6k. Die Image-Schließung (2026-11-20)

Das Bildelement hört auf, ein Platzhalter zu sein. Es wurde keine Bibliothek hinzugefügt: die Bildspalte des Speichers hält bereits PNG-Bytes.

**Engine.** Außerhalb Apples sind `MADReferenceImage` und `MADElementImage` `NSData` — das Wire-Format des Speichers selbst —, also ist das Modell headless-bereit, und `RptqDocumentElementImage (Extras)` erhielt das portable `-pngData` / `-setPngData:`, das die Bytes überall wörtlich speichert (Apples `-image`-Accessoren codieren/decodieren das Bild weiterhin, wo UIKit/AppKit existiert). `MADPrintPageElementImage -renderedImageData` antwortet mit dem gespeicherten PNG, sodass `MADReportLineRepresentation.imageData` — die Naht der Barcode-Schließung — auch ein Bild trägt: das HTML-Faksimile bettet es als `data:image/png;base64,…`-URI ein, und der JSON-Bericht benennt es mit `"image": true` ohne Text. Auf Apple zeichnet der PDF-Pfad das Element weiterhin, und `-renderedImageData` antwortet nil, was das bestehende Exportverhalten des Macs ist.

**serve.** `add-element` akzeptiert `"kind": "image"` mit einem optionalen base64-`"data"` (decodiert, bevor das Element eingefügt wird, sodass eine fehlerhafte Anfrage nichts hinterlässt); `layout-model` trägt ein verschachteltes `"image"`-Objekt `{data}`; `set-element-content` akzeptiert `"data"` (base64-PNG; leer löscht es); `duplicate-elements` kopiert das Bild.

**WPF.** Der Image-Button der Palette fügt ein Element ein; der Inspector zeigt einen lokalisierten Button „Choose Image…“ für ein ausgewähltes Bild (die Zeile des Mac-Inspectors). Der Wähler decodiert jedes PNG/JPEG über WIC und codiert es vor dem Senden als PNG neu (`ImageFileEncoder`) — die Spalte ist immer PNG, also ist die HTML-Daten-URI ehrlich. Die Leinwand zeichnet das gespeicherte Bild und fällt auf den Platzhalter `[Image]` zurück, wenn das Element keines hat. `ImageElementTests` legt das Protokoll, die Neucodierung des Wählers und die Leinwand fest; der Smoke-Test des erstellten Dokuments fügt eines zum exportierten Dokument hinzu.

## 6l. Die PDF-Schließung (2026-11-20)

`mad export --format pdf` und der `export` von `mad serve` schreiben jetzt ein PDF unter Windows, und die Windows-Hälfte ist der dritte headless Bibliotheksstack, den der Build trägt.

**Bibliotheken.** `Windows/Engine/libraries.conf` schreibt exakt die Linux-Pins fest: pixman 0.46.4 und cairo 1.18.6 (git-Tags, Commits festgeschrieben) und FreeType 2.15.0 (Tarball), plus das Liberation-2.1.5-Font-Tarball. `build.ps1` baut FreeType mit seinem eigenen CMake (clang-cl, statisch, nur Kern), dann pixman und cairo mit Meson in der MSVC-Umgebung (`cl`), statisch und nur mit der PDF-Oberfläche. Die Meson-Builds finden ihre lokalen Abhängigkeiten über generierte `.pc`-Dateien und denselben Windows-nativen pkg-config-Shim, den der libpq-Build einführte (`Ensure-PkgConfigShim`, jetzt eine Funktion, sodass beide Builds sie teilen). Drei Archive schließen sich dem Link an: `cairo.lib`, `freetype.lib`, `pixman-1.lib`; `msimg32` schließt sich der Systemliste für cairos win32-Oberfläche an.

**Fonts.** Die Liberation-Schnitte werden nach `Engine/build/fonts` kopiert; `MADReportExporterPDFCairo` sucht zuerst `<exe>/fonts` (sodass `mad.exe` `build/fonts` findet und ein Test in `build/tests` `build/fonts` über `<exe>/../fonts` findet), dann die installierten Layouts und `MAD_FONTS_DIR`.

**Writer.** `MADReportExporterPDFCairo` in `MAD/Source` ist der Nicht-Apple-Körper von `MADReportExporterPDF`; der Apple-Körper ist unberührt und linkt Cairo nicht. Das strukturelle Ziel, die Font-Zuordnung und die Determinismus sind die von `docs/developers/build/pdf.md`. `MADPDFExportTests` ist der Abnahmetest auf beiden Engines; er liest das PDF zurück und vergleicht Seitenzahl, MediaBox, jeden Rahmen und den Text jeder Zeile mit dem Oracle `json-report`, prüft den Barcode und das Bild als Bild-XObjects und prüft die deterministische Byte-Gleichheit.

**Lizenzen.** cairo (MPL-1.1), pixman (MIT), FreeType (FTL) und die Liberation-Fonts (SIL OFL 1.1) sind in `THIRD_PARTY_LICENSES.md` §3.5 und §10 registriert, ihre Texte liegen in `ThirdParty/Licenses/`, und `WindowsLicenseRegistry` listet alle vier für das About-Fenster. Keine fügt eine Relink-Pflicht hinzu.

**Viewer.** Der Formatwähler des WPF-Viewers listet PDF zuerst, wie es der des Macs tut, und exportiert es über die Pfadform von `serve` (`export` mit `path`), sodass die Engine die Bytes des Exporters schreibt und die Antwort die Bytezahl trägt. Die Textformate behalten das `data`-Zurücklesen, dessen UTF-8-Decodierung für sie verlustfrei ist. Ein unbestimmter Fortschrittsbalken und eine Statuszeile „Exporting…“ decken den Aufruf; die Strings `Format.Pdf` und `Viewer.Exporting` werden in allen sechs Wörterbüchern ausgeliefert.

## 7. Unterstützte Windows-Versionen

Die unterstützte OS-Matrix von .NET 10 (Windows 10 Enterprise 21H2/1809/1607, Windows 11) und die Windows-10-1903+-Basislinie von GNUstep; getestet auf Windows 11 Enterprise 26H2 (Build 26300). Windows 7/8 werden von .NET 10 nicht unterstützt.

## 8. Drittanbieter-Lizenzen und die Windows-About-Seite

Die Windows-Engine ist eine dritte Distributionsoberfläche, registriert in `docs/project/THIRD_PARTY_LICENSES.md` §10. Sie fügt die GNUstep-Runtime zur Compliance-Oberfläche hinzu:

* **GNUstep Base, gnustep-corebase und die libiconv-Bibliothek** sind LGPL-2.1-or-later. Die Windows-Distribution muss den LGPL-2.1-Text, den Hinweis und das schriftliche Relink-Angebot in `ThirdParty/Licenses/README.md` tragen.
* **libobjc2 (einschließlich libBlocksRuntime) und libffi** sind MIT; behalten Sie die Hinweise.
* **libdispatch** ist Apache-2.0 mit der Swift-Runtime-Ausnahme; liefern Sie den vollständigen Text aus.
* **FreeTDS und MariaDB Connector/C** sind unter der bestehenden LGPL-3.0-Wahl statisch gelinkt; die Bearbeitung von `sybdb.h` in FreeTDS ist markiert, und das bestehende Relink-Angebot nennt jetzt die Windows-Engine.
* **Die C-Bibliotheken** (SQLite, zlib, bzip2, libarchive, libpng, zint, OpenSSL, libpq) verwenden die bestehenden Einträge und Texte in `ThirdParty/Licenses/`.
* **Microsoft Edge WebView2** (das Vorschau-Steuerelement des WPF-Viewers, NuGet `Microsoft.Web.WebView2` 1.0.4314.35) ist ein Microsoft-Produkt, keine Open-Source-Software: die Evergreen WebView2 Runtime wird mit Windows 11 und Edge installiert und von diesem Projekt weder geändert noch weiterverbreitet. Sie ist mit der BSD-3-Clause-Lizenz des SDK und Microsofts Drittanbieterhinweisen, den Microsoft Software License Terms der Laufzeit und der Nennung dieses Projekts registriert — alles in `ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`.
* **gnustep-make** ist GPL-3.0-or-later-Build-Tooling und wird nicht verteilt; sein `Testing.h` wird nur in Testbinärdateien kompiliert, die nicht ausgeliefert werden. Die `iconv`-Werkzeuge von libiconv und die Testprogramme von gnustep-corebase werden ebenso nicht verteilt. Die Kommandozeilenwerkzeuge von GNUstep Base (`gdomap`, `gdnc`, `defaults`, `plutil`, `gspath`) sind GPL-3.0-or-later und nicht Teil von `mad.exe`; paketieren Sie sie nicht ohne den GPL-Text und ein Angebot des entsprechenden Quellcodes.

Die genaue DLL-/Statik-Aufteilung wird am gebauten `mad.exe` mit `dumpbin /dependents` (oder `llvm-objdump -p`) gemessen und im Bericht von Phase 3b festgehalten; sie wird nicht aus dem Layout der Toolchain abgeleitet. Der Build und jedes Paket müssen `ThirdParty/Licenses/` und `NOTICE` kopieren.

Das WPF-**About**-Fenster (Shell-Beweis von Phase 5, vollendet in Phase 6e; die Trennung von Engine-/Anwendungsversion kam in Phase 6f) spiegelt die drei Tabs des Macs — Overview, License & Notice und Acknowledgements — und listet jede Komponente oben, einschließlich WebView2, mit den Texten aus `ThirdParty/Licenses/Windows/` und den geteilten Wurzeltexten und dem schriftlichen LGPL-Angebot. Die Acknowledgements-Liste ist die Windows-Komponentenliste, nicht die der Apple-App; der Tab License & Notice trägt den MIT-/Marken-Hinweis und das Windows-Relink-Angebot; die Overview trägt den Hinweis zur maschinenunterstützten Übersetzung. Ihr Chrome ist lokalisiert, während jeder Lizenzkörper, Komponentenhinweis, Lizenzname und jede Copyright-Zeile wörtlich Englisch bleibt (D6/§8 von `MAD_APP_LOCALIZATION.md`). Die bestehenden About-Bildschirme von iOS und macOS bleiben Apple-only: sie listen die C-Bibliotheken, die die Apple-App linkt, und dürfen nicht behaupten, die Apple-App linke die GNUstep-Runtime. Die öffentliche `docs/windows.md` und der Windows-Eintrag in `README.md` landeten mit dem unsignierten 0.7-Release (2026-11-21); die Seite ist in allen sechs Sprachen unter dem Dokumentationsvertrag vorhanden (`docs/project/localization/LOCALIZATION.md`). Der Windows-Verifikations-Workflow (`.github/workflows/windows.yml`) testet die .NET-Suiten gegen das Engine-Asset `mad-windows-x64.zip`, das an `v0.8.0` angehängt ist; `Windows/package.ps1` stellt sowohl dieses Asset als auch das Release-Zip der App zusammen.

## Testdatenbanken

Die drei Live-Treibersuiten (Phase 3b) werden gegen dieselben festgeschriebenen Docker-Testserver ausgeübt, die die Apple-/Linux-Builds verwenden, ausgeführt als **lokale Windows-Container, gebunden an `127.0.0.1`** (der Mac behält das Veröffentlichen auf allen Schnittstellen, damit das Linux-Image und die CLI-Fixtures seine Container per Namen erreichen). Die plattformübergreifenden Einstiegspunkte sind `TestDatabase/test-databases.sh` (Git Bash) und `TestDatabase/test-databases.ps1` (PowerShell), die an die drei Skripte pro Framework delegieren; `TestDatabase/README.md` ist die Referenz.

```powershell
.\TestDatabase\test-databases.ps1 -Action download   # fetch datasets, no Docker
.\TestDatabase\test-databases.ps1 -Action up         # create/start all three
.\TestDatabase\test-databases.ps1 -Action status     # -Service mysql|tds|postgres
.\TestDatabase\test-databases.ps1 -Action verify
.\TestDatabase\test-databases.ps1 -Action env        # print the env block
```

Der `env`-Block ist der Vertrag, den die Live-Suiten von Phase 3b lesen; wenden Sie ihn in derselben Sitzung wie `build.ps1` an:

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"; $env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"; $env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"; $env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"; $env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"; $env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"; $env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
```

Es gibt kein `MAD_TDS_TEST_PORT` — die TDS-Suite hat 1433 fest verdrahtet. Treiberbuild-Ergebnisse sind im Bericht von Phase 3b dokumentiert, nicht hier.

## Verwandte Dokumente

* `docs/developers/build/linux.md` und `Linux/README.md` — der Linux-Build, den dieser Windows-Build spiegelt.
* `docs/developers/build/macos.md` und `Mac/README.md` — die native macOS-Anwendung, deren Verhalten die WPF-App spiegeln wird.
* `docs/project/THIRD_PARTY_LICENSES.md` §10 — das Lizenzregister der Windows-Engine; `ThirdParty/Licenses/` und `ThirdParty/Licenses/Windows/` — die Texte und das schriftliche Relink-Angebot.
