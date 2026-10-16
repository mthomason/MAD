//
//  MADReportExporterCSV.h
//  MAD
//
//  `--format csv`: the document's rows as RFC 4180 CSV -- a header row of the column
//  keys, then one line per row, CRLF between lines, a field quoted only when it has
//  to be.  Pure Foundation, so it is the format a spreadsheet and a script both take
//  on any platform.
//
//  A NULL is an empty field (RFC 4180 has no spelling for it; json is the format that
//  keeps the distinction), binary is base64, and a date is ISO 8601 -- the same
//  presentations the text table and json use.
//

#ifndef MAD_MADReportExporterCSV_h
#define MAD_MADReportExporterCSV_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportExporterCSV : NSObject <MADReportExporting>
@end

NS_ASSUME_NONNULL_END

#endif
