## 1. What a document is, in one sentence

A `.mad` file is a **bzip2-compressed tar archive** whose members are a Core Data
persistent store, a small property list describing the document, and an optional
thumbnail directory.

The row data a report displays is **not** in the document. It is a derived cache,
regenerated on refresh, and it lives outside the file. That distinction is the single
most important thing in this document and is explained in §5.
