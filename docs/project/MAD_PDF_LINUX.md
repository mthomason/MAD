# The Linux PDF writer — status, options, and what it still needs

**Status (2026-10-17): deliberately deferred, blocked on the user's research. Do not
start it without the user's decision.** This file exists so the next agent knows what
is missing, what is already decided, and what is deliberately not.

## What exists

`pdf` is on the export seam, and it is the one format that does not run on Linux:

* `MADReportExporterPDF` registers everywhere (`+load`), requires `--out`, and its
  body is Apple's — Core Graphics drawing through `UIPrintPageRenderer`. It is the
  same code the CLI used before the seam, and its output is byte-identical to it
  (43,177 bytes, 5 pages, `sha256 3eb2f1c4…` on the London sample).
* Off Apple it answers `+isAvailable NO` with a reason, and `mad export --format pdf`
  exits 5 saying so. Nothing silently produces a different artifact.
* Everything above the writing is already shared and already identical on both
  platforms: `MADReportPageBuilder` prepares the document (sort the rows, size the
  formatter, lay the report out) and walks the pages at US Letter with the 1pt trim;
  `MADReportPageBuilder` + `MADDocumentRenderProtocol` + `MADDocumentRenderDataSource`
  are the one render path. The `html`, `html-flow` and `json-report` exports are
  byte-identical across platforms for the London fixture (`Linux/README.md`), so the
  page count, every element's frame, every line's text and every line's font, size,
  traits and alignment are known-good inputs to a writer.
* The supported way to get a PDF on Linux today is a browser printing `--format html`
  — which is why the facsimile exists and why it carries the page boxes.

## What is missing

**Only the writing.** A Linux body for `MADReportExporterPDF` that draws the walked
pages into a PDF file. Nothing above it changes: same preparation, same pages, same
frames, same text, same styles.

## The target, as decided (`MAD_LINUX.md` §10.2)

Same page count, same section and element boxes, same text and same fonts — **not**
byte-identical. Core Graphics' PDF writer cannot be reproduced, so byte equality is
off the table and should not be a test. The acceptance target is structural:

* the page count and each page's size and trim;
* each line's frame (the walk gives it) and resolved text;
* each line's font family, size, weight, slant, decoration and alignment;
* the same page furniture on the same pages.

## The candidate stacks

Recorded in `MAD_LINUX.md` §10.2; repeated here for the decision:

| option | licence | what it gives | what it costs |
|---|---|---|---|
| **Cairo + Pango** (+ FreeType/HarfBuzz) | LGPL-2.1/MPL-1.1, LGPL-2.1, FTL/GPLv2-dual, MIT | vector drawing with a PDF surface, and real text layout — the closest Linux has to Core Graphics + Core Text; the stack GTK/WebKit/Firefox use | a new dependency in the image and its licence/notice work; LGPL is a class the project already handles (FreeTDS) |
| **libharu** | zlib | PDF output, permissive | PDF only, no layout engine: wrapping and positioning are hand-rolled |
| **Skia** | BSD-3 | capability closest to CG + Core Text in one library, with a PDF backend | a heavy C++ build; an Impl wrapper would be warranted |
| **hand-written PDF emitter** | none | no dependency; base-14 fonts need no embedding | approximate typography, and a second drawing path — the drift the user rejected on 2026-10-16 |

## The open questions this needs research on

1. **Fonts are half the problem, and they are not in the table above.** Documents name
   Apple fonts: `MADFont` defaults to Helvetica Neue, and the London sample uses
   Verdana, Helvetica Neue and Courier. Linux has none of them. A writer needs
   metric-compatible substitutes (Nimbus Sans / TeX Gyre Heros / Liberation) and a
   mapping policy, and that policy changes what "looks the same" means. This is the
   part most likely to disappoint if skipped.
2. **Which stack, and at what licence cost.** Cairo + Pango is the recommendation on
   capability; whether its LGPL obligations are acceptable for the deployment shape is
   the user's call, as is the build cost in `Compressor`/`Linux/libraries.conf`.
3. **Where the writer lives.** In `MAD` (linked by the image and the CLI, Apple body
   unchanged), or a separate framework the exporter links? The seam supports either;
   it depends on the dependency's blast radius.
4. **Is unattended server PDF actually needed?** A browser printing the HTML facsimile
   covers a human-driven export today. A scheduled job with no browser does not. Until
   that is answered, nothing is blocked.

## The acceptance test, ready when the decision is

The oracle already exists: a Linux PDF can be compared against what the two platforms
already agree on.

* page count, page size and trim vs `MADReportPageBuilder`'s walk;
* each line's frame and text vs the `json-report` output for the same document (the
  Linux and Mac bytes are the same, so it is a stable oracle);
* the visual page vs the `html` facsimile (same boxes, same text);
* Apple's PDF must not change: 43,177 bytes / 5 pages / `sha256 3eb2f1c4…` on the
  London sample, checked with `--deterministic`.

## What to do meanwhile

Phase F (`MAD_LINUX.md` §9): the Compressor Linux driver, the CMake polish, the CI row
and the deployable image. None of it depends on the PDF writer, and it is the recorded
next step after Phase E. The open entries in `BUGS.md` are also fair game — but, per
that file's own rule, not on the agent's initiative.
