# `MADArrayCaching`

A disk-backed, append-only ordered array, used as the report's **render cache**. Written
2026-10-01 against `master` at `7ebe82f89`.

---

## What it is

`MADArrayCaching<ObjectType>` (in `MADSqlite3`) is an `NSEnumerator` subclass that behaves like
an `NSMutableArray` whose elements live on disk instead of in memory. Each element is serialised
with `NSKeyedArchiver` and stored as a BLOB in a SQLite file. It is the class behind the
`.madac` companion files in `MAD_FORMAT.md` §5.

Two instances per document, both owned by `MADReportFormatter`:

| Identifier suffix | Holds | Element type |
|---|---|---|
| `…ih{w,h}` | the page **indexes** (which rows land on each page) | `NSArray<NSNumber *>` |
| `…lh{w,h}` | the page **layouts** (section representations per page) | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter` fills them with `beginBulkInserts` / `addObject:` / `endBulkInserts` and
reads them back with `objectAtIndex:` / `objectAtIndexedSubscript:`. This is the render cache —
the ~15 MB of `.madac` files in a Music cache — and it is what lets a re-render skip recomputing
the page layout.

## On-disk format

`<identifier>.madac` is an ordinary SQLite file with one table:

| Column | Type | Meaning |
|---|---|---|
| `ci` | INTEGER, primary key | the element's index (0, 1, 2, …) |
| `ck` | BLOB | the `NSKeyedArchiver`-serialised element |

The file lives in the document's cache directory, named by
`[self.identifier stringByAppendingPathExtension:@"madac"]` (`MADArrayCaching.m:269-274`), where
`identifier` is the formatter's `layoutIdentifier` + `ih`/`lh` + page size.

## API

`initWithIdentifier:cachedDelegate:types:` — `cachedDelegate` supplies the cache directory via
`MADCacheProtocol`, `types` is the set of classes `NSKeyedUnarchiver` may decode.

Then: `initializeDatabase` (open, create the table if absent), `addObject:` (append), 
`objectAtIndex:` / `objectAtIndexedSubscript:` (read), `beginBulkInserts` / `endBulkInserts`
(transaction around many appends), `removeAllObjects`, `finalizeDatabase`, and the `count` /
`state` / `identifier` accessors.

## Why it is fast (the design is right)

- **Prepared statements.** The insert, select and count statements are compiled once
  (`prepareStatement*`) and re-bound per call — no re-parsing.
- **Indexed lookups.** `ci` is the primary key, so `objectAtIndex:` is a `SELECT ck WHERE ci = ?`
  — an O(1) index probe, not a scan.
- **Bulk inserts in a transaction.** `beginBulkInserts` / `endBulkInserts` wrap the appends, so
  a full render is one commit rather than one fsync per page.
- **A per-element memory cache.** `objectAtIndex:` caches every element it unarchives (keyed by
  index), so a repeated read — the renderer's normal pattern — is an `NSDictionary` lookup with
  no SQLite round-trip and no unarchive. `lastObjectSelected` remains for `nextObject`.
- **Two serial queues** (`archivingQueue`, `unarchiveQueue`) keep the single SQLite connection
  to one writer and one reader.

The dominant cost is `NSKeyedArchiver` / `NSKeyedUnarchiver` serialisation, not SQLite — the
render cache spends its time marshalling `MADSectionRepresentation` graphs, which is the same
work the formatter would do anyway.

## Issues found

Items 1–4 fixed 2026-10-01; items 5–6 remain open and are recorded rather than fixed (the
enumerator is dead code, and the concurrency footgun is latent while the formatter is
single-threaded).

1. **`-isEmpty` is inverted.** `MADArrayCaching.m:440` is
   `return _numberOfRows > 0;` — it returns YES when the cache *has* rows. It is dead code
   (no caller), so it is a latent trap, not a live bug. **Fixed**, and exposed as a readonly
   property.
2. **`-count` returns 1 for an empty cache.** `MADArrayCaching.m:424-438` computes count as
   `max(ci) + 1`, but when the table is empty the `SELECT … ORDER BY ci DESC LIMIT 1` returns
   `SQLITE_DONE`, and `sqlite3_column_int64` on a done statement reads garbage; the result is 1
   instead of 0. **Fixed.**
3. **`-readDataAtIndex:` and `-writeData:` are dead.** Not in the header, no callers. They are a
   leftover raw-`NSData` path superseded by `addObject:`. `readDataAtIndex:` also mixes types:
   on a `lastObjectSelected` hit it returns the *unarchived* object, not `NSData`. **Deleted.**
4. **The table/column constants are duplicated.** `MTArrayCachedTableName` / `…ColumnKey` /
   `…ColumnValue` / `…Extension` are declared `static` in `MADArrayCaching.m` and re-declared
   global in `MADArrayCachingEnumerator.m`. One header should own them. **Fixed** — the
   `extern` declarations now live in `MADArrayCaching.h` with the definitions in
   `MADArrayCaching.m`.
5. **`MADArrayCachingEnumerator` is on the old unarchiver.** It calls the deprecated
   `unarchiveObjectWithData:` (non-secure) where `MADArrayCaching` uses
   `unarchivedObjectOfClasses:`. And its `nextObject` resets the statement after every step, so
   manual iteration never advances (fast enumeration via `countByEnumeratingWithState:` is
   unaffected). **Still open** — the class has no callers.
6. **`_numberOfRows` is read outside the queue.** `addObject:` reads `_numberOfRows` before the
   `dispatch_*`, so concurrent appends would collide on an index. The formatter calls them
   single-threaded today, so it is latent. **Still open.**

## Suggested improvements

In order of value:

1. Fix `-isEmpty` and `-count` (two one-line corrections), and delete the dead
   `readDataAtIndex:` / `writeData:` pair. Behaviour-safe: the first two are bug fixes, the
   second is dead code with a type bug.
2. Move the `MTArrayCached*` constants into a single header both files import.
3. Bring `MADArrayCachingEnumerator` up to the same unarchiver as `MADArrayCaching`, and fix or
   remove its broken `nextObject`.
4. Only if profiling shows it: replace `NSKeyedArchiver` with a lighter, cache-specific
   serializer, and/or drop the per-read `dispatch_sync` for a direct call when the queue is
   already owned. These are the "really fast" levers; the correctness items above come first.
