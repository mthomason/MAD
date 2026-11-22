---
layout: default
lang: de-DE
title: "Berichte mit mehreren Quellen"
description: "Berichte als Tabellen und Treiber für alles, was eine Tabelle zurückgibt."
---

# Berichte mit mehreren Quellen — Berichte als Tabellen und Treiber für alles

Diese Seite beschreibt kombinierbare Berichte: das Ergebnis eines Berichts wird eine Tabelle, die ein anderer Bericht abfragen kann, und ein Treiber kann alles fronten, was Zeilen zurückgibt. Es ist eine Designaufzeichnung; §8 benennt die Phasen, und nicht alle sind gebaut.

**Umfang:** die Architektur, die der Benutzer am 2026-11-22 beschrieb: ein Benutzer entwirft einen Bericht gegen eine Datenquelle (MySQL, SQL Server, PostgreSQL, SQLite oder eine Web-API wie die Seller API von eBay); das Ergebnis dieses Berichts ist eine materialisierte SQLite-Tabelle; und ein anderer Bericht kann eine Abfrage gegen diesen Bericht entwerfen — die Ausgabe eines Berichts mit der Ausgabe eines anderen Berichts und mit Basisquellen in einem Abfragegraphen joinen. Beim Refresh durchläuft die Engine den Graphen von unten nach oben, führt jedes Blatt gegen seine eigene Quelle aus, materialisiert jedes Ergebnis und führt schließlich die komponierende Abfrage über die Materialisierungen aus. Die Naht für Nicht-SQL-Treiber ist Teil davon: ein Treiber, der eine API frontet, erhält eine strukturierte Abfrage, keinen SQL-Text, und gibt Zeilen in Tabellenform zurück.
**Datum:** 2026-11-22, gelesen bei `eba4225a1`; Entscheidungen eingearbeitet am 2026-11-22 (§9.2).
**Status:** Designbericht. Er legt die Idee und das Design dar; er implementiert nichts und fügt `TASKS.md` keine Arbeit hinzu. Der Code-Audit, der die Datenobjekt-Hälfte begründet, ist [`MAD_DATA_OBJECT.md`](data-object.md); die Richtung ist [`docs/vision.md`](../vision.md). Dieses Dokument fügt das Kompositionsmodell für mehrere Quellen hinzu (zuerst Unterberichte innerhalb eines Dokuments), die Treiber-API, die Nicht-SQL-Quellen erstklassig macht, und eine kombinierte Phasenreihenfolge.

---

## 1. Die Idee, auf einer Seite

Ein Bericht ist eine Funktion von Datenquellen auf eine Tabelle. Die Unterscheidung zwischen Definition und Ergebnis, die für dieses Design zählt, steht bereits im Code:

- Die **Definition** ist der Abfragegraph — Tabellen, Felder, Links, Prädikate, Gruppierungen — plus das bandbasierte Layout. Sie lebt im `.mad`-Archiv.
- Das **Ergebnis** ist ein Schema (`MADDataColumn`s) und Zeilen. Es lebt neben dem Dokument in einem begleitenden SQLite-Cache (`.maddb` + `.mdcache`), außerhalb des Archivs, weil es abgeleitet und regenerierbar ist.

Die Erweiterung besteht darin, das Ergebnis **als Tabelle adressierbar** zu machen. Die Ausgabe eines Berichts wird dann eine Quelle für einen anderen Bericht, genau wie eine Schematabelle heute eine Quelle ist. Ein Bericht, der auf Berichten aufbaut, ist ein DAG abgeleiteter Tabellen: eine portable semantische Schicht, in der einen Bericht zu entwerfen auch heißt, eine wiederverwendbare Datenquelle zu entwerfen.

Dieselbe Erweiterung macht Berichte mit mehreren Quellen natürlich. Jedes Quellobjekt führt gegen seine eigene Datenbank oder API aus, mit seinem eigenen Treiber und eigenen Zugangsdaten, und materialisiert in seine eigene SQLite-Tabelle. Das komponierende Objekt führt gegen den **lokalen Cache** aus, nicht gegen einen entfernten Server, und joint die Materialisierungen. Es wird keine Föderations-Engine hinzugefügt; die Snapshots sind die Föderation.

Das Beispiel des Benutzers: ein Unternehmen möchte einen Bericht über seine eBay-Angebote. Ein Berichtsobjekt fragt die eBay Seller API ab und materialisiert die Angebote; ein anderes fragt die MySQL-Datenbank des Unternehmens nach Verkäufen ab; ein komponierender Bericht joint die beiden Ausgaben über SKU. Jeder Treiber kennt nur seine eigene Quelle. Der Join geschieht in SQLite, lokal.

Der Nicht-SQL-Treiber ist es, der das erste Objekt möglich macht. Sein Vertrag ist derselbe „Schema plus Zeilen“-Vertrag, den die SQL-Treiber erfüllen — aber seine Eingabe sollte der Abfragegraph sein, kein SQL-String, den er parsen muss.

## 2. Was im Code bereits wahr ist

Die teuren Teile existieren. `MAD_DATA_OBJECT.md` §3 ist der ausführliche Audit; die tragenden Fakten für diesen Bericht sind:

1. **Die Definition ist ein Graph, und der Speicher erlaubt viele.** `RptqQuery` besitzt Tabellen, Felder, Links, Prädikate und Gruppen. `MADModelDocument` baut ein `MADModelDatabase` pro `RptqQuery`, mit der eigenen Anmerkung des Codes, dass aktuelle Versionen eines verwenden. Die Kardinalität ist eine Konvention der Abläufe der App, nicht des Speichers (`MAD_DATA_OBJECT.md` §3.1).
2. **Der Compiler existiert und ist deterministisch.** `MADQueryFull -copySQLWithManagedObjectContext:error:` (`MAD/Source/MADQueryFull.m:133-273`) baut die SELECT-Liste, den FROM/JOIN-Baum aus einem topologisch sortierten Graphen, die WHERE-Klausel und das Limit, über die Dialekt-Haken des Treibers.
3. **Die Ausführungsnaht ist bereits tabellenförmig.** Der abstrakte Punkt von `MADDatabase` ist `executeSQL:fieldKeys:onConnection:intoResultTable:withError:` (`MADAPI/Source/MADDatabaseProtocol.h:33-34`), und das Ziel ist jedes `id <MADDataTableWriting>`, keine konkrete Tabellenklasse. Alle vier Treiber füllen es auf dieselbe Weise: alle Objekte entfernen, Spalten hinzufügen, massenhaft einfügen, Zeilen hinzufügen.
4. **Die Materialisierung ist eine echte SQLite-Tabelle.** `MADDataTableFast` schreibt `<tag>.maddb` und die Tabelle `t<tag>` (`MADSqlite3/Source/MADDataTableFast.m:403-406`, `:463-467`, `:503-511`). Das Schema-Plist ist `.mdcache`; Zeilen und Schema sind trennbar (`docs/05-companion-files.md` §5). SQLite ist bereits ein Treiber (`MADSqlite3/Source/MADDatabaseSqlite3.m`), also ist eine Abfrage, deren „Datenbank“ der Cache ist, heutiger Code, kein neuer Code.
5. **Der Cache ist entbehrlich und pro Gerät.** Er ist nicht im Dokument und nicht in iCloud (`docs/05-companion-files.md` §5.2). Das ist richtig für ein abgeleitetes Artefakt, aber es ist eine Einschränkung für jedes Design, das den Cache eines anderen Berichts als Quelle behandelt: der Cache ist vielleicht nicht da.

