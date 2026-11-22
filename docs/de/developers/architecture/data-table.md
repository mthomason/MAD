---
layout: default
lang: de-DE
title: "Die MADDataTable-Architektur"
description: "Der Datenbanktabellen-Klassencluster über die Frameworks und sein Entkopplungsplan."
---

# MADDataTable — Architektur- und Entkopplungsbericht

Diese Seite ist der Architekturbericht für `MADDataTable` und jede Implementierung in `MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL` und `MADTdsClient`. Sie hält den Klassencluster und die Entkopplungsarbeit fest.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

**Umfang:** `MADDataTable` und jede Implementierung, Unterklasse, jedes Protokoll und jede Aufrufstelle in `MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL` und `MADTdsClient`.
**Branch:** `refactor/mad-database-decouple`
**Datum:** 2026-10-01
**Verifikation:** `xcodebuild test` — alle 11 Schemes, 809 Tests, 0 Fehlschläge; keine Warnungen aus einer Datei im Umfang (die beiden `-Warc-repeated-use-of-weak`-Warnungen in `MADDatabaseMySQL.m` sind vorbestehend und unberührt). (798 bei Revision 2; 804 bei Revision 3; 807 bei Revision 4.)

Alle `file:line`-Verweise unten wurden bei dieser Analyse aus erster Hand gelesen, nicht abgeleitet.

> **Revision 5 — 2026-10-01.** Die Phasen 3 und 5 sind geschlossen und Phase 1 Schritt 7 ist bewiesen. `-dropTable`, `-dropTableName:`, `-deleteAll` und `-vacuumCacheDb` hinterlassen jetzt einen `rowCounter`, der die Datei beschreibt (§2.5), was den ganzen Schritt 10/11 ausmachte; die drei gefährdeten Konstanten sind durch vier neue Tests abgedeckt. Die sqlite-Zeilenschleife mit einem reinen `<MADDataTableWriting>`-Konformanten zu treiben — ohne `MADDataTable` dahinter, ohne `.maddb` — ist Schritt 7 und jetzt ein Test (`MADWritePortRecorder`). Schritt 14 ist erledigt: `MADDataTableLocation` ist gelöscht. Die Schritte 13 und 15 werden bewertet statt erledigt, mit Gründen, in ihren Einträgen unten.
>
> Zwei aktive Defekte fielen beim Schreiben dieser Tests heraus, beide jetzt behoben. `-deleteAll` übergab einen *String* an `-[MADQueryCacheDeleteAllFromTable initWithObject:]`, das ihn als Parameterwörterbuch subscriptet und beim ersten Zeilenzugriff auslöst — die Methode hat keine Aufrufer, weshalb nie etwas darauf gestoßen war; jetzt verwendet sie `-initWithTableName:`. Und `MTTableController` las `datatable.count` als Seiten-Cursor auf seinem Fehlerpfad, wo die Tabelle noch die vorherige Seite hält, sodass ein gescheiterter Fetch `hasMore = YES` meldete und ewig wiederholte.
>
> Die Zählerkommentare verschoben `MADDataTableFast.m` um 13 Zeilen ab `-deleteAll`, also wurde jeder `file:line`-Verweis hinter diesem Punkt neu hergeleitet statt angepasst; `MTTableController.m` verschob sich ebenfalls, und seine Verweise wurden mit ihm neu hergeleitet.
>
> **Revision 4 — 2026-10-01.** Das MySQL-Hindernis von Revision 3 ist weg. Die Spaltenmetadaten, die `MADMySQLFetch+DataTable.m` mitten im Fetch liest, werden jetzt von `<MADDataTableWriting>` selbst deklariert, also nehmen alle drei Treiber — einschließlich `MADDatabaseMySQL`, `MADDatabase.m` und des Protokolls `MADDatabaseDataSource` — `id <MADDataTableWriting>`, und die Out-Parameter des Fetch sind by-value (`&` an allen Aufrufstellen entfernt). Phase 2 („`urlFastCache` speichern; das Cache-Verzeichnis injizieren“) und Phase 4 Schritt 12 (die Schreibpipeline serialisieren) sind erledigt, und Phase 3 ist nur für den Rehydrierungspfad erledigt. §2.1 und §2.3–§2.5 und §4.2 markieren es jeweils. Drei Tests wurden hinzugefügt; die Suite geht 804 → 807. Weil die Behebungen `MADDataTableFast.m` um 87 Zeilen verschoben, wurde jeder `file:line`-Verweis darauf in diesem Bericht neu hergeleitet statt angepasst, und die Zeilenzahlen im Anhang wurden mit ihnen aufgefrischt.
>
> **Revision — 2026-09-30.** Die Abschnitte §2.5, §3.3, §3.5 und §4.2 wurden neu geschrieben, nachdem die erste Revision an drei Punkten falsch war: die Diagnose zu `-dataForRow:error:` (eine zweizeilige Methodensignatur wurde falsch gelesen — die Methode *ist* auf `MADDataTableFast` implementiert), der „aktive Fehler“ bei `-allObjects` (kein Produktionsaufrufer) und die Darstellung der `rowCounter`-Drift (unerreichbar). §4.5 ist neu. Korrigierter Text ist als **Corrected** / **Fixed** markiert; die ursprünglichen Behauptungen bleiben sichtbar, wo sie lehrreich waren. Drei Code-Behebungen landeten mit dieser Revision — siehe §3.5.
>
> **Revision 3 — 2026-10-01.** Phase 1 Schritt 5 ist gelandet: `<MADDataTableWriting>`, `<MADDataTableReading>` und `<MADDataTableCursoring>` sind in `MADDataTable.h` deklariert, und die Klasse adoptiert alle drei. Schritt 6 landete für zwei von drei Treibern — `MADDatabaseSQLServer` und `MADDatabaseSqlite3` sind jetzt write-port-typisiert. Schritt 6 **konnte nicht** für `MADDatabaseMySQL` landen, und der „den nun redundanten Stub-Block löschen“-Teil von Schritt 5 wurde abgelehnt; §4.2 hält die Gründe für jeden fest. Der ganze Durchgang ist additiv: kein Verhalten änderte sich, und alle 11 Schemes bestehen (804 Tests).
>
> **Revision 2 — 2026-09-30.** Die acht `sqlite3_mprintf`-Formatstring-Stellen von §4.5 sind jetzt behoben, und Phase 0 ist gelandet: die nicht implementierten Operationen in `MADDataTable.m` asserten statt still zu scheitern (§3.2, §4.2). Die Tabelle in §3.1 und die Zeilenzahlen im Anhang wurden gegen die geänderten Dateien neu hergeleitet. Zwei Fehler der vorherigen Revision wurden ebenfalls korrigiert: die Workspace-Testsumme war mit 799 angegeben und ist 798, und §3.6 hatte vier `_database`-Stellen zitiert, wo es fünfzehn gibt.

---

## 1. Aktuelle Architektur und Klassenhierarchie

### 1.1 Die Klassenfamilie

`MADDataTable` ist **keine** einzelne Klasse — es ist ein kleiner Klassencluster, aufgeteilt über drei Frameworks entlang einer Speicherachse, plus eine Cursorachse, die als separate Enumeratorobjekte implementiert ist.

```
MADFoundation
└── MADDataTable                          NSObject <NSCoding, NSFastEnumeration>
        │                                 "abstract": declares the full surface,
        │                                 implements metadata + plist persistence
        │
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (240 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1368 ln)
                sqlite3-backed. Rows live in a `.maddb` file; the object holds two
                MADDatabaseSqlite3 handles (one for writes, one for reads).

MADSqlite3 (private — NOT exported from the framework)
├── MADDataTableObjectEnumerator          173 ln — wraps a live sqlite3_stmt, yields row dicts
└── MADDataTableSingleColumnEnumerator    149 ln — same, yields a single column (row-ids)

MAD
└── MADDataTable+Constructor              the ONLY place that maps type -> concrete class
                                            (`MADDataTableLocation`, the other class here at
                                            Revision 4, was deleted — see §3.7)
```

Verifizierte Exportoberfläche (aus gebauten `.framework/Headers`):

| Framework | Öffentlich exportierte Datenbanktabellen-Header |
|---|---|
| `MADFoundation` | `MADDataTable.h`, `MADDataTableType.h`, `MADDataTableVirtual.h` |
| `MADSqlite3` | `MADDataTableFast.h` **nur** |
| `MADMySQL` | keine |
| `MADTdsClient` | keine |

Diese Aufteilung ist bewusst und gesund: die Namen der Enumeratorklassen lecken nie. Konsumenten sehen immer nur `NSEnumerator *`, was `MADDataTable.h` zurückgibt.

