//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterHTML.m
//  MAD
//
//  See MADReportExporterHTML.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterHTML.h"

#import <MAD/MADDocumentRenderProtocol.h>

#import "MADReportExportSource.h"
#import "MADReportExportWriter.h"
#import "MADReportExporterRegistry.h"
#import "MADReportLineRepresentation.h"
#import "MADReportFormatter.h"
#import "MADReportPageBuilder.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"

#import <MAD/MADReportLineStyle.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

static NSString *MADReportExporterHTMLTypeToken(NSString *, NSString *);
static NSString *MADReportExporterCSSAlignment(MADHorizontalAlignment);
static NSString *MADReportExporterFontName(NSString *);

@implementation MADReportExporterHTML

+ (void)load {
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"html";
}

+ (NSString *)formatDescription {
	return @"the rendered report as one HTML file, one page box per page";
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
					 @"the facsimile needs a document that renders (MADDocumentRenderProtocol); "
					 @"--format html-flow is the reflowable one and needs no more." }];
		}
		return NO;
	}

	id <MADDocumentRenderProtocol> renderDocument = (id <MADDocumentRenderProtocol>)document;
	MADReportPageBuilder *builder = [MADReportPageBuilder builderForDocument: renderDocument];
	CGRect pageBounds = [MADReportPageBuilder pageBoundsForDocument: renderDocument];
	CGRect trimBox = [MADReportPageBuilder pageTrimBoxForDocument: renderDocument];
	MADReportFormatter *reportFormatter = renderDocument.reportFormatter;

	NSMutableString *html = [[NSMutableString alloc] init];
	[html appendString: @"<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"];
	[html appendFormat: @"<title>%@</title>\n", [MADReportExporterHTML escapedString: renderDocument.filename]];
	[html appendString: @"<style>\n"];
	[html appendString: @"@page { size: "];
	[self appendPageSize: pageBounds.size toHTML: html];
	[html appendString: @"; margin: 0 }\n"];
	[html appendString: @"html, body { margin: 0; padding: 0 }\n"];
	[html appendString: @"body { background: #fff; color: #000 }\n"];
	// One box per page, the page's own size, broken before every page but the first --
	// `break-before` is what a current browser reads and `page-break-before` what an
	// older print path does.
	[html appendString: @".page { position: relative; overflow: hidden; break-before: page; page-break-before: always }\n"];
	[html appendString: @".page:first-of-type { break-before: auto; page-break-before: auto }\n"];
	// The renderer's line-break rule, spelled the way CSS spells it: one line, clipped,
	// with an ellipsis (MADElementStylizedText sets NSLineBreakByTruncatingTail).  `pre`
	// keeps the resolved text exactly, spaces and all.
	[html appendString: @".line { position: absolute; white-space: pre; overflow: hidden; text-overflow: ellipsis; line-height: normal }\n"];
	[html appendString: @"</style>\n</head>\n<body>\n"];

	NSUInteger pageIndex = 0;
	for (pageIndex = 0; pageIndex < reportFormatter.numberOfPages; pageIndex++) {
		MADReportPageRepresentation *page = nil;
		@autoreleasepool {
			page = [builder buildPageAtIndex: pageIndex inPageRect: trimBox draw: NULL];
		}
		[self appendPage: page index: pageIndex pageSize: pageBounds.size toHTML: html];
	}

	[html appendString: @"</body>\n</html>\n"];

	return [MADReportExportWriter writeString: html toURL: url error: error];
}

#pragma mark - Pages

- (void)appendPage:(MADReportPageRepresentation *)page index:(NSUInteger)pageIndex pageSize:(CGSize)pageSize toHTML:(NSMutableString *)html {

	[html appendFormat: @"<div class=\"page\" data-index=\"%lu\" style=\"", (unsigned long)pageIndex];
	[self appendSize: pageSize toHTML: html];
	[html appendString: @"\">\n"];

	for (MADReportSectionRepresentation *section in [page allSections]) {
		for (MADReportSectionRowsRepresentation *row in [section allRows]) {
			for (MADReportLineRepresentation *line in [row allLines]) {
				[self appendLine: line toHTML: html];
			}
		}
	}

	[html appendString: @"</div>\n"];
}