Derselbe Abschnitt benennt die drei Festverdrahtungspunkte der einen Abfrage, und sie gelten heute noch:

- `MADQueryFull` liest die erste Datenbank und die erste Abfrage des Dokuments neu, statt die Abfrage zu verwenden, mit der es initialisiert wurde (`MAD/Source/MADQueryFull.m:147-149`).
- `MADocument -dataTableForQuery:` ist ein Ein-Slot-Schalter: es gibt die eine Tabelle des Dokuments für `MADQueryFull` und nil für alles andere zurück (`MAD/Source/MADocument.m:873-880`).
- `MADQueryActiveQueryFields` durchsucht jedes Element, jeden Link und jede Gruppe im Speicher ohne Abfragebereich (`MAD/Source/MADQueryActiveQueryFields.m:27-100`). Die Felder einer zweiten Abfrage würden in die SELECT-Liste der ersten Abfrage lecken.

Zwei weitere Fakten zählen für das Kompositionsdesign:

- **Die Adresse ist der Dateinamen-Hash.** Das Dokument erzeugt seine Tabelle mit `initWithId: self.fileURL.lastPathComponent.hash` (`MAD/Source/MADocument.m:273-275`), und das Cache-Verzeichnis wird nach diesem Hash benannt. Nichts kann die Tabelle über eine stabile Identität adressieren.
- **Ein `MADDataTableFast` ist eine Datei.** `filenameCacheMadDB` ist `<tag>.maddb` (`MADSqlite3/Source/MADDataTableFast.m:403-406`), und jede Instanz öffnet ihre eigenen Einfüge- und Auswahlverbindungen (`:482-501`). Es gibt heute keinen Modus „mehrere Tabellen in einer `.maddb`“. `MAD_DATA_OBJECT.md` §5.1 beschreibt diesen Modus als Designvariante; die aktuelle Klasse implementiert ihn nicht.
- **Es gibt keine `ATTACH`-Unterstützung.** Eine Suche in `MADSqlite3`, `MAD` und `CLI` findet keine Verwendung von `ATTACH DATABASE`. Dateiübergreifende Komposition braucht sie als Ergänzung oder einen Hineinkopierschritt.

## 3. Das Kompositionsmodell

### 3.1 Knoten und Kanten

- Ein **Quellobjekt** besitzt eine `RptqDatabase` (Treiber + Verbindung + Zugangsdaten) und eine Abfragedefinition. Es wird gegen seine Quelle ausgeführt.
- Ein **komponierendes Objekt** besitzt eine Abfrage, deren Tabellen andere Datenobjekte sind (Quelle oder komponierend). Es wird gegen den lokalen Cache ausgeführt. Ein komponierendes Objekt besitzt in diesem Design keine entfernte Quelle: eine entfernte Tabelle, die es braucht, ist ein **Quellobjekt**, auf dessen Ausgabe es verweist. Das hält die Knotentaxonomie auf zwei Arten — entfernte Blätter und lokale Komponisten — und hält den Refresh-Durchlauf ehrlich.
- Eine **Kante** ist ein Tabellenverweis in einer komponierenden Abfrage auf das Ausgabeschema eines anderen Objekts.
- Der Graph muss azyklisch sein. Ein Zyklus ist ein Fehler zur Designzeit, gemeldet am fehlerhaften Verweis, kein Stack Overflow beim Refresh.

### 3.2 Refresh ist topologisch

1. Den DAG von unten nach oben durchlaufen. Der vorhandene Compiler sortiert den Join-Graphen bereits topologisch (`MAD/Source/MADQueryFull.m:170-204`); der Objektgraph braucht dieselbe Disziplin auf Objektebene.
2. Jedes Blatt gegen seine eigene Quelle ausführen, durch seinen eigenen Treiber, in seine eigene Materialisierung.
3. Die vom komponierenden Objekt benötigten Materialisierungen anhängen oder öffnen.
4. Die komponierende Abfrage gegen die lokale SQLite-Datenbank ausführen und ihr Ergebnis materialisieren.
5. Den Graphen hinauf wiederholen. Die Wurzel ist ein gewöhnlicher Bericht; ihr Cache ist das, was der Betrachter liest.

Das Paging bleibt unverändert. Die Engine zieht weiterhin das vollständige Ergebnis in den lokalen Cache; die UI blättert über den Cache. Für einen API-Treiber ist „Pagination“ eine **interne Schleife** über die Seiten der API, um seine Materialisierung zu füllen; es ist kein Streaming- oder Paging-Vertrag mit der Engine. Die `limit`/`offset` des Plans existieren für Vorschauen im Design-Modus und für einen Treiber, der seinen Abruf begrenzen will, nicht für das Paging des Betrachters.

Gruppierung, Sortierung und Aggregate bleiben unverändert: sie werden über den lokalen Cache berechnet (`MAD_DATA_OBJECT.md` §3.5). Der Treiber gibt Detailzeilen zurück; er muss kein `GROUP BY` oder die Gruppierung des Berichts implementieren. Ein Sortierhinweis im Plan lässt einen Treiber eine Top-N-Anfrage nach unten durchreichen, wenn ein Limit vorhanden ist; die Engine sortiert trotzdem neu.

### 3.3 Zwei Materialisierungslayouts

Der Instinkt des Benutzers war `ATTACH`, und der aktuelle Code macht es zum kürzeren Weg.

**Layout A — eine `.maddb` pro Quellobjekt, `ATTACH` zum Joinen.**
- Das `MADDataTableFast` jedes Objekts behält seine eigene `<tag>.maddb` und `t<tag>`.
- Die komponierende Abfrage öffnet eine Verbindung zum lokalen Cache (oder einer In-Memory-Datenbank) und führt `ATTACH DATABASE '<path>' AS <alias>` für jedes benötigte Quellobjekt aus.
- Die SQL-Erzeugung qualifiziert die Tabelle als `<alias>.t<tag>`.
- Neue Arbeit: `ATTACH`-Unterstützung in `MADDatabaseSqlite3`, Aliasverwaltung und Quoting von Pfaden. Die Klasse ist bereits ein vollständiger SQLite-Wrapper, also ist dies eine kleine Ergänzung.
- Grenzen: SQLites `SQLITE_MAX_ATTACHED` ist standardmäßig 10, und kein Buildrezept im Repository hebt es an (`Compressor/sqlite3.xcconfig`, `Linux/`, `Windows/Engine/`). Es anzuheben ist eine Buildänderung auf drei Plattformen. v1 behandelt mehr als zehn direkte Quellen als Fehler zur Designzeit.
- Das komponierende Objekt selbst materialisiert in seine eigene `.maddb`, wie jedes andere Ergebnis.

