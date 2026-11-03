---
layout: default
lang: de-DE
---

# Einen MAD-Treiber an einem Nachmittag schreiben

Alle folgenden Datei:Zeile-Angaben sind auf dem Stand vom 2026-10-25.

## Was ein Treiber ist

Ein Treiber besteht aus zwei kleinen Klassen und einem Registrierungsaufruf:

1. einer Unterklasse von `MADDatabase` (`MADAPI/Source/MADDatabase.h` – der Header
   sagt es klar: „This class is built for subclassing“), die weiß, wie man das
   Schema einer Quelle durchsucht und eine Abfrage dagegen ausführt;
2. einer Verbindungsklasse – einer Unterklasse von `MADDatabaseConnection`, die
   das Protokoll `MADDatabaseDriver`
   (`MADAPI/Source/MADDatabaseDriverRegistry.h`) erfüllt und sich in `+load`
   registriert.

Alles andere – der Graph des Abfrage-Designers, die SQL-Erzeugung, der
Zeilen-Cache, die Render-Pipeline, die sieben Exportformate, die CLI, das
Docker-Image – ist gemeinsame Maschinerie, in die sich der Treiber einhängt. Der
Kontrakt, den ein Treiber erfüllt, lautet *„ein Schema und Zeilen in Tabellenform
zurückgeben“* (`docs/project/MAD_STRATEGY.md` §3.7); deshalb kann ein Treiber vor
allem stehen, was sich wie eine Tabelle darstellen lässt: eine SQL-Datenbank, ein
Webdienst, eine Datei.

Die drei Server-Beispiele zum Abschauen sind `MADPostgres` (6 Dateien,
`MADPostgres/Source/`, Unterklasse `MADDatabasePostgres` über `libpq`),
`MADMySQL` (18 Dateien, `MADMySQL/Source/`, Unterklasse `MADDatabaseMySQL`) und
`MADTdsClient` (SQL Server über FreeTDS). Sqlite3 ist der vierte ausgelieferte
Treiber (`MADSqlite3`), und der dateibasierte Fall
(`+newDatabaseConnectionWithURL:`) zeigt sich in seiner Verbindungsklasse.

## Schritt 1 – die Typkonstante

Wählen Sie den nächsten freien Wert von `MADDatabaseType`
(`MADAPI/Source/MADDatabaseType.h`; die ausgelieferten Typen sind 1–12) oder
erweitern Sie das Enum. Diesen Wert speichert das Dokument, er ist also eine
Formatkonstante: Sobald Dokumente mit Ihrem Typ existieren, ist die Nummer
dauerhaft.

## Schritt 2 – `MADDatabase` ableiten

Die abstrakten Nahtstellen liegen in `MADAPI/Source/MADDatabaseProtocol.h`
(`MADDatabaseDataSource`). Die erforderliche Oberfläche:

```objc
- (void)getTables:(void (^)(BOOL success, NSError *error,
                            NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                    error:(NSError **)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
                                     connection:(id)dbconn
                                          error:(NSError **)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError **)error;

// The execution seam: the driver fills the table it is handed.  The
// destination is any <MADDataTableWriting>, which is what keeps the
// promise to "anything that returns a table" (MADDataTable.h).
- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
  intoResultTable:(id <MADDataTableWriting>)dataTable
         withError:(NSError **)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError **)error;
- (BOOL)executeQuery:(MADQuery *)query
       withDataTable:(id <MADDataTableWriting>)dataTable
            andError:(NSError **)error;

// Optional: only file-backed drivers have nothing to dial.
- (void)closeConnection:(id)process;
```

Das Schema-Browsing (`getTables…`, `fieldsForTable:…`) ist das, was der
Dokumenterstellungsablauf der App aufruft, wenn er das Schema einer Datenbank in
eine neue `.mad`-Datei importiert; die Ausführungsnahtstelle ist das, was `mad
refresh` und der Viewer aufrufen. `MADOperationRefresh.m:134` zeigt den genauen
Aufruf, den die Refresh-Kette macht.

## Schritt 3 – die Verbindungsklasse und die Registrierung

