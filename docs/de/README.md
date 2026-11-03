---
layout: default
lang: de-DE
---

# Das `.mad`-Dokumentformat

Dieses Dokument definiert, was eine `.mad`-Datei ist. Es beschreibt das Format
**so, wie es heute existiert**, ermittelt aus zwei ausgelieferten
Beispieldokumenten und dem Code, der sie liest und schreibt, und beschreibt
anschließend das Format **so, wie es definiert sein sollte**, damit ein Leser auf
einer anderen Plattform – ein Kommandozeilenwerkzeug, ein Windows-Build – ein
Dokument öffnen kann, ohne auf Core Data oder ein Apple-Framework angewiesen zu
sein.

Das Format ist wichtig, weil ein Bericht *klein* ist – die ausgelieferten
Beispiele bleiben unter 80 KB – und weil die Engine, die ihn ausführt, auf ein
Telefon und in einen Container passt: Dieselbe Definition läuft unter iOS, macOS
und im headless Linux-Build. Wohin das Format führt – die Ergebnistabelle eines
Berichts wird zur Datenquelle für andere Berichte, sodass ein Dokument mehrere
Datenbanken umspannen kann – beschreibt
[`vision.md`](vision.md). Die Spezifikation wird außerdem als Website unter
<https://docs.everydayapps.com> bereitgestellt.

Alles in der ersten Hälfte ist gemessen, nicht abgeleitet. Die beiden Beispiele
sind
`../../MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad`
und `…/London.dataset/London.mad`.

---

**Das `.mad`-Format ist eine offene Spezifikation.** Jeder darf sie lesen und
implementieren. Die MIT-Lizenz gilt für den Code des Projekts. Die Namen „MAD“,
„MAD Designer“ und „MAD Viewer“ sowie die Anwendungssymbole und das übrige
Produkt-Artwork gehören dem Autor und sind nicht lizenziert; beschreibende
Verweise auf `.mad`-Dateien und auf dieses Projekt sind willkommen. Siehe
[`../../LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE),
[`../../NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)
und
[`../project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).

Die Spezifikation ist als ein Kapitel pro Datei organisiert. Die Kapitel 1–6
beschreiben das Format in seiner ausgelieferten Form; Kapitel 7 ist das normative
Ziel (`v1`); die Kapitel 8–9 behandeln die offenen Fragen und die Art der
Verifikation:

1. [Was ein Dokument ist – in einem Satz](01-document.md)
2. [Der Container](02-container.md)
3. [Der Speicher](03-store.md)
4. [Lesen und Schreiben, wie implementiert](04-reading-writing.md)
5. [Was *nicht* im Dokument steht: die Begleitdateien](05-companion-files.md)
6. [Fallstricke, die ein zweiter Leser bewältigen muss](06-hazards.md)
7. [Das Format, wie es definiert sein sollte](07-normative.md)
8. [Offene Fragen](08-open-questions.md)
9. [Verifikation](09-verification.md)
