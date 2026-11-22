---
layout: default
lang: de-DE
title: "Die MADModel-Schicht"
description: "Das Dokument-Read-Modell über den Rptq-Entitäten und wie es aktuell gehalten wird."
---

# MADModel — die Read-Modell-Schicht des Dokuments

Diese Seite beschreibt `MADModel`, das Read-Modell über den `Rptq`-Entitäten: was jede Klasse ist, wie sie befüllt und aktuell gehalten wird und wer sie liest.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

**Umfang:** `MAD/Source/model/MADModel*.{h,m}`, `MAD/Source/model/MADTableFieldIdentifier.{h,m}` und jeder Konsument der Schicht in `MAD` und `MAD Designer`.
**Datum:** 2026-10-16, gelesen bei `d7faff320`.
**Status:** Referenz. Alles hier wurde aus erster Hand bei diesem Commit gelesen; die Refactoring-Kandidaten in §7 sind Vorschläge und nicht angewandt.

---

## 1. Was die Schicht ist

`MADModel*` ist eine **dokumentbezogene, schreibgeschützte Sicht auf die Definition des Dokuments** — die Verbindung, das Schema (Tabellen und Felder) und den Abfragegraphen (welche Tabellen die Abfrage verwendet, welche Felder und die Joins zwischen ihnen). Es ist das, an das die Abfrage-UI des Designers bindet.

Es ist *nicht* das kanonische Modell. Das kanonische Modell ist der `Rptq*`-Objektgraph im portablen Speicher: er ist das, was die App bearbeitet, speichert, konvertiert und rendert. Ein `MADModel*`-Objekt ist kaum mehr als **eine Speicherzeilen-Kennung (`int64_t`) plus ein schwacher Zeiger auf den `RptqStoreContext` plus ein paar kopierte Anzeigewerte**, träge aufgelöst durch Abrufen der Zeilen mit `objectsForEntity:identifier:`.

Die Faustregel, der der Code folgt:

> **Durch `Rptq` schreiben; durch `MADModel` lesen und beobachten.**

Die beiden Schichten teilen einen Kennungsraum: das `identifier` eines Modellobjekts *ist* das `identifier` der Speicherzeile. Das ist der ganze Leim — siehe §3.

```
MADModelDocument                       one per open .mad — MADocument.documentModel
 └ databases: [MADModelDatabase]       (today: exactly one)
    ├ driverID / driverType / schemaName   ← RptqDatabase + RptqDatabaseCredentals
    ├ tables / tableDictionary : {id → MADModelTable}      ← RptqDatabaseSchemaTable
    │   └ MADModelTable  (name, queryable)
    │      └ fields / fieldIDs : {id → MADModelField}      ← RptqDatabaseSchemaField
    │         └ MADModelField (name, dataType, decimals, width, primaryKey)
    └ queries: [MADModelQuery]         (today: exactly one; `firstQuery` everywhere)
       └ MADModelQuery
          ├ queryTableIDs / tables : {id → MADModelQueryTable}   ← RptqQueryTable
          │   └ MADModelQueryTable  (schemaTable id, dropIndex, alias)
          │      └ queryFields : {id → MADModelQueryField}       ← RptqQueryField
          │         └ MADModelQueryField (schemaTable + schemaField ids)
          └ queryLinkIDs / links : {id → MADModelQueryLink}      ← RptqQueryLinks
              └ MADModelQueryLink   (left/right table+field ids — one join)
```

## 2. Die Klassen

### 2.1 `MADModel` — Identität (`MADModel.h`, `MADModel.m`)

Die Basisklasse ist nur Identität: `_uid` (`MADModel.m:32-64`), mit `hash`, `isEqual:` (gleiche Klasse und gleiche `_uid`) und `-objectID`, das die ID in einem `NSNumber` verpackt zurückgibt. `+[MADModel newModelDocument:]` (`MADModel.m:35`) ist die nominelle Fabrik — niemand ruft sie auf; `MADocument` allokiert `MADModelDocument` direkt. `MADModelType.h` definiert `MADModelTypeUnknown/Document/Database/Queries`; nichts im Baum verwendet das Enum.