### 1.2 Zwei orthogonale Achsen, ein Enum

`MADDataTableType` (`MADFoundation/Source/MADDataTableType.h`) kodiert nur die **Speicher**achse:

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```

Die **Zugriffs**achse — Zeile für Zeile vs. Cursor — ist orthogonal und wird ausgedrückt, indem ein Enumerator zurückgegeben wird statt durch einen Typ. Es gibt kein `MADDataTableTypeCursor`. Das zählt für das Refactoring: die Cursor-Naht existiert bereits und ist korrekt verborgen.

### 1.3 Der einzige Punkt der Unterklassenauswahl

`MAD/Source/MADDataTable+Constructor.m:51-69` ist die einzige Stelle in der Codebasis, die eine konkrete Unterklasse nennt:

```objc
+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	switch (type) {
		case MADDataTableTypeVirtual:  result = [[MADDataTableVirtual alloc] initWithId:objectID]; break;
		case MADDataTableTypePhysical: result = [[MADDataTableFast alloc] initWithId:objectID];    break;
		default: NSAssert(NO, @"Not implemented."); break;
	}
	return result;
}
```

Ich habe bestätigt, dass es **kein** `isKindOfClass:`, `NSClassFromString`, keinen Klassennamen-Stringvergleich und keine `respondsToSelector:`-Probe auf einer Datenbanktabelle irgendwo in der Codebasis gibt. Das ist die wertvollste Eigenschaft für das Refactoring — der Cluster lässt sich hinter dieser einen Methode umformen.

Zwei Einschränkungen in derselben Datei:

* `+newDataTableWithDefinition:` ruft `NSAssert(NO, @"Not implemented.")` und gibt `nil` zurück, wenn keine Objekt-ID vorhanden ist (`:44-46`). Die Absicht „standardmäßig virtuell“ im Kommentar bei `:31-32` ist unerreichbar — `objectIdSet` steuert den einzigen Rückgabepfad.
* `+newDataTableForIdentifier:` (`:79-92`) ist der *de facto* öffentliche Einstiegspunkt: die meisten Aufrufstellen (`MTTableController.m:90`, `MADQuerySampleDataTable.m:68`, `MADQuerySampleDataTableRange.m:69`) gehen stattdessen direkt über `newDataTableWithDefinition:`, und legen den Typ immer auf Virtuell fest.

### 1.4 Der Schreibvertrag

Jeder Datenbanktreiber füllt eine Tabelle über die API der **Basisklasse**, nie über eine unterklassenspezifische. `MADDatabaseSqlite3.m:474-540` ist die kanonische Schleife:

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```

`MADDatabaseSQLServer.m:500 / :1367 / :1472` verwendet dieselbe Fünf-Aufruf-Form. `MADMySQLFetch+DataTable.m:211 / :438 / :442` ebenso.

Das ist ein **schmaler, wohldefinierter Schreibport**: fünf Methoden. Er ist die stärkste bestehende Grenze in der Familie und sollte von jedem Refactoring wortgetreu bewahrt werden.

Divergenz zwischen den Treibern:

| Treiber | Tabelle, die er baut | Schreibpfad |
|---|---|---|
| `MADDatabaseSqlite3` | was ihm übergeben wird (typisch `MADDataTableFast`) | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | **konstruiert** selbst `MADDataTableVirtual` (`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`) | `MADMySQLFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **konstruiert nie eine** — rein schreibend in eine vom Aufrufer gelieferte Tabelle | `MADDatabaseSQLServer.m` |

MySQL kann also kein `MADDataTableFast` erzeugen, und SQL Server kann überhaupt keine Tabelle erzeugen. Der „physische“ (sqlite-gestützte) Speicher existiert nur für den lokalen Cache, nicht für entfernte Ergebnisse.

### 1.5 Der Lesevorgang-Vertrag

Drei verschiedene Lesestile sind produktiv in Verwendung:

1. **Wahlfreier Zugriff** — `-objectAtRow:` / `-objectAtRow:column:`.
   `MADMySQL` verwendet `objectAtRow:i column:0` in O(n)-Schleifen (`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`), um `SHOW TABLES`-Ergebnisse zu lesen. `MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131` rufen `objectAtRow:0` einmal auf, um eine Breitenzeile zu lesen. `MTTableController.m:281, 284, 393` verwendet `objectAtRow:` für das Paging.

2. **Aufzählung** — `-enumeratorForKeyObjectsSorted`.
   `MADocument.m:865-867` gibt ihn als `enumeratorForReportData` zurück, konsumiert von `MADReportFormatter.m:449-502`.

3. **Zählungen** — `-rowCounter` / `-count` / `-numberOfRows`.
   `MADocument.m:197` (`numberOfResults`), `MTTableController.m:249` (Tabellengröße) und `:377, :399, :449, :455` (Seiten-Cursor-Arithmetik).

`MADReportFormatter` ist der nachsichtigste Konsument und der, der das Refactoring am wenigsten einschränkt. Beachten Sie `MADReportFormatter.m:463-472`:

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```

Der Formatierer **toleriert bereits einen Enumerator, der reine Zeilen-ID-`NSNumber`s liefert**, ebenso wie vollständige Zeilenwörterbücher. `enumeratorForAllObjectsSortedRowIdOnly` existiert genau für diesen Fall. Das ist eine fertige Naht: ein Cursor, der nur Zeilen-IDs streamt, ist bereits ein akzeptierter Eingang.

---

## 2. Speichermodell, Lebenszyklus und Zustand

### 2.1 ARC und das eine rohe Ivy

