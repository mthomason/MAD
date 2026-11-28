---
layout: default
title: "Kompositionsberichte"
description: >-
  Kombinieren Sie Berichte aus mehreren Datenbanken in einem einzigen portablen .mad-Dokument: Jede Quelle behält ihre Abfrage, ihr Layout und ihre Daten, und das Ergebnis verknüpft sie zu einem neuen Bericht.
lang: de-DE
---

# Kompositionsberichte

Ein **Kompositionsbericht** kombiniert andere Berichte zu einem einzigen `.mad`-Dokument. Jeder
Bericht, den Sie einbringen, ist eine **Quelle**; der Standardbericht des Dokuments ist das
**Ergebnis**, das die Ergebnistabellen der Quellen zu einem eigenen neuen Bericht verknüpft.

Komposition ist der Weg, wie ein einzelnes portables Dokument mehrere Datenbanken — MySQL,
PostgreSQL, SQL Server und SQLite — ohne einen Föderationsserver dazwischen umspannt. Die
Quellen werden **mit ihren Layouts** in das Dokument gebracht; ihre Kombination flacht eine
Quelle nicht zu einer Tabelle ab. Jedes Mitglied einer Komposition ist ein vollständiger Bericht.

> **Plattformen:** Kompositionsberichte sind in **MAD Designer für macOS** (0.8)
> und **MAD Designer für Windows** (0.8) verfügbar. Die iOS-App kann noch keine Kompositionen
> erstellen; diese Seite beschreibt die Desktopanwendungen.


## Das mentale Modell

> Ein Kompositionsbericht kombiniert andere Berichte zu einem. Sie bringen vorhandene Berichte
> (**Quellen**) ein, verknüpfen ihre Ergebnistabellen zu einem neuen **Ergebnis**-Bericht, wählen
> aus, welche Ergebnis-**Spalten** angezeigt werden, und entwerfen und betrachten dieses Ergebnis
> dann genau wie einen Standardbericht. Wenn Sie eine Quelle auswählen, erhalten Sie wieder deren
> Abfrage, Layout und Zeilen.

Vier Verben decken den Arbeitsablauf ab: **Quellen hinzufügen → verknüpfen → Spalten auswählen → auswählen**.

| Begriff | Bedeutung |
|---|---|
| **Kompositionsbericht** | Ein `.mad`-Dokument, das einen Graphen von Berichten hält: das Ergebnis plus seine Quellen. |
| **Ergebnis** | Der Standardbericht des Dokuments. Er verknüpft die materialisierten Tabellen der Quellen und ist der Bericht, der zuerst geöffnet, standardmäßig gedruckt und standardmäßig exportiert wird. |
| **Quelle** | Ein untergeordneter Bericht, der in die Komposition eingebracht wird. Er behält seine eigene Abfrage, Datenbankverbindung, sein Layout und seine Zeilen. |
| **Berichtsspalten** | Die Felder, die das Ergebnis seinem eigenen Layout und seinen übergeordneten Berichten offenlegt. Bearbeitet im Abfrage-Arbeitsbereich (der Eintrag **Outputs…** unter macOS, **Columns** unter Windows). |
| **Quelle ohne Layout** | Eine Quelle, deren Bericht noch keine Elemente hat. Der Designer bietet an, ein Layout zu erstellen; der Betrachter zeigt ihre Zeilen als Tabelle. |

### Jedes Mitglied ist ein Bericht

Das ist die Regel, die die Funktion lesbar macht. Eine Quelle wird beim Import nicht auf eine
Tabelle reduziert: ihre Abfragedefinition, ihr eigenes Berichtslayout und ihre Daten kommen alle
mit, und sie werden im selben `.mad`-Dokument gespeichert. Die Zeilen bleiben im Begleitspeicher
(den Dateien `.maddb` und `.mdcache` neben dem Dokument), nicht im `.mad`.

