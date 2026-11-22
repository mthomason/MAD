---
layout: default
lang: de-DE
title: "SQL in den Abfragedesigner einfügen"
description: "Die unterstützte SQL-Teilmenge, der Parser und der Apply-Pfad."
---

# MAD SQL-Eingabe — eine SQL-Abfrage in den Abfragedesigner einfügen

Diese Seite hält die SQL-Eingabefunktion fest: die unterstützte `SELECT`-Teilmenge, den Parser und Resolver und den Apply-Pfad, der eine Anweisung zurück in den portablen Abfragegraphen verwandelt. Die Phasen A-D sind implementiert; Phase E ist aufgeschoben.

**Umfang:** ein neuer Parser/Resolver/Compiler in `MAD/Source/sql/`, ein Apply-Pfad auf `MADocument`, das SQL-Popover in `MADDesigner`, der persistierte Quelltext (§8, der den ersten Versionierungsschritt des Speichers hinzufügt) und die Tests, die all das festlegen.
**Datum:** 2026-10-22, gelesen bei `cf0fe3acd`; überarbeitet am 2026-10-22 mit der Persistenzentscheidung (§8).
**Status:** implementiert — die Phasen A–D landeten am 2026-10-22 und wurden als `c48a39fb7` in master gemergt (die interne Aufgabenwarteschlange §16). Phase E (§9) bleibt aufgeschoben; §8.1–§8.2 tragen die Ergänzungen im Ist-Zustand.

---

## 1. Das Ziel

Heute ist der einzige Weg, eine Abfrage zu bauen, der visuelle Designer: Tabellen wählen, Feld für Feld verknüpfen, Filter hinzufügen, Gruppierungen hinzufügen — alles über die tabbed UI. Der Benutzer möchte einen zweiten Einstieg:

> „…ein Benutzer könnte einen Button drücken, und es dreht sich um und zeigt eine mehrzeilige Textansicht, in die er das SQL einfügen kann … wenn dieses SQL gespeichert wird, erzeugt es die Abfrage im Backend des Berichts manuell … es tut alles, was es bereits tun würde, wenn der Benutzer alle Details auswählt … die Software erkennt weiterhin, welche Felder verwendet werden, welche Joins verwendet werden, welche Tabellen verwendet werden, und richtet das Dokument vollständig auf die richtige Weise ein und erlaubt dem Benutzer dann sogar, den Abfragedesigner mit den Feldern zu verwenden, die von der Standardabfrage eingegeben wurden (wenn er möchte).“

Also: das eingefügte SQL wird **in das Abfragemodell des Dokuments** (den `Rptq`-Objektgraphen) kompiliert, durch genau dieselben Fabriken, die der visuelle Designer aufruft. Nach dem Apply sehen der visuelle Abfragedesigner, die Visualisierungsleinwand und der Berichtsdesigner die Abfrage, als wäre sie von Hand gebaut worden — und der Benutzer kann sie dort weiter bearbeiten. Es muss eine Validierungsphase geben.

## 2. Was heute existiert (aus erster Hand gelesen)

### 2.1 Das kanonische Abfragemodell — der `Rptq`-Graph

Die Abfrage des Dokuments lebt im portablen Speicher als einfache `Rptq*`-Objekte (`MAD/Source/rptq/`); die Schicht `MADModel*` ist eine schreibgeschützte Sicht darauf (`MADModel_Layer.md`). Der Importer schreibt `Rptq`-Zeilen und sonst nichts.

* `RptqQuery` (`MAD/Source/rptq/autogen/RptqQuery.h:30-34`): `hasQueryTables`, `hasQueryLinks`, `hasQueryPredicate` (beachten Sie den Singular-Namen), `hasQueryGroups`.
* `RptqQueryTable` — ein Schematabellen-Verweis plus ein Alias; der Alias wird *berechnet*: der Name der Schematabelle für die erste Kopie, Name + Drop-Index danach (`Customer`, `Customer0`, … — `MADModelQueryTable.m:119-129`).
* `RptqQueryField` — zwei IDs: `inQueryTable` + `databaseSchemaField`. Jedes Feld jeder Abfragetabelle erhält eine Zeile (der Add-Table-Ablauf erzeugt eine pro Schemafeld, `MADQueryViewController.m:762-770`).
* `RptqQueryLinks` — ein Join: `hasLeftField`/`hasRightField` (je ein `RptqQueryField`), `type` (`MADLinkType`, `MADQueryLinkType.h`: inner / equi / natural / cross / left / right / full outer). Genau ein Feldpaar pro Link; der Generator gibt immer `ON l = r` aus (`MADQueryFull.m:366-380`).
* `RptqQueryPredicate` — `comparson` (`MADPredicateOperator`: `=`, `<>`, `>`, `>=`, `<`, `<=` — `MADPredicateOperator.h`, `RptqQueryPredicate+Extras.m:245-265`), plus eine linke/rechte Seite, die entweder ein `RptqQueryField` oder ein typisierter Wertestring ist (`leftFieldID`/`rigthFieldID`). Alle Prädikate sind mit AND verknüpft, jedes geschrieben als `(left op right)` (`MADQueryPredicate.m:43-93`). Kein OR, kein LIKE, kein IN, keine Funktionen.
* `RptqQueryGroup` — `hasField`, `sort` (`MADSortOrder`), `weight` und `hasSection`: die Kopf-/Fußabschnitte der Gruppe des Berichts (`RptqQueryGroup.h:24-29`).

