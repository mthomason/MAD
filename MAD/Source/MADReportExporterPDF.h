//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterPDF.h
//  MAD
//
//  `--format pdf`: the rendered report, drawn.  Pages come from the same walk
//  json-report reads and the HTML facsimile prints from (MADReportPageBuilder).
//  The drawing is MADPrintPageRenderer's on Apple -- UIKit's UIPrintPageRenderer
//  over Core Graphics -- and MADReportExporterPDFCairo's everywhere else: a Cairo
//  PDF surface with FreeType glyphs from the bundled Liberation faces.  The format
//  is available on every platform; the two writers target structural parity (same
//  pages, frames and text), not the same bytes (docs/project/MAD_PDF_LINUX.md).
//
//  `--out` is required: a PDF is a file, not a stream.
//
//  With MADReportExportOptionsDeterministic the export pins what the writer would
//  otherwise take from the clock -- Core Graphics' creation and modification dates
//  and trailer identifier, Cairo's creation and modification dates -- so two runs
//  over an unchanged report are the same bytes and a difference means a real one.
//  On Apple every replacement is the same length as what it replaces, so the
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