Wenn Sie eine Quelle in der **Report**-Auswahl (macOS) oder in der **Component**-Auswahl und dem
Bereich **Composition** (Windows) auswählen, wechseln **alle drei Arbeitsbereiche** — Abfrage,
Designer und Betrachter — zu dieser Quelle. Eine Quelle ohne Layout ist weiterhin ein gültiger
Bericht: Der Betrachter zeigt ihre zwischengespeicherten Zeilen in einem Raster statt auf einer Seite.



## Eine Komposition erstellen

### macOS

* **File ▸ New Document…** bietet **Standard Report** und **Composition Report**.
  Wenn Sie Composition Report wählen, werden Sie gebeten, einen oder mehrere vorhandene
  `.mad`-Berichte auszuwählen und dann anzugeben, wo die neue Komposition gespeichert wird.
* **File ▸ New Composition…** ist der direkte Befehl für denselben Ablauf.
* **File ▸ Convert to Composition…** verwandelt den geöffneten Standardbericht in eine
  Komposition mit einer Quelle und behält dabei sein Layout.
* Im Arbeitsbereich **MAD Query** fügt das Add-Menü eine Tabelle, eine **Quellabfrage** aus
  einer neuen Datenbankverbindung, einen **importierten Bericht** oder die zusammengesetzte
  **Wurzelabfrage** hinzu.

Die **Report**-Auswahl in der Symbolleiste listet zuerst das **Ergebnis** auf (markiert als
*Ergebnis — <Name>*) und dann jede Quelle. Die Auswahl eines Eintrags ändert nie den aktiven
Arbeitsbereich; sie ändert, welchen Bericht dieser Arbeitsbereich anzeigt.

### Windows

* **File ▸ New Composition…** erstellt eine Komposition aus vorhandenen Berichten.
* **File ▸ Import…** fügt der geöffneten Komposition einen Bericht als Quelle hinzu.
* **File ▸ Convert to Composition** verwandelt den geöffneten Standardbericht in eine Komposition.

Ein angedockter Bereich **Composition** sitzt neben dem Arbeitsbereich (bei einem Standardbericht
fehlt er). Sein Graph zeigt das Ergebnis auf Tiefe 0 und seine Quellen darunter, wobei
Verbindungen auf den Konsumenten zeigen. Der Bereich und die **Component**-Auswahl der
Symbolleiste teilen sich eine Auswahl; der Bereich kann eingeklappt werden, und die Auswahl
bleibt bestehen.

## Quellen verknüpfen und Spalten auswählen

Ziehen Sie auf der Leinwand des Ergebnisses ein Feld von einer Quellenkarte auf ein Feld in einer
anderen, um eine Verknüpfung zu erstellen, und klicken Sie dann auf das Verknüpfungsabzeichen, um
ihren Typ zu ändern (`INNER`, `LEFT OUTER`, `RIGHT OUTER`, `FULL OUTER`, `CROSS`) oder ihre
Richtung umzukehren. Das Ergebnis ist eine normale Abfrage: Es kann beliebig viele Quellen
verknüpfen, filtern, gruppieren und sortieren.

Eine Quelle, die selbst eine Komposition ist, tritt dem Graphen mit ihren eigenen Quellen bei;
der übergeordnete Bericht verweist auf das Ergebnis dieser Komposition. Ein komponierender
Knoten verweist nur auf seine Kinder — nie auf eine entfernte Tabelle —, sodass jedes Blatt gegen
seine eigene Datenbank läuft und jeder Verknüpfungsschritt lokal in SQLite ausgeführt wird.

Verwenden Sie den **Berichtsspalten**-Editor des Ergebnisses, um die Felder, die das Ergebnis
offenlegt, auszuwählen, zu benennen und zu ordnen. Die Feldliste des Designers für das Ergebnis
ist genau diese Menge. Eine Quelle legt ihre eigenen Abfragefelder offen.

## Aktualisieren, Zugangsdaten und Datenschutz

