---
layout: default
lang: de-DE
---

## 8. Offene Fragen

1. **Muss der Speicher überhaupt Core Data sein?** Die Definition, die er
   enthält, ist ein überschaubarer Objektgraph. Ein handgeschriebenes Schema in
   derselben SQLite-Datei würde H3 beseitigen, die letzte Apple-Abhängigkeit aus
   dem Format entfernen und ist unabhängig davon, was die CLI tut, Voraussetzung
   für Windows. Dies ist eine Designentscheidung für die Core-Data-Migration,
   nicht für dieses Dokument.
2. **Sollte das Vorschaubild im Dokument liegen?** Es ist neu erzeugbar, wie der
   Zeilen-Cache, und der einzige Grund, warum `AdditionalContent/` existiert.
   Entfernte man es, wäre jeder Eintrag einer `.mad`-Datei maßgeblich.
3. **Sollte `.mad` den Zeilen-Cache optional mitführen?** Eine „gepackte“
   Variante würde ein Dokument auf einem zweiten Gerät offline öffnen lassen, auf
   Kosten der Größe. Heute tut das nichts; die Frage wird aufgeworfen, weil der
   Name die Erwartung weckt (§5).
4. **Sollten Inhaltsänderungen den Render-Cache ungültig machen?** Inzwischen
   *mechanisch* beantwortet: Der `.madac`-Cache ist nach Dateiname und
   Seitengröße indiziert, ohne Inhalts-Hash, sodass eine Bearbeitung des
   Dokuments unter demselben Dateinamen veraltete Seiten ausliefert, bis die
   Dateien gelöscht werden (§5.3). Offen ist die Produktentscheidung – *soll* eine
   Bearbeitung ihn ungültig machen –, und die Sicht des Benutzers ist, dass der
   Cache tragend und nicht die vordringliche Baustelle ist (§5.1). Das wird also
   festgehalten, aber derzeit nicht behoben.
