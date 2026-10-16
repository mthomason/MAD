//
//  MADReportExportSource.h
//  MAD
//
//  One document, read the way every exporter reads it: the identity, the columns in
//  the order the query defines, the rows, and one value's presentation.  An exporter
//  that re-derived any of this would drift from the others, so this is the one place
//  that answers -- and it is deliberately pure Foundation, so a format that needs no
//  rendering works wherever a document opens (MAD_LINUX.md section 9 Phase E).
//
//  The columns are the document's *result* columns: the query's active fields, which
//  are the row cache's columns in the same order (MADQuerySelectExpressionActiveFields
//  defines it; BUGS.md, the SELECT-list entry).  The rows are keyed by column key,
//  which is what MADDataTableFast hands back.
//

#ifndef MAD_MADReportExportSource_h
#define MAD_MADReportExportSource_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MADDocumentDataProtocol;

@class RptqDatabase;

@interface MADReportExportSource : NSObject

/// Reads the document's query, schema and row table.  Fails when the query generates
/// no SQL -- there is nothing to export then.
+ (nullable instancetype)sourceWithDocument:(id <MADDocumentDataProtocol>)document
									  error:(NSError * _Nullable __autoreleasing *)error;

@property (readonly, nonatomic, strong) id <MADDocumentDataProtocol> document;

/// The stored driver identifier -- "Sqlite 3", "MySQL", "TDS" -- which is a
/// document-format constant (MADDatabaseDriverRegistry.h).
@property (readonly, nonatomic, copy) NSString *driverName;

/// The SQL the document's query generates.
@property (readonly, nonatomic, copy) NSString *sql;

/// The column keys, in the order the SELECT list defines.
@property (readonly, nonatomic, copy) NSArray <NSString *> *columnKeys;

@property (readonly, nonatomic, assign) NSUInteger numberOfRows;

/// The schema field's name for a column key, or the key itself when the document
/// does not name one (a zero-row result still describes its columns this way).
- (NSString *)columnName:(NSString *)columnKey;

/// The schema table's name for a column key, or nil when the document does not name one.
- (nullable NSString *)columnTable:(NSString *)columnKey;

/// The stored data type as a stable token -- "String", "Integer", "Date" -- or nil.
/// Not RptqDatabaseSchemaField +dataTypeDisplay:, which is localized.
- (nullable NSString *)columnType:(NSString *)columnKey;

/// The rows in table order, each keyed by column key; nil when the result has no
/// columns at all.
- (nullable NSEnumerator <NSDictionary <NSString *, id> *> *)rowEnumerator;

/// One value as text: NULL is the empty string, binary is base64, a date is ISO 8601,
/// a number is +stringForNumber:, anything else is its -description.  CSV, the text
/// table and the JSON exporter's strings all go through this, so they agree.
- (NSString *)stringForValue:(nullable id)value;

/// The canonical spelling of a number in every format: an integer without a fraction,
/// a real in a locale-independent round-trip form (15 significant digits when they
/// round-trip, 17 when they do not) -- the same string on Apple and on GNUstep.
+ (NSString *)stringForNumber:(NSNumber *)number;

/// The ISO 8601 UTC spelling of a date, "2001-01-12T00:00:00Z", computed from the
/// epoch rather than through a formatter, so the locale cannot reach it.
+ (NSString *)stringForDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END

#endif
