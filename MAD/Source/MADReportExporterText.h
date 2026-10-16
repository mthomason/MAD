//
//  MADReportExporterText.h
//  MAD
//
//  `--format text`: the document's rows as a fixed-width table, for a reader.  Pure
//  Foundation and no renderer, so it is the format that proves the export seam is
//  real on both platforms (ROADMAP.md section 5.2: text first, because if the seam
//  is wrong, text is where that shows).
//
//  The content is the same as json's and csv's -- the columns the query selects, the
//  rows the refresh filled -- laid out rather than quoted.  A value wider than the
//  table's longest line is elided at MADReportExporterTextMaximumValueLength with a
//  trailing ellipsis, and newlines and tabs inside a value are shown escaped (\\n,
//  \\t): the CSV and JSON formats are the lossless ones.
//

#ifndef MAD_MADReportExporterText_h
#define MAD_MADReportExporterText_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

/// The width past which a value is elided in the text table.
NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger MADReportExporterTextMaximumValueLength;

@interface MADReportExporterText : NSObject <MADReportExporting>
@end

NS_ASSUME_NONNULL_END

#endif
