# The `.mad` Store Migration — Core Data to a Portable SQLite Store

This is the plan for moving the `.mad` document's store off Core Data and onto a SQLite
schema of our own. It is the work behind `MAD_FORMAT.md` §8.1 and `ROADMAP.md` §4.2, and it is
what removes hazard H3 — the last Apple dependency in the format.

Written 2026-10-01 against `master` at `73468c6f4`; revised the same day after reading the
actual Core Data usage in the code, per the user's question *"does this really need core data
style faulting?"* The answer, with evidence, is in §3.

---

## 1. The goal, in the user's own terms

The core issue is **portability**. The store inside a `.mad` is a Core Data SQLite file, and
Core Data does not exist off Apple platforms. Because `MADocument` is a `UIManagedDocument`,
moving off Core Data also removes the iCloud document machinery — and **stripping iCloud is an
explicit part of this plan, not a side effect.** `MADDocument` drops `UIManagedDocument` for
`UIDocument`, the iCloud/ubiquity container and file-coordination paths go away, and document
sync is no longer offered. Old documents are not stranded by this: the user reaches them
through the iOS Files app and opens them with the app, which converts them on open — the
iCloud machinery is not needed to retrieve them.

The user's mental model, which the code confirms: *"I just think of it as a simple database."*
The migration keeps the auto-generated `Rptq` headers as a fixed, hand-maintained contract and
writes the insert/update/read code ourselves.

**The success criterion:** everything keeps working **except iCloud**. Local document
open/save, the query and designer tools, the viewer, refresh/export, and the `.maddb` /
`.mdcache` / `.madac` caches all behave as today; only the iCloud sync path is removed.

---

## 2. What is actually stored

Three things, no more. All of it is a *definition* — the row data lives in the `.maddb` cache
and is not part of this store.

| Part | Entities | How it gets there |
|---|---|---|
| **Schema** | `RptqDatabase`, `RptqDatabaseSchemaTable`, `RptqDatabaseSchemaField`, `RptqDatabaseCredentals` | Imported from the source database at document creation by `MADOperationCreateDocumentImportSchema`, reading `MADDatabaseTable` / `MADDatabaseField` and writing `Rptq` entities. **Reloadable** — the import is a bulk replace (drop the old tables/fields, write the new). |
| **Query** | `RptqQuery`, `RptqQueryTable`, `RptqQueryField`, `RptqQueryLinks`, `RptqQueryGroup`, `RptqQueryPredicate`, `RptqQuerySort` | Built by the user in the MAD Query tab. |
| **Layout** | `RptqDocument`, `RptqDocumentSection`, `RptqDocumentSectionRows`, `RptqDocumentElement` + 8 subclasses, plus value types (`RptqPoint`, `RptqRect`, `RptqSize`, `RptqAlignment`, `RptqBorder`, `RptqTextStyle`, `RptqNumericFormat`, `RptqDirectional*`) | Built by the user in the MAD Designer tab. |

The graph is a tree keyed by the `identifier` (`Integer 64`) that every entity carries. The
32 entities, the four ordered to-many relationships, the four transformable attributes, and
the one many-to-many join table are as described in the model dump that follows this document's
original version.

---

## 3. What the code actually uses Core Data for

This is the research that matters. It is a much smaller surface than "Core Data" sounds.

**Fetch, mostly by identifier.** There are ~81 fetch/execute sites, but the dominant patterns
are: fetch one object by `identifier` (`RptqDocumentElement
-newDocumentElementWithIdentifier:fromObjectContext:`, `RptqDocumentSection
-newDocumentSectionWithIdentifier:…`), and fetch the single root with `fetchLimit = 1`
(`RptqDocument -newDocumentReadFromManagedObjectContext:`). This is a `SELECT … WHERE
identifier = ?` — trivial in a plain SQLite store.

**Relationship traversal, which is faulting today.** Code such as `MADQueryFull.m:151-152`
reads `document.hasDatabaseSchemas.anyObject` then `databaseSchema.hasQueries.anyObject`. That
faults each relationship lazily. But the whole definition is under 80 KB, so **faulting is an
implementation detail, not a requirement** — lazy loading at the granularity of the three parts
(schema, query, layout) is more than enough, and the user's instinct not to load it all at once
is the right one.

**A small set of lifecycle hooks.** `-awakeFromInsert` / `-awakeFromFetch` in ~11 `Rptq+Extras`
files assign `identifier` and defaults. `obtainPermanentIDsForObjects:` appears once. KVO
(`-willChangeValueForKey:` on `identifier`) is used to fan out change notifications. All of
these have plain equivalents.

