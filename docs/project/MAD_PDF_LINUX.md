# The headless PDF writer — the Cairo + FreeType body

**Status (2026-11-20): implemented, on Linux and Windows, and green.** `mad export
--format pdf` and `mad serve`'s `export` write a PDF on both headless engines;
`MADReportExporterPDF`'s Apple body is unchanged and still writes the same
43,177-byte, 5-page, `sha256 3eb2f1c4…` London sample under `--deterministic`.
The sections below are the delivered record; the decision history that led here
(status, candidate stacks, open questions) is kept at the end.

## What it is

The gap this closes was only ever the writing. `MADReportPageBuilder` prepares the
document and walks the pages; `html`, `html-flow` and `json-report` already read
that walk and are byte-identical across platforms. The PDF writer takes the same
walked pages and draws them:

* `MADReportExporterPDFCairo` (`MAD/Source/MADReportExporterPDFCairo.m`) is the
  non-Apple body of `MADReportExporterPDF`. On Apple the exporter keeps its Core
  Graphics path; off Apple the same `exportDocument:toURL:options:error:` hands the
  document here.
* The writer prepares the document exactly as the Apple body does
  (`+MADReportPageBuilder prepareDocumentForRender:`), creates a Cairo PDF surface
  at the page's bounds, and for every walked page draws the white canvas, every
  line's text at its frame, every picture, and the text decorations.
* `+isAvailable` answers YES on every platform and `+unavailableReason` is nil.
  A missing font bundle is an export error with its own message, not a silent
  substitute.

## The stack, and its licences

| Component | Version | Licence | Role |
|---|---|---|---|
| cairo | 1.18.6 (git tag, commit pinned) | **MPL-1.1** (the MPL option) | the PDF surface and drawing |
| pixman | 0.46.4 (git tag, commit pinned) | MIT | cairo's raster core |
| FreeType | 2.15.0 | **FTL** | glyph advances, kerning and outlines |
| Liberation Sans/Serif/Mono | 2.1.5 | **SIL OFL 1.1** | the substitute faces |

No Pango: the walk already resolves each line's frame, text, font, size, traits
and alignment, and the frame's width is the one wrapping bound there is
(`NSLineBreakByTruncatingTail`). What is left is advances and kerning, which
FreeType supplies directly. cairo is built with the PDF surface only — FreeType
and zlib in; fontconfig, Pango/glib, Xlib/XCB, Quartz and the image backends
other than PNG out — so it pulls in nothing beyond the table above (zlib and
libpng were already there for the barcode stack).

The texts are in `ThirdParty/Licenses/` (`cairo-MPL-1.1.txt`,
`pixman-MIT.txt`, `freetype-FTL.txt`, `liberation-OFL-1.1.txt`) and the register
is `THIRD_PARTY_LICENSES.md` §3.5, §9 (Linux image) and §10 (Windows engine).
None of the four adds a relink obligation, so the written offer in
`ThirdParty/Licenses/README.md` does not change. The Windows About window lists
all four from `WindowsLicenseRegistry`.

## The font mapping

Documents name Apple fonts; the bundle carries Liberation, so a name is mapped to
a family and then to a face by the element's bold and italic flags (and by any
weight or slant the name itself states, e.g. `HelveticaNeue-Bold`):

| Document font | Substitute | Notes |
|---|---|---|
| Helvetica Neue, Helvetica, Arial, Verdana, Tahoma, Trebuchet MS, Calibri, system | Liberation Sans | Arial's metric twin, so Helvetica/Arial lines are close; **Verdana is wider than Liberation Sans**, so a Verdana line is narrower than Core Graphics' and can truncate earlier |
| Courier, Courier New, Menlo, Consolas | Liberation Mono | Courier New's metric twin |
| Times New Roman, Times, Georgia, Palatino, Baskerville, Garamond | Liberation Serif | Times New Roman's metric twin; **Georgia is wider than Liberation Serif** |
| anything else | Liberation Sans | the renderer's own fallback is the system font, which the headless engine does not have |

Weight and slant choose the face (`Regular`, `Bold`, `Italic`, `BoldItalic`);
underline and strikethrough are drawn as filled rectangles under/through the
measured run, using the face's PostScript underline metrics. Alignment is the
style's (`left`, `center`, `right`; justified and natural draw left, matching the
HTML facsimile). A run wider than its frame is cut and ends with `…`, the
renderer's truncating-tail rule.