```objc
@interface MyDriverConnection : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MyDriverConnection
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}
+ (MADDatabaseType)databaseType { return MADDatabaseTypeMyDriver; }
+ (NSString *)Identifier { return @"MyDriver"; } // stored in documents
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { … }
+ (Class)databaseClass { return [MyDatabase class]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
										 database:(NSString *)database
											 port:(NSInteger)port { … }
@end
```

`+Identifier` ist der Wert, den `RptqDatabaseCredentals.driverID` hält, also
ebenfalls eine Formatkonstante des Dokuments – wählen Sie eine stabile
Schreibweise („MySQL“, „TDS“, „PostgreSQL“, „Sqlite 3“ sind die ausgelieferten).
Eine zweite Klasse, die einen bereits belegten Typ beansprucht, ist ein
Programmierfehler; die Registry prüft dies mit einer Assertion.

## Schritt 4 – einbinden, damit die Registrierung läuft

Die Registrierung erfolgt pro Prozess und **über das Linken**: Ein Prozess, der
Ihren Treiber nicht linkt, kann seine Datenbanken nicht aufbauen (der Konstruktor
prüft mit einer klaren Meldung über eine Assertion, statt später mit nil zu
scheitern).

* **Apple:** Binden Sie Ihr Framework in den Host ein (die CLI nennt ihre Treiber
  in der Liste `FRAMEWORKS` von `CLI/build.sh`), oder verwenden Sie `-ObjC` beim
  Linken eines statischen Archivs – Kategorien und `+load`-Methoden werden sonst
  stillschweigend verworfen.
* **Linux:** Fügen Sie Ihr Archiv **whole-archived** dem Ziel `mad` in
  `Linux/CMakeLists.txt` hinzu, so wie `madsqlite3`, `madmysql`, `madtdsclient`
  und `madpostgres`:

  ```cmake
  target_link_libraries(mad PUBLIC
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,my_driver>" …)
  ```

  Dies ist keine Feinheit – die Arbeit eines Treibers wird über Kategorien
  erreicht (Nachrichtenversand, keine Symbole), und ein nicht vollständig
  archivierter statischer Link verwirft sie: Der Fehler ist ein Absturz beim
  ersten Nachrichtenversand, keine Linker-Warnung (`Linux/README.md`, „The compat
  shims“ / „The drivers are registered“). Eine Quelldateiliste pro Treiber in
  `cmake/MyDriverSources.cmake` folgt der Form von
  `MADFoundationSources.cmake`, mit jeder ausgeschlossenen Datei und dem Grund.

## Schritt 5 – die Testkonventionen (das ist der Hausstil; halten Sie sich daran)

Zwei Suites im Testtarget des Frameworks:

1. **Offline-Tests** – Schemastrukturen, Feldmetadaten, das Quoting von
   Bezeichnern, der Eigenschafts-Roundtrip der Verbindung. Sie laufen immer.
2. **Live-Tests** – sprechen eine echte Quelle an und werden **übersprungen und
   schlagen nie fehl**, wenn keine erreichbar ist.
   `MADMySQL/MADMySQLTests/MADMySQLLiveTests.m` ist die Vorlage: Zugangsdaten
   zeigen standardmäßig auf einen dokumentierten lokalen Server und sind
   sämtlich über eine Umgebungsvariable überschreibbar
   (`MAD_MYSQL_TEST_HOST`, `MAD_MYSQL_TEST_PORT`, `MAD_MYSQL_TEST_USER`,
   `MAD_MYSQL_TEST_PASSWORD`, `MAD_MYSQL_TEST_SCHEMA`), und jeder Live-Test
   beginnt mit `XCTSkipIf(![self serverIsAvailable], …)`. Ein Rechner ohne Ihre
   Quelle bekommt trotzdem eine grüne Suite. Beachten Sie den Kommentar in der
   MySQL-Datei: Verwenden Sie im iOS-Simulator `127.0.0.1`, nicht `localhost`.
