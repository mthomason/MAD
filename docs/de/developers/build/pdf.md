---
layout: default
lang: de-DE
title: "Der headless PDF-Writer"
description: "Der Cairo- und FreeType-Stack, die Font-Zuordnung und deterministischer PDF-Export."
---

# Der headless PDF-Writer — der Cairo-+-FreeType-Körper

Diese Seite hält den headless PDF-Writer fest: den Cairo- und FreeType-Stack, die Richtlinie zur Font-Zuordnung, den deterministischen Modus und den Abnahmetest gegen das Oracle `json-report`.

*Geschrieben am ursprünglichen Datum; Fakten zum aktuellen Stand abgeglichen am 2026-11-22.*

**Status (2026-11-20): implementiert, unter Linux und Windows, und grün.** `mad export
--format pdf` und der `export` von `mad serve` schreiben auf beiden headless Engines ein PDF; der Apple-Körper von `MADReportExporterPDF` ist unverändert und schreibt weiterhin dasselbe 43.177-Byte-große, 5-seitige London-Beispiel mit `sha256 3eb2f1c4…` unter `--deterministic`. Die Abschnitte unten sind die Lieferaufzeichnung; die Entscheidungsgeschichte, die hierher führte (Status, Kandidaten-Stacks, offene Fragen), ist am Ende erhalten.

## Was es ist

Die Lücke, die dies schließt, war immer nur das Schreiben. `MADReportPageBuilder` bereitet das Dokument vor und durchläuft die Seiten; `html`, `html-flow` und `json-report` lesen diesen Durchlauf bereits und sind über Plattformen byte-identisch. Der PDF-Writer nimmt dieselben durchlaufenen Seiten und zeichnet sie:

* `MADReportExporterPDFCairo` (`MAD/Source/MADReportExporterPDFCairo.m`) ist der Nicht-Apple-Körper von `MADReportExporterPDF`. Auf Apple behält der Exporter seinen Core-Graphics-Pfad; außerhalb Apples übergibt dasselbe `exportDocument:toURL:options:error:` das Dokument hierher.
* Der Writer bereitet das Dokument genau so vor wie der Apple-Körper (`+MADReportPageBuilder prepareDocumentForRender:`), erzeugt eine Cairo-PDF-Oberfläche in den Grenzen der Seite und zeichnet für jede durchlaufene Seite die weiße Leinwand, den Text jeder Zeile in ihrem Rahmen, jedes Bild und die Textdekorationen.
* `+isAvailable` antwortet auf jeder Plattform mit YES und `+unavailableReason` ist nil. Ein fehlendes Font-Bundle ist ein Exportfehler mit eigener Meldung, kein stiller Ersatz.

## Der Stack und seine Lizenzen

| Komponente | Version | Lizenz | Rolle |
|---|---|---|---|
| cairo | 1.18.6 (git-Tag, Commit festgeschrieben) | **MPL-1.1** (die MPL-Option) | die PDF-Oberfläche und das Zeichnen |
| pixman | 0.46.4 (git-Tag, Commit festgeschrieben) | MIT | cairos Rasterkern |
| FreeType | 2.15.0 | **FTL** | Glyphen-Vorschübe, Kerning und Umrisse |
| Liberation Sans/Serif/Mono | 2.1.5 | **SIL OFL 1.1** | die Ersatzschriften |

Kein Pango: der Durchlauf löst bereits Rahmen, Text, Font, Größe, Merkmale und Ausrichtung jeder Zeile auf, und die Breite des Rahmens ist die einzige Umbruchgrenze, die es gibt (`NSLineBreakByTruncatingTail`). Was bleibt, sind Vorschübe und Kerning, die FreeType direkt liefert. cairo wird nur mit der PDF-Oberfläche gebaut — FreeType und zlib hinein; fontconfig, Pango/glib, Xlib/XCB, Quartz und die Bild-Backends außer PNG hinaus — also zieht es nichts über die Tabelle oben hinaus herein (zlib und libpng waren für den Barcode-Stack bereits da).

Die Texte liegen in `ThirdParty/Licenses/` (`cairo-MPL-1.1.txt`, `pixman-MIT.txt`, `freetype-FTL.txt`, `liberation-OFL-1.1.txt`), und das Register ist `THIRD_PARTY_LICENSES.md` §3.5, §9 (Linux-Image) und §10 (Windows-Engine). Keine der vier fügt eine Relink-Pflicht hinzu, also ändert sich das schriftliche Angebot in `ThirdParty/Licenses/README.md` nicht. Das Windows-About-Fenster listet alle vier aus `WindowsLicenseRegistry`.

## Die Font-Zuordnung