**The residual is the substitutes' metrics.** The page, every line's frame, every
line's resolved text, its font family mapping, size, weight, slant and alignment
are the walk's and are exact. The width of a line inside its frame is the
substitute face's, so a line drawn slightly wider or narrower than the Mac's —
most visibly for Verdana and Georgia, whose real faces are not metric-compatible
with anything in the bundle. This is a visual difference, not a structural one;
the oracle test compares text and frames, not glyph extents.

## Determinism

`MADReportExportOptionsDeterministic` pins the two dates Cairo would otherwise
take from the clock (`CAIRO_PDF_METADATA_CREATE_DATE` / `_MOD_DATE`) to the same
instant the Apple body pins in its trailer, `2001-01-12T00:00:00Z` (the PDF
epoch). Cairo writes no trailer `/ID`, and its object numbering, font subset
tags, compression and page trees are deterministic, so two exports of an
unchanged report are the same bytes. The test proves it.

One writer-side hazard had to be removed to keep that true: cairo caches its
font faces and scaled fonts by the `FT_Face` pointer, so a writer that opened
and freed a set of faces per export could be handed a stale cache entry when
the allocator reused an address, and the content stream would sometimes switch
from `Tj` to per-glyph `TJ` offsets. The faces are now load-once process-wide
statics, and exports are serialized under a recursive lock while they are
shared.

Across platforms the two writers are not asked to agree byte for byte, but the
London fixture's Cairo output is the same size on Linux and Windows and differs in 44
bytes only -- the font-subset prefixes cairo generates (it hashes the glyphs as
`unsigned long`, 8 bytes on Linux and 4 on Windows).  The text, geometry and page
structure are identical.

The surface is restricted to **PDF 1.4**: a classic cross-reference table and
plain objects. Cairo's default 1.7 writes object and cross-reference streams,
which is no easier to draw and harder to read back; 1.4 is also the broadest
reader base. One consequence: Cairo's PDF API has no TrimBox, so the page's
MediaBox is US Letter and the content is drawn inside the same 1pt trim the walk
uses (`[1, 1, 610, 790]`); the trim is structural in the frames, not a PDF box.

## The drawing

For each page, in cairo's PDF user space (origin top-left, y down; cairo
writes the `1 0 0 -1 0 H cm` flip itself, so the walk's frames pass through
unchanged):

* the white trim box, as the Apple renderer's `drawWhiteCanvas:pageRect:` does;
* each text line: the face and size from `MADReportLineStyle`, the resolved text
  from the line, the glyphs placed with FreeType's advances and kerning at
  the line's size (`FT_KERNING_UNFITTED`, so shaping depends only on face and
  size), at the frame's left (or centred/right) edge and its baseline;
* each picture: an image element's stored PNG or a barcode's symbol
  (`MADReportLineRepresentation -imageData`, rendered lazily), aspect-fitted into
  the frame the way the HTML facsimile fits it (`object-fit: contain`), decoded
  through cairo's PNG reader;
* the decorations: underline and strikethrough as filled rectangles;
* `cairo_show_page` (and the white fill) per page.

The page walk is one read transaction per page, as everywhere else; pictures are
read after it closes and cost nothing for a document without them.

## The acceptance test

`Linux/Tests/MADPDFExportTests.m` (and `Windows/Engine/Tests/`) opens the London
fixture, adds a barcode and a picture, refreshes, and exports. It reads the PDF
back with a small PDF 1.4 reader in the test (page tree, MediaBox, content
streams, font ToUnicode maps) and compares it with the `json-report` for the same
document — the oracle both platforms agree on byte-for-byte:

* the page count and each page's US Letter MediaBox;
* every walked line's frame inside the 1pt trim;
* every text line's text, in the walk's order, page by page (with the
  truncating-tail ellipsis allowed where the frame is narrower than the text);
* the barcode and the picture as image XObjects, not text;
* two deterministic exports byte-identical, with the pinned date; an ordinary
  export taking the clock's date.

`MADReportExporterTests` also exports the plain London fixture and checks five
pages, the walk's page count. The Apple byte pin is not a headless test: the
Apple suite still asserts the 43,177-byte / `3eb2f1c4…` export, and the
`#if __APPLE__` body was not touched.

## Building it