**Layout B — mehrere Tabellen in einer `.maddb`.**
- Eine Cache-Datei pro Dokument, mehrere Tabellen `t<tag>`, kein `ATTACH`.
- Das erfordert, `MADDataTableFast` von „eine Instanz besitzt eine Datei“ auf ein geteiltes Datei-/Verbindungsmodell umzustellen oder eine Tabellenregistratur darüber hinzuzufügen. Das ist eine größere Änderung als `ATTACH` und läuft dem aktuellen Ein-Datei-pro-Tabelle-Design der Klasse zuwider.
- Sein Vorteil ist eine einzige Datei und kein Attach-Limit.

**Empfehlung:** Layout A für die erste Kompositionsimplementierung, weil es der aktuellen Klassengrenze folgt und zum Modell des Benutzers passt. Layout B bleibt die sauberere langfristige Dateigeschichte, falls das Dateimodell pro Tabelle je überarbeitet wird.

### 3.4 Was ein Verweis bedeutet

Der Tabellenverweis einer komponierenden Abfrage braucht eine zweite Art neben `databaseSchemaTable` (dem heutigen `RptqQueryTable.databaseSchemaTable`, `MAD/Source/rptq/autogen/RptqQueryTable.h:27`). Die Entscheidung des Benutzers (2026-11-22) ist, dass Komposition **zuerst innerhalb eines Dokuments** geschieht: ein `.mad`-Dokument enthält mehrere Berichts-/Abfragedefinitionen — **Unterberichte** —, und der komponierende Bericht verweist über seine Identität auf einen davon. Die Eigenschaft einer einzigen portablen Datei bleibt erhalten, und das iOS-Problem der dateiübergreifenden Neuauthorisierung entsteht für v1 nicht. Ein Verweis auf einen **Bericht in einer anderen `.mad`-Datei** (eine Dokumentidentität plus ein Pfad) ist ein späteres, separates Anliegen, hinter der Komposition innerhalb desselben Dokuments zurückgestellt.

Der Cache ist pro Gerät und entbehrlich, also zeichnet der Verweis auf, *was auszuführen ist*, nicht *wo die Daten sind*:

- **Live-Verweis (Standard).** Das Elternteil speichert den Definitionsverweis des Kindes und führt beim Refresh das Kind aus und materialisiert sein Ergebnis.
- **Festgeschriebener Snapshot.** Das Elternteil bewahrt die Materialisierung des Kindes im Begleit-Cache (`.maddb`/`.mdcache`) auf und verwendet sie wieder, statt das Kind erneut auszuführen. Eine Festschreibung ist ein aufbewahrtes Cache-Artefakt, **nie im `.mad` eingebettete Daten** — das Archiv bleibt definitionsonly (§6). Live und festgeschrieben lesen beide aus dem Cache-Verzeichnis; „pin“ heißt „diese Materialisierung behalten und wiederverwenden“, nicht „die Daten ins Dokument kopieren“.

Die Benennung der Materialisierung wandert vom Dateinamen-Hash zu einer stabilen Objektidentität, sodass Dateien nicht kollidieren und ein Elternteil ein bestimmtes Kind adressieren kann (§3.6, §6).

### 3.4.1 Wie das Elternteil die Spalten eines Kindes benennt

`RptqQueryField` hat genau einen Feldverweis, `databaseSchemaField` (`MAD/Source/rptq/autogen/RptqQueryField.h:27`), und der Select-Builder, der Join-Builder, die Prädikate und die Join-UI lesen alle `queryField.databaseSchemaField.name`. Die Ausgabespalten eines Kindes sind `MADDataColumn`s, keine Schemafelder. Die Empfehlung ist, **eine Ergebnisschema-Tabelle und -Feldmenge pro Objekt aus den `MADDataColumn`s des Kindes zu synthetisieren**: die Abfragefelder des Elternteils zeigen dann auf gewöhnliche Schemafeldzeilen, und jeder vorhandene Builder und jede UI funktioniert unverändert. Die synthetischen Zeilen sind ein Snapshot des Ergebnisschemas des Kindes und werden aufgefrischt, wenn sich das Schema des Kindes ändert. Die Alternative — eine zweite Feldverweisart auf `RptqQueryField` — berührt jeden Builder und wird nicht empfohlen. **Builder-Entscheidung.**

### 3.5 Fehler, Veraltung und Koordination

- Wenn ein Kind scheitert, scheitert der Refresh des Elternteils mit dem Fehler des Kindes und dem Namen des Knotens. Der vorherige Cache des Elternteils wird nicht durch ein halb gebautes Ergebnis ersetzt.
- Eine fehlende Kinddatei, eine verschobene Datei, ein geändertes Schema oder fehlende Zugangsdaten sind ein Fehler zur Refreshzeit, den die UI erklären kann, kein stilles leeres Ergebnis.
- Zyklen, Selbstverweise und ein Kind, das auch ein Vorfahre ist, werden vor der Ausführung abgelehnt.
- Dateiübergreifende Verweise (über v1 hinaus aufgeschoben) gehen, wenn sie kommen, über Dateikoordination und sicherheitsbereichsbezogene URLs unter iOS; iCloud kann das Kind verdrängen. Die CLI und macOS nehmen ausdrückliche Pfade. Das Design braucht eine Richtlinie zur Pfadauflösung über alle drei hinweg.
- Der Refresh-Fortschritt sollte pro Knoten sein. Ein langer API-Abruf in einem Kind sollte als Fortschritt dieses Kindes sichtbar sein, nicht als unerklärte Stockung.
- Der Abbruch muss den laufenden Treiber erreichen. Die aktuelle Ausführungsmethode ist synchron und hat kein Abbruch-Token; ein Ausführungsoptionen-Objekt des Plans ist der natürliche Ort dafür.

### 3.6 Was das Elternteil speichert

Zur Designzeit braucht das Elternteil das **Ergebnisschema** des Kindes — Spaltennamen, Typen, Längen —, um die Join-UI zu zeichnen und Feldverweise zu validieren. Es sollte die Zeilen des Kindes nicht brauchen und auch nicht die Quellverbindung des Kindes. Das Schema ist dieselbe `MADDataColumn`-Beschreibung, die der Cache bereits serialisiert. Das ist die Hälfte „beschreiben ohne auszuführen“ des Datenobjekt-Vertrags; sie ist eine Voraussetzung für Komposition, keine optionale Nettigkeit.

Die Entscheidung des Benutzers (2026-11-22) ist, dass **das Ergebnisschema die aktiven Felder sind** — die Spalten, auf die die Elemente, Joins und Gruppen des Berichts verweisen —, genau die SELECT-Liste, die `MADQueryActiveQueryFields` bereits berechnet (`MAD/Source/MADQueryActiveQueryFields.m:27-100`). Keine Verhaltensänderung: describe gibt diese Liste als `MADDataColumn`s zurück, ohne zu laufen. Die All-Spalten-Form bleibt ein Anliegen der Tabellenvorschau, kein Datenobjekt-Schema. Öffentliche Spaltennamen sollten benutzerseitig lesbar sein: `MADDataColumn.caption` existiert bereits für den Anzeigenamen, und der SELECT-Listen-Builder sollte ihn aus dem Anzeigenamen des Schemafelds setzen, wenn einer existiert, statt nur den internen Alias `"Table0"."Field"` offenzulegen.