Dokumente benennen Apple-Fonts; das Bundle enthält Liberation, also wird ein Name auf eine Familie und dann über die Fett- und Kursiv-Flags des Elements (und über jeden Gewichts- oder Neigungswert, den der Name selbst angibt, z. B. `HelveticaNeue-Bold`) auf einen Schnitt abgebildet:

| Dokument-Font | Ersatz | Hinweise |
|---|---|---|
| Helvetica Neue, Helvetica, Arial, Verdana, Tahoma, Trebuchet MS, Calibri, system | Liberation Sans | Arilas metrischer Zwilling, also liegen Helvetica/Arial-Zeilen nahe; **Verdana ist breiter als Liberation Sans**, also ist eine Verdana-Zeile schmaler als die von Core Graphics und kann früher abschneiden |
| Courier, Courier New, Menlo, Consolas | Liberation Mono | Courier News metrischer Zwilling |
| Times New Roman, Times, Georgia, Palatino, Baskerville, Garamond | Liberation Serif | Times New Romans metrischer Zwilling; **Georgia ist breiter als Liberation Serif** |
| alles andere | Liberation Sans | der eigene Fallback des Renderers ist die Systemschrift, die die headless Engine nicht hat |

Gewicht und Neigung wählen den Schnitt (`Regular`, `Bold`, `Italic`, `BoldItalic`); Unterstreichung und Durchstreichung werden als gefüllte Rechtecke unter/über den gemessenen Lauf gezeichnet, wobei die PostScript-Unterstreichungsmaße des Schnitts verwendet werden. Die Ausrichtung ist die des Stils (`left`, `center`, `right`; Blocksatz und natürliche Ausrichtung zeichnen links, passend zum HTML-Faksimile). Ein Lauf, der breiter ist als sein Rahmen, wird abgeschnitten und endet mit `…`, der Truncating-Tail-Regel des Renderers.

**Der Rest sind die Maße der Ersatzschriften.** Die Seite, der Rahmen jeder Zeile, der aufgelöste Text jeder Zeile, seine Font-Familienzuordnung, Größe, Gewicht, Neigung und Ausrichtung stammen aus dem Durchlauf und sind exakt. Die Breite einer Zeile innerhalb ihres Rahmens ist die der Ersatzschrift, also wird eine Zeile etwas breiter oder schmaler als am Mac gezeichnet — am sichtbarsten bei Verdana und Georgia, deren echte Schnitte mit nichts im Bundle metrisch kompatibel sind. Das ist ein visueller Unterschied, kein struktureller; der Oracle-Test vergleicht Text und Rahmen, nicht Glyphen-Ausdehnungen.

## Determinismus

`MADReportExportOptionsDeterministic` legt die beiden Daten, die Cairo sonst von der Uhr nehmen würde (`CAIRO_PDF_METADATA_CREATE_DATE` / `_MOD_DATE`), auf denselben Zeitpunkt fest, den der Apple-Körper in seinem Trailer festlegt, `2001-01-12T00:00:00Z` (die PDF-Epoche). Cairo schreibt keinen Trailer `/ID`, und seine Objektnummerierung, Font-Subset-Tags, Kompression und Seitenbäume sind deterministisch, also sind zwei Exporte eines unveränderten Berichts dieselben Bytes. Der Test beweist es.

Eine Gefahr auf der Writer-Seite musste entfernt werden, damit dies wahr bleibt: cairo cached seine Font-Schnitte und skalierten Fonts über den `FT_Face`-Zeiger, also konnte ein Writer, der pro Export eine Menge Schnitte öffnete und freigab, einen veralteten Cache-Eintrag erhalten, wenn der Allocator eine Adresse wiederverwendete, und der Inhaltsstream wechselte manchmal von `Tj` zu Pro-Glyphe-`TJ`-Offsets. Die Schnitte sind jetzt prozessweite Load-once-Statiken, und Exporte werden unter einer rekursiven Sperre serialisiert, während sie geteilt werden.

Über Plattformen hinweg werden die beiden Writer nicht aufgefordert, byteweise übereinzustimmen, aber die Cairo-Ausgabe des London-Fixtures ist unter Linux und Windows gleich groß und unterscheidet sich nur in 44 Bytes — den Font-Subset-Präfixen, die cairo erzeugt (es hasht die Glyphen als `unsigned long`, 8 Bytes unter Linux und 4 unter Windows). Text, Geometrie und Seitenstruktur sind identisch.

Die Oberfläche ist auf **PDF 1.4** beschränkt: eine klassische Querverweistabelle und einfache Objekte. Cairos Standard 1.7 schreibt Objekt- und Querverweis-Streams, was nicht einfacher zu zeichnen und schwerer zurückzulesen ist; 1.4 ist zudem die breiteste Leserbasis. Eine Folge: Cairos PDF-API hat keine TrimBox, also ist die MediaBox der Seite US Letter und der Inhalt wird innerhalb desselben 1pt-Beschnitts gezeichnet, den der Durchlauf verwendet (`[1, 1, 610, 790]`); der Beschnitt ist strukturell in den Rahmen, keine PDF-Box.