Alle Dateien sind ARC (`#if !__has_feature(objc_arc) #warning ...`-Guards). Zustand lebt in Klassenerweiterungen. `MADDataTableFast` hat genau ein Nicht-Objekt-Ivy:

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```

Es wird in `-dealloc` (`:163-165`) und in `-endBulkInsert` (`:1334-1339`) finalisiert. Das Muster ist korrekt, war aber *fragil*: `-endBulkInsert` nullte die Anweisung **vor** dem Barrier-Setzen, sodass der Abbau außerhalb des einzigen Fensters lag, in dem kein Insert läuft.

**Behoben (Revision 4).** Der Abbau läuft jetzt innerhalb der Barriere, bei `:1337-1338`.

### 2.2 Zwei sqlite-Verbindungen über eine Datei

`-reopenDbConnection` (`:385-401`) baut **zwei** unabhängige `MADDatabaseSqlite3`-Instanzen, die auf dieselbe `.maddb`-Datei zeigen:

```objc
// write handle
MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
database.databaseConnection = connection;
[(MADDatabaseSqlite3 *)database openDatabaseWithFlags:
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
self.databaseForInserts = database;

// read handle — same URL, separate connection, default flags
MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
[databaseSelect setDatabaseConnection:connectionSelect];
[databaseSelect openDatabase];
databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
self.databaseForSelects = databaseSelect;
```

Das Lese-Handle wird mit **`-openDatabase` (Standard-Flags)** geöffnet und das Schreib-Handle mit `SQLITE_OPEN_FULLMUTEX`. `SQLITE_OPEN_FULLMUTEX` ist ein **pro Verbindung** wirkender Serialisierungsmodus; er schlichtet nicht zwischen zwei Verbindungen auf derselben Datei. Zusammen mit §2.4 ist dies die einzelne größte Korrektheitsannahme in der Familie.

### 2.3 Der Speicherort wird aus umgebendem globalem Zustand aufgelöst

`-urlFastCache` war eine *berechnete* Eigenschaft (`:299-311` vor dieser Revision), nicht gespeichert:

```objc
- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}
```

Konsequenzen:

* Eine Tabelle ohne `cacheDelegate` **hängt still vom globalen App-Delegaten** für ihre Identität auf der Platte ab. Deshalb konnte `MADDataTableFast` in einem hostlosen Logiktest ohne Delegaten nicht instanziiert werden — die Regression-Suite umgeht es mit einem Stub, der `MADCacheProtocol` + `MADDatabaseResultsProtocol` erfüllt.
* `-setCacheDelegate:` (`:377-383`) ruft `-reopenDbConnection`. Ein Delegatenwechsel **richtet die Tabelle auf eine andere Datei neu aus**, während `tag`/`rowCounter`/`columnKeys` im Speicher bleiben. Nichts erkennt die Diskrepanz.
* `-copyPlist` assertet `urlFastCache != nil` (`:243`) — also hängt die persistierte URL einer archivierten Tabelle vom umgebenden Zustand zur Archivierungszeit ab.

**Behoben (Revision 4).** `-urlFastCache` löst jetzt einmal auf und hält die Antwort (`_urlFastCache`, bei `:347-355`, geschrieben vom Getter und von `-setCacheDelegate:` bei `:377-383`, das sie vor dem erneuten Öffnen verwirft). `-newUrlFastCache` (`:357-373`) behält die Auflösung selbst, mit einer neuen ersten Wahl: ein beim Init geliefertes Cache-Verzeichnis. `MADDataTableFast` erhielt `-initWithId:cacheDirectory:` (`:173-181`), `+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]` reicht es durch (`nil` behält das alte Verhalten), und es öffnet die Verbindung sofort, sodass die Tabelle ohne Delegaten und ohne App nutzbar ist. Das Neuausrichten beim Delegatenwechsel oben geschieht weiterhin — das ist die beabsichtigte Lesung von „die URL wird aus dem Delegaten abgeleitet“ —, hängt aber nicht mehr davon ab, *wann* die Eigenschaft zuerst gelesen wurde.

`tag` (gesetzt aus `initWithId:fromCache:`, `:190`) ist die einzige stabile Identität; er erzeugt sowohl den Tabellennamen (`t<tag>`, `:403-409`) als auch den Dateinamen (`<tag>.maddb`, `:340-343`).

### 2.4 Threadsicherheit: keine Sperren, eine Warteschlange

Ich habe die ganze Familie nach `dispatch_sync`, `dispatch_async`, `@synchronized`, `NSLock`, `os_unfair_lock` und `pthread_mutex` gegrept. Das **einzige** vorhandene Nebenläufigkeitsprimitiv ist `queueBulkAdd`:

* Dreimal separat erzeugt — `initWithId:fromCache:` (`:186`), `initWithCoder:` (`:202`) und `beginBulkInsert` (`:1322`) —, jeweils `dispatch_queue_create(..., SERIAL)`.
* An genau **zwei** Stellen verwendet: `-endBulkInsert` (`:1334`) umschließt den Delegatenaufruf mit `dispatch_barrier_sync`, und (seit Revision 4) tritt `-addRow:error:` mit `dispatch_sync` ein.
* Vor Revision 4 wurde sie **nie** verwendet, um `-addRow:error:` zu serialisieren.

Also war `-addRow:` — der Mutations-Einstiegspunkt — *völlig* ungeschützt durch die Warteschlange. Unter `_bulkInsertLoop` verwendet `-addRow:` eine einzige gecachte `_statementInsert` über Aufrufe hinweg wieder (`:529-611`): `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` → `sqlite3_reset`, ohne gegenseitigen Ausschluss. Zwei Threads, die gleichzeitig in `-addRow:` eintreten, rennen auf dieser geteilten Anweisung, unabhängig von `SQLITE_OPEN_FULLMUTEX`, weil das Rennen in der *Sequenz* bind/step/clear/reset liegt, nicht in einem einzelnen sqlite-Aufruf.

Die Regression-Suite zeichnet aktuelles nebenläufiges Verhalten auf, kann es aber nicht sicher machen — die Serialisierung muss hinzugefügt werden.

**Behoben (Revision 4).** `-addRow:error:` (`:504-528`) ist jetzt ein dünner Wrapper, der den Insert-Körper (`-insertRow:error:` bei `:529`, die alte Methode umbenannt) unter `dispatch_sync(queueBulkAdd)` ausführt und nur dann auf einen direkten Aufruf zurückfällt, wenn die Warteschlange nil ist — was nur für eine Tabelle geschieht, die nie fertig initialisiert wurde. `sqlite3_finalize(_statementInsert)` von `-endBulkInsert` wanderte *in* sein `dispatch_barrier_sync`, sodass die gecachte Anweisung nur abgebaut wird, wenn kein Insert läuft. Auf einer seriellen Warteschlange sind die Barriere und das `dispatch_sync` gegenseitig ausschließend, was der gesamte gegenseitige Ausschluss ist, den die Sequenz bind/step/clear/reset braucht. Zwei Tests legen es fest: `testFastTableConcurrentWritersLoseNoRows` (neu) treibt vier Schreiber aus einer *nebenläufigen* Warteschlange; `testFastTableSerializedConcurrentWritesLoseNoRows` behält das serielle Warteschlangenmuster der App, und seine Vertragsnotiz „the table does not serialize internally“ wurde korrigiert. Schritt 13 (ein Verbindungspaar pro Datei) ist unberührt.

### 2.5 `rowCounter` ist ein unabhängiger Zähler, kein abgeleiteter Wert

`-insertRow:error:` erhöht `rowCounter` (`:532`) und **konsultiert nie sqlite**. `-numberOfRows` / `-count` geben ihn direkt zurück (`:1222` / `:1216`), und `-removeAllObjects` nullt ihn (`:683`). Aber `-dropTable` (`:799`), `-dropTableName:` (`:804`), `-deleteAll` (`:818`) und `-vacuumCacheDb` (`:789`) haben ihn bis Revision 5 **nicht** angefasst.

Die beiden Wahrheitsquellen können daher auseinanderlaufen:

* `rowCounter` sagt N; die `.maddb`-Datei hält eine andere Zeilenzahl.
* Bei einem Round Trip mit `-loadFromCacheWithUrl:` kam der Zähler aus dem Plist (`MADDataTable.m:305-306`), während die Zeilen aus der sqlite-Datei kommen — sie werden von zwei unabhängigen Mechanismen rehydriert.

**Behoben (Revision 4) — die Neulade-Hälfte.** `-loadWithPlist:` endet jetzt mit `self.rowCounter = [self recountRows];` (`:313`), wobei `-recountRows` (`:317-338`) die Cache-Datei nach `SELECT COUNT(*)` fragt und nur dann auf den Plist-Wert zurückfällt, wenn die Tabelle noch nicht existiert. Ein durch den In-Memory-Pfad aufgeblähter Zähler kann ein Neuladen nicht mehr überleben. `testFastTableReloadRecountsRowsFromCacheFile` legt das fest, indem es ein Plist lädt, dessen Zähler 99 sagt, über einer Datei mit 3 Zeilen.

**Behoben (Revision 5) — die In-Memory-Hälfte, die Schritt 10/11 war.** `-dropTable` (`:799`) und `-dropTableName:` (`:804`) nullen den Zähler jetzt, `-deleteAll` (`:818`) nullt ihn, und `-vacuumCacheDb` (`:789`) tut es bewusst nicht, weil VACUUM jede Zeile behält — die Quelle trägt einen Kommentar, der das sagt, denn „warum setzt *diese* ihn nicht zurück“ ist genau die Frage, die der nächste Leser haben wird. `-dropTableName:` nimmt einen beliebigen Namen, also nullt es den Zähler nur, wenn die verschwundene Tabelle diese ist; das Verwerfen einer fremden Tabelle darf diesen Zähler nicht berühren. `-numberOfRows` (`:1222`) und `-count` (`:1216`) geben weiterhin das Ivy zurück, statt die Datei abzufragen, was der Punkt ist — `-recountRows` ist die Prüfung des Neuladepfads, keine Kosten pro Lesevorgang.

`-removeAllObjects` (`:674`) verbarg die ganze Gefahr und tut es noch: es ist der einzige Aufrufer aller vier und nullt den Zähler selbst (`:683`). Genau deshalb war es wert, dies zu schließen statt zu lassen — die Gefahr war einen Aufrufer davon entfernt, aktiv zu sein, `-count` ist ein Seiten-Cursor für die App (§4.3), und die vier privaten Methoden sind ein `git log -S` davon entfernt, von irgendwo neu aufgerufen zu werden. Die Notiz von Revision 4 nannte die Drift hier „real im Code, aber kein Aufrufer kann sie heute erreichen“; der Aufrufer-Audit hält weiterhin — `-deleteAll` hat **überall im Repository keine Aufrufer**, und `-dropTable` wird nur von `-removeAllObjects` erreicht —, aber der Zähler ist jetzt auf jedem Pfad korrekt, statt nur, weil sein einziger Aufrufer zufällig danach aufräumt. Vier Tests in `MADDataTableRegressionTests.m` treiben jede der vier direkt.

`MADDataTableVirtual` hat dieselbe Form (`:179`, `:193`, `:225`), aber sein Zähler und sein `sortIndex` werden gemeinsam mutiert, also ist er von der Konstruktion her konsistent.

Das ist der Zustand, der bei einem Klassencluster-Refactoring am meisten gefährdet ist: `MTTableController.m` liest `datatable.count` bei `:377` und `:399` und leitet `hasMore = (count == limit)` bei `:455` daraus ab, sodass ein Zähler, der von der Realität abweicht, das Paging beschädigen würde. Revision 5 macht diese Ableitung zudem total — eine leere Seite wickelt `offset + count - 1` nicht mehr auf `NSUIntegerMax` (`:380`, `:402`), und der Fehlerpfad gibt `completion(NO)` (`:449`) zurück, statt einen Zähler zu lesen, der noch die *vorherige* Seite beschreibt.

Das Schreiben dieser Tests brachte einen Defekt in `-deleteAll` hervor, der nichts mit dem Zähler zu tun hatte: es übergab einen `NSString` an `-[MADQueryCacheDeleteAllFromTable initWithObject:]`, das sein Argument als Parameterwörterbuch subscriptet, sodass es beim ersten Zeilenzugriff `unrecognized selector` auslöste. `-initWithTableName:` ist der Initialisierer, der einen Namen nimmt und der eine, den `MADDatabaseSqlite3 -beginBulkInsert` bereits verwendete. Kein Aufrufer hat ihn je getroffen, weil es keinen Aufrufer gibt.

### 2.6 Zwei unzusammenhängende Persistenzmechanismen

| Mechanismus | Wo | Speichert |
|---|---|---|
| Plist, `NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`, `:135-191` | `name`, `columnKeys`, `columns` (Metadaten), `rowCounter`. **Keine Zeilen.** |
| sqlite-`.maddb`-Datei | `MADDataTableFast.m` | tatsächliche Zeilendaten plus `MADDataTableFast`-spezifische Schlüssel (`urlFastCache`, `tag`, `bulkInsertLoop`, `sortDescriptorsSet`, `groupKeyIndexes`) |

`-cacheWithUrl:error:` in der Basisklasse ist als generisches Cachen dokumentiert, serialisiert aber immer nur *Form*, nicht *Inhalt*. `MADocument.m:413-414` leitet `urlDataTableCache` aus `[self.dataTable newFilenameMDCache]` (`<tag>.mdcache`) ab, während `MADDataTableFast` `<tag>.maddb` liest und schreibt (`:340-343`). Zwei Dateiendungen, zwei Formate, zwei Besitzer, eine logische Tabelle.

**Bewertet (Revision 5) — Schritt 15, der einen Abgleich forderte. Die Rahmung ist falsch, und das ist der Befund.** „Das Basis-Plist ist nur Metadaten“ gilt für die Basisklasse und nicht für die Familie: jede Unterklasse erweitert `-copyPlist` / `-loadWithPlist:` um genau einen zusätzlichen Schlüssel, und dieser Schlüssel *ist* ihr Speicher.

| Klasse | Speicher | Plist-Schlüssel, der ihn trägt |
|---|---|---|
| `MADDataTable` | keiner (abstrakt) | `name`, `columnKeys`, `columns`, `rowCounter` |
| `MADDataTableVirtual` | `sortIndex`, ein Array von Zeilenwörterbüchern (`MADDataTableVirtual.m:106-109`, `:89-104`) | `keySortIndex` — die Zeilen selbst |
| `MADDataTableFast` | die `.maddb`-Datei | `keyUrlFastCache`, `keyTag`, … — ein *Locator* für die Zeilen |

Zeilen machen also bereits dann den Round Trip durch das Plist, wo das Plist der Speicher ist, und können es nicht, wo der Speicher eine sqlite-Datei ist. Weder die Umbenennung („nenne es Metadaten“) noch die Alternative („lege Zeilen hinein“) ist für die Familie als Ganzes richtig; die Basisklasse sind die Metadaten, die *beide* Unterklassen teilen, und der Mechanismus ist von der Konstruktion her pro Unterklasse. Die beiden Erweiterungen sind auch kein Konflikt: `MADocument` schreibt `<tag>.mdcache` (das Plist) neben `<tag>.maddb` (die Zeilen), und `-loadFromCacheWithUrl:` liest ersteres, um letzteres zu finden — sofern das Tag übereinstimmt, was es tut, weil `-filename` (`MADDocument.m:1397-1399`) `fileURL.lastPathComponent` `stringByDeletingPathExtension` ist, derselbe String, den init für das Tag hasht.

Was es wert wäre zu tun und hier nicht getan wird, ist Dokumentation statt Umstrukturierung: die beiden Dateien im Cache-Verzeichnis von `MADocument` so benennen, wie sie sind, und in `MADDataTable.h` sagen, dass `-copyPlist` die geteilten Metadaten zurückgibt und eine Unterklasse mit eigenem Speicher sie erweitern muss. Das ist eine Kommentaränderung ohne zu bewahrendes Verhalten, gehört also in einen Dokumentationsdurchgang, nicht hierher.

### 2.7 Lebensdauer des Enumerators

`MADDataTableObjectEnumerator` hält seine eigene `MADDatabaseSqlite3` + Verbindung + vorbereitete Anweisung, alles in `-initWith...` gebaut (`:60-72`) und in `-dealloc` freigegeben (`:45-49`). Daher:

* Ein Enumerator hält ein Datenbank-Handle und einen Dateideskriptor am Leben, solange er behalten wird — und `MADReportFormatter.m:449-502` hält einen für die gesamte Dauer eines Berichtsrenderings.
* Jede Tabellenmutation, die die Tabelle verwirft oder neu baut (`-removeAllObjects`, `-dropTable`), macht die aktive Anweisung in einem ausstehenden Enumerator ungültig. Nichts schützt davor.
* Jeder Aufruf von `-objectEnumerator` / `-enumeratorFor...` allokiert eine **frische Verbindung** zur selben Datei (`:1139`, `:1158`, `:1186`, `:1202`). Zweimal aufzählen öffnet sqlite zweimal.

**Bewertet (Revision 5) — Schritt 13, der ein geteiltes Verbindungspaar pro Datei forderte. Nicht erledigt, und der Grund liegt in der Lebensdauer, nicht in der Anzahl.** Die Insert-Verbindung kann überhaupt nicht geteilt werden: `MADDatabaseSqlite3 -endBulkInsert` endet mit ihrem Schließen und Nullen von `_database` (`:794-795`), weshalb `MADDataTableFast -removeAllObjects` neu öffnet, bevor es etwas verwirft, und weshalb die vier privaten Mutationen asserten, wenn sie direkt getrieben werden (es ist falsch, sie direkt zu treiben — siehe die Tests von Revision 5, die aus genau diesem Grund zuerst neu öffnen). Ein geteiltes „Paar“ müsste also eine geteilte *Lese*verbindung plus eine Schreibverbindung pro Zyklus sein, was ein gespartes Handle ist, nicht zwei.

Und die Ersparnis ist kleiner, als es aussieht: jede Verbindung hier öffnet mit `SQLITE_OPEN_SHAREDCACHE` (`MADDatabaseSqlite3.m:220`), also teilen die Enumeratoren bereits einen Seitencache und einen Satz Sperren über die Datei. Was jede Aufzählung tatsächlich kostet, ist ein `sqlite3*` und ein Dateideskriptor — real, aber nicht die duplizierten Cache-Kosten, die der Schritt impliziert.

Dagegen würde das Teilen der Lese-Verbindung etwas *verlieren*. Enumeratoren werden für die Dauer eines Berichtsrenderings gehalten (`MADReportFormatter.m:449-502`), und `-removeAllObjects` verwirft und baut die Tabelle darunter neu; heute besitzt ein ausstehender Enumerator seine Anweisung und sein Handle, sodass die beiden nur über die Datei interagieren. Ihnen ein geteiltes Handle zu geben, würde diese Interaktion in eine einzige Verbindung legen, auf einer Klasse, deren Lesevorgänge keine eigene Sperre tragen. Das zu entwerfende Szenario ist das, das §2.7 bereits markiert — ein aktiver Enumerator über einen Tabellenneubau hinweg —, und geteilte Verbindungen machen es schlechter, nicht besser. Bewusst so gelassen.

---

## 3. Öffentliche API vs. undichte Abstraktionen

### 3.1 Deklarierte Oberfläche vs. tatsächliche Implementierung

`MADDataTable.h` deklariert 30 Methoden (plus die Eigenschaften `name` / `columnKeys` / `sortDescriptors` / `columns` / `rowCounter` / `tag`, von denen das Schreibprotokoll zwei neu deklariert — siehe §4.2). Die Basisklasse implementiert 18 davon und stubbt 12:

| In `MADDataTable.h` deklariert | Basis-Impl. (`MADDataTable.m`) | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **assert** `:365` | override `:112` | override `:431` |
| `-addRow:error:` | **assert** `:369` | override `:179` | override `:504` |
| `-addRowWithDataForFieldKeys:` | **assert** `:374` | override `:197` | override `:614` |
| `-sortUsingDescriptors:` | **assert** `:378` | override `:208` | override `:634` |
| `-removeAllObjects` | **assert** `:382` | override `:225` | override `:674` |
| `-objectAtRow:column:` | **assert** `:386` | override `:159` | override `:834` |
| `-objectAtRow:` | **assert** `:391` | override `:151` | override `:848` |
| `-columnsEnumerator` | **assert** `:396` | override `:149` | override `:1123` |
| `-objectEnumerator` | **assert** `:401` | override `:148` | override `:1127` |
| `-beginBulkInsert` / `-endBulkInsert` | no-op `:408-409` | no-op `:236-238` | override `:1311`/`:1330` |
| `-allObjects` | `return @[]` `:414-417` | override `:118` | override `:1209` |
| `-objectAtRow:limit:` | `return @[]` `:419` | override `:220` | override `:1086` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | override `:122`, `:214`, `:216` | override `:1216`, `:1220`, `:1222` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | override `:140` | inherits (0) |
| `-enumeratorForAllObjectsSorted*`, `-objectsForGroupKeys:`, `-dataForRow:error:`, `-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **also** `NSAssert(NO)` `:31-54` | implemented `:1034`, `:1148`, `:1172`, `:1193`; `-dataForRow:error:` `:941` |

