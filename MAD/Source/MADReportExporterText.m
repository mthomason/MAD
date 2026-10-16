//
//  MADReportExporterText.m
//  MAD
//
//  See MADReportExporterText.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterText.h"

#import "MADReportExportSource.h"
#import "MADReportExportWriter.h"
#import "MADReportExporterRegistry.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

const NSUInteger MADReportExporterTextMaximumValueLength = 400;

// The two spaces between columns: wide enough to read, narrow enough that a wide
// table still fits a terminal's worth of fields.
static NSString * const MADReportExporterTextColumnSeparator = @"  ";

// A cell as one line of text: the value's string with the characters that would break
// the table escaped, and anything past the maximum elided.
static NSString *MADReportExporterTextCell(NSString *value) {
	NSMutableString *cell = [NSMutableString stringWithCapacity: value.length];
	NSUInteger index = 0;
	while (index < value.length && cell.length < MADReportExporterTextMaximumValueLength) {
		unichar character = [value characterAtIndex: index];
		switch (character) {
			case '\n': [cell appendString: @"\\n"]; break;
			case '\r': [cell appendString: @"\\r"]; break;
			case '\t': [cell appendString: @"\\t"]; break;
			default:   [cell appendFormat: @"%C", character]; break;
		}
		index++;
	}
	if (index < value.length) {
		[cell appendString: @"..."];
	}
	return cell;
}

// Padding by character count, not by bytes: a wide character is one column to the
// reader even though its UTF-8 form is several bytes, so %-*s with UTF8String would
// misalign every row after it.
static void MADReportExporterAppendSpaces(NSMutableString *out, NSUInteger count) {
	static NSString * const spaces = @"                                                                ";
	while (count >= spaces.length) {
		[out appendString: spaces];
		count -= spaces.length;
	}
	if (count > 0) {
		[out appendString: [spaces substringToIndex: count]];
	}
}

@implementation MADReportExporterText

+ (void)load {
	// Registered by link, the way a driver is (MADReportExporterRegistry.h); the CLI
	// reaches it by name and never by importing this class.
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"text";
}

+ (NSString *)formatDescription {
	return @"the rows as a fixed-width text table";
}

+ (NSString *)fileExtension {
	return @"txt";
}

+ (BOOL)requiresOutputPath {
	return NO;
}

+ (BOOL)isAvailable {
	return YES;
}

+ (NSString *)unavailableReason {
	return nil;
}

- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError * _Nullable __autoreleasing *)error {

	MADReportExportSource *source = [MADReportExportSource sourceWithDocument: document error: error];
	if (source == nil) return NO;

	NSArray <NSString *> *columnKeys = source.columnKeys;

	// The table is laid out in two passes -- every cell's text, then the widths -- so
	// a column is as wide as its widest value and the rows line up.  The widths start
	// at the header's, and a result with no rows is then just the header.
	NSMutableArray <NSNumber *> *widths = [NSMutableArray arrayWithCapacity: columnKeys.count];
	NSUInteger column = 0;
	for (NSString *columnKey in columnKeys) {
		[widths addObject: @(columnKey.length)];
		column++;
	}

	NSMutableArray <NSArray <NSString *> *> *rows = [NSMutableArray arrayWithCapacity: source.numberOfRows];
	NSEnumerator <NSDictionary <NSString *, id> *> *enumerator = [source rowEnumerator];
	NSDictionary <NSString *, id> *row = nil;
	while ((row = [enumerator nextObject]) != nil) {
		if (![row isKindOfClass: [NSDictionary class]]) continue;

		NSMutableArray <NSString *> *cells = [NSMutableArray arrayWithCapacity: columnKeys.count];
		column = 0;
		for (NSString *columnKey in columnKeys) {
			NSString *cell = MADReportExporterTextCell([source stringForValue: row[columnKey]]);
			[cells addObject: cell];
			widths[column] = @(MAX(widths[column].unsignedIntegerValue, cell.length));
			column++;
		}
		[rows addObject: cells];
	}

	NSMutableString *out = [[NSMutableString alloc] init];
	[out appendFormat: @"%@ -- %lu %@, %lu %@\n\n",
		source.driverName.length > 0 ? source.driverName : @"(unknown driver)",
		(unsigned long)columnKeys.count, columnKeys.count == 1 ? @"column" : @"columns",
		(unsigned long)source.numberOfRows, source.numberOfRows == 1 ? @"row" : @"rows"];

	[self appendRow: columnKeys widths: widths to: out];
	for (NSArray <NSString *> *cells in rows) {
		[self appendRow: cells widths: widths to: out];
	}

	return [MADReportExportWriter writeString: out toURL: url error: error];
}

// One padded line: every column except the last takes its width, so no line ends in
// spaces.
- (void)appendRow:(NSArray <NSString *> *)cells widths:(NSArray <NSNumber *> *)widths to:(NSMutableString *)out {
	NSUInteger column = 0;
	for (NSString *cell in cells) {
		if (column > 0) [out appendString: MADReportExporterTextColumnSeparator];
		if (column + 1 < cells.count) {
			[out appendString: cell];
			MADReportExporterAppendSpaces(out, widths[column].unsignedIntegerValue - cell.length);
		} else {
			[out appendString: cell];
		}
		column++;
	}
	[out appendString: @"\n"];
}

@end
