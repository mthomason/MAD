# MAD Error and Nullability Convention

**Status: decision record, agreed in principle 2026-11-28.** Adoption is phased and no code
change is part of this record. The order and the known violations below are queued as
[`TASKS.md` §20](../registers/TASKS.md#20-the-2026-11-28-backlog-review), item 6.

---

## 1. The three outcomes

Every public method has one of three outcomes. The declaration should say which, and the
implementation should produce it.

| Outcome | When it applies | What the method does |
|---|---|---|
| **Programmer error** | A nil where the declaration says nonnull, an invalid index, a mis-wired queue. The caller broke the contract. | Raise `NSInvalidArgumentException`, or `NSParameterAssert` at the public entry point. Do not return an error object for it. |
| **Recoverable runtime failure** | Network, file, SQL, credentials — anything the caller can reasonably report and retry. | Return `nil` or `NO` and fill an `NSError **`. |
| **Expected absence** | A lookup that legitimately finds nothing. Nothing went wrong. | Return `nil` without an error. |

The distinction between the second and third rows is the caller's question: "did this fail?"
A failed lookup is not an error, and recording one trains callers to ignore the error
parameter.

### 1.1 Never `@throw` the `NSError` object

`NSError` is not an `NSException`. `@throw` on an `NSError` instance raises an object the
codebase's `@catch (NSException *)` cannot catch, so the throw passes every handler and
lands as an untyped object at the top of the stack. A recoverable failure returns `NO` with
the error in the out-parameter; a programmer error raises an `NSException` subclass. There
is no third shape.

### 1.2 Honest nullability

Annotate the parameter and the return to match what the implementation does. A signature
that says a value may be nil and then crashes on nil is worse than an unannotated one: it
tells the caller a lie in the one place they looked for the contract.

## 2. Correcting the framing

"The app never throws" is not the convention, and it was never Apple's. Foundation and
UIKit raise exceptions for programmer error routinely; what they do not do is use
exceptions for recoverable failure. The convention is the three-way split in §1:
exceptions for broken contracts, `NSError` for runtime failure, `nil` for absence.

The existing tree does not follow this uniformly. `BUGS.md` records the mixed state under
[Nullability and error reporting are not uniform across the program](../registers/BUGS.md#nullability-and-error-reporting-are-not-uniform-across-the-program).
That entry stays as the description of the current state; this record is the target state.

## 3. Scope

**Public framework headers first.** The convention governs what a caller may rely on. Go
through the public headers and make each one's declaration state one of the three outcomes.

Do **not** retrofit implementation files or private methods as part of this work. A
nil-tolerant internal path is not a contract violation; an internal helper may be
permissive where the public entry point is strict. The public entry point is where the
assertion belongs, and it is the only surface the convention promises.

## 4. Adoption order

When the work is picked up, in this order:

1. **`MADDatabase` and the three drivers** — `MADMySQL`, `MADTdsClient`, `MADPostgres` — at
   the wire boundary. This is the surface where network, SQL, and credential failures
   actually occur, and it is the one every app path crosses.
2. **`MADFoundation`** — the shared types and the keychain wrapper.
3. **`MADFileManager`** — file coordination and metadata.
4. **The application targets** — last, because they consume the frameworks' contracts.

The order is by value, not by size: the driver boundary has the failures, and the app
targets inherit the annotations rather than inventing their own.

## 5. Known violations

These are recorded in `BUGS.md`; fix them when the owning code is next touched, not in a
sweep.

* [`MADDataTable`'s caching pair throws the `NSError` object](../registers/BUGS.md#maddatatables-caching-pair-throws-an-nserror-object-not-an-nsexception).
  Both nil-URL guards `@throw` the error; the rest of each method returns `NO`.
* [`MADElementStylizedText` accepts a nullable font name that crashes when nil](../registers/BUGS.md#madelementstylizedtext-accepts-a-nullable-font-name-that-crashes-when-nil).
  The annotation promises a graceful nil; the dictionary literal raises instead.
* [The fourteen `nullability.NullReturnedFromNonnull` / `NullPassedToNonnull` analyzer sites](../registers/BUGS.md#the-nullability-analyzer-reports-nil-crossing-nonnull-boundaries).
  Each is a crash risk if its value is ever nil; fix the value path or make the annotation
  honest.
* [`MADQueryFull` treats its `error` out-parameter as an input and drops the sort error](../registers/BUGS.md#madqueryfull-treats-its-error-out-parameter-as-an-input-and-drops-the-sort-error).
  It reads `*error` before writing it, crashes when the caller passes `NULL`, and never
  reads the topological sort's own error.

## 6. The immediate mechanical fixes

Not part of this record's adoption; recorded so the shape of each fix is decided.

* **The caching pair:** make it raise an `NSException` for the nil URL, or return `NO` and
  fill the error — one of the three outcomes, not the current `@throw NSError`.
* **The font name:** make the annotation honest, or accept nil and return nil.
* **`MADQueryFull`:** NULL-check the `error` parameter before reading or writing through it,
  and read `sortError` in the guard so a cyclic query reports itself.

Each is a small, testable change at one site; none needs the full adoption to land.
