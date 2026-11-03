---
layout: default
lang: de-DE
---

## 4. Lesen und Schreiben, wie implementiert

```
write:  document model ──▶ UIManagedDocument ──▶ ~/tmp/<name>.mada/ ──▶ tar.bz2 ──▶ <name>.mad
read:   <name>.mad ──▶ tar.bz2 ──▶ ~/tmp/<name>.mada/ ──▶ UIManagedDocument
```

Das Zwischenverzeichnis heißt **Guts**. Seine Dateiendung ist `.mada`
(`MADConstants.m:12`, `MADFileExtentionMobleApplicationDocumentArchive`), es trägt
den Namen des Dokuments und liegt in einem temporären Verzeichnis
(`MADURLFactory.m:51-56`, `newURLLocalTemporaryDirectory` → `~/tmp`).

- Speichern – `MADocument.m:497-514`: das Modell in die Guts schreiben, dann die
  Guts über die Dokument-URL archivieren.
- Öffnen – `MADocument.m:456-476`: das Dokument in die Guts entpacken, dann den
  Speicher von dort lesen.

Der Kommentar über `-readFromURL:` (`MADocument.m:452-455`) bringt es mit den
Worten des Autors auf den Punkt:

> 1. Die MAD-Datei entpacken; es ist eine ZIP-Datei (vielleicht tar.bz2).
> 2. Die entpackte Datei lesen. Derzeit ist es eine Core-Data-Datei.

„Derzeit ist es eine Core Data-Datei“ – darin besteht die gesamte Migration, in
fünf Wörtern.
