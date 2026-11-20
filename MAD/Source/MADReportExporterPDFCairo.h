//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterPDFCairo.h
//  MAD
//
//  The headless half of `--format pdf`: MADReportExporterPDF's non-Apple body.
//  It draws the same page walk the Apple body draws -- MADReportPageBuilder's
//  pages, MADReportLineRepresentation's lines -- into a Cairo PDF surface, with
//  FreeType shaping the glyphs from the bundled Liberation faces.  Core Graphics
//  cannot be reproduced, so the target is structural parity, not byte parity
//  (docs/project/MAD_PDF_LINUX.md).
//
//  Compiled only where Core Graphics is not (the Linux and Windows source lists);
//  the Apple body keeps its own path untouched.
//

#ifndef MAD_MADReportExporterPDFCairo_h
#define MAD_MADReportExporterPDFCairo_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MADDocumentDataProtocol;

@interface MADReportExporterPDFCairo : NSObject

/// Writes the document's walked pages to url as a PDF.  The document must conform
/// to MADDocumentRenderProtocol; url must be non-nil (the format requires --out).
+ (BOOL)writeDocument:(id <MADDocumentDataProtocol>)document
				toURL:(NSURL *)url
			  options:(MADReportExportOptions)options
				error:(NSError * _Nullable __autoreleasing *)error;

/// The directory the bundled Liberation faces were found in, for the export's
/// failure message and the tests; nil when they are missing.
+ (nullable NSString *)fontsDirectory;

@end

NS_ASSUME_NONNULL_END

#endif