Der Name `objectID` und ein auskommentiertes `debugDescription`, das `_objectID.URIRepresentation` formatiert, sind der Hinweis auf das Alter der Schicht: die Objekte verpackten früher `NSManagedObjectID`s (siehe §5).

### 2.2 `MADModelDocument` — die Wurzel (`MADModelDocument.h`, `.m`)

- Einmal pro offenem Dokument erzeugt von `-MADocument.documentModel` (`MADocument.m:389-395`), träge, über `self.storeContext`. Nichts sonst in der Produktion baut eines; der App-Delegat hat keinen Anteil daran.
- Hält `databases` (gebaut von `-updateDocumentDatabaseQuery`, `MADModelDocument.m:210-240`: ein `MADModelDatabase` *pro `RptqQuery`-Zeile* — „database“ bedeutet hier die Verbindung plus ihr Schema plus eine Abfrage) mit den Komfortzugriffen `firstDatabase` / `firstQuery`. Der Code sagt, warum der Plural Theater ist: *„current versions of the software only use one database and query“* (`MADModelDocument.m:207-208`).
- **Registriert sich für die Änderungsbenachrichtigungen des Speichers** (`RptqStoreContextObjectsDidChange`, `WillSave`, `DidSave`, `MADModelDocument.m:160-176`) auf einer privaten `NSOperationQueue` (`MADModelDocument.m:83-87`, `_objectContextQueue`). Bei Insert/Delete einer Zeile `RptqQueryTable` oder `RptqQueryLinks` spiegelt es die Änderung in `firstQuery` — siehe §3.3.
- `-update` (`MADModelDocument.m:201-205`) führt den Scan Dokument→Datenbank→Abfrage erneut aus und *ersetzt* `_databases` durch neue Objekte.

### 2.3 `MADModelDatabase` — Verbindung, Schema und Abfragen (`MADModelDatabase.h`, `.m`)

- Verschlüsselt nach dem `identifier` der `RptqDatabase`-Zeile.
- Metadaten werden *durch den Speicher, eine Eigenschaft nach der anderen* aufgelöst: `driverType` (`MADModelDatabase.m:157-164`), `schemaName` (`:166-173`) und `driverID` (`:175-182`) rufen jeweils träge die `RptqDatabase` ab und lesen durch zu `RptqDatabaseCredentals`. `schemaName` und der defekte `driverName` (§6) antworten beide mit der `dbname` der Zugangsdaten.
- `tables` / `tableDictionary` (`-updateTables`, `MADModelDatabase.m:221-247`) listen jede `RptqDatabaseSchemaTable`, deren `inDatabase` passt, **nach Namen sortiert** — und stellen die Sortierung wieder her, die ein Fetch vor der Migration anwandte, mit einem Kommentar, der auf BUGS.md verweist.
- `queries` (`-updateQueries`, `:249-261`) tun dasselbe für `RptqQuery`-Zeilen.

### 2.4 `MADModelTable` / `MADModelField` — das Schema (`MADModelTable.{h,m}`, `MADModelField.h`)

- `MADModelTable` cached `name` und baut träge `fields` / `fieldIDs` (`MADModelTable.m:120-146`) aus `RptqDatabaseSchemaField`-Zeilen, deren `inTable` passt, nach Namen sortiert. `MADModelField` ist ein einfacher Wert: Name, Primärschlüssel-Flag, Datentyp, nativer Typ, Dezimalstellen, Breite — kein Speicherzugriff.

### 2.5 `MADModelQuery` — eine Abfrage (`MADModelQuery.h`, `.m`)

Die größte Klasse und die, die ihren Unterhalt tatsächlich verdient. Sie besitzt:

