---
layout: default
lang: de-DE
title: "Portabilität und die native macOS-Anwendung"
description: "Das Framework-Portabilitätsaudit und die AppKit-Anwendungsarchitektur."
---

# `MAD_MACOS.md` -- Multiplattform-Frameworks und die native macOS-Anwendung

Diese Seite hält den Multiplattform-Audit der Frameworks und die Architektur der nativen macOS-Anwendung fest. Die benutzerseitige Anleitung steht unter `/macos.html`.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

Dieses Dokument hält die Architekturentscheidung, den Portabilitätsaudit Framework für Framework und den phasenweisen Migrations- und Implementierungsplan fest, um die MAD-Frameworks wirklich multiplattformfähig zu machen (`iphoneos`, `iphonesimulator`, `macosx` und headless Linux) und das native macOS-Frontend (`AppKit`) für **MAD Designer** zu bauen.

---

## 1. Entscheidung: natives macOS (`AppKit`) vs. Mac Catalyst

**Entscheidung:** Eine **native macOS-Anwendung (`macosx`-SDK, `AppKit`)** über geteilten Multiplattform-Frameworks bauen (`MACOSX_DEPLOYMENT_TARGET = 12.0`, unterstützt jeden Apple-Silicon-Mac und Intel-Macs auf Monterey oder neuer). **Mac Catalyst wird abgelehnt.**

### Warum natives macOS gewinnt

| Dimension | Natives macOS (`macosx` / `AppKit`) | Mac Catalyst (`maccatalyst` / `UIKit`) |
|---|---|---|
| **Statische C-Bibliotheken (`Compressor`)** | **Bereits gebaut.** Alle 10 `.xcframework`-Bundles in `Compressor/library/` tragen universelle `macosx`-Slices (`arm64` + `x86_64`, `-mmacosx-version-min=11.0`), verifiziert durch `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`. | **Fehlen.** Es existieren null `maccatalyst`-Slices (`-target <arch>-apple-ios15.0-macabi`). Der Mach-O-Linker verweigert das Linken von `MACOS`-Archiven in `MACCATALYST`-Binärdateien; Catalyst würde erfordern, `Compressor` eine vierte Plattform hinzuzufügen und alle 10 C-Bibliotheken neu zu bauen (`openssl`, `mariadb`, `postgres`, `freetds`, `libarchive`, `sqlite3`, `zint`, `libpng`, `bzip2`, `zlib`). |
| **Portabilität der Kern-Engine** | **90 % abgeschlossen.** Der headless Linux-Port (`MAD_LINUX.md`) hat Core Data bereits aus `MAD.framework` entfernt, die Datenbanktreiber (`MADDatabaseDriverRegistry`) und Berichtsexporter (`MADReportExporterRegistry`) entkoppelt und `MADHeadlessDocument`, `MADSQLQueryCompiler` und `MADDesignerLayout` eingeführt. | Dieselbe Engine, aber an `UIDocument` und die Lebenszyklen der iOS-Hintergrundaufgaben gebunden. |
| **Desktop-Ergonomie** | Natives `NSDocument` / `NSDocumentController` (Finder-Doppelklick, `Cmd+N`, `Cmd+O`, `Cmd+S`, `Cmd+Shift+S`, zuletzt verwendete Dokumente, Fensterwiederherstellung, `NSUndoManager`), native Split-Views, native Tabellen-/Outline-Views, natives `PDFView` / `WKWebView` und Standard-macOS-Menüs. | Verschachtelte zoombare `UIScrollView` + `UICollectionView`-Abschnitte, iOS-Tab-/Navigationsleisten, `UIPickerView`-Räder und der sandboxed iOS-Dokumentbrowser (`MADExplorer`). Apple-Silicon-Macs führen den iPad-Build bereits über *Designed for iPad* aus. |
| **Verteilung über GitHub** | Sauberes eigenständiges `.app`-Bundle, paketiert als herunterladbare `.dmg` und `.zip` auf GitHub Releases (`arm64` + `x86_64`). | Erfordert ein Catalyst-Provisioning-Profil und -Entitlements, die nicht zur Ergonomie der Verteilung außerhalb des App Stores passen. |

---

## 2. Audit der statischen Bibliotheken (`Compressor`)

Alle zehn mitgelieferten C-Bibliotheken in `Compressor` bauen universelle `macosx`-Slices (`arm64` + `x86_64`) mit `-mmacosx-version-min=11.0`:

