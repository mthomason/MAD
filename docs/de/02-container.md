---
layout: default
lang: de-DE
---

## 2. Der Container

```
$ file Music.mad
Music.mad: bzip2 compressed data, block size = 900k
```

Der Schreiber ist `MADArchiveManager.m:86-100`:

| Eigenschaft | Wert | Fundstelle |
|---|---|---|
| Archivformat | `pax restricted` | `MADArchiveManager.m:88` |
| Komprimierungsfilter | bzip2 | `MADArchiveManager.m:95` |
| Versteckte Dateien | **übersprungen** | `MADArchiveManager.m:111` |
| Pfade der Einträge | relativ zum Wurzelverzeichnis des Archivs | `MADArchiveManager.m:124-130` |

`pax restricted` bezeichnet POSIX-pax mit den Erweiterungen, die ustar bereits
abdeckt; das Archiv ist daher mit jeder tar-Implementierung lesbar. bzip2 ist in
jedem Paketmanager jeder Plattform verfügbar. **Nichts im Container ist
Apple-spezifisch.** Eine `.mad`-Datei lässt sich unter macOS, Linux und Windows
gleichermaßen mit `tar xjf` entpacken.

### Einträge

Beide ausgelieferten Beispiele enthalten genau diese sechs Einträge, in dieser
Reihenfolge:

```
AdditionalContent/
StoreContent/
StoreContent/analyitics-wal
StoreContent/analyitics-shm
StoreContent/analyitics
meta.plist
```

`AdditionalContent/` ist in beiden Beispielen vorhanden, aber leer. Es ist das
Verzeichnis, das das Dokument für ein Vorschaubild verwendet:
`MADocument.m:571-583` liest `thumbnail@2x.png` daraus in `extraInformation`, und
`MADURLFactory.m:58-68` bildet diesen Pfad. Geschrieben wird es von
`-writeAdditionalContent:toURL:…` (`MADocument.m:617-648`) im Rahmen des
Additional-Content-Protokolls von `UIManagedDocument`.

`StoreContent/` ist der persistente Core-Data-Speicher, benannt durch
`+persistentStoreName` (`MADocument.m:650`), das `@"analyitics"` zurückgibt.

> Der Name ist falsch geschrieben, und er ist **auf dem Datenträger, in
> ausgelieferten Dokumenten** falsch geschrieben. Es handelt sich nicht um einen
> Tippfehler in einem Kommentar, den man korrigieren könnte: Eine Umbenennung
> ändert den Dateinamen des Speichers und bricht jede vorhandene `.mad`-Datei. Er
> bleibt bestehen, und diese Anmerkung existiert, damit der nächste Leser ihn
> nicht „repariert“.

`meta.plist` enthält die eigenen Metadaten des Dokuments, geschrieben in
`MADocument.m:636-644`:

```xml
{
  "generator" => "MAD Designer"
  "version"   => 1
}
```

Die Version wird als `double` geschrieben (`MADocument.m:611`) und liest sich in
den Beispielen als Ganzzahl zurück. Konsumenten sollten beide Formen akzeptieren.
