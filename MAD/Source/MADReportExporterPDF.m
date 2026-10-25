//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterPDF.m
//  MAD
//
//  See MADReportExporterPDF.h.  The drawing sequence is MADCLIDocument's, moved here
//  unchanged so the bytes stay the bytes; the metadata pinning is MADCLIPinPDFMetadata's,
//  moved with it.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterPDF.h"

#import "MADReportExporterRegistry.h"
#import "MADReportFormatter.h"
#import "MADReportPageBuilder.h"

#import <MAD/MADDocumentRenderProtocol.h>

#import <Foundation/NSData.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>

#if __APPLE__

#import "MADPrintPageRenderer.h"

#import <UIKit/UIGraphics.h>
#import <UIKit/UIGeometry.h>

#pragma mark - Deterministic PDF metadata

static NSUInteger MADReportExporterFindBytes(const uint8_t *bytes, NSUInteger length, NSUInteger from, const char *needle) {
	NSUInteger needleLength = strlen(needle);
	if (needleLength == 0 || length < needleLength) return NSNotFound;
	for (NSUInteger i = from; i + needleLength <= length; i++) {
		if (memcmp(bytes + i, needle, needleLength) == 0) return i;
	}
	return NSNotFound;
}

static NSUInteger MADReportExporterFindBytesLast(const uint8_t *bytes, NSUInteger length, const char *needle) {
	NSUInteger needleLength = strlen(needle);
	if (needleLength == 0 || length < needleLength) return NSNotFound;
	for (NSUInteger i = length - needleLength + 1; i-- > 0; ) {
		if (memcmp(bytes + i, needle, needleLength) == 0) return i;
	}
	return NSNotFound;
}

static NSUInteger MADReportExporterSkipToByte(const uint8_t *bytes, NSUInteger length, NSUInteger from, uint8_t byte) {
	for (NSUInteger i = from; i < length; i++) {
		if (bytes[i] == byte) return i;
	}
	return NSNotFound;
}

/// Core Graphics takes /CreationDate and /ModDate from the clock and derives the
/// trailer /ID from them, so two exports of a report that has not changed differ in a
/// handful of bytes at the end and nowhere else.  That is exactly enough to defeat the
/// byte-for-byte comparison a report format wants, so the deterministic mode pins all
/// three to constants.
static void MADReportExporterPinPDFMetadata(NSURL *url) {

	NSMutableData *data = [NSMutableData dataWithContentsOfURL: url];
	if (data == nil) return;

	uint8_t *bytes = data.mutableBytes;
	NSUInteger length = data.length;

	// A PDF does not require a key and its value to share a line, and Core Graphics
	// does not put them on one: it writes "/CreationDate" and leaves the string for
	// the next line.  So find the key, then the value, rather than one literal.
	static const char *dateKeys[] = { "/CreationDate", "/ModDate" };
	static const char *pinned  = "20010112000000";		// 2001-01-12 00:00:00, the PDF epoch
	for (NSUInteger key = 0; key < 2; key++) {
		NSUInteger at = MADReportExporterFindBytesLast(bytes, length, dateKeys[key]);
		if (at == NSNotFound) continue;
		NSUInteger string = MADReportExporterFindBytes(bytes, length, at, "(D:");
		if (string == NSNotFound) continue;
		NSUInteger digits = string + strlen("(D:");
		if (digits + strlen(pinned) > length) continue;
		// Only a full date is replaced; a partial one would change the file's length.
		BOOL full = YES;
		for (NSUInteger i = 0; i < strlen(pinned); i++) {
			if (!isdigit(bytes[digits + i])) { full = NO; break; }
		}
		if (full) memcpy(bytes + digits, pinned, strlen(pinned));
	}

	NSUInteger identifier = MADReportExporterFindBytesLast(bytes, length, "/ID");
	NSUInteger bracket = identifier == NSNotFound ? NSNotFound : MADReportExporterSkipToByte(bytes, length, identifier, '[');
	if (bracket != NSNotFound) {
		static const char *alphabet = "0123456789abcdef";
		NSUInteger cursor = bracket;
		for (NSUInteger string = 0; string < 2; string++) {
			NSUInteger open = MADReportExporterSkipToByte(bytes, length, cursor, '<');
			if (open == NSNotFound) break;
			NSUInteger close = MADReportExporterSkipToByte(bytes, length, open + 1, '>');
			if (close == NSNotFound) break;
			for (NSUInteger i = open + 1; i < close; i++) {
				bytes[i] = (uint8_t)alphabet[(i - open - 1) % 16];
			}
			cursor = close + 1;
		}
	}

	[data writeToURL: url atomically: YES];
}

#endif

@implementation MADReportExporterPDF

+ (void)load {
	[MADReportExporterRegistry registerExporterClass: self];
}

+ (NSString *)formatName {
	return @"pdf";
}

+ (NSString *)formatDescription {
	return @"the rendered report, drawn";
}

+ (NSString *)fileExtension {
	return @"pdf";
}

+ (BOOL)requiresOutputPath {
	return YES;
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
	return @"PDF is a Core Graphics context drawn by a UIPrintPageRenderer, neither of which exists "
			"off Apple.  The report's pages are the same everywhere -- --format html prints them from "
			"a browser, and a Linux PDF writer is the next step (docs/project/MAD_LINUX.md §10.2).";
#endif
}

- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError * _Nullable __autoreleasing *)error {

#if !__APPLE__
	if (error) {
		*error = [NSError errorWithDomain: @"MADReportExport"
									 code: 3
								 userInfo: @{ NSLocalizedDescriptionKey: [MADReportExporterPDF unavailableReason] }];
	}
	return NO;
#else

	if (![document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 3
									 userInfo: @{ NSLocalizedDescriptionKey:
					 @"PDF needs a document that renders (MADDocumentRenderProtocol)." }];
		}
		return NO;
	}
	if (url == nil) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 4
									 userInfo: @{ NSLocalizedDescriptionKey: @"PDF needs a file to write to." }];
		}
		return NO;
	}

	id <MADDocumentRenderProtocol> renderDocument = (id <MADDocumentRenderProtocol>)document;

	// The reload the viewer runs after a refresh, then the page's letter-and-1pt-trim
	// geometry: the same preparation the other render-side formats run.
	[MADReportPageBuilder prepareDocumentForRender: renderDocument];
	MADReportFormatter *reportFormatter = renderDocument.reportFormatter;

	CGRect letterRect = [MADReportPageBuilder pageBounds];
	CGRect trimBox = [MADReportPageBuilder pageTrimBox];

	NSDictionary *pdfOptions = @{ (__bridge NSString *)kCGPDFContextCreator: @"MAD® Designer" };
	NSDictionary *boxInfo = @{ (__bridge NSString *)kCGPDFContextTrimBox: [NSValue valueWithCGRect: trimBox] };

	// The renderer draws from the document's own formatter -- not from a second one
	// built alongside it -- so the document's is the one the preparation formatted.
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource: renderDocument];

	UIGraphicsBeginPDFContextToFile(url.path, letterRect, pdfOptions);
	for (NSUInteger page = 0; page < reportFormatter.numberOfPages; page++) {
		@autoreleasepool {
			UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
			[renderer drawPageAtIndex: (NSInteger)page inRect: trimBox];
		}
	}
	UIGraphicsEndPDFContext();

	if (options & MADReportExportOptionsDeterministic) {
		MADReportExporterPinPDFMetadata(url);
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath: url.path]) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 5
									 userInfo: @{ NSLocalizedDescriptionKey: @"No PDF was written." }];
		}
		return NO;
	}

	return YES;
#endif
}

@end
