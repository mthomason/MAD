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

The writer checkpoints the store's WAL before archiving, so the WAL and SHM members
become optional and a reader that finds them must replay them rather than ignore them.
The result is recorded in the header's flag bit 0 — **not** in `meta.plist`, which is
written before the checkpoint runs, so the flag is the authoritative record and is
readable without decompressing.

This also shrinks documents: the `Music` sample spends a third of its bytes on a WAL
that a checkpoint would fold into the main file.

### 7.3 Members

| Member | Required | Contents |
|---|---|---|
| `meta.plist` | yes | `generator`, `version` |
| `StoreContent/<name>` | yes | the document definition |
| `StoreContent/<name>-wal` / `-shm` | no | present only when not checkpointed (header flag bit 0 = 0) |
| `AdditionalContent/` | no | `thumbnail@2x.png` |

### 7.4 Compatibility

- **v0** -- what ships today: no magic, possibly a WAL, `version` 1. Readers must
  accept it indefinitely; both sample documents are v0.
- **v1** -- magic header, checkpointed store, `version` 1, new members as above.

A writer emits v1 and `meta.plist` unchanged otherwise. A reader detects v0 by the
absence of the magic.