Was das Modell **nicht** hält — die Grenzen, die der Importer respektieren muss:

* **Keine SELECT-Liste.** Das SELECT wird zur SQL-Bauzeit daraus abgeleitet, auf welche Abfragefelder Designer-Elemente (Datenbeschriftungen, Aggregate, Barcodes), Links und Gruppen verweisen (`MADQueryActiveQueryFields.m:37-97`, `MADQuerySelectExpressionActiveFields.m`).
* **Kein freies ORDER BY.** Sortierreihenfolge gibt es nur pro Gruppe (`RptqQueryGroup.sort`).
* **Kein OR / IN / LIKE / Funktionen / Unterabfragen / UNION** — keines ist darstellbar.
* **Kein gespeicherter SQL-Text** und keine Speicherversionierung, um eine Spalte hinzuzufügen (unten §8).

### 2.2 SQL-Erzeugung — der Round-Trip-Vertrag

`MADQueryFull` baut das ausgeführte SQL aus dem Modell (`SQLOnlyActiveFields:managedObjectContext:error:`, `MADQueryFull.m:143-273`):

* `SELECT`-Teil vom Treiber, dann die aktiven Felder, nach Spaltenalias sortiert, geschrieben **ohne `AS`**: `"Table0"."Field"` (`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`).
* `FROM` — eine DFS über den Join-Graphen: `tableName <connector> queryAlias`, dann `LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field` pro Link (`MADQueryFull.m:275-426`, Join-Text aus `RptqQueryLinks SqlForLinkType:`, `RptqQueryLinks+Extras.m:76-86`).
* `WHERE` — die mit AND verknüpften Prädikat-Tripel (`MADQueryPredicate.m`).
* Kein `GROUP BY`/`ORDER BY` im SQL — Gruppierung und Sortierung werden über den `.maddb`-Cache angewandt (`MADParameters+QueryCacheAggregate`, `MADQueryCacheSelectGroupKeys`).
* Eine vom Treiber gelieferte `LIMIT`-Klausel.

Der Vertrag des Importers lautet daher: **eine eingefügte Anweisung ist genau dann akzeptabel, wenn sie die Ausgabe von `MADQueryFull` für irgendein Modell sein könnte.** Das ist es, was den Round Trip ehrlich macht — die View-Seite des SQL-Popovers zeigt das aus dem importierten Modell neu erzeugte SQL, und es liest sich wie das, was der Benutzer eingefügt hat.

### 2.3 Die Refresh-Pipeline — das Muster, das die Validierung wiederverwendet

`MADOperationRefresh.m:60-172`: mit Zugangsdaten verbinden, die von Operationsabhängigkeiten geliefert werden, das SQL **auf der Hauptwarteschlange** bauen (der Speicherkontext gehört der Hauptwarteschlange — BUGS.md), dann `[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]` (`MADDatabaseProtocol.h:33`) und `dataTableMakeCache`. Eine Validierungsprobe ist dieselbe Operationsform minus den Cache-Aufbau.

### 2.4 Das Backend, das die UI bereits aufruft — die Naht, die der Compiler wiederverwendet

`Rptq`-Zeilen zu schreiben und zu speichern genügt; die Schicht `MADModel*` spiegelt die Änderung über Speicherbenachrichtigungen in die UI (`MADModel_Layer.md` §3.3). Die Fabriken, die aufzurufen sind, wörtlich aus dem heutigen UI-Code:

* **Tabelle hinzufügen** — `[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`, dann ein `[RptqQueryField newQueryField:context]` pro Schemafeld, verdrahtet mit der Tabelle, Tabelle zu `query.hasQueryTables` hinzugefügt, speichern (`MADQueryViewController.m:744-799`).
* **Link hinzufügen** — `[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`, dann `[document.activeDocumentModel addQueryLink:link]`, speichern (`MADQueryLinkBuilderController.m:112-122`).
* **Prädikat hinzufügen** — `[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` / die Varianten `…WithLeftValue:…` (`MADQueryAddPredicateController.m:142-162`, `RptqQueryPredicate+Extras.h:20-39`).
* **Gruppe hinzufügen** — `[document addQueryGroupWithQueryField:andSortOrder:]` (`MADocument.m:728-792`). Dieser eine Aufruf erzeugt die Gruppenzeile *und* die Kopf-/Fußabschnitte der Gruppe des Berichts *und* deren Abschnitts-Layout-Manager — „richtet das Dokument vollständig ein“ für ein `GROUP BY`, gratis.
* **Löschung für den Ersetzungspfad** — `removeGroupWitObjectID:fromManagedObjectContext:` (`MADocument.m:1130`), `deleteDatafieldsRelatedToTable:inContent:` und `deleteAggregateFieldRelatedToTable:inContent:` (`MADocument.h:91-95`) sowie die vorhandenen Entfernungspfade für Links/Prädikate in der Abfrage-UI. Phase B inventarisiert diese; jeder fehlende symmetrische Helfer für Links/Prädikate wird dort hinzugefügt.

### 2.5 Die UI-Naht

