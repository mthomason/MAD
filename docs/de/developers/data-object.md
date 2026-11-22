---
layout: default
lang: de-DE
title: "Das Datenobjekt"
description: "Definition, Schema und Ergebnismenge eines Berichts als ein Vertrag."
---

# Das Datenobjekt — die Definition eines Berichts, sein Schema und seine Ergebnismenge

Diese Seite definiert das Datenobjekt: die Definition eines Berichts, sein Schema und seine Ergebnismenge als ein Vertrag. Es ist das Design, auf dem die Arbeit mit mehreren Quellen aufbaut; die Formatspezifikation beschreibt das Dokument, wie es heute ausgeliefert wird.

**Umfang:** das am 2026-10-16 aufgeworfene Konzept — was ein Datenobjekt ist, wie es in dieser Codebasis repräsentiert wird und was seine Formalisierung erfordert. Die im selben Gespräch beschriebene Verdrahtung für mehrere Quellen / Unterberichte ist hier als Konsequenz des Vertrags niedergeschrieben, bewusst nicht gebaut.
**Datum:** 2026-10-16, gelesen bei `445794e11`.
**Status:** Designdokument. Es schlägt vor; es implementiert nichts, und nichts hier ist eingeplant. [die Projektvision](../vision.html) §1 — „ein Bericht ist eine Funktion von Datenquellen auf eine Tabelle“ — ist die Vision, die diese Datei konkretisiert und für die sie den Code benennt.

---

## 1. Die Idee und was sie nicht ist

Heute entwirft der Benutzer eine Ad-hoc-Abfrage gegen eine Datenbank (MySQL, SQL Server oder Sqlite3), sie gibt eine Datentabelle zurück, und der Bericht wird von den Layoutwerkzeugen auf diesen Daten aufgebaut. Der Bericht ist Abfrage plus Layout. Die Verallgemeinerung besteht darin, die Abfragehälfte zu nehmen und sie zum Objekt zu machen:

> Ein Datenobjekt ist eine benannte Definition, die ein **Schema** und eine **Ergebnismenge** erzeugt — die Abfrage eines Berichts, getrennt von seinem Layout und mit einer eigenen Identität versehen, sodass ihre Ausgabe aktualisiert, adressiert und von einem anderen Datenobjekt als Quelle verwendet werden kann. Ein Bericht ist ein Datenobjekt plus eine Präsentation, die an die Spalten des Objekts gebunden ist.

Die Worte des Benutzers selbst (2026-10-16): *„etwas, das eine Art Schema und eine Ergebnismenge zurückgibt, während der Bericht Ad-hoc-Abfrage, Reporting und Design ist.“*

Drei Konsequenzen, jede unten verfolgt:

1. **Die Abfrage wird zur Produktgrenze.** Dasselbe Objekt dient dem Designer (was der MAD Query-Arbeitsbereich bearbeitet), dem Betrachter (was Refresh ausführt), der CLI (was `mad refresh` ausführt), einem künftigen Webserver (was ein Endpunkt ausführt) und einer KI (was sie entwirft und die Engine validiert). Eine Definition, viele Konsumenten — was erst wahr ist, sobald das Objekt einen eigenen Namen und ein eigenes Schema hat.
2. **Objekte komponieren.** *„Die Idee wäre, mehrere davon zu verknüpfen. In der Reporting-Welt wären das Unterberichte“* (Benutzer). In Datenbegriffen ist es ein DAG abgeleiteter Tabellen: die Ausgabe eines Objekts ist eine Tabelle für ein anderes, genau wie heute eine Schematabelle.
3. **Quellen vervielfachen sich als Konsequenz, nicht als Funktion.** Ein Objekt pro Quelldatenbank — jedes trägt bereits eigenen Treiber und eigene Verbindung — materialisiert und dann über ihre Ausgaben verknüpft. Die Skizze des Benutzers: *„du würdest MySQL in einem Unterbericht abfragen und SQL Server in einem Unterbericht … und dann könntest du diese Berichte im Abfragedesigner über ihre Ausgabe als Tabellen verknüpfen.“* [die Projektvision](../vision.html) §1 sagt dasselbe: keine Föderations-Engine nötig; die Snapshots *sind* die Föderation.

Was es ausdrücklich **nicht** ist:

- Keine Föderations-Engine. Nichts Neues spricht in einer Anweisung mit MySQL und SQL Server; jedes Objekt führt gegen seine eigene Quelle aus, und der Join geschieht über die bereits lokalen Ergebnisse.
- Keine zweite Abfrageimplementierung. Der SQL-Generator, die Treiber, die Ergebnistabelle und die SQLite-Join-Engine existieren alle; §5 ist eine Verdrahtung darauf.
- Keine Änderung am zweistufigen Paradigma „alles in den Cache ziehen“. Der Cache ist tragend und bewusst groß (`MAD_FORMAT.md` §5.1); ein Datenobjekt erzeugt genau das, was der Cache heute bereits hält.

## 2. Vokabular, weil „Schema“ in dieser Codebasis vier verschiedene Dinge ist