- `queryTableIDs` + `tables` (`MADModelQuery.m:213-283`): jedes `RptqQueryField`, dessen `inQueryTable.inQuery` diese Abfrage ist, wird in ein Wörterbuch projiziert (`MADStoreProjectionForQueryField`, `:59-68`) — die genaue Form, die die alten Core-Data-Fetch-Projektionen erzeugten — und `-insertTablesFromFetchRequestResults:` übergeben.
- `queryLinkIDs` + `links` (`:302-344`): dasselbe für `RptqQueryLinks` (`MADStoreProjectionForQueryLink`, `:70-78`).
- Topologie-Helfer: `-tablesInLinks` (`:183`) und `-orphanedQueryTables` (`:196`, die Tabellen, die kein Link berührt, über ein `NSExpression`-Mengenminus).
- **Die Mutationsoberfläche**: `-insertQueryTable:` / `-insertQueryLink:` / `-deleteQueryTableID:` / `-deleteQueryLinkID:` und die id-basierten Varianten. Jede wendet die Änderung auf die Sammlungen an und sendet dann `MADNotificationQueryTableInsert/Delete` oder `MADNotificationQueryLinkInsert/Delete` (Namen in `MADModel.h:22-26`) **auf der Hauptwarteschlange** über `[NSOperationQueue mainQueue] addOperationWithBlock:` erneut, mit dem betroffenen Modellobjekt im `userInfo`. Diese Benachrichtigungen sind der öffentliche Ereignisstrom der Schicht; der Designer abonniert sie (§4).

### 2.6 `MADModelQueryTable` / `MADModelQueryField` — Tabellen und Felder der Abfrage

- `MADModelQueryTable` (`MADModelQueryTable.m`) cached `dropIndex` und die ID der **Schema**tabelle und hält träge `queryFields` / `queryFieldIDs` (gebaut von `-addField:schemaField:`, `:92`). `-alias` (`:119-129`) ist der SQL-seitige Name: der Name der Schematabelle für die erste Kopie und Name + Drop-Index danach (`Customer`, `Customer0`, …).
- `MADModelQueryField` (`MADModelQueryField.m`) sind zwei IDs: die Schematabelle und das Schemafeld. `-schemaField` (`:52-57`) löst die echten Metadaten auf, indem es Datenbank → `tableDictionary[schemaTable]` → `fields[schemaField]` durchläuft. Diese Kette — Link → Abfragetabelle → Schematabelle → Abfragefeld → Schemafeld — ist das bestimmende Muster der Schicht; `MADQueryVisualizationViewController.m:1024-1048` führt sie von Hand aus, um einen Verbinder zu platzieren.

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier` (`MADTableFieldIdentifier.{h,m}`) ist ein winziges Wertepaar (Tabellen-ID + Feld-ID) mit `NSNumber`-Zugriffen.
- `MADModelQueryLink` (`MADModelQueryLink.m`) hält ein `MADTableFieldIdentifier` für jedes Ende, gebaut entweder aus rohen IDs oder aus einer `RptqQueryLinks`-Zeile (`-initWithRptqQueryLink:`, `:60-76`, das `hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier` liest). `-isAdjacentToQueryTable:` (`:78`) und `-tables` (`:82`) beantworten die Graphfragen, die die Visualisierung stellt.

### 2.8 Die Protokolle und die rudimentären Stücke

- `MADModelIDProtocol` — vier Zeilen: `identifier` (`MADModelIDProtocol.h`).
- `MADModelDataProtocol` (`MADModelDataProtocol.h`) — `managedObjectContext`, `-initWithIdentifier:managedObjectContext:` und `-update`. In der Praxis ist `-update` ein interner Auffrischungshaken: er wird nur von den eigenen trägen Gettern der Schicht aufgerufen (`MADModelDocument.m:188`, `MADModelTable.m:99` und `:115`). `MADModelDatabase -update` (`MADModelDatabase.m:148`) und `-MADModelQuery -update` (`MADModelQuery.m:354`, eine leere Methode) haben überhaupt keine Aufrufer.

## 3. Lebenszyklus

### 3.1 Erzeugung

`MADocument` baut träge ein `MADModelDocument` (`MADocument.m:389-395`) und behält es für die Lebensdauer des Dokuments. Es hält den `RptqStoreContext` **schwach** (`MADModelDocument.m:42`), wie jedes Modellobjekt, das einen Kontext hält — der Speicherkontext gehört dem Dokument.

### 3.2 Befüllung

Alles unterhalb des Dokuments ist **träge und gecached**: der erste Lesezugriff auf `databases`, `tables`, `fields`, `queryTableIDs`, `queryFields` oder `links` löst einen Fetch-und-Filter-Durchlauf aus (`objectsForEntity:` über die relevante Rptq-Entität, gefiltert nach der Kennung des Elternteils, dann sortiert, wo ein Fetch vor der Migration sortierte). Die Caches werden nur durch Aufruf von `-update` oder über den Benachrichtigungspfad unten ungültig; nichts verfällt von selbst.

### 3.3 Live-Änderungen — der Round Trip

Das Hinzufügen einer Tabelle oder eines Links im Designer schreibt **Rptq-Zeilen** (z. B. erzeugt der Add-Table-Ablauf bei `MADQueryViewController.m:745-790` Zeilen `RptqQueryTable` + `RptqQueryField` und speichert den Kontext). Das Modell holt dann von selbst auf:

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```

