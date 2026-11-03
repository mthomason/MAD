[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | **Deutsch** | [Español](README_es.md)

# Linux — der Build der headless Engine

`docs/project/MAD_LINUX.md` §9: Phase B hat die Toolchain bewiesen (ein
Dockerfile, das clang + libobjc2 + GNUstep Base aus Quellen baut und eine
MADFoundation-Teilmenge kompiliert hat); Phase C ist die Shim-Liste aus §4, und
in diesem Verzeichnis wird sie umgesetzt. Der Build kompiliert inzwischen **alle
elf headless Frameworks** — jedes Framework aus der Tabelle in
docs/project/MAD_LINUX.md §3 plus `MADPostgres`, außer den reinen UI-Frameworks
(`MADExplorer`, `MADBarcodes`, `MADFeedback`, `Scrimpter`, die App) — und führt
ihre Suites im Container aus: 126 Testprogramme, 1.303 Tests, 7 festgehaltene
Needs. Die Testabdeckung, die am 2026-10-10 in master zusammengeführt wurde
(~100 Xcode-Testdateien), ist vollständig portiert, Suite für Suite. Nichts davon
wird in der App ausgeliefert; auch die CLI — der Checkpoint von Phase D — wird
hier gebaut und ausgeführt (siehe „Die CLI läuft hier“ unten), und das
Runtime-Image von Phase F führt sie als auslieferbares Artefakt aus („Das
Runtime-Image“ unten).

## Ausführung

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --runtime    build the runtime image (mad-cli:latest)
	./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

Die CLI von Docker Desktop liegt standardmäßig nicht im `PATH`; `build.sh` findet
sie unter `/Applications/Docker.app/Contents/Resources/bin` und setzt sie (und den
danebenliegenden Credential-Helper) für den Lauf in den `PATH`. Der erste Build
dauert 15–25 Minuten (die Toolchain-Stufe) und erzeugt ein Image von ~2,5 GB;
spätere Läufe sind zwischengespeichert — nur die Quellstufe wird neu gebaut. Die
Gegenprüfung mit `--platform linux/amd64` wurde zuletzt Ende zu Ende ausgeführt,
nachdem die zusammengeführte Abdeckung ankam (2026-10-11, vor Phase D): Das ganze
Image baut unter Emulation (die amd64-Toolchain-Stufe und die Bibliotheken kamen
aus dem früheren Cache; die Teilmenge, die 55 neuen Suites eingeschlossen, wurde
neu gebaut), und der Lauf stimmte exakt mit nativem arm64 überein — 114
Executables, 1098 Tests, 6 Needs, 10 Berichtseinträge, die Zählungen jenes Tages.
Er bleibt als Protokoll jenes Handlaufs erhalten; er wird durch den CI-Build
abgelöst, der das Image nativ auf amd64 (ubuntu-latest) kompiliert und dort bei
jedem Push auf master `--verify` ausführt — der Publish-Workflow pusht die
Runtime-Stufe derselben Plattform. Führen Sie diesen Lauf unter einem eigenen Tag
aus (`MAD_LINUX_IMAGE=mad-linux:phase-b-amd64 ./Linux/build.sh --platform
linux/amd64`), damit das native Image nicht ersetzt wird.

## Fixierte Versionen

`toolchain.conf` ist die einzige Stelle, an der Version, Quelle und Hash einer
Toolchain-Komponente festgeschrieben sind, in derselben Form wie
`Compressor/matrix.conf`; Git-Quellen fixieren das Release-Tag *und* den
ausgecheckten Commit, die GNUstep-Tarballs tragen sha256-Werte, die von
`ftp.gnustep.org` berechnet wurden.

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

Die Library-Kombination ist `ng-gnu-gnu` mit Runtime-ABI `gnustep-2.2`, sodass
alles mit `-fobjc-runtime=gnustep-2.2` und ARC kompiliert wird.

## Die Bibliotheksschicht

`libraries.conf` + `lib/libraries.sh` bauen die C-Bibliotheken, die die
Frameworks linken, nativ nach `/usr/local` (docs/project/MAD_LINUX.md §7). Gleiche
Form und Absicht wie die Compressor-Matrix daneben; nichts davon wird
ausgeliefert.

	sqlite3      3.53.3   the released amalgamation; the option list still comes
	                      from Compressor/sqlite3.xcconfig, the one place it lives
	openssl      3.5.9    static, before freetds
	freetds      1.4.27   --enable-msdblib, apps/server/pool/odbc off, and the
	                      recipe's sybdb.h BOOL edit (spelled for GNU sed)
	zlib         1.3.2
	bzip2        1.0.8    CC=clang: its Makefile hardcodes gcc
	libarchive   3.8.9    the .mad container's tar/bzip2 path
	mariadb      3.4.11   the mariadbclient static target, openssl + external
	                       zlib, auth plugins static, others off (mirrors
	                       Compressor/lib/recipes/mariadb.sh)
	postgres     17.11    the libpq static client library + libpgcommon/libpgport,
	                       with openssl, without readline/icu/gssapi/ldap/pam/xml/
	                       xslt/lz4/zstd/zlib (mirrors Compressor/lib/recipes/postgres.sh)

Zwei externe Build-Abhängigkeiten stammen noch aus dem eingestellten
mysqlclient-Build (`libncurses-dev` und `libtirpc-dev`, die cmake von mysql
brauchte); der mariadb-Build verwendet sie nicht, aber sie bleiben im Image.

## Was kompiliert wird und was nicht

| Framework | Linux-Build | Ausgeschlossen und warum |
|---|---|---|
| MADFoundation | 26 von 27 | `MADKeyChain` (Security.framework; §4 — der Refresh-Pfad liest den Schlüsselbund nie). Das Umbrella-Framework entfällt mit |
| MADDataStructures | alle 17 | (die Dateien des Xcode-Targets; `madmap.cpp` ist auch nicht darin) |
| MADFileManager | 10 von 11 | `MADCloudFileCoordinator` (NSMetadataQuery; §4 — iCloud stirbt in Phase D) |
| MADCocoaExtensions | 7 von 17 | die zehn UIKit-Drawer/Presenter (Farben, Labels, Textfelder, Alerts, View-Helfer, der Fehler-Presenter, MessageUI) |
| MADAPI | 8 von 11 | die drei Verbindungs-View-Controller (§3: nicht headless) |
| MADSqlite3 | alle 26 | (fünf verwaiste `.m`-Dateien sind auch nicht im Xcode-Target) |
| MADTds | alle 1 | |
| MADTdsClient | 4 von 5 | sein Verbindungs-View-Controller |
| MADMySQL | 18 von 19 | sein Verbindungs-View-Controller |
| MADPostgres | 5 von 6 | sein Verbindungs-View-Controller |
| MAD | 150 von 181 | der UI-Schwanz (§5.2), `MADocument` + die Operationen, die eines bauen/schließen (die von Phase D), die Schlüsselbund-Operationen, die von MADBarcodes gestützten Elementdateien. Jede ist in `cmake/MADSources.cmake` genannt |

Die Quelldateiliste jedes Frameworks ist ein `cmake/<Name>Sources.cmake` neben
dem Build, mit den genannten Ausschlüssen und ihren Gründen — dieselbe Form wie
`MADFoundationSources.cmake`. `MADExplorer`, `MADBarcodes`, `MADFeedback` und
`Scrimpter` sind überhaupt nicht im Linux-Build (docs/project/MAD_LINUX.md §3).

Der Linux-Build liefert, was GNUstep fehlt, ohne die Framework-Quellen zu
berühren:

* einen Include-Shim pro Framework, damit die Selbstimporte `<Framework/…>`
  auflösen (der von MAD ist ein Verzeichnis mit Symlinks, weil das Xcode-Target
  seine Header als `<MAD/Foo.h>` abflacht), plus vier Library-Header-Shims
  (`<MADSqlite3/sqlite3.h>`, `<MADTds/sybdb.h>`, das MADTdsClient-Umbrella,
  `<MADPostgres/libpq-fe.h>`);
* einen Prelude-Header (`Compat/MADCompat.h`) mit den Plattformlücken, die
  Makros oder Typedefs sind (siehe die Liste unten);
* Whole-Archive-Linking, Apples `-ObjC`, ohne das die Kategorien der Frameworks
  stillschweigend aus den statischen Archiven fallen;
* eine in `libmad.a` kompilierte Kategorie (`target_sources` in
  `Linux/CMakeLists.txt`): `MADQuery+Sqlite3`s `-whereClauseWithRowIds:` /
  `-whereClauseWithParameters:` werden per Nachrichtenversand erreicht, sodass
  der Linker das Archivmitglied verwirft, und ein Whole-Archive von
  `libmadsqlite3.a` würde die Compat-Objekte duplizieren, die jedes
  Framework-Archiv bereits einbettet;
* `-lgnustep-base` vor `-lobjc` auf der Linkzeile: libobjc2 exportiert ein
  schwaches `objc_enumerationMutation()`, das abbricht, und GNUstep Base
  exportiert das echte, das eine Ausnahme auslöst, und die erste Bibliothek auf
  der Zeile gewinnt.

Die Frameworks selbst haben kleine Plattform-Guards erhalten, alle als
`#if __APPLE__`, sodass die Apple-Pfade textuell unverändert bleiben. Die
macOS-Suites sind der Beweis, dass sie verhaltensneutral sind: MADFoundation,
MADDataStructures, MADFileManager, MADCocoaExtensions, MADAPI, MADSqlite3,
MADMySQL, MADTdsClient, MADPostgres und MAD sind alle grün im Simulator, und der
Workspace `MAD Designer` baut.

## Die Treiber werden registriert, nicht importiert

Der Konstruktor importierte früher die Treiber, was der Zyklus `MAD` ↔ Treiber
ist (`docs/project/ROADMAP.md` §5.1). `MADDatabaseDriverRegistry` (`MADAPI`) ist
jetzt die Nahtstelle: Die Verbindungsklasse jedes Treibers erfüllt
`MADDatabaseDriver` und registriert sich in `+load`, und
`MADDatabase+Constructor` / `MADDatabaseConnection+Constructor` schlagen einen
Treiber über `MADDatabaseType` nach, statt einen zu benennen. Welche Treiber ein
Prozess hat, hängt daher davon ab, was er *linkt*.

Auf Apple linkt der Host die Treiber-Frameworks — die App und die CLI nennen
MADMySQL, MADTdsClient und MADPostgres, und `MAD.framework` tut es nicht mehr,
weshalb auch sein Test-Bundle sie nennt. Auf Linux werden die Treiberarchive vom
Ziel `mad` aus **whole-archived** (`$<LINK_LIBRARY:WHOLE_ARCHIVE,…>`, was sich an
jeden Konsumenten fortpflanzt): Ein statisches Archiv wird durchsucht, nicht
geladen, sodass ein Mitglied, auf das nichts verweist — das `+load` eines
Treibers oder eine Kategorie —, anderenfalls verworfen wird. Das ist keine
Feinheit; es ist der Grund, warum `mad refresh` über MySQL abbrach, bevor es
behoben wurde (siehe den Abschnitt über Kategorien unten).
`MADDatabaseDriverDispatchTests` fixiert die Registry, und
`Linux/Tests/MADHeadlessDocumentTests.m` durchläuft die ganze Kette.

Einen Treiber hinzuzufügen bedeutet einen Link-Eintrag in `Linux/CMakeLists.txt`
und nichts in `MAD`.

## Die Compat-Shims sind ein eigenes Archiv — und warum

Jedes Framework-Archiv bettete früher `Compat/*.m` ein. Das machte das
Whole-Archive zweier solcher Archive zu einem Duplicate-Symbol-Fehler, weshalb
genau eine Kategorie (`MADQuery+Sqlite3`) von Hand in `libmad.a` kompiliert worden
war. Die CLI entdeckte die Kosten dieser Anordnung: `mad refresh` gegen ein
Live-MySQL **brach ab** (SIGABRT, ohne Diagnose), weil `MADMySQLFetch (DataTable)`
— die Methode, die das Prepared Statement ausführt — eine per
Nachrichtenversand erreichte Kategorie war, sodass der Linker ihre Objektdatei
nie hereingezogen hatte. `nm` zeigte `.objc_category_MADMySQLFetchDataTable` im
MySQL-Testbinary vorhanden und im CLI-Binary fehlend.

`madcompat` ist jetzt eine eigene statische Bibliothek, whole-archived von jedem
Executable (`mad_add_test`, `ToolchainProbe`, `mad-cli`), und die
Framework-Archive sind rein, sodass die Treiberarchive wie jeder andere Code
whole-archived werden können. Der `target_sources`-Hack pro Datei ist
verschwunden. Die allgemeine Regel, die daraus folgt: **Ein Framework-Archiv lässt
sich nur dann sicher linken, wenn es whole-archived wird**; bei weniger sind
seine Kategorien zur Laufzeit stillschweigend nicht vorhanden.

## GNUstep-Abweichungen, die die Probe und die Tests gefunden haben

* **NSOperationQueue und KVO — hier gefunden, in MADOperation behoben.** GNUsteps
  `NSOperationQueue` entfernt seine `"isReady"`-Beobachtung bei jeder
  Benachrichtigung, die sie erhält, und prüft `isReady` noch einmal, nachdem sie
  diese Beobachtung registriert hat. MADOperation trieb seine Zustandsmaschine
  früher aus `-isReady` selbst voran (über die KVO-abhängigen Schlüssel von
  `state`), sodass die erste Bereitschaftsprüfung die Benachrichtigung auslöste,
  auf die die Queue wartete, und der zweite Aufruf dann eine Beobachtung
  entfernte, die bereits verschwunden war — `NSInvalidArgumentException`, und die
  Operation lief nie. MADOperation treibt den Fortschritt jetzt explizit voran
  (`-willEnqueue` startet die Bedingungsauswertung) und sendet
  `will`/`didChangeValueForKey:` für `isReady`, `isExecuting` und `isFinished`
  nur, wenn sich der jeweilige Wert tatsächlich ändert, sodass die Queue pro
  Enqueue eine `isReady`-Benachrichtigung sieht, wie bei Apple. Die Linux-Tests
  prüfen dies auf beiden Plattformen schlicht; nichts wird stillgelegt, und der
  Refresh-Pfad von Phase D wird nicht mehr durch sie blockiert.
* **Secure-Coding-Archivierung fehlt.** `archivedDataWithRootObject:
  requiringSecureCoding:YES` gibt nil ohne Fehler zurück, daher fallen die
  Codepfade, die außerhalb von Apple funktionieren müssen — der
  `.madac`-Render-Cache von MADArrayCaching, der Gruppenschlüssel-Satz von
  MADDataTableFast, die Archive von MADFileUtilities —, hinter `#if __APPLE__`
  auf `requiringSecureCoding:NO` zurück, also denselben Coder ohne die Härtung.
  Die Entpackungsseite braucht keinen Rückfall:
  `unarchivedObjectOfClass:fromData:error:` und seine Pluralform funktionieren
  unter GNUstep (gemessen am 2026-10-06 — der frühere Bericht der Probe, dass
  weder diese Methode noch `+unarchiveTopLevelObjectWithData:error:` existiere,
  stammte von einem Branch, den der strikte nil-Archivpfad nie erreichte, sodass
  nur Letzteres je zutraf). Letztere existiert nicht und wird in `Compat/` über
  `+unarchiveObjectWithData:` als Shim bereitgestellt.
* **`-localizedCaseInsensitiveCompare:` ist unter GNUstep case-sensitiv** — nicht
  mehr tragend (behoben am 2026-10-25). Die SQLite-Sortierung, die
  MADDatabaseSqlite3 registriert (`compare_string_utf8_localized_asc_collation`),
  die Selektoren für das Sortieren im Speicher und der String-Vergleicher des
  Berichtsformatierers laufen alle über eine eigenentwickelt definierte
  Reihenfolge (`NSString+Comparison.h`: Case-Folding, dann
  UTF-8-Codepoint-Reihenfolge), sodass die Abweichung, die der lokalisierte
  Vergleich verursachte, beseitigt und nicht übertüncht ist; die Tests prüfen
  die definierte Reihenfolge auf beiden Plattformen identisch. Siehe den
  Abschnitt `mad export` in `docs/project/MAD_CLI.md`.
* **Die Runtime-Codierung von BOOL und die Vererbung von `class_getProperty` —
  gefunden von den rptq-Suites von MAD, behoben in RptqObject.** Die Runtime
  vergleicht die Typcodierung eines installierten Accessors mit der der
  kompilierten Aufrufstelle, und BOOL ist unter GNUstep `unsigned char` (`'C'`),
  wo Apple `signed char` (`'c'`) verwendet, sodass die dynamisch installierten
  bool-Accessoren von `RptqObject` jetzt eine plattformspezifische Codierung
  registrieren (`MAD_RPTQ_BOOL_TYPE`). Und GNUsteps `class_getProperty()`
  betrachtet nur die Klasse selbst, während Apples die Superklassenkette
  durchläuft — daher fiel eine vererbte Eigenschaft (die `alignment` eines
  Labels) in den generischen Objektzweig; `RptqPropertyNamed` durchläuft die
  Kette auf beiden Plattformen. Der Fehlermodus war ein stillschweigend falscher
  Wert, kein Absturz, daher sind beide durch die portierten Suites fixiert.
* **GNUsteps Datei-APIs verweigern URLs ohne Schema — gefunden von den portierten
  Tests von MADFileManager, behoben in MADURLFactory.**
  `-contentsOfDirectoryAtURL:` und `-writeToURL:` tun für eine URL ohne
  `file://`-Schema stillschweigend nichts (gemessen am 2026-10-11), und
  `+newURLForLocalDocumentsDirectory` baute seine URL mit `-initWithString:` aus
  einem Pfad — was Apple toleriert. Jetzt verwendet es `+fileURLWithPath:`, die
  ehrliche Antwort auf beiden Plattformen; das plus den Koordinator-Shim unten
  verwandelte fünf zurückgestellte Needs in fünf erfolgreich laufende Tests
  (`MADLocalFileCoordinatorTests`, 12 Tests, 0 Needs).
* **dispatch-Objekte sind einfache C-Zeiger** (`os/object.h` verweigert die
  ObjC-Unterstützung außerhalb von Darwin und lehnt `OS_OBJECT_USE_OBJC=1`
  rundheraus ab — die Build-Kommentare von libdispatch sagen es), sodass ARC
  keines besitzen kann: Jede `strong`/`copy`-dispatch-Eigenschaft ist außerhalb
  von Apple `assign` und an Ort und Stelle kommentiert. Queues werden einmal
  erzeugt und leben für den Prozess; nichts gibt sie frei.
* **Kleinere Lücken, per Shim oder Guard geschlossen:** `NSOperation.name`,
  `NSOperation.cancelled` und `NSOperation.asynchronous` (GNUstep behält nur die
  alte Schreibweise `-isConcurrent`, als Stub, der immer NO antwortet — seine
  eigene Buchführung befragt sie, und ohne die Compat-Kategorie, die
  `[self isAsynchronous]` beantwortet, löste eine abschließende asynchrone
  Operation aus `-dealloc` eine Ausnahme aus), die Ubiquity-Methoden von
  NSFileManager (kein iCloud außerhalb von Apple; jede Antwort ist die leere),
  `-initWithFilePresenter:` auf NSFileCoordinator,
  `-coordinateAccessWithIntents:queue:byAccessor:` (GNUsteps Implementierung
  stürzt ab, wenn sie den Accessor ausführt — SIGSEGV, gemessen; die
  Compat-Kategorie ruft den Accessor auf der angegebenen Queue auf, da es
  außerhalb von Apple nichts zu koordinieren gibt), der sicherheitsbezogene
  Zugriff von NSURL und `-fileSystemRepresentation`, die
  `-options:error:`-Leser von NSData und ihre Konstanten,
  `-decodeTopLevelObjectOfClasses:forKey:error:` auf NSCoder,
  `-registerUndoWithTarget:handler:` auf NSUndoManager,
  `+propertyListWithStream:options:format:error:` (ein Stub, der nil zurückgibt,
  der Stream wird nie gelesen — die Compat-Kategorie liest den Stream und
  delegiert an `+propertyListWithData:`; damit läuft `-loadFromCacheWithUrl:` von
  MADDataTable unter Linux und wird auf beiden Plattformen geprüft), die
  `CG*Value`-Schreibweisen von NSValue, die Makros `CF_ENUM`/`CFAvailability`,
  die CFNumber-Extraktionsaufrufe (ein Compat-`CoreFoundation/CFNumber.h`),
  `copyfile(3)` in POSIX, `htonll`, die MacTypes-Skalare (`Float64`,
  `SInt32`…`UInt64`, `Boolean`), `NS_RETURNS_INNER_POINTER`, die Schreibweise
  `__nullable`, `NSOperation.qualityOfService`, `NSDataWritingFileProtection*`,
  `containerURLForSecurityApplicationGroupIdentifier:` (fehlt — der Grund, warum
  der Gruppenpfad von MADURLFactory auf die benutzerspezifischen Verzeichnisse
  zurückfällt), `QOS_CLASS_DEFAULT` aus `<sys/qos.h>` (fehlt).
* **Als gut verifiziert:** ARC und schwaches Nullsetzen, Blocks, Exceptions,
  `@synchronized`, KVO (manuell und abhängige Schlüssel), die
  `NSOperation`-Zustandsmaschinen-KVO, `NSPredicate
  predicateWithFormat:@"error != nil"` (das exakte Prädikat von MAD), dispatch
  (once/queues/groups/semaphores), das Leerlaufen der Main Queue unter einem
  einfachen Executable, JSON, UUID, Datumsangaben, Plists, Sortierdeskriptoren,
  Streams, NSDecimalNumber, NSCalendar und Keyed Archiving auf dem permissiven
  Pfad. Der vollständige Bericht ist, was `--probe` ausgibt; seine 19
  Kernprüfungen bestimmen den Exit-Code, seine 12 Berichtseinträge nicht (der Lauf
  der CLI ergänzte `directory-enumeration` und `directory-enumeration-url-form`).

**Währungsformatierung (gefunden am 2026-10-16, behoben am 2026-10-17).** Zwei
GNUstep-Verhaltensweisen ließen das gerenderte Geld von Apples Darstellung
abweichen: `NSNumberFormatterCurrencyStyle` rendert für jedes Locale keine
Nachkommastellen (`en_US` ergab `$1`, Apple `$0.99`), und das aktuelle Locale des
Images ist `en_US_POSIX`, dessen Währung ein Leerzeichen nach dem Symbol und
keine Gruppierung hat. Beides wird beantwortet, ohne den Formatierer zu ersetzen:
Der Bericht bezieht sein Locale und seine Nachkommastellen aus dem numerischen
Format des Dokuments (der Rückfall ist `en_US`, nicht das Locale der Maschine),
und das Währungssymbol wird explizit geschrieben, mit normalisiertem Yen-Zeichen
(GNUstep schreibt es als Vollbreite U+FFE5). Ein Vergleich über 60 Fälle — sechs
Locales mal zehn Werte, negative Werte und 1e12 eingeschlossen — ist inzwischen
byte-identisch zwischen den beiden Plattformen; der einzige gefundene Unterschied
war jener Yen-Codepoint. `docs/project/BUGS.md` enthält den Eintrag (archiviert:
behoben), und die renderseitigen Exporte unten sind auf die Bytes des Macs
fixiert.

## Die Need-Anzahl und warum sie 6 ist

Das Image von Phase B meldete 3 Needs; das fertige Image von Phase C meldet 6,
und die drei neuen stammen jeweils daher, dass MADs Suites auf reine
Apple-Maschinerie gestoßen sind. Sie sind bewusst Needs, keine Skips: Die Prüfung
kann ohne eine Ressource, die Linux nicht hat, nicht laufen, und die Need sagt es
laut, wo ein Skip es verbergen würde.

* **Die drei, die es schon gab.** Die Strict-Archiving-Prüfung der
  Toolchain-Probe (`requiringSecureCoding:YES` gibt nil zurück, oben) und ihre
  App-Group-Prüfung (`containerURLForSecurityApplicationGroupIdentifier:` fehlt)
  plus die bedingte von MADCredentialTests zur selben Strict-Archiving-Lücke.
* **MADStoreTests** — die Modelltreue-Prüfung braucht Core Data und das
  kompilierte `MAD.momd`, beides nur unter Apple.
* **RptqStoreContextTests, zweimal** — das Fixture des konvertierten Beispiels
  braucht `MADStoreConverter`, Core Data und `London.mad`, und der Dokumentpfad
  braucht `MADocument` und `MADStoreConverter` (von Phase D zu klären).

Die Live-Datenbank-Suites werden übersprungen (scheitern nie), wenn kein
Server erreichbar ist — derselbe Kontrakt wie die Xcode-Schemes —, und die
SQLite-Benchmarks werden in ihrer Standardgröße übersprungen; Skips werden
separat gezählt und sind keine Needs.

## Die Live-Datenbanksuites laufen hier

`MADMySQLLiveTests`, `MADTdsClientLiveTests` und `MADPostgresLiveTests` sprechen
echte Server an und werden übersprungen (scheitern nie), wenn keiner
erreichbar ist — derselbe Kontrakt wie die Xcode-Schemes. Die Server sind die drei
Container, die `docs/project/DEVELOPER.md` dokumentiert; starten Sie sie zuerst:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on :13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on :1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on :5432

	docker run --rm \
		-e MAD_MYSQL_TEST_HOST=host.docker.internal \
		-e MAD_MYSQL_TEST_PORT=13306 \
		-e MAD_TDS_TEST_HOST=host.docker.internal \
		-e MAD_PG_TEST_HOST=host.docker.internal \
		--entrypoint bash mad-linux:phase-b -c \
		'/src/Linux/build/MADMySQLLiveTests && /src/Linux/build/MADTdsClientLiveTests && /src/Linux/build/MADPostgresLiveTests'

Am 2026-10-17 mit diesem sauberen Aufbau gemessen: MySQL 44/44, 311 Prüfungen
(Prepared Statements, die Typkonvertierungen, Schema-Erkennung), und SQL Server
29/29, 169 Prüfungen (der freetds-Wire-Pfad, das Aufschlüsseln von Datum/Uhrzeit,
decimal/blob/nvarchar, Schema-Erkennung); PostgreSQL 14/14, 132 Prüfungen
(gemessen am 2026-10-27: libpq-Fetch, OID-Typkonvertierungen, Schema-Erkennung
über öffentliche und nicht öffentliche Schemata) — alle drei Treiber funktionieren
also unter Linux, nicht nur sie kompilieren. Die beiden Verbindungsfehler-Tests
von `MADTdsClientTests` laufen ohne Server.

## Lizenzen

Alles im Image ist Build-Tooling; nichts wird in die App gelinkt. libobjc2 ist MIT;
libdispatch ist Apache-2.0 mit der Swift-Runtime-Ausnahme; GNUstep Base ist
LGPL-2.1-or-later; gnustep-make ist GPL-3.0-or-later, und sein `Testing.h`
(GPL-3.0-or-later) wird in die Linux-Testbinaries kompiliert — diese existieren
nur innerhalb dieses Build-Images. Die C-Bibliotheken tragen ihre eigenen
Lizenzen (docs/project/THIRD_PARTY_LICENSES.md); das GPL-Problem von mysqlclient
ist geklärt — D1 wechselte zu MariaDB Connector/C (LGPL-2.0-or-later, gewählt als
LGPL-3.0), und dieses Image baut es (`docs/project/TASKS.md` §10). Das
Runtime-Image wird als `ghcr.io/mthomason/mad` veröffentlicht, daher brauchen die
LGPL-Komponenten, die es vertreibt, Relink-Angebote: Das schriftliche Angebot in
`ThirdParty/Licenses/README.md` nennt jetzt das Image, und der Registereintrag ist
`THIRD_PARTY_LICENSES.md` §9. gnustep-make ist Build-Tooling und nicht im
Runtime-Image.

## Die CLI läuft hier — Phase D

`mad` wird von diesem CMakeLists aus `CLI/Source` gebaut (denselben Quellen, die
`CLI/build.sh` für den iOS-Simulator baut), linkt die elf Frameworks
whole-archive und läuft im Image:

	/build/mad inspect <document.mad>
	/build/mad schema  <document.mad>
	/build/mad query   <document.mad>
	/build/mad refresh --credentials user:pass <document.mad>

`export` ist das eine Verb, das hier nicht vorkommt: PDF ist ein
Core-Graphics-Kontext, gezeichnet von einem `UIPrintPageRenderer`, also bleibt es
auf Apple und sagt das auch (`docs/project/MAD_LINUX.md` §5.2; die Entscheidung
über den Renderer gehört zu Phase E).

**`export` bekam hier seine Foundation-Formate (Phase E, 2026-10-16).** Die
Export-Nahtstelle (`MADReportExporting` + `MADReportExporterRegistry`,
`docs/project/MAD_CLI.md` §5.3) liegt in `mad`, daher laufen `text`, `csv` und
`json` im Image und schreiben dieselben Bytes wie das Werkzeug des Macs (die
renderseitigen Formate — `html`, `html-flow`, `json-report` — laufen hier
ebenfalls; siehe den Abschnitt unten, und `pdf` sagt, warum es nicht kann). Der
Vergleich, für das Protokoll am London-Fixture ausgeführt
(`CLI/Fixtures/London.portable.mad`, vorher aktualisiert, `sha256sum` auf beiden
Seiten):

| Format | Bytes | sha256 (auf beiden Plattformen identisch) |
|---|---|---|
| `json` | 64595 | `569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc` |
| `csv` | 12538 | `773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21` |
| `text` | 40441 | `7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49` |

`Linux/Tests/MADReportExporterTests.m` ist dieselbe Prüfung als Test: die Datei
aktualisiert das Fixture und prüft die FNV-1a-Prüfsumme jedes Exports gegen die
Bytes des Macs (plus Form und einige Werte), sodass eine Schreibweise, die
zwischen GNUstep und Apple auseinanderdriftet, hier fehlschlägt — und dieselben
FNV-1a-Prüfsummen sind inzwischen auf der Mac-Seite fixiert
(`MAD/MADTests/MADReportExporterTests.m`), sodass die Abweichung auf keiner
Plattform still bleiben kann. `json-report` ist dasselbe Schema mit dem
gerenderten Bericht als zusätzlichem Mitglied; es braucht die Render-Hälfte
(`MADReportFormatter` und den Seitenrenderer), die seit Phase E hier kompiliert —
der Abschnitt unten enthält den Digest, und nur `pdf` registriert sich und sagt,
warum es nicht laufen kann (`docs/project/MAD_CLI.md` §3);
`Linux/Tests/MADReportExporterTests.m` prüft, dass es fehlschlägt, statt
stillschweigend die Datenhälfte zu schreiben.

**Wie die Dokumentklasse geklärt wurde.** `MADocument` ist ein `UIDocument`, kann
also nicht mitkommen, und `MADCLIDocument` baute früher darauf auf. Die
Datenhälfte eines Dokuments ist jetzt ein Protokoll —
`MADDocumentDataProtocol` —, das `MADocument` erfüllt (unverändertes Verhalten;
jedes Mitglied war bereits einer seiner Accessoren) und `MADHeadlessDocument`
implementiert: Es öffnet den Container und den portablen Speicher mit
`MADDocumentStore` (dem Speicherlayout, das auch MADocument verwendet, sodass die
beiden sich nicht widersprechen können), kompiliert die Abfrage, baut die
treibergestützte Datenbank über die Registry und hält die Zeilentabelle. Die
Refresh-Kette nimmt das Protokoll, sodass Apple und Linux denselben
`MADOperationRefresh` ausführen — nur sein einziger renderseitiger Zweig (der
Berichtsformatierer und die Section-Layout-Manager) ist `#if __APPLE__`. Der
Benutzer wählte diese Form am 2026-10-16 gegenüber einem `UIDocument`-Shim in
Compat und gegenüber einer Aufteilung von `MADocument` selbst.

**Der Checkpoint, von innerhalb des Images** (Docker Desktop; die Dokumente liegen
in `CLI/Fixtures/`, und ihr Hostname `mac` löst hier zum Mac auf):

| Lauf | Ergebnis |
|---|---|
| `mad inspect` auf `London.mad` (das Legacy-Beispiel) | v0, 6 Mitglieder, Store + WAL + SHM gemeldet |
| `mad inspect` auf `London.portable.mad` | v1, 4 Mitglieder, `StoreContent/store.sqlite (portable)`, 41 Bereiche / 25 Elemente |
| `mad schema` auf den beiden portablen Fixtures | identisch mit der Ausgabe des Macs, Byte für Byte |
| `mad query` auf denselben | dieselbe Feldmenge wie auf dem Mac; die *Reihenfolge* weicht ab (unten) |
| `mad refresh` auf `London.portable.mad` | 76 Zeilen, und der Zeilen-Cache ist identisch mit dem des Macs (21 Spalten nach Namen, 76 Zeilen, jeder Wert gleich) |
| `mad refresh --rows 50 --credentials root:root` auf `MySQL.employees.mad` | 50 Zeilen aus live MySQL 8.4 (Prepared-Statement-Fetch, Datenbank `employees`) |
| `mad refresh --rows 20 --credentials sa:Root1@Root2` auf `TDS.AdventureWorksLT2022.mad` | 20 Zeilen aus live SQL Server 2022 (freetds, `AdventureWorksLT2022`) |
| `mad refresh --rows 25 --credentials mad:mad_test_pw` auf `Postgres.chinook.mad` | 25 Zeilen aus live PostgreSQL 17 (libpq, `chinook`) |

Die Live-Suites stimmen zu: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests`
29/29 und `MADPostgresLiveTests` 14/14 aus demselben Image.
`Linux/Tests/MADHeadlessDocumentTests.m` ist derselbe Checkpoint als Test —
öffnen, Schema, Abfrage, Treiberauflösung, Refresh, 76 Zeilen —, sodass er in CI
statt in einem Handlauf fehlschlägt.

**Zwei Unterschiede, die man kennen sollte, beide hier gefunden.** Die
Spaltenreihenfolge der SELECT-Liste war die Reihenfolge des *Sets*
(`MADQueryActiveQueryFields` sammelt in ein `NSSet`), sodass dasselbe Dokument
unter Apple und unter GNUstep eine unterschiedliche Reihenfolge erzeugte —
dieselben Felder, andere Reihenfolge; die *Daten* des Caches sind identisch,
sobald man nach Feldnamen vergleicht, und die Spaltennamen `c<hash>` des Caches
sind hash-abgeleitet, sodass sie sich ebenfalls pro Plattform unterschieden.
**Geklärt am 2026-10-16 (die Entscheidung zur Form des JSON-Exports,
`docs/project/MAD_LINUX.md` §10.1):** Die Reihenfolge ist jetzt als Spaltenalias
definiert, sortiert mit `-compare:`, in beiden SQL-Buildern, sodass das erzeugte
SQL, der Zeilen-Cache und jeder Export auf beiden Plattformen übereinstimmen
(docs/project/BUGS.md, der SELECT-List-Eintrag; die Reihenfolgetests in
`Linux/Tests/MADQuerySelectExpressionTests.m`). Ein Cache, der vor der Änderung
aktualisiert wurde, ordnet seine Spalten anders als einer, der danach aktualisiert
wurde — dieselben Daten, eine neue Reihenfolge —, also einmal aktualisieren, bevor
man Caches über dieses Datum hinweg vergleicht.

## Der Writer läuft hier, und die beiden Plattformen stimmen überein

Die andere Hälfte von Phase E (`docs/project/MAD_LINUX.md` §9; die Anforderung
des Benutzers, 2026-10-16): Der `.mad`-Writer funktioniert unter Linux und erzeugt
für dasselbe Dokument **dieselben Bytes** wie der des Macs. `mad write <doc.mad>
--out <copy.mad> [--reproducible]` ist die Oberfläche, und das Dokument wird auf
beiden Plattformen headless geöffnet, sodass beide Seiten denselben Writer
ausführen.

Gemessen am London-Fixture (`CLI/Fixtures/London.portable.mad`):

	$ mad write London.portable.mad --out copy.mad --reproducible
	16261 bytes, sha256 09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5
	                                     (identical on the Mac and in this image)

Das Fixture ist ein Speicher der Version 1, und das Schreiben öffnet zuerst das
Dokument, daher trägt die geöffnete Kopie auf beiden Plattformen die
Speichermigration (SQL-Eingabe Phase A: die Spalte `sqlSourceText` und
`user_version` 2); die obigen Bytes gehören dem migrierten Dokument.

`--reproducible` fixiert uid/gid 0, die feste Zeit 2001-01-12T00:00:00Z und einen
sortierten Mitgliederdurchlauf; ein gewöhnliches Schreiben behält die echten
Metadaten der Mitglieder, unterscheidet sich also konstruktionsbedingt zwischen
Läufen und Plattformen.

Zwei Dinge mussten behoben werden, damit der Writer hier läuft, beide in
`docs/project/BUGS.md` festgehalten (der Eintrag zur Byte-Identität von `.mad`):

* `-write_archive:` lief jede aufgezählte URL *bis* zum archivierten Verzeichnis
  ab, und GNUsteps `-enumeratorAtURL:` entfernt das enthaltende Verzeichnis,
  sodass die Schleife nie ankam. Die Mitglieder werden jetzt mit
  `-subpathsAtPath:` gelesen, so wie es die Mitgliederliste der CLI bereits tat.
* `backup_file` übergab seinen Pfad an `dirname(3)`/`basename(3)`, den glibc
  ändern darf und ändert: Der Archivpfad des Aufrufers kam am letzten Schrägstrich
  abgeschnitten zurück, sodass das zusammengesetzte Dokument über sein eigenes
  Verzeichnis geschrieben wurde (`Open (…) failed - Is a directory`). Apples
  Implementierungen lassen den Puffer unangetastet, weshalb nur Linux es sah.

`Linux/Tests/MADArchiveManagerTests.m` ist die Abdeckung (5 Tests, 0 Needs): der
Roundtrip (`docs/project/MAD_CLI.md` §6.1), die Charakterisierung des gewöhnlichen
Modus, der reproduzierbare Modus — einschließlich einer FNV-1a-Prüfsumme des
gesamten Dokuments gegen die Bytes des Macs — und der Dokumentpfad, der eine Kopie
schreibt und die Quelle unangetastet lässt.

## Die Render-Hälfte und die HTML-Formate laufen hier

Die zweite Entscheidung von Phase E (die des Benutzers, 2026-10-16) war HTML als
Nächstes und PDF zuletzt, und im HTML-Schritt verlässt die Render-Hälfte Apple.
Sie zog um als Konformität:

* `MADReportFormatter` nimmt `id <MADDocumentRenderProtocol>`;
  `MADHeadlessDocument` erfüllt es, und der Render-Zweig von
  `MADOperationRefreshInitialize` richtet sich nach dem Protokoll.
* `MADReportPageBuilder` ist der Seitenlauf, herausgelöst aus
  `MADPrintPageRenderer` (das `UIPrintPageRenderer` und das Zeichnen behält). Er
  besitzt die Geometrie der Renderseite (US Letter, der 1-pt-Beschnitt) und die
  Vorbereitungssequenz, sodass PDF, json-report und die HTML-Formate sich nicht
  über eine Seite uneinig sein können.
* `MADDocumentRenderDataSource` ist die eine Implementierung der Lesezugriffe der
  Render-Hälfte, gemeinsam genutzt von `MADocument` und `MADHeadlessDocument`;
  die Familie `MADPrintPageElement` kompiliert hier (ihre Initialisierer sind
  Foundation; nur das Zeichnen gehört Apple).

`mad export` hat hier jetzt `html`, `html-flow` und `json-report`, und `pdf`
registriert sich und sagt, warum es nicht laufen kann (sein Rumpf ist Core
Graphics). Gegen den Mac am London-Fixture gemessen:

| Format | Bytes | sha256 (auf beiden Plattformen identisch) |
|---|---|---|
| `json-report` | 118,109 | `9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c` |
| `html` | 62,007 | `285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327` |
| `html-flow` | 54,766 | `0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382` |
| `pdf` | — | hier nicht erzeugt; `+isAvailable` NO mit Begründung |

Die renderseitigen Formate sind plattformübergreifend byte-identisch, wie die
Datenseitigen: jeder Rahmen, jede Schrift, Schriftgröße, Schriftschnitt,
Ausrichtung, jeder Textlauf und jeder Seitenkasten, und das Geld (der Befund, der
sie unterschied, und seine Behebung stehen oben und in `docs/project/BUGS.md`).
`Linux/Tests/MADReportExporterTests.m` fixiert die drei Prüfsummen.

## Das Runtime-Image — das CLI-Artefakt (Phase F)

Das Artefakt von Phase F ist ein Container, der die CLI ausführt, kein Build-Baum,
an dessen Pfad sich ein Entwickler erinnern muss. `./Linux/build.sh --runtime`
baut ihn aus demselben Dockerfile (die Stufe `runtime`, nachgelagert zu `build`),
getaggt als `mad-cli:latest`:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad

Das Image wird (seit 2026-10-26) als `ghcr.io/mthomason/mad` veröffentlicht,
getaggt als `latest` und mit dem kurzen SHA des Commits. Die veröffentlichten
Tags werden von CI (`.github/workflows/publish-image.yml`) auf ubuntu-latest
gebaut, sind also **linux/amd64** — der lokale Build `mad-cli:latest` des Macs
ist arm64. Ziehen statt bauen ist der Zehn-Sekunden-Weg; unter Apple Silicon
fügen Sie `--platform linux/amd64` hinzu (Docker Desktop führt den Tag in
Emulation aus — ohne das Flag schlägt der Pull mit `no matching manifest` fehl):

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Der Vertrieb des Images verpflichtet zu Relink-Angeboten für die darin
enthaltenen LGPL-Komponenten (GNUstep Base sowie mariadb und freetds statisch in
`mad`); das schriftliche Angebot in `ThirdParty/Licenses/README.md` nennt das
Image (der Abschnitt „Lizenzen“ oben).

Das Image enthält:

* `/usr/local/bin/mad`, den stabilen Pfad der CMake-Installationsregel (das
  Binary ist nicht mehr nur unter `Linux/build/mad` erreichbar);
* die Shared Objects, die das Binary linkt — GNUstep Base, libobjc2, libdispatch
  und libBlocksRuntime —, plus GNUsteps Runtime-Verzeichnisse und -Konfiguration.
  Die anderen C-Bibliotheken (sqlite3, freetds, openssl, zlib, bzip2, libarchive,
  mariadb, postgres) sind statisch und bereits im Binary;
* keine Share-Daten von mysqlclient: Connector/C bettet seine
  Client-Fehlermeldungen ein und installiert keine `share/`-Dateien;
* `chinook.sqlite3` unter `/root/GNUstep/Library/ApplicationSupport/`, wo der
  bloße Datenbankname eines Sqlite3-Dokuments aufgelöst wird. Ein Dokument
  speichert den Namen, keinen Pfad, daher ist diese eine Datei das, was die
  eingecheckten Fixtures London und Music ohne zusätzliche Einrichtung
  aktualisierbar macht.

Es lässt den Compiler, cmake, git, die Quellen, die 126 Testbinaries sowie die
statischen Archive und Header zurück: Die letzte Stufe ist `ubuntu:24.04` plus die
Runtime-Bibliotheken aus apt, nicht das Toolchain-Image. Es ist **283 MB auf der
Festplatte (66,5 MB komprimiert)**; das Build-Image ist 6,65 GB.

Jedes Verb läuft auf dieselbe Weise:

	docker run --rm -v "$PWD/docs":/docs mad-cli:latest mad schema /docs/x.mad
	docker run --rm -v "$PWD/docs":/docs -v "$PWD/out":/out mad-cli:latest \
		mad export /docs/x.mad --format html --out /out/x.html
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

Die Live-Fixtures nennen den Server `mac` (`CLI/Fixtures/README.md`); vom Container
aus löst das über Docker Desktop zum Mac auf. Der Refresh-Cache wird im Container
unter `/root/GNUstep/Library/Caches` geschrieben, überlebt `--rm` also nicht;
`export` aktualisiert das Dokument selbst, das ist also kein Problem. Fügen Sie
ein Volume hinzu, wenn ein Cache zwischen Läufen bestehen bleiben soll. Das Image
läuft als root; ein Lauf mit `--user` braucht die Beispieldatenbank (und jedes
Dokument) im eigenen Application-Support-Verzeichnis dieses Benutzers.

**`--verify` ist die wiederholbare Prüfung.** Es baut das Runtime-Image neu und
führt `Linux/verify-cli.sh` darin mit read-only eingebundenem Repository aus: die
sechs Verben, jedes Exportformat gegen seinen fixierten Digest, die Verweigerung
von `pdf`, die Bytes des `--reproducible`-Writers, die Exit-Codes und die Form
des Images selbst (kein clang, cmake, git oder Build-Baum). 41 Prüfungen; bei
jedem Fehler endet es mit einem Wert ungleich null.

	./Linux/build.sh --verify
	...
	MADVERIFY 41 passed, 0 failed

`--live` ergänzt die Refreshes für MySQL, TDS und PostgreSQL (50, 20 und 25
Zeilen); starten Sie zuerst die drei Testcontainer (`docs/project/DEVELOPER.md`
hat ihre Skripte und Logins):

	MADMySQL/TestDatabase/mysql-test-db.sh up
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up
	MADPostgres/TestDatabase/postgres-test-db.sh up
	docker run --rm -v "$PWD":/repo:ro mad-cli:latest \
		bash /repo/Linux/verify-cli.sh --live

**Veröffentlicht, mit CI (2026-10-26, womit die Entscheidung vom 2026-10-17
umgekehrt wurde).** `.github/workflows/publish-image.yml` pusht die Runtime-Stufe
bei jedem Push auf master zu `ghcr.io/mthomason/mad` als `latest` und
`<short-sha>`, außerdem manuell über den Actions-Tab (`workflow_dispatch`); der
lokale Build `./Linux/build.sh --runtime` bleibt unverändert. Die veröffentlichten
Tags sind amd64, von CI gebaut; der lokale Build des Macs ist arm64.

**Eine Dockerfile-Falle, aufgeschrieben, weil sie den ersten Build gebissen hat.**
Die Runtime-Stufe ist die letzte Stufe des Dockerfiles, daher erzeugt `docker
build` ohne `--target` jetzt das Runtime-Image. `build.sh` übergibt `--target
build` für das Build-Image und `--target toolchain` für den Toolchain-Cache; ein
von Hand ausgeführter Build sollte dasselbe tun.

## Was dies noch nicht tut

Der Linux-PDF-Writer — **zurückgestellt am 2026-10-17, blockiert durch die
Recherche des Benutzers; ohne dessen Entscheidung nicht beginnen.**
`docs/project/MAD_PDF_LINUX.md` ist die Übergabedatei (was existiert, was fehlt,
die Kandidaten-Stacks mit Lizenzen, die offenen Fragen, der Abnahmetest);
`docs/project/MAD_LINUX.md` §10.2 hält die Begründung fest. Bis er landet, ist
ein PDF unter Linux ein Browser, der `--format html` druckt.

Die übrigen Teile von Phase F, Stand 2026-10-17: Das **Runtime-Image** und seine
**wiederholbare Verifikation** sind erledigt (der Abschnitt oben), und die
**CI-Zeile wurde auf Entscheidung des Benutzers gestrichen** — keine GitHub
Actions, weil der Linux-Port ein Machbarkeitsnachweis zum Testen ist, keine
Produktveröffentlichung. Das änderte sich am 2026-10-26 mit der
GHCR-Veröffentlichung: Das Image wird veröffentlicht, und `publish-image.yml`
baut und pusht es (der Abschnitt oben). Der **Compressor-Linux-Treiber** ist nicht
erledigt und für die CLI nicht nötig: Das Image baut die C-Bibliotheken bereits
nativ (`libraries.conf` + `lib/libraries.sh`). Fragen Sie, bevor Sie ihn beginnen.