## Das Zeichnen

Für jede Seite, im PDF-Benutzerraum von cairo (Ursprung oben links, y nach unten; cairo schreibt die Spiegelung `1 0 0 -1 0 H cm` selbst, sodass die Rahmen des Durchlaufs unverändert durchgehen):

* die weiße Beschnittbox, wie es `drawWhiteCanvas:pageRect:` des Apple-Renderers tut;
* jede Textzeile: Schnitt und Größe aus `MADReportLineStyle`, der aufgelöste Text aus der Zeile, die Glyphen platziert mit FreeTypes Vorschüben und Kerning in der Größe der Zeile (`FT_KERNING_UNFITTED`, sodass die Formung nur von Schnitt und Größe abhängt), an der linken (oder zentrierten/rechten) Kante des Rahmens und seiner Grundlinie;
* jedes Bild: das gespeicherte PNG eines Bildelements oder das Symbol eines Barcodes (`MADReportLineRepresentation -imageData`, verzögert gerendert), seitenverhältnistreu in den Rahmen eingepasst, so wie das HTML-Faksimile es einpasst (`object-fit: contain`), decodiert über cairos PNG-Leser;
* die Dekorationen: Unterstreichung und Durchstreichung als gefüllte Rechtecke;
* `cairo_show_page` (und die weiße Füllung) pro Seite.

Der Seitendurchlauf ist eine Lesetransaktion pro Seite, wie überall sonst; Bilder werden nach ihrem Schließen gelesen und kosten für ein Dokument ohne sie nichts.

## Der Abnahmetest

`Linux/Tests/MADPDFExportTests.m` (und `Windows/Engine/Tests/`) öffnet das London-Fixture, fügt einen Barcode und ein Bild hinzu, aktualisiert und exportiert. Er liest das PDF mit einem kleinen PDF-1.4-Leser im Test zurück (Seitenbaum, MediaBox, Inhaltsstreams, Font-ToUnicode-Maps) und vergleicht es mit dem `json-report` desselben Dokuments — dem Oracle, auf das sich beide Plattformen byteweise einigen:

* die Seitenzahl und die US-Letter-MediaBox jeder Seite;
* den Rahmen jeder durchlaufenen Zeile innerhalb des 1pt-Beschnitts;
* den Text jeder Textzeile, in der Reihenfolge des Durchlaufs, Seite für Seite (mit der Ellipse des Truncating-Tail, wo der Rahmen schmaler ist als der Text);
* den Barcode und das Bild als Bild-XObjects, nicht als Text;
* zwei deterministische Exporte byte-identisch, mit dem festgeschriebenen Datum; ein gewöhnlicher Export nimmt das Datum der Uhr.

`MADReportExporterTests` exportiert zudem das schlichte London-Fixture und prüft fünf Seiten, die Seitenzahl des Durchlaufs. Der Apple-Byte-Pin ist kein headless Test: die Apple-Suite prüft weiterhin den Export mit 43.177 Bytes / `3eb2f1c4…`, und der `#if __APPLE__`-Körper wurde nicht berührt.

## Bauen

* **Linux** — `Linux/libraries.conf` schreibt pixman, FreeType, cairo und das Liberation-Tarball fest; `Linux/lib/libraries.sh` hat `build_pixman` (meson), `build_freetype` (autoconf, nur Kern), `build_cairo` (meson, die PDF-Oberfläche) und `build_liberation` (die zwölf Schnitte nach `${PREFIX}/share/mad/fonts`). Das Image installiert sie nach `/usr/local`; die Laufzeitstufe kopiert `/usr/local/share/mad` für die Fonts. Die `toolchain-base` des Dockerfile braucht `meson` und `ninja-build` (das Buildsystem von cairo und pixman) und `xz-utils` (FreeTypes Pin ist `.tar.xz`).
* **Windows** — `Windows/Engine/build.ps1` baut FreeType mit seinem CMake, pixman und cairo mit Meson in der MSVC-Umgebung (cairo mit seinem DWrite-Backend, das cairos win32-Quelle zum Linken benötigt) (der pkg-config-Shim, den der libpq-Build bereits brauchte, findet die lokalen Pins über generierte `.pc`-Dateien), linkt die drei statischen `.lib`s in `mad.exe` und kopiert die Liberation-Schnitte nach `Build\fonts`. Der Writer sucht in `<exe>/fonts`, `<exe>/../fonts`, `<exe>/../share/mad/fonts`, `/usr/local/share/mad/fonts`, `/usr/share/mad/fonts`, `/usr/local/share/fonts/liberation`, `/usr/share/fonts/truetype/liberation` und einer `MAD_FONTS_DIR`-Überschreibung.

