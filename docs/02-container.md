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
