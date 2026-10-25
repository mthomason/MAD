//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporting.h
//  MAD
//
//  The export seam (MAD_CLI.md section 5.3, ROADMAP.md section 5.2): a format is a
//  class that adopts this protocol and registers itself with MADReportExporterRegistry
//  in +load, not an arm of a switch.  The shape is the driver registry's
//  (MADDatabaseDriverRegistry.h, ROADMAP.md section 5.1) -- an implementation protocol
//  and a lookup by name -- so adding "export to markdown" is a new class in a new
//  framework and nothing in the core changes.
//
//  An exporter reads the document through MADDocumentDataProtocol, so a format that
//  needs no rendering works wherever a document opens -- Apple and Linux alike.  A
//  format that needs the render half says so: it registers everywhere and answers
//  +isAvailable NO with a reason where the machinery is absent (json-report off Apple
//  until the render half ports; MAD_LINUX.md section 9 Phase E).
//

#ifndef MAD_MADReportExporting_h
#define MAD_MADReportExporting_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MADDocumentDataProtocol;

typedef NS_OPTIONS(NSUInteger, MADReportExportOptions) {
	MADReportExportOptionsNone				= 0,

	/// Pin whatever a writer would otherwise take from the clock, so two runs over an
	/// unchanged report produce identical bytes (the PDF exporter's creation and
	/// modification dates and trailer identifier; MADCLIPinPDFMetadata).
	MADReportExportOptionsDeterministic	= 1 << 0,
};

@protocol MADReportExporting <NSObject>
@required

/// The name `mad export --format` matches.  Lower case, one word: "text", "csv",
/// "json", "json-report", "pdf".
+ (NSString *)formatName;

/// One line for the usage text: what the format writes.
+ (NSString *)formatDescription;

/// The extension of what it writes, without the dot: "txt", "csv", "json", "pdf".
+ (NSString *)fileExtension;

/// YES for a format that cannot write to a stream and therefore needs --out.
+ (BOOL)requiresOutputPath;

/// NO when this process cannot produce the format -- the machinery is not linked or
/// not ported.  The CLI reports +unavailableReason instead of calling the exporter.
+ (BOOL)isAvailable;

/// Why +isAvailable answers NO; nil when it answers YES.
+ (nullable NSString *)unavailableReason;

/// Writes the document's data in this format to url, or to the standard output when
/// url is nil (only for a format whose +requiresOutputPath is NO).
- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
                 toURL:(nullable NSURL *)url
               options:(MADReportExportOptions)options
                 error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