### 3.2 Leck 1 — die Basisklasse kann „abstrakt“ nicht ausdrücken

Objective-C hat kein `abstract`. Also gab die Basis früher **`YES` aus `-addRow:error:`** und **`nil` aus jedem Leser** zurück. Eine teilweise implementierte Unterklasse oder eine direkte `MADDataTable`-Instanz würde still Schreibvorgänge annehmen und Erfolg melden und dann nichts zurücklesen.

**Behoben (Phase 0).** Die neun Schreib-/Leseoperationen, die eine Speicher-Unterklasse überschreiben muss, öffnen jetzt mit `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` (`MADDataTable.m:365`, `:369`, `:374`, `:378`, `:382`, `:386`, `:391`, `:396`, `:401`), passend zur Gruppe `:327-350`. `-addRow:error:` gibt in Release `false` statt `true` zurück, sodass es selbst mit auskompilierten Assertions nicht mehr behauptet, eine Zeile sei gespeichert worden.

Zwei Gruppen wurden bewusst als stille Standardwerte **belassen**, weil Stille für sie richtig ist:

* `-beginBulkInsert` / `-endBulkInsert` (`:408-409`) — optionale Haken. Eine Unterklasse, die den Massenmodus nicht braucht, darf den No-op rechtmäßig erben.
* `-allObjects` (`:414-417`), `-objectAtRow:limit:` (`:419`), `-count` / `-numberOfColumns` / `-numberOfRows` (`:420-422`) und `-countByEnumeratingWithState:...` (`:423-427`) — diese geben `@[]` / `0` zurück, was die *wahrheitsgemäße* Antwort für eine Tabelle ohne Zeilen ist und zu dem passt, was `MADDataTableVirtual` zurückgibt. Auf `-count` zu asserten würde eine korrekte Antwort in einen Absturz verwandeln.

