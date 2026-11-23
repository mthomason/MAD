---
layout: default
title: "Die Richtung"
description: "Die Richtung von MAD: von Berichten zu kombinierbaren Datenobjekten, einer einbettbaren Engine und KI-verfassten Dokumenten."
lang: de-DE
---

# Die Richtung: Von Berichten zu kombinierbaren Daten

Aktualisiert am 2026-11-22. Diese Seite beschreibt die Richtung, in die MAD
hineinwachsen soll. Sie trennt, was heute ausgeliefert wird, von dem, was
vorgeschlagen ist, und sie verlinkt die öffentlichen Entwurfsunterlagen statt
der internen Arbeitsnotizen: den
[Entwurf für das Datenobjekt](developers/data-object.html), die
[Berichte mit mehreren Quellen](developers/multi-source.html) und die
[Format-Spezifikation](README.html).

## Was heute existiert

Ein `.mad`-Dokument ist die **Definition** eines Berichts: der
Schema-Snapshot, der Abfragegraph (Tabellen, Joins, Prädikate,
Gruppierungen) und der bandbasierte Layoutbaum. Beim Aktualisieren
kompiliert die Engine den Graphen zu SQL, liest die Zeilen einmal und
materialisiert sie in einem begleitenden SQLite-Cache (`.maddb` +
`.mdcache`). Die Zeilendaten bleiben bewusst außerhalb des Dokuments; die
Definition bleibt unter 100 KB.

Die Engine verfügt bereits über die Bausteine, die eine breitere Richtung
benötigt:

* Ein offenes, portables Dokumentformat: ein bzip2-tar-Archiv mit einem
  portablen SQLite-Speicher, für dessen Öffnen kein Apple-Framework
  erforderlich ist.
* Ein Abfragegenerator, der strukturierte Definitionen zu SQL kompiliert,
  sowie ein SQL-Parser für direkt eingegebene Anweisungen.
* Vier SQL-Treiber — MySQL, SQL Server, PostgreSQL und SQLite —, die
  jeweils ein Schema und Zeilen als Tabelle zurückgeben.
* Lokale SQLite-Materialisierung (`MADDataTableFast`), die Gruppierungen,
  Aggregate und wiederholtes Rendern auf einem Telefon praktikabel macht.
* Native iOS- und macOS-Anwendungen, eine native Windows-Anwendung und
  dieselbe Engine, die unter Linux und Windows über `mad serve` und die
  `mad`-CLI headless läuft.

Eine Konsequenz wird leicht übersehen: **Ein Bericht ist eine Funktion von
Datenquellen auf eine Tabelle.** Jeder Treiber liefert ein Schema und Zeilen
in Tabellenform, und die Ausgabe eines Berichts *ist* ein Schema und Zeilen
in Tabellenform. Die Engine behandelt beides bereits identisch.

## Wohin es geht

Die folgenden Richtungen sind Vorschläge. Sie bauen auf der obigen
Architektur auf, aber keine davon wird heute ausgeliefert, sofern diese
Seite nicht ausdrücklich sagt, dass sie es wird.

### Kombinierbare Datenobjekte

In einer Datenbank wählt man aus Basistabellen wie `employee` oder
`sales_data` aus. Ein Bericht verknüpft mehrere Tabellen miteinander, und
seine Ausgabe ist eine materialisierte Ad-hoc-SQLite-Tabelle. Heute kann
nichts eine Abfrage auf die Ausgabe eines anderen Berichts richten: Der
Ergebnis-Cache existiert, ist aber nach einem Dateinamen-Hash statt nach
einer adressierbaren Identität indiziert.

Dieser Ausgabe eine stabile Identität zu geben, würde das Ergebnis eines
Berichts zu einer Tabelle machen, aus der andere Berichte auswählen und
gegen die sie joinen können. Ein Bericht, der auf einem Bericht aufbaut,
wird zu einem gerichteten azyklischen Graphen (DAG) abgeleiteter Tabellen —
einer portablen semantischen Schicht, in der das Entwerfen eines Berichts
zugleich das Entwerfen einer wiederverwendbaren Datenquelle ist. Der
[Entwurf für das Datenobjekt](developers/data-object.html) beschreibt das
Modell und was seine Formalisierung erfordert.

### Lokale Materialisierung aus mehreren Quellen

