//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

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
#import "MADReportFormatter.h"
#import "MADReportPageBuilder.h"

#import <MAD/MADDocumentRenderProtocol.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/MADReportLineRepresentation.h>
#import <MAD/MADReportPageRepresentation.h>
#import <MAD/MADReportSectionRepresentation.h>
#import <MAD/MADReportSectionRowsRepresentation.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/MADDocumentObjectType.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

// "MADDocumentSectionTypeBody" is the runtime's stable spelling; a contract wants the
// tail.  The same rule the column types follow (MADReportExportSource.m).
static NSString *MADReportExporterTypeToken(NSString *name, NSString *prefix) {
	if ([name hasPrefix: prefix]) {
		return [name substringFromIndex: prefix.length];
	}
	return name;
}

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
	// The report member reads the page walk, which is the render half's and is
	// compiled wherever the data half is (MADDocumentRenderProtocol).
	return YES;
}

+ (NSString *)unavailableReason {
	return nil;
}

// The CLI checks +isAvailable before it asks, but a direct caller must not get the
// data half's bytes under this format's name from a document that cannot render.
- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 query:(RptqQuery *)query
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError * _Nullable __autoreleasing *)error {
	if (query == nil || [query isLayoutRootInDocument: document.activeDocumentModel]) {
		return [self exportDocument: document toURL: url options: options error: error];
	}
	// json-report cannot render a specific node's pages and rows yet: it would write
	// the root's rows for a non-root query.  Error rather than silently do that.
	if (error != NULL) {
		*error = [NSError errorWithDomain: @"MADReportExport" code: 3 userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"json-report cannot export a specific node.", @"Error when json-report is asked for a non-root node.") }];
	}
	return NO;
}

- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError * _Nullable __autoreleasing *)error {

	if (![document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 3
									 userInfo: @{ NSLocalizedDescriptionKey:
					 NSLocalizedString(@"the report's rendered structure needs a document that renders (MADDocumentRenderProtocol); " @"--format json is the data half and needs no more.", @"Error when the JSON report export has no renderable document.") }];
		}
		return NO;
	}

	return [super exportDocument: document toURL: url options: options error: error];
}

- (void)appendEntriesToJSON:(NSMutableString *)json source:(MADReportExportSource *)source {
	// One snapshot for the rows and the pages: the export source already pinned the
	// result it was created with, and the page walk below must read the same one, so
	// a refresh that publishes mid-export cannot pair one generation's rows with
	// another's pages.  Pin the render data source explicitly (the format's own pin
	// then leaves it alone) and clear it when the export is done.
	id <MADDocumentRenderProtocol> renderDocument = nil;
	if ([source.document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		renderDocument = (id <MADDocumentRenderProtocol>)source.document;
	}
	BOOL pinned = NO;
	if ([renderDocument respondsToSelector: @selector(pinRenderResult:)]) {
		[renderDocument pinRenderResult: source.result];
		pinned = YES;
	}

	[super appendEntriesToJSON: json source: source];

	[json appendString: @",\n  \"report\": {\n"];
	[self appendPagesToJSON: json document: source.document];
	[json appendString: @"  }"];

	if (pinned) {
		[renderDocument unpinRenderResult];
	}
}

// The pages, in order: the same walk the PDF draws from and the HTML formats read
// (MADReportPageBuilder), with no drawing block, on the same letter-and-1pt-trim page.
- (void)appendPagesToJSON:(NSMutableString *)json document:(id <MADDocumentDataProtocol>)document {

	id <MADDocumentRenderProtocol> renderDocument = nil;
	if ([document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		renderDocument = (id <MADDocumentRenderProtocol>)document;
	}

	MADReportPageBuilder *builder = [MADReportPageBuilder builderForDocument: renderDocument];
	CGRect trimBox = [MADReportPageBuilder pageTrimBoxForDocument: renderDocument];
	MADReportFormatter *reportFormatter = renderDocument.reportFormatter;

	[json appendString: @"    \"pages\": ["];
	NSUInteger pageIndex = 0;
	for (pageIndex = 0; pageIndex < reportFormatter.numberOfPages; pageIndex++) {
		MADReportPageRepresentation *page = nil;
		@autoreleasepool {
			page = [builder buildPageAtIndex: pageIndex inPageRect: trimBox draw: NULL];
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

// A line: what kind of element it is, where it sits on the page, and its resolved text
// when it has one.  An image has no text -- the member leaves it out rather than
// inventing one.
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
	// A barcode or image line also carries a picture; the member is a token, not the
	// bytes, so the document stays text and the image is re-rendered on demand.
	if (line.imageData != nil) {
		[json appendString: @", \"image\": true"];
	}
	[json appendString: @"}"];
}

@end
