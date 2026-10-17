//
//  MADReportExporterHTMLFlow.m
//  MAD
//
//  See MADReportExporterHTMLFlow.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterHTMLFlow.h"

#import <MAD/MADDocumentRenderProtocol.h>

#import "MADReportExportSource.h"
#import "MADReportExportWriter.h"
#import "MADReportExporterRegistry.h"
#import "MADReportLineRepresentation.h"
#import "MADReportPageBuilder.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"

#import <MAD/MADocumentSectionType.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADReportLineStyle.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

static NSString *MADReportExporterFlowTypeToken(NSString *, NSString *);
static NSString *MADReportExporterFlowSectionHeading(NSString *, NSUInteger);
static NSString *MADReportExporterFlowEscaped(NSString *);
static NSString *MADReportExporterFlowCSSAlignment(MADHorizontalAlignment);

// The exporter instance lives for one export, so the style table it discovers while
// walking is per-file: one CSS class per distinct element style, written once in the
// head and referenced by every cell that has it.  A report's elements share a handful
// of styles, so this is what keeps a reflowable file lean.
@interface MADReportExporterHTMLFlow ()
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *styleClassNames;
@property (nonatomic, strong) NSMutableArray <NSString *> *styleRules;
@end

@implementation MADReportExporterHTMLFlow

+ (void)load {
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"html-flow";
}

+ (NSString *)formatDescription {
	return @"the rendered report as HTML the browser lays out, one table per section";
}

+ (NSString *)fileExtension {
	return @"html";
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

	if (![document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 3
									 userInfo: @{ NSLocalizedDescriptionKey:
					 @"the report's sections need a document that renders (MADDocumentRenderProtocol); "
					 @"--format json is the data half and needs no more." }];
		}
		return NO;
	}

	id <MADDocumentRenderProtocol> renderDocument = (id <MADDocumentRenderProtocol>)document;
	MADReportPageBuilder *builder = [MADReportPageBuilder builderForDocument: renderDocument];
	CGRect trimBox = [MADReportPageBuilder pageTrimBox];
	MADReportFormatter *reportFormatter = renderDocument.reportFormatter;

	self.styleClassNames = [[NSMutableDictionary alloc] init];
	self.styleRules = [[NSMutableArray alloc] init];

	NSMutableString *body = [[NSMutableString alloc] init];
	// A page header and a page footer are the same section on every page; the first
	// page's is emitted and the rest are recognised and skipped.
	NSMutableSet <NSString *> *furniture = [[NSMutableSet alloc] init];
	NSUInteger pageIndex = 0;
	for (pageIndex = 0; pageIndex < reportFormatter.numberOfPages; pageIndex++) {
		MADReportPageRepresentation *page = nil;
		@autoreleasepool {
			page = [builder buildPageAtIndex: pageIndex inPageRect: trimBox draw: NULL];
		}
		[self appendPage: page toHTML: body furniture: furniture];
	}

	NSMutableString *html = [[NSMutableString alloc] init];
	[html appendString: @"<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"];
	[html appendFormat: @"<title>%@</title>\n", MADReportExporterFlowEscaped(renderDocument.filename)];
	[html appendString: @"<style>\n"];
	[html appendString: @"html { font-family: sans-serif; font-size: 12pt }\n"];
	[html appendString: @"body { margin: 2em }\n"];
	[html appendString: @"section { margin: 0 0 1.5em 0 }\n"];
	[html appendString: @"section > h2 { font-size: 1em; margin: 0 0 0.25em 0; color: #444 }\n"];
	[html appendString: @"table { border-collapse: collapse }\n"];
	[html appendString: @"td { vertical-align: top; padding: 0 0.75em 0 0; white-space: pre }\n"];
	for (NSString *rule in self.styleRules) [html appendString: rule];
	[html appendString: @"</style>\n</head>\n<body>\n"];
	[html appendString: body];
	[html appendString: @"</body>\n</html>\n"];

	return [MADReportExportWriter writeString: html toURL: url error: error];
}

