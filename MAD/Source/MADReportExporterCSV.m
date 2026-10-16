//
//  MADReportExporterCSV.m
//  MAD
//
//  See MADReportExporterCSV.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterCSV.h"

#import "MADReportExportSource.h"
#import "MADReportExportWriter.h"
#import "MADReportExporterRegistry.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

static NSString * const MADReportExporterCSVLineEnding = @"\r\n";

// RFC 4180: a field is quoted when it holds a quote, a comma, a carriage return or a
// line feed; an embedded quote is doubled.  Everything else is written as it is.
static NSString *MADReportExporterCSVField(NSString *value) {
	if ([value rangeOfString: @"\""].location == NSNotFound &&
		[value rangeOfString: @","].location == NSNotFound &&
		[value rangeOfString: @"\n"].location == NSNotFound &&
		[value rangeOfString: @"\r"].location == NSNotFound) {
		return value;
	}
	NSMutableString *quoted = [NSMutableString stringWithCapacity: value.length + 2];
	[quoted appendString: @"\""];
	NSUInteger index = 0;
	while (index < value.length) {
		unichar character = [value characterAtIndex: index];
		if (character == '"') [quoted appendString: @"\"\""];
		else [quoted appendFormat: @"%C", character];
		index++;
	}
	[quoted appendString: @"\""];
	return quoted;
}

@implementation MADReportExporterCSV

+ (void)load {
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"csv";
}

+ (NSString *)formatDescription {
	return @"the rows as RFC 4180 CSV";
}

+ (NSString *)fileExtension {
	return @"csv";
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
	NSMutableString *out = [[NSMutableString alloc] init];

	NSUInteger column = 0;
	for (NSString *columnKey in columnKeys) {
		if (column > 0) [out appendString: @","];
		[out appendString: MADReportExporterCSVField(columnKey)];
		column++;
	}
	[out appendString: MADReportExporterCSVLineEnding];

	NSEnumerator <NSDictionary <NSString *, id> *> *enumerator = [source rowEnumerator];
	NSDictionary <NSString *, id> *row = nil;
	while ((row = [enumerator nextObject]) != nil) {
		if (![row isKindOfClass: [NSDictionary class]]) continue;

		column = 0;
		for (NSString *columnKey in columnKeys) {
			if (column > 0) [out appendString: @","];
			[out appendString: MADReportExporterCSVField([source stringForValue: row[columnKey]])];
			column++;
		}
		[out appendString: MADReportExporterCSVLineEnding];
	}

	return [MADReportExportWriter writeString: out toURL: url error: error];
}

@end