**Two real Core Data features to replace, both small:**
- `NSFetchedResultsController` — used in `MADQueryBuilderAddTableViewController` and
  `MTGraph+RptqQuery`. It provides sectioning + change tracking for a table view. A plain
  store replaces this with a manual reload-on-change, which is what the app already does
  elsewhere (`reloadData` is everywhere).
- The `NSUndoManager` on the managed object context (§4).

**Undo — the part the user flagged, and it is not a blocker.** All undo is in
`MADDesignerLayout` and it is **manual, high-level undo**: every operation calls
`[delegate.undoManager setActionName:…]` and
`[delegate.undoManager registerUndoWithTarget:self handler:…]`, where the handler invokes the
*inverse* high-level method (for example, `updateElements:setBold:` registers an undo that
calls `updateElements:setBold:NO`). The inverse re-fetches by identifier and re-sets the
property. So undo needs exactly three things, none of them Core Data: an `NSUndoManager`
(a Foundation class), fetch-by-identifier, and set-a-property. It does **not** rely on Core
Data's automatic change tracking — there are no `processPendingChanges` /
`disableUndoRegistration` calls, and no automatic-undo reliance.

**A clean domain layer already exists.** `MADModel*` (`MADModelDocument`, `MADModelDatabase`,
`MADModelQuery`, `MADModelTable`, `MADModelField`, …) are plain `NSObject` subclasses that wrap
the `Rptq` entities and expose the app's vocabulary — `databases`, `firstQuery`,
`tableDictionary`. ~20 files use it; the rest reach `Rptq` directly. This is the seam: the
migration re-points `MADModel*` (and the `Rptq` accessors) at our store, and the domain stays
recognisably the same.

---

## 4. What the store should be

A plain SQLite schema, one table per entity, keyed by `identifier`, with the object graph
preserved as foreign keys and an order column on the ordered relationships. Transformables
become portable scalars (`UIColor` → RGBA, `NSLocale` → identifier string, `UIImage` → PNG).
The many-to-many `inQuery` keeps its join table.

The difference from the first draft is the **loading model**: no per-relationship faulting. The
reader fetches the three parts on demand — open the document, fetch the `RptqDocument` row and
its section tree when the designer tab is shown, fetch the query when the query tab is shown,
fetch the schema when needed. Each is one or two indexed `SELECT`s.

---

## 5. The hard parts, re-ranked

1. **The app integration, not the schema.** Roughly 110 files touch `NSManagedObjectContext`
   / `NSFetchRequest` / `NSManagedObject`, with ~158 fetch/insert sites. This is the bulk of
   the work: replacing `@dynamic` Core Data properties and `NSFetchRequest` with our store.
2. **Undo, but smaller than feared.** Keep `NSUndoManager`; keep `MADDesignerLayout`'s manual
   handlers; provide fetch-by-id and set-property against our store. The undo *design* is
   already right; only its data source changes.
3. **The element hierarchy.** Core Data already flattens the 8 `RptqDocumentElement`
   subclasses into one table with a `Z_ENT` discriminator and name-mangled columns
   (`ZTEXT`/`ZTEXT1`, `ZGROUPNUMBER`/`ZGROUPNUMBER1`). The conversion must therefore go
   **through the model objects** (load with Core Data, re-save to our store), never hand-parse
   the `Z_` tables.
4. **`NSFetchedResultsController`.** Two files; replace with manual reload, which the app
   already does elsewhere.

---

## 6. The conversion

Read a legacy `.mad` with the existing `MADocument` path, walk the object graph, and serialise
it to our schema. This runs once per legacy document on first open after the migration ships,
then re-saves in the new format. The two shipping samples (`London.mad`, `Music.mad`) are the
fixtures that pin it.

---

## 7. Phasing

- **Phase A — the store, standalone.** Define the SQLite schema and a reader/writer pair that
  round-trips a `RptqDocument` graph. Proven headlessly: build a graph in memory, write it,
  read it back, assert equality — including fetch-by-identifier and fetch-by-part.
  *Done:* `MAD/Source/rptq/store/`, with `MADStoreTests`.
