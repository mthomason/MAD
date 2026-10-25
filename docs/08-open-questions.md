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
4. **Should content changes invalidate the render cache?** Now answered *mechanically*:
   the `.madac` cache is keyed by filename and page size, with no content hash, so a
   document edit under the same filename serves stale pages until the files are deleted
   (§5.3). The open part is a product decision — *should* an edit invalidate it — and the
   user's own framing is that the cache is load-bearing and not the pressing thing
   (§5.1). So this is recorded, not being fixed now.
