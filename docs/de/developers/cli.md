---
layout: default
lang: de-DE
title: "Das Kommandozeilenwerkzeug `mad`"
description: "`.mad`-Dokumente ohne UI öffnen, inspizieren, abfragen, aktualisieren und exportieren."
---

# `mad` -- die MAD Designer-Kommandozeilenschnittstelle

Diese Seite beschreibt das Kommandozeilenwerkzeug `mad`: die Einbettungsoberfläche der Engine und den schnellsten Weg, ein `.mad`-Dokument ohne die App durchzuspielen. Lesen Sie zuerst die Formatspezifikation, falls Container und Speicher für Sie neu sind.

Dieses Dokument definiert ein Kommandozeilenwerkzeug, das `.mad`-Dokumente ohne Benutzeroberfläche öffnet, inspiziert, aktualisiert und exportiert.

Es existiert, weil die Anwendung die beiden Orte nicht erreichen kann, an die sie muss. Sie kann auf einem Mac nicht als Mac-Anwendung laufen und unter Windows überhaupt nicht, weil ihre gesamte Präsentationsschicht UIKit ist. Eine CLI braucht nichts davon: der Datenpfad -- das Dokument öffnen, die Abfrage ausführen, den Cache füllen, den Bericht rendern -- ist bereits fast vollständig frei von UIKit (siehe §4). Die CLI zuerst zu bauen ist daher kein Umweg um die Plattformarbeit herum; sie **ist** die Plattformarbeit, in der Reihenfolge ausgeführt, die bei jedem Schritt etwas Brauchbares erzeugt.

---

## 1. Umfang

**Im Umfang.** Eine einzelne Binärdatei, `mad`, die:

- ein `.mad`-Dokument öffnen und berichten kann, was darin ist
- das Datenbankschema ausgeben kann, gegen das das Dokument gebaut wurde
- die Abfrage ausgeben kann, die das Dokument definiert, als SQL
- sich mit der Quelldatenbank verbinden, die Abfrage ausführen und den Zeilen-Cache füllen kann
- einen gerenderten Bericht exportieren kann

**Bewusst außerhalb des Umfangs.** Alles, was ein Dokument bearbeitet. Die CLI liest und führt Dokumente aus; sie entwirft sie nicht. Die Argumentanalyse, die Verben und die Exit-Codes sind die gesamte Oberfläche.

---

## 2. Warum zuerst eine CLI

| | CLI | Mac-App |
|---|---|---|
| Braucht ein UI-Toolkit | nein | AppKit (Neuschreiben) oder Catalyst (abgelehnt) |
| Braucht portable Frameworks | **ja** | ja |
| Braucht einen portablen Zeilen-Cache | **ja** | ja |
| Braucht definiertes `.mad` | **ja** | ja |
| Liefert etwas, das gefragt war | ja | ja |
| Arbeit, die bei einer Formatänderung weggeworfen wird | keine | die UI |

Alles, was die Mac-Anwendung braucht, um zu existieren -- portable Frameworks, ein definiertes Dateiformat, für mehr als eine Plattform gebaute Bibliotheken -- braucht die CLI zuerst. Den UI-Port zuerst zu machen wäre der teure Weg, dieselben Probleme zu entdecken. Die Mac-Anwendung bleibt eine separate Entscheidung, später getroffen, mit bereits portablen Frameworks.

---

## 3. Kommandooberfläche

```
mad <command> [options] <document.mad>
```

### `mad inspect <doc.mad>`

Liest nur den Container. Keine Datenbankverbindung, kein Core Data.

```
$ mad inspect London.mad
London.mad
  format      v0 (bzip2 tar, no magic header)
  generator   MAD Designer
  version     1
  store       StoreContent/analyitics (SQLite 3.43.2, 126 pages)
  wal         present, 313152 bytes (not checkpointed)
  thumbnail   none
  elements    14 sections, 63 elements
```