#pragma mark - Pages

- (void)appendPage:(MADReportPageRepresentation *)page
			toHTML:(NSMutableString *)html
		 furniture:(NSMutableSet <NSString *> *)furniture {

	for (MADReportSectionRepresentation *section in [page allSections]) {
		if ([self section: section isRepeatedFurniture: furniture]) continue;
		[self appendSection: section toHTML: html];
	}
}

/// YES for a page header or footer whose content was already emitted from an earlier
/// page.  Anything that differs -- a footer that did change -- is emitted again.
- (BOOL)section:(MADReportSectionRepresentation *)section
isRepeatedFurniture:(NSMutableSet <NSString *> *)furniture {

	MADDocumentSectionType type = section.type;
	if (type != MADDocumentSectionTypePageHeader && type != MADDocumentSectionTypePageFooter) {
		return NO;
	}
	NSString *signature = [self signatureForSection: section];
	BOOL repeated = [furniture containsObject: signature];
	[furniture addObject: signature];
	return repeated;
}

- (NSString *)signatureForSection:(MADReportSectionRepresentation *)section {
	NSMutableString *signature = [[NSMutableString alloc] init];
	[signature appendFormat: @"%d/%lu", (int)section.type, (unsigned long)section.groupLevel];
	for (MADReportSectionRowsRepresentation *row in [section allRows]) {
		for (MADReportLineRepresentation *line in [row allLines]) {
			[signature appendString: @"|"];
			[signature appendString: [line text] ?: @""];
		}
	}
	return signature;
}

#pragma mark - Sections

- (void)appendSection:(MADReportSectionRepresentation *)section toHTML:(NSMutableString *)html {

	NSString *type = MADReportExporterFlowTypeToken(NSStringFromMADDocumentSectionType(section.type),
													@"MADDocumentSectionType");
	[html appendFormat: @"<section data-type=\"%@\"", MADReportExporterFlowEscaped(type)];
	if (section.groupLevel != NSUIntegerMax) {
		[html appendFormat: @" data-group-level=\"%lu\"", (unsigned long)section.groupLevel];
	}
	[html appendFormat: @" data-visible=\"%@\">\n", section.isVisibile ? @"true" : @"false"];

	if (section.isVisibile) {
		[html appendString: @"<h2>"];
		[html appendString: MADReportExporterFlowEscaped(MADReportExporterFlowSectionHeading(type, section.groupLevel))];
		[html appendString: @"</h2>\n"];

		// The rows are built apart from the file: a section can have rows with no
		// elements in them -- the walk keeps the row, and the designer uses it for
		// spacing -- and an empty table would be noise in a reading view.
		NSMutableString *rows = [[NSMutableString alloc] init];
		for (MADReportSectionRowsRepresentation *row in [section allRows]) {
			NSMutableString *cells = [[NSMutableString alloc] init];
			for (MADReportLineRepresentation *line in [row allLines]) {
				[self appendLine: line toHTML: cells];
			}
			if (cells.length > 0) {
				[rows appendString: @"<tr>"];
				[rows appendString: cells];
				[rows appendString: @"</tr>\n"];
			}
		}
		if (rows.length > 0) {
			[html appendString: @"<table><tbody>\n"];
			[html appendString: rows];
			[html appendString: @"</tbody></table>\n"];
		}
	}
	[html appendString: @"</section>\n"];
}

- (void)appendLine:(MADReportLineRepresentation *)line toHTML:(NSMutableString *)html {

	NSString *kind = MADReportExporterFlowTypeToken(NSStringFromMADPrintPageElementType(line.elementType),
													@"MADPrintPageElementType");
	[html appendFormat: @"<td class=\"%@\" data-kind=\"%@\">",
		[self classNameForStyle: line.style], MADReportExporterFlowEscaped(kind)];
	NSString *text = [line text];
	if (text != nil) [html appendString: MADReportExporterFlowEscaped(text)];
	[html appendString: @"</td>"];
}