Die verbleibende Hälfte dieses Lecks — die Aufteilung im Typsystem auszudrücken statt durch Assertion — ist Phase 1 (§4.2).

### 3.3 Leck 2 — ein Nullability-Vertrag, der bereits gebrochen ist

`MADDataTable.h:65` deklariert (innerhalb von `@protocol MADDataTableCursoring`):

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m` beantwortete es früher so (`:1093-1096` vor dieser Revision):

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

Eine als `nonnull` deklarierte Methode, die auf einer Unterklasse `nil` und auf den anderen `@[]` / `[self.sortIndex copy]` zurückgibt. Jeder Aufrufer, der der Annotation vertraute, würde abstürzen — es war das einzige `FIXME` in der Familie, das einem Header-Vertrag widersprach.

**Korrigiert:** es gibt keinen Produktionsaufrufer. Die einzigen Sends an `-allObjects` auf einer Datenbanktabelle stehen in dieser Regression-Suite, und `MADDataTableRegressionTests.m` legte das `nil` absichtlich in `testFastTableBulkInsertAllObjectsIsUnimplemented` fest. Die Annotation war also eine Falle für einen künftigen Aufrufer, kein aktiver Absturz.

**Behoben:** `MADDataTableFast -allObjects` (`:1209-1214`) gibt jetzt jede Zeile über `-objectAtRow:0 limit:numberOfRows` zurück und `@[]` für eine Tabelle ohne Spalten, passend zur `nonnull`-Deklaration und zum bestehenden Verhalten von `MADDataTableVirtual` (`:118-120`). Der Test, der das `nil` festlegte, wurde durch zwei ersetzt, die den echten Vertrag prüfen.

### 3.4 Leck 3 — `-objectAtRow:column:` bedeutet pro Unterklasse Verschiedenes

Die beiden Implementierungen unterscheiden sich sowohl in der Bedeutung von `row` als auch im konsultierten Speicher:

```objc
// MADDataTableVirtual.m:159-163 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```

```objc
// MADDataTableFast.m:834-846 — reads the row dictionary, physical order
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) return nil;
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) return nil;
	return objForRow[columnMetaData.identifier];      // PHYSICAL (sqlite) order
}
```

Beachten Sie auch, dass die Grenzdisziplin abweicht: Virtual macht **keine** Grenzprüfung auf `column` (`self.columnKeys[column]` wirft `NSRangeException` bei Out-of-Bounds, gefangen nur vom `@try` in `-objectAtRow:`, nicht hier) und keine Nil-Prüfung auf `dataInColumn`; Fast macht beides.

Gleicher Selektor, zwei Semantiken. `MADMySQL` ruft dies in einer engen Schleife auf (`MADDatabaseMySQL.m:88-92` und drei weitere Stellen), also wird ein Refactoring, das die Semantik vereinheitlicht, zuerst von MySQL zu spüren sein.

### 3.5 Leck 4 — `-dataForRow:error:` ist auf einer Unterklasse implementiert und auf der anderen nicht

**Dieser Abschnitt war in der ersten Revision dieses Berichts falsch.** Er behauptete, `MADDataTableFast` implementiere `-dataForRow:error:` nicht, und der Barcode-/Druckpfad träfe daher das `NSAssert(NO)` der Basisklasse. Das ist falsch, und es schickte einen Leser auf einen falschen Pfad. Die korrigierte Analyse folgt.

`MADDataTable.h:67` deklariert
`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`
und die Basis implementiert es als `NSAssert(NO, @"Not implemented: %s")` + `return nil` (`MADDataTable.m:342-345`).

* **`MADDataTableFast` implementiert es**, bei `MADDataTableFast.m:941-1015`:

  ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```

  Es ist eine zweizeilige Signatur, was die frühere Revision falsch las: der Selektor bricht auf eine zweite Zeile um, und die zweite Zeile wurde für eine separate `-dataForRow:column:`-Überladung gehalten. (Das echte `-dataForRow:column:error:` ist eine andere Methode bei `:866-932`.) Die Implementierung ist real, und die Regression-Suite deckt sie bereits ab — `MADDataTableRegressionTests.m` `testFastTableDataForRowReturnsValues` und `testFastTableDataForRowCachesLastRow` senden beide den Zweiparameter-Selektor an ein aktives `MADDataTableFast` und bestehen.

* **`MADDataTableVirtual` implementiert keine der beiden Formen.** Es hat einen `-dataForRow:`-Stub bei `:41-44`, aber dieser Stub ist `NSAssert(NO, @"Not implemented: %s")` + `return nil` — er ist keine funktionierende Überladung und im Header `MADDataTableVirtual.h` nicht deklariert. Die Zweiparameter-Form fällt zur assertenden Basis durch. Die In-Memory-Unterklasse hat also überhaupt keinen Zeilen-für-ID-Zugriff.

Die Aufrufstellen sind daher nicht gefährdet: `MADocument.m:875/880/919` dispatcht an `MADocument.dataTable`, das sowohl statisch als auch tatsächlich ein `MADDataTableFast` ist (`MADocument.m:159`, allokiert bei `:230` und `:288`). Die Pfade `MADPrintPageElement.m:80` und `MADPrintPageElementBarcode.m:30` erreichen dasselbe Objekt. Nichts auf einem aktiven Pfad assertet.

Der echte Defekt ist enger und jetzt behoben: weil `MADDataTableVirtual` den Selektor nie implementierte, hätte jeder künftige Aufrufer, der einen `MADDataTable *` hält, der zufällig eine Virtual-Tabelle ist, in Debug assertet und in Release still `nil` erhalten. `MADDataTableVirtual` implementiert `-dataForRow:error:` jetzt, indem es an `-objectAtRow:` delegiert und den Außerbereichsfall über den Fehlerzeiger meldet.

Die Implementierung von `MADDataTableFast` hatte ebenfalls einen echten Defekt, jetzt behoben: ihr `if (sqlite3_prepare == SQLITE_OK)` hatte **kein `else`**, also gab ein Prepare-Fehler `nil` zurück, ohne `*outError` zu setzen, und der `-getSql:`-Fehler wurde verworfen. Ihr Geschwister `-dataForRow:column:error:` (`:905-932`) behandelt beides korrekt. Das SQL wurde zudem als *Format*string an `sqlite3_mprintf` übergeben (`sqlite3_mprintf((char *) sql.UTF8String)`), was SQL mit `%` verstümmelt oder zum Absturz bringt; jetzt ist es `sqlite3_mprintf("%s", ...)`, passend zum Geschwister bei `:901`. Acht weitere Stellen in `MADSqlite3` hatten denselben Defekt; alle sind jetzt behoben — siehe §4.5.

### 3.6 Leck 5 — `MADDataTableFast` greift in das private Ivy einer anderen Klasse

`MADDataTableFast.m` greift an fünfzehn Stellen direkt auf das private Ivy `_database` von `MADDatabaseSqlite3` zu — `:488`, `:538`, `:784`, `:793`, `:810`, `:829` (über `_databaseForInserts`) und `:905`, `:976`, `:1065`, `:1078`, `:1106`, `:1108`, `:1248`, `:1251`, `:1261` (über `databaseForSelects`):

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```

