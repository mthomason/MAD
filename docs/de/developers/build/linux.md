---
layout: default
lang: de-DE
title: "Die Engine unter Linux bauen"
description: "Der Docker-Build, die zwölf headless Frameworks und ihre Suiten."
---

# Die MAD-Engine unter Linux kompilieren — eine technische Einschätzung

Diese Seite hält den Linux-Build fest: das Docker-Image, die festgeschriebene Toolchain, die zwölf headless Frameworks und die Suiten, die sie ausführen. `Linux/README.md` enthält die täglichen Befehle.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

Geschrieben am 2026-10-04 gegen `master` bei `c807eeb4d`. Der Abhängigkeitsaudit (§4) und die Ökosystemrecherche (§5-6), auf denen dieses Dokument beruht, entstanden beide am selben Tag: den Audit durch Greppen im Quellverzeichnis jedes Frameworks, die Recherche aus Primärquellen (Release Notes, Paket-Repositories, Projekt-Mailinglisten). Wo die Evidenz dünn war, wird das gesagt. Dieses Dokument ist der technische Begleiter zu `MAD_FUTURE.md` §5.1, das die Plattformmatrix skizzierte; dies ist der Tauchgang.

---

## 1. Die Frage, beantwortet

Kann das unter Linux kompilieren? **Ja, bedingt — in beiderlei Sinn.**

- Der Code, der kompilieren muss — die headless Engine —, ist nach Messung bereits nahezu frei von Apple-Abhängigkeiten. Die beiden, die bleiben (Core Data und UIKit/CoreGraphics), sind entweder mitten in der Migration oder Datei für Datei aufgezählt, und keiner von beiden sitzt auf dem Refresh-Pfad.
- Das Ökosystem, das hosten muss — Objective-C mit Foundation unter Linux —, existiert, ist in jeder großen Distribution paketiert und betreibt heute einen produktiven Groupware-Server (SOGo, Debian-gepackt gegen GNUstep Base 1.31.1). Es ist Nische, seine Abdeckung moderner APIs ist an den Rändern ungeprüft, und seine UIKit-Geschichte existiert nicht — aber diese Codebasis braucht unter Linux kein UIKit. Sie braucht die Engine.

Die beiden Sternchen: **GNUsteps Foundation ist vorhanden, aber ungeprüft** für die genauen APIs, auf die sich dieser Code am stärksten stützt (`NSPredicate`/`NSExpression`, Keyed Archiving, `NSURLSession`), und **es gibt kein realistisches UIKit unter Linux** — was in Ordnung ist, weil der Audit zeigt, dass der Code UIKit bereits auf benannte Dateien beschränkt, und der Rendering-Plan sich ohnehin von UIKit wegbewegt.

---

## 2. Die Zwei-Produkte-Frage: neu schreiben oder kompilieren-und-aufrufen

Die Wahl, die der Benutzer stellte: alles in Python neu schreiben und zwei Produkte pflegen oder einmal kompilieren und Python die Engine aufrufen lassen. Der Audit klärt es.

**Die Engine ist groß.** Der headless Frameworksatz — `MADFoundation` (65 h+m-Dateien), `MADCocoaExtensions` (44), `MADDataStructures` (36), `MADFileManager` (30), `MADAPI` (33), `MAD` (403), `MADSqlite3` (64), `MADMySQL` (41), `MADTds` (3), `MADTdsClient` (8) — umfasst grob 727 Dateien. Ein Python-Neuschreiben dupliziert nicht nur das Volumen, sondern *Verhalten, das durch Tests festgelegt und hart erarbeitet ist*: den SQL-Generator, den Aufnahmepfad von `MADDataTableFast` (200.000 Zeilen in 1,16 s, gebenchmarkt), die Typzuordnungen der Treiber (SQL Servers moderne Datums-/Zeitbehandlung existiert nur, weil Live-Tests sie zweimal gefangen haben), die Null-Sentinel-Familie, den Speicherleser. Zwei Implementierungen davon driften auseinander; die Suite legt nur eine fest. Das sind nicht „zwei Produkte“, sondern ein Produkt und eine Last.

**Die Integrationsoberfläche existiert bereits.** Die CLI *ist* der Vertrag: `mad inspect` → Metadaten, `mad query` → SQL, `mad refresh` → Zeilen, `mad export` → Formate, mit Exit-Codes, die schlechtes Dokument (2) von nicht erreichbarem Server (3) von gescheiterter Abfrage (4) unterscheiden. Ein Python-Dienst ruft sie als Subprozess mit `--format json` auf und erhält den Bericht. Der Subprozess-Overhead ist auf Refresh-Zeitskalen irrelevant (die Beispiele aktualisieren in 0,02-1,2 s; der Prozessstart ist ~10 ms). Falls In-Process-Einbettung je als wichtig gemessen wird, können dieselben Quellen eine kleine C-ABI-Bibliothek für ctypes/CFFI bauen — aber das ist optional, keine Voraussetzung.

**Zum genannten Grund, Python zu bevorzugen — der Treiberanschluss.** Es stimmt, dass Pythons Connector-Ökosystem breit ist, und ein `pip install` erreicht Datenbanken, für die dieses Projekt keinen Treiber hat. Aber für die heute existierenden Quellen ist der Anschluss bereits sprachneutral: die MAD-Treiber sitzen auf freetds und MariaDB Connector/C — denselben C-Bibliotheken, die ein Python- oder C-Programm linken würde — und beide bauen nativ unter Linux (§7). Die Engine zu kompilieren verschiebt diesen Anschluss unverändert nach Linux. Wo Python wirklich einen Vorteil hat, sind *neue* Quellentypen (Postgres, BigQuery, REST), und dort ist die richtige Antwort die Erweiterungsnaht, die das Projekt bereits verspricht: eine `MADDatabase`-Unterklasse, die ein Schema und Zeilen zurückgibt. Ein Treiber, der HTTP spricht, verhält sich in Objective-C und Python identisch; Python kauft mehr vorgefertigte Connectoren, keinen einfacheren Kern.

**Der ehrliche Kompromiss, klar gesagt:** das ist eine Wahl zwischen dem Pflegen *zweier Implementierungen* (Python + Objective-C) mit dauerhaftem Drift-Risiko und dem Pflegen *einer Implementierung auf einer Nischen-Toolchain* (clang + libobjc2 + GNUstep) mit Ökosystemrisiko. Dieses Dokument empfiehlt Letzteres, mit einem messbaren Auslöser zur Überprüfung: §9 benennt den Kontrollpunkt. Das eine, das die Empfehlung verbindlich macht, ist die **Form des JSON-Exports** — der Python-Vertrag ist nur so gut wie sein Schema, und ihn zu definieren ist Entscheidung 1 in §10.

Und falls je ein Neuschreiben geschieht, ist die richtige Sprache Swift unter Linux — nicht Python —, weil der portable SQLite-Speicher (die Arbeit von Phase C) bereits ein sprachneutraler Vertrag ist: welche Seite auch immer den Speicher schreibt, die andere liest ihn.

---

## 3. Was kompilieren muss und was nicht