Zwei Warteschlangen sind im Spiel: das Modell *mutiert* auf `_objectContextQueue` (einer privaten `NSOperationQueue`, `MADModelDocument.m:83-87`), und die Benachrichtigungen *kommen* auf der Hauptwarteschlange an. Die Sammlungen selbst sind nicht synchronisiert.

### 3.4 Veraltung

`-update` (Dokument oder Datenbank) baut Sammlungen mit **neuen** Modellobjekten neu auf; jedes früher herausgegebene Modellobjekt funktioniert für das weiter, was es gecached hat, ist aber nicht mehr das in `firstQuery.tables`. Nichts im Baum ruft heute `-update` auf einem Modellobjekt auf — der Benachrichtigungspfad ist der lebende —, aber Code, der Modellobjekte über ein `-update` hinweg aufbewahrt, würde veraltete Einträge lesen.

## 4. Konsumenten

### 4.1 Der Abfrage-Arbeitsbereich (Ad-hoc-Abfrage-Builder)

- `MADQueryViewDataSource.m:365` — die Kopfzelle der Datenquelle: „You are connecting to *driverID* datasource named *schemaName*“ aus `firstDatabase`.
- `MADQueryViewDataSource.m:533-546` — die Liste der Abfragetabellen nimmt `firstQuery` und verwendet `query.identifier`, um `RptqQueryTable`-Zeilen zu filtern. Beachten Sie das Muster: **das Modell liefert Identität und Metadaten; die Zeilen selbst sind Rptq-Objekte.**
- `MADQueryTableViewController.m:163-174` — der Kastentitel einer Abfragetabelle kommt aus `firstQuery.tables[id].alias`; `:186-200` und `:239-266` rendern die Schemafeldliste aus `firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields`. Das ist das ganze Inhaltsmodell des Schema-Browsers.
- `MADQueryBuilderAddTableViewController.m:29-33` — beobachtet die Insert/Delete-Benachrichtigungen des Modells, um sein Tabellenpanel aktuell zu halten.

### 4.2 Der Arbeitsbereich Abfragevisualisierung (Kästen und Verbinder)

