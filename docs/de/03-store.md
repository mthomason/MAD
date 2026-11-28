---
layout: default
lang: de-DE
---

## 3. Der Speicher

`StoreContent/analyitics` ist eine gewöhnliche SQLite-Datenbank:

```
StoreContent/analyitics: SQLite 3.x database, last written using SQLite version 3043002,
  writer version 2, read version 2, file counter 52, database pages 126, cookie 0x6e,
  schema 4, largest root page 113, UTF-8, vacuum mode 1, version-valid-for 52
```

Er enthält die **Dokumentdefinition**: die Abfrage, ihre Tabellen und Joins, die
Bereiche und Elemente des Berichts sowie den Schema-Snapshot der Datenbank. Das
Core-Data-Modell ist `MAD/MAD.xcdatamodel`; alle seine Entitäten tragen das
Präfix `Rptq` (`RptqDocument`, `RptqQuery`, `RptqDocumentElement`,
`RptqDocumentSection`, …).

Zwei Eigenschaften dieses Speichers sind entscheidend für die Portabilität:

1. **Er wird im WAL-Modus geschrieben.** `-wal` und `-shm` werden zusammen mit der
   Hauptdatenbank im Archiv ausgeliefert. Ein Leser, der nur `analyitics`
   extrahiert und das WAL ignoriert, liest eine Datenbank, die bis zu einem
   Checkpoint veraltet ist. Im `Music`-Beispiel ist das WAL **313 KB groß bei
   einer Hauptdatei von 516 KB** – das ist kein theoretisches Risiko.
2. **Er ist ein Core-Data-Speicher**, sein Schema stammt also von Core Data und
   nicht von uns. Ihn ohne Core Data zu lesen bedeutet, die eigenen Tabellen von
   Core Data zu lesen. Das ist möglich – es ist SQLite, und die Abbildung ist
   stabil –, aber es ist der Teil dieses Formats, der einen Leser an Core Data
   bindet, und der Grund, warum die Ablösung von Core Data hier wichtiger ist als
   an jeder anderen Stelle.

### 3.1 Der portable Speicher (seit der Speichermigration)

Seit der Speichermigration (`docs/project/design/MAD_STORE_MIGRATION.md`) lebt die
Definition eines Dokuments in einem portablen SQLite-Speicher eigener Bauart.
Sein Schema wird durch die handgepflegten `MADStoreSchema`-Deskriptoren
(`MAD/Source/rptq/store/`) beschrieben, von `-createSchemaSQL` erzeugt und von
`MADStoreTests` gegen das kompilierte Modell abgeglichen. Der Speicher führt
seine Schemaversion in `PRAGMA user_version`: Version 1 ist das ausgelieferte
Schema (fehlend oder 0), Version 2 ergänzt `RptqQuery.sqlSourceText` – das vom
Benutzer eingefügte SQL, unverändert aufbewahrt (`docs/developers/sql-entry.md`
§8) –, Version 3 ergänzt die Kompositionsfelder, und Version 4 ergänzt Layouts pro
Knoten. `MADStore` wendet beim Öffnen die fehlenden Schritte an; jeder Deskriptor
markiert die Revision, die ihn eingeführt hat, mit `introducedInVersion` in
`MAD/Source/rptq/store/MADStoreSchema.m`.

Die Komposition ergänzte in Revision 3:

| Ergänzung | Zweck |
|---|---|
| `RptqQuery.name` | Ein benutzerseitig lesbarer Name für einen Bericht im Graphen. |
| `RptqDocument.rootQuery` | Der Standardbericht des Dokuments (das Ergebnis). |
| `RptqQueryTable.upstreamQuery` | Eine Tabelle, deren Quelle eine andere Abfrage ist, keine entfernte Schematabelle. |
| `RptqQueryField.outputIndex`, `RptqQueryField.outputKey` | Der stabile Name und die Reihenfolge der Ausgabespalten eines komponierenden Berichts. |

Revision 4 ergänzt `RptqDocumentSection.ownerQuery`: Jede Abfrage kann eigene
Layoutbereiche und -elemente besitzen, sodass jeder Bericht einer Komposition eigene
Bänder und Feldbindungen hat. Ein Leser muss jeden Schritt bis zur `user_version`
des Dokuments anwenden; ein älterer Leser verweigert ein neueres Dokument, statt ein
Teil-Schema zu lesen.

Die Felder der Tabelle `RptqQuery`:

| Spalte | Typ | Hinweise |
|---|---|---|
| `identifier` | INTEGER | der Zeilenschlüssel |
| `cachedText` | TEXT | |
| `override` | INTEGER | |
| `overrideText` | TEXT | |
| `sqlSourceText` | TEXT | die zuletzt erfolgreich angewendete eingefügte Anweisung, unverändert; andernfalls NULL |
| `inDatabase_identifier` | INTEGER | Fremdschlüssel auf `RptqDatabase` |
