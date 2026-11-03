[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | **Deutsch** | [Español](README_es.md)

# CLI-Fixtures

Dokumente, gegen die die Verben der CLI ausgeführt werden, neben den Beispielen,
aus denen sie stammen (`docs/project/MAD_CLI.md` §6).

| Fixture | Quelle | Was es fixiert |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | der Sqlite3-Datenpfad: 11-Tabellen-Schema, das London-Prädikat, 76 Zeilen |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | derselbe Pfad am größeren Beispiel (3503 Zeilen) |
| `MySQL.employees.mad` | die Beispieldatenbank `employees`, live (MySQL 8.4) | der MySQL-Treiberpfad von Anfang bis Ende: Schema-Import, SQL mit Backticks, ein Fetch per Prepared Statement |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022, live (SQL Server 2022) | der TDS-Pfad von Anfang bis Ende: schemaqualifizierte Tabellen, T-SQL in eckigen Klammern, der freetds-Fetch |
| `Postgres.chinook.mad` | Chinook, live (PostgreSQL 17) | der PostgreSQL-Pfad von Anfang bis Ende: Schema-Import, SQL mit doppelten Anführungszeichen, der libpq-Fetch |

## Warum die Beispiele konvertiert werden mussten

Beide ausgelieferten Beispiele sind **Legacy**-Dokumente: Ihre Definition ist ein
Core-Data-Speicher (`StoreContent/analyitics`), und eines zu konvertieren erfordert
Core Data, das das MAD-Framework nicht linkt und das Linux nicht hat
(`docs/project/MAD_LINUX.md` §5.1, §9). `London.portable.mad` und
`Music.portable.mad` sind dieselben Dokumente, geschrieben im portablen Speicher,
sodass eine Plattform ohne Core Data sie lesen und aktualisieren kann — was die
Linux-CLI und `Linux/Tests/MADHeadlessDocumentTests.m` tun.

Sie sind außerdem das Gegenstück auf der Leseseite zu den v0-Beispielen: `mad
inspect` meldet ein Fixture als v1 mit `StoreContent/store.sqlite` und das
Beispiel als v0 mit dem Legacy-Speicher, und beide Aussagen stammen vom selben
Container-Leser.

Die drei Live-Fixtures sind gewöhnliche Dokumente, die die Erstellungskette der App
gegen einen echten Server geschrieben hat; ihre Schemata sind also echte Schemata
(8 Tabellen von `employees`, 12 von AdventureWorksLT, 11 von Chinook) und ihre
Abfragen echte `SELECT`s.

## Wie sie erstellt wurden

Auf dem Mac, mit den eigenen Codepfaden der App — nichts hier ist von Hand
geschrieben:

	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad" \
		"$PWD/CLI/Fixtures/London.portable.mad"
	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad" \
		"$PWD/CLI/Fixtures/Music.portable.mad"

	CLI/build.sh --make-fixture create mysql mac 13306 root root employees "$PWD/CLI/Fixtures/MySQL.employees.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/MySQL.employees.mad" titles "title,from_date,to_date"

	CLI/build.sh --make-fixture create tds mac 1433 sa 'Root1@Root2' AdventureWorksLT2022 "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad" "SalesLT.Product" "Name,ListPrice,Color"

	CLI/build.sh --make-fixture create postgres mac 5432 mad mad_test_pw chinook "$PWD/CLI/Fixtures/Postgres.chinook.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/Postgres.chinook.mad" track "name,composer,unit_price"

`--make-fixture` kompiliert `MADFixtureMaker.m` (dieselben Flags wie das Werkzeug,
plus den Legacy-Konverter und die Value-Transformer) und führt es im Simulator
aus:

* `portable` kopiert das Dokument, öffnet es mit `MADocument` — wodurch der
  Legacy-Speicher beim Einlesen konvertiert wird —, markiert es als geändert und
  schließt es, was der Speicherpfad ist.
* `create` führt die Dokumenterstellungskette der App gegen einen Live-Server aus:
  das Dokument erstellen, die Ersteinrichtung, die Verbindung hinzufügen, das
  Schema importieren, schließen (wodurch gespeichert wird).
* `select` tut, was der Designer tut, wenn eine Tabelle und ihre Felder angehakt
  werden: die Abfragetabelle hinzufügen, ein Abfragefeld pro Schemafeld und ein
  Datenlabel pro Abfragefeld — die Labels sind es, die die Felder *aktiv* machen,
  denn die SELECT-Liste besteht aus den Feldern, auf die die Elemente des Berichts
  verweisen (`MADQueryActiveQueryFields`).

Das Ergebnis ist über mehrere Läufe hinweg nicht byte-stabil (der Speicher ist
SQLite, und das Archiv trägt Zeitstempel), daher werden die Fixtures nur neu
erzeugt, wenn sich ein Beispiel oder das Speicherformat ändert, und ein Diff darin
ist ein echter Diff, den man sich ansehen sollte.

## Der Hostname in den Live-Fixtures

Alle drei nennen den Server `mac` — den Hostnamen dieses Macs, der sich hier und
in den Docker-Containern zu seiner LAN-Adresse auflöst. Ein Name also für das
MySQL des Macs (vom Fixture-Container unten sowohl auf dem Loopback *als auch* im
LAN freigegeben) und für die SQL-Server- und PostgreSQL-Container (auf allen
Schnittstellen freigegeben), sodass dasselbe Dokument vom Mac und vom Linux-Image
aus aktualisiert werden kann. `host.docker.internal` würde nur innerhalb eines
Containers funktionieren; `127.0.0.1` nur auf dem Mac.

Alle drei Live-Fixtures wurden gegen die kanonischen Testcontainer erstellt, die
`docs/project/DEVELOPER.md` dokumentiert und deren Skripte sie aus fixierten Images
und prüfsummenverifizierten Datensätzen erzeugen:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on 13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on 1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on 5432

Alle drei sind auf jeder Schnittstelle freigegeben, sodass der Hostname `mac` der
Dokumente sowohl vom Mac als auch aus dem Linux-Image heraus auflöst. Der
MySQL-Container läuft auf 13306, nicht 3306, weil der launchd-Dienst des
Oracle-MySQL-Installers 3306 belegen kann. `down` stoppt einen Server (die Volumes
behalten die Daten); `reset` entfernt ihn, und das nächste `up` baut ihn neu.

Die Optionen `--host`, `--port` und `--database` der CLI überschreiben die
gespeicherte Verbindung für einen Lauf (`docs/project/MAD_CLI.md` §3); so richtet
ein CI-Job eines dieser Dokumente auf einen Service-Container, dessen Host und Port
vom Mac abweichen. Das Dokument selbst wird nicht neu geschrieben.
