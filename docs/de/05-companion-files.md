---
layout: default
lang: de-DE
---

## 5. Was *nicht* im Dokument steht: die Begleitdateien

Eine `.mad`-Datei ist eine Definition, kein Datensatz. Alles, was ein Bericht
*anzeigt*, ist abgeleitet, neu erzeugbar und bewusst außerhalb des Archivs.
Daneben entstehen drei Arten von Dateien:

| Datei | Geschrieben von | Inhalt |
|---|---|---|
| `<hash>.maddb` | `MADDataTableFast` | die Zeilendaten des Berichts |
| `<hash>.mdcache` | `MADDataTable` (`:354`) | eine Property List, die die virtuellen Tabellen über diesen Daten beschreibt |
| `<hash>{ih,lh}{w, h}.madac` | `MADArrayCaching`, gespeist von `MADReportFormatter` (`:179`, `:183`) | gerenderte Seiteninhalte – eine **SQLite**-Datenbank, indiziert nach Layout-Identifikator und Seitengröße. `ih` ist der Berichts-*Index*-Cache, `lh` der Berichts-*Layout*-Cache |

Alle drei liegen zusammen in einem Verzeichnis pro Dokument, benannt nach
`dataTableIdHash`. `MADocument.m:286-300` baut die Tabelle aus einem Verzeichnis,
das `MADURLFactory newURLCacheFilesDirectoryForFilename:` (`MADURLFactory.m:47-49`)
liefert; es liegt benutzer- und gerätespezifisch außerhalb des Dokuments:

```objc
MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
...
NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
self.urlDataTableCache = cacheUrl;
[datatable loadFromCacheWithUrl:cacheUrl error:&error];
```

### 5.1 Die Größenordnungen entsprechen nicht dem, was der Name vermuten lässt

Gemessen in einem realen Cache-Verzeichnis unter `Library/Caches/`:

| Art | Dateien | Gesamt |
|---|---|---|
| `<hash>.maddb` | 1 | 816 KB |
| `<hash>.mdcache` | 1 | 1,7 KB |
| `<hash>{ih,lh}{...}.madac` | 6 | **~15 MB** |

Die `.madac`-Dateien sind der Seitencache des Formatierers. Die Schlüssel `ih`
und `lh` stammen aus `MADReportFormatter.m:179` und `:183`, die
`<layoutIdentifier>ih<CGSize>` und `<layoutIdentifier>lh<CGSize>` bilden;
`{612, 792}` ist US Letter in Punkten. Der Cache ist also nach *Layout-Identität
und Seitengeometrie* indiziert – genau das macht die beiden Fallstricke in §5.3
real.

Gemessen an einem Dokument unter 80 KB ist der Render-Cache etwa **200-mal so
groß wie das Dokument**. Die Zeilendaten, von denen man erwarten würde, dass sie
dominieren, machen weniger als 6 % des Verzeichnisses aus.

**Warum er bewusst so groß ist.** Der Umfang ist eine Folge des Designs, kein
Unfall, den man wegoptimieren sollte. Zwei Gründe, beide aus der Beschreibung des
Benutzers (2026-10-01):

1. **Zweistufiges Rendern.** Seitenzahl und Gruppierungen lassen sich erst
   kennen, wenn die vollständige Zeilenmenge vorliegt. Eine Zählgruppe in der
   Berichtsfußzeile kann am Ende summiert werden, aber eine in der
   Berichtskopfzeile muss bekannt sein, bevor die erste Seite gesetzt wird – und
   Seiten lassen sich erst nummerieren, wenn die Zeilenzahl bekannt ist –, also
   wird die gesamte Ergebnismenge einmal gelesen und auf dem Gerät gehalten.
2. **Der Cache ist die Plattform für künftige Ansichten.** Sobald die Zeilen
   lokal vorliegen, lassen sich verschiedene Ansichten derselben Daten aus dem
   einen Cache bauen, ohne die Quelle erneut abzufragen – das Gegenteil einer
   Website, die für jede Seite erneut die Datenbank anspricht. Auf diesem einen
   Cache ist mehr geplant, daher wäre es falsch, ihn als Wegwerfspeicher zu
   behandeln.

Der Cache ließe sich komprimieren, aber das ist nicht die vordringliche Änderung.

### 5.2 Die Konsequenzen

- Ein `.mad` ist **klein und in sich geschlossen**: eine Definition, kein
  Datensatz. Beide ausgelieferten Beispiele bleiben unter 80 KB.
- Alles im Cache-Verzeichnis ist **entbehrlich**. Löschen kostet eine
  Aktualisierung, nie ein Dokument.
