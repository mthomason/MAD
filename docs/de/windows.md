---
layout: default
title: MAD Designer für Windows
description: >-
  Nativer relationaler Berichtsdesigner und -betrachter für Windows (WPF) für SQLite, MySQL, MariaDB, PostgreSQL und SQL Server — visuelle Abfrageleinwand, bandbasierter Berichtsdesigner, seitengenauer Betrachter und Export nach HTML/CSV/JSON, auf derselben headless Engine wie Linux und macOS.
image: /assets/mad-designer-icon-512.png
lang: de-DE
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-icon-512.png" alt="Symbol von MAD Designer für Windows" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>MAD Designer für Windows

**MAD Designer für Windows** ist eine native Desktopanwendung auf Basis von Windows Presentation Foundation (WPF) und .NET 10 zum Erstellen, Abfragen, Layouten, Aktualisieren und Exportieren von Mobile Analytics Documents (`.mad`). Sie führt dieselbe eigenentwickelte Objective-C-Engine (`mad.exe`) aus wie die macOS-Anwendung und die headless `mad`-CLI unter Linux, sodass jedes von ihr geschriebene Dokument mit den iPad-/iPhone-Apps, der `mad`-CLI und der GitHub Action [`mad-action`](https://github.com/mthomason/mad-action) kompatibel ist.

> **Dieser 0.7-Build ist unsigniert.** Er wird aus dem öffentlichen Quellcode gebaut und veröffentlicht, trägt aber kein kommerzielles Code-Signaturzertifikat, sodass Windows SmartScreen beim ersten Start warnt. Es ist nichts verborgen: Prüfen Sie den Build (siehe unten), verifizieren Sie seine SHA-256-Prüfsumme und führen Sie ihn aus.

## Herunterladen & installieren

* **Direkter Download:** [**MAD-Designer-Windows-0.7.zip**](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-Windows-0.7.zip)
* **Version:** App 0.7 / Engine 9.0 (r4433).
* **Voraussetzungen:** Windows 10 (1903 oder neuer) oder Windows 11, 64-Bit. Das Archiv ist eigenständig (self-contained), sodass **keine .NET-Runtime installiert werden muss**. Der Betrachter verwendet die Microsoft Edge WebView2 Evergreen Runtime, die mit Windows 11 und aktuellem Edge ausgeliefert wird; auf älteren Windows-10-Images installieren Sie die [Evergreen Runtime](https://developer.microsoft.com/microsoft-edge/webview2/).

1. Laden Sie die `.zip` herunter und entpacken Sie sie in einen Ordner Ihrer Wahl. Behalten Sie die Ordnerstruktur bei: Anwendung, Engine und Lizenzen gehören zusammen.
2. Führen Sie `Mad.Designer.Windows.exe` aus dem Stamm des entpackten Ordners aus.
3. Beim ersten Start meldet Windows SmartScreen möglicherweise *„Windows hat Ihren PC geschützt“*. Wählen Sie **Weitere Informationen** und dann **Trotzdem ausführen** — der Build ist bewusst unsigniert (siehe unten).

### Was im Archiv enthalten ist

```
MAD-Designer-Windows-0.7/
  Mad.Designer.Windows.exe   die WPF-Anwendung (self-contained)
  ...                        die eigenen Dateien der Anwendung
  CLI/Fixtures/              London.portable.mad (ein Beispielbericht) und
                             chinook.sqlite3 (die Beispieldaten dafür)
  Windows/Engine/build/mad.exe       die headless Engine
  Windows/Engine/build/*.dll         die GNUstep-/ObjC-/VC-Laufzeit der Engine
  Windows/Engine/build/fonts/        die Liberation-Schriften für den PDF-Export
  ThirdParty/Licenses/       jede Lizenz und jeder Hinweis Dritter
  LICENSE, NOTICE, README-Windows.txt
```

**Wo die Engine liegt:** `Windows/Engine/build/mad.exe`, neben ihren Laufzeit-DLLs und dem Ordner `fonts`. Die Anwendung findet sie über dieselbe repository-relative Struktur, die auch der Quellbaum verwendet; eine systemweite GNUstep-Installation ist nicht nötig. Lassen Sie die Ordner dort, wo das Archiv sie angelegt hat.

### Den Download verifizieren

Die Release-Seite veröffentlicht eine SHA-256-Prüfsumme für das Archiv. Vergleichen Sie sie nach dem Download:

```powershell
Get-FileHash .\MAD-Designer-Windows-0.7.zip -Algorithm SHA256
```

Das entpackte Archiv lässt sich auch Datei für Datei prüfen: Es enthält nur die veröffentlichte Anwendung, die mit `Windows/Engine/build.ps1` gebaute Engine, das Beispieldokument und die Lizenztexte. `mad.exe` ist dieselbe Kommandozeilen-Engine, die im [Linux-Leitfaden](https://github.com/mthomason/MAD/blob/master/Linux/README.md) und in der [Windows-Builddokumentation](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md) beschrieben ist.

### Diesen Build prüfen und selbst signieren

Sie können `mad.exe` direkt ausführen, um ein Dokument ohne die GUI zu inspizieren:

```powershell
.\Windows\Engine\build\mad.exe inspect .\CLI\Fixtures\London.portable.mad
```

Wenn Windows bei *Ihrer eigenen* Kopie nicht mehr warnen soll, erstellen Sie ein lokales Code-Signaturzertifikat und signieren Sie die ausführbare Datei selbst. Das ist eine lokale Vertrauensentscheidung — der öffentliche Download wird dadurch für niemanden sonst vertrauenswürdig:

```powershell
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=MAD Designer (local review)" `
    -CertStoreLocation Cert:\CurrentUser\My
Set-AuthenticodeSignature -FilePath .\Mad.Designer.Windows.exe -Certificate $cert
```

Um diesem Zertifikat auf diesem Rechner zu vertrauen, exportieren Sie es und importieren Sie es mit `certmgr.msc` oder `Import-Certificate` unter **Vertrauenswürdige Stammzertifizierungsstellen**. Tun Sie das nur mit einem Zertifikat, das Sie selbst erstellt haben und kontrollieren.

## Arbeitsbereiche

Die Anwendung hat dieselben drei Berichtsphasen wie die macOS-App:

* **MAD Query** — die visuelle Abfrageleinwand (verschiebbare Tabellenkarten, Bezier-Join-Verbindungen, Join-Typ-Abzeichen, Filter und Gruppierungen) und der direkte SQL-Editor, beide gegen das importierte Schema des Dokuments.
* **MAD Designer** — der bandbasierte Layout-Arbeitsbereich: die Minimap für Seite und Abschnitte, die Gliederung der Berichtsbänder, durchsuchbare Abfragefelder, die zoombare/lineale Gestaltungsleinwand mit Ausrichtungslinien und Rückgängig/Wiederholen sowie der Element-Inspektor für Inhalt, Typografie und Geometrie.
* **MAD Viewer** — aktualisiert die Abfrage in die lokale materialisierte Tabelle, wählt die Seitengröße (US Letter, US Legal, A4), blättert durch die gerenderten Seiten und exportiert.

Der Betrachter exportiert **HTML**, **HTML Flow**, **CSV**, **JSON**, **JSON-Vollbericht** und **Reinen Text**. Der PDF-Export ist in der Engine und der `mad`-CLI unter Windows vorhanden, wird aber in der Formatauswahl dieses Builds noch nicht angeboten; für ein PDF rufen Sie die Engine direkt auf:

```powershell
.\Windows\Engine\build\mad.exe export .\CLI\Fixtures\London.portable.mad `
    --format pdf --out .\london.pdf
```

## Bauen aus dem Quellcode

Die Anwendung wird mit dem in [`Windows/global.json`](https://github.com/mthomason/MAD/blob/master/Windows/global.json) festgelegten .NET SDK (10.0.404) gebaut:

```powershell
dotnet publish Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj `
    -c Release -r win-x64 --self-contained true
```

Die Engine ist die schwierigere Hälfte. `Windows\Engine\build.ps1` reproduziert den nativen Build (Clang 20.1.8, die festgelegte Visual-Studio-MSCV-Toolchain, NASM, Strawberry Perl, Meson, Python und ein aus sieben festgelegten Revisionen gebautes GNUstep in `C:\GNUstep`). Das Skript muss in einer erhöhten PowerShell-Eingabeaufforderung laufen:

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # vollständiger Toolchain-Bootstrap und Build
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # Neubau, wenn die Toolchain bereits existiert
```

Die beiden .NET-Testsuiten laufen gegen die gebaute Engine:

```powershell
dotnet test Windows\App\Mad.Designer.Windows.slnx
```

`Windows/Engine/build.ps1` führt außerdem die portierten nativen Suiten aus, und `Windows/package.ps1` stellt nach dem Bau von Engine und App das unsignierte Release-Archiv und das Engine-Asset für CI zusammen. Das vollständige Rezept, die Windows-spezifischen Laufzeitkorrekturen, die Lizenzpflichten und die unterstützte Betriebssystemmatrix sind in [`docs/project/MAD_WINDOWS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md) dokumentiert.

## Lizenz

MAD ist unter der MIT-Lizenz lizenziert (siehe [`LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE)); die Namen „MAD“, „MAD Designer“ und „MAD Viewer“ sowie die App-Grafiken sind davon ausgenommen (siehe [`NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)). Die Engine bringt die GNUstep-Laufzeit (LGPL-2.1-or-later) und die C-Bibliotheken mit; jede Komponente, ihre Lizenz und das schriftliche Relink-Angebot finden sich im Ordner `ThirdParty/Licenses/` des Archivs und in [`docs/project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).
