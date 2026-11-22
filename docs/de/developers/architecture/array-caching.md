---
layout: default
lang: de-DE
title: "MADArrayCaching"
description: "Das plattengestützte, nur anhängende Array hinter dem Render-Cache des Berichts."
---

# `MADArrayCaching`

Diese Seite beschreibt `MADArrayCaching`, das plattengestützte, nur anhängende Array, das als Render-Cache des Berichts dient.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

Ein plattengestütztes, nur anhängendes geordnetes Array, das als **Render-Cache** des Berichts dient. Geschrieben am 2026-10-01 gegen `master` bei `7ebe82f89`.

---

## Was es ist

`MADArrayCaching<ObjectType>` (in `MADSqlite3`) ist eine Unterklasse von `NSEnumerator`, die sich wie ein `NSMutableArray` verhält, dessen Elemente auf der Platte statt im Speicher liegen. Jedes Element wird mit `NSKeyedArchiver` serialisiert und als BLOB in einer SQLite-Datei gespeichert. Es ist die Klasse hinter den `.madac`-Begleitdateien in `MAD_FORMAT.md` §5.

Zwei Instanzen pro Dokument, beide im Besitz von `MADReportFormatter`:

| Kennungs-Suffix | Enthält | Elementtyp |
|---|---|---|
| `…ih{w,h}` | die Seiten-**Indizes** (welche Zeilen auf welche Seite gelangen) | `NSArray<NSNumber *>` |
| `…lh{w,h}` | die Seiten-**Layouts** (Abschnittsdarstellungen pro Seite) | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter` füllt sie mit `beginBulkInserts` / `addObject:` / `endBulkInserts` und liest sie mit `objectAtIndex:` / `objectAtIndexedSubscript:` zurück. Das ist der Render-Cache — die ~15 MB `.madac`-Dateien in einem Music-Cache — und er ist es, der ein erneutes Rendern das Neuberechnen des Seitenlayouts überspringen lässt.

## Format auf der Platte

`<identifier>.madac` ist eine gewöhnliche SQLite-Datei mit einer Tabelle:

| Spalte | Typ | Bedeutung |
|---|---|---|
| `ci` | INTEGER, Primärschlüssel | der Index des Elements (0, 1, 2, …) |
| `ck` | BLOB | das mit `NSKeyedArchiver` serialisierte Element |

Die Datei liegt im Cache-Verzeichnis des Dokuments und wird benannt durch
`[self.identifier stringByAppendingPathExtension:@"madac"]` (`MADArrayCaching.m:269-274`), wobei `identifier` aus dem `layoutIdentifier` des Formatierers + `ih`/`lh` + Seitengröße besteht.

## API

`initWithIdentifier:cachedDelegate:types:` — `cachedDelegate` liefert das Cache-Verzeichnis über `MADCacheProtocol`, `types` ist die Menge der Klassen, die `NSKeyedUnarchiver` decodieren darf.

Dann: `initializeDatabase` (öffnen, die Tabelle anlegen, falls sie fehlt), `addObject:` (anhängen), 
`objectAtIndex:` / `objectAtIndexedSubscript:` (lesen), `beginBulkInserts` / `endBulkInserts` (Transaktion um viele Anhänge), `removeAllObjects`, `finalizeDatabase` und die Zugriffsmethoden `count` / `state` / `identifier`.

## Warum es schnell ist (das Design stimmt)

- **Vorbereitete Anweisungen.** Die Anweisungen zum Einfügen, Auswählen und Zählen werden einmal kompiliert (`prepareStatement*`) und pro Aufruf neu gebunden — kein erneutes Parsen.
- **Indizierte Nachschlagen.** `ci` ist der Primärschlüssel, also ist `objectAtIndex:` ein `SELECT ck WHERE ci = ?` — eine O(1)-Indexabfrage, kein Scan.
- **Massenhaftes Einfügen in einer Transaktion.** `beginBulkInserts` / `endBulkInserts` umschließen die Anhänge, sodass ein vollständiges Rendern ein Commit ist statt ein fsync pro Seite.
- **Ein Speicher-Cache pro Element.** `objectAtIndex:` cached jedes Element, das es entarchiviert (nach Index verschlüsselt), sodass ein wiederholtes Lesen — das normale Muster des Renderers — ein `NSDictionary`-Nachschlagen ohne SQLite-Rundreise und ohne Entarchivieren ist. `lastObjectSelected` bleibt für `nextObject` erhalten.
- **Zwei serielle Warteschlangen** (`archivingQueue`, `unarchiveQueue`) halten die einzige SQLite-Verbindung bei einem Schreiber und einem Leser.

Die dominierende Kosten ist die Serialisierung mit `NSKeyedArchiver` / `NSKeyedUnarchiver`, nicht SQLite — der Render-Cache verbringt seine Zeit mit dem Marshalling von `MADSectionRepresentation`-Graphen, was dieselbe Arbeit ist, die der Formatierer ohnehin erledigen würde.

## Gefundene Probleme

Punkte 1–4 behoben am 2026-10-01; Punkte 5–6 bleiben offen und werden festgehalten statt behoben (der Enumerator ist toter Code, und die Nebenläufigkeitsfalle ist latent, solange der Formatierer einthreadig ist).

1. **`-isEmpty` ist invertiert.** `MADArrayCaching.m:440` lautet
   `return _numberOfRows > 0;` — es gibt YES zurück, wenn der Cache *Zeilen hat*. Es ist toter Code (kein Aufrufer), also eine latente Falle, kein aktiver Fehler. **Behoben** und als schreibgeschützte Eigenschaft offengelegt.
2. **`-count` gibt für einen leeren Cache 1 zurück.** `MADArrayCaching.m:424-438` berechnet count als `max(ci) + 1`, aber wenn die Tabelle leer ist, gibt `SELECT … ORDER BY ci DESC LIMIT 1` `SQLITE_DONE` zurück, und `sqlite3_column_int64` auf einer abgeschlossenen Anweisung liest Müll; das Ergebnis ist 1 statt 0. **Behoben.**
3. **`-readDataAtIndex:` und `-writeData:` sind tot.** Nicht im Header, keine Aufrufer. Sie sind ein übrig gebliebener Pfad mit rohem `NSData`, ersetzt durch `addObject:`. `readDataAtIndex:` vermischt zudem Typen: bei einem Treffer auf `lastObjectSelected` gibt es das *entarchivierte* Objekt zurück, nicht `NSData`. **Gelöscht.**
4. **Die Tabellen-/Spaltenkonstanten sind dupliziert.** `MTArrayCachedTableName` / `…ColumnKey` / `…ColumnValue` / `…Extension` werden in `MADArrayCaching.m` als `static` deklariert und in `MADArrayCachingEnumerator.m` erneut global deklariert. Ein Header sollte sie besitzen. **Behoben** — die `extern`-Deklarationen liegen jetzt in `MADArrayCaching.h`, die Definitionen in `MADArrayCaching.m`.
5. **`MADArrayCachingEnumerator` nutzt den alten Entarchivierer.** Er ruft das veraltete `unarchiveObjectWithData:` (nicht sicher) auf, wo `MADArrayCaching` `unarchivedObjectOfClasses:` verwendet. Und sein `nextObject` setzt die Anweisung nach jedem Schritt zurück, sodass manuelles Iterieren nie voranschreitet (die schnelle Aufzählung über `countByEnumeratingWithState:` ist nicht betroffen). **Weiterhin offen** — die Klasse hat keine Aufrufer.
6. **`_numberOfRows` wird außerhalb der Warteschlange gelesen.** `addObject:` liest `_numberOfRows` vor den `dispatch_*`-Aufrufen, sodass nebenläufige Anhänge bei einem Index kollidieren würden. Der Formatierer ruft sie heute einthreadig auf, also ist es latent. **Weiterhin offen.**

## Vorgeschlagene Verbesserungen

Nach Wert geordnet:

1. `-isEmpty` und `-count` beheben (zwei einzeilige Korrekturen) und das tote Paar `readDataAtIndex:` / `writeData:` löschen. Verhaltenssicher: die ersten beiden sind Fehlerbehebungen, das zweite ist toter Code mit einem Typfehler.
2. Die Konstanten `MTArrayCached*` in einen einzigen Header verschieben, den beide Dateien importieren.
3. `MADArrayCachingEnumerator` auf denselben Entarchivierer wie `MADArrayCaching` bringen und sein defektes `nextObject` beheben oder entfernen.
4. Nur falls das Profiling es zeigt: `NSKeyedArchiver` durch einen leichteren, cache-spezifischen Serialisierer ersetzen und/oder das `dispatch_sync` pro Lesevorgang für einen direkten Aufruf aufgeben, wenn die Warteschlange bereits gehört wird. Das sind die Hebel für „wirklich schnell“; die Korrektheitspunkte oben kommen zuerst.