| Begriff | Was er ist | Heutige Klassen |
|---|---|---|
| **Quellschema** | Die Tabellen und Felder einer Datenbank, die der Benutzer abfragen kann | Live-Browsing: `MADDatabaseTable` / `MADDatabaseField` (`MADAPI`). Snapshot: `RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`, einmal bei der Dokumenterstellung importiert |
| **Definition** | Der Abfragegraph: welche Tabellen, welche Felder, die Joins, Filter, Gruppierungen, Sortierung | `RptqQuery` + `RptqQueryTable` / `RptqQueryField` / `RptqQueryLinks` / `RptqQueryPredicate` / `RptqQueryGroup` |
| **Ergebnisschema** | Die Spalten der Ausgabe: Name, Typ, nativer Typ, Länge/Präzision, Primärschlüssel, not-null | `MADDataColumn` (eine pro Spalte), an der Tabelle getragen |
| **Ergebnismenge** | Die Zeilen | Klassencluster `MADDataTable`; materialisiert als `MADDataTableFast` |
| **Materialisierung** | Die Ergebnismenge auf der Platte: die SQLite-Tabelle und ihr serialisiertes Schema | `<tag>.maddb` (SQLite) + `<tag>.mdcache` (plist, `MADDataTable -copyPlist`) im Cache-Verzeichnis des Dokuments |
| **Snapshot** | Das Wort von `MAD_FUTURE.md`: eine Materialisierung, benannt, versioniert und adressierbar gemacht | Existiert nicht; §4.3 ist, wie sie beginnt |
| **Speicherschema** | Unabhängig von alldem oben: das eigene Speicherformat des Dokuments | `MADStoreSchema` (`MAD/Source/rptq/store/`) |

Das Dokument hält heute Definitionen und Layouts; Materialisierungen leben daneben, verschlüsselt nach dem Dokument (nicht nach der Definition). Diese Trennung ist die richtige — `MAD_FORMAT.md` §5 — und dieses Design behält sie bei.

## 3. Wie die Idee heute repräsentiert wird

Jedes Stück eines Datenobjekts existiert bereits, in einer anderen Schicht, für einen anderen Zweck gebaut. Was folgt, ist der genaue Zustand jedes Stücks, mit der Naht, die eine Formalisierung einklemmen würde.

### 3.1 Die Definition existiert — `RptqQuery` und ihr Graph

Der Abfragegraph ist vollständig genug zum Kompilieren: Tabellen (`RptqQueryTable`, mit `alias` und einem `dropIndex`, sodass eine Schematabelle mehrmals eingeschlossen werden kann), Projektionen (`RptqQueryField` — Schematabelle + Schemafeld-IDs), Joins (`RptqQueryLinks`, mit einem Link-Typ), Filter (`RptqQueryPredicate`), Gruppierungen (`RptqQueryGroup`, die über `RptqQuery -sortDescriptorsForDatabase:` Sortierdeskriptoren treiben) und eine rudimentäre Sortierzeile (`RptqQuerySort`, nur von Debug-Beschreibungen gelesen). Der Designer bearbeitet ihn durch das Read-Modell `MADModel*` („durch `Rptq` schreiben; durch `MADModel` lesen und beobachten“ — `MADModel_Layer.md`).

Eine Gruppierung ist eine Definition auf Abfrageebene, kein Berichtsabschnitt. `RptqQueryGroup.hasField` benennt das Feld, nach dem die Abfrage gruppiert, und `sort` seine Richtung. Damit die Abfrage läuft, muss jedes Feld einer Gruppe zu einer Abfragetabelle gehören, die das Dokument auswählt (`hasField.inQueryTable`): die Gruppierung wird als geordneter Schlüssel über die Ergebniszeilen materialisiert (`-sortDescriptorsForDatabase:`), und der Formatierer vergleicht diesen Schlüssel, um Gruppengrenzen zu finden. Ein Kopf-/Fußabschnitt einer Berichtsgruppe ist nur die Präsentation dieser Gruppe — er darf kein Element enthalten, das das Gruppierungsfeld anzeigt, und die Gruppierung geschieht trotzdem. Kein Layout kann ein fehlendes Gruppierungsfeld liefern, also ist eine Gruppe mit einem nil-Feld oder einem Feld, das nicht durch eine ausgewählte Abfragetabelle gestützt ist, ein ungültiges Dokument. Der Designer baut und beschriftet einen solchen Abschnitt dennoch, damit die defekte Gruppe sichtbar ist; Abfrageausführung und Rendern verweigern ihn mit `NSInvalidArgumentException` und protokollieren die Gruppe.

Zwei Fakten über ihre Identität:

- Eine `RptqQuery` hängt an einer `RptqDatabase`-Zeile und erreicht das Dokument über „das jeweils erste“: `RptqDatabase -defaultQuery` ist `hasQueries.anyObject` (`RptqDatabase+Extras.m:88`), `RptqDocument -mainQuery` ebenso (`RptqDocument+Extras.m:184`).
- Der Speicher erlaubt bereits viele: `MADModelDocument` baut **ein `MADModelDatabase` pro `RptqQuery`-Zeile** (`MADModelDocument.m:210-240`), mit dem eigenen Kommentar des Codes, dass „current versions of the software only use one database and query.“ Die Kardinalität ist eine Konvention der Abläufe der App, nicht des Speichers.

