//
//  MADReportExporterJSONReport.m
//  MAD
//
//  See MADReportExporterJSONReport.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterJSONReport.h"

#import "MADReportExportSource.h"
#import "MADReportExporterRegistry.h"

#import <MAD/MADDocumentRenderProtocol.h>
#import <MAD/MADReportSectionRepresentation.h>
#import <MAD/MADReportSectionRowsRepresentation.h>
#import <MAD/MADReportLineRepresentation.h>
#import <MAD/MADReportPageRepresentation.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/MADDocumentObjectType.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

#if __APPLE__
// The render half: the formatter, the page renderer that walks it, the paper the
// application lays out on.  All three are excluded from the Linux build, which is why
// this format reports itself unavailable there (isAvailable below).
#import <MAD/MADPrintPageRenderer.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MTPaper.h>
#import <UIKit/UIGeometry.h>
#endif

#if __APPLE__

// "MADDocumentSectionTypeBody" is the runtime's stable spelling; a contract wants the
// tail.  The same rule the column types follow (MADReportExportSource.m).
static NSString *MADReportExporterTypeToken(NSString *name, NSString *prefix) {
	if ([name hasPrefix: prefix]) {
		return [name substringFromIndex: prefix.length];
	}
	return name;
}

#endif

@implementation MADReportExporterJSONReport

+ (void)load {
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"json-report";
}

+ (NSString *)formatDescription {
	return @"the rows as JSON, plus the rendered report's sections";
}

+ (NSString *)fileExtension {
	return @"json";
}

+ (BOOL)requiresOutputPath {
	return NO;
}

+ (BOOL)isAvailable {
#if __APPLE__
	return YES;
#else
	return NO;
#endif
}

+ (NSString *)unavailableReason {
#if __APPLE__
	return nil;
#else
	return @"the report's rendered structure needs the render half (MADReportFormatter and the page renderer), "
			"which this build does not compile (MAD_LINUX.md §9 Phase E); --format json is the data half and works here.";
#endif
}

// The CLI checks +isAvailable before it asks, but a direct caller must not get the
// data half's bytes under this format's name where the render half is absent.
- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError **)error {

	if (![[self class] isAvailable]) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 3
									 userInfo: @{ NSLocalizedDescriptionKey: [MADReportExporterJSONReport unavailableReason] }];
		}
		return NO;
	}

	return [super exportDocument: document toURL: url options: options error: error];
}

#if __APPLE__

- (void)appendEntriesToJSON:(NSMutableString *)json source:(MADReportExportSource *)source {
	[super appendEntriesToJSON: json source: source];

	[json appendString: @",\n  \"report\": {\n"];
	[self appendPagesToJSON: json document: source.document];
	[json appendString: @"  }"];
}

// The pages, in order, the way MADCLIDocument's PDF export walks them -- the same
// sequence before the walk (ready the rows, format the report), the same page renderer
// and the same letter-and-1pt-trim geometry -- with no context, so nothing is drawn.
- (void)appendPagesToJSON:(NSMutableString *)json document:(id <MADDocumentDataProtocol>)document {

	id <MADDocumentRenderProtocol> renderDocument = nil;
	if ([document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		renderDocument = (id <MADDocumentRenderProtocol>)document;
	}

	CGRect letterRect = [[MTPaper alloc] initWithType: MTPaperTypeLetter].bounds;
	CGRect trimBox = UIEdgeInsetsInsetRect(letterRect, UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0));

	[renderDocument prepareForQuery];

	MADReportFormatter *reportFormatter = renderDocument.reportFormatter;
	reportFormatter.overrideIdentifier = @"madpreview";
	reportFormatter.didRefresh = YES;
	reportFormatter.layoutSize = letterRect.size;
	[reportFormatter setMarginUsingPrintableRect: trimBox];
	[renderDocument format];

	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource: renderDocument];

	[json appendString: @"    \"pages\": ["];
	NSUInteger pageIndex = 0;
	for (pageIndex = 0; pageIndex < reportFormatter.numberOfPages; pageIndex++) {
		MADReportPageRepresentation *page = nil;
		@autoreleasepool {
			page = [renderer buildPageAtIndex: pageIndex context: NULL inPageRect: trimBox];
		}
		[json appendString: pageIndex == 0 ? @"\n" : @",\n"];
		[self appendPageToJSON: json page: page index: pageIndex];
	}
	if (pageIndex > 0) [json appendString: @"\n    ]\n"]; else [json appendString: @"]\n"];
}