| Framework | Headless benötigt | Warum / warum nicht |
|---|---|---|
| `MADFoundation` | ja | die Basis: Operationen, URL-Fabrik, Schlüsselbund (ausschließbar), Logging |
| `MADCocoaExtensions` | ja | überall verwendete Helfer (11 UIKit-Dateien, aber ausschließbare) |
| `MADDataStructures` | ja | 0 Apple-Importe; 3 C++-Dateien (braucht libc++) |
| `MADFileManager` | ja | 0 Apple-Importe; Cloud-Koordinator ausgeschlossen (iCloud wird ohnehin in Phase D gelöscht) |
| `MADAPI` | ja | Verbindungsschicht; 3 UIKit-Dateien sind View-Controller, nicht headless |
| `MAD` | ja | der schwierige: 29 UIKit, 34 CoreData, 15 CoreGraphics von 403 |
| `MADSqlite3` | ja | 0 Apple-Importe; `MADArrayCaching` (der `.madac`-Speicher) ist zu 100 % sauber |
| `MADMySQL` | ja | 0 Apple-Importe |
| `MADTds` / `MADTdsClient` | ja | 0 Apple-Importe |
| `MADExplorer` | nein | Datei-Explorer-UI (19 von 32 Dateien importieren UIKit) |
| `MADBarcodes` | ja | der Kodier-+-PNG-Kern ist portabel (zint + libpng); nur `MADBarcodeView` und `MADBarcodeCache` bleiben Apple-seitig |
| `MADFeedback` | nein | ungenutzt und ungepflegt |
| `Scrimpter` | nein | 0 Apple-Importe, aber ungenutzt |
| `MADDesigner` (App) | nein | 302 UIKit-Dateien; die UI bleibt auf Apple-Plattformen |

Abhängigkeitsrichtung: alles sitzt auf `MADFoundation`; die Treiber unterklassen `MADDatabase` in `MAD`, während die `Constructor`-Dateien von `MAD` die Treiber importieren — der bekannte Zyklus (`ROADMAP.md` §3.4). Die Treiberregistratur (`ROADMAP.md` §5.1) zählt für Linux doppelt: sie bricht diesen Zyklus und ist das, was einen Linux-Build Treiber als Plugins linken lässt statt als hart importierten Haufen.

---

## 4. Der gemessene Audit

Dateien, die jedes Apple-Framework importieren, pro Framework-Quellverzeichnis (eine Datei, die mehrere UIKit-Header importiert, zählt einmal):

| Framework | gesamt | UIKit | CoreData | CoreGraphics | Security | os/log | CoreFoundation | dispatch |
|---|---|---|---|---|---|---|---|---|
| MADFoundation | 65 | 4 | 0 | 0 | 1 | 9 | 3 | 1 |
| MADCocoaExtensions | 44 | 11 | 0 | 3 | 0 | 1 | 0 | 0 |
| MADDataStructures | 36 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MADFileManager | 30 | 0 | 0 | 0 | 0 | 2 | 0 | 5 |
| MADAPI | 33 | 3 | 0 | 0 | 0 | 4 | 0 | 2 |
| MAD | 403 | 29 | 34 | 15 | 1 | 15 | ~19 | 3 |
| MADSqlite3 | 64 | 0 | 0 | 0 | 0 | 4 | 3 | 5 |
| MADMySQL | 41 | 0 | 0 | 0 | 0 | 2 | 0 | 1 |
| MADTds | 3 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| MADTdsClient | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |

Der lange Schwanz außerhalb der Säulen, jeweils mit einer Behandlung:

| Element | Stellen | Behandlung |
|---|---|---|
| `os_log` (alles läuft durch `madlog.h`, zwei Kopien) | 9+15+4+2+… Dateien importieren den Shim | einen ~20-zeiligen Header gegen syslog/printf neu schreiben; keine andere Aufrufstelle ändert sich |
| `asl.h` (veraltetes Apple System Log) | `MADocument.m:107`, `RptqDocumentElement+Extras.m:60` | auf den madlog-Shim umstellen |
| `copyfile.h` | `MADArchiveManager.m:14`, `madtar.m:18` | POSIX rename/link |
| `mach/machine/vm_param.h` (Seitengröße) | `MADocument.m:108` | `getpagesize()` |
| `CFNetwork`/`CFHost` Reverse-DNS | `BDHost.m` (1 Datei) | `getaddrinfo` |
| `NSMetadataQuery`-Cloud-Koordinator | `MADFileManager` (3 Dateien) | ausschließen — iCloud wird in Phase D gelöscht |
| `Security.framework` / `SecItem` | `MADKeyChain.m`, `MADOperationKeyChainGet.m` + Test | ausschließen — der Refresh-Pfad nimmt Zugangsdaten aus einer Operationsabhängigkeit, nie aus dem Schlüsselbund; die CLI ersetzt bereits durch `--credentials` |
| `AppKit`-Guard in `MADApplication.m` | 1 Datei | einen `TARGET_OS_LINUX`-Zweig hinzufügen |
| `UIScreen`-Skala in `MADURLFactory.m:32` | 1 Zeile | 2.0 zurückgeben |
| `UIApplication`-Hintergrundaufgabe in `MADOperation.m:549-563` | 1 geschützte Funktion | `#if`-aus |
| CoreFoundation (`CFNumber`/`CFData`/`CFString`, Toll-Free Bridging) | ~25 Stellen in MAD, MADFoundation, MADSqlite3 | GNUstep-Äquivalente / mechanisches Neuschreiben; CoreBase (GNUsteps CF-Klon) ist unreif, nicht darauf verlassen |
| UIKit-Value-Transformer (`MADColorTransformer`, `MADLocaleTransformer`, `MADPngImageTransformer`) | 3 Dateien, derzeit über die Targetgrenze der CLI geschleppt | **sterben mit Phase D** — die Speichermigration konvertiert Transformables in portable Skalare |

SystemConfiguration: null Vorkommen. CommonCrypto: null in den Frameworks (nur App, Receipt-Validierung). `@import`: null — alles ist `#import`, was GNUstep will.

---

## 5. Die drei Säulen

### 5.1 Core Data — die laufende Migration ist der Hebel

34 MAD-Dateien importieren Core Data; `MADocument` ist ein `UIManagedDocument`; der Speicher ist ein kompiliertes `MAD.momd`; `MADAtomicStore` liegt darunter. Nichts davon existiert unter Linux, und nichts davon muss — weil das Projekt es bereits ersetzt: Phase C von `MAD_STORE_MIGRATION.md` landete am 2026-10-03, und `RptqStoreContext.h` erklärt „Nothing here imports Core Data.“ Phase D löscht `UIManagedDocument`, die Value-Transformer, das `.xcdatamodel` und die iCloud-Mechanik — was gleichzeitig mehrere Elemente aus §4 tötet (die Value-Transformer, den Cloud-Koordinator, das `MAD.momd`, das die CLI derzeit aus dem App-Bundle kopiert).

**Phase C und D abzuschließen ist der einzelne Schritt mit dem höchsten Hebel Richtung Linux**, und es ist Arbeit, die das Projekt ohnehin für Portabilität besitzt, keine Linux-spezifische Anstrengung. Eine Anmerkung aus dem Migrationsplan: alte Dokumente aus der iCloud-Ära werden vom Benutzer über die iOS-Dateien-App abgerufen und beim Öffnen konvertiert (`MADStoreConverter`) — die iCloud-Mechanik wird zum Abrufen nicht gebraucht, also lässt ihre Löschung in Phase D nichts verwaist zurück.

### 5.2 UIKit / CoreGraphics — 29 Dateien, die meisten trivial

Die 29 UIKit-Dateien von MAD gliedern sich als:

| Art | Anzahl | Behandlung |
|---|---|---|
| `CGGeometry`-Structs (`CGRect`/`CGSize`/`CGPoint`) | 15 Dateien | einfache Structs — die Definitionen nachbilden; kein Zeichnen |
| `UIEdgeInsets` im Formatierer | ~3 Dateien | durch die Struct-Mathematik ersetzen |
| `UIFont`/`UIColor`/`UIImage` in Modell-/Layoutcode | mehrere | leichte Äquivalente für Metriken und gespeicherte Stile |
| `UIActivityItemProvider` / Share-Sheet | 2 Dateien | nicht headless — ausschließen |
| `UIScreen`/`UIApplication` | 2 Dateien | Einzeiler, §4 |
| `MADPrintPageRenderer` + `UIGraphics`-PDF-Kontexte | die Exportnaht | **die eigentliche Arbeit** — siehe unten |
| `MADocument`s Basis `UIManagedDocument` | die Dokumentklasse | stirbt mit Phase D |

