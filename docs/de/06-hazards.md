---
layout: default
lang: de-DE
---

## 6. Fallstricke, die ein zweiter Leser bewältigen muss

Dies sind Mängel des aktuellen Formats, keine Meinungen. Zu jedem wird
angegeben, was er brechen würde.

| # | Fallstrick | Konsequenz |
|---|---|---|
| H1 | **Keine Magic Bytes.** Die Datei wird ausschließlich anhand der Dateiendung erkannt (`MADocument.m:459`). | Windows hat keine aussagekräftige `.mad`-Zuordnung, und eine umbenannte Datei ist nicht identifizierbar. Siehe §7. |
| H2 | **WAL und SHM werden mit ausgeliefert.** `analyitics-wal` ist 313 KB groß bei einer 516 KB großen Datenbank. | Ein Leser, der das WAL ignoriert, liest veraltete Daten. Eine CLI muss entweder das WAL erneut abspielen oder vor dem Archivieren einen Checkpoint verlangen. |
| H3 | **Core-Data-Schema im Inneren.** | Bindet jeden Leser an Core Data, das außerhalb von Apple-Plattformen nicht existiert. Das Format kann nicht als portabel bezeichnet werden, solange dies nicht gelöst ist. |
| H4 | **Versteckte Dateien werden übersprungen** (`MADArchiveManager.m:111`). | Jeder künftige versteckte Eintrag wird stillschweigend aus dem Archiv entfernt. |
| H5 | **`analyitics` ist falsch geschrieben** – auf dem Datenträger. | Kann nicht korrigiert werden, ohne bestehende Dokumente zu brechen. |
| H6 | **`version` ist im Schreiber ein `double`, in den Beispielen eine Ganzzahl.** | Konsumenten müssen beide Formen akzeptieren. |
| H7 | **Die SQLite-Kompilierungsflags sind nicht fixiert.** `build_sqlite3.sh` deklariert 20 Präprozessor-Definitionen; das Target `MADSqlite3` wendet eine an. | Die Engine, die `.maddb` schreibt, verwendet eine Seitengröße von 4096 Byte, wo das Skript 8192 verlangt, und es fehlen FTS5 und STAT4. Die Seitengröße wird in den Dateikopf geschrieben, das Format ist also durch Zufall definiert. **Inzwischen behoben**: Die Definitionen liegen in `Compressor/sqlite3.xcconfig`, das sowohl das Target als auch das Skript lesen. Seitdem geschriebene Caches haben 8192-Byte-Seiten; ältere lassen sich weiterhin öffnen, weil SQLite die Seitengröße aus dem Dateikopf liest. Siehe `docs/project/LIBRARIES.md` §4. |
