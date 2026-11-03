[English](CONTRIBUTING.md) | [简体中文](CONTRIBUTING_zh.md) | [日本語](CONTRIBUTING_ja.md) | [Português (Brasil)](CONTRIBUTING_pt-BR.md) | **Deutsch**

# Zu MAD beitragen

Danke, dass Sie hier sind. MAD (Mobile Analytics Document) ist das Projekt — die
Apps MAD Designer und MAD Viewer, die Frameworks und die headless Engine —, und
die Nahtstellen für neue Arbeit sind der Punkt: ein neuer Datenbanktreiber, ein
neues Dokumentelement, ein neues Exportformat. Das Tutorial zum Schreiben von
Treibern
([`docs/tutorials/driver-authoring.md`](docs/de/tutorials/driver-authoring.md))
führt durch das erste; es ist der vorgesehene erste Beitrag.

## Voraussetzungen

* **macOS mit Xcode** — die iOS-Seite ist ein Workspace aus vierzehn Frameworks
  plus der App, gebaut für iOS 15 und neuer. Die Frameworks sind Objective-C.
* **Docker** — der Linux-Build der headless Engine: ein Image, das die
  Objective-C-Toolchain (libobjc2, libdispatch, GNUstep) und die C-Bibliotheken
  aus Quellen baut, die elf headless Frameworks kompiliert und ihre Suites
  ausführt.
* Zum Mitwirken ist kein Datenbankserver nötig: Die Live-Suites für MySQL, SQL
  Server und PostgreSQL werden übersprungen, wenn kein Server erreichbar ist, und
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) dokumentiert die
  Docker-Container, die sie bereitstellen.

## Erste Schritte

1. Forken Sie das Repository und klonen Sie Ihren Fork.
2. Bauen und testen Sie, bevor Sie etwas ändern, damit Sie die Ausgangslage
   kennen:

   ```sh
   # iOS: any framework's suite, against the iOS Simulator
   xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
       -destination 'platform=iOS Simulator,id=<device-udid>' \
       -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
   ```

   ```sh
   # Linux: the whole headless engine — 126 test executables, 1,303 tests
   ./Linux/build.sh
   ```

   [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) enthält die
   vollständige Befehlsmatrix, den gemeinsamen DerivedData-Pfad, den die
   Frameworks erwarten, und die Einrichtung der Testdatenbanken.
3. Suchen Sie sich etwas aus. Einen neuen Treiber, ein Element oder ein Issue mit
   dem Label „good first issue“. Klein ist gut: Hier wird gründlich geprüft.

## Die Test-first-Regel

**Schreiben Sie zuerst den fehlschlagenden Test.** Das ist die Kultur des
Projekts, kein Vorschlag: Der Test fixiert das Verhalten, bevor der Code
existiert, und der Fix ist die Änderung, die ihn grün macht. Bei Format- oder
Datenarbeit halten Sie das Fixture vor der Änderung als Momentaufnahme fest,
statt den erwarteten Wert mit dem neuen Code zu erzeugen — das Fixture ist der
Zeuge dafür, dass das Verhalten real war.

Der Zyklus, in dieser Reihenfolge:

1. Fügen Sie einen fehlschlagenden Test hinzu, der das beabsichtigte Verhalten
   beschreibt.
2. Führen Sie ihn aus; sehen Sie zu, dass er aus dem richtigen Grund
   fehlschlägt.
3. Implementieren Sie, dann machen Sie ihn grün.
4. Führen Sie die gesamte Suite aus — iOS *und* `./Linux/build.sh`, wenn Sie
   etwas berührt haben, das der Linux-Build kompiliert (siehe
   `Linux/cmake/*Sources.cmake`). Jeder Commit muss jede Suite grün hinterlassen.

Die Linux-Suites zeichnen bekannte Plattformabweichungen als `NEED`-Zeilen auf,
statt sie stillschweigend zu überspringen — eine neue `NEED` muss einen Grund
tragen, und eine Abweichung, die weder behoben noch festgehalten wird, ist eine
fehlschlagende Änderung.

## Stil

* Tabs, keine Leerzeichen. Kommentare, wo sie ihren Platz verdienen, nicht
  überall.
* Bewusst ungenutzter Code wird mit dem clang-Attribut `unused` an der
  Deklaration markiert — eine nicht markierte Unused-Warnung bedeutet, dass der
  Code tot ist.
* Neue Dateien tragen den einzeiligen Header `Copyright © 2012-2026 Michael
  Thomason. SPDX-License-Identifier: MIT` (`//` für Quellcode, `#` für Skripte).
* [`docs/project/BUGS.md`](docs/project/BUGS.md) hält offene Defekte mit den
  Tests fest, die sie fixieren; wenn Sie einen beheben, wandert der Eintrag nach
  [`docs/project/BUGS_FIXED.md`](docs/project/BUGS_FIXED.md) — ein Fix, der
  nicht festgehalten wird, ist nicht geschehen.

## Developer Certificate of Origin

Dieses Projekt verlangt einen DCO-Sign-off statt einer CLA. Jeder Commit muss
enden mit:

    Signed-off-by: Name <email>

(`git commit -s` fügt ihn hinzu.) Mit der Zeile bescheinigen Sie gemäß
[developercertificate.org](https://developercertificate.org), dass Sie die
Änderung geschrieben haben oder berechtigt sind, sie unter der Lizenz des
Projekts (MIT, siehe `LICENSE`) beizutragen. Die DCO-Prüfung läuft auf den Pull
Requests, sobald das Repository auf GitHub veröffentlicht ist.

## Pull Requests

* Ein Anliegen pro PR. Halten Sie die Commits reviewbar; die Historie des
  Projekts ist ein Protokoll, kein Notizblock.
* Füllen Sie die PR-Vorlage aus — die Test-first-Checkliste ist für den Reviewer
  gedacht, und „nicht zutreffend“-Antworten sind in Ordnung, wo sie wahr sind.
* Ein PR, der den Linux-Build berührt, muss `./Linux/build.sh` im eigenen Branch
  grün zeigen.

## Issues

Die Vorlagen für Fehlerberichte und Treibervorschläge liegen unter
[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/). Sicherheitsprobleme gehen
an den privaten Weg in [`SECURITY.md`](SECURITY_de.md), niemals an ein
öffentliches Issue.

## Hilfe

Fragen Sie in einem Issue (oder im Diskussionsforum, sobald es geöffnet ist). Der
Maintainer beantwortet jedes Issue; das Projekt ist ein Solo-Einsatz, der zu einer
Community heranwächst, daher bekommt eine klare Frage, die zeigt, was Sie versucht
haben, die schnellste Antwort.

## Unterstützung

Der Code von MAD steht unter MIT-Lizenz und ist frei, und Beiträge sind die beste
Art der Unterstützung. Wenn das Projekt Ihrem Team Zeit spart und Sie mehr geben
möchten, nimmt der Maintainer
[GitHub Sponsors](https://github.com/sponsors/mthomason) und API-Guthaben für die
agentengesteuerte Entwicklung an — jeder Beitrag fließt in die Arbeit zurück
(siehe die [README](README_de.md), Abschnitt „Unterstützung“).