Das ist das Verb, das beweist, dass `MAD_FORMAT.md` §7 umgesetzt ist: es muss an einem v0-Beispiel funktionieren. Es ist auch das Verb, das die Gefahren des Formats sichtbar macht -- H2 (das nicht gecheckpointete WAL) wird gemeldet, statt still erlitten.

### `mad schema <doc.mad>`

Gibt das in der Dokumentdefinition erfasste Datenbankschema aus: den Treiber, die nach Namen sortierten Tabellen und die Felder jeder Tabelle mit ihrem Anzeigetyp und einer `pk`-Markierung. Es liest den zur Erstellungszeit gespeicherten Snapshot und braucht daher keine Zugangsdaten und keine Quelldatenbank. (Der ursprüngliche Plan war hier, SQL `CREATE TABLE` auszugeben; der Snapshot speichert die Abstraktion `MADDataType` statt der Typnamen jedes Quelldialekts, also braucht ein getreues `CREATE TABLE` eine Zuordnung pro Dialekt, die es noch nicht gibt. Die lesbare Auflistung ist das, was das Werkzeug bis dahin erzeugt.)

### `mad query <doc.mad>`

Gibt das SQL aus, das die Abfrage des Dokuments erzeugt, ohne es auszuführen. Das ist die Funktion, um die herum die Anwendung gebaut ist -- der Benutzer stellt Tabellen, Joins und Filter zusammen, und die Software schreibt das SQL --, also ist ihre Offenlegung das natürliche erste nicht-triviale Verb.

```
$ mad query London.mad --format sql
SELECT ... FROM ... WHERE ...
```

### `mad refresh <doc.mad>`

Verbindet sich mit der Quelldatenbank, führt die Abfrage aus und füllt den Zeilen-Cache. Das ist der Datenpfad, und es ist das Verb, auf dem der Rest beruht.

```
$ mad refresh London.mad --credentials user:pass
refreshed 148,392 rows in 1.21 s (122,638 rows/s)
cache  ~/Library/Caches/MADDesigner/<id>/<tag>.maddb
```

Optionen: `--credentials`, `--host`, `--port`, `--database`, `--no-cache` (ohne Persistieren ausführen), `--rows N` (nach N Zeilen stoppen, für Smoke-Tests).

`--rows` existiert, weil es das Verb in CI gegen einen echten Server testbar macht, ohne eine Million Zeilen zu ziehen, und weil der Benchmark in `MADDataTableFastBenchmarkTests` bereits beweist, dass der Pfad im großen Maßstab messbar ist.

### `mad export <doc.mad>`

Rendert den Bericht und schreibt ihn aus.

```
$ mad export London.mad --format pdf  --out London.pdf
$ mad export London.mad --format json --out -          # to the standard output
```

Die Formate sind die Naht des Exports (§5.3): jedes ist eine bei `MADReportExporterRegistry` registrierte Klasse, und der Nutzungstext nennt, was der Build hat.

| Format | Schreibt | Wo es läuft |
|---|---|---|
| `pdf` | den gerenderten Bericht (Seiten, gezeichnet) | Apple: UIKit's `UIPrintPageRenderer`, Core Graphics; Linux sagt, warum nicht |
| `html` | den gerenderten Bericht als eine HTML-Datei, ein Seitenkasten pro Seite, aus einem Browser gedruckt | beide Plattformen |
| `html-flow` | den gerenderten Bericht als umbrechbares HTML, eine Tabelle pro Abschnitt | beide Plattformen |
| `text` | die Zeilen als Tabelle fester Breite | beide Plattformen |
| `csv` | die Zeilen als RFC-4180-CSV | beide Plattformen |
| `json` | das Schema und die Zeilen als JSON (§8.3) | beide Plattformen |
| `json-report` | `json` plus die Abschnitte des gerenderten Berichts | beide Plattformen |

`--out` ist für die Foundation-Formate optional -- fehlt es oder ist es `-`, wird die Standardausgabe geschrieben -- und für `pdf` erforderlich. Die Foundation-Formate schreiben für dasselbe Dokument auf Apple und Linux dieselben Bytes (`Linux/README.md`; die Exporte der beiden Plattformen des London-Fixtures sind per Digest gleich).