### 3.2 Der Compiler existiert — `MADQueryFull`

`MADQueryFull -copySQLWithManagedObjectContext:error:` (`MADQueryFull.m:133`) baut das SQL: die projizierten Spalten kommen aus `MADQuerySelectExpressionActiveFields`, das `MADQueryActiveQueryFields` für jedes Feld fragt, auf das die *Elemente*, Links und Gruppen des Berichts verweisen; FROM/JOIN wird aus einem `MTGraph` von Tabellen und Links kompiliert, topologisch sortiert (`:170-204`); Prädikate und das Quoting von Literalen gehen über `MADDatabase` (`newSafeIdentifier:`, `newSafeLiteral:`); `LIMIT` über `sqlLimitClause:`.

Das ist die deterministische, eigene SQL-Erzeugung, die `MAD_FUTURE.md` §3 als Unterscheidungsmerkmal zählt — sie existiert, und sie ist headless (im Linux-Build `MADSources.cmake:93`).

**Aber sie ist an das Dokument geschweißt.** `MADQueryFull` speichert die Abfrage, mit der es initialisiert wurde, in `queryObject` (`:79`) und **verwendet sie nie**: der SQL-Pfad liest die erste Datenbank und die erste Abfrage des Dokuments neu (`:147-149`). Und es implementiert `-getSql:error:` nicht (die Basis gibt `@""` zurück, `MADQuery.m:48`), also kann der generische Pfad `MADDatabase -executeQuery:withError:` die Hauptabfrage des Dokuments überhaupt nicht ausführen. Das Abfrageobjekt, das man ihm übergibt, bestimmt nicht, was läuft.

### 3.3 Die Ausführungsnaht existiert — `MADDatabase`

Der abstrakte Punkt ist
`-[MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADAPI/Source/MADDatabase.m:147`, von allen drei Treibern überschrieben). Sein Ziel ist typisiert als `id <MADDataTableWriting>` — *jede* beschreibbare Tabelle, keine Tabellenklasse. Der Füllvertrag ist über die Treiber hinweg einheitlich: `removeAllObjects` → `addColumn:` → `beginBulkInsert` → `addRowWithDataForFieldKeys:` → `endBulkInsert` (die Treiber von `MAD_DATA_OBJECT`: MySQL `MADMySQLFetch+DataTable.m:148-235`, SQL Server `MADDatabaseSQLServer.m:485-571`, Sqlite3 `MADDatabaseSqlite3.m:474-540`).

Die Treiber bevorzugen zudem bereits das eigene Ziel einer Abfrage gegenüber dem des Dokuments, wenn die Abfrage `MADQueryDataTableProtocol` erfüllt (`MADQuery.h:28-50`; `-executeQuery:` jedes Treibers prüft es — z. B. `MADDatabaseMySQL.m:331-339`). Mehrere Ergebnistabellen pro Prozess sind ein beabsichtigter Erweiterungspunkt, der nur von der Beispieldaten-Abfragefamilie genutzt wird.

Die Verklebung auf Dokumentebene ist `MADOperationRefresh` (`MADDesigner/Source/MADOperationRefresh.m`, 131 Zeilen, kein UIKit): Zugangsdaten hinein, `document.mainQuery` → SQL, `document.database` verbindet, Ausführen in `document.dataTable`, `dataTableMakeCache` schreibt die `.mdcache`, `document.refreshed = YES`. Es ist auch das Refresh-Verb der CLI, über die Targetgrenze hinweg kompiliert durch `REFRESH_SOURCES` in `CLI/build.sh` (`ROADMAP.md` §3.4). Es ist *Refresh + Persistieren + Veröffentlichen*, nicht *Ausführen*: es ist fest an den geteilten Dokumentzustand verdrahtet, entdeckt Zugangsdaten durch Untersuchen von `self.dependencies` und verändert das Dokument.

### 3.4 Der Rückgabewert existiert — `MADDataTable` und `MADDataColumn`

`MADDataTable` (`MADFoundation/Source/MADDataTable.h`) ist der Klassencluster, dessen gesamte Aufgabe „Schema plus Zeilen“ ist: Metadaten plus Persistenz auf der Basis, Speicherung pro Unterklasse (`MADDataTableVirtual` im Speicher, `MADDataTableFast` über SQLite). Das Schemaobjekt ist `MADDataColumn` — `identifier`, `fieldName`, `caption`, `type` (`MADDataType`), `nativeType`, `dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`, `isAutoIncrement`, `defaultValue` — eine erstklassige, serialisierbare Spaltenbeschreibung.