Der Split-View-Controller des Abfrage-Builders hat bereits ein Toolbar-Element `barButtonItemSQL`, das ein **schreibgeschütztes** Popover `MADViewControllerSQL` präsentiert (`MADQueryBuilderSplitViewController.m:31, 106-111`; `MADQuery.storyboard`; `MADViewControllerSQL.m:27-56` zeigt `[doc.mainQuery SQLOnlyActiveFields:…]`). Die Funktion ist ein Modus desselben Bildschirms, also existieren der Button, das Popover und die Navigation bereits.

## 3. Die Funktion, wie der Benutzer sie sieht

1. Im Abfrage-Arbeitsbereich tippen Sie auf den vorhandenen SQL-Button. Das Popover hat jetzt die Modi **View / Edit**.
2. **View** zeigt beide Darstellungen des SQL der Abfrage als segmentiertes Steuerelement:
   * **Generated** — das SQL, das `MADQueryFull` gerade jetzt aus dem Modell baut (der heutige Popover-Inhalt, als Standard-Tab beibehalten).
   * **As entered** — die letzte angewandte Anweisung des Benutzers, wörtlich (`RptqQuery.sqlSourceText`, §8); verborgen oder leer, wenn die Abfrage noch nie aus eingefügtem SQL gebaut wurde.
   Beide Tabs sind schreibgeschützt — der Bildschirm „sieh, was du eingefügt hast, und sieh, was daraus wurde“.
3. **Edit** — eine mehrzeilige Textansicht in Festbreitenschrift, gespeist aus `sqlSourceText`, wenn vorhanden (der Benutzer bearbeitet *seinen* Text erneut, Formatierung und Kommentare intakt), sonst aus dem erzeugten SQL; ein Button **Revert to generated** speist erneut aus der erzeugten Form.
4. **Validate** — strukturelle Prüfung plus, wenn die Datenbank des Dokuments erreichbar ist, eine Serverprobe mit null Zeilen (§7). Fehler kommen mit Zeile und Spalte zurück.
5. **Apply** — die Anweisung wird in das Dokument kompiliert (atomar — §6.5) und der exakt eingefügte Text wird als `sqlSourceText` persistiert (§8). Das Popover schließt sich; die Liste der Abfragetabellen, die Visualisierungsleinwand und der Berichtsdesigner zeigen alle die importierte Struktur. Die Feldwähler des Designers funktionieren wie gewohnt.
6. Ein fehlgeschlagenes oder konfliktbehaftetes Apply persistiert nichts — weder den Text noch irgendwelche Zeilen. Die vorherige Abfrage und ihr vorheriger eingegebener Text bleiben genau, wie sie waren.
7. Der Benutzer kann jederzeit zurückwechseln: der visuelle Designer arbeitet weiter an der importierten Abfrage, View zeigt beide Formen, und Edit öffnet erneut seine eigenen Worte.

## 4. Architektur

```
pasted SQL
  → MADSQLTokenizer        dialect-aware lexer; quotes per driver; tracks line:column
  → MADSQLParser           recursive descent; produces a MADSQLStatement parse tree
  → MADSQLStatementResolver  binds names to RptqDatabaseSchemaTable / RptqDatabaseSchemaField
  → [MADOperationValidateSQL]  server probe, when connected (§7); never writes
  → MADSQLQueryCompiler    the write plan: deletes + creates Rptq rows via the §2.4 factories
  → store save → model notifications → query UI / visualization / designer update
```

**Platzierung.** Alles außer der Probeoperation und der Editor-UI lebt im Framework `MAD`, reines Foundation, kein UIKit — also läuft es in der Testsuite von `MAD` und im Linux-Image. Die neuen Dateien kommen auf `Linux/cmake/MADSources.cmake`, und `./Linux/build.sh` bleibt grün. Die Probeoperation (braucht Treiber, Zugangsdaten, UIKit-Alerts) und die Popover-UI leben in `MADDesigner/Source`.

**Neue Dateien.** `MAD/Source/sql/MADSQLTokenizer.{h,m}`, `MADSQLParser.{h,m}`, `MADSQLStatement.{h,m}` (der Baum und seine Werttypen: `MADSQLColumnReference`, `MADSQLPredicateTerm`, …), `MADSQLStatementResolver.{h,m}`, `MADSQLQueryCompiler.{h,m}`, `MADSQLCompileError.{h,m}`. App: `MADOperationValidateSQL.{h,m}` (spiegelt `MADOperationRefresh`) plus die Editor-Änderungen in `MADViewControllerSQL` oder einem benachbarten Editor-Controller in derselben Storyboard-Naht.

**Eine kleine API-Ergänzung.** Der Lexer braucht das Identifikator-Quoting jedes Dialekts (MySQL-Backticks, T-SQL-Klammern, doppelte Anführungszeichen), bevor eine Verbindung existiert. Fügen Sie `+ (NSString *)identifierQuoteCharacters` zu `MADDatabase` hinzu (Standard: doppeltes Anführungszeichen), mit Überschreibungen pro Treiber in `MADMySQL`/`MADTdsClient` (`MADPostgres` nutzt das Standard-Doppelanführungszeichen) — oder, falls bevorzugt, eine Klassenmethode am Treiberprotokoll, aufgelöst über `MADDatabaseDriverRegistry`. So oder so ist es eine Ergänzung von drei Methoden.

## 5. Die unterstützte Teilmenge

Der Importer akzeptiert **genau die Sprache, die das Modell halten kann** — ein `SELECT`, nirgendwo Unterabfragen und jede Klausel innerhalb der Grenzen von §2.1:

* **SELECT-Liste** — nur Spaltenverweise: `col`, `tbl.col`, `schema.tbl.col`, `alias.col`, quotiert oder nackt, plus `alias.*` / `schema.tbl.*`. Die Liste wird *validiert und für die Tabellen-/Spaltenentdeckung verwendet*, nicht gespeichert (das Modell hat keine SELECT-Liste — §2.1): jede Spalte muss auflösen, und eine qualifizierte Spalte benennt eine Tabelle, die in `FROM` erscheinen muss. Ausdrücke, Aggregate, Aliase (`AS x`) und `DISTINCT` werden mit einem Hinweis auf Phase E (§9) abgelehnt, die Phase, die die eingefügte Spaltenliste real macht, indem sie Designer-Elemente synthetisiert. Der eingegebene Text selbst *wird* wörtlich in `sqlSourceText` gespeichert (§8) — Validierungsform und Eingabetext sind getrennte Dinge.
* **FROM** — ein Tabellenverweis `[schema.]name [AS alias]`, dann eine Kette/Baum von `[INNER] JOIN`, `LEFT [OUTER] JOIN`, `RIGHT [OUTER] JOIN`, `FULL [OUTER] JOIN`, jeweils mit genau einer Equi-Bedingung `l.col = r.col` (nackte, zweiteilige oder dreiteilige Spalten `schema.tbl.col`; nackt erlaubt, wenn eindeutig).
  * Aliase müssen der eigene Name der Schematabelle sein (oder ihre punktbereinigte Form), oder die Drop-Index-Form (`name0`, `name1`, `schema.name0` oder das punktbereinigte `schemaname0`, das zu `RptqQueryTable -queryAlias` passt) für eine zweite Kopie derselben Tabelle — das Modell berechnet Aliase selbst und kann Umbenennungen nicht halten (`Customer AS c` wird abgelehnt: „the designer names tables itself“).
  * Höchstens ein Join zwischen einem gegebenen Tabellenpaar (der Generator gibt ein `JOIN` pro Tabellenpaar aus; zwei Links zwischen demselben Paar würden den Alias verdoppeln).
  * Keine Komma-Joins, keine `NATURAL`/`CROSS`-Joins (das Link-Modell hält genau ein Feldpaar, und der Generator schreibt immer `ON …`), keine Unterabfragen in `FROM`/`ON`.
* **WHERE** — eine Konjunktion (AND) von Vergleichen `left op right`, `op` ∈ `{ =, <>, >, >=, <, <= }` (die Menge `MADPredicateOperator`), jede Seite ein Spaltenverweis oder ein Literal. Klammern werden nur akzeptiert, wo sie die flache AND-Form nicht ändern. Alles andere — `OR`, `IN`, `BETWEEN`, `LIKE`, `NOT`, Funktionen, Unterabfragen — wird abgelehnt: das Prädikatmodell verknüpft flache Tripel mit AND und nichts anderes.
* **GROUP BY** — Spaltenverweise, in Reihenfolge importiert (weight), jeweils eine Gruppe werdend über den Helfer von `MADocument`, der auch die Gruppenabschnitte des Berichts erzeugt.
* **ORDER BY** — akzeptiert **nur, wenn jede Spalte eine GROUP-BY-Spalte ist**, und asc/desc bilden auf die Sortierreihenfolgen der Gruppen ab. Andernfalls abgelehnt (keine freie Sortierung im Modell).
* **LIMIT** — abgelehnt: die App wendet ihr eigenes Limit für den Designer-/Reporting-Modus an (`MADDocument.limitResultsDesignMode`, `MADQueryFull.limitResults`).

Literale werden pro Dialekt zur Erzeugungszeit behandelt (`newSafeLiteral:`, `MADDatabaseSQLProtocol.h`); der Importer zeichnet nur den Wertestring und den Datentyp des Felds auf, genau wie es die Prädikat-UI tut (`MADQueryPredicate.m:74-88`).

Ablehnungen sind nie still: jede benennt das Konstrukt, die Klausel, den Grund (welche Modellbeschränkung sie trifft) und die Zeile:Spalte.

## 6. Auflösung und Kompilierung

### 6.1 Resolver

* Alias (oder nackter Tabellenname) → `RptqDatabaseSchemaTable` nach Namen, ohne Rücksicht auf Groß-/Kleinschreibung. Unbekannt → Fehler „unknown table“.
* Spalte → `RptqDatabaseSchemaField`: qualifiziert muss auf ihrer Tabelle existieren; nackt muss sie über die `FROM`-Menge eindeutig sein, sonst „ambiguous column“.

### 6.2 Der Schreibplan

Die Ausgabe des Resolvers ist ein Plan aus Werten: geordnete Tabellenliste, Join-Liste (`MADLinkType` pro Join), Prädikatliste (`MADPredicateOperator` + linke/rechte Terme), Gruppenliste mit Sortierreihenfolgen. Der Plan wird als Ganzes validiert, bevor etwas geschrieben wird.

### 6.3 Konfliktprüfung — das Apply ist atomar