| Bibliothek | Version | `ios` (`arm64`) | `simulator` (`arm64` + `x86_64`) | `macosx` (`arm64` + `x86_64`) | Verwendet von |
|---|---|:---:|:---:|:---:|---|
| `sqlite3` | 3.53.3 | Ja | Ja | Ja | `MADSqlite3`, `MAD` |
| `zlib` | 1.3.2 | Ja | Ja | Ja | `MAD`, `MADMySQL`, `MADPostgres`, `MADBarcodes` |
| `openssl` | 3.5.9 | Ja | Ja | Ja | `MADTds`, `MADMySQL`, `MADPostgres` |
| `bzip2` | 1.0.8 | Ja | Ja | Ja | `MAD` |
| `libpng` | 1.6.59 | Ja | Ja | Ja | `MADBarcodes` |
| `libarchive` | 3.8.9 | Ja | Ja | Ja | `MAD` |
| `freetds` | 1.4.27 | Ja | Ja | Ja | `MADTds`, `MADTdsClient` |
| `mariadb` | 3.4.11 | Ja | Ja | Ja | `MADMySQL` |
| `postgres` | 17.11 | Ja | Ja | Ja | `MADPostgres` |
| `zint` | 2.16.0 | Ja | Ja | Ja | `MADBarcodes` |

Verifikationsbefehl:

```sh
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```

---

## 3. Multiplattform-Audit Framework für Framework

Zwölf Frameworks bilden den Multiplattform-Stack (`iphoneos`, `iphonesimulator`, `macosx`, plus Linux für die zwölf headless Frameworks):

1. **`MADFoundation`** (28 `.m`-Dateien):
   - `MADApplication.h`: `<UIKit/UIApplication.h>` mit `#if TARGET_OS_IPHONE` schützen statt mit `#if __APPLE__` (`MADApplication.m` hat bereits `#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`).
   - `MADURLFactory.m`: `<UIKit/UIScreen.h>` mit `#if TARGET_OS_IPHONE` schützen und unter `TARGET_OS_OSX` `NSScreen.mainScreen.backingScaleFactor > 1.0` verwenden.
   - `MADKeyChain.m`: verwendet `Security.framework`, das unter iOS und macOS nativ ist.
2. **`MADDataStructures`** (17 `.m`-Dateien):
   - Reines Foundation + C++. Keine Quellcodeänderungen erforderlich.
3. **`MADFileManager`** (11 `.m`-Dateien):
   - Den ungenutzten `#import <MobileCoreServices/UTType.h>` in `MADMetaDataLocal.m:16` entfernen (`<UniformTypeIdentifiers/UTType.h>` ist bereits in Zeile 17 importiert).
