# The `.mad` Document Format

This document defines what a `.mad` file is. It describes the format **as it exists
today**, taken from two shipping sample documents and the code that reads and writes
them, and then states the format **as it should be defined** so that a reader on
another platform -- a command-line tool, a Windows build -- can open a document
without relying on Core Data or on any Apple framework.

Everything in the first half is measured, not inferred. The two samples are
`MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad` and
`…/London.dataset/London.mad`.

---

## 1. What a document is, in one sentence

A `.mad` file is a **bzip2-compressed tar archive** whose members are a Core Data
persistent store, a small property list describing the document, and an optional
thumbnail directory.

The row data a report displays is **not** in the document. It is a derived cache,
regenerated on refresh, and it lives outside the file. That distinction is the single
most important thing in this document and is explained in §5.

---

## 2. The container

```
$ file Music.mad
Music.mad: bzip2 compressed data, block size = 900k
```

The writer is `MADArchiveManager.m:86-100`:

| Property | Value | Where |
|---|---|---|
| Archive format | `pax restricted` | `MADArchiveManager.m:88` |
| Compression filter | bzip2 | `MADArchiveManager.m:95` |
| Hidden files | **skipped** | `MADArchiveManager.m:111` |
| Member paths | relative to the archive root | `MADArchiveManager.m:124-130` |

`pax restricted` means POSIX pax with the extensions ustar already covers, so the
archive is readable by any tar implementation. bzip2 is in every package manager on
every platform. **Nothing in the container is Apple-specific.** A `.mad` file
unpacks with `tar xjf` on macOS, Linux and Windows alike.

### Members

Both shipping samples contain exactly these six entries, in this order:

```
AdditionalContent/
StoreContent/
StoreContent/analyitics-wal
StoreContent/analyitics-shm
StoreContent/analyitics
meta.plist
```

`AdditionalContent/` is present but empty in both samples. It is the directory the
document uses for a thumbnail: `MADocument.m:571-583` reads
`thumbnail@2x.png` from it into `extraInformation`, and
`MADURLFactory.m:58-68` builds that path. It is written by
`-writeAdditionalContent:toURL:…` (`MADocument.m:617-648`) as part of the
`UIManagedDocument` additional-content protocol.

`StoreContent/` is the Core Data persistent store, named by
`+persistentStoreName` (`MADocument.m:650`), which returns `@"analyitics"`.

> The name is misspelled, and it is misspelled **on disk, in shipping documents**.
> It is not a typo in a comment that can be corrected: renaming it changes the store
> filename and breaks every existing `.mad` file. It stays, and this note exists so
> the next reader does not "fix" it.

`meta.plist` is the document's own metadata, written at `MADocument.m:636-644`:

```xml
{
  "generator" => "MAD Designer"
  "version"   => 1
}
```

Version is written as a double (`MADocument.m:611`) and reads back as an integer in
the samples. Consumers should accept either.

---

## 3. The store

`StoreContent/analyitics` is an ordinary SQLite database:

```
StoreContent/analyitics: SQLite 3.x database, last written using SQLite version 3043002,
  writer version 2, read version 2, file counter 52, database pages 126, cookie 0x6e,
  schema 4, largest root page 113, UTF-8, vacuum mode 1, version-valid-for 52
```

It holds the **document definition**: the query, its tables and joins, the report's
sections and elements, and the database schema snapshot. The Core Data model is
`MAD/MAD.xcdatamodel`; its entities all carry the `Rptq` prefix (`RptqDocument`,
`RptqQuery`, `RptqDocumentElement`, `RptqDocumentSection`, …).

Two properties of this store are load-bearing for portability:

1. **It is written in WAL mode.** `-wal` and `-shm` are shipped inside the archive
   alongside the main database. A reader that extracts only `analyitics` and ignores
   the WAL will read a database up to one checkpoint stale. In the `Music` sample the
   WAL is **313 KB against a 516 KB main file** -- this is not a theoretical risk.
2. **It is a Core Data store**, so its schema is Core Data's, not ours. Reading it
   without Core Data means reading Core Data's own tables. That is possible -- it is
   SQLite, and the mapping is stable -- but it is the part of this format that ties a
   reader to Core Data, and it is the reason the migration off Core Data matters here
   more than anywhere else.

---

## 4. Reading and writing, as implemented

```
write:  document model ──▶ UIManagedDocument ──▶ ~/tmp/<name>.mada/ ──▶ tar.bz2 ──▶ <name>.mad
read:   <name>.mad ──▶ tar.bz2 ──▶ ~/tmp/<name>.mada/ ──▶ UIManagedDocument
```

The intermediate directory is called the **guts**. Its extension is `.mada`
(`MADConstants.m:12`, `MADFileExtentionMobleApplicationDocumentArchive`), it is named
after the document, and it is placed in a temporary directory
(`MADURLFactory.m:51-56`, `newURLLocalTemporaryDirectory` → `~/tmp`).

- Save — `MADocument.m:497-514`: write the model to the guts, then archive the guts
  over the document URL.
- Open — `MADocument.m:456-476`: unarchive the document into the guts, then read the
  store from there.