Ein weiteres Stück Identität fehlt: die **Wurzel**. `RptqDocument -mainQuery` und `RptqDatabase -defaultQuery` sind beide `hasQueries.anyObject` (`MAD/Source/rptq/RptqDocument+Extras.m:184-186`, `MAD/Source/rptq/RptqDatabase+Extras.m:88`), und `MADocument -database` nimmt `hasDatabaseSchemas.anyObject` (`MAD/Source/MADocument.m:1248-1258`). Mit mehreren Datenobjekten in einem Dokument ist die Abfrage, die Betrachter und Designer rendern, nichtdeterministisch. Fügen Sie einen ausdrücklichen Wurzelverweis (oder ein Flag) zum Dokument hinzu und migrieren Sie die heutige einzige Abfrage dorthin. **Builder-Entscheidung.**

## 4. Die Treibernaht für Nicht-SQL-Quellen

### 4.1 Warum SQL-Text die falsche Grenze ist

Heute kompiliert der Berichts-Refresh den Graphen zu SQL und ruft `executeSQL:fieldKeys:onConnection:intoResultTable:withError:` (`MAD/Source/MADOperationRefresh.m:134`). Das ist für einen SQL-Dialekt richtig. Für eine REST-API zwingt es den Treiber, SQL zurück in einen Graphen zu parsen, und die Teilmenge des Parsers passt an mindestens zwei Stellen nicht zum erzeugten SQL: der Generator hängt eine `LIMIT`-Klausel an (`MADQueryFull.m:164`), die `MADSQLParser` ablehnt (`MAD/Source/sql/MADSQLParser.m:151-154`), und der Designer kann `NATURAL`/`CROSS`-Joins erzeugen (`RptqQueryLinks+Extras.m:76-86`, `MADQueryLinkType.h:15-16`), die der Parser ebenfalls ablehnt (`MADSQLParser.m:330-338`). Den Parser wiederzuverwenden würde zudem die Schichtung umkehren: er lebt in `MAD`, über den Treibern, und unter Linux linkt `mad` die Treiber als Whole-Archive (`Linux/CMakeLists.txt:469-474`).

`MADQuery`/`MADQueryFull` direkt zu übergeben ist ebenso wenig die Antwort: `MADQueryFull` ist speichergebunden, in `MAD`, und berechnet die aktive Feldliste nur beim Bauen von SQL. Ein Treiber würde gegen den Dokumentspeicher kompilieren.

### 4.2 Der Plan

Fügen Sie ein treiberneutrales Wertobjekt in `MADAPI` hinzu:

```objc
@interface MADQueryPlanTable : NSObject
@property (copy) NSString *name;                        // schema table or object name
@property (copy) NSString *alias;                       // query alias
@property (copy, nullable) NSString *sourceIdentifier;  // nil = schema table
@end

@interface MADQueryPlanField : NSObject
@property (strong) MADQueryPlanTable *table;
@property (copy) NSString *field;
@property (copy) NSString *outputKey; // exactly what the driver names the column
@end

@interface MADQueryPlanLink : NSObject
@property (assign) MADLinkType type;              // moved down to MADAPI
@property (strong) MADQueryPlanTable *leftTable, *rightTable;
@property (copy) NSString *leftField, *rightField;
@end

@interface MADQueryPlanPredicate : NSObject
@property (assign) MADPredicateOperator op;        // moved down to MADAPI
@property (strong) MADQueryPlanOperand *left, *right; // field reference or literal
@end

@interface MADQueryPlan : NSObject
@property (copy) NSArray<MADQueryPlanTable *> *tables;
@property (copy) NSArray<MADQueryPlanField *> *fields;   // the active SELECT list
@property (copy) NSArray<MADQueryPlanLink *> *links;
@property (copy) NSArray<MADQueryPlanPredicate *> *predicates;
@property (copy) NSArray<MADQueryPlanSort *> *sort;      // pushdown hint
@property (assign) NSUInteger limit;
@property (assign) NSUInteger offset;
@end
```

`MADLinkType`, `MADPredicateOperator` und `MADSortOrder` liegen derzeit in `MAD` (`MAD/Source/MADQueryLinkType.h`, `MADPredicateOperator.h`, `MADSortOrder.h`). Ein Plan in `MADAPI` kann sie nicht referenzieren, bis sie nach unten wandern (oder der Plan definiert seine eigenen Enums, was das Modell dupliziert). Die drei reinen Enums nach unten zu verschieben ist die richtige Behebung.

Die Ausführung wird eine optionale Methode am vorhandenen Protokoll:

```objc
@protocol MADDatabaseDataSource <NSObject>
// existing required methods stay ...
@optional
- (BOOL)executeQueryPlan:(MADQueryPlan *)plan
                 options:(MADDatabaseExecutionOptions *)options
          intoResultTable:(id <MADDataTableWriting>)table
                withError:(NSError **)error;
@end

@interface MADDatabaseExecutionOptions : NSObject
@property (copy) BOOL (^isCancelled)(void);
@property (copy) void (^progress)(double fraction, NSString *node);
@property (strong) id credentials;                  // driver-specific, or a resolver
@property (copy) NSArray<MADMaterializationReference *> *attachments; // SQLite composer
@end
```

Der Plan bleibt **logisch**; die Optionen tragen den Ausführungskontext. Ein komponierender SQLite-Treiber löst den `sourceIdentifier` jeder Tabelle auf eine in `options` gelieferte Anhängung (Pfad, Tabelle, Alias) auf. Das hält Dateipfade aus der Treiberoberfläche von Drittanbietern heraus und gibt Abbruch und Fortschritt pro Knoten ein Zuhause. **Builder-Entscheidung.**

`MADOperationRefresh` bevorzugt ihn, wenn der Treiber ihn implementiert, und fällt sonst auf den vorhandenen SQL-Pfad zurück. Die vier ausgelieferten Treiber brauchen am ersten Tag keine Änderung. Eine Referenzimplementierung kann den Plan intern zu SQL kompilieren und behaupten, dass er zur Ausgabe des aktuellen Compilers passt, was den Plan gegen die bestehende Suite festlegt.

### 4.3 Fähigkeiten

Die Engine und die UI sollten einen Treiber fragen, was er kann, statt Treiber-IDs fest zu verdrahten:

```objc
@interface MADDatabaseCapabilities : NSObject
@property (assign) MADLinkTypeMask supportedLinkTypes;
@property (assign) MADPredicateOperatorMask supportedOperators;
@property (assign) BOOL supportsLimitOffset;
@property (assign) BOOL supportsServerSideSort;
@property (assign) BOOL supportsNativeStatementText; // SQL editor
@property (assign) BOOL isReadOnly;
@property (assign) NSUInteger maximumPageSize;
@end
```

Dies ersetzt die fest verdrahteten Treiberlisten und Join-Regeln in `MADDesigner/Source/MADDriverSelectorController.m:64-90,124-140`, `MAD/Source/rptq/RptqDatabaseCredentals+MADDatabaseConnection.m:19-33`, `Mac/Source/MADMacConnectionWindowController.m:198-204,359-375`, `CLI/Source/MADCLIServe.m:277-291` und `MADDesigner/Source/MADQueryAddLinkJoinTypeController.m:46-95`. Die Registratur zählt die Treiber bereits auf (`registeredDriverClasses`); die UI kann sie plus `driverName`/`imageIconName` verwenden statt eines Switch.