Bemerkenswerte gute Nachricht: die UIKit-Verwendung in `MADReportFormatter.m` ist praktisch rudimentär (ein `UIEdgeInsetsMake`, ein ungenutzter `UIPrintInteractionController`-Import), und `MADArrayCaching` — der `.madac`-Speicher gerenderter Seiten — ist bereits zu 100 % frei von UIKit/CoreData. Er kompiliert heute auf jedem ObjC-Foundation.

**Die Renderer-Entscheidung.** CoreGraphics-PDF-Kontexte haben kein Linux-Äquivalent. Die Stufung mit den geringsten Kosten: Datenpfad-Verben zuerst grün; `export --format json` / `--format csv` als Nächstes (reines Foundation — und das sind ohnehin die Formate, die ein Python-Aufrufer will); HTML/SVG-Seiten als Nächstes (keine nativen Abhängigkeiten); PDF zuletzt, indem ein cairo- oder libharu-Writer hinter dieselbe Zeichenschleife von `MADPrintPageRenderer` gelegt wird oder indem PDF-Rendering auf macOS-Workern bleibt, während Linux Daten und Seiten liefert. Das Flag `--deterministic`, das die CLI bereits byteweise in PDFs patcht, ist der Keim eines plattformübergreifenden Renderer-Tests.

### 5.3 Foundation auf GNUstep — existiert, teils verifiziert, an den Rändern riskant

Was die Recherche verifizierte, aus Primärquellen:

- **GNUstep Base 1.31.1** (2025-02-28) ist aktuell; master ist aktiv (bemerkenswerte NSURLSession-Arbeit im August 2026 gemergt). Die Release-Kadenz ist langsam — etwa jährlich.
- Vorhanden und funktional: `NSJSONSerialization`, `NSUUID`, `NSRegularExpression` (ICU), `NSISO8601DateFormatter`, `NSDateFormatter` (ICU-gestützt — `libicu-dev` ist eine erforderliche Build-Abhängigkeit), `NSOperationQueue`, Property Lists, `NSXML*` (libxml2), Keyed Archiving mit Ziel Apple-XML-Kompatibilität.
- **`NSURLSession` ist die Schwachstelle**: in 1.31.0 als „new experimental implementation“ ausgeliefert, ausdrücklich keine unterstützte Klasse; die De-Blocking-Arbeit von 2026 (Bauen ohne Blocks) ist gemergt, aber die Stabilisierung ist unfertig. Bauen Sie das Linux-Produkt nicht darauf — bevorzugen Sie direkte Treiberverbindungen (was der Refresh ohnehin tut) oder libcurl.
- **`libdispatch` ist nach GNUsteps eigener Politik optional** — der Betreuer der Basis nennt es „not in a state where it's portable/reliable enough“, um sich darauf zu verlassen. Diese Codebasis verwendet dispatch breit (`dispatch_once`, `dispatch_sync`, Semaphoren). swift-corelibs-libdispatch ist C und aus ObjC aufrufbar (mit `OS_OBJECT_HAVE_OBJC_SUPPORT=1`), und der hier verwendete *Kern* ist der stabile Teil — aber behandeln Sie dispatch als shim-bare Schicht, nicht als Gegebenheit.
- **CoreBase** (GNUsteps CoreFoundation-Klon) ist unreif — der Build-Leitfaden sagt, sich nicht darauf zu verlassen. Die ~25 CF-Stellen bekommen stattdessen GNUstep-Äquivalente.
- **An den Rändern ungeprüft und hier tragend:** `NSPredicate`/`NSExpression` (13+ Importstellen in MAD), `unarchivedObjectOfClass:` (iOS-11+-API — GNUstep-Abdeckung variiert), `NSOperation`+KVO-Verhalten. Das Vorhandensein ist bewiesen; die Verhaltensparität nicht. Das ist das ehrliche Risiko, und genau dafür existieren die Fixtures in §8.

**Der Existenzbeweis:** SOGo, ein Objective-C-Groupware-Server, wird in Debian sid ausgeliefert und hängt hart von `gnustep-base-runtime (>= 1.31.1)` ab — GNUstep Foundation läuft als Produktionsdaemon im Maßstab. Darling treibt libobjc2. Nicht-GUI-ObjC-Tooling unter Linux ist normal, nicht exotisch.

---

## 6. Toolchain und Ökosystem

- **Runtime: libobjc2 2.3** (2025-09-16) — der einzige Weg zu modernem Objective-C unter Linux. ARC, Blocks, schwache Referenzen, `@synchronized`, nicht-fragile Ivars, die gnustep-2.0-ABI. **ARC erfordert clang + libobjc2**, und die Pakete der Mainstream-Distributionen bauen GNUstep gegen die GCC-Runtime ohne ARC — also wird die Build-Umgebung aus dem Quellcode zusammengestellt (oder aus Fedoras libobjc2-Paketierung), nicht aus Debian-Standards. Das ist ein echtes operatives Bekenntnis.
- **Blocks**: libobjc2 2.3 kann die BlocksRuntime von swift-corelibs-libdispatch konsumieren; `libblocksruntime-dev` ist ebenfalls paketiert. Die Blocks des Codes sind Standard.
- **Exceptions**: clang + libobjc2 liefert native Unwinder-basierte Exceptions; GNUsteps zwei Exception-Mechanismen dürfen nicht in einer Binärdatei gemischt werden — bauen Sie alles mit dem nativen Pfad.
- **Keine clang-Module / keine `@import`-Unterstützung** — und die Codebasis verwendet bereits überall `#import`, also kostet das nichts.
- **UIKit unter Linux: bestätigt abwesend.** Die Erinnerung des Benutzers an Microsoft ist WinObjC — die Windows Bridge for iOS, eine bewusst partielle UIKit-Teilmenge unter Windows, zuletzt 2022 vorangetrieben, 2025-05-28 archiviert. Chameleon (UIKit unter macOS) starb 2015. `gnustep/libs-uikit` (Juni 2026) ist ein Experiment mit 26 Commits und einem Stern. Die Lehre aus sogar Microsofts Aufgabe der Idee: **UIKit nicht portieren.** Der Audit zeigt, warum dieses Projekt es nicht muss — UIKit ist bereits auf benannte Dateien beschränkt, und alles Headless rendert über Daten, nicht über Views.
- **Testen: kein XCTest für ObjC unter Linux** (swift-corelibs-xctest ist Swift-only). GNUsteps eigenes `gnustep-tests` + `Testing.h` ist der abhängigkeitsfreie Unit-Runner; UnitKit ist archiviert. Die echte Abnahmeschicht sind die Fixtures von §8, nicht Unit-Tests.
- **Krypto und Geheimnisse**: kein CommonCrypto-Port (der eigene Rat des GNUstep-Projekts ist `#ifdef` auf OpenSSL oder GnuTLS); kein Schlüsselbund (das funktionale Analogon ist libsecret/Secret Service oder keyutils für Session-Geheimnisse) — und gemäß §4 braucht die headless Engine beides nicht.

---

## 7. Die C-Bibliotheken — der leichte Teil, mit einem Lizenzblocker

Jede mitgelieferte Bibliothek ist portables C mit einem Upstream-autoconf/cmake-Build:

| Bibliothek | Version | Lizenz | Linux-Build |
|---|---|---|---|
| sqlite3 | 3.53.3 | gemeinfrei | nativ; Format-pinnende Flags liegen bereits in `Compressor/sqlite3.xcconfig` |
| zlib | 1.3.2 | Zlib | nativ |
| openssl | 3.5.9 | Apache-2.0 | nativ |
| bzip2 | 1.0.8 | BSD-ähnlich | nativ |
| libpng | 1.6.59 | PNG Reference v2 | nativ |
| libarchive | 3.8.9 | BSD-2 | nativ |
| freetds | 1.4.27 | LGPL-2.0+ | nativ (das Rezept hat einen BSD-`sed -i ''`-Schönheitsfehler zu beheben) |
| mysqlclient | 8.4.10 | **GPL-2.0 + FOSS-Ausnahme** | nativ — **aber GPL ist ein Auslieferungsblocker für eine proprietäre Binärdatei**; MariaDB Connector/C (LGPL-2.1) ist der in `LICENSE_COMPLIANCE_PLAN.md` bereits benannte Ersatz |
| zint | 2.16.0 | BSD-3 | nativ; das Barcode-Backend, das der PNG-Kern von MADBarcodes linkt (mit libpng oben) |

Dazu das C im Baum (`miniz`, `madmath`, `madpng`, `madtar`, `madlib` — alles portabel, alles permissiv lizenziert). Nur die *Verpackungs*-Schicht von Compressor ist Apple-spezifisch (`xcrun`, `-isysroot`, `lipo`, `xcodebuild -create-xcframework`); ein Linux-Treiber wirft all das ab, führt dieselben Upstream-Builds nativ aus und endet mit schlichtem `ar` + Include-Installation. Die iOS-spezifische Komplexität (der zweistufige Host-Tools-Build von mysqlclient, der pro Plattform generierte Header von freetds) *verschwindet* bei nativen Builds. Ein Flag aus dem Audit: der MySQL-Connector von Karl Kraft ist unlizenziert — ersetzen Sie ihn mit dem MariaDB-Wechsel, liefern Sie ihn nicht aus.

---

## 8. Der Build- und Testplan

- **Buildsystem**: CMake für die zwölf headless Frameworks plus die CLI — ein Flagsatz (`clang`, `-fobjc-arc`, `-fblocks`, GNUsteps `gnustep-config --objc-flags`). Der `.momd`-Kopiertanz in `CLI/build.sh` verschwindet mit Phase D, und die Reichweite von `REFRESH_SOURCES` über die Targetgrenze verschwindet mit dem Umzug von `MADOperationRefresh` (`ROADMAP.md` §3.4).
- **Abnahmeschicht**: die Round-Trip-Fixtures in `MAD_CLI.md` §6, unter Linux ausgeführt und byteweise gegen den macOS-/Simulator-Lauf verglichen — Containertreue, v0-Lesbarkeit, Round Trip ohne Cache, Exit-Codes. Der Zeilen-Cache und die JSON/CSV-Ausgabe sind byte-vergleichbar; PDF ist nur strukturell vergleichbar, bis ein Renderer existiert. Diese Fixtures sind auch der *Abdeckungstest für GNUstep Foundation*: früh ausführen, jeden Fehlschlag triagieren, und die Unbekannten aus §5.3 lösen sich empirisch statt durch Lesen von API-Indizes.
- **CI**: ein Linux-Job in der Testmatrix, der die Fixtures ausführt; die Suite bleibt die Simulator-Suite, die sie heute ist.

### 8.1 Der Deployment-Pfad: Container, keine Cross-Kompilierung

Wie wird das tatsächlich gebaut und ausgeliefert?

- **Nicht von macOS aus cross-kompilieren.** Eine Objective-C-Runtime plus GNUstep Base ist host-gekoppelt — sie gegen ein Linux-Sysroot von einem Mac aus cross-zu-kompilieren ist ein Forschungsprojekt, kein Buildschritt. Die iOS-App bleibt von Xcode auf dem Mac gebaut; die Linux-Engine wird *unter Linux gebaut*.
- **Docker ist die Build-Umgebung.** Ein Dockerfile, zwei Stufen: eine Toolchain-Stufe, die clang + libobjc2 2.3 + GNUstep Base aus dem Quellcode baut (für ARC erforderlich — §6), und eine Build-Stufe, die den Linux-Treiber von Compressor für die C-Bibliotheken ausführt (§7) und dann CMake für die zwölf Frameworks und die CLI. Dasselbe Image dient doppelt als CI-Umgebung und als Deployment-Artefakt.
- **Welches Linux unterstützt wird: eine Basislinie, in einem Container.** Wählen Sie eine einzige Basislinie — Debian stable oder ein Ubuntu LTS — und bauen Sie dort, weil die echte Kompatibilitätseinschränkung glibc ist: alles Gelinkte wird aus dem Quellcode gebaut außer der libc, also heißt „unterstütztes Linux“ „die glibc des Images, das wir ausliefern“. Auf der ältesten akzeptierten glibc zu bauen ist die Regel. Einen Container auszuliefern heißt, jeder Docker-fähige Host führt das Produkt ohne Distributionsmatrix aus.
- **Der Workflow ist das Skript-und-Kompilieren, das Sie bereits kennen, automatisiert.** `git clone` auf dem Linux-Builder → Compressor-Rezepte bauen sqlite, zlib, openssl, bzip2, libpng, libarchive, freetds und MariaDB aus dem Quellcode → CMake kompiliert die Frameworks mit einem Flagsatz → `mad` linken → die Round-Trip-Fixtures ausführen (oben) → das Image taggen. Ein Ubuntu-Runner von GitHub Actions ist der übliche Ort dafür bei jedem Commit.
- **Die Rolle von macOS.** Der Mac bleibt der Entwicklungs-Host für die App, die Simulator-CLI und die Referenz-Fixture-Ausgaben. Die beiden Plattformen werden durch git und durch den Byte-Vergleich der Fixtures verbunden — der Linux-Build wird *gegen* die Ausgaben des Macs *geprüft*, was die Portabilitätsgarantie ausführbar macht.

---

## 9. Aufwand und Phasen

Eimer, in der Reihenfolge, in der sie angegangen werden sollten:

| Phase | Arbeit | Charakter |
|---|---|---|
| A | Phase C + D der Speichermigration abschließen | bereits besessene Portabilitätsarbeit; entfernt Core Data, iCloud, Value-Transformer, `.momd` — der einzelne größte Linux-Hebel |
| B | Toolchain-Spike: ein Dockerfile, das clang + libobjc2 + GNUstep Base aus dem Quellcode baut; eine MADFoundation-Teilmenge kompilieren | beweist die Umgebung und wird das Build-/CI-Image; Tage |
| C | Die Shim-Liste aus §4 | begrenzt und aufgezählt — madlog, asl, copyfile, vm_param, CFHost, MADApplication, UIScreen, Hintergrundaufgabe, ~25 CF-Stellen, Ausschlüsse |
| D | **Der Kontrollpunkt**: Datenpfad-Verben grün unter Linux — `inspect`, `schema`, `query`, `refresh` gegen beide Beispiele, Fixtures byte-verglichen | ist dies nach C nicht grün, ist der Schwanz von GNUstep Foundation größer als geschätzt, und *das* ist der Moment, die Neuschreiben-Frage zu überprüfen — nicht vorher |
| E | Export: JSON/CSV (der Python-Vertrag), dann HTML/SVG-Seiten, dann die PDF-Entscheidung (cairo/libharu vs. Rendering auf der macOS-Seite) | reines Foundation zuerst; Renderer zuletzt |
| F | Linux-Treiber von Compressor (native Builds, Matrixspalte, MariaDB-Wechsel, freetds-sed-Behebung) + CMake-Politur + CI-Zeile + das deploybare Image | mechanisch, lizenzgesteuert |

Begründung der Reihenfolge: A ist besessene Arbeit, B ist billig und entschärft alles, C ist aufzählbar, und D ist das ehrliche Go/No-Go. Nichts in E oder F wird gebraucht, um die Frage zu *beantworten*; sie werden nur gebraucht, um *auszuliefern*.