- `MADQueryVisualizationModel` (`MADQueryVisualizationModel.m:40-77`) baut einen `MTGraph` über `-[MTGraph initWtthQueryID:]` (`MTGraph+RptqQuery.m:39-67`), das **vollständig auf dem Modell** geschrieben ist: `query.queryTableIDs` werden Knoten, `query.links` werden Kanten. Es sortiert dann topologisch, berechnet `startingPoints` (Tabellen, in die kein Link *hineinzeigt*) und speichert das DAG-Flag. (Dieselbe Kategorie hat auch speicherbasierte Initialisierer, `:69-93`, die dem Modellpfad vorausgehen; die Visualisierung verwendet den Modellpfad.)
- `MADQueryVisualizationViewController` (`MADQueryVisualizationViewController.m`) ist der Hauptkonsument des Benachrichtigungsstroms: er abonniert alle vier Modellbenachrichtigungen (`:314-335`), fügt Kästen und Verbinder hinzu/entfernt sie, während sie ankommen, markiert Wurzeltabellen nach einer Link-Löschung mit `-orphanedQueryTables` neu (`:936`), fragt `-linksForQueryTable:` pro Tabelle ab (`:644`) und legt jeden Verbinder durch Durchlaufen der Kennungskette aus (`:1024-1048`, §2.6).
- `MADQueryVisualizationCacheManager` persistiert das Leinwand-Layout, verschlüsselt nach Modellkennungen (`updateCacheWithQuery:…`, `MADQueryVisualizationCacheManager.h:20`).

### 4.3 Das Dokument und die Tests

`MADocument.documentModel` ist der einzige Produktionseinstiegspunkt. Tests: `MADDocumentTests.m:263-265` (die `databases`/`queries` eines erneut geöffneten Dokuments), `MADDocumentTests.m:399-404` (die Tabellen-/Feldreihenfolge eines `MADModelDatabase`), plus die eigenen Suiten `MADModelQueryTableTests`, `MADModelQueryFieldTests` und die Abdeckung von `MADModelField` / `MADModelQueryLink` in `MADModelValueTypesTests`.

### 4.4 Was die Schicht *nicht* verwendet

- **SQL-Erzeugung** — `MADQueryFull` und die Klassen `Rptq*+Extras` arbeiten auf der Rptq-Schicht (z. B. baut `RptqQueryField+Extras.m:137` die Namen `table.field` aus `RptqQueryTable.alias`).
- **Layout und Rendern** — `MADDesignerLayout` und der Berichtspfad arbeiten auf `RptqDocumentElement`; `MADReportFormatter` verwendet die Schicht überhaupt nicht (seine drei `MADModel*`-Importe bei `MADReportFormatter.m:18-20` sind veraltet).
- **Zeilendaten** — nichts davon berührt den `.maddb`-Cache; das ist Territorium von `MADDataTableFast` / `MADReportFormatter`.

Der reale Umfang der Schicht ist heute also: **die Abfrageseite des Designers und nichts anderes.**

## 5. Warum sie existiert

Die Schicht stammt aus dem frühen 2017 (Dateiköpfe `1/22/17`–`6/3/17`) und wurde in der Core-Data-Ära als **handgemachtes View-Modell für die Abfrage-UI** gebaut: leichte Objekte, an die die Tabellenansichten des Designers und die Visualisierungsleinwand binden konnten, statt `NSManagedObject`s und `NSFetchedResultsController`s. Die Belege stehen in den Dateien: `-objectID`, die auskommentierte `NSManagedObjectID`-Debug-Beschreibung in `MADModel.m:66-80` und drei überlebende Kommentare, die sagen „was an `NSFetchedResultsController`“ (`MADQueryChooseFieldController.m:149`, `MTGroupByViewController.m:53`, `MADTableViewControllerCoreDataResults.h:14`).

Die Speichermigration (Phase C/D von `MAD_STORE_MIGRATION.md`) verdrahtete jeden Fetch von Core Data auf `RptqStoreContext` + `objectsForEntity:` **um, ohne die Oberfläche dieser Schicht zu ändern** — weshalb `MIGRATION_KICKOFF.md` §Findings sie „[a] clean `MADModel*` domain layer [that] already wraps the `Rptq` entities; it is the seam to keep.“ nennt.

