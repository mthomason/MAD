//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterPDF.h
//  MAD
//
//  `--format pdf`: the rendered report, drawn.  Pages come from the same walk
//  json-report reads and the HTML facsimile prints from (MADReportPageBuilder), and
//  the drawing is MADPrintPageRenderer's -- UIKit's UIPrintPageRenderer over Core
//  Graphics, which is Apple's alone, so this format registers everywhere and answers
//  +isAvailable NO where the renderer is not compiled.  It is the CLI's own arm moved
//  onto the seam (MAD_CLI.md §5.3), and the render-half protocol's second customer.
//
//  `--out` is required: Core Graphics writes a file, not a stream.
//
//  With MADReportExportOptionsDeterministic the export pins what Core Graphics takes
//  from the clock -- the creation and modification dates and the trailer identifier --
//  so two runs over an unchanged report are the same bytes and a difference means a
//  real one.  Every replacement is the same length as what it replaces, so the
//  cross-reference offsets stay correct and the file is still a valid PDF.
//

#ifndef MAD_MADReportExporterPDF_h
#define MAD_MADReportExporterPDF_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportExporterPDF : NSObject <MADReportExporting>
@end

NS_ASSUME_NONNULL_END

#endif