4. **`MADCocoaExtensions`** (17 `.m`-Dateien):
   - `CGGeometry+Extras.h`: unter `TARGET_OS_OSX` `UIEdgeInsets` bereitstellen (mit `NSEdgeInsets` kompatibles Layoutstruct + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`), `NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect` und `NSValue (MADCGGeometryExtensions)` (`valueWithCGPoint:`, `CGPointValue`, `valueWithCGRect:`, `CGRectValue`, `valueWithCGSize:`, `CGSizeValue`).
   - `MADColor.h` / `MADColor.m`: `MADColor` unter `TARGET_OS_OSX` auf `NSColor` überbrücken, während unter `TARGET_OS_IPHONE` `UIColor` erhalten bleibt.
   - Die iOS-only-Kategorien `UIView`, `UIAlertController`, `UITextField` und `UIColor` mit `#if TARGET_OS_IPHONE` schützen.
5. **`MADAPI`** (11 `.m`-Dateien):
   - 9 Kern-Dateien für Datenbank, Abfrage und Treiberregistratur sind reines Foundation.
   - `MADConnectionViewController` und `MADConnectionSQLGenericViewController` mit `#if TARGET_OS_IPHONE` schützen.
6. **`MADSqlite3`** (26 `.m`-Dateien):
   - Reines Foundation + `sqlite3.xcframework`. Keine Quellcodeänderungen erforderlich.
7. **`MADTds`** (1 `.m`-Datei):
   - Reines Foundation + `freetds.xcframework` + `openssl.xcframework`. Keine Quellcodeänderungen erforderlich.
8. **`MADTdsClient`** (4 `.m`-Dateien):
   - `MADDatabaseSQLServer`, `MADTdsConnection` und `MADDataTypeSQLServer` sind reines Foundation. `MADTdsConnectionViewController` mit `#if TARGET_OS_IPHONE` schützen.
9. **`MADMySQL`** (19 `.m`-Dateien):
   - 18 Treiberdateien sind reines Foundation + `mariadb.xcframework`. `MADMySQLConnectionViewController` mit `#if TARGET_OS_IPHONE` schützen.
10. **`MADPostgres`** (5 `.m`-Dateien):
    - 4 Treiberdateien sind reines Foundation + `postgres.xcframework`. `MADPostgresConnectionViewController` mit `#if TARGET_OS_IPHONE` schützen.
11. **`MADBarcodes`** (70 `.m`-Dateien):
    - 67 Symbologie-Klassen sind reines Foundation + `zint.xcframework`.
    - `MADBarcode`, `MADBarcodeCache` und `MADBarcodeView`: `UIImage` / `NSImage` und `UIView` / `NSView` unter `TARGET_OS_OSX` über die vorhandene `CGImageRef`-Pipeline `MADBarcodeImageFromZintBitmap` überbrücken.
12. **`MAD`** (199 `.m`-Dateien):
    - `#if __APPLE__` durch `#if TARGET_OS_IPHONE` und `#elif TARGET_OS_OSX` und AppKit-Brücken über die 9 geteilten Modell-/Renderdateien ersetzen (`RptqObject.m`, `RptqDocumentElementImage+Extras.m`, `RptqDocument+Extras.m`, `RptqDocumentSection+Extras.m`, `RptqDocumentElement+Extras.m`, `MADPrintPageElement.m`, `MADElementStylizedText.m`, `MADFonts.m` und `MADReportExporterPDF.m`).
    - In `MADReportExporterPDF.m` paginierte PDFs unter `TARGET_OS_OSX` mit `CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData` und `NSGraphicsContext` (`+graphicsContextWithCGContext:flipped:YES`) rendern, sodass `MADPrintPageRenderer` und `MADPrintPageElement` nativ unter macOS zeichnen.
    - Die 22 iOS-only-Dateien für `UIDocument` (`MADocument`), `UIView` und `UICollectionViewLayout` mit `#if TARGET_OS_IPHONE` schützen.

`MADExplorer` bleibt iOS-only (macOS verwendet `NSDocumentController`, Finder und `NSOpenPanel` mit einem primären **New Document**-Button). `MADFeedback` und `Scrimpter` bleiben ungenutzt gemäß `AGENTS.md`.

---

## 4. Phasenweiser Implementierungsplan

### Phase 1: Fehlerbehebungen und Freischaltung der Multiplattform-Frameworks (abgeschlossen)

1. **6 während des macOS-Audits und -Ports aufgedeckte Defekte behoben** und mit Unit-Tests von `docs/project/BUGS.md` nach `docs/project/BUGS_FIXED.md` archiviert:
   - `MADKeyChain` (`MADFoundation/Source/MADKeyChain.m`): das Anfordern von `kSecReturnData : @YES` (und das Lecken des zurückgegebenen `CFDataRef`) in `+credentialsExist:`, `+saveToken:forKey:withDescription:`, `+deleteKey:` und `+deleteSavedPasswordForKey:error:` beendet.
   - `MADURLFactory` (`MADFoundation/Source/MADURLFactory.m`): `+newURLForLocalApplicationSupportDirectory` geschützt, wenn `[NSBundle mainBundle].bundleIdentifier` nil ist (mit Rückfall auf `[MADApplication groupIdentifier]`), und `containerURLForSecurityApplicationGroupIdentifier:` mit `#if defined(__APPLE__) && TARGET_OS_IPHONE` geschützt, sodass nicht-berechtigte macOS-Prozesse die üblichen benutzerspezifischen Verzeichnisse verwenden, statt TCC-Abfragen auf `~/Library/Group Containers/` auszulösen.
   - `MADDataTable` (`MADFoundation/Source/MADDataTable.m`): `NSDataWritingFileProtectionCompleteUnlessOpen` mit `#if defined(__APPLE__) && TARGET_OS_IPHONE` geschützt, sodass Cache-Schreibvorgänge unter nicht-berechtigtem macOS gelingen.
   - `MADDatabaseSqlite3` (`MADSqlite3/Source/MADDatabaseSqlite3.m`): `[dataTable endBulkInsert]` mit `if (rowCounter > 0)` geschützt, sodass `SELECT`-Abfragen mit null Zeilen kein `COMMIT TRANSACTION` ausführen, wenn `[dataTable beginBulkInsert]` nie aufgerufen wurde.
   - `MADBarcode` (`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`): `-drawInRect:` verdoppelte `rect.origin` nicht mehr, wenn `self.center == YES`.
   - `MADDesignerLayout` (`MAD/Source/MADDesignerLayout.m`): den eigenen vorherigen Wert jedes ausgewählten Elements in einem Wörterbuch bewahrt, wenn Undo-Aktionen über alle Massenaktualisierungsmethoden registriert werden (`setFontsize:`, `setFontname:`, `setVerticalAlignment:`, `setHorizontalAlignment:`, `setSizeWidth:`, `setSizeHeight:`, `setMargin*`, `setPadding*`, `setBorder*`).
2. **`macosx` über die 12 Framework-Xcode-Projekte freigeschaltet:**
   - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` und `MACOSX_DEPLOYMENT_TARGET = 12.0` gesetzt.
   - `platformFilters = (ios, maccatalyst, );` bei `UIKit.framework`-Verweisen hinzugefügt und `AppKit.framework` mit `platformFilters = (macos, );` verlinkt, wo nötig.
   - Die Build-Phasen `Ensure Libraries` aktualisiert, um `--platforms ios,simulator,macosx` zu übergeben.
3. **Alle 12 Frameworks unter nativem macOS verifiziert (`-destination 'platform=macOS,arch=arm64'`):**
   - `MADFoundation`: **199 Tests bestanden, 0 Fehlschläge**
   - `MADDataStructures`: **72 Tests bestanden, 0 Fehlschläge**
   - `MADCocoaExtensions`: **80 Tests bestanden, 0 Fehlschläge**
   - `MADFileManager`: **85 Tests bestanden, 0 Fehlschläge**
   - `MADAPI`: **106 Tests bestanden, 0 Fehlschläge**
   - `MADSqlite3`: **118 Tests bestanden (5 Benchmarks übersprungen), 0 Fehlschläge**
   - `MADTds`: **sauber für `macosx` gebaut**
   - `MADTdsClient`: **77 Tests bestanden (einschließlich der Live-SQL-Server-Suite), 0 Fehlschläge**
   - `MADMySQL`: **alle Offline- und Live-MariaDB/MySQL-Tests bestanden, 0 Fehlschläge**
   - `MADPostgres`: **31 Tests bestanden (einschließlich der Live-PostgreSQL-Suite), 0 Fehlschläge**
   - `MADBarcodes`: **30 Tests bestanden, 0 Fehlschläge**
   - `MAD`: **650 Tests bestanden, 0 Fehlschläge**

### Phase 2: Multiplattform-Schemaimport und `NSDocument`-Schicht (abgeschlossen)

1. **Multiplattform-Dokumenterstellung und Schemaimport (`MADHeadlessDocument`):**
   - `+createDocumentAtURL:withDatabaseConnection:credentials:error:` auf `MADHeadlessDocument` hinzugefügt (`MAD/Source/MADHeadlessDocument.h`, `.m`), das sich mit jedem registrierten Treiber verbindet (`SQLite3`, `MySQL`, `SQL Server`, `PostgreSQL`), alle Datenbanktabellen (`-getTablesFromConnection:error:`) und Spalten (`-fieldsForTable:connection:error:`) in `RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField` importiert, die Standardberichtsabschnitte initialisiert (`Report Header`, `Page Header`, `Report Detail`, `Page Footer`, `Report Footer`) und den portablen `.mad`-Container schreibt.
2. **`MADMacDocument` (`NSDocument`-Unterklasse in `Mac/Source/MADMacDocument.m`):**
   - Wickelt `MADHeadlessDocument` (mit automatischer Konvertierung von Legacy-Core-Data-`.mad` über `MADStoreConverter`, wenn nötig), erfüllt `MADocumentDesignerProtocol`, sodass `MADDesignerLayout` Undo/Redo direkt auf `NSDocument.undoManager` aufzeichnet, und unterstützt `readFromURL:ofType:error:`, `writeToURL:ofType:forSaveOperation:originalContentsURL:error:` und das asynchrone `refreshWithCredentials:maxRows:completion:`.

### Phase 3: Native macOS-Anwendung (`Mac/`) (abgeschlossen)

Gebaut unter `Mac/` (`Mac/Source/`, `Mac/Resources/`, `Mac/Tests/`, `Mac/build.sh`) und über das Target **`MAD Designer Mac`** und das geteilte Scheme in `MAD Designer.xcodeproj` integriert:

1. **Anwendungslebenszyklus, About-Fenster und Dokument-Controller (`MADMacAppDelegate`, `MADMacAboutWindowController` und `MADMacDocumentController`):**
   - Registriert alle vier Datenbanktreiber und `MADStoreLegacyConverter`, baut das native macOS-Hauptmenü (`MAD Designer`, `File`, `Edit` mit `Undo`/`Redo`, `View` mit Arbeitsbereichswechsel `Cmd+1`/`Cmd+2`/`Cmd+3`, `Report` mit Refresh `Cmd+R`, `Window`, `Help`) und präsentiert beim Start das standardmäßige `NSOpenPanel`, wenn kein Dokument offen ist.
   - `MADMacAboutWindowController` präsentiert das native Fenster **About MAD Designer** (`MAD Designer → About MAD Designer` und `Help`-Menüpunkte) mit der Engine-Version/-Build (`MADMeta.plist`) und der macOS-Anwendungsversion (`CFBundleShortVersionString`) als getrennten Werten, Copyright- und Marken-/Artwork-Hinweis, der Aktion **Source Code on GitHub** und drei Tab-Abschnitten: **Overview** (was MAD ist, der vierstufige Reporting-Ablauf und unterstützte Treiber/Bänder/Exporter), **License & Notice** (MIT-Lizenz, `NOTICE` und das schriftliche Relink-Angebot nach LGPL-3.0 für FreeTDS und MariaDB Connector/C) und **Acknowledgements** (interaktive Seitenleiste aller 16 Open-Source-Komponenten von Drittanbietern mit ihren Nennungen und den 12 vollständigen Lizenztexten unter `Contents/Resources/Licenses/`).
   - `MADMacDocumentController` konfiguriert `NSOpenPanel` mit allen `.mad`-`UTType`-Kennungen (`com.everydayapps.productivity.mad` und `com.thomason.report.mad`), sodass bestehende `.mad`-Dateien nie ausgegraut werden, und platziert einen primären **New Document**-Button direkt in der unteren linken Leiste des Open-Panels.
2. **Assistent für Datenbankverbindung und Schemaimport (`MADMacConnectionWindowController`):**
   - Unterstützt **SQLite** (eigene `.sqlite3`/`.db`-Datei über `NSOpenPanel`), **MySQL**, **Microsoft SQL Server** und **PostgreSQL**, mit **Test Connection**, Passwortspeicherung über `MADKeyChain` und **Create Document…** (`NSSavePanel`).
3. **Hauptdokumentfenster (`MADMacWindowController`):**
   - Zentriert das segmentierte Steuerelement **Workspace** (**MAD Query**, **MAD Designer**, **MAD Viewer**) in der Fenstersymbolleiste.
4. **Arbeitsbereich MAD Query (`MADMacQueryViewController`):**
   - Sich gegenseitig ausschließende Arbeitsbereichsmodi **Query Designer** und **SQL Query** (in der Kopfleiste des Arbeitsbereichs umgeschaltet, sodass visuelles Abfragedesign und manuelle SQL-Eingabe nie gleichzeitig gezeigt werden).
   - **Modus Query Designer**: eine linke Liste **Database Tables** mit `200px` (vom Benutzer über `NSSplitViewDelegate` größenveränderbar, ohne zurückzuschnappen, und bei Fenstergrößenänderung auf fester Breite gehalten, sodass stattdessen die visuelle Leinwand ihre Größe ändert), gepaart mit einer interaktiven visuellen Leinwand rechts (`MADMacQueryCanvasView`). Ein Doppelklick auf eine Schematabelle fügt sie der Abfrage hinzu (befüllt alle `RptqQueryField`-Zeilen) und zeigt sie als ziehbare, größenveränderbare schwebende AppKit-Tabellenkarte (`MADMacQueryTableCardView` + `MADMacQueryFieldTableView`), gestaltet mit topologischen Kopfzeilen für Wurzel/Kind (`MTGraph`); das Ziehen von einem Feld in einer Tabellenkarte zu einem Feld in einer anderen erzeugt einen Standard-**Left Outer Join** (`MADLinkTypeLeftOuterJoin`), gezeichnet über Bezier-Verbinder und Join-Typ-Abzeichen (`MADMacQueryLinksOverlayView`, passend zu `MADConnectorView` des iPads). Ein Klick oder Rechtsklick auf einen visuellen Join-Verbinder öffnet ein Join-Inspector-Popover oder Kontextmenü zum Ändern des Link-Typs, Umkehren der Richtung oder Löschen des Links; Kopf-Popovers bieten **Filters (WHERE)**, **Groupings (GROUP BY)** und **Arrange Tables**.
   - **Modus SQL Query**: ein SQL-Anweisungseditor in voller Breite, der erzeugtes oder eingegebenes SQL anzeigt und Validierung, Kompilierung und Anwendung unterstützt (`MADSQLParser` + `MADSQLStatementResolver` + `MADSQLQueryCompiler`).
5. **Arbeitsbereich MAD Designer (`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`):**
   - **Obere Arbeitsbereichsleiste (Höhe `38pt`):** bietet klickbare und ziehbare SF-Symbol-Palettenelemente (**Label**, **Data Field**, **Aggregate**, **Barcode**, **Image**, **Line**), schnelle Ausrichtungssteuerungen für mehrere Elemente (`Left`, `Center`, `Right`, `Top`, `Middle`, `Bottom`), **Size to Fit**, die Umschalter **Grid** / **Snap** / **Rulers** und einen **Zoom**-Schieber mit Ein-Klick-Rücksetzung auf `100%`.
   - **Vom Benutzer größenveränderbare 3-Bereichs-Split-View (`NSSplitViewDelegate`):** die linke Navigator-Seitenleiste hat standardmäßig `220pt` (`180–340pt`), der rechte Inspector standardmäßig `260pt` (`220–380pt`), und beide Seitenleisten behalten ihre Breiten über Fenstergrößenänderungen hinweg, während Benutzer-Anpassungen der Trenner erhalten bleiben.
   - **Linke Seitenleiste (Minimap + Bänder + Abfragefelder-Browser):**
     - **Interaktive Minimap für Seiten und Abschnitte (`MADMacDesignerMinimapView`):** zeichnet proportionale Berichtsbänder mit farbcodierten Streifen, live Miniatur-Elementblöcke und ein blaues Viewport-Rechteck; Klicken oder Ziehen springt zum Band und wählt es aus.
     - **Outline der Berichtsbänder:** listet alle Berichts- und Gruppenabschnitte mit Elementzählungen, Höhen und Seitenumbruchindikatoren; ein Doppelklick schaltet die Sichtbarkeit des Bands um.
     - **Abfragefelder-Browser:** filterbare Liste (`NSSearchField`) aller `RptqQueryField`-Spalten; das Ziehen eines Felds auf ein beliebiges Abschnittsband auf der Leinwand (oder ein Doppelklick) fügt ein gebundenes `RptqDocumentElementLabelDataField` ein.
   - **Mittlere interaktive Leinwand (`MADMacDesignerCanvasView`):** gespiegelte, zoombare `NSView`-Leinwand mit horizontalen/vertikalen Linealen, Papierrändern, farbcodierten Abschnittsbändern, Ziehgriffen für Abschnittshöhen, intelligenten Ausrichtungslinien, Einrasten am Raster, Rahmenauswahl, `Shift`-Klick-Mehrfachauswahl, 8-Punkt-Größengriffen, Inline-Bearbeitung von Beschriftungen per Doppelklick, intelligenter nicht-überlappender Elementplatzierung (`-nextAvailableOriginInSection:forElementSize:`) und Drag-and-Drop über Abschnitte hinweg (`-moveElement:toSection:atOrigin:`) mit Live-Hervorhebung des Zielbands und vollständiger `NSUndoManager`-Integration.
   - **Rechte Inspector-Seitenleiste (klar unterteilt und scrollbar):**
     - **Karte 1 (`1 · PAGE & SELECTED SECTION`):** Papiergröße, Abzeichen des ausgewählten Bands, Bandhöhe (`pt`) mit Button **Fit Height**, **Section Visible** und **Page Break After**.
     - **Deutlicher visueller Trenner + Abschnitt 2 (`2 · SELECTED ELEMENT INSPECTOR`):** 4 gruppierte Inspector-Karten (**Element & Band Assignment** mit Popup zum Verschieben über Abschnitte, **Duplicate** und **Delete**; **Content & Data Binding** mit statischem Text, Bindung an Abfragefelder, Aggregatfunktion und -bereich, Währungsformatierung und Barcode-Optionen; **Typography & Appearance** mit Font-Familie/-Größe, Fett/Kursiv/Unterstrichen/Durchgestrichen, horizontaler/vertikaler Ausrichtung und Text-/Hintergrundfarben; und **Position, Size & Box Model** mit `X`, `Y`, `W`, `H`, synchronisiert über `rect.origin` und `dropPoint`, plus Rahmen, Padding und Margin).
6. **Arbeitsbereich MAD Viewer (`MADMacViewerViewController`):**
   - **Obere Viewer-Symbolleiste (Höhe `40pt`):** Popup **Page Size** (Standard-Papiertypen von `MTPaper`: `US Letter`, `US Legal`, `US Tabloid`, `A3`, `A4`, `A5`, `B4`, `B5`, `JIS B4`, `JIS B5`), **Refresh** (`Cmd+R`), **Zoom**-Steuerungen (`-`, `100%`, `+`), **Page Navigation** (`Previous`, `Page N of M`, `Next`), **Print…** (`Cmd+P` über `NSPrintOperation`) und **Export…** (`Cmd+E`).
   - **Gerahmte paginierte Vorschau (`PDFView`):** rendert paginierte PDF-Seiten in der gewählten Papiergröße aus dem lokalen SQLite-Tabellen-Cache (`MADDataTableFast`) mit Seitenschatten und einer unteren Statusleiste (`statusBarView`), die die gerenderte Seitenzahl, die gecachte Zeilenzahl und die Papierabmessungen anzeigt.
   - **Mehrformat-Export (`NSSavePanel`):** konfiguriert ein Zubehör-Format-Popup, das alle 7 registrierten Exporter unterstützt (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`, `Plain Text`), und aktualisiert dynamisch die zulässige Dateiendung des Speicherpanels.