3. **Registry-Tests** – `MADDatabaseDriverRegistryTests` zeigt die Form: einen
   Testtreiber registrieren, den Lookup prüfen, den Wurf bei doppeltem Typ
   prüfen. Ihr Treiber bekommt einen davon durch die Konstruktion gratis.
4. Portieren Sie die Suites nach `Linux/Tests/`, wenn der Treiber in den headless
   Build gehört (siehe `cmake/` und `Linux/README.md`, „Adding the next
   framework“); anderenfalls begründen Sie im Pull Request, warum er nur für
   Apple bestimmt ist.

## Schritt 6 – die ehrliche Einschränkung: Was ein Nicht-SQL-Treiber heute kann und nicht kann

Dies ist der einzige Teil der Argumentation, der nicht fertig ist, und er ist
bewusst festgehalten (`docs/project/MAD_STRATEGY.md` §4.7): Die
**Ausführungsschicht** ist treiberförmig – `executeSQL:…intoResultTable:…` und
das Ziel `MADDataTableWriting` halten ehrlich, was „alles, was eine Tabelle
zurückgibt“ verspricht –, aber die **Kompilierungsschicht** ist gemeinsam:
`MADQueryFull` kompiliert den Abfragegraphen in einen SQL-Text pro Treiber. Ihr
Treiber erhält **SQL-Text**, nicht den Graphen (Tabellen, Felder, Prädikate,
Gruppen).

Ein REST-/Webdienst-Treiber heute:

* **kann** sein Schema durchsuchen (`getTables…`, `fieldsForTable:…`), das
  Verbindungsformular übernehmen, das die App bereits hat, das erzeugte SQL
  empfangen und in API-Aufrufe übersetzen, Zeilen in jede beschreibbare Tabelle
  liefern und den gesamten Refresh-/Render-/Export-Pfad mitfahren – ein voll
  funktionsfähiger Treiber;
* **kann nicht** den Abfragegraphen nativ empfangen: Um zu wissen, *was* die
  Engine von ihm verlangt, muss er den SQL-Text aus der Zeichenkette
  herausparsen, die er erhalten hat. Der praktische Weg: Der SQL-Parser der
  Engine selbst (gebaut für die SQL-Eingabe, `docs/project/MAD_SQL_ENTRY.md`)
  parst bereits die unterstützte Teilmenge – das erzeugte SQL gehört konstruktiv
  zu dieser Teilmenge –, sodass ein Treiber ihn wiederverwenden kann, um den
  Graphen zurückzugewinnen;
* Die **eigentliche Lösung** ist ein Kompilierungs-Hook pro Treiber – die Form,
  die das Projekt 2012 für Salesforce SFQL skizziert hat –, sodass „einen Treiber
  installieren“ heißt „einen Treiber für alles installieren“ und nicht „für die
  SQL-Dialekte, die wir zufällig abdecken“. Er ist als Arbeit am Engine-Kontrakt
  eingeplant (Stufe 1) und ein wirklich willkommener erster Pull Request, wenn
  Sie einen größeren Brocken als einen Treiber möchten.

Noch eine ehrliche Anmerkung, für Server-Deployments statt für Treiber: Ein vom
Benutzer installierter Treiber ist **beliebiger Code im Serverprozess**. Die
Registry funktioniert heute für vertrauenswürdige, eigenentwickelte Treiber; ein
Treiber-Marktplatz braucht Signierung, Sandboxing oder Prozessisolierung, bevor er
existieren kann, und das muss in die API des Servers hineindesignt werden, nicht
später angeschraubt.

## Schritt 7 – einbringen

Schlagen Sie den Treiber über die Issue-Vorlage für Treibervorschläge vor,
befolgen Sie die Test-first-Regel in
[CONTRIBUTING.md](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md)
(zuerst ein fehlschlagender Test, dann Code bis zum Grün; Fixtures als
Momentaufnahme festhalten, statt sie mit dem neuen Code zu erzeugen), und wenn der
Treiber eine neue Drittbibliothek linkt, erweitern Sie
[docs/project/THIRD_PARTY_LICENSES.md](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md)
und die Lizenzpflichten entsprechend – das Repository nimmt diese Datei ernst.
