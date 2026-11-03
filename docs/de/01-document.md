---
layout: default
lang: de-DE
---

## 1. Was ein Dokument ist – in einem Satz

Eine `.mad`-Datei ist ein **bzip2-komprimiertes tar-Archiv**, dessen Einträge ein
persistenter Core-Data-Speicher, eine kleine Property List, die das Dokument
beschreibt, und ein optionales Verzeichnis mit einem Vorschaubild sind.

Die Zeilendaten, die ein Bericht anzeigt, sind **nicht** im Dokument enthalten.
Sie sind ein abgeleiteter Cache, werden bei jeder Aktualisierung neu erzeugt und
liegen außerhalb der Datei. Dieser Unterschied ist der wichtigste Punkt in diesem
Dokument und wird in §5 erläutert.
