---
layout: default
title: MAD Designer for Windows
description: >-
  Native Windows (WPF) relational report designer and viewer for SQLite, MySQL, MariaDB, PostgreSQL, and SQL Server — visual query canvas, banded report designer, page-accurate viewer, and HTML/CSV/JSON export, over the same headless engine as Linux and macOS.
image: /assets/mad-designer-icon-512.png
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="assets/mad-designer-icon-512.png" alt="MAD Designer for Windows icon" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>MAD Designer for Windows

**MAD Designer for Windows** is a native Windows Presentation Foundation (WPF) desktop application on .NET 10 for creating, querying, laying out, refreshing, and exporting Mobile Analytics Documents (`.mad`). It runs the same first-party Objective-C engine (`mad.exe`) as the macOS application and the headless Linux `mad` CLI, so every document it writes is compatible with the iPad/iPhone apps, the `mad` CLI, and the [`mad-action`](https://github.com/mthomason/mad-action) GitHub Action.

> **This 0.8.0 build is unsigned.** It is built and published from the public source, but it carries no commercial code-signing certificate, so Windows SmartScreen will warn on first launch. Nothing is hidden: [review the build](#reviewing-and-self-signing-this-build), verify its SHA-256 checksum, and run it.

## Download & Install

* **Direct Download:** [**MAD-Designer-Windows-0.8.0.zip**]({{ site.data.versions.release_base_url }}/MAD-Designer-Windows-0.8.0.zip)
* **Version:** app {{ site.data.versions.windows_app_version }} / engine {{ site.data.versions.engine_version }} ({{ site.data.versions.engine_revision }}).

**Languages.** The application UI is available in English, Simplified Chinese, Japanese, Brazilian Portuguese, German, and Latin American Spanish. Translations are machine-assisted and may contain errors; report them at <https://github.com/mthomason/MAD/issues>.
* **Requirements:** Windows 10 (1903 or later) or Windows 11, 64-bit. The archive is self-contained, so **no .NET runtime install is needed**. The Viewer uses the Microsoft Edge WebView2 Evergreen Runtime, which ships with Windows 11 and current Edge; on older Windows 10 images, install the [Evergreen Runtime](https://developer.microsoft.com/microsoft-edge/webview2/).

1. Download the `.zip` and extract it to a folder of your choosing. Keep the folder structure intact: the application, the engine, and the licences belong together.
2. Run `Mad.Designer.Windows.exe` from the top of the extracted folder.
3. On first launch, Windows SmartScreen may say *"Windows protected your PC"*. Choose **More info**, then **Run anyway** — the build is unsigned by design (see below).

### What is in the archive

```
MAD-Designer-Windows-0.8.0/
  Mad.Designer.Windows.exe   the WPF application (self-contained)
  ...                        the application's own files
  CLI/Fixtures/              London.portable.mad (a sample report) and
                             chinook.sqlite3 (the sample data it refreshes from)
  Windows/Engine/build/mad.exe       the headless engine
  Windows/Engine/build/*.dll         the engine's GNUstep/ObjC/VC runtime
  Windows/Engine/build/fonts/        the Liberation fonts used by PDF export
  ThirdParty/Licenses/       every third-party licence and notice
  LICENSE, NOTICE, README-Windows.txt
```

**Where the engine sits:** `Windows/Engine/build/mad.exe`, next to its runtime DLLs and `fonts` folder. The application finds it through the same repository-relative layout the source tree uses; it does not use a system-wide GNUstep install. Leave the folders where the archive put them.

### Verifying the download

The release page publishes a SHA-256 checksum for the archive. Compare it after downloading:

```powershell
Get-FileHash .\MAD-Designer-Windows-0.8.0.zip -Algorithm SHA256
```

The extraction can also be reviewed file by file: the archive contains only the published application, the engine built by `Windows/Engine/build.ps1`, the sample document, and the licence texts. `mad.exe` is the same command-line engine documented in the [Linux guide](https://github.com/mthomason/MAD/blob/master/Linux/README.md) and the [Windows build record](https://github.com/mthomason/MAD/blob/master/docs/developers/build/windows.md).

### Reviewing and self-signing this build

You can run `mad.exe` directly to inspect a document without opening the GUI:

```powershell
.\Windows\Engine\build\mad.exe inspect .\CLI\Fixtures\London.portable.mad
```

If you want Windows to stop warning about *your own* copy, create a local code-signing certificate and sign the executable yourself. This is a local trust decision — it does not make the public download trusted by anyone else:

```powershell
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=MAD Designer (local review)" `
    -CertStoreLocation Cert:\CurrentUser\My
Set-AuthenticodeSignature -FilePath .\Mad.Designer.Windows.exe -Certificate $cert
```

To trust that certificate on this machine, export it and import it into **Trusted Root Certification Authorities** with `certmgr.msc` or `Import-Certificate`; only do that for a certificate you created and control.

## Workspaces

The application has the same three reporting stages as the macOS app:

* **MAD Query** — the visual query canvas (draggable table cards, Bezier join connectors, join-type badges, filters and groupings) and the direct SQL editor, both against the document's imported schema.
* **MAD Designer** — the banded layout workspace: the page and section minimap, the Report Bands outline, searchable query fields, the zoomable/ruled design canvas with alignment guides and undo/redo, and the element inspector for content, typography, and geometry.
* **MAD Viewer** — refresh the query into the local materialized table, choose the page size (US Letter, US Legal, A4), step through the rendered pages, and export.

The Viewer exports **PDF**, **HTML**, **HTML Flow**, **CSV**, **JSON**, **JSON Full Report**, and **Plain Text**, in the macOS viewer's order. The PDF is written by the engine itself (the same exporter `mad export --format pdf` uses), so a large report exports without blocking the window: the status bar shows an indeterminate progress bar and an "Exporting…" line until the file is written, then reports its size.

## Composition Reports

A **Composition Report** combines several reports into one `.mad` document, joining data
from MySQL, PostgreSQL, SQL Server, and SQLite locally instead of through a federation
server. [The composition guide](composition.html) covers the model and the samples.

* **Composition pane:** a Composition Report shows a docked left pane with the document's
  graph — the **Result** at the top and its sources below, connectors pointing at the
  report that consumes them. The pane has a `GridSplitter` and an Expand/Collapse mode.
* **One selection:** clicking a card in the graph, or choosing a report in the toolbar's
  **Component** picker, switches the Query, Designer, and Viewer workspaces to that
  report. The picker stays visible when the pane is collapsed.
* **Every source is a report:** a source keeps its own query, layout, and rows. A source
  with no layout is a report of rows — the Viewer shows its cached rows in a grid and the
  Designer offers to author a layout.
* **Per-source credentials:** refresh prompts once per credential-taking source, with the
  connection details prefilled. Passwords stay in the session or the platform credential
  store, not in the document.

**Creating one:** **File ▸ New Composition…** builds a composition from existing reports;
**File ▸ Import…** adds a report to the open composition; **File ▸ Convert to Composition**
converts the open standard report. The pane's Import action does the same from inside the
workspace.

## Building from Source

The application builds with the .NET SDK pinned in [`Windows/global.json`](https://github.com/mthomason/MAD/blob/master/Windows/global.json) (10.0.404):

```powershell
dotnet publish Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj `
    -c Release -r win-x64 --self-contained true
```

The engine is the harder half. `Windows\Engine\build.ps1` reproduces the native build (Clang 20.1.8, the pinned Visual Studio MSVC toolchain, NASM, Strawberry Perl, Meson, Python, and GNUstep built from seven pinned revisions into `C:\GNUstep`). It must run from an elevated PowerShell prompt:

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # full toolchain bootstrap and build
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # rebuild after the toolchain exists
```

The two .NET suites run against the built engine:

```powershell
dotnet test Windows\App\Mad.Designer.Windows.slnx
```

`Windows/Engine/build.ps1` also runs the ported native suites, and `Windows/package.ps1` assembles the unsigned release archive and the engine-only CI asset once the engine and app are built. The full recipe, the Windows-only runtime fixes, the licence obligations, and the supported OS matrix are recorded in [`docs/developers/build/windows.md`](https://github.com/mthomason/MAD/blob/master/docs/developers/build/windows.md).

## Licence

MAD is MIT-licensed (see [`LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE)); the names "MAD", "MAD Designer" and "MAD Viewer" and the app artwork are excluded (see [`NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)). The engine adds the GNUstep runtime (LGPL-2.1-or-later) and the C libraries; every component, its licence, and the written relink offer are in the archive's `ThirdParty/Licenses/` folder and in [`docs/project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).