Sie ist also eine Art MVC, aber nicht „das Modell der App“: sie ist ein **Read-Modell pro Dokument** (das „Modell“ von MVC, wie der Controller es sieht), und die kanonischen Domänenobjekte sind der Rptq-Graph. Die Abstraktion kauft drei Dinge und ist überall sonst dünn: (1) den Abfragegraphen in anzeigeförmiger Gestalt (Aliase, Nachbarschaft, ID-zu-Metadaten-Nachschlagen) ohne Beziehungsdurchlauf; (2) eine Stelle, die Änderungsbenachrichtigungen des Speichers in Abfragegraph-Ereignisse umwandelt; (3) eine Schnittstelle, die die UI unberührt lassen konnte, während sich der Speicher darunter vollständig änderte — was genau geschah.

## 6. Bekannte raue Kanten

Aus erster Hand gelesen; keine davon hat heute einen Konsumenten, also sind alle latent.

1. `MADModelField.inTable` (`MADModelField.h:20`) ist als `weak MADModelField *` deklariert — der Typ ist falsch (er sollte `MADModelTable *` sein) — und nichts weist ihn je zu.
2. Die anderen Eltern-Rückzeiger sind ebenso unbenutzt: `MADModelTable.inDatabase`, `MADModelQueryTable.inQuery` und `MADModelQueryField.inQueryTable` werden von keinem Codepfad im Baum je zugewiesen. Nur `MADModelQuery.inDatabase` wird je gesetzt (`MADModelQuery.m:108-114`). (Dass `-addField:schemaField:` den Rückzeiger seines Felds nicht verdrahtet, ist bereits in BUGS.md festgehalten.)
3. `MADModelDatabase -driverName` (`MADModelDatabase.m:184-215`) endet in `return @"";`, antwortet also mit dem leeren String, selbst nachdem es den echten Namen gecached hat; `-schemaName` gibt bereits denselben String von derselben Stelle zurück. Es gibt keinen Leser.
4. `MADModelDocument.m:228-234` decodiert eine Dokument-ID (`docID`) und verwendet sie nie.
5. `MADModelQuery -update` (`MADModelQuery.m:354`) ist leer; `MADModelDatabase -update` hat keine Aufrufer; `+[MADModel newModelDocument:]` hat keine Aufrufer.
6. `MADModelType` ist unbenutzt.
7. Keine Synchronisierung zwischen der privaten Warteschlange, die das Modell mutiert, und den Hauptthread-Lesern; und `MADModelDocument` hält den Speicherkontext schwach, also hat ein Modell, das sein Dokument überlebt, keinen Kontext, um irgendetwas aufzulösen.
8. Benennung: ein `MADModelDocument` hat `databases`, und ein `MADModelDatabase` hat `queries` — aber das Dokument baut eine „Datenbank“ *pro Abfrage*, und heute gibt es genau je eine. Die Struktur ist Zukunftssicherung von vor der Vereinfachung auf eine Datenbank/eine Abfrage.

## 7. Refactoring-Kandidaten (Vorschläge — keiner angewandt)

Nach Wert über Risiko geordnet. A und B sind reines Aufräumen; C ändert, was ein öffentlicher Header verspricht; D ist eine Entscheidung.

**A. Dokumentation, nicht Konsolidierung.** Der billigste Klarheitsgewinn sind Header-Kommentare pro Klasse (2–4 Zeilen: was die Klasse ist, wonach sie verschlüsselt ist, wer sie liest) plus dieses Dokument. Die *Dateien* der Klassen zu verschmelzen ist die teure Option, nicht die billige: sechzehn-plus Dateien importieren die Header pro Klasse (`#import <MAD/MADModelQueryField.h>` usw.), jeder Header ist eine eigene Datei in den Xcode-Targets, und der Include-Shim des Linux-Builds ist ein Verzeichnis von Symlinks pro Header (`Linux/README.md`, der Shim von MAD). Konsolidieren würde das pbxproj, die Linux-Quelllisten und jede Importstelle für einen kosmetischen Gewinn berühren. Falls je ein Merge gewünscht wird, ist die sichere Richtung die entgegengesetzte: eine Klasse pro Datei behalten und den **Einstiegspunkt** offensichtlich machen (Dokument oben in `MADModel.h`, „start at `MADModelDocument`“).