### 4.4 Was jede Schicht behält

- **Schema-Browsing** bleibt `getTables:` / `getTablesFromConnection:error:` und `fieldsForTable:connection:error:`. Ein Nicht-SQL-Treiber gibt `MADDatabaseTable`- und `MADDatabaseField`-Werte zurück; der berichtende Benutzer sieht sie im Abfragedesigner genau wie heute Schematabellen.
- **Der Ergebnisvertrag** bleibt `id <MADDataTableWriting>`; der Treiber fügt `MADDataColumn`s und Zeilen hinzu, verschlüsselt nach `fieldKeys`/`outputKey`.
- **Gruppierung, Sortierung, Aggregate** bleiben in der Engine über dem Cache. Der Treiber gibt Detailzeilen zurück.
- **Joins** sind eine Fähigkeit: nativ, clientseitig oder nicht unterstützt. Komposition ist der Rückfall. Ein Treiber, der keine Joins unterstützt, kann trotzdem ein Quellobjekt sein; der Benutzer teilt die Ressourcen in separate Objekte und joint sie im komponierenden Bericht.
- **SQL-Texteingabe und die Validierungsprobe** sind durch Fähigkeiten gesteuert. Ein Nicht-SQL-Treiber muss kein eingefügtes SELECT akzeptieren.
- **Registrierung** kann aus Kompatibilitätsgründen an der Verbindungsklasse (`MADDatabaseDriver`) bleiben. Der sauberere langfristige Vertrag legt Typ, Kennung, Fähigkeiten und Verbindungskonstruktion auf die Unterklasse `MADDatabase`; das kann neben dem aktuellen Protokoll hinzugefügt werden, ohne die vier Treiber zu brechen.

## 5. Der generische API-Treiber

Der „eine Treiber für eine ganze Klasse von Datenquellen“ des Benutzers ist ein Treiber, dessen Schema aus einem **Quellmanifest** kommt, nicht aus dem Code. Die Engine sieht ein gewöhnliches `MADDatabase`; das Manifest sagt dem Treiber, welche Tabellen, Felder, Endpunkte und Pagination-Regeln existieren.

Minimale Manifestform:

```json
{
  "name": "eBay Seller",
  "baseURL": "https://api.ebay.com",
  "resources": {
    "listings": {
      "path": "/sell/inventory/v1/inventory_item",
      "rowsPath": "inventoryItems",
      "primaryKey": "sku",
      "pagination": { "limitParam": "limit", "offsetParam": "offset", "max": 100 },
      "fields": {
        "sku": "string",
        "listingId": "string",
        "product.title": "string",
        "price.value": "number"
      },
      "filters": { "sku": { "eq": "sku" } }
    }
  }
}
```

Der Treiber bildet den Plan auf Anfragen ab:

- `tables[0]` wählt die Ressource.
- `fields` werden eine Select-Liste oder ignoriert, wenn die API ganze Objekte zurückgibt.
- `predicates` werden Query-Parameter, wenn das Manifest eine Zuordnung nennt; andernfalls filtert der Treiber lokal.
- `limit`/`offset` treiben die Seitenschleife. Ohne Limit blättert der Treiber, bis erschöpft.
- `links` sind nativ, wenn die API sie unterstützt, clientseitig, wenn der Treiber einen Hash-Join implementiert, oder nicht unterstützt (die Fähigkeit deaktiviert den Link in der UI).
- JSON-Werte werden über die Feldtypen des Manifests auf `MADDataType` abgebildet.

Verbindungsseitig deckt die heutige Zugangsdatenzeile die SQL-Treiber ab (`host`, `username`, `password`, `database`). Für einen API-Treiber, der ein Client-Secret, ein Refresh-Token, eine Marketplace-ID oder ein Sandbox-Flag braucht, ist die Entscheidung des Benutzers (2026-11-22) ein einzelnes **erweiterbares Optionsfeld** an den Zugangsdaten: eine Textspalte, die JSON (oder XML) hält, in das Speicherformat versioniert, vom Treiber geparst — statt einer neuen Speicherspalte pro Treiber. Die vorhandenen Felder bilden den häufigen Fall ab (`host` = Basis-URL, `database` = Manifestname, `username` = Client-ID, `password` = OAuth-Token). Sensible Werte (Client-Secret, Refresh-Token) gehören in den Schlüsselbund, nicht ins Dokument; das JSON hält die nicht-geheime Form plus einen Schlüsselbund-Verweis. Das ist kein Workaround — es ist der Erweiterungspunkt, damit ein Treiber das Dokumentformat nicht jedes Mal ändert, wenn er einen Parameter hinzufügt.

Die Urheberschaft des Manifests ist **zuerst gebündelt/vom Entwickler erstellt** (die Entscheidung des Benutzers, 2026-11-22): der Entwickler des Treibers schreibt das Manifest und liefert es mit dem Treiber aus. Ein benutzerseitiger Manifest-Editor/-Import und seine Vertrauensgrenze sind hinter dem Plugin-System zurückgestellt (§5.1). Der langfristige Wunsch — Treiber, die sich einstecken lassen und über die UI hinzugefügt/entfernt werden — ist hier festgehalten; es ist zuerst ein Anliegen für macOS/Linux/Windows und Server, weil iOS historisch das Laden beliebigen Drittanbietercodes blockiert hat, also bleiben Treiber unter iOS zur Buildzeit gelinkt.

Der generische Treiber trägt auch die Nicht-SQL-Verpflichtungen, die der Plan nicht hat: HTTP-Client und TLS, Auth-Auffrischung, Rate-Limits, Wiederholungen, Abbruch, Obergrenzen der Antwortgröße und Fehlerzuordnung. Diese gehören ins Treiberframework, nicht in die Engine.

Was der generische Treiber nicht kann, ist ebenso wichtig wie das, was er kann: beliebiges GraphQL, eine Quelle, deren Zeilen nicht tabellarisch sind, oder serverseitige Joins, die das Manifest nicht ausdrücken kann. Das Fähigkeitenobjekt ist, wie er das sagt, und der Abfragedesigner ist, wo der Benutzer es erfährt.

### 5.1 Plug-and-Play-Treiber (Zukunft, nicht v1)

Das größere Ziel des Benutzers sind Treiber, die sich wie Plugins installieren, registrieren und abmelden und über die UI hinzugefügt oder entfernt werden können, statt in die App gelinkt zu sein. Die Registratur macht bereits prozessweise Registrierung per Link (§1 des Treiber-Tutorials); ein echtes Plugin-System ist eine Verpackungs- und Vertrauensfrage, die darauf geschichtet wird: dynamisches Laden, ein Entdeckungsort, Signierung/Sandboxing und eine UI. Das ist eine Funktion für macOS/Linux/Windows und Server, keine für iOS, und außerhalb des Umfangs der Phasen dieses Designs. Es ist hier vermerkt, damit sich die Treibernaht (Phase 0) nicht selbst in eine Ecke malt: die Typen für Plan, Fähigkeiten und Registrierung sollten aus einem dynamisch gelinkten Image ladbar bleiben, was keine Kompilierzeit-Kopplung an eine feste Treiberliste bedeutet.