The comment above `-readFromURL:` (`MADocument.m:452-455`) states this in the
author's own words:

> 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
> 2. Read the unarchived file. It's currently a Core Data file.

"It's currently a Core Data file" is the whole migration in five words.

---

## 5. What is *not* in the document

**Row data.** The report's rows live in a `.maddb` SQLite cache, written by
`MADDataTableFast` and addressed through `MADDataTable`.

That cache is deliberately *not* a member of the archive. `MADocument.m:286-300`
builds it from a cache directory supplied by
`MADURLFactory newURLCacheFilesDirectoryForFilename:` (`MADURLFactory.m:47-49`),
which resolves to `NSCachesDirectory/<id>/<tag>.maddb` -- a per-user, per-device
location outside the document:

```objc
MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
...
NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
self.urlDataTableCache = cacheUrl;
[datatable loadFromCacheWithUrl:cacheUrl error:&error];
```

The consequences are worth stating plainly:

- A `.mad` is **small and self-contained**: it is a definition, not a dataset. Both
  shipping samples are under 80 KB.
- Data is **disposable**. Deleting a cache costs a refresh, never a document.
- Data is **not shared** between devices, and is not in iCloud, even if the document
  is. Every device re-fetches on first open.
- `.mad` is therefore **not** the "compressed SQLite file with the data in it" it
  might appear to be. It is a compressed SQLite file with the *definition* in it.

The name `<tag>.mdcache` (`MADDataTable.m:354`) is a sibling plist describing the
virtual tables; it lives in the same cache directory, not in the document.

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
| H7 | **sqlite compile flags are not pinned.** `build_sqlite3.sh` declares 20 defines; the `MADSqlite3` target applies one. | The engine that writes `.maddb` uses a 4096-byte page size where the script asks 8192, and is missing FTS5 and STAT4. The page size is written into the file header, so the format is defined by accident. **Now fixed**: the defines live in `Compressor/sqlite3.xcconfig`, which both the target and the script read. Caches written since have 8192-byte pages; older ones still open, because SQLite reads the page size from the header. See `LIBRARIES.md` §4. |

---

## 7. The format as it should be defined

This is the normative target. It is deliberately a small delta from what exists,
because what exists is nearly right.

### 7.1 Identification by content, not by name

A `.mad` file should begin with a fixed header **outside** the compression stream,
so a reader can identify it from the first bytes:

```
offset 0  8 bytes   "MADFILE\0"      magic
offset 8  2 bytes   uint16 LE        format major version
offset 10 2 bytes   uint16 LE        format minor version
offset 12 4 bytes   uint32 LE        flags (bit 0: WAL checkpointed)
offset 16 ...       bzip2 stream
```

Rationale: this is what removes the Windows problem. The extension becomes a
*convention* for the file browser, not the thing that identifies the file. A `.mad`
renamed to `.zip`, or a document received over a channel that mangles extensions, is
still recognisably a `.mad`. It also gives version detection without decompressing.

The header is backwards-incompatible with the two shipping samples. That is
acceptable *only* because a reader can fall back: no `MADFILE` magic → treat as a
legacy v0 document (§7.4).

### 7.2 A checkpointed store

`meta.plist` gains a member recording whether the store was checkpointed before
archiving, and the writer checkpoints by default. The WAL and SHM members then become
optional, and a reader that finds them must replay them rather than ignore them.

This also shrinks documents: the `Music` sample spends a third of its bytes on a WAL
that a checkpoint would fold into the main file.

### 7.3 Members

| Member | Required | Contents |
|---|---|---|
| `meta.plist` | yes | `generator`, `version`, `checkpointed` |
| `StoreContent/<name>` | yes | the document definition |
| `StoreContent/<name>-wal` / `-shm` | no | present only when not checkpointed |
| `AdditionalContent/` | no | `thumbnail@2x.png` |

### 7.4 Compatibility

- **v0** -- what ships today: no magic, possibly a WAL, `version` 1. Readers must
  accept it indefinitely; both sample documents are v0.
- **v1** -- magic header, checkpointed store, `version` 1, new members as above.

A writer emits v1 and `meta.plist` unchanged otherwise. A reader detects v0 by the
absence of the magic.

---

## 8. Open questions

1. **Does the store need to be Core Data at all?** The definition it holds is a
   modest object graph. A hand-rolled schema in the same SQLite file would remove
   H3, remove the last Apple dependency from the format, and is a prerequisite for
   Windows regardless of what the CLI does. This is a design decision for the
   Core Data migration, not for this document.
2. **Should the thumbnail be in the document?** It is regenerable, like the row
   cache, and it is the only reason `AdditionalContent/` exists. Removing it would
   make every member of a `.mad` authoritative.
3. **Should `.mad` carry the row cache optionally?** A "packed" variant would make a
   document openable offline on a second device at the cost of size. Nothing does
   this today; it is raised because the name invites the expectation (§5).

---

## 9. Verification

The claims in §§2-5 are reproducible:

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

Any change to the format must extend the round-trip fixtures described in
`MAD_CLI.md` §6, so that the definition in this file is pinned by a test rather than
by this prose.