- (void)appendPageToJSON:(NSMutableString *)json page:(MADReportPageRepresentation *)page index:(NSUInteger)pageIndex {

	[json appendFormat: @"      { \"index\": %lu,\n", (unsigned long)pageIndex];
	[json appendString: @"        \"sections\": ["];

	NSUInteger sectionIndex = 0;
	for (MADReportSectionRepresentation *section in [page allSections]) {
		[json appendString: sectionIndex == 0 ? @"\n" : @",\n"];
		[self appendSectionToJSON: json section: section];
		sectionIndex++;
	}
	if (sectionIndex > 0) [json appendString: @"\n        ] }"]; else [json appendString: @"] }"];
}

- (void)appendSectionToJSON:(NSMutableString *)json section:(MADReportSectionRepresentation *)section {

	NSString *type = MADReportExporterTypeToken(NSStringFromMADDocumentSectionType(section.type),
												@"MADDocumentSectionType");
	[json appendString: @"          { "];
	[json appendFormat: @"\"type\": %@, ", [MADReportExporterJSON quotedString: type]];

	// The report's own sections carry NSUIntegerMax for "no group level"
	// (MADSectionRepresentation.h); a contract spells that null.
	if (section.groupLevel == NSUIntegerMax) {
		[json appendString: @"\"groupLevel\": null, "];
	} else {
		[json appendFormat: @"\"groupLevel\": %lu, ", (unsigned long)section.groupLevel];
	}
	[json appendFormat: @"\"visible\": %@, ", section.isVisibile ? @"true" : @"false"];
	[json appendString: @"\"rows\": ["];

	NSUInteger rowIndex = 0;
	for (MADReportSectionRowsRepresentation *row in [section allRows]) {
		[json appendString: rowIndex == 0 ? @" " : @", "];
		[json appendString: @"{\"lines\": ["];
		NSUInteger lineIndex = 0;
		for (MADReportLineRepresentation *line in [row allLines]) {
			[json appendString: lineIndex == 0 ? @" " : @", "];
			[self appendLineToJSON: json line: line];
			lineIndex++;
		}
		[json appendString: lineIndex > 0 ? @" ]}" : @"]}"];
		rowIndex++;
	}
	[json appendString: rowIndex > 0 ? @" ] }" : @"] }"];
}

// A line: what kind of element it is, where it sits, and its resolved text when it has
// one.  An image has no text -- the member leaves it out rather than inventing one.
- (void)appendLineToJSON:(NSMutableString *)json line:(MADReportLineRepresentation *)line {

	NSString *kind = MADReportExporterTypeToken(NSStringFromMADPrintPageElementType(line.elementType),
												@"MADPrintPageElementType");
	[json appendString: @"{"];
	[json appendFormat: @"\"kind\": %@, ", [MADReportExporterJSON quotedString: kind]];
	[json appendFormat: @"\"frame\": [%@, %@, %@, %@]",
		[MADReportExportSource stringForNumber: @(line.frame.origin.x)],
		[MADReportExportSource stringForNumber: @(line.frame.origin.y)],
		[MADReportExportSource stringForNumber: @(line.frame.size.width)],
		[MADReportExportSource stringForNumber: @(line.frame.size.height)]];

	NSString *text = [line text];
	if (text != nil) {
		[json appendFormat: @", \"text\": %@", [MADReportExporterJSON quotedString: text]];
	}
	[json appendString: @"}"];
}

#endif

@end
