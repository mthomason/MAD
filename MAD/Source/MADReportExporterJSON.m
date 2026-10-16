//
//  MADReportExporterJSON.m
//  MAD
//
//  See MADReportExporterJSON.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterJSON.h"

#import "MADReportExportSource.h"
#import "MADReportExportWriter.h"
#import "MADReportExporterRegistry.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>

// The schema's identifier: a reader dispatches on it the way MAD_FORMAT.md's magic
// dispatches on a container.  It changes when the members' meaning changes, not when
// one is added.
static NSString * const MADReportExporterJSONFormat = @"mad.report/1";

@implementation MADReportExporterJSON

+ (void)load {
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"json";
}

+ (NSString *)formatDescription {
	return @"the rows as JSON, one object per row";
}

+ (NSString *)fileExtension {
	return @"json";
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

	NSMutableString *json = [[NSMutableString alloc] init];
	[json appendString: @"{\n"];
	[self appendEntriesToJSON: json source: source];
	[json appendString: @"}\n"];

	return [MADReportExportWriter writeString: json toURL: url error: error];
}

- (void)appendEntriesToJSON:(NSMutableString *)json source:(MADReportExportSource *)source {

	// Each member but the first is *preceded* by its comma, so the object never ends on
	// a comma and a subclass appending a member after -super has one place to put its
	// own.

	[json appendFormat: @"  \"format\": %@", [MADReportExporterJSON quotedString: MADReportExporterJSONFormat]];

	[json appendString: @",\n  \"document\": {\n"];
	[json appendFormat: @"    \"driver\": %@\n", [MADReportExporterJSON quotedString: source.driverName]];
	[json appendString: @"  }"];

	[json appendString: @",\n  \"query\": {\n"];
	[json appendFormat: @"    \"sql\": %@,\n", [MADReportExporterJSON quotedString: source.sql]];
	[json appendFormat: @"    \"rowCount\": %lu\n", (unsigned long)source.numberOfRows];
	[json appendString: @"  }"];

	[json appendString: @",\n  \"columns\": ["];
	NSUInteger column = 0;
	for (NSString *columnKey in source.columnKeys) {
		[json appendString: column == 0 ? @"\n" : @",\n"];
		[json appendString: @"    {\n"];
		[json appendFormat: @"      \"key\": %@,\n", [MADReportExporterJSON quotedString: columnKey]];
		[json appendFormat: @"      \"name\": %@,\n", [MADReportExporterJSON quotedString: [source columnName: columnKey]]];

		NSString *table = [source columnTable: columnKey];
		[json appendFormat: @"      \"table\": %@,\n",
			table != nil ? [MADReportExporterJSON quotedString: table] : @"null"];

		NSString *type = [source columnType: columnKey];
		[json appendFormat: @"      \"type\": %@\n",
			type != nil ? [MADReportExporterJSON quotedString: type] : @"null"];

		[json appendString: @"    }"];
		column++;
	}
	if (column > 0) [json appendString: @"\n  ]"]; else [json appendString: @"]"];

	[json appendString: @",\n  \"rows\": ["];
	NSEnumerator <NSDictionary <NSString *, id> *> *enumerator = [source rowEnumerator];
	NSDictionary <NSString *, id> *row = nil;
	BOOL wroteRow = NO;
	while ((row = [enumerator nextObject]) != nil) {
		if (![row isKindOfClass: [NSDictionary class]]) continue;

		[json appendString: wroteRow ? @",\n" : @"\n"];
		wroteRow = YES;

		// One row per line: a report of any size stays skimmable, and the structure
		// above it stays indented.
		[json appendString: @"    { "];
		column = 0;
		for (NSString *columnKey in source.columnKeys) {
			if (column > 0) [json appendString: @", "];
			[json appendFormat: @"%@: ", [MADReportExporterJSON quotedString: columnKey]];
			[MADReportExporterJSON appendValue: row[columnKey] to: json source: source];
			column++;
		}
		[json appendString: @" }"];
	}
	if (wroteRow) [json appendString: @"\n  ]"]; else [json appendString: @"]"];

	[json appendString: @"\n"];
}

#pragma mark - JSON spelling

+ (NSString *)quotedString:(NSString *)string {
	NSMutableString *quoted = [NSMutableString stringWithCapacity: string.length + 2];
	[quoted appendString: @"\""];
	NSUInteger index = 0;
	while (index < string.length) {
		unichar character = [string characterAtIndex: index];
		switch (character) {
			case '"':  [quoted appendString: @"\\\""]; break;
			case '\\': [quoted appendString: @"\\\\"]; break;
			case '\b': [quoted appendString: @"\\b"]; break;
			case '\f': [quoted appendString: @"\\f"]; break;
			case '\n': [quoted appendString: @"\\n"]; break;
			case '\r': [quoted appendString: @"\\r"]; break;
			case '\t': [quoted appendString: @"\\t"]; break;
			default:
				if (character < 0x20) {
					[quoted appendFormat: @"\\u%04x", (unsigned int)character];
				} else {
					[quoted appendFormat: @"%C", character];
				}
				break;
		}
		index++;
	}
	[quoted appendString: @"\""];
	return quoted;
}

+ (void)appendValue:(nullable id)value to:(NSMutableString *)json source:(MADReportExportSource *)source {
	if (value == nil || value == [NSNull null]) {
		[json appendString: @"null"];
		return;
	}
	if ([value isKindOfClass: [NSNumber class]]) {
		// Numbers stay numbers -- a JSON reader should not have to parse them back --
		// and +stringForNumber: spells them the same on both platforms.
		[json appendString: [MADReportExportSource stringForNumber: (NSNumber *)value]];
		return;
	}
	[json appendString: [MADReportExporterJSON quotedString: [source stringForValue: value]]];
}

@end