Das umgeht die API von `MADDatabaseSqlite3` vollständig und ist der Grund, warum `MADDataTableFast` eine echte sqlite-Datei braucht, um überhaupt etwas zu tun. Es ist auch der Grund, warum das Testtarget die Modulimportarbeit von `MADDataTable+Constructor` brauchte: die Klassenfamilie ist nur aus Code nutzbar, der beide Frameworks zusammen linkt.

### 3.7 Leck 6 — tote öffentliche API — **entfernt (Revision 5)**

`MADDataTableLocation` (`MAD/Source/MADDataTableLocation.{h,m}`, 67 Zeilen) war ein `(row, column)`-Wertobjekt mit `NSCoding` und einer Fabrik `+newDataTableLocationForRow:inColumn:`. Ich habe die ganze Codebasis außer ihrer eigenen Implementierung gegrept: **ihre einzigen Verweise standen in der Regression-Testdatei.** Sie war produktiv tot. Sie adoptierte zudem `NSCoding`, aber nicht `NSSecureCoding`, was die Regression-Suite als Vertrag festhielt.

Phase 5 Schritt 14 bot eine Wahl — in eine Funktion einbinden oder löschen. Sie ist gelöscht, weil es keine Funktion gab, auf die sie wartete: ein Commit in ihrer ganzen Geschichte (`e702bb062`, die Neuorganisation des Frameworks `MAD`), kein Aufrufer und nichts außer ihren eigenen drei Tests, die beschrieben, wofür sie war. Eine Klasse, die nur von ihren Tests am Leben gehalten wird, ist eine Klasse, für die die Tests doppelt zahlen. Die Dateien, ihre zwei Build-Einträge in `.pbxproj` und die drei Tests sind mit ihr verschwunden; §3.7 bleibt als Leck 6 statt umnummeriert zu werden, sodass die Nummerierung, die der Rest des Berichts zitiert, gilt.

### 3.8 Leck 7 — die Tabelle greift *zurück* in die Schreibabfrage

`MADDataTableFast` konformiert privat mit vier Protokollen (`:71`):

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

und implementiert `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData` (`:419-430`) rein, damit `MADQueryCacheAddRow` den Zustand aus der Tabelle zurückziehen kann, in die es schreibt. Der Insert-Pfad ist daher ein Zyklus: Tabelle → Abfrageobjekt → zurück in die Tabelle. Beachten Sie das Namenskollisionsrisiko — `-queryRowData` (`:428`) und die private Eigenschaft `_rowDataLastInserted` haben nichts mit der öffentlichen `-dataForRow:`-Familie zu tun.

### 3.9 Was *nicht* undicht ist (diese bewahren)

* Die gesamte Unterklassenauswahl ist in `MADDataTable+Constructor.m:51-69`.
* Der Schreibport sind fünf Basisklassenmethoden (§1.4).
* Enumeratorklassen sind privat in `MADSqlite3` und treten nur als `NSEnumerator *` an die Oberfläche.
* `MADReportFormatter.m:463-472` toleriert bereits die Aufzählung nur mit Zeilen-IDs.
* `MADArrayCaching` (`MADSqlite3`) ist in dieser Codebasis Vorbild für eine Caching-Abstraktion mit einer engeren, protokollförmigen Oberfläche.
* Kein Runtime-Klassen-Sniffing auf Tabellen irgendwo.

---

## 4. Entkopplungs- und Refactoring-Strategie

Das Ziel ist, `MADDataTable` zu einer *stabilen Schnittstelle* über austauschbaren Speicher- und Zugriffsstrategien zu machen, ohne das Verhalten zu ändern, auf das sich die fünf Treiber und vier Konsumenten bereits verlassen.

### 4.1 Zielform

Die Klassennamen behalten (sie sind in `NSCoding`-Archive und Core Data eingebacken), aber die Variation hinter zwei Protokolle verschieben, die die Konstruktoren zurückgeben:

```
                    ┌─────────────────────────────────────┐
                    │  MADDataTable        (concrete base) │
                    │  metadata, plist persistence,        │
                    │  NSCoding, — no-op defaults removed   │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴───────────────────────────┐
        │                                                       │
  MADDataTableVirtual                                   MADDataTableFast
  (unchanged semantics)                          (sqlite; owns a connection pair)

  Both conform to:
     <MADDataTableWriting>   removeAllObjects / addColumn: /
                             begin|endBulkInsert /
                             addRowWithDataForFieldKeys:
     <MADDataTableReading>   objectAtRow: / objectAtRow:column: /
                             count / numberOfRows
     <MADDataTableCursoring> enumeratorForKeyObjectsSorted /
                             enumeratorForAllObjectsSorted /
                             enumeratorForAllObjectsSortedRowIdOnly
```

`MADDatabaseSqlite3.m:474-540` und `MADDatabaseSQLServer.m:500-1472` sollten `id <MADDataTableWriting>` statt `MADDataTable *` nehmen. Das allein entfernt die Gefahr „die Basisklasse gibt YES aus einem Schreibvorgang zurück, den ich verwarf“ aus jedem Treiber.

### 4.2 Geplanter Ablauf

**Phase 0 — die Fehlermodi laut machen (keine Verhaltensänderung).**
1. **Erledigt**, mit engerem Umfang als zuerst vorgeschlagen. Die neun Operationen, die eine Speicher-Unterklasse überschreiben muss, asserten jetzt (`MADDataTable.m:365-403`); die ehrlichen Leere-Tabelle-Antworten und die optionalen Massen-Haken blieben als Standardwerte, weil für sie der stille Wert der *richtige* ist. Siehe §3.2 für die Aufteilung und die Begründung sowie `MADDataTableRegressionTests.m` `testBaseTableAbstractOperationsAssert` für den Vertrag.
2. **Nicht nötig — siehe §3.5.** Der ursprüngliche Text hier sagte, `MADDataTableFast -dataForRow:error:` zu implementieren, weil es „derzeit assertet“. Es assertet nicht; die Methode ist bei `:941-1015` implementiert, und die frühere Lesung verwechselte eine zweizeilige Signatur mit einer `column:`-Überladung. Die Unterklasse, der der Selektor wirklich fehlte, ist `MADDataTableVirtual`, und sie implementiert ihn jetzt, indem sie an `-objectAtRow:` delegiert.
3. **Erledigt.** `-allObjects` (§3.3) war eine `nonnull`-Methode, die auf `MADDataTableFast` `nil` zurückgab; sie gibt jetzt die Zeilen zurück. Im selben Durchgang erhielt `MADDataTableFast -dataForRow:error:` das fehlende `else` an seiner Prepare-Prüfung und verwirft nicht mehr den `-getSql:`-Fehler oder übergibt SQL als Formatstring an `sqlite3_mprintf`.
4. Gegen die bestehende Regression-Suite (`MADDataTableRegressionTests.m`) erneut verifizieren — sie legt bereits Instanziierung, Aufzählung und Nebenläufigkeit fest, also erkennt sie hier einen Fehler. (Sie legte auch den `MADDataTableLocation`-Vertrag fest, bis Revision 5 die Klasse löschte.)

**Phase 1 — die Protokolle deklarieren.**