**Die definierte Reihenfolge.** Die Gruppenreihenfolge des Exports ist Teil dieses Vertrags, also ist sie eine definierte Reihenfolge, nicht die der Plattform: Textschlüssel vergleichen ohne Rücksicht auf Groß-/Kleinschreibung und dann nach Codepunktreihenfolge über die UTF-8-Bytes. Die Case-Fold ist die einfache (eins-zu-eins) Case-Fold von Unicode 17.0.0, gehalten als eingecheckte Tabelle (`MADStringOrderingTable` in `MADFoundation/Source/NSString+Comparison.m`, erzeugt aus den Status-C/S-Einträgen der `CaseFolding.txt` des UCD) -- ASCII und jedes Unicode-Paar, das die Tabelle abbildet, folden; alles andere, einschließlich diakritischer Zeichen, vergleicht als eigener Codepunkt. Weil die Fold jeden Buchstaben in den Kleinbuchstabenbereich schickt, der jedem ASCII-Satzzeichenbyte folgt, sortiert ein satzzeichenführender Schlüssel (`[1997] Black Light Syndrome`) vor einem wortführenden (`Core`) -- dieselbe Stelle, an die SQLites `NOCASE` ihn setzt. UTF-8 bewahrt die Codepunktreihenfolge, also ist der Bytevergleich der Codepunktvergleich. Ein Comparator (`-[NSString mad_orderedCompare:]` und sein C-Kern `MADStringOrderedCompareUTF8`) treibt alle drei Stellen: die Kollation `LSASC` des Caches, die Sortierdeskriptoren im Speicher (`MADDataTypeSelectorForSorting`) und den Gruppengrenzenvergleich des Berichtsformatierers. Die Reihenfolge ist deterministisch über Plattformen, OS-Releases und Locales hinweg; sie änderte sich am 2026-10-25 von der lokalisierten Reihenfolge, also sind Exporte vor diesem Datum nicht gleich den Exporten danach.

**`json-report`** (`MAD_LINUX.md` §10.1, §9 Phase E) ist dasselbe Schema mit dem gerenderten Bericht als Mitglied `report`: Seiten, die Abschnitte jeder Seite in Zeichenreihenfolge (Typ, Gruppenebene, Sichtbarkeit), die Zeilen jedes Abschnitts und Art, Rahmen und aufgelösten Text jedes Elements jeder Zeile. Es ist das, was Tests und ein Renderer lesen, und es ist die eigene Struktur des Renderers -- der Seitendurchlauf mit nichts Gezeichnetem --, also kann es nicht von dem abweichen, was ein PDF zeigt. Der Rahmen ist, wo die Zeile **auf der Seite** sitzt (der Rahmen des Elements, versetzt um seinen Abschnitt), was ein Renderer oder ein Browser braucht. Die Render-Hälfte wird jetzt unter Linux kompiliert, also läuft dieses Format auf beiden Plattformen.

**`html`** ist das seitenförmige Artefakt, das ein Browser druckt: ein CSS-Seitenkasten pro durchlaufener Seite, jedes Element absolut an seinem Rahmen positioniert, sein aufgelöster Text in Font, Größe, Gewicht, Neigung, Dekoration und Ausrichtung des Elements selbst. Die Zeilenumbruchregel ist die des Renderers (`NSLineBreakByTruncatingTail` -> `white-space: pre; overflow: hidden; text-overflow: ellipsis`). Es ist eine UTF-8-Datei mit einem eingebetteten Style-Block und ohne Skript. **`html-flow`** ist derselbe Bericht ohne die Seiten: ein `<section>` pro Berichtsabschnitt, eine `<table>` pro Abschnitt, ein `<td>` pro Element, Seitenzubehör einmal ausgegeben und eine generierte Klasse pro eigenständigem Elementstil. Es ist eine Leseansicht; `json` ist der Datenvertrag. Keines trägt Farben (die Farbspalten des Speichers haben heute auf keiner Plattform einen Leser) oder unter Linux Bilder (der Apple-Pfad zeichnet sie aus `UIImage`; ein Linux-Export platziert den leeren Kasten).