**Status Phase A (2026-10-06).** Core Data ist aus dem Framework MAD heraus: `MADocument` ist ein `UIDocument`, der Legacy-Konverter und das kompilierte Modell leben im App-Target hinter `MADLegacyStoreConversion`, ein konvertiertes Dokument bereinigt seine Core-Data-Dateien, und der Framework-/MADDesigner-Sweep entfernte die verbleibenden Importe, Typen und toten Code. Die Value-Transformer, der Cloud-Bereich des Explorers und die iCloud-Entitlements werden per Benutzerentscheidung behalten — sie sind App-seitig, also blockieren sie den headless Build nicht; der Cloud-Code des Dateimanagers bleibt, wo er ist, ungenutzt (laut Benutzer: für den headless Modus nicht nötig). Was vor B bleibt, sind die Datei-Ausschlüsse aus §4, die der Toolchain-Spike als nötig erweist.

**Status Phase B (2026-10-06).** Der Toolchain-Spike ist grün auf dem Branch `linux-port`, am 2026-10-16 nach `master` gemergt (`524e0d86e`): `Linux/` baut ein Docker-Image — Ubuntu 24.04 mit dem Distributions-clang 18 (die „aus dem Quellcode“-Anforderung in §6 betrifft GNUstep, das gegen libobjc2 gebaut wird, nicht LLVM), plus aus dem Quellcode gebaute libobjc2 2.3, libdispatch 6.1.3, gnustep-make 2.9.3 und gnustep-base 1.31.1, festgeschrieben in `Linux/toolchain.conf` —, kompiliert 23 der 27 Implementierungsdateien von MADFoundation und `madlib.c` gegen GNUstep und führt 15 Testprogramme darin aus (14 portierte Suiten und eine Toolchain-Probe): alle bestehen, mit 5 festgehaltenen Bedarfen und 10 Berichtseinträgen der Probe. `./Linux/build.sh` ist der Einstiegspunkt; die iOS-Suite blieb grün (118 Tests) als Beweis, dass die sechs kleinen Plattform-Guards, die die Arbeit erforderte, auf Apple verhaltensneutral sind.

Die Probe mustert den Großteil der Risikoliste von §5.3 für die Foundation aus, die die Engine tatsächlich verwendet: ARC und Weak-Nulling, Blocks, Exceptions, `@synchronized`, KVO (manuelle und abhängige Schlüssel), die KVO-Zustandsmaschine von `NSOperation`, `NSPredicate predicateWithFormat:@"error != nil"` (MADs exaktes Prädikat), dispatch einschließlich des Abfließens der Hauptwarteschlange unter einem einfachen Programm, JSON, Daten, Plists, Sortierdeskriptoren, Streams und Keyed Archiving auf dem permissiven Pfad — alles besteht. Zwei Lücken werden festgehalten, nicht versteckt: GNUsteps Archiver hat keine Secure-Coding-Unterstützung (`requiringSecureCoding:YES` gibt nil zurück; der permissive Pfad geht im Round Trip) und GNUsteps `NSOperationQueue` entfernt seine `isReady`-Beobachtung bei jeder Benachrichtigung, während MADOperations Zustandsmaschine früher mehr als einmal pro Enqueue `isReady` benachrichtigte — die zweite Entfernung löste eine Exception aus, sodass eine MADOperation unter Linux nicht enqueued werden konnte. Das ist geklärt (2026-10-06, `linux-port`, jetzt in `master`): MADOperation treibt den Zustandsfortschritt ausdrücklich aus `-willEnqueue` und sendet KVO für `isReady`/`isExecuting`/`isFinished` nur bei echten Wertänderungen, sodass die Warteschlange eine Benachrichtigung sieht, wie auf Apple; die Linux-Tests prüfen es schlicht auf beiden Plattformen, und die Bedarfe sanken auf 3. Der Mechanismus ist in `Linux/README.md` niedergeschrieben, neben den ausgeschlossenen Dateien und den kleineren Shims (`NSOperation.name`, `qualityOfService`, `NSDataWritingFileProtection*`, `QOS_CLASS_DEFAULT`, App-Group-Container). Die Datei-Ausschlüsse, die Phase A erwartete, erwiesen sich als genau die vier Dateien aus §4 (`BDHost`, `MADApplication`, `MADKeyChain`, `MADURLFactory`); die Bereinigung der eigenständigen Header, die das Prelude früher überdeckte, ist erledigt (2026-10-06): jeder Header und jede Quelle im Linux-Build importiert, was er verwendet, und `Linux/Compat/MADCompat.h` ist auf die eine echte Plattformlücke reduziert, die Eigenschaft `name` von `NSOperation`.

**Status Phase C (2026-10-06).** Die Shim-Liste aus §4 ist abgearbeitet, und der Build ist kein Spike mehr: alle zwölf headless Frameworks der Tabelle in §3 kompilieren und linken im Image — MADFoundation 26 von 27 Dateien, MADDataStructures 17, MADFileManager 10 von 11, MADCocoaExtensions 7 von 17, MADAPI 8 von 11, MADSqlite3 26, MADTds 1, MADTdsClient 4 von 5, MADMySQL 18 von 19, MAD 150 von 181 —, und ihre Suiten laufen unter ctest: 114 Programme (1098 Tests), alle grün, mit 6 festgehaltenen Bedarfen, jeder Apple-only-Mechanik (Core Data, das kompilierte Modell, `MADocument`, der Konverter), benannt in `Linux/README.md`. Die Abdeckung des am 2026-10-10 gemergten masters (~100 Xcode-Testdateien) ist vollständig portiert — 55 neue Programme, Suite für Suite —, und der Merge fand zwei Apple-seitige Defekte, beide behoben und in `BUGS.md`: die Framework-Targets hatten `$(inherited)` aus ihren Präprozessor-Definitionen verloren (DEBUG war in jedem Debug-Build jedes Frameworks tot), und MADs Dokument-Fixtures teilten einen Speicher über Läufe hinweg. Eine Bibliotheksschicht (`Linux/libraries.conf`, `Linux/lib/libraries.sh`) baut sqlite3, openssl, freetds, zlib, bzip2, libarchive, libpng, zint und mysqlclient nativ ins Image (§7s C-Bibliotheken; nichts wird ausgeliefert). Die Langschwanz-Elemente gingen, wie §4 vorhersagte — die `asl.h`/`vm_param.h`-Importe waren rudimentär, `copyfile(3)` wurde POSIX, `CFHost` wurde `getaddrinfo`, die CF-Stellen wurden ein `CFNumberGetValue`-Shim —, und der UIKit/CoreGraphics-Schwanz wird Datei für Datei mit Gründen ausgeschlossen, nicht portiert (§5.2s Behandlung; `MADocument`, ein UIDocument, und `MADReportFormatter` warten auf Phase D, was ebenso das Problem der CLI wie der Plattform ist). MADs Suiten fanden drei weitere Divergenzen, alle behoben oder geshimmt und in `Linux/README.md` aufgeschrieben: die BOOL-Kodierung der Runtime (`'C'` außerhalb Apples), der fehlende Superklassen-Durchlauf von `class_getProperty()` (beide in `RptqObject` behoben) und ein Stub `+propertyListWithStream:` (geshimmt). Der Port der Testabdeckung fügte drei weitere hinzu, ebenfalls behoben oder geshimmt: `NSOperation.asynchronous`/`-isConcurrent` (eine Compat-Kategorie — ohne sie löste eine endende asynchrone Operation aus `-dealloc` aus), `-coordinateAccessWithIntents:` (seine GNUstep-Implementierung stürzt ab; die Compat-Kategorie ruft den Accessor auf der Warteschlange auf) und schema-lose URLs von `MADURLFactory` (jetzt `+fileURLWithPath:`, was fünf geparkte Koordinator-Tests löste). Die eine Divergenz, die am längsten festgeschrieben blieb — GNUsteps `-localizedCaseInsensitiveCompare:` ist groß-/kleinschreibungssensitiv, sodass die registrierte Kollation von MADSqlite3 Text anders ordnete als auf Apple —, ist jetzt behoben (2026-10-25): die Kollation, die In-Memory-Sortierselektoren und der Comparator des Formatierers laufen alle über eine definierte Ordnung aus eigener Hand (`NSString+Comparison.h`), und der Pin wurde zu Tests der definierten Ordnung, die identisch auf beiden Plattformen gelten. Die Live-Suite `MADTdsClientLiveTests` läuft grün aus dem Image gegen den SQL-Server-Container (29/29), also wird der Treiberpfad unter Linux ausgeübt, nicht nur kompiliert. Phase D — die CLI und die Datenpfad-Verben — ist der nächste Schritt und das Go/No-Go.

