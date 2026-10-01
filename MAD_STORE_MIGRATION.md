# The `.mad` Store Migration — Core Data to a Portable SQLite Store

This is the plan for moving the `.mad` document's store off Core Data and onto a SQLite
schema of our own. It is the work behind `MAD_FORMAT.md` §8.1 and `ROADMAP.md` §4.2, and it is
what removes hazard H3 — the last Apple dependency in the format.

Written 2026-10-01, against `master` at `73468c6f4` (v1 header + checkpoint landed).

---

## 1. Why, in one paragraph

The store inside a `.mad` is a Core Data SQLite file. Core Data does not exist off Apple
platforms, so the format cannot be called portable until the store is our own SQLite. Because
`MADocument` is a `UIManagedDocument`, this also removes the iCloud document machinery — the
user's note: *"with getting rid of Core Data we are also getting rid of iCloud stuff. That
should simplify the application."* The migration is therefore a **de-iCloud-ing** and a
**de-Core-Data-ing** in one, and the open/save path gets simpler, not just more portable.

The user's direction on how: **keep the auto-generated `Rptq` headers as a fixed,
hand-maintained contract, and write the insert/update/read code ourselves** against a SQLite
schema.

---

## 2. What the store is today

The store is a plain SQLite file (`StoreContent/analyitics`) whose schema is Core Data's, not
ours. It is read and written through `UIManagedDocument` (`MADocument`). Measured from the two
shipping samples and the current model (`MAD 3.xcdatamodel`):

- **32 entities**, all `Rptq`-prefixed. **24** have their own `Z_` table; **8** are the
  `RptqDocumentElement` subclasses, which Core Data flattens into the single
  `ZRPTQDOCUMENTELEMENT` table with a `Z_ENT` discriminator column (single-table inheritance).
- **24 `Z_` tables** plus one join table (`Z_5INQUERY` for the many-to-many
  `RptqDatabaseSchemaField.inQuery ↔ RptqQuery.hasFields`) and Core Data's own
  `Z_METADATA` / `Z_MODELCACHE` / `Z_PRIMARYKEY`.
- Every entity carries an `identifier` (`Integer 64`) — the app's logical id, present since the
  first model, and the obvious stable key for a portable schema.
- **Four transformable attributes** — the portability risk: `RptqDocumentElement`
  `backgroundColor` / `foregroundColor` (`UIColor`), `RptqDocumentElementImage.image`
  (`UIImage`), `RptqNumericFormat.locale` (`NSLocale`). These are archived by the
  `MADColorTransformer` / `MADLocaleTransformer` / `MADPngImageTransformer` value transformers,
  which today only exist because the app links them.
- **Four ordered to-many relationships** — `RptqDatabaseSchemaTable.hasFields`,
  `RptqDocumentSection.hasRows`, `RptqDocumentSectionRows.hasObjects`, and
  `RptqQueryTable`'s ordered `inQueryTable`. Order is meaningful and must survive.

The object graph is a tree: `RptqDocument` → databases (schema snapshot) and sections; a
database → tables → fields and → queries → query tables/fields/links/groups/predicates/sorts;
a section → rows → elements. The `identifier` values are the join keys today and can be the
foreign keys tomorrow.

---

## 3. What the store should be

A SQLite schema of our own, with the same object graph, written and read by our code. The
mapping is deliberately mechanical:

- **One table per entity** (the 24 non-element entities), named without Core Data's `Z_` prefix,
  keyed by the existing `identifier`. Scalar attributes become columns.
- **The element hierarchy stays single-table.** `RptqDocumentElement` plus its eight subclasses
  live in one `document_element` table with a `type` discriminator, exactly as Core Data already
  flattens them. This is the lowest-risk choice because the conversion then has to do almost no
  reshaping.
- **Relationships become foreign keys.** A to-one relationship is a column holding the target's
  `identifier`; a to-many relationship is the inverse FK on the child. The ordered to-many
  relationships get an explicit `position` column.
- **The many-to-many `inQuery`** keeps its join table (two `identifier` columns).
- **Transformables become portable scalars.** `UIColor` → four `REAL` components or a hex
  string; `NSLocale` → its identifier string; `UIImage` → PNG bytes (what
  `MADPngImageTransformer` already produces). A non-Apple reader can ignore or re-interpret
  these, but they must not be archived ObjC objects.

This is not a redesign of the model. It is the same graph in a schema we own, which is what
makes "convert existing documents" a mechanical problem rather than a semantic one.

---

## 4. The hard parts, called out