Jeder Treiber materialisiert seine Ergebnismenge in derselben lokalen
SQLite-Tabellendarstellung. Sobald ein Dokument mehrere Abfragedefinitionen
halten und jede Ausgabe als Tabelle adressieren kann, kann ein Bericht eine
PostgreSQL-Tabelle mit einer SQL-Server-Tabelle und einer MySQL-Tabelle
joinen — lokal in SQLite kombiniert, ohne einen Föderationsserver
dazwischen. Jede Quelle versteht ihre eigenen Daten; MAD versteht die
daraus entstehenden Tabellen. Der [Entwurf für mehrere
Quellen](developers/multi-source.html) hält die Architektur und die Phasen
fest, von denen nicht alle gebaut sind.

### Einbettbare und headless Nutzung

MAD muss nicht auf Anwendungen mit dem Namen MAD beschränkt bleiben.
Dieselbe Engine könnte in die Produkte anderer Entwickler eingebettet
werden: ein Bestandsverwaltungssystem, eine Finanzanwendung, ein
Fertigungswerkzeug oder ein branchenspezifisches Managementsystem, das
Abfragen, Berichte, Exporte und betriebliche Zusammenfassungen benötigt,
ohne ein Reporting-Teilsystem von Grund auf zu bauen.

Die Host-Anwendung liefert den Datenzugriff, die Integration und ihre eigene
Benutzererfahrung. MAD liefert wiederverwendbare Fähigkeiten für Abfragen,
Materialisierung, Reporting und Export. Die Treiber-Schnittstelle ist
bewusst breit gehalten — eine Quelle muss ein Schema und Zeilen
bereitstellen, nicht unbedingt eine konventionelle SQL-Datenbank —, sodass
derselbe Kontrakt relationale Datenbanken, lokale Anwendungsdaten,
strukturierte Dateien und Geräte abdecken kann. Einige dieser Quellen haben
heute Treiber; andere bräuchten einen.

Diese Richtung reicht auch über Desktop-Software hinaus: Ein Gerät oder
industrielles System mit ausreichenden Ressourcen könnte die Engine lokal
nutzen, um Messungen und Wartungsaufzeichnungen in Diagnoseberichte zu
verwandeln, ohne durchgehende Konnektivität. Das ist keine Behauptung, dass
die vollständige Engine in einen winzigen Mikrocontroller oder eine
Regelschleife mit harten Echtzeitanforderungen passt.

### Darstellung jenseits von Papier

Die bandbasierte Paginierung — Report Header, Page Header, Gruppierungen,
Detail, Fußzeilen — wurde für den Druck auf Papier erfunden. Ein
`.mad`-Layout sind parametrische Daten, und der Zeilen-Cache ist lokales
SQLite, sodass Papierseiten nur eine Darstellung der Daten sind und nicht
ihre Definition.

Die Definition und ihre materialisierte Tabelle getrennt zu halten,
ermöglicht andere Darstellungen über demselben Datenobjekt: interaktive
Tabellen und Daten-Explorer, native Anwendungsansichten, Diagramme und
Dashboards, in Anwendungen eingebettete Ansichten und browserbasierte
Betrachter. Traditionelle paginierte Berichte bleiben wichtig; das Ziel ist,
sie zu einer nützlichen Darstellung unter mehreren zu machen, nicht sie
aufzugeben.

### KI-verfasste Dokumente

Die deklarative Struktur von MAD macht es für ein anderes Modell
KI-gestützten Reportings geeignet. Statt ein Bild eines Diagramms zu
erzeugen, könnte ein Modell ein tatsächliches MAD-Dokument vorschlagen: die
verfügbaren Quellen und Schema-Metadaten entdecken, die relevanten Tabellen
und Felder auswählen, die Abfragegraphen und Beziehungen aufbauen, ein
Layout vorschlagen und das Ergebnis der Engine zur Validierung und
Ausführung übergeben.

Die Aufteilung der Verantwortung ist wichtig. Das Modell interpretiert die
Absicht und schlägt eine strukturierte Definition vor; MAD validiert und
führt sie aus. Das Modell sollte Abfragegraphen und Layoutdefinitionen
erzeugen statt beliebiges ungeprüftes SQL, und die Engine sollte für die
SQL-Erzeugung, den Datenzugriff und die Materialisierung verantwortlich
bleiben.

Das Ergebnis wäre ein normales, editierbares `.mad`-Dokument statt einer
einmaligen Antwort. Der Abfragegraph könnte inspiziert, die Joins und
Filter bearbeitet, die Darstellung angepasst, die Ergebnisse ohne das Modell
aktualisiert und das Dokument anderswo wiederverwendet werden. Das lässt die
Kontrolle über das Artefakt beim Benutzer und vermeidet, dass der Betrieb
von der KI abhängt, die es verfasst hat. Autorisierung, Validierung und
Datenschutzkontrollen wären Teil der Umsetzung; die strukturelle
Validierung allein beweist nicht, dass eine Analyse semantisch korrekt ist.

