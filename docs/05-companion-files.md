---
layout: default
---

## 5. What is *not* in the document: the companion files

A `.mad` is a definition, not a dataset. Everything a report *displays* is derived,
regenerable, and deliberately outside the archive. Three kinds of file are built beside it:

| File | Written by | What it holds |
|---|---|---|
| `<hash>.maddb` | `MADDataTableFast` | the report's row data |
| `<hash>.mdcache` | `MADDataTable` (`:354`) | a plist describing the virtual tables over that data |
| `<hash>{ih,lh}{w, h}.madac` | `MADArrayCaching`, fed by `MADReportFormatter` (`:179`, `:183`) | rendered page content — a **SQLite** database, keyed by layout identifier and page size. `ih` is the report-*index* cache, `lh` the report-*layout* cache |

All three live together in one directory per document, named by `dataTableIdHash`.
`MADocument.m:286-300` builds the table from a directory supplied by
`MADURLFactory newURLCacheFilesDirectoryForFilename:` (`MADURLFactory.m:47-49`), which
resolves to a per-user, per-device location outside the document:

```objc
MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
...
NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
self.urlDataTableCache = cacheUrl;
[datatable loadFromCacheWithUrl:cacheUrl error:&error];
```

### 5.1 The sizes are not what the name suggests

Measured on a real cache directory under `Library/Caches/`:

| Kind | Files | Total |
|---|---|---|
| `<hash>.maddb` | 1 | 816 KB |
| `<hash>.mdcache` | 1 | 1.7 KB |
| `<hash>{ih,lh}{...}.madac` | 6 | **~15 MB** |

The `.madac` files are the formatter's page cache. The `ih` and `lh` keys come from
`MADReportFormatter.m:179` and `:183`, which build `<layoutIdentifier>ih<CGSize>` and
`<layoutIdentifier>lh<CGSize>`; `{612, 792}` is US Letter in points. So the cache is
keyed by *layout identity and page geometry* -- which is what makes the two hazards
in §5.3 real.

Against a document under 80 KB, the render cache is roughly **200× the document**. The
row data, which one would expect to dominate, is under 6% of the directory.

**Why it is deliberately this big.** The size is a consequence of the design, not an
accident to be optimised away. Two reasons, both the user's own description (2026-10-01):

1. **Two-pass rendering.** Page count and groupings cannot be known until the full row
   set is in hand. A count group in the report footer can be summed at the end, but one
   in the report header must be known before the first page is laid out -- and pages
   cannot be numbered until the row count is known -- so the whole result set is pulled
   once and held on device.
2. **The cache is the platform for future views.** Once the rows are local, different
   views of the same data can be built from the one cache without re-querying the
   source, the opposite of a website that hits the database again for every page. There
   is more planned on top of this one cache, so treating it as scratch space would be
   wrong.

The cache could be compressed, but it is not the pressing thing to change.

### 5.2 The consequences

- A `.mad` is **small and self-contained**: it is a definition, not a dataset. Both
  shipping samples are under 80 KB.
- Everything in the cache directory is **disposable**. Deleting it costs a refresh,
  never a document.
- It is **not shared** between devices, and is not in iCloud, even if the document is.
  Every device re-fetches on first open.
- `.mad` is therefore **not** the "compressed SQLite file with the data in it" it might
  appear to be. It is a compressed SQLite file with the *definition* in it.

### 5.3 What the companion files do not yet define

The directory is named and populated but not specified. Three gaps, each of which a
second platform would have to guess at:

1. **The render cache is keyed by filename, not by content — confirmed 2026-10-01.**
   `MADReportFormatter -layoutIdentifier` (`MADReportFormatter.m:186`) returns
   `_overrideIdentifier ? _overrideIdentifier.hash : _filename.hash`. So the key is the
   document's *name* plus the page size, and nothing in the load path checks content:
   `MADArrayCaching -initializeDatabase` (`MADArrayCaching.m:141`) reuses the existing
   SQLite file whenever its `ac` table is present, with no version, timestamp or content
   hash anywhere in the key or the load. **Editing a document under the same filename
   does not invalidate its `.madac` files** — a stale page is served until the files are
   deleted or a different page size is rendered.

   **Measured on 2026-10-01, consistent with that.** A headless refresh and export were
   run against the London document at 15:22. In its cache directory afterwards:

   | File | Size | mtime |
   |---|---|---|
   | `<hash>.maddb` | 835,584 | 15:22 |
   | `<hash>.mdcache` | 1,644 | 15:22 |
   | `<layoutId>ih{612, 792}.madac` | 81,920 | 15:22 |
   | `<layoutId>lh{612, 792}.madac` | 737,280 | 15:22 |
   | `<layoutId>ih{0, 0}.madac` | 1,867,776 | **10:52** |
   | `<layoutId>lh{0, 0}.madac` | 4,333,568 | **10:52** |

   A refresh rewrites only the files it needs — the `{612, 792}` entries (US Letter, the
   PDF's page geometry) — and leaves the rest. The `{0, 0}` entries were not touched, and
   together they are 6.0 MB of the directory's 15 MB. `{0, 0}` is the page size before a
   real geometry is known, so those two files are almost certainly a measurement pass;
   they are also, under the filename-keyed scheme, never invalidated by anything short of
   deletion.
2. **Nothing says what may be deleted.** All three kinds are regenerable, so all three
   should be safe — but a 0-byte `.maddb` in a directory otherwise untouched shows the
   directory is created before it is filled, and nothing states whether such a
   directory is meaningful.
3. **The `.mdcache` plist schema.** Now known — it is the serialized schema of the result
   table, written by `MADDataTableFast -copyPlist` and read by `-loadWithPlist:`. Top-level
   keys: `name`, `columnKeys` (ordered array of `c<hash>` ids), `columns` (a dict keyed by
   `c<hash>`, each a `MADDataColumn` plist: `caption`, `fieldName`, `identifier`, `type`,
   `nativeType`, `dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`,
   `isAutoIncrement`, `defaultValue`), `rowCounter`, `sortDescriptors`, and the fast table's
   `bulkInsertLoop`. `defaultValue` is the sentinel `~MTNull~`
   (`MADDataColumnNullSentinel`, `MADDataColumn.m:23`). Note the two persistent quirks:
   `dataPercision` is misspelled in the format, and the `~MTNull~` sentinel is a third null
   marker distinct from the `"<null>"` / `"(null)"` family of `docs/project/BUGS.md` Track 1.5.