**Status Phase D (2026-10-16).** Der Kontrollpunkt ist erreicht: `mad` baut im Image aus `CLI/Source` (dieselben Quellen, aus denen das iOS-Simulator-Werkzeug gebaut wird), linkt die zwölf Frameworks und führt dort den Datenpfad aus. `inspect` berichtet über ein Legacy-v0-Beispiel und ein portables v1-Fixture; `schema` und `query` liefern dieselben Antworten wie das Werkzeug des Macs (byte-identisch bei `schema`); `refresh` füllt den Zeilen-Cache am Sqlite3-Beispiel und ist byte-identisch mit dem Cache des Macs, wenn nach Feldnamen verglichen (76 Zeilen, 21 Spalten); und gegen Live-Server aus dem Image zog `mad refresh` 50 Zeilen aus MySQL 8.4 (`employees`, ein Fetch mit vorbereiteter Anweisung) und 20 aus SQL Server 2022 (`AdventureWorksLT2022`, über freetds). Die Live-Suiten stimmen überein — `MADMySQLLiveTests` 44/44 und `MADTdsClientLiveTests` 29/29 im selben Image —, und der ctest-Lauf umfasst 117 Programme, 1153 Tests, 6 Bedarfe, alle grün.

Zwei Dinge mussten geklärt werden, um dorthin zu gelangen, beide in `Linux/README.md` festgehalten:

1. **Die Dokumentfrage (§5.1, §9 Phase D).** `MADocument` ist ein `UIDocument`, kann also nicht mitkommen. Die Wahl des Benutzers (2026-10-16) war ein headless Dokumentpfad, nicht ein `UIDocument`-Shim in `Compat` und nicht eine Aufteilung von `MADocument`: die Datenhälfte eines Dokuments ist jetzt ein Protokoll, `MADDocumentDataProtocol`, das `MADocument` erfüllt (jedes Mitglied war bereits einer seiner Accessoren) und `MADHeadlessDocument` über denselben `MADDocumentStore` implementiert, den das Dokument der App verwendet. Die Refresh-Kette — mit der Treiberregistratur in `MAD` verschoben (`ROADMAP.md` §3.4, §5.1) — nimmt das Protokoll, also laufen beide Plattformen dieselbe `MADOperationRefresh`; ihr einziger Render-seitiger Zweig ist `#if __APPLE__`, und `mad export` (PDF, Core Graphics) bleibt auf Apple, was die Stufung von §5.2 ist.
2. **Die Treiberregistratur (§3, §5.1).** Der Konstruktor importiert nicht mehr MySQL und TDS: jeder Treiber registriert sich in `+load`, und der Konstruktor schlägt ihn nach Typ nach. Unter Linux werden die Treiberarchive als Whole-Archive gelinkt, weil die Arbeit eines Treibers über *Kategorien* erreicht wird und eine Kategorie eine Nachricht ist, die der Linker nicht sehen kann — die CLI brach bei MySQL ab, bis das behoben war (§ die Compat-Archive-Anmerkung in `Linux/README.md`).

Die GNUstep-Divergenzen, die die CLI hinzufügte: der Verzeichnis-Enumerator (`-enumeratorAtURL:…` liefert URLs mit abgetrenntem enthaltendem Verzeichnis — gemessen, und die Mitgliederliste der CLI verwendet stattdessen `-subpathsAtPath:`) und die Spaltenreihenfolge der SELECT-Liste, die Mengenordnung war und daher von Apples abwich (gleiche Felder, gleiche Zeilen; vermerkt in `Linux/README.md`). **Geklärt am 2026-10-16**, mit der Entscheidung zur Form des JSON-Exports (§10.1 unten): die Reihenfolge ist als Spaltenalias in beiden SQL-Buildern definiert, sodass das erzeugte SQL, der Zeilen-Cache und jeder Export auf beiden Plattformen übereinstimmen (docs/project/registers/BUGS.md, der SELECT-List-Eintrag; die Ordnungstests in `Linux/Tests/MADQuerySelectExpressionTests.m`).

**Status Phase E (2026-10-16, erste Hälfte).** Die Exportnaht ist echt, und die Foundation-Formate laufen hier. `MADReportExporting` + `MADReportExporterRegistry` haben die Form der Treiberregistratur (ein Implementierungsprotokoll, `+load`-Registrierung, ein Nachschlagen nach Namen), und `mad export` wählt ein Format durch sie aus, sodass ein neues Format eine neue Klasse ist (`MAD_CLI.md` §5.3, ROADMAP.md §5.2). `text`, `csv` und `json` sind reines Foundation und erzeugen **byte-identische Ausgabe unter Linux und auf Apple** für das London-Fixture — gemessen mit `sha256sum` am Werkzeug des Macs und am Image (§ der CLI-Abschnitt von `Linux/README.md`; `Linux/Tests/MADReportExporterTests.m` legt dieselben Bytes mit einer FNV-1a-Prüfsumme fest). Die JSON-Form ist entschieden (§10.1): `json` ist der Datenvertrag — die Spalten der Abfrage in Aliasreihenfolge, die Zeilen, das SQL, der Treiber —, und `json-report` ist dasselbe Dokument mit den Abschnitten des gerenderten Berichts als zusätzlichem Mitglied, die Wahl des Benutzers am 2026-10-16: Seiten, Abschnitte in Zeichenreihenfolge und Art, Rahmen und aufgelöster Text jeder Zeile, gebaut aus dem eigenen Seitendurchlauf des Renderers mit nichts Gezeichnetem — also kann es nicht von dem abweichen, was ein PDF zeigt. Es braucht die Render-Hälfte, also registriert es sich überall und berichtet, warum es hier nicht laufen kann. Dieser Durchlauf ist `MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`, das einen nullbaren Kontext nimmt: der PDF-Pfad übergibt seinen eigenen und zeichnet wie zuvor, und json-report übergibt NULL; das erste Protokoll der Render-Hälfte, `MADDocumentRenderProtocol`, ist das, wonach das Format das Dokument fragt. Die verbleibende Hälfte von Phase E — das Berichtsmitglied unter Linux und HTML/SVG — ist der Umzug der Render-Hälfte nach Linux, den die Renderer-Entscheidung des Benutzers (HTML/SVG als Nächstes, PDF zuletzt, §10.2) auf den HTML-Schritt legt. `pdf` ist noch der eigene Zweig der CLI; es wird mit demselben Schritt ein Exporter.

---

