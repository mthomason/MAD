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