- Es wird **nicht zwischen Geräten geteilt** und liegt nicht in iCloud, selbst
  wenn das Dokument dort liegt. Jedes Gerät lädt beim ersten Öffnen neu.
- `.mad` ist daher **nicht** die „komprimierte SQLite-Datei mit den Daten“, die
  sie zu sein scheint. Es ist eine komprimierte SQLite-Datei mit der
  *Definition*.

### 5.3 Was die Begleitdateien noch nicht definieren

Das Verzeichnis ist benannt und befüllt, aber nicht spezifiziert. Drei Lücken,
bei denen eine zweite Plattform raten müsste:

1. **Der Render-Cache wird nach Dateinamen indiziert, nicht nach Inhalt –
   bestätigt am 2026-10-01.** `MADReportFormatter -layoutIdentifier`
   (`MADReportFormatter.m:186`) gibt
   `_overrideIdentifier ? _overrideIdentifier.hash : _filename.hash` zurück. Der
   Schlüssel ist also der *Name* des Dokuments plus die Seitengröße, und nichts
   im Ladepfad prüft den Inhalt: `MADArrayCaching -initializeDatabase`
   (`MADArrayCaching.m:141`) verwendet die vorhandene SQLite-Datei wieder, sobald
   ihre Tabelle `ac` existiert, ohne Version, Zeitstempel oder Inhalts-Hash im
   Schlüssel oder beim Laden. **Eine Bearbeitung des Dokuments unter demselben
   Dateinamen macht seine `.madac`-Dateien nicht ungültig** – bis die Dateien
   gelöscht werden oder eine andere Seitengröße gerendert wird, wird eine
   veraltete Seite ausgeliefert.

   **Am 2026-10-01 gemessen, im Einklang damit.** Um 15:22 wurden ein headless
   Refresh und ein Export gegen das London-Dokument ausgeführt. Danach enthielt
   sein Cache-Verzeichnis:

   | Datei | Größe | mtime |
   |---|---|---|
   | `<hash>.maddb` | 835,584 | 15:22 |
   | `<hash>.mdcache` | 1,644 | 15:22 |
   | `<layoutId>ih{612, 792}.madac` | 81,920 | 15:22 |
   | `<layoutId>lh{612, 792}.madac` | 737,280 | 15:22 |
   | `<layoutId>ih{0, 0}.madac` | 1,867,776 | **10:52** |
   | `<layoutId>lh{0, 0}.madac` | 4,333,568 | **10:52** |

   Eine Aktualisierung schreibt nur die Dateien neu, die sie braucht – die
   Einträge `{612, 792}` (US Letter, die Seitengeometrie des PDF) – und lässt
   den Rest unangetastet. Die Einträge `{0, 0}` wurden nicht berührt, und
   zusammen machen sie 6,0 MB der 15 MB des Verzeichnisses aus. `{0, 0}` ist die
   Seitengröße, bevor eine echte Geometrie bekannt ist; diese beiden Dateien sind
   daher mit hoher Wahrscheinlichkeit ein Messdurchlauf. Im dateinamenbasierten
   Schema werden sie außerdem durch nichts außer Löschen ungültig.
2. **Nichts legt fest, was gelöscht werden darf.** Alle drei Arten sind neu
   erzeugbar, alle drei sollten also sicher sein – aber eine 0-Byte-`.maddb` in
   einem ansonsten unberührten Verzeichnis zeigt, dass das Verzeichnis angelegt
   wird, bevor es befüllt wird, und nichts sagt, ob ein solches Verzeichnis
   aussagekräftig ist.
3. **Das Schema der `.mdcache`-Property-List.** Inzwischen bekannt – es ist das
   serialisierte Schema der Ergebnistabelle, geschrieben von
   `MADDataTableFast -copyPlist` und gelesen von `-loadWithPlist:`. Schlüssel auf
   oberster Ebene: `name`, `columnKeys` (geordnetes Array von `c<hash>`-IDs),
   `columns` (ein Dictionary mit `c<hash>` als Schlüssel, jeweils eine
   `MADDataColumn`-Property-List: `caption`, `fieldName`, `identifier`, `type`,
   `nativeType`, `dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`,
   `isAutoIncrement`, `defaultValue`), `rowCounter`, `sortDescriptors` und den
   `bulkInsertLoop` der Fast-Tabelle. `defaultValue` ist der Sentinel `~MTNull~`
   (`MADDataColumnNullSentinel`, `MADDataColumn.m:23`). Zu beachten sind die
   beiden dauerhaften Eigenheiten: `dataPercision` ist im Format falsch geschrieben,
   und der Sentinel `~MTNull~` ist ein dritter Null-Marker, verschieden von der
   Familie `"<null>"` / `"(null)"` aus `docs/project/BUGS.md`, Track 1.5.