**Status Phase E (2026-10-16, zweite Hälfte: der Writer).** Der `.mad`-Writer läuft unter Linux, und beide Plattformen schreiben dieselben Bytes. `MADArchiveManager.reproducible` ist der Opt-in-Modus, den der Benutzer wählte (feste Zeit 2001-01-12T00:00:00Z, uid/gid 0, sortierter Mitgliederdurchlauf; gewöhnliche Speicherungen behalten die Metadaten des Dateisystems), `MADHeadlessDocument` erhielt `-writeToURL:reproducible:error:` (das Speichern der App ohne die UIDocument-Teile), und `mad write` ist das Verb, das es auf beiden Plattformen erreicht. Gemessen: das London-Fixture, auf dem Mac und im Image geschrieben, ist dieselbe 16.261-Byte-Datei, sha256 `09815b24…` (die Speichermigration von SQL-Eingabe Phase A änderte die geschriebenen Bytes; das Fixture selbst bleibt ein Version-1-Speicher); `Linux/Tests/MADArchiveManagerTests.m` legt die Bytes, den Round Trip und den Modus fest. Zwei Linux-only-Defekte standen im Weg und sind behoben (`BUGS.md`, der Byte-Identitäts-Eintrag): der Durchlauf, der nie endete, und `dirname(3)`/`basename(3)`, die den Archivpfad des Aufrufers unter glibc abschnitten. Was der Vergleich abdeckt, ist der Container: die Mitglieder sind die eigenen Bytes des Fixtures. Ein Linux-Writer, der einen Speicher *erzeugt*, erweitert das auf die Speicherschicht.

**Status Phase E (2026-10-16, dritter Teil: die Render-Hälfte und HTML).** Die Render-Hälfte zog nach Linux um, und sie zog als Konformität um, nicht als Fork. Die Antwort des Benutzers zur Form war „ein Formatierer, nicht zwei Pfade, und sie sollen dasselbe rendern“, also:

* `MADReportFormatter` nimmt `id <MADDocumentRenderProtocol>`; das Protokoll erhielt die vier Mitglieder, die der Formatierer liest (`filename`, `storeContext` — es fragte früher nach dem `-managedObjectContext` von MADocument —, `database`, `resetSectionLayoutManagers`) und erbt die Daten-, Cache- und Report-Data-Source-Protokolle, die der Formatierer vom Dokument zuweist.
* Der Seitendurchlauf zog aus `MADPrintPageRenderer` in `MADReportPageBuilder`, eine einfache Foundation-Klasse: dieselbe Lesetransaktion pro Seite, dieselben Elementverweise, dieselbe eine Zeilendarstellung pro Element, wobei das Zeichnen jetzt ein Block ist, den der Aufrufer übergibt (der Renderer übergibt einen, der zeichnet; die Formate übergeben keinen). Der Builder besitzt auch die Geometrie der Render-Seite (US Letter, der 1pt-Beschnitt) und die Vorbereitungssequenz (die Zeilen sortieren, den Formatierer dimensionieren, formatieren), die zuvor im PDF-Zweig der CLI und in json-report kopiert waren.
* `MADDocumentRenderDataSource` ist die eine Implementierung der Lesezugriffe der Render-Hälfte — `MADPrintPageRendererDataSourceProtocol` und `MADReportFormatterDataSource` über einem Dokument —, und sowohl `MADocument` als auch `MADHeadlessDocument` antworten, indem sie sie fragen. Die Körper sind die von MADocument, verschoben; die Seiten der App lesen genau, was sie zuvor lasen.
* `MADHeadlessDocument` erfüllt `MADDocumentRenderProtocol`, also formatiert und durchläuft ein Dokument ohne Fenster jetzt. Der Render-Zweig von `MADOperationRefreshInitialize` schlüsselt auf das Protokoll statt auf `[doc isKindOfClass: [MADocument class]]`.
* Die Elementfamilie kompiliert headless: die Initialisierer von `MADPrintPageElement` sind Foundation (der Text wird dort aufgelöst), und nur die `-drawInRect:`-Körper sind `#if __APPLE__`. Außerhalb Apples ist das Bild des Bildelements die PNG-Bytes des Speichers (`MADElementImage` ist `NSData`), und `-renderedImageData` übergibt sie an die Zeilendarstellung, die die Exporter lesen. `MADElementStylizedText` bleibt Apples — es zeichnet, nicht layoutet.

**Pagination braucht keine Text-Engine**, gemessen statt angenommen: die Anzeigehöhe eines Abschnitts kommt aus `MADSectionLayout` (gespeichertes Rect + Margin + Padding + Border), das im Linux-Build ist und seit Phase C war, also sind die Seitenumbrüche überall dieselben. Textmetriken kommen erst ins Spiel, wenn ein Element *gezeichnet* wird, und der Renderer zeichnet mit `NSLineBreakByTruncatingTail` — eine Zeile, abgeschnitten —, was CSS als `white-space: pre; overflow: hidden; text-overflow: ellipsis` schreibt. Nichts bricht um, also gibt es kein Umbruchmodell zu portieren; keine Font-Engine wurde hinzugefügt.

**`mad export --format json-report` läuft hier**, auf demselben Durchlauf, und die Rahmen, die es berichtet, sind jetzt *Seiten*koordinaten (der Rahmen des Elements, versetzt um seinen Abschnitt), was ein Renderer oder ein Browser braucht.

**Zwei neue Formate, beide auf beiden Plattformen** (der Benutzer wählte beide): `html` ist das Faksimile — ein CSS-Seitenkasten pro durchlaufener Seite, jedes Element absolut an seinem Rahmen positioniert mit seinem aufgelösten Text und seiner gespeicherten Font, Größe, Merkmalen und Ausrichtung; ein Browser druckt es auf dieselben Seiten, die das PDF hat. `html-flow` ist derselbe Bericht umbrechbar — `<section>`s, eine `<table>` pro Abschnitt, ein `<td>` pro Element, das Seitenzubehör einmal ausgegeben; eine Leseansicht, während `--format json` der Datenvertrag bleibt. Beide sind eine UTF-8-Datei mit einem eingebetteten `<style>` und ohne Skript; das CSS des Faksimiles sind die 20 Zeilen oben plus eine Positionierungsregel, und die Stile der Flow-Datei sind eine generierte Klassentabelle (neun Klassen für das London-Fixture).

**`pdf` ist auf der Naht**: `MADReportExporterPDF` registriert sich überall. Auf Apple ist sein Körper Core Graphics + `MADPrintPageRenderer`, unverändert; außerhalb Apples übergibt es dieselben durchlaufenen Seiten an `MADReportExporterPDFCairo`, das sie mit FreeType-Glyphen aus mitgelieferten Liberation-Schnitten in eine Cairo-PDF-Oberfläche zeichnet (docs/developers/build/pdf.md). Die CLI hat keine lokalen Zweige mehr. Der Apple-Umzug war byte-neutral: der deterministische Export des London-Beispiels ist dasselbe 43.177-Byte-, 5-seitige PDF vorher und nachher (`sha256 3eb2f1c4…` auf beiden), gemessen durch Bauen der CLI des vorherigen Commits und Vergleichen. Der headless Writer zielt auf strukturelle Parität, nicht Byte-Parität.

**Was der plattformübergreifende Vergleich sagt.** Der Text jeder Zeile, jeder Rahmen, jede Font, die Seitenzahl und die Dateistruktur sind auf Apple und Linux für das London-Fixture identisch, und ebenso die Bytes: `html`, `html-flow` und `json-report` haben auf beiden Plattformen dieselbe sha256 (`Linux/README.md` enthält die Digests). Dorthin zu gelangen kostete einen Befund und seine Behebung: gerenderte Währung hing früher von der Maschine ab. Der Bericht nimmt jetzt seine Locale *und* seine Dezimalstellenzahl aus dem numerischen Format des Dokuments (der Speicher behält beides; ein Dokument, das es nicht sagt, fällt auf `en_US` zurück, nicht auf die Locale der Maschine), die Elementfabrik zeichnet die Design-Locale auf neuen Elementen auf, und das Währungssymbol wird ausdrücklich geschrieben, mit normalisiertem Yen-Zeichen (GNUstep schreibt es in voller Breite). Ein Vergleich mit 60 Fällen über sechs Locales ist byte-identisch; der vollständige Eintrag steht im Archiv von `BUGS.md`.