Das Rendern nach PDF geht über `MADPrintPageRenderer`; der Share-Sheet-Wrapper `MADActivityItemProviderPdf` ist sein anderer Aufrufer, und `MADActivityItemProviderDelegate.h` ist das Protokoll, mit dem er spricht. Alle drei leben im Framework `MAD` statt in der App. Was PDF nicht ist, ist **headless**: es ist UIKit's `UIPrintPageRenderer`, weshalb es das eine Format ist, das noch auf der Seite der CLI implementiert wird (siehe §5.3).

### `mad write <doc.mad> --out <copy.mad>`

Schreibt das Dokument als `.mad` aus -- eine *Kopie*: das Verzeichnis mit den Innereien, in das das Dokument gelesen wurde, erneut archiviert mit dem v1-Header. Es bearbeitet nicht das gelesene Dokument, und die CLI entwirft weiterhin keine Dokumente (§1); wofür dieses Verb da ist, ist die Byte-Identitätsanforderung -- dasselbe auf zwei Plattformen geschriebene Dokument muss dieselbe Datei sein -- und das Round-Trip-Fixture von §6.1, das einen Writer braucht, den ein Skript ausführen kann.

```
$ mad write London.portable.mad --out copy.mad --reproducible
wrote /tmp/copy.mad (16261 bytes, reproducible)
```

`--reproducible` legt fest, was die Uhr und das Dateisystem sonst ins Archiv stempeln würden: eine feste Änderungszeit (2001-01-12T00:00:00Z, derselbe Zeitpunkt, auf den der PDF-Export seine Daten festlegt), Besitzer und Gruppe 0 und einen sortierten Mitgliederdurchlauf (`MADArchiveManager.reproducible`). Ohne dies wird ein gewöhnliches Speichern geschrieben, mit den echten Metadaten der Mitglieder. Das Dokument wird auf beiden Plattformen headless geöffnet (`MADHeadlessDocument`), also laufen die beiden Seiten des Vergleichs denselben Writer, und dasselbe Dokument schreibt dort dieselben Bytes (16.261 Bytes beim London-Fixture, `Linux/README.md`).

### Globale Optionen

| Option | Bedeutung |
|---|---|
| `--verbose` | den Datenpfad in jeder Stufe protokollieren |
| `--quiet` | alles außer dem Ergebnis unterdrücken |
| `--credentials user:pass` | Zugangsdaten der Quelldatenbank; sonst der Schlüsselbund |
| `--host <name>` | Überschreibung des Hosts der Quelldatenbank (refresh, export) |
| `--port <n>` | Überschreibung des Ports der Quelldatenbank, 1-65535 (refresh, export) |
| `--database <name>` | Überschreibung des Namens der Quelldatenbank (refresh, export) |
| `--no-keychain` | den Schlüsselbund nie berühren |
| `--format <name>` | Ausgabeformat |
| `--out <path>` | Ausgabepfad; Standard stdout |
| `--deterministic` | die Daten und die Kennung des Exports festlegen, damit zwei Läufe über unveränderte Daten byte-identisch sind |
| `--reproducible` | die Eingaben des `.mad`-Archivs festlegen -- Zeit, Besitz, Mitgliederreihenfolge (`write`) |

Die Verbindungsdefinition -- Host, Port und Datenbankname -- ist Teil des portablen Speichers des Dokuments; Benutzername und Passwort sind es nie. `--host`, `--port` und `--database` überschreiben die gespeicherte Verbindung nur für diesen Lauf, sodass ein eingechecktes Dokument gegen einen CI-Service-Container laufen kann, ohne umgeschrieben zu werden. Was nicht angegeben ist, behält seinen gespeicherten Wert. Sie werden bei einem Sqlite3-Dokument, dessen Verbindung eine Datei ist, und bei den Verben, die sich nicht verbinden (`inspect`, `schema`, `query`, `write`), einfach nicht verwendet. Zugangsdaten bleiben `--credentials`; der Speicher enthält keinen Benutzernamen und kein Passwort.