Eine Aktualisierung durchläuft den Graphen **zuerst die Kinder, zuletzt das Ergebnis**. Jedes
Blatt führt gegen seine eigene Datenbank mit seinen eigenen Zugangsdaten aus; jeder komponierende
Bericht läuft lokal über die materialisierten Tabellen seiner Kinder. Jeder Knoten materialisiert
seine eigene Tabelle, und ein fehlgeschlagener Knoten lässt die Aktualisierung scheitern, während
die vorherigen vollständigen Ergebnisse lesbar bleiben.

Eine Komposition mit mehreren Quellen fragt daher **eine Zugangsdatenangabe pro Quelle** ab,
jeweils ein Dialogblatt auf einmal, wobei Treiber, Host, Port, Datenbank und der nicht geheime
Benutzername bereits ausgefüllt sind. Kennwörter werden nie in der `.mad`-Datei gespeichert:
macOS bewahrt sie im Schlüsselbund (oder in der aktuellen Sitzung) auf, und Windows bewahrt sie
in der Sitzung oder im Zugangsdatenspeicher der Plattform auf. Eine SQLite-Quelle benötigt keine
Zugangsdaten.

## Beispiele

Zwei ausführbare Kompositionen liegen in [`Samples/Reports`](https://github.com/mthomason/MAD/tree/master/Samples/Reports):

* **`Chinook-Composition.mad`** — zwei SQLite-Quellen (ein Albums-Bericht mit eigenem
  Layout und ein Artists-Bericht ohne) zu einem Ergebnis verknüpft. Es braucht nichts außer
  der mitgelieferten `chinook.sqlite3`.
* **`Composition-MySQL-PostgreSQL-SQLServer.mad`** — eine kleine Tabelle aus MySQL,
  PostgreSQL und SQL Server, verknüpft über `demo_id`, was ein einzelnes Dokument
  demonstriert, das drei Datenbanken umspannt.

Richten Sie die drei Live-Server ein und befüllen Sie die datenbankübergreifende Tabelle mit
einem idempotenten Skript (macOS, Linux und Git Bash unter Windows):

```sh
./Samples/setup-databases.sh up
```

Unter Windows PowerShell:

```powershell
.\Samples\setup-databases.ps1 -Action up
```

`up` erstellt oder startet die fixierten Container über die Testdatenbank-Skripte und lädt die
Tabelle `composition_demo` in jeden Server. `status` meldet die Container und Zeilenanzahlen;
`down` stoppt sie. Dasselbe SQL kann ohne Docker mit
`./Samples/setup-databases.sh sql` ausgegeben werden. Siehe [die Beispielanleitung](https://github.com/mthomason/MAD/blob/master/Samples/README.md)
für die Erstinbetriebnahme, einschließlich der Kennwortabfragen pro Quelle.

## Aktuelle Einschränkungen

* **Nur dasselbe Dokument.** Die Definition und das Layout jeder Quelle leben in der einen
  `.mad`-Datei. Ein Verweis auf einen Bericht in einer anderen Datei wird nicht unterstützt.
* **Bis zu zehn direkte Kinder pro komponierendem Bericht.** Der SQLite-Build der Engine
  erlaubt zehn angehängte Datenbanken; der Designer lehnt ein elftes Kind ab.
* **Verschachtelte Kompositionen sind im Abfrage-Arbeitsbereich schreibgeschützt.** Eine Quelle,
  die selbst eine Komposition ist, zeigt die Quellen, die sie verknüpft, aber einen
  verschachtelten Komponisten direkt zu erstellen ist eine spätere Arbeit.
* **`json-report` exportiert nur das Ergebnis.** Jedes andere Exportformat exportiert den
  ausgewählten Bericht.

## Verwandte Themen

* [MAD Designer für macOS](../macos.html) — die native AppKit-Anwendung.
* [MAD Designer für Windows](../windows.html) — die native WPF-Anwendung.
* [Die Richtung](../vision.html) — Berichte als kombinierbare Datenquellen.
* [Das Datenobjekt](developers/data-object.html) — Definition, Schema und Ergebnismenge eines
  Berichts als ein Vertrag.
* [Berichte mit mehreren Quellen](developers/multi-source.html) — die Architektur hinter der
  Komposition im selben Dokument.