5. **Erledigt — der Stub-Block wurde bewusst behalten.** Die drei Protokolle sind in `MADFoundation/Source/MADDataTable.h` über dem `@interface` deklariert, das jetzt `MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting, MADDataTableReading, MADDataTableCursoring>` lautet, und die dreißig flachen Methodendeklarationen, die früher im `@interface`-Körper standen, sind daraus verschwunden. Die Aufteilung ist nach Achse: **Writing** ist die mutierbare Oberfläche (`removeAllObjects`, `addColumn:`, `addRow:error:`, `addRowWithDataForFieldKeys:`, `sortUsingDescriptors:` plus `@optional` `beginBulkInsert`/`endBulkInsert`); **Reading** ist Wahlzugriff und die Zählungen; **Cursoring** ist Aufzählung, mit den drei sortierten Enumeratoren und `objectsForGroupKeys:` `@optional`, weil `MADDataTableVirtual` sie wirklich nicht bedienen kann.

   Der „den nun redundanten Stub-Block löschen“-Teil des Plans wurde **nicht** ausgeführt, weil beide Stub-Blöcke festgelegte Verträge sind, nicht Redundanz: `testBaseTableAbstractOperationsAssert` verlangt, dass die neun assertenden Stubs der Basisklasse existieren und werfen, und `testVirtualTableDoesNotImplementSortedEnumerators` behauptet, dass `-respondsToSelector:` für die vier sqlite-only-Selektoren auf `MADDataTableVirtual` **YES** ist. Beide zu löschen hätte einen gefangenen Defekt in einen Unrecognized-Selector-Absturz verwandelt und einen Test gebrochen, der genau das verhindern soll. `MADDataTable` erfüllt die `@required`-Mitglieder der Protokolle durch Asserten, was Phase 0 dorthin setzte.

6. **Erledigt (Revision 4) — alle drei Treiber und das Protokoll.** Der Block unten ist Revision 3s Darstellung, warum dies blockiert war; er ist für die Aufzeichnung behalten. Die Entblockung, die er identifizierte, wurde genommen: die Spaltenmetadaten, die `MADMySQLFetch+DataTable.m` braucht (`columns`, `columnKeys`), werden jetzt von `<MADDataTableWriting>` selbst deklariert, also ist der Schreibport auch für MySQL ausreichend. Die beiden Methoden `fetchWithCommand:dataTable:...` von `MADMySQLFetch` und sein privates `-fetchResultsFromConnection:intoDataTable:...` nehmen `id <MADDataTableWriting>` by value und geben dieselbe Tabelle zurück (`(MADDataTable *)dataTable`); alle 11 Aufrufstellen in `MADDatabaseMySQL.m` und die 7 in `MADMySQLLiveTests.m` ließen ihr `&` fallen. Die Metadaten wurden auf das Schreibprotokoll gelegt statt auf ein viertes, weil MySQL sie *beim Schreiben* liest — es korrigiert den Typ einer Spalte in der ersten Zeile —, und weil jeder Konformant sie gratis von der Basisklasse bekommt. §2.5s `// FIXME: This is a hack.` ist unberührt.

   *Revision-3-Text, für die Aufzeichnung:* **teilweise erledigt — zwei von drei Treibern, und die Protokolldeklaration bewusst nicht verengt.** `MADDatabaseSqlite3` (`executeSQL:...intoResultTable:`, `executeQuery:withDataTable:andError:`, `executeQuery:withError:`) und `MADDatabaseSQLServer` (dieselben zwei plus das private `-runQuery:onProcess:withDataTable:` und `-runSQL:onDataTable:fieldKeys:process:`) nehmen jetzt `id <MADDataTableWriting>`. Beide sind wirklich rein schreibend: ein `grep` danach, was sie an die Tabelle senden, liefert genau den Fünf-Aufruf-Port und nichts anderes.

   **`MADDatabaseMySQL` kann noch nicht verengt werden**, und ebenso wenig `MADAPI/Source/MADDatabaseProtocol.h:28-31`. Das Hindernis liegt nicht im Treiber — es liegt in `MADMySQLFetch+DataTable.m`, das `(*dataTable).columns` und `.columnKeys` liest, *während* es die Tabelle füllt, um den Typ einer Spalte zu korrigieren, sobald es die erste Zeile sieht (`:301` und `:321`, unter dem bestehenden `// FIXME: This is a hack.` bei `:297`). Ein Schreibport, der die Spaltenmetadaten nicht offenlegt, ist für diesen Pfad also nicht ausreichend. Da `MADDatabaseMySQL` `MADDatabaseDataSource` erfüllt und weiterhin erfüllen muss, hätte das Verengen des Protokolls es etwas versprechen lassen, was seine eigene Implementierung nicht halten kann — ein entfernter Absturz für den nächsten Aufrufer, kein Compilierfehler. Beide Deklarationen tragen einen Kommentar, der hierher verweist.

   **Die konkrete Entblockung, beim Prüfen gefunden:** `MADMySQLFetch+DataTable.m` weist nie durch seine `MADDataTable * __autoreleasing *`-Out-Parameter zu — `grep -n '\*dataTable *=' MADMySQL/Source/MADMySQLFetch+DataTable.m` liefert nichts. Der Zeiger ist ein In-Parameter, von dem die Aufrufer nie erfuhren. Ihn by-value zu machen (`dataTable:(id <MADDataTableWriting>)dataTable`) entfernt das Zeigertyp-Problem vollständig und lässt die 11 Aufrufstellen in `MADDatabaseMySQL.m` ihr `&` fallen. Das plus das Hinzufügen der Spaltenmetadaten-Accessoren zu `<MADDataTableWriting>` oder einem vierten Protokoll ist alles, was für MySQL bleibt. Es ist zurückgestellt statt gebündelt, weil §4.3 MySQL bereits als risikoreichsten Konsumenten einstuft und die Änderung mechanisch genug ist, um für sich geprüft zu werden.

7. **Jetzt möglich für sqlite, unbewiesen für MySQL.** Die Zeilenschleife von `MADDatabaseSqlite3` kann von jedem Objekt getrieben werden, das `<MADDataTableWriting>` erfüllt, ohne `.maddb`-Datei und ohne App-Delegaten, da der Parameter nicht mehr die Klasse `MADDataTable` impliziert — und durch sie die `-urlFastCache`-Abhängigkeit von `[MADApplication AppDelegate]`, die in §2.3 beschrieben ist. Noch wurde kein solcher Mock-Test geschrieben; er ist der natürliche nächste Schritt und das Erste, was das injizierte Cache-Verzeichnis von Phase 2 billiger macht.
   **Revision 4:** die hostlose Hälfte ist bewiesen — `testFastTableInitWithCacheDirectoryNeedsNoDelegate` baut eine funktionierende physische Tabelle mit einem Verzeichnis und ohne Delegaten.
   **Revision 5: erledigt, beide Hälften.** `testDriverFillsAWritePortWithNoDataTableBehindIt` (`MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`) übergibt der Zeilenschleife einen `MADWritePortRecorder` — ein `NSObject`, das `<MADDataTableWriting>` und sonst nichts erfüllt, also kein `MADDataTable`, kein `MADDataTableFast`, keinen Cache-Delegaten, keine `.maddb` — und prüft, dass die fünf Aufrufe in der versprochenen Reihenfolge mit beiden Zeilen intakt ankommen und scheitert, falls eine `.maddb`-Datei erscheint. Der Mock ist nur ausdrückbar, weil der Parameter das Protokoll ist.

**Phase 2 — die Mehrdeutigkeit des Speicherorts entfernen. ERLEDIGT (Revision 4).**
8. ✅ `urlFastCache` gespeichert statt berechnet machen (§2.3). Einmal in `_urlFastCache` aufgelöst; ein Delegatenwechsel verwirft es in `-setCacheDelegate:` vor dem erneuten Öffnen, sodass die Auflösung immer gegen den aktuellen Delegaten erfolgt.
9. ✅ Das Cache-Verzeichnis injizieren, statt im Inneren der Eigenschaft nach `[MADApplication AppDelegate]` zu greifen. `-initWithId:cacheDirectory:` und `+newDataTableOfType:withObjectID:cacheDirectory:` tragen es; `nil` behält die alte Kette. `testFastTableInitWithCacheDirectoryNeedsNoDelegate` baut, füllt und liest eine physische Tabelle ganz ohne Delegaten.

**Phase 3 — `rowCounter` abgeleitet machen.**
10. ✅ Ein privates, auf `SELECT COUNT(*)` gestütztes `-recountRows` hinzufügen und `-numberOfRows`/`-count` es verwenden lassen (oder dagegen invalidieren) auf `MADDataTableFast`. Die Eigenschaft `rowCounter` für die Archivkompatibilität behalten, aber aufhören, sie als Wahrheitsquelle zu behandeln (§2.5).
    **Revision 4:** `-recountRows` existiert und läuft am Ende von `-loadWithPlist:`, sodass eine neu geladene Tabelle keinen Zähler mehr tragen kann, der ihrer Datei widerspricht.
    **Revision 5:** die In-Memory-Hälfte ist geschlossen — die vier Mutationen, die den Zähler nie berührten, hinterlassen ihn jetzt als Beschreibung der Datei (§2.5). `-numberOfRows`/`-count` geben weiterhin per Design das Ivy zurück; das ist jetzt der einzige Leser, und `-recountRows` bewacht das Neuladen. Vier Tests decken die vier Methoden ab.