### Exit-Codes

| Code | Bedeutung |
|---|---|
| 0 | Erfolg |
| 1 | Nutzungsfehler |
| 2 | Dokument konnte nicht gelesen werden oder ist kein `.mad` |
| 3 | Quelldatenbank nicht erreichbar oder Zugangsdaten abgelehnt |
| 4 | die Abfrage ist auf dem Server gescheitert |
| 5 | Export gescheitert |

Getrennte Codes zählen, weil die erste echte Verwendung dieses Werkzeugs ein Skript ist, und ein Skript muss „das Dokument ist schlecht“ von „der Server ist aus“ unterscheiden können.

---

## 4. Was existieren muss, bevor die CLI gebaut werden kann

Der Datenpfad ist bereits nahezu frei von UIKit. Das ist gemessen, nicht geschätzt:

| Framework | Dateien mit UIKit-Import | Von der CLI benötigt |
|---|---|---|
| `MADDataStructures` | 0 / 37 | ja |
| `MADFileManager` | 0 / 31 | ja |
| `MADSqlite3` | 0 / 65 | ja |
| `MADMySQL` | 0 / 42 | ja |
| `MADTds` / `MADTdsClient` | 0 / 3, 0 / 9 | ja |
| `Scrimpter` | 0 / 48 | nein |
| `MADFoundation` | 4 / 66 | ja |
| `MADAPI` | 3 / 34 | teilweise |
| `MAD` | 28 / 464 | teilweise |

Vier Dateien in `MADFoundation` tragen die gesamte UIKit-Abhängigkeit des Basisframeworks:

| Datei | UIKit-Verwendung | Behandlung |
|---|---|---|
| `MADApplication.{h,m}` | ein `UIApplication`-Wrapper | von der CLI nicht benötigt; vom headless Target ausgeschlossen |
| `MADURLFactory.m:32` | `UIScreen.mainScreen.scale > 1.0` | ein Aufruf; außerhalb von iOS 2.0 zurückgeben |
| `MADOperation.m:550-563` | `beginBackgroundTaskWithName:` | eine Funktion, geschützt durch `#if TARGET_OS_IPHONE` |

Der Autor hat die letzte bereits markiert (`MADOperation.m:21`): *„Wish I didn't have to import UIApplication here, but it's really the cleanest way.“* Für einen headless Build ist sie nicht der sauberste Weg, und sie ist die einzige Stelle im Basisframework, an der das gilt.

Die drei UIKit-Dateien von `MADAPI` sind Verbindungs-*View-Controller* und einfach nicht Teil eines headless Targets.

### 4.1 Der Refresh-Kern muss umziehen

Die eine substanzielle Arbeit ist diese. Die Refresh-Orchestrierung liegt **im App-Target, nicht in einem Framework**:

| Datei | Zeilen | UIKit-Symbole | Rolle |
|---|---|---|---|
| `MADDesigner/Source/MADOperationRefresh.m` | 131 | **0** | baut das SQL, führt es aus, schreibt den Cache |
| `MADDesigner/Source/MADOperationRefreshReload.m` | 196 | 3 | Neuladen auf der UI-Seite |
| `MADDesigner/Source/MADRefreshOperationReload.m` | 132 | 1 | Neuladen auf der UI-Seite |

`MADOperationRefresh.m` importiert nur `MADAPI`, `MADFoundation` und `MAD` und berührt kein UIKit. Es ist bereits das Refresh-Verb der CLI; es liegt nur im falschen Target. Es zieht ins Framework `MAD` um, und die beiden `Reload`-Operationen bleiben in der App zurück, was ihre Namen die ganze Zeit gesagt haben.

### 4.2 Das headless Target

Eine Buildkonfiguration von `MADFoundation`, `MADAPI` und `MAD`, die ohne UIKit kompiliert, plus das CLI-Target selbst. Mechanisch ist das `SUPPORTED_PLATFORMS` erweitert um `macosx`, die Bibliothekssuchpfade pro SDK aus `LIBRARIES.md` §6 und die drei Dateiausschlüsse oben.