#pragma mark - The style table

- (NSString *)classNameForStyle:(MADReportLineStyle *)style {

	if (style == nil) return @"s0";

	NSString *signature = [[NSString alloc] initWithFormat: @"%@|%f|%d%d%d%d|%d",
						   style.fontName ?: @"", style.fontSize,
						   style.bold, style.italic, style.underline, style.strikethrough,
						   (int)style.horizontalAlignment];
	NSString *name = self.styleClassNames[signature];
	if (name != nil) return name;

	name = [[NSString alloc] initWithFormat: @"s%lu", (unsigned long)self.styleRules.count + 1];
	self.styleClassNames[signature] = name;
	[self.styleRules addObject: [self ruleForStyle: style name: name]];
	return name;
}

- (NSString *)ruleForStyle:(MADReportLineStyle *)style name:(NSString *)name {
	NSMutableString *rule = [[NSMutableString alloc] init];
	[rule appendFormat: @".%@ {", name];
	if (style.fontName.length > 0) {
		[rule appendFormat: @" font-family: '%@', sans-serif;", style.fontName];
	}
	if (style.fontSize > 0.0) {
		[rule appendString: @" font-size:"];
		[rule appendString: [MADReportExportSource stringForNumber: @(style.fontSize)]];
		[rule appendString: @"pt;"];
	}
	if (style.bold) [rule appendString: @" font-weight: bold;"];
	if (style.italic) [rule appendString: @" font-style: italic;"];
	if (style.underline && style.strikethrough) [rule appendString: @" text-decoration: underline line-through;"];
	else if (style.underline) [rule appendString: @" text-decoration: underline;"];
	else if (style.strikethrough) [rule appendString: @" text-decoration: line-through;"];
	NSString *alignment = MADReportExporterFlowCSSAlignment(style.horizontalAlignment);
	if (alignment != nil) [rule appendFormat: @" text-align: %@;", alignment];
	[rule appendString: @" }\n"];
	return rule;
}

#pragma mark - HTML spelling

// The runtime's stable spellings want their prefixes off, the way the JSON member's
// tokens do (MADReportExporterJSONReport).
static NSString *MADReportExporterFlowTypeToken(NSString *name, NSString *prefix) {
	if ([name hasPrefix: prefix]) {
		return [name substringFromIndex: prefix.length];
	}
	return name;
}

static NSString *MADReportExporterFlowSectionHeading(NSString *type, NSUInteger groupLevel) {
	if (groupLevel == NSUIntegerMax) return type;
	return [[NSString alloc] initWithFormat: @"%@ (level %lu)", type, (unsigned long)groupLevel];
}

static NSString *MADReportExporterFlowCSSAlignment(MADHorizontalAlignment alignment) {
	switch (alignment) {
		case MADHorizontalAlignmentLeft:		return @"left";
		case MADHorizontalAlignmentRight:		return @"right";
		case MADHorizontalAlignmentCenter:		return @"center";
		case MADHorizontalAlignmentJustified:	return @"justify";
		case MADHorizontalAlignmentNatrual:		return @"start";
		default:								return nil;
	}
}

static NSString *MADReportExporterFlowEscaped(NSString *string) {
	NSMutableString *escaped = [[NSMutableString alloc] initWithCapacity: string.length];
	NSUInteger index = 0;
	while (index < string.length) {
		unichar character = [string characterAtIndex: index];
		switch (character) {
			case '&':	[escaped appendString: @"&amp;"]; break;
			case '<':	[escaped appendString: @"&lt;"]; break;
			case '>':	[escaped appendString: @"&gt;"]; break;
			case '"':	[escaped appendString: @"&quot;"]; break;
			case '\'':	[escaped appendString: @"&#39;"]; break;
			default:	[escaped appendFormat: @"%C", character]; break;
		}
		index++;
	}
	return escaped;
}

@end
