---
layout: default
lang: de-DE
---

## 7. Das Format, wie es definiert sein sollte

Dies ist das normative Ziel. Es weicht bewusst nur wenig vom Bestehenden ab,
weil das Bestehende nahezu richtig ist.

### 7.1 Identifikation nach Inhalt, nicht nach Namen

Eine `.mad`-Datei sollte mit einem festen Header **außerhalb** des
Komprimierungsstroms beginnen, damit ein Leser sie an den ersten Bytes erkennen
kann:

```
offset 0  8 bytes   "MADFILE\0"      magic
offset 8  2 bytes   uint16 LE        format major version
offset 10 2 bytes   uint16 LE        format minor version
offset 12 4 bytes   uint32 LE        flags (bit 0: WAL checkpointed)
offset 16 ...       bzip2 stream
```

Begründung: Das beseitigt das Windows-Problem. Die Dateiendung wird zu einer
*Konvention* für den Dateibrowser, nicht zu dem, was die Datei identifiziert. Eine
zu `.zip` umbenannte `.mad`-Datei oder ein Dokument, das über einen Kanal
empfangen wurde, der Dateiendungen verstümmelt, ist weiterhin erkennbar eine
`.mad`-Datei. Außerdem ermöglicht dies die Versionserkennung, ohne zu
dekomprimieren.

Der Header ist rückwärts inkompatibel zu den beiden ausgelieferten Beispielen. Das
ist *nur* akzeptabel, weil ein Leser zurückfallen kann: keine `MADFILE`-Magic → als
Legacy-Dokument der Version v0 behandeln (§7.4).

### 7.2 Ein Speicher mit Checkpoint

Der Schreiber führt vor dem Archivieren einen Checkpoint des WAL des Speichers
aus, sodass die Einträge WAL und SHM optional werden und ein Leser, der sie
vorfindet, sie erneut abspielen muss, statt sie zu ignorieren. Das Ergebnis wird
im Flag-Bit 0 des Headers festgehalten – **nicht** in `meta.plist`, das vor dem
Checkpoint geschrieben wird; das Flag ist also die maßgebliche Angabe und ohne
Dekomprimierung lesbar.

Damit schrumpfen auch die Dokumente: Das `Music`-Beispiel verwendet ein Drittel
seiner Bytes auf ein WAL, das ein Checkpoint in die Hauptdatei überführen würde.

### 7.3 Einträge

| Eintrag | Erforderlich | Inhalt |
|---|---|---|
| `meta.plist` | ja | `generator`, `version` |
| `StoreContent/<name>` | ja | die Dokumentdefinition |
| `StoreContent/<name>-wal` / `-shm` | nein | nur vorhanden, wenn kein Checkpoint ausgeführt wurde (Header-Flag-Bit 0 = 0) |
| `AdditionalContent/` | nein | `thumbnail@2x.png` |

### 7.4 Kompatibilität

- **v0** – was heute ausgeliefert wird: keine Magic, möglicherweise ein WAL,
  `version` 1. Leser müssen es auf unbestimmte Zeit akzeptieren; beide
  Beispieldokumente sind v0.
- **v1** – Magic-Header, Speicher mit Checkpoint, `version` 1, neue Einträge wie
  oben.

Ein Schreiber erzeugt v1 und ansonsten unverändertes `meta.plist`. Ein Leser
erkennt v0 am Fehlen der Magic.