Und das Schema ist auf der Platte bereits von den Zeilen trennbar: `-copyPlist` (`MADDataTable.m:238-253`) serialisiert Name + Spaltenschlüssel + Spalten-Plists + Zeilenzähler und **ausdrücklich keine Zeilen** — genau das ist die Datei `.mdcache`, geschrieben und gelesen von `MADDataTableFast` (`-copyPlist` / `-loadWithPlist:`; `MAD_FORMAT.md` §5.3).

Was in dieser Schicht fehlt:

- **Keine reine Schema-API.** Nichts gibt das Ergebnisschema einer Abfrage zurück, ohne sie auszuführen. Schema und Daten sind ein Objekt, nie zwei — das Schema wird *aus* den Zeilen entdeckt.
- **Sqlite3-Ergebnisse mit null Zeilen verlieren ihr Schema vollständig.** Der Sqlite3-Treiber entdeckt Spalten nur innerhalb der ersten `SQLITE_ROW`-Iteration (`MADDatabaseSqlite3.m:496-535`), also erzeugt ein leeres Ergebnis eine Tabelle ohne Spalten und ohne DDL. MySQL und SQL Server fügen Spalten aus den Ergebnis-Metadaten hinzu, bevor eine Zeile ankommt, also ist die Lücke Sqlite3-spezifisch.
- Die `columnKeys` von `MADDataTableFast` sind generierte Namen `c<hash>`, keine Feldnamen; die nutzbare Schemaoberfläche ist das Wörterbuch `columns` von `MADDataColumn`. Und `for (x in fastTable)` liefert still nichts — die Basis gibt 0 Elemente zurück und Fast überschreibt `countByEnumeratingWithState:` nicht; Aufrufer müssen `objectEnumerator` verwenden.

### 3.5 Die Materialisierung ist heute eine SQLite-Tabelle

`MADDataTableFast` ist keine Abstraktion über eine Tabelle; es *ist* die Tabelle. Jede Instanz besitzt eine physische SQLite-Tabelle `t<tag>` in `<tag>.maddb` (`-tableName` `MADDataTableFast.m:498`, `-filenameCacheMadDB` `:399`), mit Spalten `c<hash-of-fieldName>`. Eine zweite Verbindung (`databaseForSelects`) führt die Auswahlseite aus. Gruppierung sind Indizes auf dieser einen Tabelle (`-sortUsingDescriptors:` `:737`, `-setupGroupKeyIndexes` `:545`, ein Index pro Präfixebene der Gruppe), und Aggregate sind SQL über den Cache (`MADQueryCacheAggregateFunction`, getrieben von `MADocument -dataForRows:column:groups:function:groupBy:`). **Für die Quelldatenbank wird nie ein `GROUP BY` erzeugt** — geprüft: der String erscheint in keiner Quelldatei. Die Quelle wird flach abgefragt; alles Gruppierte oder Aggregierte wird lokal über die Materialisierung von Sqlite3 berechnet.

Zwei verräterische Stubs zeigen, dass die Architektur Grund hat, *viele* Tabellen zu wollen: die Klassenfabrik `MADDataTable+Constructor` (`newDataTableOfType:withObjectID:cacheDirectory:` — physical bildet auf `MADDataTableFast` mit der id als Tag ab, `:56-78`) macht zweite und dritte Tabellen von der Konstruktion her billig; und `-cacheTableNameForGroupLevel:` (`MADDataTableFast.m:813`) würde eine Tabelle `s<level>` pro Gruppenebene benennen — es hat **keine Aufrufer**; die pro Gruppierung implizierten Tabellen materialisieren nie.

**Die Adresse ist der Dateiname.** Die Tabelle des Dokuments wird erzeugt mit
`initWithId: fileURL.lastPathComponent.hash` (`MADocument.m:269-283`); das Cache-Verzeichnis wird `dataTableIdHash` benannt (`MADURLFactory newURLCacheFilesDirectoryForFilename:`). Eine Ergebnistabelle pro Dokument; ihr Name ändert sich, wenn das Dokument umbenannt wird; nichts kann darauf zeigen.

### 3.6 Was fehlt, in einer Tabelle

| Schicht | Existiert | Fehlt für ein Datenobjekt |
|---|---|---|
| Definition | Voller Abfragegraph; Read-Modell; Speicher erlaubt viele Abfragen | Ein eigener Name und eine eigene Identität; ein Quellverweis, der ein anderes Datenobjekt sein kann |
| Compiler | Deterministisches SQL aus dem Graphen | Freiheit von „der ersten Abfrage des Dokuments“; ein reiner Schema-Pfad |
| Ausführung | Jedes Ziel `MADDataTableWriting`; drei Treiber; Zieltabelle pro Abfrage | Ein Ausführen, das nicht Refresh ist — keine Veränderung des Dokuments, Zugangsdaten übergeben statt entdeckt |
| Rückgabewert | `MADDataTable` + `MADDataColumn`; reine Schema-Persistenz (`-copyPlist`) | Eine API für Schema ohne Ausführen; der Schemaverlust bei null Zeilen |
| Materialisierung | Echte SQLite-Tabellen `t<tag>`; lokale Gruppierung und Aggregate | Tag = Dateinamen-Hash; eine Tabelle pro Dokument per Konvention |
| Bindung | Layout → `referencesQueryField` → beim Rendern aufgelöst von `MADDocumentObjectDataReference*` | Bindung an *ein* Datenobjekt statt an die einzige Abfrage *des* Dokuments |
| Adresse | — | Alles |

