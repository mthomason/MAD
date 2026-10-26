---
layout: default
---

## 6. Hazards a second reader must handle

These are defects in the current format, not opinions. Each is stated with what it
would break.

| # | Hazard | Consequence |
|---|---|---|
| H1 | **No magic bytes.** The file is detected by extension only (`MADocument.m:459`). | Windows has no meaningful `.mad` association, and a renamed file is unidentifiable. See §7. |
| H2 | **WAL and SHM are shipped.** `analyitics-wal` is 313 KB against a 516 KB database. | A reader that ignores the WAL reads stale data. A CLI must either replay the WAL or require a checkpoint before archiving. |
| H3 | **Core Data schema inside.** | Ties every reader to Core Data, which does not exist off Apple platforms. The format cannot be called portable until this is addressed. |
| H4 | **Hidden files are skipped** (`MADArchiveManager.m:111`). | Any future hidden member is silently dropped from the archive. |
| H5 | **`analyitics` is misspelled** on disk. | Cannot be corrected without breaking existing documents. |
| H6 | **`version` is a double in the writer, an integer in the samples.** | Consumers must accept both. |
| H7 | **sqlite compile flags are not pinned.** `build_sqlite3.sh` declares 20 defines; the `MADSqlite3` target applies one. | The engine that writes `.maddb` uses a 4096-byte page size where the script asks 8192, and is missing FTS5 and STAT4. The page size is written into the file header, so the format is defined by accident. **Now fixed**: the defines live in `Compressor/sqlite3.xcconfig`, which both the target and the script read. Caches written since have 8192-byte pages; older ones still open, because SQLite reads the page size from the header. See `docs/project/LIBRARIES.md` §4. |
