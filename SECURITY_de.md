[English](SECURITY.md) | [简体中文](SECURITY_zh.md) | [日本語](SECURITY_ja.md) | [Português (Brasil)](SECURITY_pt-BR.md) | **Deutsch**

# Sicherheitsrichtlinie

## Unterstützte Versionen

Nur die neueste Version erhält Sicherheitskorrekturen. Das Projekt hat noch keine
öffentliche Version veröffentlicht; sobald es eine gibt, ist alles Ältere als
die neueste Version nicht unterstützt, und Benutzer sollten aktualisieren.

| Version | Unterstützt |
|---|---|
| neueste Version | :white_check_mark: |
| alle älteren | :x: |

## Was zum Geltungsbereich gehört

* Die Engine und ihre Frameworks: der `.mad`-Leser und -Schreiber, der
  Abfrage-Compiler, die Renderer, die Treiber (MySQL, SQL Server, SQLite) und die
  `mad`-CLI.
* Die App selbst, für die Teile, die von einem Dokument oder einer Verbindung aus
  erreichbar sind: Dokument-Parsing, Speicherung von Zugangsdaten und alles, was
  eine Serverantwort oder eine Datei als Eingabe nimmt.

Bitte beachten Sie das Vertrauensmodell: Ein `.mad`-Dokument enthält eine Abfrage,
und eines zu öffnen bedeutet, einen Bericht ausführen zu wollen — das Format ist
eine Definition, kein in einer Sandbox isolierter Code, und Code innerhalb eines
Dokuments wird niemals ausgeführt.

## Eine Schwachstelle melden

**Öffnen Sie kein öffentliches Issue.** Melden Sie privat:

* Sobald das Repository veröffentlicht ist: Verwenden Sie den GitHub-Ablauf
  **Report a vulnerability** (**Security → Advisories**), der den Bericht
  vertraulich hält und es uns ermöglicht, ein Advisory zu veröffentlichen, in
  dem Sie genannt werden, wenn der Fix erscheint.
* Bis dahin wenden Sie sich direkt an den Maintainer.

Geben Sie nach Möglichkeit an: die betroffene Komponente und Version, einen
minimalen Reproduzierer oder das Dokument/die Abfrage, die das Problem auslöst,
und die erwartete Auswirkung. Sie erhalten innerhalb einer Woche eine Bestätigung
und, sobald eine vorliegt, einen Fix oder eine schriftliche Einschätzung.

## Erwartungen

Es gibt kein Bug-Bounty-Programm. Das Projekt ist die Arbeit eines einzelnen
Maintainers; Sie erhalten einen schnellen Fix, bei dem Sie genannt werden, und
ein schriftliches Advisory. Responsible Disclosure (der Bericht bleibt privat,
bis ein Fix ausgeliefert ist) wird vorausgesetzt, und das Advisory nennt Melder,
die genannt werden möchten.

## Bekannte, akzeptierte Kompromisse

Dies sind Designentscheidungen, keine zu meldenden Fehler — sie sind in der
Spezifikation und im Fehlerregister dokumentiert, und sie zu ändern ist eine
Produktentscheidung:

* Der `.mad`-Container hat noch keine Magic Bytes (`docs/06-hazards.md`, Fallstrick
  H1); die Erkennung erfolgt im ausgelieferten Format über die Dateiendung, mit
  Magic Bytes in der normativen `v1`.
* Der Render-Cache ist nach Dateiname und Seitengröße indiziert, nicht nach
  Inhalt (`docs/05-companion-files.md` §5.3), sodass eine Bearbeitung eines
  Dokuments unter demselben Namen veraltete Seiten ausliefern kann, bis die
  Cache-Dateien entfernt werden.
* Die Datenbank-Zugangsdaten der Testsuiten in
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) sind
  Wegwerf-Zugangsdaten für lokale Docker-Container, keine
  Produktionsgeheimnisse.
