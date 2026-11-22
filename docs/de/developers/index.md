---
layout: default
lang: de-DE
title: Entwickler
description: "Binden Sie die MAD-Engine ein, verwenden Sie die mad-CLI, lesen Sie den Datenobjekt-Vertrag und bauen Sie die headless Engine."
---

# Entwickler

MAD ist eine eingebettete Engine für relationales Reporting: ein portables `.mad`-Dokument, eine eigenentwickelte Objective-C-Engine und ein Kommandozeilenwerkzeug `mad`, das dieselbe Engine headless unter Linux und Windows ausführt. Diese Seiten richten sich an alle, die die Engine einbetten, sie aus einem Skript steuern, eine Datenquelle hinzufügen oder sie aus dem Quellcode bauen möchten.

## Hier beginnen

* [Die `.mad`-Formatspezifikation](../README.html) — was ein Dokument ist, der Container, der Speicher und das normative Ziel `v1`.
* [MAD Designer für macOS](../macos.html) — die native `AppKit`-Anwendung.
* [MAD Designer für Windows](../windows.html) — die native WPF-Anwendung.
* [Vision](../vision.html) — Berichte als kombinierbare Datenquellen.

## Engine und CLI

* [Das Kommandozeilenwerkzeug `mad`](cli.html) — ein Dokument ohne UI öffnen, inspizieren, abfragen, aktualisieren und exportieren.
* [Das Datenobjekt](data-object.html) — Definition, Schema und Ergebnismenge eines Berichts als ein Vertrag.
* [Berichte mit mehreren Quellen](multi-source.html) — Berichte als Tabellen und Treiber für alles, was eine Tabelle zurückgibt.
* [SQL in den Abfragedesigner einfügen](sql-entry.html) — die unterstützte Teilmenge, der Parser und der Apply-Pfad.

## Architektur

* [Die MADDataTable-Architektur](architecture/data-table.html) — der Datenbanktabellen-Klassencluster über die Frameworks hinweg.
* [Die MADModel-Schicht](architecture/model-layer.html) — das Dokument-Read-Modell über den `Rptq`-Entitäten.
* [MADArrayCaching](architecture/array-caching.html) — das plattengestützte Array des Render-Caches.

## Bauen und testen

* [Die Engine unter Linux bauen](build/linux.html) — der Docker-Build und die zwölf headless Frameworks.
* [Die Engine unter Windows bauen](build/windows.html) — die festgeschriebene Clang- und GNUstep-Toolchain.
* [Portabilität und die native macOS-Anwendung](build/macos.html) — das Framework-Audit und die AppKit-Architektur.
* [Der Compressor-Build der statischen Bibliotheken](build/libraries.html) — die C-Bibliotheken von Drittanbietern und wie Xcode sie erreicht.
* [Der headless PDF-Writer](build/pdf.html) — Cairo, FreeType und deterministischer Export.

## Satelliten und Quellcode

* [Satelliten-Repositories](satellites.html) — wie `mad-action` und das Container-Image aus diesem Repository veröffentlicht werden.
* [Quellcode](https://github.com/mthomason/MAD) — das Repository, die Issues und der
  [Leitfaden für Beiträge](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md).