**Status Phase F (2026-10-17, teilweise).** Die CLI ist ein Deliverable als Laufzeit-Image, keine Binärdatei in einem Build-Baum. `Linux/Dockerfile` erhielt eine Stufe `runtime` auf `ubuntu:24.04`, die `/usr/local/bin/mad` (die Installationsregel von CMake), die geteilten Objekte, die die CLI linkt (GNUstep Base, libobjc2, libdispatch, libBlocksRuntime, mysqlclient), GNUsteps Laufzeitverzeichnisse, mysqlclients Meldungs- und Charset-Dateien und `chinook.sqlite3` am App-Support-Pfad trägt; sie lässt den Compiler, die Quellen, Tests, Header und statischen Archive zurück. Sie ist 283 MB auf der Platte (66,5 MB komprimiert) gegen das 6,65 GB große Build-Image. `./Linux/build.sh --runtime` baut sie, und `--verify` führt `Linux/verify-cli.sh` darin aus: 30 Prüfungen — die sechs Verben, den festgeschriebenen Digest jedes Offline-Formats, die Verweigerung von `pdf`, die Bytes des reproduzierbaren Writers, die Exit-Codes und die eigene Form des Images (kein clang, cmake, git oder Build-Baum). Grün am 2026-10-17; `--live` fügt die MySQL- und TDS-Refreshes hinzu (32/32). Die Suite erhielt zudem einen `RESOURCE_LOCK` zwischen den beiden Testprogrammen, die das London-Fixture und die Beispieldatenbank teilen — die Parallelität von ctest hatte dieses Paar intermittierend scheitern lassen (35 aufeinanderfolgende grüne parallele Läufe nach der Sperre).

Die Entscheidungen des Benutzers am selben Tag: **keine CI** (der Linux-Port ist ein Machbarkeitsnachweis und ein wiederholbarer Test, kein Release; `./Linux/build.sh --verify` ist die Prüfung) und **keine Veröffentlichung** (nichts wird aus einer Registratur gezogen, also bleibt die GPL-Frage dort, wo §10.3 sie ließ). Der Linux-Treiber von Compressor ist der eine nicht erledigte Teil von Phase F, und er wird für die CLI nicht gebraucht: das Image baut die C-Bibliotheken nativ.

## 10. Entscheidungen für den Benutzer

1. **Die Form des JSON-Exports** (`MAD_CLI.md` §8.3, `MAD_FUTURE.md` §10.5) — das ist der Python-Vertrag; entscheiden Sie ihn zuerst, weil alles in §2 davon abhängt. **Entschieden am 2026-10-16: beides, die Berichtshälfte als eigenes Format.** `--format json` ist der Datenvertrag — ein Umschlag (Format-ID, Dokument/Treiber, das SQL, die Zeilenzahl), `columns` (Schlüssel, Name, Tabelle, Typ) und `rows` als ein Objekt pro Zeile mit JSON-typisierten Werten —, und `--format json-report` ist dieses Dokument plus ein Mitglied `report` (die gerenderten Abschnitte). Damit ist die Reihenfolge der SELECT-Liste als Spaltenalias definiert, sortiert, sodass das erzeugte SQL, der Zeilen-Cache und jeder Export auf beiden Plattformen übereinstimmen (docs/project/registers/BUGS.md, der SELECT-List-Eintrag — zuvor Mengenordnung). Die Datenhälfte ist gebaut (`MADReportExporterJSON`, beide Plattformen); das Berichtsmitglied wartet auf die Render-Hälfte.
2. **Stufung des Renderers** — HTML/SVG zuerst, PDF zuletzt, oder PDF-Worker auf der macOS-Seite? **Entschieden am 2026-10-16: HTML/SVG als Nächstes, PDF zuletzt.** Kein Linux-PDF-Renderer und keine macOS-seitigen Worker: der HTML-Schritt ist auch, wo die Render-Hälfte (`MADReportFormatter`) nach Linux umzieht, was `json-report` und das Testen ebenfalls wollen. `pdf` bleibt bis dahin der Apple-seitige Zweig der CLI. **Erledigt am 2026-10-16 (der HTML-Schritt).** Die Render-Hälfte ist auf Linux, und `mad export` hat keine lokalen Zweige: `pdf` ist ein registrierter Exporter, dessen Körper Apples ist, und es sagt, warum außerhalb Apples. Die weitere Entscheidung des Benutzers am selben Tag: der Linux-PDF-Writer ist der *nächste* Schritt, nicht Teil dieses Schritts, weil die Seitenkästen des HTML-Faksimiles die Geometrie sind, die ein Linux-Writer reproduzieren und zu seinem Test machen muss. Die Form des Writers ist hier für diesen Schritt festgehalten: **Cairo (Zeichnen, PDF-Oberfläche) + Pango (Layout, Umbruch) + FreeType/HarfBuzz**, der Stack, den GTK/WebKit/Firefox verwenden und der Linux dem Kern von Core Graphics + Core Text am nächsten bringt — C-APIs, aus Objective-C aufgerufen wie freetds und sqlite3 bereits, also kein Impl-Wrapper nötig. Lizenzen: Cairo LGPL-2.1/MPL-1.1 dual, Pango LGPL-2.1, HarfBuzz MIT, FreeType FTL/GPLv2-Dual; das Projekt liefert bereits LGPL aus (FreeTDS, `LICENSE_COMPLIANCE_PLAN.md` §4), und das Linux-Image ist ein Server-Build, also ist es eine bekannte Klasse von Verpflichtung. `libharu` ist die permissive Alternative, hat aber keine Layout-Engine; Skia ist von den Fähigkeiten am nächsten, aber ein schwerer C++-Build. **Nicht erreichbar: byte-identische PDFs über Plattformen** — der Writer von Core Graphics lässt sich nicht reproduzieren —, also sind die Ziele dieselben Seiten, Kästen, Texte und Fonts, mit metrisch kompatiblen Ersatzschriften für Apples Fonts (die Standardfamilie von `MADFont` ist Helvetica Neue, die Linux nicht hat). **Erledigt am 2026-11-20 (die PDF-Schließung).** Der Stack ist Cairo (PDF-Oberfläche) + FreeType, ohne Pango: der Durchlauf übergibt jeder Zeile ihren Rahmen, Text, Font, Größe, Merkmale und Ausrichtung, also gibt es kein Layout zu tun — nur Glyphen-Vorschübe und die eigene `kern`-Tabelle des Schnitts, die FreeType liefert. Cairo 1.18.6 (MPL-1.1) und pixman 0.46.4 (MIT) werden statisch gebaut; die Liberation-Schnitte (SIL OFL 1.1) sind die Ersatzschriften für die Apple-Fonts. `MAD_PDF_LINUX.md` hält fest, was landete, die Font-Zuordnungsrichtlinie und den gemessenen Rest. Das Ziel bleibt strukturell: die Bytes von Core Graphics sind nicht reproduzierbar.
3. **Zeitpunkt mysqlclient → MariaDB Connector/C** — der GPL-Blocker steuert jede ausgelieferte Binärdatei; der Ersatz ist bereits in `LICENSE_COMPLIANCE_PLAN.md` benannt.
4. **Toolchain-Politik** — aus dem Quellcode gebautes clang/libobjc2/GNUstep (für ARC nötig) ist ein Wartungsbekenntnis; akzeptieren Sie es oder bleiben Sie auf macOS-Hosts.
5. **Der Neuschreiben-Auslöser** — Phase D von §9 ist der messbare Kontrollpunkt; bis er scheitert, gilt die Empfehlung: eine Objective-C-Engine, aus Python über die CLI-Grenze aufgerufen.
6. **Die Build-Basislinie** — Docker auf einer Debian-stable- oder Ubuntu-LTS-Basis, unter Linux gebaut statt von macOS cross-kompiliert (§8.1). Die Wahl legt die unterstützte glibc-Untergrenze fest, also treffen Sie sie einmal und bewusst.