Drei Festverdrahtungspunkte sind die konkreten Blocker, und alle drei sind im Code sichtbar:

1. `MADQueryFull` ignoriert sein eigenes Abfrageobjekt (`MADQueryFull.m:147-149`).
2. `MADDocument -dataTableForQuery:` gibt `self.dataTable` für `MADQueryFull` und nil für alles andere zurück (`MADocument.m:908`) — ein Ein-Slot-Schalter.
3. `MADQueryActiveQueryFields` durchsucht **alle** Elemente, Links und Gruppen im Speicher ohne Abfragebereich (`MADQueryActiveQueryFields.m:27-99`), unter seinem eigenen Header-FIXME: *„Right now the software only handles one query object.“* Die Felder einer zweiten Abfrage würden in die SELECT-Liste der ersten Abfrage lecken.

## 4. Der Vertrag

### 4.1 Form im Code (vorgeschlagen, illustrativ)

Zwei Hälften, bewusst getrennt:

```objc
@protocol MADDataObjectSchema <NSObject>            // describe: no database needed
- (NSArray<MADDataColumn *> *)resultSchema;          // columns, types, from graph + snapshot
@end

@protocol MADDataObjectExecuting <NSObject>          // execute: yields the materialization
- (nullable MADDataTable *)executeIntoDataTable:(nullable MADDataTable *)target
                                      credentials:(MADCredentials *)credentials
                                            error:(NSError **)error;
@end
```

Die Namen sind illustrativ; die Trennung ist der Punkt. **Beschreiben** muss ohne Verbindung, ohne Zugangsdaten und ohne Zeilen funktionieren — aus dem Graphen plus dem gespeicherten Schema-Snapshot —, weil das das ist, was der Designer zeichnet, wogegen die KI validiert, was ein Webserver auflistet und was ein umbenanntes Dokument nicht beschädigen kann. **Ausführen** muss eine Zieltabelle und Zugangsdaten als Argumente nehmen und die Tabelle zurückgeben — keine Dokumentveränderung, sodass `MADOperationRefresh` auf „execute aufrufen, dann persistieren, dann veröffentlichen“ schrumpft und CLI, Server und Test alle dasselbe aufrufen.

### 4.2 Schema ohne Ausführen

Das ist der erste ehrliche Beweis, dass der Vertrag echt ist, weil es *ableitbar* ist und heute nichts es ableitet: das Ergebnisschema ist genau die SELECT-Liste, die `MADQueryFull` bereits berechnet — die aktiven Abfragefelder, aliasiert als `Table.Field`, plus das, was die Aggregate und Gruppierungen projizieren. Die Typen und Breiten kommen aus dem Schema-Snapshot (`RptqDatabaseSchemaField`); Aggregatspalten aus `MADAggregateFunctionType`. Die Arbeit besteht darin, die Konstruktion der SELECT-Liste von der Ausführung zu trennen und sie als `MADDataColumn`s zurückzugeben. Sie behebt zudem die Sqlite3-Lücke bei null Zeilen gratis, sobald Spalten vor Zeilen existieren: die Treiber rufen bereits `addColumn:` vor `addRow:` auf, und die DDL der Tabelle wird mit der ersten Spalte erzeugt (`MADDataTableFast.m:526-543`).

### 4.3 Identität und Adresse

Ein Datenobjekt braucht einen Namen, der Umbenennungen übersteht, und eine Adresse, die Regeneration übersteht:

- **Identität:** das `identifier` einer Speicherzeile, wie bei jeder anderen `Rptq`-Entität, plus ein benutzerseitiger Name. Der Materialisierungs-Tag wird der Identitäts-Hash des Objekts, nicht `fileURL.lastPathComponent.hash` — was für diesen Zweck die dateinamensgestützte Adressierung ausmustert (Gefahr `MAD_FORMAT.md` §5.3; die Anmerkung in `MAD_FUTURE.md` §2.2 „content hash the key“ ist dieselbe Behebung auf der Render-Schicht).
- **Adresse:** das Cache-Verzeichnis hält bereits eine `.maddb` pro Dokument; die natürliche Formalisierung ist eine Tabelle `t<tag>` **pro Datenobjekt** darin (Tags machen sie bereits unterscheidbar), jede mit ihrem eigenen Schema-Plist im Stil von `.mdcache`. Die Datei `.maddb` pro Objekt (die Paarung `t<tag>`/`<tag>.maddb` wörtlich genommen) ist die Alternative; §5.1 sagt, wann sie zählt.

### 4.4 Wo sich der Speicher ändert — und was er bereits erlaubt

Minimale Form, empfohlen:

- `RptqQuery` erhält einen Namen (es ist bereits die Definition; nichts zieht um).
- Der Verweis von `RptqQueryTable` — heute eine Schematabellen-ID innerhalb einer `RptqDatabase` — erhält eine zweite Art: **ein anderes Datenobjekt**. Das ist die einzige Schemaänderung, die Komposition braucht, und sie ist additiv: eine v1-Zeile mit einem Schematabellen-Verweis bedeutet genau das, was sie heute bedeutet.
- Mehrere Quellen brauchen überhaupt keine Speicheränderung: der Speicher unterstützt bereits viele `RptqDatabase`-Zeilen, jede mit eigener Abfrage (ein `MADModelDatabase` pro `RptqQuery`, §3.1). Was heutige Dokumente haben, ist je eines, weil der Erstellungsablauf eines macht; das Schema wurde 2017 zukunftssicher gemacht und wartet noch.

Die schwerere Alternative — eine neue Entität `RptqDataObject`, die die Definition besitzt, mit degradierter `RptqQuery` — ist sauberere Benennung und eine größere Migration. Festgehalten als Entscheidung 9.1.

## 5. Komposition — die Unterbericht-Verdrahtung, dokumentiert, nicht gebaut

**Dieser Abschnitt ist bewusst nicht eingeplant** (der Benutzer, 2026-10-16: *„Ich will es nicht verdrahten … aber ich will diese Idee dokumentieren“*). Er existiert, damit es, wenn es gewünscht wird, ein Plan statt einer Entdeckung ist.

### 5.1 Der Mechanismus, genau

1. Jedes Datenobjekt führt gegen seine eigene Quelle aus — seine eigene `RptqDatabase`, seinen Treiber und seine Zugangsdaten — und materialisiert in seine eigene SQLite-Tabelle (eine `t<tag>` im Cache des Dokuments, nach §4.3).
2. Der Abfragegraph des komponierenden Objekts ist in der Art unverändert: seine „Tabellen“ schließen Datenobjekte ein; Joins, Filter und Aliase gelten alle, weil auf beiden Seiten eine Tabelle eine Menge benannter Spalten ist.
3. Die Ausführung ist topologisch über den Objekt-DAG (derselbe Algorithmus, den `MADQueryFull` bereits auf dem Join-Graphen ausführt, `MADQueryFull.m:202`): Quellen zuerst, komponierendes Objekt zuletzt, sein Ergebnis wie jedes andere materialisiert.
4. Das komponierende Objekt führt **gegen den Cache aus, nicht gegen eine entfernte Datenbank** — es ist eine Abfrage, deren „Datenbank“ die `.maddb` ist. `MADSqlite3` ist bereits ein volles `MADDatabase`, also wird der Treiber für diesen Schritt heute schon ausgeliefert. Eine `.maddb` mit mehreren `t<tag>`-Tabellen braucht überhaupt kein `ATTACH`; `ATTACH DATABASE` ist die Variante für **getrennte Dateien** — eine `.maddb` pro Objekt oder Objekte aus *verschiedenen Dokumenten*, was der Fall ist, in dem die Unterberichtsgrenze eine Dateigrenze ist und `ATTACH` (oder ein Hineinkopieren) der einzige Join-Weg ist.

Die Einzeiler-Version, die der ganze Grund ist, warum dies eine Verdrahtung und kein Projekt ist: **das Ergebnis jeder Abfrage ist bereits eine SQLite-Tabelle, und SQLite ist bereits ein Treiber.** Die Föderations-Engine ist im Kasten; sie wird derzeit über einen Dateinamen-Hash adressiert.

### 5.2 Was gebaut würde, wenn gewünscht

1. Der Vertrag von §4 (describe/execute, Identität, Adresse) — eine Voraussetzung, keine Phase.
2. Die Quellenart: `RptqQueryTable` → Datenobjekt; die SQL-Erzeugung löst es auf die Materialisierungstabelle des Objekts auf statt auf `db.table`.
3. Die Ausführungsreihenfolge: den DAG durchlaufen; veraltete Objekte aktualisieren; dann die komponierende Abfrage.
4. Das Teleskopieren des Designers (das Wort des Benutzers): im Add-Table-Panel eine zweite Art von Quelle neben Schematabellen — die anderen Datenobjekte des Dokuments oder eine Unterberichtsbox, die die Ausgabefelder des anderen Objekts auflistet. Die Join-UI ist unverändert; beide Enden sind Felder.
5. `ATTACH`-Unterstützung in `MADDatabaseSqlite3`, wenn und falls dateiübergreifende Komposition gewünscht wird.

### 5.3 Was es zu keinem Einzeiler macht

Festgehalten, damit die Schätzung ehrlich bleibt: die drei Festverdrahtungspunkte von §3.6 (das erneute Lesen in `MADQueryFull`, das Ein-Slot-`dataTableForQuery:` und die ungeteilte `MADQueryActiveQueryFields`) müssen jeder fallen, bevor eine zweite Abfrage — geschweige denn eine *verschachtelte* — ausführen kann; `MADModelDocument` spiegelt auf dem Änderungspfad nur `firstQuery` (`MADModel_Layer.md` §8); und `RptqQuery -sortDescriptorsForDatabase:` gruppiert gegen den einzigen Cache des Dokuments. Nichts davon ist schwer; alles ist tragend für die aktuelle Ein-Abfrage-App.