- (void)appendLine:(MADReportLineRepresentation *)line toHTML:(NSMutableString *)html {

	NSString *kind = MADReportExporterHTMLTypeToken(NSStringFromMADPrintPageElementType(line.elementType),
													@"MADPrintPageElementType");
	CGRect frame = line.frame;

	[html appendString: @"<div class=\"line\" data-kind=\""];
	[html appendString: [MADReportExporterHTML escapedString: kind]];
	[html appendString: @"\" style=\"left:"];
	[html appendString: [MADReportExportSource stringForNumber: @(frame.origin.x)]];
	[html appendString: @"pt; top:"];
	[html appendString: [MADReportExportSource stringForNumber: @(frame.origin.y)]];
	[html appendString: @"pt; width:"];
	[html appendString: [MADReportExportSource stringForNumber: @(frame.size.width)]];
	[html appendString: @"pt; height:"];
	[html appendString: [MADReportExportSource stringForNumber: @(frame.size.height)]];
	[html appendString: @"pt"];
	[self appendStyle: line.style toHTML: html];
	[html appendString: @"\">"];

	NSString *text = [line text];
	if (text != nil) {
		[html appendString: [MADReportExporterHTML escapedString: text]];
	}
	[html appendString: @"</div>\n"];
}

// The element's styling, the same five facts MADElementStylizedText turns into
// drawing attributes: the font, its size, bold, italic, underline/strikethrough and
// the horizontal alignment.
- (void)appendStyle:(MADReportLineStyle *)style toHTML:(NSMutableString *)html {

	if (style == nil) return;
	if (style.fontName.length > 0) {
		[html appendString: @"; font-family:"];
		[html appendString: MADReportExporterFontName(style.fontName)];
		[html appendString: @", sans-serif"];
	}
	if (style.fontSize > 0.0) {
		[html appendString: @"; font-size:"];
		[html appendString: [MADReportExportSource stringForNumber: @(style.fontSize)]];
		[html appendString: @"pt"];
	}
	if (style.bold) [html appendString: @"; font-weight:bold"];
	if (style.italic) [html appendString: @"; font-style:italic"];

	NSString *decoration = nil;
	if (style.underline && style.strikethrough) decoration = @"underline line-through";
	else if (style.underline) decoration = @"underline";
	else if (style.strikethrough) decoration = @"line-through";
	if (decoration != nil) {
		[html appendString: @"; text-decoration:"];
		[html appendString: decoration];
	}

	NSString *alignment = MADReportExporterCSSAlignment(style.horizontalAlignment);
	if (alignment != nil) {
		[html appendString: @"; text-align:"];
		[html appendString: alignment];
	}
}

// The @page rule takes a bare pair of lengths -- `size: 612pt 792pt` -- where the
// page box takes the two properties.
- (void)appendPageSize:(CGSize)size toHTML:(NSMutableString *)html {
	[html appendString: [MADReportExportSource stringForNumber: @(size.width)]];
	[html appendString: @"pt "];
	[html appendString: [MADReportExportSource stringForNumber: @(size.height)]];
	[html appendString: @"pt"];
}

- (void)appendSize:(CGSize)size toHTML:(NSMutableString *)html {
	[html appendString: @"width:"];
	[html appendString: [MADReportExportSource stringForNumber: @(size.width)]];
	[html appendString: @"pt; height:"];
	[html appendString: [MADReportExportSource stringForNumber: @(size.height)]];
	[html appendString: @"pt"];
}

#pragma mark - HTML spelling

// The runtime's stable element-type spelling wants its prefix off, the way the JSON
/// member's tokens do (MADReportExporterJSONReport).
static NSString *MADReportExporterHTMLTypeToken(NSString *name, NSString *prefix) {
	if ([name hasPrefix: prefix]) {
		return [name substringFromIndex: prefix.length];
	}
	return name;
}

// The element's alignment as CSS; nil where the renderer would leave it alone
/// (MADElementStylizedText maps the unknown case to left, which is CSS's own default).
static NSString *MADReportExporterCSSAlignment(MADHorizontalAlignment alignment) {
	switch (alignment) {
		case MADHorizontalAlignmentLeft:		return @"left";
		case MADHorizontalAlignmentRight:		return @"right";
		case MADHorizontalAlignmentCenter:		return @"center";
		case MADHorizontalAlignmentJustified:	return @"justify";
		case MADHorizontalAlignmentNatrual:		return @"start";
		default:								return nil;
	}
}

// A font name for CSS: quoted, because families are names with spaces in them, and
/// with the quote and backslash characters escaped so a name cannot end the string.
static NSString *MADReportExporterFontName(NSString *name) {
	NSMutableString *quoted = [[NSMutableString alloc] initWithCapacity: name.length + 2];
	[quoted appendString: @"'"];
	NSUInteger index = 0;
	while (index < name.length) {
		unichar character = [name characterAtIndex: index];
		if (character == '\'' || character == '\\') [quoted appendString: @"\\"];
		[quoted appendFormat: @"%C", character];
		index++;
	}
	[quoted appendString: @"'"];
	return quoted;
}

// Text as HTML: the five characters that change how a document parses, and nothing
/// else -- the file is UTF-8 and a reader that takes UTF-8 reads the rest back.
+ (NSString *)escapedString:(NSString *)string {
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