## 6. Was sich im Speicher und im Format ändert

Minimale Form, `MAD_DATA_OBJECT.md` §4.4 folgend:

- `RptqQuery` erhält einen Namen. Es ist bereits die Definition.
- Der Verweis von `RptqQueryTable` erhält eine zweite Art: **ein Datenobjekt (Unterbericht) im selben Dokument**, zusätzlich zu einer Schematabelle. Eine v1-Zeile, die eine Schematabelle nennt, bedeutet genau das, was sie heute bedeutet. Ein Verweis auf einen Bericht in einer *anderen* `.mad`-Datei ist über v1 hinaus aufgeschoben; wenn er kommt, braucht er eine Dokumentidentität und einen Pfad plus eine Live-/Pin-Markierung.
- Die Zugangsdaten erhalten die erweiterbare Textspalte **options** (JSON/XML) für treiberspezifische Parameter (§5), mit dem Format hineinversioniert.
- Die Adresse der Materialisierung wird der Identitäts-Hash des Objekts, nicht `fileURL.lastPathComponent.hash`. Der Tabellenname bleibt `t<tag>`; das Tag wird die Identität des Objekts.
- Jedes Objekt erhält sein eigenes Schema-Plist (`.mdcache`) und seine Tabelle. Layout A behält eine Datei pro Objekt; Layout B würde das Dateimodell ändern.
- Der Speicher braucht einen Versionsschritt für die neuen Verweis- und Optionsfelder. Der vorhandene Speicher hat bereits eine Versionierungsmechanik für die SQL-Quellspalte (`MADStoreSchema.m:314`), also ist dies ein bekanntes Muster, kein neuer Mechanismus.

Das `.mad`-Dokument bleibt eine Definition und enthält **keine Daten, jetzt oder später** — das ist die ausdrückliche Entscheidung des Benutzers. Snapshots und Materialisierungen sind begleitende Cache-Dateien auf dem System des Benutzers, und sie sind das, was `ATTACH` zusammensjoint. Die automatische Benennung dieser Cache-Dateien wandert vom Dateinamen-Hash zu einer stabilen Objektidentität, sodass Dateien nicht kollidieren.

## 7. UI, CLI und die headless Engine

- Das Add-Table-Panel erhält eine zweite Art von Quelle: die anderen Datenobjekte des Dokuments (Unterberichte). Die Join-UI ist unverändert; beide Enden sind Felder. Dateiübergreifende `.mad`-Verweise sind eine spätere Ergänzung.
- Der Designer muss das Ergebnisschema eines Kindes zeigen können, ohne es auszuführen, und einen defekten Verweis (geändertes Schema, fehlende Zugangsdaten) vor dem Refresh markieren.
- Refresh braucht Fortschritt und Fehler pro Knoten. Ein Kind, das scheitert, sollte benannt werden.
- Zugangsdaten sind pro Knoten. Unterberichte im selben Dokument behalten ihre Zugangsdaten im einen Dokument, also ist die Richtlinie pro Objekt; ein dateiübergreifender Refresh, wenn er kommt, braucht eine Richtlinie zum Erlangen der Zugangsdaten des Kindes.
- Die CLI und die headless Engine durchlaufen denselben DAG. `MADOperationRefresh` wird von der App, macOS und der CLI geteilt (`CLI/Source/MADCLIDocument.m:120-127`, `Mac/Source/MADMacDocument.m:337-360`), also gehört der topologische Durchlauf dorthin oder in einen Helfer, den er aufruft, nicht in jedes Frontend.
- Das Verbindungsformular der macOS-App und die Treibertoken-Zuordnung der CLI brauchen dieselbe registraturgesteuerte Behandlung wie der iOS-Wähler.

## 8. Phasen

So geordnet, dass jede Phase grün ausliefert und die Ein-Abfrage-App weiter funktioniert. Die erste Phase ist unabhängig von der Komposition und ist diejenige, die Nicht-SQL-Quellen freischaltet.

| Phase | Arbeit | Hängt ab von |
|---|---|---|
| 0 | **Die Treibernaht.** `MADQueryPlan` + Werttypen hinzufügen und die drei Enums nach `MADAPI` verschieben; das optionale `executeQueryPlan:` hinzufügen; Fähigkeiten hinzufügen; Refresh den Plan bevorzugen und auf SQL zurückfallen lassen. Den Plan in einem vorhandenen Treiber als Referenz implementieren und die Plan-zu-SQL-Äquivalenz mit Tests festlegen. Keine Verhaltensänderung. | — |
| 1 | **Der Datenobjekt-Vertrag.** Die SELECT-Listen-Konstruktion von der Ausführung trennen; describe/execute hinzufügen; das Ergebnisschema als `MADDataColumn`s zurückgeben; Refresh den Vertrag aufrufen lassen. Das ist `MAD_DATA_OBJECT.md` Phase 1. | 0 (überlappt) |
| 2 | **Die Abfrage besitzt sich selbst.** `MADQueryFull` verwendet die Abfrage, die es erhielt; `dataTableForQuery:` löst pro Abfrage auf; `MADQueryActiveQueryFields` beschränkt auf eine Abfrage; `MADModelDocument` spiegelt jede Abfrage. | 1 |
| 3 | **Komposition im selben Dokument.** Eine Abfragetabelle darf auf ein anderes Datenobjekt (Unterbericht) verweisen; topologischer Refresh; `ATTACH`-Unterstützung in `MADDatabaseSqlite3`; die komponierende Abfrage führt gegen den lokalen Cache aus. Das ist das Modell des Benutzers mit einer portablen Datei. | 1, 2 |
| 4 | **Dateiübergreifende Komposition (aufgeschoben).** Ein Verweis auf einen anderen `.mad`-Bericht; Dokumentidentität und Pfadauflösung; live vs. festgeschrieben; Dateikoordination; Zugangsdatenrichtlinie; Behandlung fehlender/umbenannter Dateien. Niedrigere Priorität: die Komposition im selben Dokument erfüllt das Modell des Benutzers. | 3 |
| 5 | **Der generische API-Treiber.** Ein manifestgesteuerter HTTP/JSON-Treiber; Schema aus dem Manifest; Plan-zu-Anfrage-Abbildung; Paginationsschleife; Typzuordnung; das erweiterbare Feld `options` der Zugangsdaten; eBay Seller als durchgearbeitetes Beispiel. | 0, 1 (und 3 für Joins) |
| 6 | **Oberflächen und Dokumentation.** Registraturgesteuerte Treiberlisten und Join-Regeln; Refresh-UI pro Knoten; CLI-Verben; das Tutorial zum Schreiben von Treibern aktualisiert um die Plan-/Fähigkeiten-Naht. | 0–5 |

