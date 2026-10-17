//
//  MADReportExporterHTML.h
//  MAD
//
//  `--format html`: the rendered report as one self-contained HTML file, page boxes
//  and all.  It is a facsimile of what the PDF prints -- one CSS page box per report
//  page, each element absolutely positioned at the frame the page walk gives it, its
//  resolved text inside -- so a browser prints it to the same pages, and a reader can
//  see the report without a PDF viewer.  The companion `html-flow` is the same report
//  with the page geometry dropped and the browser laying it out.
//
//  The four things that decide whether it matches the PDF, and where each comes from
//  (MADElementStylizedText is the Apple-side original of all four):
//
//    * the pages      MADReportPageBuilder's walk, the same one json-report reads and
//                     the PDF draws -- one page box per walked page, letter size
//    * the frames     the walked line's frame, which is where the drawing would put it
//    * the font       the element's stored font name and size
//    * the traits     bold, italic, underline, strikethrough and the horizontal
//                     alignment, mapped to CSS
//
//  Line breaking is the same rule too: the renderer draws with
//  NSLineBreakByTruncatingTail, which CSS spells
//  `white-space: nowrap; overflow: hidden; text-overflow: ellipsis`.
//
//  What it does not carry: colours (the store's four colour reals have no reader on
//  either platform today, so the PDF is monochrome too) and images (an image element
//  is an empty, correctly-placed box; the PDF's image path is Core Graphics').  Both
//  are recorded rather than approximated.
//
//  The file is UTF-8 and pure Foundation: the same bytes on Apple and on Linux, like
//  the other Foundation formats.
//

#ifndef MAD_MADReportExporterHTML_h
#define MAD_MADReportExporterHTML_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportExporterHTML : NSObject <MADReportExporting>
@end

NS_ASSUME_NONNULL_END

#endif
