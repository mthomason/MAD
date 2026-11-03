---
layout: default
lang: de-DE
---

## 9. Verifikation

Die Aussagen in §§2–5 sind reproduzierbar (aus dem Wurzelverzeichnis des
Repository ausführen):

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

Die Aussagen in §5 sind aus einem Geräte- oder Simulator-Container
reproduzierbar:

```sh
ls -la ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Caches/<dataTableIdHash>/
```

Jede Änderung am Format muss die Round-Trip-Fixtures erweitern, die in
`docs/project/MAD_CLI.md` §6 beschrieben sind, damit die Definition in dieser
Datei durch einen Test und nicht durch diese Prosa fixiert wird. Das Fixture des
Containers existiert seit dem 2026-10-16
(`../../Linux/Tests/MADArchiveManagerTests.m`: entpacken, neu packen, erneut
entpacken, Eintragsliste und Bytes unverändert), und das Checkpoint-Bit aus §7.2
wird durch den Schreiber fixiert, der es setzt (`mad write`). Der *reproduzierbare
Modus* des Schreibers – feste Zeitstempel der Einträge, Besitz 0, sortierter
Durchlauf – ist es, was die Dokumente zweier Plattformen gleich macht; er ist
opt-in, ein gewöhnliches Archiv zeichnet also weiterhin die Metadaten des
Dateisystems auf, und er ist keine Formatversion (die Datei ist in beiden Fällen
v1). §5 ist der Teil ohne ein solches Fixture – die Begleitdateien werden hier
anhand von Messungen beschrieben, und nichts schlägt fehl, wenn die Messung nicht
mehr stimmt.