### Phase 4: Build, Smoke-Verifikation und GitHub-Release-Verpackung (abgeschlossen)

```sh
./Mac/build.sh --smoke-test --package
```

Erzeugt:
- `Mac/build/MAD Designer.app` (eigenständiges natives macOS-App-Bundle mit allen 12 Frameworks und eingebetteten und signierten Legacy-Core-Data-`.momd`-Modellen)
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`

Die öffentliche Benutzer- und Entwicklerdokumentation für die native macOS-Anwendung wird in [`docs/macos.md`](../../macos.md) veröffentlicht (mit Screenshots unter `docs/assets/macos-native-mad-query.png` und `docs/assets/macos-native-mad-designer.png`) und in [`Mac/README.md`](../../../../Mac/README.md).

### Kontinuierliche Integration (abgeschlossen)

`.github/workflows/macos.yml` läuft bei jedem Pull Request und Push auf `master`. Es baut (und cached) die statischen Compressor-Bibliotheken, führt dann die Suiten `MADBarcodes` und `MAD` auf einem aus dem Runner entdeckten iPhone-Simulator aus, baut das iOS-Scheme `MAD Designer` und führt `./Mac/build.sh --smoke-test` aus. Das About-Fenster meldet die Engine-Version (`MADMeta.plist`, `v9.0 (r4433)`) und die macOS-Anwendungsversion (`CFBundleShortVersionString`, `v0.7`) als getrennte Werte, passend zur Darstellung des Windows-About-Fensters nach Phase 6f.

`macos-latest` ist ein arm64-Runner, und `Mac/build.sh` baut die Frameworks für `platform=macOS,arch=arm64`. Der erste Lauf lädt und kompiliert jede festgeschriebene Drittanbieterquelle für drei Plattformen (etwa 15–40 Minuten); spätere Läufe stellen `Compressor/library` aus dem Actions-Cache wieder her, und der Ensure-Schritt ist ein No-op. Das freetds-Rezept holt `config.guess`/`config.sub` einmal ohne Wiederholung von Savannah, also speist der Workflow zuerst `Compressor/media` (siehe die Kommentare des Workflows). Ein Rest, kein Buildfehler: der configure-Schritt von libarchive fand die `libbz2.tbd` des SDK statt die bzip2-Installation von Compressor, weil `BZIP2_LIBRARY` nicht der Hinweis ist, den das moderne `FindBZIP2` von CMake liest; die SDK-Bibliothek ist vorhanden, und die App verarbeitet das bzip2-xcframework.
