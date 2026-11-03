---
layout: default
lang: de-DE
---

# Die Richtung: Ein Bericht ist eine Tabelle

Aktualisiert am 2026-10-29. Diese Seite beschreibt die Richtung, in die MAD
wachsen soll. Keiner der hier beschriebenen Kompositions- oder
Migrationsmechanismen ist bereits gebaut; das Design, auf dem das
Datenobjektmodell basiert, steht in
[`docs/project/MAD_DATA_OBJECT.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_DATA_OBJECT.md),
das Arbeitsprotokoll in
[`docs/project/MAD_FUTURE.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_FUTURE.md)
und die Produktwunschliste in
[`docs/project/TODO.md`](https://github.com/mthomason/MAD/blob/master/docs/project/TODO.md).

## Wo MAD heute steht

Ein `.mad`-Dokument ist die *Definition* eines Berichts: der Schema-Snapshot, der
Abfragegraph (Tabellen, Joins, Gruppierungen, Filter) und der bandbasierte
Layoutbaum. Beim Aktualisieren kompiliert die Engine den Graphen zu SQL, liest die
Zeilen einmal und materialisiert sie in einem begleitenden SQLite-Cache
(`.maddb` + `.mdcache`). Die Zeilendaten bleiben bewusst außerhalb des Dokuments;
die Definition bleibt unter 100 KB.

Eine Konsequenz wird leicht übersehen: **Ein Bericht ist eine Funktion von
Datenquellen auf eine Tabelle.** Jeder Treiber liefert ein Schema und Zeilen in
Tabellenform, und die Ausgabe eines Berichts *ist* ein Schema (`MADDataColumn`)
und Zeilen in Tabellenform (`MADDataTableFast`). Die Engine behandelt beide
bereits identisch.

## Wohin es führt

Den Kreis zwischen der Definition eines Berichts und seiner materialisierten
Ausgabe zu schließen, eröffnet vier Fähigkeiten:

### 1. Eine `.mad`-Datei als Ad-hoc-Datenbanktabelle

In einer Datenbank wählt man aus Basistabellen wie `employee` oder `sales_data`
aus. Ein Bericht verknüpft mehrere Tabellen miteinander, und seine Ausgabe ist
eine materialisierte Ad-hoc-SQLite-Tabelle. Heute kann nichts eine Abfrage auf
die Ausgabe eines anderen Berichts richten — der Ergebnis-Cache existiert, ist
aber nach einem Dateinamen-Hash statt nach einer adressierbaren Identität
indiziert. Diese Ausgabe adressierbar zu machen bedeutet:

> **Das Ergebnis eines Berichts wird zu einer Datenbanktabelle, aus der andere
> Berichte und Abfragen auswählen und gegen die sie joinen können.**

Ein Bericht, der auf einem Bericht aufbaut, ist ein DAG aus abgeleiteten Tabellen —
eine portable semantische Schicht, in der das Entwerfen eines Berichts zugleich
das Entwerfen einer wiederverwendbaren Datenquelle ist.

### 2. Mehrere Datenquellen in einem einzigen Bericht

Jeder Treiber (`MADMySQL`, `MADPostgres`, `MADTdsClient`, `MADSqlite3`)
materialisiert seine Ergebnismenge in derselben lokalen SQLite-Tabellendarstellung.
Sobald ein Dokument mehrere Abfragedefinitionen halten und jede Ausgabe als
Tabelle adressieren kann, kann ein Bericht eine PostgreSQL-Tabelle mit einer
SQL-Server-Tabelle und einer MySQL-Tabelle joinen — lokal in SQLite föderiert,
ohne einen Föderationsserver dazwischen. Die Snapshots *sind* die Föderation.

### 3. Papier als nur ein Paradigma — native UIKit-Ansichten über Rohdaten

Das bandbasierte Seitenlayout (Report Header, Page Header, Gruppierungen,
Detail, Fußzeilen) wurde für den Druck auf Papier erfunden. Weil das Layout einer
`.mad`-Datei parametrische Daten sind und der Zeilen-Cache `.maddb` lokales SQLite
auf dem Gerät ist, sind Papierseiten nur eine Möglichkeit, einen Bericht
darzustellen. Wenn der Benutzer nicht druckt, können dieselbe Definition und
derselbe lokale Cache als interaktive native UIKit-Ansichten und
Rohdaten-Explorer gerendert werden — einmal layouten, als Papier oder als native
UI anzeigen.

### 4. Legacy-Crystal-Reports-Dateien (`.rpt`) in offene `.mad`-Dateien konvertieren

Crystal Reports (`.rpt`) und ähnliche Legacy-Berichtsdateien sind in Tausenden
von Unternehmen tief verwurzelt, weil keine offene, portable Engine ihr Modell aus
bandbasierten Bereichen und relationalem Abfragegraphen teilt. Weil MAD genau auf
diesem strukturellen Paradigma aufbaut — und seine Definitionen dabei in einem
offenen, dokumentierten SQLite-in-tar-Format speichert —, bietet die Konvertierung
von Legacy-`.rpt`-Dokumenten in `.mad`-Dateien Unternehmen einen direkten
Migrationspfad weg von proprietären Legacy-Reporting-Stacks.

## Was bereits existiert

Die aufwendigen Teile sind gebaut: portable Definitionen, deterministische
SQL-Erzeugung und -Analyse, ein portables Materialisierungsformat (SQLite), vier
Datenbanktreiber und eine Engine, die nativ unter iOS/macOS und headless unter
Linux läuft.

## Was dies nicht ist

Ein Versprechen. Diese Seite hält die Richtung fest; das Design und die
Aufgabenwarteschlange liegen in `docs/project/`, und nichts, was hier beschrieben
wird, wird ausgeliefert, bevor es so entworfen, getestet und dokumentiert ist wie
alles andere im Repository.
