[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | **Deutsch** | [Español](README_es.md)

# <a href="../StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../docs/assets/mad-designer-macos-icon-256.png" alt="MAD Designer-Symbol" width="44" height="44" align="absmiddle" /></a> Mac — die native macOS-Anwendung (`AppKit`)

`Mac/` enthält das native macOS-Frontend (`AppKit`, SDK `macosx`,
`MACOSX_DEPLOYMENT_TARGET = 12.0`) für **MAD Designer**, gebaut auf den zwölf
multiplattformfähigen MAD-Frameworks (`MADFoundation`, `MADDataStructures`,
`MADCocoaExtensions`, `MADFileManager`, `MADAPI`, `MADSqlite3`, `MADTds`,
`MADTdsClient`, `MADMySQL`, `MADPostgres`, `MADBarcodes` und `MAD`) und den zehn
universellen (`arm64` + `x86_64`) statischen C-Bibliotheken, die `Compressor`
baut.

Für die benutzerseitige Übersicht der Arbeitsbereiche und Screenshots siehe
[`docs/macos.md`](../docs/de/macos.md). Für den Framework-für-Framework-Audit der
Portabilität und das Architekturprotokoll siehe
[`docs/project/MAD_MACOS.md`](../docs/project/MAD_MACOS.md).

## Eine vorgebaute Version installieren

```sh
brew install --cask mthomason/tap/mad-designer
```

Oder laden Sie [**MAD-Designer-macOS.dmg**](https://github.com/mthomason/MAD/releases/download/v9.1.0-macos/MAD-Designer-macOS.dmg) / [**MAD-Designer-macOS.zip**](https://github.com/mthomason/MAD/releases/download/v9.1.0-macos/MAD-Designer-macOS.zip) aus dem [Release `v9.1.0-macos`](https://github.com/mthomason/MAD/releases/tag/v9.1.0-macos) herunter.

## Aus dem Quellcode bauen und ausführen

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

Sie können die Anwendung auch direkt in Xcode bauen, ausführen und debuggen, indem
Sie `Reports.xcworkspace` öffnen, das gemeinsame Scheme **`MAD Designer Mac`**
auswählen und als Ziel **My Mac** wählen.

## Aufbau

* `Mac/Source/` — `AppKit`-Anwendung, `NSDocument`-Architektur und die drei
  Arbeitsbereiche:
  * `MADMacAppDelegate.{h,m}` — Anwendungslebenszyklus, Registrierung von
    Treibern/Konvertern und Hauptmenüleiste (`MAD Designer`, `File`, `Edit`,
    `View`, `Report`, `Window`, `Help`).
  * `MADMacAboutWindowController.{h,m}` — natives Fenster **About MAD Designer**
    (`Overview`, `License & Notice` und `Acknowledgements` mit Komponenten-Seitenleiste
    und eingebetteten Lizenztexten von Drittanbietern).
  * `MADMacDocumentController.{h,m}` — Unterklasse von `NSDocumentController`, die
    den Standard-Öffnen-Dialog mit `.mad`-`UTType`-Filtern
    (`com.everydayapps.productivity.mad` und `com.thomason.report.mad`) und einer
    primären Schaltfläche **New Document** konfiguriert.
  * `MADMacDocument.{h,m}` — `NSDocument`-Wrapper über `MADHeadlessDocument`,
    `MADDesignerLayout` (`NSUndoManager`), `MADSectionsLayout`, asynchronem Refresh
    (`MADOperationQueue`) und Export.
  * `MADMacWindowController.{h,m}` — Hauptdokumentfenster mit dem zentrierten
    segmentierten Steuerelement **Workspace** (`MAD Query`, `MAD Designer`,
    `MAD Viewer`).
  * `MADMacConnectionWindowController.{h,m}` — Assistent für
    Datenbankverbindung und Schema-Import mit Unterstützung für SQLite, MySQL,
    Microsoft SQL Server und PostgreSQL sowie Zugangsdatenspeicherung über
    `MADKeyChain`.
  * `MADMacQueryViewController.{h,m}` — Arbeitsbereich **MAD Query** mit der
    visuellen Tabellen-/Join-Leinwand (`MADMacQueryCanvasView`,
    `MADMacQueryTableCardView`, `MADMacQueryLinksOverlayView`), Popovern für
    Filter/Gruppierungen und dem SQL-Query-Editor über die volle Breite
    (`MADSQLParser` / `MADSQLQueryCompiler`).
  * `MADMacDesignerViewController.{h,m}` & `MADMacDesignerCanvasView.{h,m}` —
    Arbeitsbereich **MAD Designer** mit Elementpalette, interaktiver Page &
    Section Minimap (`MADMacDesignerMinimapView`), Gliederung Report Bands,
    Drag-Quelle Query Fields, zoombarer/mit Linealen versehener Design-Leinwand und
    zweikartigem Inspector rechts.
  * `MADMacViewerViewController.{h,m}` — Arbeitsbereich **MAD Viewer** mit
    Papierformat-Auswahl (`MTPaper`), Refresh, Zoom/Seitennavigation, gerahmter
    `PDFView`-Darstellung, Statusleiste, Drucken über `NSPrintOperation` und
    Export in 7 Formaten (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON
    Report`, `Plain Text`).
* `Mac/Resources/Info.plist` — Bundle-Metadaten und Deklarationen für
  `.mad`-Dokumenttypen / UTIs.
* `Mac/Tests/MADMacSmokeTest.m` — End-to-End-Verifikationsprogramm, das
  Bundle-Struktur, Schema-Import, visuelles Abfragedesign, SQL-Eingabe, Änderungen
  an Designer-Leinwand/Minimap/Inspector, Rückgängig/Wiederholen, Datenaktualisierung
  und alle sieben Exportformate durchläuft.