1. **The app's Core Data surface.** Roughly 110 files in `MAD/Source` and `MADDesigner/Source`
   touch `NSManagedObjectContext`, `NSFetchRequest` or `NSManagedObject`, with ~158
   fetch/insert sites. The `Rptq` classes are pure `@dynamic` `NSManagedObject` subclasses
   today. "Keep the headers, write CRUD ourselves" means the interfaces stay and the backing
   changes — which is the bulk of the work, not the schema.

2. **The element hierarchy's flattened columns.** Because Core Data already mangled colliding
   subclass attribute names into `ZGROUPNUMBER` vs `ZGROUPNUMBER1` and `ZTEXT` vs `ZTEXT1` vs
   `ZTEXT2`, the conversion must read the flattened table through the model metadata, not by
   hand. The plan is to convert **through the existing model objects** (load with Core Data,
   re-save to our store) rather than to hand-parse `Z_` tables, which avoids ever depending on
   Core Data's name mangling.

3. **`awakeFromInsert` / `awakeFromFetch` behavior.** Several `Rptq` classes set defaults or
   required fields (`identifier`, group values) in `awakeFromInsert`. The replacement store must
   reproduce those semantics, or the app will write rows without the fields it expects.

4. **Faulting and change tracking.** The app assumes lazy relationship resolution and a save
   that diffs changes. A hand-written store does not get these for free; the plan must decide
   whether the new backing loads the whole graph on open (fine — the definition is small, the
   row data is already in the `.maddb` cache) or reimplements a subset.

---

## 5. The conversion

Because the definition graph is small (both samples under 80 KB, and that is the whole document),
the conversion strategy is **read with Core Data, write to our store**:

1. Open a legacy `.mad` with the existing `MADocument` (Core Data) path.
2. Walk the object graph (`activeDocumentModel` and its relationships), serialising each entity
   to our SQLite schema, transformables included, ordered relationships in order.
3. Write the new store beside the old one, then archive the new store as the `.mad`.

This runs once per legacy document, on first open after the migration ships. The reader then
opens only the new format; legacy v0/v1 documents without a converted store are converted on
demand and re-saved. The two shipping samples are the fixtures that pin this conversion.

---

## 6. Phasing

Each phase ends with the suite green and, where possible, a CLI check.

- **Phase A — the store, standalone.** Define the portable SQLite schema (entity tables, FK
  columns, order columns, join table, transformable serialisation) and a reader/writer pair
  that round-trips a `RptqDocument` graph. Proven headlessly: build a graph in memory, write it,
  read it back, assert equality. No app integration yet.
- **Phase B — the conversion.** The legacy-reader: open a Core Data `.mad`, serialise it to the
  new store. Pinned by the two samples round-tripping through *convert → read → compare*.
- **Phase C — the app integration.** Replace the `Rptq` classes' Core Data backing with our
  store, keeping the headers. This is the large one and is done incrementally, entity-family by
  entity-family (schema, then query, then sections/elements), with the design/query/viewer tabs
  as the acceptance tests.
- **Phase D — remove Core Data.** Delete `UIManagedDocument` / `MADDocument`'s Core Data stack,
  the value transformers, the `.xcdatamodel`, and the iCloud machinery. This is where the
  "simplification" the user called out actually lands.

**Not before Phase C:** moving `MADOperationRefresh` into `MAD` (`ROADMAP.md` §3.4) and the
driver registry (`§5.1`). Both are entangled with the current object graph and are cheaper to
cut once the store is ours.

---

## 7. Decisions the user has to make

- **Does the reader load the whole graph on open?** Recommended yes — the definition is tiny and
  the row data already lives in `.maddb`. Loading whole removes faulting from scope entirely.
- **Are the `Rptq` classes still `NSManagedObject` subclasses?** Recommended no — they become
  plain objects backed by the store, keeping the property names. This is what "keep the headers"
  means in practice, and it is the decision that commits the rest of the plan.
- **Transformable wire formats.** Color as RGBA vs hex; image as PNG vs JPEG. Minor, but should
  be pinned in the schema so a second platform reads them identically.

These are the same kind of format decisions `MAD_FORMAT.md` §8 already tracks, and they belong
in that register rather than being guessed.

---

## 8. Standing constraints

- The two shipping samples (`London.mad`, `Music.mad`) stay openable throughout; they are the
  conversion fixtures.
- Nothing is deleted from `Compressor/library` as part of this.
- `+[NSString stringWithFormat:]` stays out of tight loops; match the `initWithFormat:` /
  `appendFormat:` house style.
- Behaviour-safe: the suite is the proof. The 110 Core Data files are a known mess the user has
  explicitly said is worth tightening while we are in there.