## 6. Die CLI, der Webserver und die Engine

Die Frage des Benutzers, 2026-10-16: *„die CLI ist wirklich zum Testen, Verstehen und für künftige Nutzung … sie ist wichtig, aber das Ziel ist, etwas zu haben, das vom Webserver aufgerufen werden kann, und ich weiß nicht, ob die CLI der beste Weg dafür ist.“*

Die ehrliche Antwort, wie die Artefakte stehen:

- **Die CLI ist ein Client der Engine, nicht die Engine.** Ihre sechs Verben — `inspect`, `schema`, `query`, `refresh`, `export`, `write` — sind Beispiel-Aufrufstellen der Aufrufkette in §3: den Container öffnen, den Speicher lesen, SQL erzeugen, in eine Tabelle ausführen, rendern. Was ein Webserver braucht, ist dieselbe Kette hinter einem stabilen Einstiegspunkt; ein Subprozess ist eine Bindung dieser Kette (die Form, die `MAD_LINUX.md` §2 skizziert: `mad --format json` als Subprozess), eine gelinkte Bibliothek eine andere, eine In-Process-Objective-C/Swift-API eine dritte.
- **Der Einstiegspunkt ist das fehlende Stück, und er ist benannt.** Es gibt heute keine UIKit-freie Top-Level-Klasse, die ein `.mad` öffnet, die Abfrage ausführt und Zeilen zurückgibt: auf Apple ist `MADocument` ein `UIDocument`; `MADCLIDocument` der CLI ist headless im *Verhalten*, wartet aber auf die Run-Loop für dieses UIDocument. (Phase D hat die headless Seite geklärt: `MADHeadlessDocument` ist der Einstiegspunkt unter Linux, und seit Phase E trägt es auch die Render-Hälfte — `MADDocumentRenderProtocol`, `MADReportPageBuilder` —, sodass `mad export` dort läuft. `MAD_LINUX.md` §9.) Der Vertrag von §4 ist, was ein solcher Einstiegspunkt offenlegen würde: öffnen → Datenobjekte auflisten → beschreiben → ausführen → (Schema, Zeilen).
- **Das Wire-Format ist eine Entscheidung, nicht drei.** Schema + Zeilen als JSON ist dieselbe Form wie der JSON-Export (`MAD_CLI.md` §8.3, Entscheidungstabelle in `ROADMAP.md`) und die strukturierte Ausgabe, die eine KI-Schicht validiert (`MAD_FUTURE.md` §7). `MADDataColumn` ist bereits eine plist-fähige Spaltenbeschreibung; das `.mdcache`-Plist ist bereits ein serialisiertes Ergebnisschema. Entwerfen Sie die JSON-Form einmal, offen, und Export, API und KI konsumieren sie alle.
- **Wofür die CLI verantwortlich bleibt**, ist die Disziplin, die `ROADMAP.md` Track 3 festlegte: das Dokument sichtbar mit der App aus dem Weg, die Exit-Codes (0–5) als Fehlervokabular, die Round-Trip-Fixtures, die das Format festlegen. Diese ziehen nicht zum Webserver um; sie sind, wie die Engine des Webservers ehrlich bleibt.

Die gemessenen Fakten hinter „das ist billig, sobald der Vertrag existiert“: der Datenpfad ist bereits headless — SQL-Erzeugung, der Speicher, `MADDataTableFast` und alle drei Treiber kompilieren heute unter Linux, mit 124 Testprogrammen und 1.270 grünen Tests (`Linux/README.md`), und seit Phase D baut und läuft die CLI in diesem Image (`inspect`, `schema`, `query`, `refresh`, `export`, `write`). Die sich daraus ergebende Reihenfolge ist also Vertrag zuerst, Einstiegspunkt zweitens, Frontends drittens — und sie macht „CLI oder Webserver?“ zu einer Frage mit einer Zwei-Zeilen-Antwort statt einer architektonischen Gabelung.

## 7. Was es erfordert — in Phasen, auf den bestehenden Spuren

So geordnet, dass die App weiter ausliefert und die Suite durchgehend grün bleibt; jede Phase benennt die Änderung aus §3, die sie ausmustert.