Keine Phase: **das Laden von Plug-and-Play-Treibern** (§5.1) ist eine Funktion für macOS/Linux/Windows und Server, die getrennt von diesem Design verfolgt wird; nichts in den Phasen 0–6 hängt davon ab, und Phase 0 sollte lediglich eine Kopplung an eine feste Treiberliste vermeiden, damit dynamisches Laden möglich bleibt.

Phase 0 ist der Teil „nicht weit entfernt“: es sind neue Werttypen, eine optionale Methode, ein Zweig im Refresh und Tests. Es erfordert nicht, dass sich Speicher, UI oder Kompositionsmodell ändern. Phase 3 ist, wo das `ATTACH`-Modell des Benutzers landet, und sie ist kleiner, als sie klingt, weil SQLite bereits ein Treiber ist und der Compiler bereits einen Graphen sortiert.

## 9. Entscheidungen

### 9.1 In diesem Dokument festgehaltene Builder-Entscheidungen

Diese sind aus dem Code oder durch einen Design-Kompromiss geklärt; sie können überdacht werden, aber der Plan setzt sie voraus.

1. **Layout A, mit `ATTACH`.** Eine `.maddb` pro Objekt; die komponierende Verbindung hängt sie an. Das folgt dem Ein-Tabelle-pro-Datei-Modell von `MADDataTableFast`. Layout B (mehrere Tabellen in einer Datei) ist ein späteres Refactoring, nicht v1. Dies ersetzt die Layout-B-Empfehlung von `MAD_DATA_OBJECT.md` §9.2 für dieses Design.
2. **Komponierende Objekte sind nur lokal.** Die Tabellen einer komponierenden Abfrage sind Datenobjekte; eine entfernte Tabelle wird in ein Quellobjekt gewickelt. Keine gemischte entfernte/lokale Ausführung.
3. **Die Kindfelder des Elternteils sind gewöhnliche Schemafelder.** Synthetisieren Sie eine Ergebnisschema-Tabelle/-Feldmenge pro Objekt aus den `MADDataColumn`s des Kindes und frischen Sie sie auf, wenn sich das Schema des Kindes ändert. Keine zweite Feldverweisart.
4. **Die Wurzel ist ausdrücklich.** Ein Wurzelverweis (oder Flag) auf Dokumentebene, migriert aus der heutigen einzigen Abfrage. Nicht `hasQueries.anyObject`.
5. **Der Plan ist logisch; der Ausführungskontext ist getrennt.** `MADDatabaseExecutionOptions` trägt Abbruch, Fortschritt, Zugangsdaten und die Anhängungsmenge des SQLite-Komponisten. `MADQueryPlanTable.sourceIdentifier` benennt die logische Quelle; er ist kein Dateipfad.
6. **Mehr als zehn direkte Quellen sind in v1 ein Fehler zur Designzeit.** `SQLITE_MAX_ATTACHED` anzuheben ist eine Buildänderung auf drei Plattformen, aufgeschoben.
7. **Den Plan parallel zum SQL-Compiler bauen, dann die Äquivalenz festlegen.** Den SQL-Compiler nicht darauf umgestalten, aus dem Plan zu rendern, bis der Plan durch die aktuelle Suite bewiesen ist.
8. **Die bestehende `RptqQuery` benennen; noch kein `RptqDataObject` einführen.** `MAD_DATA_OBJECT.md` §9.1 empfiehlt dies, und es ist die kleinere Migration.
9. **`MADDatabaseDriver` aus Kompatibilitätsgründen an der Verbindungsklasse behalten.** Ein Registrierungsvertrag auf Datenbankklassenebene kann später daneben hinzugefügt werden.
10. **Der erste generische API-Treiber erklärt Joins als nicht unterstützt.** Er verlässt sich für Joins auf Komposition und wächst dann hinter dem Fähigkeitenobjekt einen clientseitigen Hash-Join. Das hält den ersten Treiber bei einem Abruf einer einzigen Ressource.
11. **Komposition im selben Dokument kommt vor dateiübergreifender.** Phase 3 mustert die Festverdrahtungspunkte ohne Pfad-/Koordinations-/Zugangsdatenkomplexität aus; dateiübergreifend ist Phase 4.

### 9.2 Vom Benutzer beantwortete Entscheidungen (2026-11-22)

Die Worte des Benutzers folgen; die Implikationen sind die des Autors.

1. **Das Ausgabeschema sind die aktiven Felder — unverändert.** Die Ausgabe eines Datenobjekts sind die Spalten, die der Bericht verwendet: die Felder der Layout-Elemente, die Join-Felder und die Gruppenfelder, was genau die SELECT-Liste ist, die `MADQueryActiveQueryFields` bereits berechnet (`MADQueryActiveQueryFields.m:27-100`). Der Benutzer: *„es wären einfach die Felder, die in diesem Bericht verwendet werden.“* Die All-Spalten-Form ist nur ein Anliegen der Tabellenvorschau. Describe gibt dieselbe Liste als `MADDataColumn`s zurück, ohne auszuführen. Zwei Konsequenzen sind als künftige Funktionen vermerkt, nicht als Teil dieser Arbeit: **benutzerseitig lesbare Spaltennamen** (`MADDataColumn.caption` setzen, das bereits existiert, statt nur den Alias `"Table0"."Field"` offenzulegen) und **Vorschau-Paging** (die Vorschau begrenzt derzeit auf ~512 Zeilen und sollte durch das vollständige Ergebnis blättern — der Benutzer hat dies für die Wunschliste markiert, also `TODO.md` des Benutzers, nicht dieses Dokument). Die Null-Zeilen-Regel gilt weiterhin: ein Quellobjekt materialisiert sein vollständiges Schema, selbst wenn es keine Zeilen zurückgibt.
2. **Treiber sollen auf jeder Plattform laufen; Plug-and-Play ist das Ziel.** Der Benutzer: *„Das liegt wirklich an der Person, die den Treiber schreibt, aber ja, ich würde es erwarten.“* Die headless Engine und derselbe DAG gelten unter Linux/Windows; ob ein *gegebener* Treiber headless läuft, ist das Anliegen seines Autors. Der größere Wunsch — *„Treiber könnten Plug-and-Play sein … Treiber über die UI hinzufügen und entfernen“* — ist §5.1, eine künftige Funktion und ein Anliegen für macOS/Linux/Windows/Server, weil iOS historisch das Laden beliebigen Drittanbietercodes blockiert hat.
3. **Snapshots leben im Begleit-Cache, nie im `.mad`.** Der Benutzer: *„Die `.mad`-Datei beschreibt nur das Schema … das sollte sich nicht ändern … Es wäre in dem, was die Cache-Datei gerade ist … den Cache-Dateien, die Sqlite3-Datenspeicher sind, und das ist, was `ATTACH`ed zusammengejoint würde.“* Das Archiv bleibt also definitionsonly; ein festgeschriebener Snapshot ist eine aufbewahrte `.maddb`/`.mdcache`, und die Benennung der Materialisierung wandert zu einer stabilen Objektidentität, um Kollisionen zu vermeiden.
4. **Manifeste sind zuerst gebündelt/vom Entwickler erstellt.** Der Benutzer: *„deine Antwort ist richtig … die Idee war immer, dass neue Treiber über irgendein Plugin-System hinzugefügt werden könnten … ich glaube nicht, dass man unter iOS Plugins haben kann.“* v1 liefert einen manifestgesteuerten Treiber mit vom Entwickler erstellten Manifesten; ein benutzerseitiger Manifest-Editor/-Import und seine Vertrauensgrenze reiten hinter dem Plugin-System.
5. **Komposition geschieht zuerst im selben Dokument — Unterberichte in einer portablen Datei.** Der Benutzer: *„vielleicht könntest du dem mad-Dokument ‚Unterberichte‘ hinzufügen … die Idee wäre weiterhin eine portable Datei.“* Ein `.mad` enthält mehrere Berichts-/Abfragedefinitionen; jede läuft zu einer SQLite-Tabelle; der komponierende Bericht `ATTACH`t sie. Das bewahrt die Ein-Datei-Eigenschaft und entfernt das iOS-Problem der dateiübergreifenden Neuauthorisierung für v1. Verweise auf *andere Dokumente* sind hinter der Komposition im selben Dokument zurückgestellt.
6. **Zugangsdaten erhalten ein erweiterbares Optionsfeld.** Der Benutzer: *„wir könnten eines entwerfen und es dem Berichtsformat hinzufügen … vielleicht alles in einem Datenbankfeld, das wir irgendwie herausparsen (wie JSON oder XML), damit es erweiterbar ist.“* Eine Textspalte, die JSON hält, in den Speicher versioniert, vom Treiber geparst. Sensible Werte (Client-Secret, Refresh-Token) gehen in den Schlüsselbund; das JSON hält die nicht-geheime Form plus einen Schlüsselbund-Verweis.