Apply **ersetzt** die Abfrage (das eingefügte SQL *ist* die Abfrage — das ist die Funktion). Prüfen Sie vor dem Schreiben für jede Tabelle, die der neue Plan **nicht** enthält, auf Verweise aus Designer-Elementen — die drei Formen, die `MADQueryActiveQueryFields` kennt (`MADQueryActiveQueryFields.m:37-68`: Verweise aus Label-Daten, Aggregat, Barcode), plus alle Gruppenabschnitte, die gelöscht würden. Wenn auf ein Feld einer verworfenen Tabelle verwiesen wird, brechen Sie mit einem Fehler ab, der die Elemente benennt („this field is used by … in the designer“); nichts wird gelöscht, nichts wird geschrieben, und die alte Abfrage läuft weiter. Das ist der eine Fall, in dem der Import nicht atomar-und-still sein kann, also scheitert er laut.

### 6.4 Schreiben

In umgekehrter Abhängigkeitsreihenfolge mit den Helfern aus §2.4: Links und Prädikate entfernen, Gruppen entfernen (über den vorhandenen Gruppenentfernungspfad, der ihre Abschnitte und Layout-Manager abtrennt), Tabellen entfernen, die nicht im Plan sind (über die vorhandene Familie `deleteDatafieldsRelatedToTable:`), dann Tabellen → Links → Prädikate → Gruppen über dieselben Fabriken erzeugen, die die UI aufruft. Ein Speichern; der Aufrufer markiert dann das Dokument als geändert und speichert automatisch, wie es der Add-Table-Ablauf tut (`MADQueryViewController.m:796-799`).

### 6.5 Nach dem Schreiben

Kein UI-Gestochere: der Benachrichtigungspfad des Speichers aktualisiert die Modellschicht und beide Abfragebildschirme (`MADModel_Layer.md` §3.3). Der Compiler gibt eine Zusammenfassung zurück (Anzahl Tabellen / Links / Prädikate / Gruppen) für das Popover.

## 7. Validierung — zwei Ebenen

**Strukturell (immer, offline).** Parsen + auflösen, §5–§6. Fehler sind `NSError`s der Domäne `MADSQLCompileError` mit Code, Zeile, Spalte und Meldung. Das ist die ganze Funktion, wenn die Datenbank des Dokuments nicht erreichbar ist.

