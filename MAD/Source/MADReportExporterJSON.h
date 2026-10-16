//
//  MADReportExporterJSON.h
//  MAD
//
//  `--format json`: the document's result set as JSON -- the contract MAD_CLI.md
//  section 8.3 asks for and MAD_DATA_OBJECT.md section 6 says the CLI, a webserver and
//  an AI layer should share.  The shape, one schema rather than three private ones:
//
//    {
//      "format":   "mad.report/1",
//      "document": { "driver": "Sqlite 3" },
//      "query":    { "sql": "SELECT ...", "rowCount": 76 },
//      "columns":  [ { "key", "name", "table", "type" } ],
//      "rows":     [ { "<column key>": <value> } ]
//    }
//
//  Keys are the column keys the query's SELECT list defines -- the qualified
//  "Customer0.City" the SQL itself writes -- and `columns` says what each one is
//  (the schema field's name and table, and its type as a stable token, never the
//  localized +dataTypeDisplay:).  A value is a JSON number, string, or null: NULL is
//  null (the distinction CSV cannot carry), binary is a base64 string, a date is ISO
//  8601.  `rows` objects are one line each; the rest is indented.
//
//  The text is written by this class, not by NSJSONSerialization: the key order is
//  fixed and the number spelling is locale-independent, so two runs -- and the two
//  platforms -- produce the same bytes (the same property the .mad writer is being
//  given; BUGS.md, the byte-identity entry).
//
//  json-report is this class with one more member, "report" (MADReportExporterJSONReport);
//  the subclassing seam is -appendEntriesToJSON:source:.
//

#ifndef MAD_MADReportExporterJSON_h
#define MAD_MADReportExporterJSON_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@class MADReportExportSource;

@interface MADReportExporterJSON : NSObject <MADReportExporting>

/// The members of the top-level object, in the order the schema lists them, each
/// followed by a comma except the last, at one level of indentation.  A subclass that
/// adds a member of its own calls super and appends its own.
- (void)appendEntriesToJSON:(NSMutableString *)json
                     source:(MADReportExportSource *)source;

/// A JSON string literal for `string`, quotes included: `"`, `\` and the control
/// characters escaped.
+ (NSString *)quotedString:(NSString *)string;

/// A value's JSON spelling at one level of indentation: a number bare, NULL as null,
/// everything else through MADReportExportSource's presentations and then quoted.
+ (void)appendValue:(nullable id)value to:(NSMutableString *)json source:(MADReportExportSource *)source;

@end

NS_ASSUME_NONNULL_END

#endif