**B. Die rudimentäre Oberfläche löschen oder vervollständigen.** Jedes davon ist verhaltenssicher (nichts liest sie), berührt aber Header, also behandeln Sie es als API-Entscheidung:
- `MADModelField.inTable`: den Typ korrigieren und ihn in `MADModelTable -update` setzen (eine Zeile, symmetrisch zu den anderen Eltern), oder die Eigenschaft löschen.
- `MADModelDatabase -driverName`: den gecachten Wert wie seine Geschwister zurückgeben oder löschen.
- `MADModelType`: den Header löschen. (Erfordert die Entfernung aus der Projektdatei; in einem Commit erledigen.)
- `+[MADModel newModelDocument:]`: entweder `MADocument -documentModel` es verwenden lassen (den Zweck der Fabrik wiederherstellen) oder löschen.
- Die ungenutzte `docID`-Decodierung in `MADModelDocument.m:228-234`.

**C. Die deklarierten Rückzeiger verdrahten.** `inDatabase`, `inQuery` und `inQueryTable` existieren, damit der Graph aufwärts durchlaufen werden kann; heute funktionieren nur Abwärts-Nachschlagen. Sie bei der Konstruktion zuzuweisen (`MADModelDatabase -updateTables` hat bereits `self`; `insertTableRptqQueryTable:` hat die Modellabfrage; `-addField:schemaField:` hat die Tabelle) lässt den Objektgraphen zu seinen Headern passen und ist gerade deshalb sicher, weil noch nichts sie liest. Semantik, die man im Kopf behalten sollte: sie sind als `weak` deklariert, was für abwärts besessene Eltern richtig ist.

**D. Identität über Auffrischungen hinweg (eine Entscheidung, kein Aufräumen).** `-update` ersetzt Objekte; falls je stabile Identität über Aktualisierungen hinweg gewünscht wird, müssen die Update-Methoden an Ort und Stelle mutieren (das Objekt für eine Kennung wiederverwenden, die Differenz hinzufügen/entfernen) statt neu zu bauen. Das ändert die beobachtbare Identität herausgegebener Objekte, also braucht es eine bewusste Entscheidung.

**E. Mechanische Deduplizierung.** `MADModelTable.fields` und `-fieldIDs` (`MADModelTable.m:88-118`) enthalten denselben Initialisierungsblock zweimal, und die drei Getter von `MADModelQuery` wiederholen denselben Tanz „Sammlungen sicherstellen, dann aktualisieren“ (`MADModelQuery.m:116-181`). Beide können je in einen privaten Helfer kollabieren, ohne Verhaltensänderung; lohnt sich nur, wenn die Datei ohnehin für etwas anderes offen ist.

**F. NICHT empfohlen: Umbenennen.** `MADModelDatabase` → so etwas wie `MADModelConnection` würde sich besser lesen, aber Umbenennungen hier sind Aufruhr über Xcode-/Linux-Projektdateien ohne funktionalen Nutzen.

## 8. Wenn Sie diese Schicht ändern

- Halten Sie den Vertrag der reinen Kennung: ein Modellobjekt muss allein aus IDs konstruierbar bleiben (darauf verlassen sich der Benachrichtigungspfad und die Tests).
- Alles, was `RptqQueryTable` / `RptqQueryLinks`-Zeilen erzeugt oder löscht, wird vom Beobachter von `MADModelDocument` automatisch aufgenommen — aber nur für Zeilen, die über `firstQuery` erreicht werden; eine zweite Abfrage in einem Dokument wird nicht gespiegelt.
- Die vier Namen `MADNotification…` sind die öffentliche API der Schicht für die UI; beobachten Sie sie gegen das `firstQuery`-Objekt, wie es `MADQueryVisualizationViewController` tut.
- Die iOS-Suite (Scheme `MAD`) und `./Linux/build.sh` kompilieren beide diese Dateien; siehe `Linux/cmake/MADSources.cmake`.