| Phase | Arbeit | Mustert aus |
|---|---|---|
| 1 | **Der Vertrag.** Die Konstruktion der SELECT-Liste von `MADQueryFull` von der Ausführung trennen; sie als `MADDataColumn`s zurückgeben. Die Protokolle describe/execute hinzufügen; `MADOperationRefresh` sie aufrufen lassen. Keine Verhaltensänderung. | Keine reine Schema-API; Sqlite3-Schemaverlust bei null Zeilen |
| 2 | **Die Abfrage besitzt sich selbst.** `MADQueryFull` nimmt die Abfrage, die ihm gegeben wurde (kein erneutes Lesen des Dokuments); `-dataTableForQuery:` löst pro Abfrage auf; `MADQueryActiveQueryFields` beschränkt auf eine Abfrage; `MADModelDocument` spiegelt jede Abfrage. Ein Dokument, viele Objekte. | Alle drei Festverdrahtungspunkte von §3.6 |
| 3 | **Identität und Adresse.** Das Objekt im Speicher benennen; Materialisierungen nach Objektidentität taggen, nicht nach Dateiname; eine Ergebnistabelle pro Objekt im Cache; Schema-Plist pro Objekt. | Dateinamen-gehashte Materialisierung; eine Tabelle pro Dokument |
| 4 | **Die Bindung und die Oberflächen.** Das Layout bindet an das Schema eines Datenobjekts; die CLI erhält `describe`; die JSON-Form wird einmal festgelegt (Export + API + KI). | Bindung an „die Abfrage des Dokuments“ |
| 5 | **Komposition** (§5), nur wenn gefragt. | — |

Phase 1 ist die eigentliche Nutzlast des Designs und die kleinste: sie braucht keine Speicheränderung, keine UI-Änderung und kein neues Format — sie sortiert vorhandenen Code neu und ist beweisbar durch die aktuellen Suiten plus eine Schemaprüfung an einer Abfrage mit null Zeilen. Die Phasen 2–4 sind dieselbe Idee, angewandt auf die Schichten, die die Ein-Abfrage-Annahme tragen. Phase 5 ist die Verdrahtung, dokumentiert, nicht eingeplant.

## 8. Was nicht zu tun ist

- **Die Mehrquellen-Verdrahtung jetzt nicht bauen.** Die Entscheidung des Benutzers, 2026-10-16; dieses Dokument ist die Aufzeichnung, kein Warteschlangeneintrag. (Die Konventionen von `TASKS.md`/`BUGS.md` gelten: nichts hier wird auf Initiative des Agenten begonnen.)
- **Den Cache nicht komprimieren oder umgestalten.** Er ist tragend, das zweistufige Design braucht ihn, und `MAD_FORMAT.md` §5.1 ist die bestehende Analyse.
- **Keine Föderations-Engine bauen.** Gemäß §1 und §5 sind die Materialisierungen die Föderation.
- **Keinen zweiten SQL-Generator oder Executor implementieren.** Alles außer der Adressierung und der Reihenfolge existiert.
- **Die bewusst toten Dinge nicht berühren** (`MADQueryDefinition*`, `RptqQuerySort`, `MADQueryFullTableEnumerator`, die Freitext-Überschreibungsfelder) als Teil hiervon — das sind separate Aufräumentscheidungen.

## 9. Offene Entscheidungen

1. **Die Form des Speichers.** Die bestehende `RptqQuery` benennen (minimal, empfohlen) oder `RptqDataObject` als eigene Entität einführen (sauberer, größere Migration)?
2. **Die Materialisierungseinheit.** Eine `.maddb` pro Dokument mit einer `t<tag>` pro Objekt (empfohlen — kein `ATTACH`, keine neuen Dateien) oder eine Datei pro Objekt (`ATTACH` beim Komponieren)?
3. **Was der Snapshot ist.** `MAD_FUTURE.md` §2.2 macht das Materialisierungspaar (`.maddb` + `.mdcache`) zum teilbaren Artefakt. Ist unter diesem Design die Einheit des Teilens das Ergebnis des Datenobjekts oder das Dokument?
4. **Was das Schema eines Datenobjekts nach außen offenlegt.** `MADDataColumn` ist reich; Name/Typ/Länge ist, was ein Webserver und eine KI brauchen. Die JSON-Form (einmal entschieden, §6) ist, wo das festgelegt wird.
5. **Benennung.** „Datenobjekt“ ist der Begriff des Benutzers und dieses Dokuments; `MAD_FUTURE.md` nennt das Branchenartefakt ein *Modell*. Eines der beiden sollte gewinnen, bevor etwas gebaut wird, weil es in Speicherentitäten, Protokolle und die Verben der CLI einfließt.

## 10. Der rote Faden

Der Abfrage-Arbeitsbereich baut die Funktion bereits; die Refresh-Kette kompiliert und führt sie bereits aus; die Ergebnistabelle *ist* bereits ein Schema und eine Ergebnismenge, auf der Platte als SQLite; die Treiber, die zwei davon joinen würden, existieren bereits und kompilieren bereits unter Linux. Was nichts davon hat, ist ein Name, eine Adresse und eine Beschreibungshälfte — die drei Dinge, die „die Abfrage des Berichts“ in ein Datenobjekt verwandeln und ein Datenobjekt in eine Tabelle, die ein anderes Datenobjekt verwenden kann. Der Rest — Unterberichte, mehrere Quellen, ein Webserver auf der Engine — ist Komposition darüber, und komponiert gerade deshalb, weil nichts Neues erfunden werden muss: es ist die bestehende Pipeline, adressiert durch etwas Besseres als einen Dateinamen-Hash.