11. ✅ `MTTableController.m` prüfen (war `:375/395/440/445`) — Paging darf keinen Zähler lesen, der von der Datei abweichen kann. **Erledigt (Revision 5)**, und es kann nicht, sobald der Zähler ehrlich ist: jeder Fetch beginnt bei `-removeAllObjects`, das die Tabelle leert und den Zähler nullt, sodass die Zählung bei Abschluss die gerade geschriebene Seite misst und nichts anderes. Zwei Defekte an genau diesen Zeilen wurden trotzdem gefunden und behoben. `offset + count - 1` wickelte auf einer leeren Seite bei `:380`/`:402` auf `NSUIntegerMax`; und der Fehlerpfad bei `:449` las den Zähler aus einer Tabelle, die der Treiber *nicht* geleert hatte (er leert nur bei Erfolg), also maß er die vorherige Seite, und ein gescheiterter Fetch meldete `hasMore = YES` und erneuerte sich selbst. Eine gescheiterte Seite meldet jetzt „keine mehr“.

**Phase 4 — Nebenläufigkeit beheben.**
12. ✅ `-addRow:error:` auf `queueBulkAdd` serialisieren (§2.4). Die Warteschlange existiert bereits und wird bereits für `-endBulkInsert` verwendet; sie auf den Mutationspfad auszudehnen ist eine kleine, enthaltene Änderung. Das `sqlite3_finalize(_statementInsert)` in `-endBulkInsert` *in* die Barriere verschieben, damit die gecachte Anweisung nur abgebaut wird, wenn kein `-addRow:` läuft.
    **Erledigt (Revision 4)** — der Abbau ist jetzt das Erste innerhalb des `dispatch_barrier_sync` bei `:1334`.
13. **Bewertet und abgelehnt (Revision 5)** — ein geteiltes Verbindungspaar pro Datei statt pro Tabelleninstanz, da `-objectEnumerator` derzeit bei jedem Aufruf eine neue Verbindung öffnet (§2.7). Teilen ist für die Schreibhälfte nicht verfügbar (`-endBulkInsert` schließt dieses Handle) und bringt für die Lesehälfte fast nichts (`SQLITE_OPEN_SHAREDCACHE` teilt den Cache bereits), während es den Fall „aktiver Enumerator über einen Neubau hinweg“ schlechter statt besser macht. §2.7 enthält das vollständige Argument.

**Phase 5 — die tote Oberfläche ausmustern.**
14. ✅ `MADDataTableLocation` (§3.7) und seine drei Tests löschen oder in eine echte Funktion einbinden. Es ist derzeit öffentliche API ohne Produktionsaufrufer. **Entfernt in Revision 5** — gelöscht statt eingebunden, weil es einen Commit in seiner Geschichte und nichts außer seinen eigenen Tests hat, die es beschreiben. Die Header- und Sources-Phasen des MAD-Targets lassen die beiden Dateien mit ihm fallen.
15. **Bewertet (Revision 5)** — die beiden Persistenzmechanismen abgleichen (§2.6). Die Prämisse hält für die Familie nicht: die Zeilen machen *doch* den Round Trip durch das Plist, wo das Plist der Speicher ist (`keySortIndex` von `MADDataTableVirtual`), und können es nicht, wo er eine sqlite-Datei ist (`keyUrlFastCache` von `MADDataTableFast`), also ist weder die Umbenennung noch die Alternative richtig. §2.6 hält die Tabelle pro Unterklasse und die verbleibende Dokumentationsänderung fest.

### 4.3 Bruchrisiko-Rangfolge für die aktuellen Konsumenten

| Konsument | Stelle | Risiko unter Refactoring |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :377, :393, :399, :449, :455` | **Hoch** — behandelt `count` als Seiten-Cursor; jede Änderung der `rowCounter`-Semantik bricht das Paging. Revision 5 machte die Ableitung total — eine leere Seite läuft nicht mehr unter und ein gescheiterter Fetch liest nicht mehr den Zähler der vorherigen Seite (§2.5) —, aber die Kopplung ist unverändert |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **Hoch** — O(n)-`objectAtRow:i column:0`; die `row`-Semantik pro Unterklasse muss zuerst vereinheitlicht werden |
| `MADocument` | `:197` (`rowCounter`), `:865-867` (Enumerator), `:874-919` (`dataForRow:error:`), `:1053-1072` | **Hoch** — aber nur für den Enumerator und `rowCounter`. Seine `-dataForRow:error:`-Sends lösen auf `MADDataTableFast` auf, das den Selektor implementiert, also ist der Druck-/Barcode-Pfad solide (siehe §3.5) |
| `MADMySQLFetch+DataTable` | `:301, :321` | **Mittel** — mutiert `column.type` mitten im Fetch hinter `// FIXME: This is a hack.` (`:297`); das Spaltenwörterbuch muss öffentlich mutierbar bleiben |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **Niedrig** — einzelne `objectAtRow:0`-Breitenprobe |
| `MADReportFormatter` | `:449-502` | **Niedrig** — tolerant gegenüber Aufzählung nach Zeilen-ID und nach Wörterbuch |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **Niedrig** — rein schreibend über den Fünf-Methoden-Port |

### 4.4 Einzuhaltende Einschränkungen

* **Die Rohwerte von `MADDataTableType` nicht ändern.** `MADDataTableParametersType` wird in Definitionswörterbücher kodiert (`MTTableController.m:91`, `MTTableViewControllerBarcodeExtraMaxicode.m:104`), und das Enum wird über `initWithShort:` serialisiert.
* **Die Klassen nicht umbenennen.** `MADDataTableFast`-Archive tragen Schlüssel im Stil von `[MADDataTableFast keyTag]` (`:114-119`), und `MADDataTableVirtual` trägt `keySortIndex` (`:202`) in bestehende `.mdcache`/`.maddb`-Dateien.
* **Den Fünf-Methoden-Schreibport behalten.** Alle drei Treiber hängen von der exakten Sequenz `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert` ab.
* **Kein Klassen-Sniffing eingeführt.** Das bewahren: jeder neue Zweig sollte auf einem Protokoll oder einem Enum sein, nie auf einer Klasse.

### 4.5 SQL als Formatstring an `sqlite3_mprintf` übergeben

Beim Beheben von §3.5 gefunden. Acht weitere Aufrufstellen übergaben eine Variable an `sqlite3_mprintf` als *Format*string statt als Argument. Jedes `%` im SQL würde dann als Konversion gelesen, sodass eine Abfrage, die eines enthält, verstümmelt wird — oder über die Argumentliste hinausliest und abstürzt.

**Behoben.** Alle acht übergeben jetzt ein literales `"%s"` und das SQL als Argument, passend zu den Stellen, die bereits korrekt waren:

| Datei | Stellen |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1062`, `:1102`, `:1245` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`, `:397`, `:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

Die bereits korrekten Referenzstellen waren `MADDataTableFast.m:548`, `:901` und `:973` sowie `MADDatabaseSqlite3.m:459`. Jeder `sqlite3_mprintf`-Aufruf in `MADSqlite3` verwendet jetzt entweder ein literales `"%s"` oder einen literalen Formatstring ohne Konversionen — `grep -n sqlite3_mprintf MADSqlite3/Source/*.m` liefert vierzehn Aufrufe und keine variablen Formatstrings.

Die Erreichbarkeit war gering: das SQL kommt aus den generierten Abfrage-Buildern, und eine repositoryweite Suche fand kein `LIKE`-Muster, das ein `%` einführen würde. Kennungen hingegen kommen aus dem Schema der verbundenen Datenbank, also hätte ein `%` in einem Spalten- oder Tabellennamen dies getroffen. Es war ein latenter Korrektheitsfehler statt eines aktiven — behoben, weil die Änderung mechanisch ist und die Folge eines Fehlers stille Korruption ist.

---

## Anhang — untersuchte Dateien

| Datei | Zeilen |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 123 / 435 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 240 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`, `MADDataProtocol.h`, `MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 47 / 1355 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | 1346 |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 30 / 94 |
| `MAD/Source/MADocument.m`, `MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`, `MADMySQLFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`, `MADQuery.h`, `MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 69 tests |