* **Linux** — `Linux/libraries.conf` pins pixman, FreeType, cairo and the
  Liberation tarball; `Linux/lib/libraries.sh` has `build_pixman` (meson),
  `build_freetype` (autoconf, core only), `build_cairo` (meson, the PDF surface)
  and `build_liberation` (the twelve faces into
  `${PREFIX}/share/mad/fonts`). The image installs them into `/usr/local`; the
  runtime stage copies `/usr/local/share/mad` for the fonts. The Dockerfile's
  `toolchain-base` needs `meson` and `ninja-build` (cairo's and pixman's build
  system) and `xz-utils` (FreeType's pin is `.tar.xz`).
* **Windows** — `Windows/Engine/build.ps1` builds FreeType with its CMake, pixman
  and cairo with Meson under the MSVC environment (cairo with its DWrite backend,
  which cairo's win32 source requires to link) (the pkg-config shim the
  libpq build already needed finds the local pins through generated `.pc`
  files), links the three static `.lib`s into `mad.exe`, and copies the
  Liberation faces to `Build\fonts`. The writer looks for
  `<exe>/fonts`, `<exe>/../fonts`, `<exe>/../share/mad/fonts`,
  `/usr/local/share/mad/fonts`, `/usr/share/mad/fonts`,
  `/usr/local/share/fonts/liberation`, `/usr/share/fonts/truetype/liberation`
  and a
  `MAD_FONTS_DIR` override.

The fonts are data files, not code: a Windows package must ship
`Windows/Engine/build/fonts` beside `mad.exe`, and the Linux image already
carries them at `/usr/local/share/mad/fonts`.

## Apple's body is unchanged

The `#if __APPLE__` path of `MADReportExporterPDF` — Core Graphics,
`MADPrintPageRenderer`, the metadata pinning — is untouched. The Apple target
does not link Cairo, and the new writer's source is not in its Xcode target. The
Apple build commands for the record:

	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

(They are not run on the Windows workstation — there is no Xcode there; the
Apple files this increment touches are the exporter's non-Apple arms and its
comments.)

## Deliberate limits

* **Structural, not byte, parity** — Core Graphics' writer cannot be reproduced.
  The oracle is the walk (`json-report`/`html`), not the Apple PDF.
* **No TrimBox** — cairo's PDF API has none; the content is inside the trim.
* **Latin text, left-to-right** — glyph placement is FreeType advances + the
  `kern` table, not a shaping engine (no HarfBuzz/Pango): no ligatures, no
  combining-mark composition, no bidirectional reordering. The documents' fields
  and labels are Latin; a document that is not would draw each code point's own
  glyph in logical order.
* **Substitute metrics** — see the residual above (Verdana and Georgia the
  widest gaps).
* **The Windows WPF Viewer's format picker** does not list PDF; `mad export
  --format pdf` and `mad serve`'s `export` do, which is the closure's surface.
  Adding the picker row is a UI change with its own string resources.

---

## The earlier decision record

These sections are kept for the decision history, not as instructions.

### The candidate stacks (MAD_LINUX.md §10.2)

| option | licence | what it gives | what it costs |
|---|---|---|---|
| **Cairo + Pango** (+ FreeType/HarfBuzz) | LGPL-2.1/MPL-1.1, LGPL-2.1, FTL/GPLv2-dual, MIT | vector drawing with a PDF surface, and real text layout | a new dependency in the image and its licence/notice work |
| **libharu** | zlib | PDF output, permissive | PDF only, no layout engine |
| **Skia** | BSD-3 | capability closest to CG + Core Text | a heavy C++ build |
| **hand-written PDF emitter** | none | no dependency | approximate typography, a second drawing path |

**What was chosen (2026-11-20): Cairo + FreeType, no Pango.** The walk provides
the layout; only glyph advances and kerning remain, and FreeType's `kern` table
supplies them without a layout engine. Pango would have added a dependency (and
its LGPL/glib tree) for wrapping nobody needs.

### The open questions, answered

1. **Fonts** — see the mapping table above: Liberation Sans/Serif/Mono, chosen
   for the metric-compatible families, with the Verdana and Georgia residuals
   recorded.
2. **Which stack and licence** — Cairo (MPL-1.1), pixman (MIT), FreeType (FTL),
   Liberation (OFL): all permissive or MPL, none LGPL, no relink obligation.
3. **Where the writer lives** — in `MAD`, as `MADReportExporterPDFCairo`, its own
   translation unit and hidden header, compiled only off Apple. The Apple target
   does not link it.
4. **Is unattended server PDF needed?** — yes: the CLI's `export` verb and
   `serve`'s `export` are the surface, and a scheduled job has no browser.