**Serverprobe (wenn eine Verbindung hergestellt werden kann).** Umschließen Sie die Anweisung:

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```

Der abgeleitete Tabellenalias ist in MySQL Pflicht und in T-SQL gültig; `WHERE 1=0` faltet, also kompiliert die Probe die Abfrage und gibt Spaltenmetadaten zurück, ohne Zeilen zu lesen. Führen Sie sie in der Form von `MADOperationRefresh` aus (`MADOperationRefresh.m:104-162`): mit Zugangsdaten aus Operationsabhängigkeiten verbinden, Speicherlesevorgänge auf die Hauptwarteschlange marshalisiert, Ergebnisse über `executeSQL:…intoResultTable:…` des Treibers, sodass `MADDataColumn` Namen und Typen liefert. Die Probe fängt dann, was statisches Parsen nicht kann — serverseitige Namensauflösung (Groß-/Kleinschreibung, Views, reservierte Wörter), Dialektunterschiede und die eigenen Syntaxfehler des Servers, die mit der Meldung des Servers offengelegt werden. Spaltennamen/-typen werden gegen die aufgelösten Schemafelder verglichen, und Abweichungen werden als Warnungen gemeldet, nicht als Fehler.

Offline, oder wenn Zugangsdaten nicht verfügbar sind, wird die Probe übersprungen, und die UI sagt „validated by structure only“.

## 8. Der persistierte Quelltext — `RptqQuery.sqlSourceText`

Das kompilierte Modell bleibt die Quelle der Wahrheit für die Ausführung, aber **der eingefügte Text des Benutzers ist Teil des Dokuments**: ein neues nullable Textattribut `sqlSourceText` auf `RptqQuery` hält die letzte erfolgreich angewandte Anweisung, wörtlich. Die Worte des Benutzers zu löschen war nie eine Option — das Dokument behält sowohl die Eingabe als auch ihre Kompilierung. Der Benutzer wählte eine einzelne Eigenschaft statt eines Verlaufsarrays (2026-10-22); eine Revisionsgeschichte kann später als geordnete To-many hinzugefügt und aus dem aktuellen Text ohne Datenverlust rückgefüllt werden.

Persistenzregeln:

* Wird nur durch ein erfolgreiches Apply geschrieben, vollständig ersetzt; ein fehlgeschlagenes oder konfliktbehaftetes Apply berührt weder die Speicherzeilen noch diesen Text (§3.6).
* Die Edit-Ansicht speist sich daraus, wenn vorhanden; der View-Tab zeigt es als **As entered** neben **Generated** (§3.2-3.3).

### 8.1 Die Speicheränderung

Das Attribut landet auf beiden Seiten der Schema-Kreuzprüfung: im kompilierten Modell und in den handgepflegten Deskriptoren von `MADStoreSchema`, plus der Autogen-Eigenschaft von `RptqQuery` (`MAD/Source/rptq/autogen/`). `MAD_FORMAT.md` erhält die Spalte in seiner Feldliste.

**Ergänzt (Phase A, 2026-10-22).** Die Modelländerung ist eine **neue Version `MAD 4.xcdatamodel`**, keine Bearbeitung von `MAD 3` an Ort und Stelle: der Hash einer ausgelieferten Modellversion legt die Speichermetadaten jedes Dokuments in freier Wildbahn fest, und sie zu bearbeiten verwaist sie. `MAD 4` entfernt zudem das tote `elementID="type"` von `RptqDocumentElementBarcode.barcodeBorderType` (keine Version vor `MAD 3` hat eine Barcode-Entität; BUGS.md).

### 8.2 Speicherversionierung — neu, klein und jetzt erforderlich

Der portable Speicher hat heute keine Versionierung (`MADStore.m` trägt kein `user_version`-Pragma). Diese Phase fügt den Mechanismus hinzu, bewusst minimal:

* `MADStoreSchema` erhält eine Versionskonstante und eine geordnete Liste von Migrationsschritten. Heute hat diese Liste einen Eintrag: Version 1 (das Schema in freier Wildbahn — `user_version` fehlt oder ist 0) → Version 2 (`ALTER TABLE` fügt `sqlSourceText` hinzu).
* Beim Öffnen liest `MADStore` `PRAGMA user_version`, wendet die fehlenden Schritte in einer Transaktion an und schreibt die neue Version. Frische Speicher werden in der aktuellen Version erzeugt (`createSchemaSQL` erzeugt bereits das ganze Schema).
* `MADLegacyStoreConversion` ist im Ablauf nicht betroffen — konvertierte Core-Data-Dokumente werden in der aktuellen Version über denselben Öffnungspfad von `MADStore` erzeugt.
* Die headless Linux-Engine kompiliert denselben Code von `MADStore`, also öffnen sich bestehende Dokumente im Image identisch; die Migrationstests laufen auch dort.

**Ergänzt (Phase A, 2026-10-22).** `MADStoreConverter` öffnet jeden Legacy-Speicher jetzt mit der momd-Version, die zu seinen Metadaten passt, nie über automatische Migration: Core Data kann für diese Modellfamilie keine Zuordnung ableiten (der Barcode-`elementID`-Konflikt, BUGS.md), und das momd-aktuelle Modell ist nicht mehr die Version, gegen die Speicher in freier Wildbahn geschrieben wurden.

### 8.3 Erwogen und verworfen: das Metadaten-Plist der Innereien

Das Metadaten-Plist, das neben dem Speicher im Verzeichnis der Innereien reist, könnte den Text ohne jede Schemaänderung halten. Verworfen: Abfragedaten gehören zum Abfrageteil des Speichers (`MADStorePartQuery` — der Vertrag des Speichers ist „drei Teile und nichts anderes“, `MADStoreSchema.h:12-13`), und die headless Engine liest den Speicher, nicht das Plist.

### 8.4 Die Zukunft, die dies ermöglicht

Der gespeicherte eingegebene Text ist die natürliche Eingabeoberfläche für das agentengesteuerte Abfragedesign am Horizont des Produkts (`MAD_FUTURE.md`): ein Agent — oder ein Mensch — schreibt eine Anweisung, der Compiler unten macht daraus das Dokument, und `sqlSourceText` bewahrt den Prompt der Aufzeichnung. Die strikte Architektur des kompilierten Modells macht diesen Schritt schrittweise: nichts am Compiler ändert sich, wenn der Schreibende ein Agent wird.

## 9. Phasen

**Phase A — der persistierte Quelltext: Speicherversionierung (nur MAD; Linux grün).**
1. `sqlSourceText` auf `RptqQuery`: kompiliertes Modell + Deskriptoren von `MADStoreSchema` + Autogen-Eigenschaft, in einer Änderung (sonst scheitert der Kreuzprüfungstest).
2. Der Versionierungsmechanismus von §8.2 — Versionskonstante, Migrationsliste, Lesen/Anwenden/Schreiben von `user_version` beim Öffnen, frische Speicher in der aktuellen Version.
3. Tests: `MADStoreSchemaTests` bleibt auf beiden Seiten grün; neue Migrationstests (§10.2); `MAD_FORMAT.md` aktualisiert.

Abnahme: ein vor dieser Phase erzeugtes Dokument öffnet sich sauber, erhält die Spalte, behält seine Daten und macht einen Round Trip durch Linux; ein frisches Dokument wird in der aktuellen Version geboren. Diese Phase ist in sich geschlossen — sie landet vor dem Parser und unabhängig von ihm.

**Phase B — Golden-Tests, dann der Parser (nur MAD; Linux grün).**
4. Golden-SQL-Tests, die die exakte Ausgabe von `MADQueryFull` pro Dialekt festlegen (§10.1) — zuerst geschrieben, damit der Parser gegen den echten Generator gebaut wird.
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + die API für Identifikator-Quoting (§4).
6. `MADSQLParserTests` — die Akzeptieren/Ablehnen-Matrix von §5, Fehlercodes, Zeile:Spalte.

Abnahme: jedes unterstützte Konstrukt, das `MADQueryFull` ausgeben kann, parst; jedes abgelehnte Konstrukt scheitert mit einem codierten, positionierten Fehler; MAD-Suite und `./Linux/build.sh` grün.

**Phase C — Resolver + Compiler (nur MAD; Linux grün).**
7. `MADSQLStatementResolver`, `MADSQLQueryCompiler` mit atomarem Apply (§6) und dem Schreiben von `sqlSourceText` bei Erfolg (§8).
8. Inventar der Löschhelfer; die fehlenden Helfer zum Entfernen von Links/Prädikaten hinzufügen.
9. `MADSQLQueryCompilerTests` + der Fixpunkt-Round-Trip-Test (§10.4).

Abnahme: das Anwenden einer Anweisung erzeugt genau die Rptq-Zeilen, die der visuelle Designer erzeugt hätte, und speichert den Text wörtlich; das Anwenden über eine bestehende Abfrage hinterlässt keine Waisen; der Konfliktfall bricht ab, wobei der Speicher — und der vorherige Text — unberührt bleibt; der Fixpunkt-Test besteht.

**Phase D — die App (MADDesigner).**
10. Das View/Edit-Popover von §3, die Probe `MADOperationValidateSQL`, die Zusammenfassungsansicht.
11. UI-Tests (§10.6) mit einem Beispieldokument (Sqlite3-Treiber — kein Server nötig).

Abnahme: Einfügen → validieren → anwenden zeigt die Tabellen/Joins/Prädikate im Abfragedesigner und in der Visualisierung, Gruppenabschnitte im Berichtsdesigner, und Refresh führt die Abfrage aus; View zeigt sowohl das erzeugte SQL als auch den eingegebenen Text; das Schließen und erneute Öffnen des Dokuments behält den eingegebenen Text.

**Phase E — aufgeschoben, eigene Entscheidungen.**
* Materialisierung der SELECT-Liste: Designer-Elemente (Datenbeschriftungen, Aggregate) synthetisieren, sodass Refresh genau die eingefügten Spalten zurückgibt. Bis dahin verhält sich eine importierte Abfrage wie jedes neue Dokument — das SELECT leitet sich aus Elementen, Links und Gruppen ab (§2.1).
* Eine Geschichte angewandter Anweisungen, falls jemals gewünscht: eine geordnete To-many, rückgefüllt aus dem aktuellen `sqlSourceText` (§8) — der natürliche Begleiter des agentengesteuerten Abfragedesigns von §8.4.

## 10. Tests

### 10.1 Bestehende Funktionalität festlegen (zuerst geschrieben)

* **Golden-SQL-Tests** in `MAD/MADTests` (erweitert `MADQueryFullTests.m`, das heute nur Fragmente prüft, `MADQueryFullTests.m:140-162`): feste Speicher-Fixtures → exakte erwartete SQL-Strings, pro Treiberdialekt (MySQL-, TDS- und PostgreSQL-Konfigurationen), die die Aliasbenennung und die Drop-Index-Form, jeden Join-Typ, jeden Prädikatoperator mit Literal-Quoting und die Reihenfolge der aktiven Felder abdecken. Diese legen den Generator fest, den der Parser rückführen muss, und laufen auch im Linux-Image.
* **Der Round-Trip-Vertrag** — siehe den Fixpunkt-Test unten; er legt Generator ∪ Importer als ein System fest.

### 10.2 Tests für Speicherpersistenz und Migration

* `MADStoreSchemaTests` — die bestehende Kreuzprüfung behauptet jetzt, dass die Deskriptoren und das kompilierte Modell bei `sqlSourceText` übereinstimmen (es ist der Test, der erzwingt, dass beide Seiten von §8.1 zusammen landen).
* Neue `MADStoreMigrationTests` (MAD): einen On-Disk-Speicher in Version 1 bauen (das Schema, wie es heute ist, `user_version` fehlt) mit Zeilen darin → mit dem neuen `MADStore` öffnen → die Spalte existiert, `user_version` liest die aktuelle Version, und jede vorher bestehende Zeile und Beziehung überlebt; ein frischer Speicher wird in der aktuellen Version erzeugt; zweimaliges Öffnen ist idempotent. Diese laufen auch im Linux-Image, da die headless Engine denselben Migrationscode teilt.
* Zusicherungen auf Compiler-Ebene (in §10.4): ein erfolgreiches Apply speichert den Text **wörtlich** — Kommentare, Whitespace, Groß-/Kleinschreibung — und ein konfliktbehaftetes Apply lässt den vorherigen Text unberührt.

### 10.3 Parser-Tests — `MADSQLParserTests` (MAD)

* Lexer: quotierte Identifikatoren pro Dialekt, String-Literale mit maskierten Anführungszeichen, Kommentare (`--`, `/* */`), Zahlen, Operatoren, Schlüsselwörter ohne Rücksicht auf Groß-/Kleinschreibung; Positionen bei Fehlern.
* Parser: die vollständige Akzeptanzmatrix von §5 (eine Tabelle, jeder Join-Typ, Join-Ketten, Aliase einschließlich Drop-Index, nackte und qualifizierte Spalten, WHERE-Konjunktionen, GROUP BY, ORDER BY ⊆ GROUP BY) und die Ablehnungstabelle (OR, IN, LIKE, Unterabfrage, UNION, DISTINCT, Ausdrücke in SELECT, mehrbedingtes ON, Alias-Umbenennungen, Komma-Joins, NATURAL/CROSS, LIMIT, unbekannte Tabelle/Spalte, mehrdeutige Spalte, ORDER BY außerhalb von GROUP BY) — jeweils mit Zusicherung des Fehler**codes** und Zeile:Spalte, nie nur der Meldung.

### 10.4 Compiler-Tests — `MADSQLQueryCompilerTests` (MAD)

In-Memory-Speicher mit einem Schema-Fixture (das Muster, das `MADModelQueryTableTests` verwendet):

* Happy Path: Apply → die resultierenden Rptq-Zeilen prüfen — Tabellen mit korrekten Schema-Verweisen und Zeilen pro Feld, Links mit korrektem `MADLinkType` und linken/rechten Feldern, Prädikate mit korrektem `comparson` und Wertestrings, Gruppen mit Sortierung/Weight **und** den erzeugten Kopf-/Fußabschnitten der Gruppe und Layout-Managern; einmal gespeichert; `sqlSourceText` entspricht exakt der Eingabeanweisung (Kommentare und Whitespace eingeschlossen).
* Ersetzungspfad: Apply über eine befüllte Abfrage → alte Tabellen/Links/Prädikate/Gruppen weg, keine Waisenzeilen (Zählung pro Entität), neue Struktur vorhanden, und `sqlSourceText` ersetzt.
* Konfliktpfad: ein Designer-Element verweist auf das Feld einer verworfenen Tabelle → Fehler, und ein Vorher/Nachher-Snapshot zeigt den Speicher unverändert — einschließlich des vorherigen `sqlSourceText`.
* **Fixpunkt-Round-Trip**: ein Modell über die Fabriken bauen → SQL über `MADQueryFull` erzeugen → parsen → in einen frischen Speicher kompilieren → erneut SQL erzeugen → die beiden SQL-Strings sind gleich. Das ist der Test, der *definiert*, dass „die Software erkennt, was eingefügt wurde“.

### 10.5 Validierungstests

* Konstruktion der Probe-SQL pro Treiber (Unit, im Testtarget der App): der Wrapper, der Alias, die Faltung von `WHERE 1=0` — mit einer gefälschten Datenbank, ohne Server.
* **Live-Tests** im Stil von `MADMySQLLiveTests.m` (überspringen, wenn kein Server): gültiges eingefügtes SQL probt sauber mit den erwarteten Spaltennamen/-typen; eine schlechte Spalte gibt den Fehler des Servers zurück; null Zeilen werden gelesen.

### 10.6 UI-Tests — `MADDesignerUITests`

Mit einem Beispiel-`.mad` (Sqlite3-Treiber): das SQL-Popover öffnen, zu Edit wechseln, einen Zwei-Tabellen-Join mit Filter und Gruppe einfügen, Apply, dann prüfen, dass die Liste der Abfragetabellen beide Tabellen zeigt, die Visualisierungsleinwand zwei Kästen und einen Verbinder zeigt, der Designer die Gruppenabschnitte zeigt und der View-Modus das neu erzeugte SQL zeigt. Dann das Dokument schließen und erneut öffnen: der Tab **As entered** zeigt weiterhin den exakt eingefügten Text, und der Tab **Generated** zeigt weiterhin das SQL der kompilierten Abfrage — das Dokument behielt beides.

### 10.7 Testbarkeitsvorgaben (verbindlich für Implementierende)

* Parser/Resolver/Compiler: reines Foundation, kein UIKit, keine App-Importe — die MAD-Suiten und das Linux-Image kompilieren sie.
* Jeder öffentliche Fehler ist ein codierter `NSError` (`MADSQLCompileError`); Tests prüfen Codes.
* Die Probe liegt hinter einem kleinen Protokoll, sodass Unit-Tests die Datenbank fälschen; Live-Abdeckung lebt nur in den Live-Suiten (das bestehende Muster).
* Der Compiler nimmt das Dokument/den Kontext, nie einen View-Controller; die App übergibt nichts UI-Förmiges.
* Neue MAD-Dateien werden zu `Linux/cmake/MADSources.cmake` hinzugefügt; `./Linux/build.sh` bleibt grün.
* Der Migrationsmechanismus lebt im geteilten Code von `MADStore` mit einer Versionskonstante, auf die Tests verweisen können — nie in Apple-only-Pfaden —, sodass die Linux-Suiten ihn ausüben.

## 11. Entscheidungen — mit dem Benutzer geklärt (2026-10-22)

1. **Strikte Teilmenge.** Bestätigt: alles, was das Modell nicht halten kann, wird mit Grund abgelehnt (§5). Kein Opak-SQL-Fallback.
2. **Apply ersetzt die Abfrage** (atomar, §6.3). Bestätigt.
3. **Der GROUP-BY-Import erzeugt die Gruppenabschnitte des Berichts** automatisch — der vorhandene Helfer von `MADocument` tut dies, und er bleibt genau, wie er ist. Bestätigt.
4. **Die SELECT-Liste wird validiert, nicht gespeichert, bis Phase E** — bis eine Elementsynthese existiert, gibt eine importierte Abfrage bei Refresh die Join-/Gruppenspalten zurück, bis der Benutzer Elemente hinzufügt, genau wie jedes neue Dokument. Als phasenweise bestätigt.
5. **Der eingefügte Text wird persistiert.** Bestätigt — `sqlSourceText` auf `RptqQuery`, eine einzelne Eigenschaft, die die letzte erfolgreich angewandte Anweisung hält (§8), als **As entered** neben **Generated** gezeigt. Die erzeugte Form bleibt, was Refresh ausführt; nichts daran, dass der Text gespeichert wird, ändert die Ausführung. Ein Verlaufsarray wurde erwogen und beiseitegelegt (§8, Phase E).