- **Phase B — the conversion.** Open a Core Data `.mad`, serialise to the new store. Pinned by
  the two samples through *convert → read → compare*.
  *Done:* `MADStoreConverter` — the one file in the store family that imports Core Data. It
  walks the model objects (never Core Data's `Z_` tables) with `MADStoreSchema` driving the
  attribute and edge lists, so the two cannot drift, and mints identifiers for the ten entities
  the model gives none to. Pinned by `MADStoreConverterTests`, which converts both shipping
  samples and compares the graphs, and counts every row against Core Data as well. One
  discrepancy is carried deliberately: the model calls the credential's key `dbkey` and the
  store calls it `key`, and the converter renames it rather than changing either side.
- **Phase C — the app integration.** Replace the `Rptq` classes' Core Data backing with our
  store, keeping the headers, entity-family by entity-family (schema, then query, then
  sections/elements), and replace `NSFetchedResultsController` with reload-on-change. The
  designer/query/viewer tabs are the acceptance tests, and undo is kept working throughout.
  *Landed 2026-10-03 in three milestones, each ending green* — the details are in
  `MAD_STORE_PHASE_C.md` and the outstanding items in its §9.

  - **(a) the swap and the document path.** All 33 `Rptq` classes are off `NSManagedObject`;
    `MADocument`'s open/save run through the store (converting a legacy Core Data document on
    open). MAD framework suite green.
  - **(b) the app.** `MADDesigner` migrated — four `NSFetchedResultsController` users, not the
    two the map predicted. Both suites green.
  - **(c) the acceptance path.** The archive-level legacy round-trip, undo end to end, the
    create-document chain against a Sqlite3 source, the three tabs exercised in the simulator,
    and real dirty-tracking: `save:` early-returns when nothing changed, writes only dirty rows
    otherwise. MAD framework 222 tests, MAD Designer 70 — measured on 2026-10-03.

  Two findings delimit what is left. First, **not every element query works**: the plural
  `objectsForEntity:` has no subentity fallback, so the four call sites that ask for
  `RptqDocumentElement` and expect its subclasses get nothing — see §9.1 of
  `MAD_STORE_PHASE_C.md`. Second, the tests that should have caught it agree with the bug
  because they narrow the same way (§9, "the coverage lesson"). Remaining Phase C work is
  those items plus the hardening that was deferred by name.
- **Phase D — remove Core Data and iCloud.** Delete `UIManagedDocument` / the Core Data stack,
  the value transformers, the `.xcdatamodel`, and the iCloud machinery (`UIManagedDocument` →
  `UIDocument`, ubiquity container, file coordination). This is where the de-iCloud-ing and the
  simplification land, and it is the only behaviour the plan deliberately changes.

  **One item Phase D must not miss:** milestone (c) compiled `MAD.momd` into the **MAD
  framework** so that a legacy document can always find its model for conversion. That is
  correct while legacy conversion exists and it must be removed when it stops — otherwise the
  framework ships the Core Data model inside it, which is the opposite of what this migration
  is for. The conversion itself (`MADStoreConverter`) is the other thing to retire at the same
  point: once no shipping document is v0, legacy conversion is dead weight.

  **Second item Phase D must not miss: the iCloud era's documents convert on open.** Users
  with old reports — there are likely few — reach them through the iOS Files app and hand
  them to the app, which converts them on open through `MADStoreConverter`, the same path as
  any other legacy document. The iCloud machinery itself (ubiquity container, file
  coordination, sync) is not needed to retrieve those documents, so deleting it strands
  nothing. The only requirement is that conversion on open stays in place while legacy
  documents exist — which the first item above already covers.

**Not before Phase C:** moving `MADOperationRefresh` into `MAD` (`ROADMAP.md` §3.4) and the
driver registry (`§5.1`); both get cheaper once the store is ours.

---

## 8. Decisions the user has to make

- **Do the `Rptq` classes stay `NSManagedObject` subclasses?** Recommended no — they become
  plain objects backed by our store, keeping the property names and the `MADModel*` layer.
  This is what "keep the headers, write the CRUD" means in practice, and it commits the rest.
- **Loading granularity.** Recommended: fetch per part (schema/query/layout) on demand, not the
  whole graph and not per-relationship. This matches the user's "I wouldn't load it all at
  once."
- **Transformable wire formats.** Color as RGBA vs hex; image as PNG vs JPEG. Pin them in the
  schema so a second platform reads them identically.

---

## 9. Standing constraints

- The two shipping samples stay openable throughout; they are the conversion fixtures.
- Nothing is deleted from `Compressor/library` as part of this.
- `+[NSString stringWithFormat:]` stays out of tight loops; match the `initWithFormat:` /
  `appendFormat:` house style.
- Behaviour-safe: the suite is the proof. The ~110 Core Data files are the known mess the user
  has said is worth tightening while we are in there.