**Erledigt unter Linux, 2026-10-16** (`MAD_LINUX.md` §9 Phase D), und so erledigt: das headless Target sind die zwölf Frameworks, die `Linux/CMakeLists.txt` gegen GNUstep kompiliert, und die CLI ist ein Target daneben. Das Stück, das §4.1 dem Framework `MAD` zuwies -- die Refresh-Kette --, ist dorthin umgezogen, und das Stück, das er nicht vorhersah -- `MADocument`, ein `UIDocument`, auf dem `MADCLIDocument` aufbaute --, wird beantwortet durch `MADHeadlessDocument` hinter `MADDocumentDataProtocol`: dieselbe Datenhälfte, ohne Dokumentlebenszyklus und ohne etwas zu rendern. `inspect`, `schema`, `query` und `refresh` sind auf beiden Plattformen dieselben Quellen; `export` ist PDF und bleibt auf Apple (§5.2, §9's Staging). Ein macOS-Target gehört weiterhin zu Track 5.1, aber es hat jetzt die Naht und die Dokumentklasse, die ihm fehlten.

---

## 5. Design

### 5.1 Eine Binärdatei, keine Frameworks im Weg

`mad` linkt die headless Frameworks direkt. Es lädt nicht das App-Bundle und darf nicht verlangen, dass das Core-Data-Modell in einer Build-Phase vorhanden ist -- eine Einschränkung, auf die die Testsuite bereits gestoßen ist (siehe die Anmerkung zu `MADTestReportFormatter` im Projektgedächtnis).

### 5.2 Das Refresh-Verb verwendet den gemessenen Pfad wieder

`mad refresh` muss denselben Code aufrufen, den die Anwendung aufruft:
`MADOperationRefresh` → `MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:`
→ `<MADDataTableWriting>`. Es darf ihn nicht neu implementieren. Der in `MADDataTableFastBenchmarkTests` hinzugefügte Benchmark misst genau diesen Pfad bei 200.000 Zeilen (1,16 s Aufnahme, 2,5 MB transient), also zeigt sich eine CLI, die ihn verschlechtert, als fehlschlagender Test statt als Beschwerde eines Nutzers.

### 5.3 Export ist ein Protokoll, kein Switch

`MAD_FORMAT.md` beschreibt Dokumente; Dokumente enthalten Berichtselemente. Export sollte ein erweiterbarer Punkt sein, passend zum erklärten Ziel des Projekts, dass Entwickler „neue Dokumentexportformate erstellen (z. B. Export nach PDF und JSON)“. Definieren Sie `<MADReportExporting>` mit einer Methode und registrieren Sie Implementierungen, sodass `--format json` eine neue Klasse ist statt ein neuer Zweig in einem Switch.

**Erledigt 2026-10-16**, in der Form, die das Treiberregister von §5.1 bereits hat: `MADReportExporting.h` ist das Protokoll (Name, Endung, ob es `--out` braucht, ob dieser Build es erzeugen kann und eine Exportmethode), `MADReportExporterRegistry` ist das Nachschlagen, und jeder Exporter registriert sich in `+load` -- also hat ein Prozess die Formate, die er linkt, und die CLI fragt eines nach Namen ab. `text`, `csv` und `json` sind die eigenen des Frameworks (`MADReportExporterText/CSV/JSON`, reines Foundation, beide Plattformen); `MADReportExportSource` ist die eine Stelle, an der ein Dokument als Spalten und Zeilen gelesen wird, sodass die Formate nicht darüber uneinig sein können, was ein Dokument ist; und `MADReportExportWriter` ist die eine Stelle, an der Bytes eine Datei oder die Standardausgabe erreichen.

`json-report`, `html` und `html-flow` liegen ebenfalls auf der Naht, gebaut auf dem Protokoll der Render-Hälfte (`MADDocumentRenderProtocol`: ein Dokument, das seine Zeilen bereitstellen, formatieren und seinen Formatierer übergeben kann) und auf einem Seitendurchlauf (`MADReportPageBuilder`). **`pdf` liegt jetzt ebenfalls auf der Naht**: `MADReportExporterPDF` registriert sich überall, sein Körper ist der von Core Graphics (Apples), und außerhalb Apples antwortet es mit `+isAvailable NO` und dem Grund (`MAD_LINUX.md` §10.2: der Linux-Writer ist der nächste Schritt). Die CLI hat keine lokalen Zweige mehr; jedes Format, `pdf` eingeschlossen, wird im Register nachgeschlagen.

### 5.4 Zugangsdaten

Die CLI darf nie nachfragen. Sie nimmt `--credentials`, oder liest den Schlüsselbund, den die Anwendung geschrieben hat, oder scheitert mit Exit-Code 3. `--no-keychain` existiert, damit ein Testlauf die echten Zugangsdaten eines Entwicklers weder lesen noch schreiben kann.

### 5.5 Ausführen: das Linux-Image

`Linux/build.sh --runtime` baut `mad-cli:latest`, eine reine Laufzeitschicht mit der CLI im PATH, den geteilten Bibliotheken, die sie linkt, und der Sqlite3-Beispieldatenbank -- kein Compiler, keine Quellen, keine Test-Binärdateien (283 MB auf der Platte; `Linux/README.md` enthält den Inhalt). Ein Dokument wird eingebunden, nicht gespeichert:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

Das Image wird veröffentlicht (2026-10-26, die frühere Nicht-Veröffentlichungsentscheidung umkehrend) als `ghcr.io/mthomason/mad`, getaggt mit `latest` und dem kurzen SHA des Commits, gepusht von `.github/workflows/publish-image.yml` bei jedem Push auf master (plus `workflow_dispatch`). Die veröffentlichten Tags sind **linux/amd64**, von CI auf ubuntu-latest gebaut; das lokale `mad-cli:latest` des Macs ist arm64, und auf Apple Silicon braucht der veröffentlichte Tag `--platform linux/amd64` (Lauf unter Emulation; ohne das Flag scheitert der Pull mit `no matching manifest`). Dieselben Verben über das veröffentlichte Image:

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Ein Sqlite3-Dokument löst seinen gespeicherten Datenbanknamen gegen das benutzerspezifische Application-Support-Verzeichnis auf, das im Image `/root/GNUstep/Library/ApplicationSupport` ist; `chinook.sqlite3` liegt dort, also aktualisieren sich die Fixtures London und Music ohne Einrichtung. Der Zeilen-Cache lebt unter demselben Home und ist pro Container; jeder Export aktualisiert das Dokument selbst, also muss ein Cache nicht zwischen Läufen bestehen bleiben. Die LGPL-Komponenten im veröffentlichten Image verpflichten zu Relink-Angeboten; das schriftliche Angebot in `ThirdParty/Licenses/README.md` benennt das Image (`THIRD_PARTY_LICENSES.md` §9 ist der Registereintrag).

`Linux/build.sh --verify` baut das Image neu und führt die wiederholbare Prüfung aus: alle sechs Verben auf den Fixtures, den festgeschriebenen Digest jedes Formats, die Verweigerung von `pdf`, die Bytes des Writers und die Exit-Codes (`Linux/verify-cli.sh`; `--live` fügt die drei Live-Datenbanken hinzu).

---

## 6. Testen

Das Format und die CLI sind durch **Round-Trip-Fixtures** festgeschrieben, nicht durch Prosa:

1. **Containertreue.** `Music.mad` und `London.mad` entpacken, neu packen und prüfen, dass die Mitgliederliste und die Bytes jedes Mitglieds unverändert sind. Das schreibt `MAD_FORMAT.md` §2 fest und erkennt H4 (verborgene Dateien) sofort. **Gelandet 2026-10-16** als Round Trip von `Linux/Tests/MADArchiveManagerTests.m` -- `mad write` schreibt den Container jetzt auf beiden Plattformen --, mit den Bytes des reproduzierbaren Modus festgeschrieben gegen die des Macs.
2. **v0-Lesbarkeit.** `mad inspect` an beiden ausgelieferten Beispielen muss gelingen und die Werte aus `MAD_FORMAT.md` §2 berichten -- einschließlich des nicht gecheckpointeten WAL, was die Prüfung ist, die beweist, dass die WAL-Gefahr gemeldet statt ignoriert wird.
3. **Round Trip ohne Cache.** Ein Dokument öffnen, aktualisieren, exportieren, schließen, erneut öffnen. Das zweite Öffnen darf das Netzwerk nicht brauchen. Das schreibt §5 des Formatdokuments fest -- dass der Cache abgeleitet und extern ist.
4. **Maßstab.** `mad refresh --rows 200000` gegen eine lokale SQLite-Quelle, geprüft gegen dieselben Obergrenzen, die der Benchmark verwendet, sodass die CLI nicht still zum langsamen Pfad werden kann.
5. **Exit-Codes.** Ein Test pro Zeile der Tabelle in §3, angetrieben durch absichtlich fehlerhafte Eingaben.

Fixtures liegen neben den Beispielen, die sie testen. Tests, die einen echten MySQL-, SQL-Server- oder PostgreSQL-Server brauchen, **überspringen** sich, wenn keiner erreichbar ist, der bestehenden Konvention in `MADMySQLLiveTests.m`, `MADTdsClientLiveTests.m` und `MADPostgresLiveTests.m` folgend.

---

## 7. Phasen

| Phase | Lieferung | Hängt ab von |
|---|---|---|
| 0 | `MAD_FORMAT.md`, `MAD_CLI.md`, `LIBRARIES.md` | -- |
| 1 | Buildsystem der Bibliotheken, sqlite-Flags festgeschrieben | Phase 0 |
| 2 | Suchpfade pro SDK; macOS-Slices verdrahtet | Phase 1 |
| 3 | Headless-Teilmenge; `MADOperationRefresh` nach `MAD` verschoben | Phase 2 |
| 4 | Target `mad`: `inspect`, `schema`, `query` | Phase 3 |
| 5 | `mad refresh` | Phase 4 |
| 6 | `mad export` (PDF zuerst) | Phase 5 |
| 7 | Round-Trip-Fixtures in die Testmatrix verdrahtet | Phase 6 |

Die Phasen 4-6 sind nach Abhängigkeit geordnet, nicht nach Schwierigkeit: `inspect` braucht nur den Container, `query` braucht das Dokumentmodell, und `refresh` braucht eine Datenbankverbindung.

---

## 8. Offene Fragen

1. **Wird die CLI ausgeliefert, oder ist sie ein Entwicklerwerkzeug?** Das entscheidet, ob sie Code-Signierung, Notarisierung und einen Installer braucht, und ob `--credentials` ein Klartextargument akzeptieren darf oder einen Dateideskriptor nehmen muss.
2. **Soll `mad` den Zeilen-Cache aus einer externen Datei akzeptieren?** Ein gepacktes `.mad` (§8.3 des Formatdokuments) würde Offline-Export möglich machen. Noch braucht es niemand.
3. **Wie sieht die JSON-Exportform aus? — beantwortet 2026-10-16: beides, die Berichtshälfte als eigenes Format.** `--format json` ist der Datenvertrag, `--format json-report` fügt den gerenderten Bericht als zusätzliches Mitglied hinzu. Die Form liegt in `MADReportExporterJSON.h`, implementiert von `MADReportExporterJSON` (die Datenhälfte, beide Plattformen) und `MADReportExporterJSONReport` (das Berichtsmitglied, wo die Render-Hälfte ist). Ihre Spalten sind die der Abfrage selbst, in der Reihenfolge, die die SELECT-Liste definiert -- der Spaltenalias, sortiert (`BUGS.md`, der SELECT-List-Eintrag) --, und ein Wert behält seinen JSON-Typ: Zahlen sind Zahlen, NULL ist `null`, Daten sind ISO 8601 und Binäres ist base64.