### Optionaler Server- und Web-Betrieb

Native Anwendungen, eingebettete Komponenten und headless Ausführung
sollten erstklassig bleiben. Ein zukünftiger Dienst könnte Planung,
Dokumentkataloge, Zugriffskontrollen, Snapshot-Verwaltung, gemeinsam
genutzte Berichte und APIs hinzufügen, und ein browserbasierter Designer
könnte auf demselben Dokumentmodell arbeiten wie die nativen Clients.

Die Engine und das Dokumentformat bleiben das gemeinsame Fundament. Ein
Kunde, der lokale Ausführung, private Infrastruktur oder Offline-Betrieb
benötigt, sollte nicht eine Cloud-Bereitstellung übernehmen müssen, um von
der Engine zu profitieren, und eine zukünftige Web-Implementierung sollte
die Abfragesemantik nicht abspalten.

### Konvertierung von Legacy-Berichten

Ein zukünftiger Importeur könnte Definitionen aus Legacy-Berichtsformaten in
offene `.mad`-Dateien überführen. Das ist ein Kompatibilitätspfad für
Organisationen mit langlebigen Berichtsbibliotheken, nicht der Mittelpunkt
der Richtung und kein Ersatz für die obigen Richtungen.

## Drei Arten, MAD zu verwenden

Dies sind keine getrennten Produkte oder getrennten Codebasen. Es sind
verschiedene Verwendungen derselben Architektur, verbunden durch das
Datenobjektmodell.

### MAD als Anwendung

Eine vollständige Erfahrung für Abfragen, Entwurf und Reporting für
Menschen, die direkt mit ihren Daten arbeiten, mit nativen Anwendungen,
Dokumentportabilität und praktischem Reporting.

### MAD als eingebettete Engine

Eine wiederverwendbare Komponente für Datenzugriff, Abfragen,
Materialisierung und Reporting für Entwickler, die MAD in ihre eigene
Software oder ihre Geräte einbinden, mit dem Schwerpunkt auf
Treiberarchitektur, headless Ausführung, wiederverwendbaren Definitionen und
lokaler Verarbeitung.

### MAD als KI-verfasste Datenplattform

Ein System, in dem Menschen die benötigten Informationen beschreiben und
ein Modell validierte MAD-Datenobjekte und -Dokumente konstruiert, mit
strukturierter Generierung, maschineller Validierung und editierbaren
Artefakten, die unabhängig von der KI nützlich bleiben.

## Warum das wichtig ist

Das Problem ist praktischer Natur. Viele Organisationen betreiben
umfangreiche, langlebige Systeme rund um relationale Datenbanken und
spezialisierte Geschäftsanwendungen. Sie wollen zuverlässigen Zugriff auf
ihre eigenen Daten, Berichte, die sie ohne wiederholte Sonderentwicklung
pflegen können, native Werkzeuge mit guter Benutzererfahrung, Kontrolle über
Zugangsdaten und darüber, wo Daten verarbeitet werden, die weitere Nutzung
bestehender Datenbankinfrastruktur und Portabilität zwischen Plattformen und
Umgebungen.

Der schwierige Teil ist meist, die Daten in eine zuverlässige, nutzbare Form
zu bringen. Sie zu präsentieren ist der letzte Schritt. MAD investiert in
Datenerfassung, relationale Modellierung, Materialisierung und Ausführung,
und die Oberfläche sitzt auf dieser Arbeit auf, statt sie zu verbergen.

Der Wert ist positiv: Portabilität, lokale Kontrolle, Kombinierbarkeit,
zuverlässige Verarbeitung, Erweiterbarkeit und eine zugängliche Erfahrung.
Ein Unternehmen sollte aus seinen Daten nützliche Antworten gewinnen können,
ohne unnötige Plattformabhängigkeiten zu akzeptieren.

## Was dies nicht ist

Ein Versprechen, eine Roadmap mit Terminen oder die Behauptung, dass die
obigen Vorschläge ausgeliefert werden. Diese Seite hält eine Richtung fest.
Jede Fähigkeit muss noch so entworfen, getestet und dokumentiert werden, wie
alles andere im Repository, und einige dieser Richtungen können sich im Zuge
ihrer Umsetzung ändern.

## Das Leitprinzip

> **Das Dokument definiert die Arbeit. Die Engine führt sie aus. Die
> Darstellung macht das Ergebnis nützlich.**