Die Fonts sind Datendateien, kein Code: ein Windows-Paket muss `Windows/Engine/build/fonts` neben `mad.exe` ausliefern, und das Linux-Image trägt sie bereits unter `/usr/local/share/mad/fonts`.

## Apples Körper ist unverändert

Der `#if __APPLE__`-Pfad von `MADReportExporterPDF` — Core Graphics, `MADPrintPageRenderer`, die Metadaten-Festlegung — ist unberührt. Das Apple-Target linkt Cairo nicht, und der Quellcode des neuen Writers ist nicht in seinem Xcode-Target. Die Apple-Buildbefehle für die Aufzeichnung:

	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

(Sie werden nicht auf der Windows-Workstation ausgeführt — dort gibt es kein Xcode; die Apple-Dateien, die dieses Inkrement berührt, sind die Nicht-Apple-Zweige des Exporters und seine Kommentare.)

## Bewusste Grenzen

* **Strukturelle, nicht byteweise Parität** — der Writer von Core Graphics lässt sich nicht reproduzieren. Das Oracle ist der Durchlauf (`json-report`/`html`), nicht das Apple-PDF.
* **Keine TrimBox** — cairos PDF-API hat keine; der Inhalt liegt innerhalb des Beschnitts.
* **Lateinischer Text, von links nach rechts** — die Glyphenplatzierung sind FreeType-Vorschübe + die `kern`-Tabelle, keine Formungsengine (kein HarfBuzz/Pango): keine Ligaturen, keine Kombination von Kombinationszeichen, keine bidirektionale Umordnung. Die Felder und Beschriftungen der Dokumente sind lateinisch; ein Dokument, das es nicht wäre, würde die eigene Glyphe jedes Codepunkts in logischer Reihenfolge zeichnen.
* **Ersatzmaße** — siehe den Rest oben (Verdana und Georgia die größten Abweichungen).
* **Der Formatwähler des Windows-WPF-Viewers** listet PDF nicht; `mad export --format pdf` und der `export` von `mad serve` tun es, was die Oberfläche der Schließung ist. Das Hinzufügen der Wählerzeile ist eine UI-Änderung mit eigenen String-Ressourcen.

---

## Die frühere Entscheidungsaufzeichnung

Diese Abschnitte sind für die Entscheidungsgeschichte erhalten, nicht als Anweisungen.

### Die Kandidaten-Stacks (MAD_LINUX.md §10.2)

| Option | Lizenz | Was sie gibt | Was sie kostet |
|---|---|---|---|
| **Cairo + Pango** (+ FreeType/HarfBuzz) | LGPL-2.1/MPL-1.1, LGPL-2.1, FTL/GPLv2-Dual, MIT | Vektorzeichnen mit einer PDF-Oberfläche und echtes Textlayout | eine neue Abhängigkeit im Image und ihre Lizenz-/Hinweisarbeit |
| **libharu** | zlib | PDF-Ausgabe, permissiv | nur PDF, keine Layout-Engine |
| **Skia** | BSD-3 | Fähigkeiten am nächsten zu CG + Core Text | ein schwerer C++-Build |
| **handgeschriebener PDF-Emitter** | keine | keine Abhängigkeit | ungefähre Typografie, ein zweiter Zeichenpfad |

**Was gewählt wurde (2026-11-20): Cairo + FreeType, kein Pango.** Der Durchlauf liefert das Layout; nur Glyphen-Vorschübe und Kerning bleiben, und FreeTypes `kern`-Tabelle liefert sie ohne Layout-Engine. Pango hätte eine Abhängigkeit (und seinen LGPL/glib-Baum) für einen Umbruch hinzugefügt, den niemand braucht.

### Die offenen Fragen, beantwortet

1. **Fonts** — siehe die Zuordnungstabelle oben: Liberation Sans/Serif/Mono, gewählt für die metrisch kompatiblen Familien, mit den festgehaltenen Resten bei Verdana und Georgia.
2. **Welcher Stack und welche Lizenz** — Cairo (MPL-1.1), pixman (MIT), FreeType (FTL), Liberation (OFL): alle permissiv oder MPL, keine LGPL, keine Relink-Pflicht.
3. **Wo der Writer lebt** — in `MAD`, als `MADReportExporterPDFCairo`, seine eigene Übersetzungseinheit und sein eigener versteckter Header, nur außerhalb Apples kompiliert. Das Apple-Target linkt ihn nicht.
4. **Wird unbeaufsichtigtes Server-PDF gebraucht?** — ja: das Verb `export` der CLI und der `export` von `serve` sind die Oberfläche, und ein geplanter Job hat keinen Browser.