### 9.3 Standardannahmen des Autors (Builder-Entscheidungen)

- **Live ist der Standard; pin heißt, den Cache-Snapshot aufbewahren.** Live führt das Kind beim Refresh aus; pin verwendet die aufbewahrte Materialisierung wieder. Beide lesen aus dem Cache-Verzeichnis.
- **Refresh-Richtlinie.** Jeden Knoten beim Refresh neu berechnen (die Bottom-up-Beschreibung des Benutzers). Ein Frische-/Cache-Wiederverwendungs-Schalter für teure API-Kinder ist eine spätere Ergänzung hinter dem Fähigkeitenobjekt.
- **Benennung.** „Datenobjekt“ ist der Speicher-/Protokollbegriff; „Unterbericht“ ist der benutzerseitige Begriff für ein referenziertes Objekt in der Kompositions-UI.

## 10. Risiken und was es zu keinem Einzeiler macht

- **Die drei Festverdrahtungspunkte** (das erneute Lesen in `MADQueryFull`, die Ein-Slot-Datentabelle, die ungeteilten aktiven Felder) sind tragend für die heutige Ein-Abfrage-App. Sie müssen fallen, bevor eine zweite Abfrage — geschweige denn eine verschachtelte — ausführen kann.
- **Die Cache-Adresse ist der Dateinamen-Hash**, und der Cache ist pro Gerät. Adressierbarkeit ist eine Voraussetzung, kein Detail.
- **Dateiübergreifende Verweise** bringen Pfadauflösung, iCloud-Verdrängung, Dateikoordination, fehlende Kinder und Zugangsdaten für eine Quelle, die das Elternteil nicht besitzt. Das ist der produktlastigste Teil.
- **`ATTACH` hat ein Limit** (`SQLITE_MAX_ATTACHED`, Standard 10) und braucht Alias-/Namensverwaltung und Pfad-Quoting. Entdecken Sie es nicht in der Produktion.
- **Kosten des vollständigen Refresh.** Das Cache-Design ist von Natur aus Pull-everything; ein DAG multipliziert das. Eine Cache-/Frische-Richtlinie ist Teil des Designs, keine Optimierung.
- **API-Rate-Limits und Datenvolumen.** Ein Treiber, der bei jedem Refresh eine API durchblättert, braucht Wiederholungen, Obergrenzen, Abbruch und eine sichtbare Fortschrittsgeschichte.
- **Schema-Drift.** Die Spalten eines Kindes können sich ändern; die Abfrage des Elternteils verweist dann auf Felder, die nicht mehr existieren. Validierung zur Designzeit und Fehler zur Refreshzeit sind erforderlich.
- **Stabilität der Treiber-API.** Drittanbieter-Treiber kompilieren gegen `MADAPI`; die Typen für Plan und Fähigkeiten werden eine öffentliche Oberfläche. Versionieren Sie sie bewusst.
- **Testmatrix.** Vier Plattformen (iOS, macOS, Linux, Windows), SQL- und Nicht-SQL-Treiber, Komposition im selben und über Dateien hinweg. Die Phasenreihenfolge ist die Milderung: eine neue Achse nach der anderen.

## 11. Was dies nicht ist

- **Keine Föderations-Engine.** Nichts Neues spricht in einer Anweisung mit MySQL und einer API. Jedes Objekt führt gegen seine eigene Quelle aus; der Join ist lokal.
- **Keine zweite Abfrageimplementierung.** Der Graph, der Compiler, die Treiber, die Ergebnistabelle und SQLites Join-Engine existieren bereits.
- **Keine Änderung am Pull-everything-Cache.** Der zweistufige Cache ist tragend (`docs/05-companion-files.md` §5.1).
- **Nicht eingeplant.** Dies ist die Designaufzeichnung für künftige Arbeit. `docs/project/TODO.md` ist die eigene Wunschliste des Benutzers (der Wunsch nach Vorschau-Paging gehört dorthin), `TASKS.md` ist die Engineering-Warteschlange, und `ROADMAP.md` sagt, was als Nächstes aufgegriffen wird. Nichts hier wird auf Initiative eines Agenten begonnen.

Zwei künftige Funktionen werden hier benannt, gehören aber in die Tracking-Dateien des Benutzers, nicht in dieses Design: die Behebung des **Vorschau-Pagings** (§9.2.1) und das **Plug-and-Play-Treibersystem** (§5.1). Dieses Dokument ist, wo ihre Form festgehalten wird; es plant sie nicht ein.

## 12. Der rote Faden

Der Abfrage-Arbeitsbereich baut die Funktion bereits. Die Refresh-Kette kompiliert und führt sie bereits aus. Die Ergebnistabelle ist bereits ein Schema und eine Ergebnismenge, auf der Platte als SQLite. SQLite ist bereits ein Treiber. Die Treiber geben bereits Tabellen zurück. Was fehlt, ist der Name, die Adresse, die Beschreibungshälfte und die strukturierte Abfrage, die ein Nicht-SQL-Treiber statt SQL-Text braucht. Diese sind additiv: ein Plan-Wertobjekt, ein Fähigkeitenobjekt, eine optionale Ausführungsmethode, eine stabile Objektidentität, eine zweite Art von Tabellenverweis, ein topologischer Durchlauf und `ATTACH`.

Die Komposition ist dann die bestehende Pipeline, adressiert durch etwas Besseres als einen Dateinamen-Hash. Der Nicht-SQL-Treiber ist dieselbe Pipeline mit einem anderen Ausführungskörper. Keines ist eine neue Engine; beide sind, was die Abstraktionen zu erlauben gebaut wurden.
