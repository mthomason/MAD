//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADPDFExportTests.m
//  Linux/Tests
//
//  The headless PDF writer end to end (docs/project/MAD_PDF_LINUX.md): a document
//  is opened (its own process -- opening the London fixture twice in one process
//  conflicts, see MADReportExporterTests), refreshed, given a barcode and a
//  picture, and exported.  The PDF is read back with the small reader below and
//  compared with the json-report for the same document, which is the oracle:
//
//    * the same page count, and every page the same US Letter MediaBox;
//    * every walked line's frame inside the 1pt trim;
//    * every text line's text, in the walk's order, page by page;
//    * the barcode and the picture as image XObjects, not text;
//    * the deterministic mode byte-identical across two runs.
//
//  The reader is PDF 1.4 only -- MADReportExporterPDFCairo restricts its surface
//  to 1.4 on purpose, so the page tree, the fonts and the content streams are
//  plain objects rather than object streams.
//

#import "MADTestSupport.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADOperationRefreshInitialize.h>
#import <MAD/MADOperationRefreshInitalizeMainDataTable.h>
#import <MAD/MADReportExporterJSONReport.h>
#import <MAD/MADReportExporterPDF.h>
#import <MAD/MADReportExporterRegistry.h>
#import <MAD/MADReportExporting.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqStoreContext.h>

#import <MADBarcodes/MADBarcodeType.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>

#include <ctype.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#pragma mark - The document

static NSString *MADPDFExportRepositoryRoot(void) {
	NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
#if defined(_WIN32)
	directory = [directory stringByDeletingLastPathComponent];	// Engine
#endif
	directory = [directory stringByDeletingLastPathComponent];		// Linux / Windows
	return [directory stringByDeletingLastPathComponent];			// the root
}

static NSString *MADPDFExportFixturePath(void) {
	return [[MADPDFExportRepositoryRoot() stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADPDFExportSampleDatabasePath(void) {
	return [[MADPDFExportRepositoryRoot() stringByAppendingPathComponent:
			 @"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset"]
			stringByAppendingPathComponent: @"chinook.sqlite3"];
}

// A real 1x1 transparent PNG -- the wire format the image column carries.
static NSData *MADPDFExportOnePixelPNG(void) {
	static NSData *data = nil;
	if (data == nil) {
		data = [[NSData alloc] initWithBase64EncodedString:
				@"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
												   options: 0];
	}
	return data;
}

static void MADPDFExportInstallSampleDatabase(void) {
	NSString *samplePath = MADPDFExportSampleDatabasePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: samplePath]) return;

	NSURL *supportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]];
	NSURL *target = [supportDirectory URLByAppendingPathComponent: @"chinook.sqlite3"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtURL: supportDirectory withIntermediateDirectories: YES attributes: nil error: NULL];
	[fileManager removeItemAtURL: target error: NULL];
	[fileManager copyItemAtURL: [NSURL fileURLWithPath: samplePath] toURL: target error: NULL];
}

/// The refresh chain the app runs, synchronously, as MADReportExporterTests does.
static BOOL MADPDFExportRefresh(MADHeadlessDocument *document) {
	MADOperationRefreshInitializeMainDataTable *initializeTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument: document];
	MADOperationRefreshInitialize *initialize = [[MADOperationRefreshInitialize alloc] initWithDocument: document];
	[initialize addDependency: initializeTable];
	MADOperationRefresh *refresh = [[MADOperationRefresh alloc] initWithDocument: document];
	[refresh addDependency: initializeTable];
	[refresh addDependency: initialize];

	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: initializeTable];
	[queue addOperation: initialize];
	[queue addOperation: refresh];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 60];
	while (queue.operationCount > 0 && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
								 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.02]];
	}
	return queue.operationCount == 0 && refresh.errors.count == 0;
}

/// A copied fixture, refreshed, with one barcode and one picture in its detail
/// section.  One document per process: the exporter tests' rule.
static MADHeadlessDocument *MADPDFExportDocument(void) {
	static MADHeadlessDocument *document = nil;
	static BOOL prepared = NO;
	if (prepared) return document;
	prepared = YES;

	NSString *fixture = MADPDFExportFixturePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: fixture]) return nil;

	MADPDFExportInstallSampleDatabase();
	NSString *copy = [NSTemporaryDirectory() stringByAppendingPathComponent:
					  [[NSUUID UUID].UUIDString stringByAppendingPathExtension: @"mad"]];
	[[NSFileManager defaultManager] copyItemAtPath: fixture toPath: copy error: NULL];

	document = [[MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: copy]
														 error: NULL] retain];
	if (document == nil || !MADPDFExportRefresh(document)) return nil;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqDocumentSection *detail = model.hasDetailSection;
	if (detail == nil) return nil;

	RptqDocumentElementBarcode *barcode = (RptqDocumentElementBarcode *)[context insertObjectForEntity:
																		 NSStringFromClass([RptqDocumentElementBarcode class])
																		 identifier: 0];
	barcode.type = MADPrintPageElementTypeBarcode;
	barcode.barcodeType = (int16_t)MADBarcodeTypeCODE128;
	barcode.humanReadable = YES;
	barcode.useStaticInput1 = YES;
	barcode.inputStatic1 = @"UK-CUST";
	barcode.barcodeHeight = 40;
	[barcode setSizeWidth: 160.0f height: 48.0f];
	[detail addDocumentObject: barcode withDropPoint: CGPointMake(300.0, 6.0) managedObjectContext: context];

	RptqDocumentElementImage *image = (RptqDocumentElementImage *)[context insertObjectForEntity:
																   NSStringFromClass([RptqDocumentElementImage class])
																						 identifier: 0];
	image.type = MADPrintPageElementTypeImage;
	image.image = MADPDFExportOnePixelPNG();
	[image setSizeWidth: 96.0f height: 64.0f];
	[detail addDocumentObject: image withDropPoint: CGPointMake(320.0, 6.0) managedObjectContext: context];

	return document;
}

/// One export of the fixture, or nil.
static NSData *MADPDFExportData(NSString *format, MADReportExportOptions options, NSString *name) {
	MADHeadlessDocument *document = MADPDFExportDocument();
	if (document == nil) return nil;

	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: format];
	if (exporterClass == Nil) return nil;

	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];

	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	BOOL ok = [exporter exportDocument: document toURL: url options: options error: &error];
	[exporter release];
	if (!ok) {
		MAD_PASS(NO, "the %s export failed: %s", [format UTF8String],
				 error != nil ? [[error description] UTF8String] : "no error given");
		return nil;
	}
	return [NSData dataWithContentsOfURL: url];
}

#pragma mark - A small PDF 1.4 reader

typedef struct {
	const uint8_t *bytes;
	NSUInteger length;
	NSUInteger position;
} MADPDFCursor;

static BOOL MADPDFWhitespace(uint8_t c) {
	return c == 0x00 || c == 0x09 || c == 0x0A || c == 0x0C || c == 0x0D || c == 0x20;
}

static BOOL MADPDFDelimiter(uint8_t c) {
	return MADPDFWhitespace(c) || c == '(' || c == ')' || c == '<' || c == '>' ||
		   c == '[' || c == ']' || c == '{' || c == '}' || c == '/' || c == '%';
}

static void MADPDFSkipSpace(MADPDFCursor *cursor) {
	while (cursor->position < cursor->length) {
		uint8_t c = cursor->bytes[cursor->position];
		if (MADPDFWhitespace(c)) {
			cursor->position++;
		} else if (c == '%') {
			while (cursor->position < cursor->length && cursor->bytes[cursor->position] != '\n') cursor->position++;
		} else {
			break;
		}
	}
}

static BOOL MADPDFMatchLiteral(MADPDFCursor *cursor, const char *literal) {
	NSUInteger length = strlen(literal);
	if (cursor->position + length > cursor->length) return NO;
	if (memcmp(cursor->bytes + cursor->position, literal, length) != 0) return NO;
	cursor->position += length;
	return YES;
}

static BOOL MADPDFReadNumber(MADPDFCursor *cursor, double *value) {
	MADPDFSkipSpace(cursor);
	NSUInteger start = cursor->position;
	if (start < cursor->length && (cursor->bytes[start] == '-' || cursor->bytes[start] == '+')) cursor->position++;
	BOOL digit = NO;
	while (cursor->position < cursor->length && isdigit(cursor->bytes[cursor->position])) {
		cursor->position++;
		digit = YES;
	}
	if (cursor->position < cursor->length && cursor->bytes[cursor->position] == '.') {
		cursor->position++;
		while (cursor->position < cursor->length && isdigit(cursor->bytes[cursor->position])) cursor->position++;
	}
	if (!digit) { cursor->position = start; return NO; }
	char buffer[64];
	NSUInteger count = cursor->position - start;
	if (count >= sizeof(buffer)) count = sizeof(buffer) - 1;
	memcpy(buffer, cursor->bytes + start, count);
	buffer[count] = '\0';
	*value = strtod(buffer, NULL);
	return YES;
}

static BOOL MADPDFReadName(MADPDFCursor *cursor, NSMutableString *name) {
	MADPDFSkipSpace(cursor);
	if (cursor->position >= cursor->length || cursor->bytes[cursor->position] != '/') return NO;
	cursor->position++;
	NSUInteger start = cursor->position;
	while (cursor->position < cursor->length && !MADPDFDelimiter(cursor->bytes[cursor->position])) cursor->position++;
	NSString *text = [[NSString alloc] initWithBytes: cursor->bytes + start
											  length: cursor->position - start
											encoding: NSISOLatin1StringEncoding];
	[name setString: text];
	[text release];
	return YES;
}

// A literal string's bytes with the escapes resolved, or a hex string decoded.
static NSData *MADPDFReadString(MADPDFCursor *cursor) {
	MADPDFSkipSpace(cursor);
	if (cursor->position >= cursor->length) return nil;

	NSMutableData *out = [NSMutableData data];
	if (cursor->bytes[cursor->position] == '(') {
		cursor->position++;
		int depth = 1;
		while (cursor->position < cursor->length && depth > 0) {
			uint8_t c = cursor->bytes[cursor->position++];
			if (c == '\\' && cursor->position < cursor->length) {
				uint8_t escaped = cursor->bytes[cursor->position++];
				switch (escaped) {
					case 'n': [out appendBytes: "\n" length: 1]; break;
					case 'r': [out appendBytes: "\r" length: 1]; break;
					case 't': [out appendBytes: "\t" length: 1]; break;
					case 'b': [out appendBytes: "\b" length: 1]; break;
					case 'f': [out appendBytes: "\f" length: 1]; break;
					case '\n': break;
					case '\r':
						if (cursor->position < cursor->length && cursor->bytes[cursor->position] == '\n') cursor->position++;
						break;
					default:
						if (escaped >= '0' && escaped <= '7') {
							int value = escaped - '0';
							for (int digit = 0; digit < 2 && cursor->position < cursor->length; digit++) {
								uint8_t next = cursor->bytes[cursor->position];
								if (next < '0' || next > '7') break;
								value = value * 8 + (next - '0');
								cursor->position++;
							}
							uint8_t byte = (uint8_t)value;
							[out appendBytes: &byte length: 1];
						} else {
							[out appendBytes: &escaped length: 1];
						}
						break;
				}
			} else if (c == '(') {
				depth++;
				[out appendBytes: &c length: 1];
			} else if (c == ')') {
				depth--;
				if (depth > 0) [out appendBytes: &c length: 1];
			} else {
				[out appendBytes: &c length: 1];
			}
		}
		return out;
	}

	if (cursor->bytes[cursor->position] == '<') {
		cursor->position++;
		int high = -1;
		while (cursor->position < cursor->length && cursor->bytes[cursor->position] != '>') {
			uint8_t c = cursor->bytes[cursor->position++];
			int value;
			if (c >= '0' && c <= '9') value = c - '0';
			else if (c >= 'a' && c <= 'f') value = c - 'a' + 10;
			else if (c >= 'A' && c <= 'F') value = c - 'A' + 10;
			else continue;
			if (high < 0) {
				high = value;
			} else {
				uint8_t byte = (uint8_t)((high << 4) | value);
				[out appendBytes: &byte length: 1];
				high = -1;
			}
		}
		if (cursor->position < cursor->length) cursor->position++;
		if (high >= 0) {
			uint8_t byte = (uint8_t)(high << 4);
			[out appendBytes: &byte length: 1];
		}
		return out;
	}
	return nil;
}

// The body of "N 0 obj" ... "endobj": the range after "obj" up to the newline
// before "endobj".  A stream's compressed bytes can contain "endobj", so only
// stream dictionaries are read from this range (the data is taken by /Length).
static BOOL MADPDFFindObject(NSData *pdf, NSUInteger number, NSRange *body) {
	const uint8_t *bytes = pdf.bytes;
	NSUInteger length = pdf.length;

	for (NSUInteger index = 0; index < length; index++) {
		BOOL lineStart = (index == 0) || bytes[index - 1] == '\n';
		if (!lineStart) continue;

		MADPDFCursor cursor = { bytes, length, index };
		double parsed = 0;
		if (!MADPDFReadNumber(&cursor, &parsed) || parsed != (double)number) continue;
		if (!MADPDFMatchLiteral(&cursor, " 0 obj")) continue;

		NSUInteger start = cursor.position;
		while (start < length && (bytes[start] == '\r' || bytes[start] == '\n' || bytes[start] == ' ')) start++;
		NSUInteger end = start;
		while (end + 6 <= length) {
			if (bytes[end] == '\n' && memcmp(bytes + end + 1, "endobj", 6) == 0) break;
			end++;
		}
		if (end + 6 > length) continue;
		body->location = start;
		body->length = end - start;
		return YES;
	}
	return NO;
}

static NSData *MADPDFInflate(NSData *input) {
	z_stream stream;
	memset(&stream, 0, sizeof(stream));
	if (inflateInit(&stream) != Z_OK) return nil;

	NSMutableData *output = [NSMutableData data];
	uint8_t buffer[65536];
	stream.next_in = (Bytef *)input.bytes;
	stream.avail_in = (uInt)input.length;

	int status = Z_OK;
	while (status == Z_OK) {
		stream.next_out = buffer;
		stream.avail_out = (uInt)sizeof(buffer);
		status = inflate(&stream, Z_NO_FLUSH);
		if (status != Z_OK && status != Z_STREAM_END) break;
		[output appendBytes: buffer length: sizeof(buffer) - stream.avail_out];
	}
	inflateEnd(&stream);
	return status == Z_STREAM_END ? output : nil;
}

// The stream data of an object: /Length resolved (direct or indirect) and
// FlateDecode decompressed.
static NSData *MADPDFStreamData(NSData *pdf, NSUInteger number) {
	NSRange body;
	if (!MADPDFFindObject(pdf, number, &body)) return nil;

	const uint8_t *bytes = pdf.bytes;
	NSUInteger length = pdf.length;
	NSUInteger streamKeyword = NSNotFound;
	for (NSUInteger index = body.location; index + 6 <= body.location + body.length; index++) {
		if (memcmp(bytes + index, "stream", 6) == 0) { streamKeyword = index; break; }
	}
	if (streamKeyword == NSNotFound) return nil;

	NSString *dictionary = [[NSString alloc] initWithBytes: bytes + body.location
													length: streamKeyword - body.location
												  encoding: NSISOLatin1StringEncoding];
	NSUInteger dataLength = 0;
	NSRange lengthKey = [dictionary rangeOfString: @"/Length"];
	if (lengthKey.location != NSNotFound) {
		MADPDFCursor cursor = { bytes, length, body.location + lengthKey.location + lengthKey.length };
		double value = 0;
		if (MADPDFReadNumber(&cursor, &value)) {
			dataLength = (NSUInteger)value;
			MADPDFSkipSpace(&cursor);
			double zero = 0;
			if (cursor.position < length && bytes[cursor.position] == '0' &&
				MADPDFReadNumber(&cursor, &zero)) {
				MADPDFSkipSpace(&cursor);
				if (cursor.position < length && bytes[cursor.position] == 'R') {
					NSRange lengthBody;
					if (MADPDFFindObject(pdf, dataLength, &lengthBody)) {
						MADPDFCursor numberCursor = { bytes, lengthBody.location + lengthBody.length, lengthBody.location };
						double resolved = 0;
						if (MADPDFReadNumber(&numberCursor, &resolved)) dataLength = (NSUInteger)resolved;
					}
				}
			}
		}
	}
	BOOL compressed = [dictionary rangeOfString: @"FlateDecode"].location != NSNotFound;
	[dictionary release];

	NSUInteger dataStart = streamKeyword + 6;
	if (dataStart < length && bytes[dataStart] == '\r') dataStart++;
	if (dataStart < length && bytes[dataStart] == '\n') dataStart++;
	if (dataStart + dataLength > length) dataLength = length - dataStart;

	NSData *raw = [pdf subdataWithRange: NSMakeRange(dataStart, dataLength)];
	return compressed ? MADPDFInflate(raw) : raw;
}

// The indirect object a key names: "/Contents" then "N 0 R" gives N.
static NSUInteger MADPDFReferenceAfter(NSData *pdf, NSString *key, NSUInteger from, NSUInteger to) {
	const uint8_t *bytes = pdf.bytes;
	NSString *text = [[NSString alloc] initWithBytes: bytes + from length: to - from encoding: NSISOLatin1StringEncoding];
	NSRange search = [text rangeOfString: key];
	[text release];
	if (search.location == NSNotFound) return NSNotFound;

	MADPDFCursor cursor = { bytes, pdf.length, from + search.location + search.length };
	double number = 0;
	if (!MADPDFReadNumber(&cursor, &number)) return NSNotFound;
	MADPDFSkipSpace(&cursor);
	if (cursor.position < pdf.length && bytes[cursor.position] == '0') {
		cursor.position++;
		MADPDFSkipSpace(&cursor);
		if (cursor.position < pdf.length && bytes[cursor.position] == 'R') return (NSUInteger)number;
	}
	return NSNotFound;
}

#pragma mark - Fonts

// One font's ToUnicode map: the character code's width and its mapping.
static NSDictionary *MADPDFToUnicodeMap(NSData *cmap, NSUInteger *codeBytes) {
	NSMutableDictionary *map = [NSMutableDictionary dictionary];
	*codeBytes = 1;

	NSString *text = [[NSString alloc] initWithData: cmap encoding: NSISOLatin1StringEncoding];
	if (text == nil) return map;

	NSRange space = [text rangeOfString: @"begincodespacerange"];
	if (space.location != NSNotFound) {
		NSRange first = [text rangeOfString: @"<" options: 0 range: NSMakeRange(space.location, text.length - space.location)];
		if (first.location != NSNotFound) {
			NSRange close = [text rangeOfString: @">" options: 0 range: NSMakeRange(first.location, text.length - first.location)];
			if (close.location != NSNotFound) {
				NSUInteger digits = close.location - first.location - 1;
				*codeBytes = digits / 2;
				if (*codeBytes == 0) *codeBytes = 1;
			}
		}
	}

	NSUInteger position = 0;
	while (position < text.length) {
		NSRange begin = [text rangeOfString: @"beginbfchar" options: 0 range: NSMakeRange(position, text.length - position)];
		if (begin.location == NSNotFound) break;
		NSRange end = [text rangeOfString: @"endbfchar" options: 0 range: NSMakeRange(begin.location, text.length - begin.location)];
		if (end.location == NSNotFound) break;

		NSUInteger cursor = begin.location + begin.length;
		while (cursor < end.location) {
			NSRange source = [text rangeOfString: @"<" options: 0 range: NSMakeRange(cursor, text.length - cursor)];
			if (source.location == NSNotFound || source.location >= end.location) break;
			NSRange sourceEnd = [text rangeOfString: @">" options: 0 range: NSMakeRange(source.location, text.length - source.location)];
			if (sourceEnd.location == NSNotFound) break;
			unsigned int sourceValue = 0;
			[[NSScanner scannerWithString: [text substringWithRange:
										   NSMakeRange(source.location + 1, sourceEnd.location - source.location - 1)]]
			 scanHexInt: &sourceValue];

			NSRange destination = [text rangeOfString: @"<" options: 0 range: NSMakeRange(sourceEnd.location, text.length - sourceEnd.location)];
			if (destination.location == NSNotFound || destination.location >= end.location) break;
			NSRange destinationEnd = [text rangeOfString: @">" options: 0 range: NSMakeRange(destination.location, text.length - destination.location)];
			if (destinationEnd.location == NSNotFound) break;
			NSString *destinationHex = [text substringWithRange:
										NSMakeRange(destination.location + 1, destinationEnd.location - destination.location - 1)];

			NSMutableData *destinationBytes = [NSMutableData data];
			for (NSUInteger index = 0; index + 4 <= destinationHex.length; index += 4) {
				unsigned int unit = 0;
				[[NSScanner scannerWithString: [destinationHex substringWithRange: NSMakeRange(index, 4)]] scanHexInt: &unit];
				uint8_t bytes[2] = { (uint8_t)(unit >> 8), (uint8_t)(unit & 0xFF) };
				[destinationBytes appendBytes: bytes length: 2];
			}
			NSString *unicode = [[NSString alloc] initWithData: destinationBytes
													  encoding: NSUTF16BigEndianStringEncoding];
			if (unicode != nil) {
				map[@(sourceValue)] = unicode;
				[unicode release];
			}
			cursor = destinationEnd.location + 1;
		}
		position = end.location + end.length;
	}
	[text release];
	return map;
}

static NSString *MADPDFDecodeString(NSData *bytes, NSDictionary *map, NSUInteger codeBytes) {
	const uint8_t *raw = bytes.bytes;
	NSUInteger length = bytes.length;
	NSMutableString *text = [NSMutableString string];
	if (codeBytes == 0) codeBytes = 1;
	for (NSUInteger index = 0; index + codeBytes <= length; index += codeBytes) {
		NSUInteger code = 0;
		for (NSUInteger byte = 0; byte < codeBytes; byte++) code = (code << 8) | raw[index + byte];
		NSString *mapped = map[@(code)];
		if (mapped != nil) [text appendString: mapped];
	}
	return text;
}

#pragma mark - The content stream

// The text-showing runs of one content stream, in order, decoded through the
// page's font maps, with each run's text-matrix origin.  Cairo emits one string
// per cairo_show_glyphs call, so a run is a walked line.
static NSArray *MADPDFTextRuns(NSData *content, NSDictionary *fontMaps, NSDictionary *fontCodeBytes) {
	NSMutableArray *runs = [NSMutableArray array];
	NSMutableArray *operands = [NSMutableArray array];
	NSString *currentFont = nil;
	double matrix[6] = { 1, 0, 0, 1, 0, 0 };

	MADPDFCursor cursor = { content.bytes, content.length, 0 };
	while (cursor.position < cursor.length) {
		MADPDFSkipSpace(&cursor);
		if (cursor.position >= cursor.length) break;
		uint8_t c = cursor.bytes[cursor.position];

		if (c == '(' || c == '<') {
			if (c == '<' && cursor.position + 1 < cursor.length && cursor.bytes[cursor.position + 1] == '<') {
				cursor.position += 2;
				continue;
			}
			NSData *string = MADPDFReadString(&cursor);
			if (string != nil) [operands addObject: string];
			continue;
		}
		if (c == '[') {
			cursor.position++;
			NSMutableArray *array = [NSMutableArray array];
			while (cursor.position < cursor.length) {
				MADPDFSkipSpace(&cursor);
				if (cursor.position >= cursor.length) break;
				uint8_t item = cursor.bytes[cursor.position];
				if (item == ']') { cursor.position++; break; }
				if (item == '(' || item == '<') {
					NSData *string = MADPDFReadString(&cursor);
					if (string != nil) [array addObject: string];
				} else if (item == '/') {
					NSMutableString *name = [NSMutableString string];
					MADPDFReadName(&cursor, name);
					[array addObject: name];
				} else if (item == '[') {
					cursor.position++;
				} else {
					double number = 0;
					if (MADPDFReadNumber(&cursor, &number)) [array addObject: @(number)];
					else cursor.position++;
				}
			}
			[operands addObject: array];
			continue;
		}
		if (c == ']' || c == ')' || c == '>' || c == '{' || c == '}') {
			cursor.position++;
			continue;
		}
		if (c == '/') {
			NSMutableString *name = [NSMutableString string];
			MADPDFReadName(&cursor, name);
			[operands addObject: name];
			continue;
		}

		NSUInteger start = cursor.position;
		while (cursor.position < cursor.length && !MADPDFDelimiter(cursor.bytes[cursor.position])) cursor.position++;
		if (cursor.position == start) { cursor.position++; continue; }

		NSString *token = [[NSString alloc] initWithBytes: cursor.bytes + start
												   length: cursor.position - start
												 encoding: NSISOLatin1StringEncoding];
		unichar first = token.length > 0 ? [token characterAtIndex: 0] : 0;
		if (first == '-' || first == '+' || first == '.' || isdigit((int)first)) {
			NSScanner *scanner = [NSScanner scannerWithString: token];
			double number = 0;
			if ([scanner scanDouble: &number] && scanner.isAtEnd) {
				[operands addObject: @(number)];
				[token release];
				continue;
			}
		}

		if ([token isEqualToString: @"BT"]) {
			double identity[6] = { 1, 0, 0, 1, 0, 0 };
			memcpy(matrix, identity, sizeof(matrix));
		} else if ([token isEqualToString: @"Tm"] && operands.count >= 6) {
			for (NSUInteger index = 0; index < 6; index++) {
				matrix[index] = [operands[operands.count - 6 + index] doubleValue];
			}
		} else if (([token isEqualToString: @"Td"] || [token isEqualToString: @"TD"]) && operands.count >= 2) {
			double tx = [operands[operands.count - 2] doubleValue];
			double ty = [operands[operands.count - 1] doubleValue];
			matrix[4] += matrix[0] * tx + matrix[2] * ty;
			matrix[5] += matrix[1] * tx + matrix[3] * ty;
		} else if ([token isEqualToString: @"Tf"] && operands.count >= 2) {
			id name = operands[operands.count - 2];
			if ([name isKindOfClass: [NSString class]]) {
				[currentFont release];
				currentFont = [name copy];
			}
		} else if ([token isEqualToString: @"Tj"] && operands.count >= 1) {
			id string = operands.lastObject;
			if ([string isKindOfClass: [NSData class]]) {
				NSString *text = MADPDFDecodeString(string, fontMaps[currentFont] ?: @{},
													[fontCodeBytes[currentFont] unsignedIntegerValue]);
				[runs addObject: @{ @"text": text, @"x": @(matrix[4]), @"y": @(matrix[5]) }];
			}
		} else if ([token isEqualToString: @"TJ"] && operands.count >= 1) {
			id array = operands.lastObject;
			if ([array isKindOfClass: [NSArray class]]) {
				NSMutableString *text = [NSMutableString string];
				NSDictionary *map = fontMaps[currentFont] ?: @{};
				NSUInteger codeBytes = [fontCodeBytes[currentFont] unsignedIntegerValue];
				for (id item in array) {
					if ([item isKindOfClass: [NSData class]]) {
						[text appendString: MADPDFDecodeString(item, map, codeBytes)];
					}
				}
				[runs addObject: @{ @"text": text, @"x": @(matrix[4]), @"y": @(matrix[5]) }];
			}
		}
		[token release];
		[operands removeAllObjects];
	}
	[currentFont release];
	return runs;
}

#pragma mark - Pages

// A page: its MediaBox as four numbers and its text runs.
static NSArray *MADPDFPages(NSData *pdf) {
	const uint8_t *bytes = pdf.bytes;
	NSUInteger length = pdf.length;
	NSMutableArray *pages = [NSMutableArray array];

	static const char *objectMarker = " 0 obj";
	static const char *pagePrefix = "<< /Type /Page ";
	NSUInteger scan = 0;
	while (scan + strlen(objectMarker) <= length) {
		if (memcmp(bytes + scan, objectMarker, strlen(objectMarker)) != 0) {
			scan++;
			continue;
		}

		// The object number is the token before " 0 obj" on this line.
		NSUInteger lineStart = scan;
		while (lineStart > 0 && bytes[lineStart - 1] != '\n') lineStart--;
		MADPDFCursor numberCursor = { bytes, length, lineStart };
		double objectNumber = 0;
		if (!MADPDFReadNumber(&numberCursor, &objectNumber) || numberCursor.position != scan) {
			scan += strlen(objectMarker);
			continue;
		}

		NSRange body;
		if (!MADPDFFindObject(pdf, (NSUInteger)objectNumber, &body)) {
			scan += strlen(objectMarker);
			continue;
		}
		if (body.length < strlen(pagePrefix) ||
			memcmp(bytes + body.location, pagePrefix, strlen(pagePrefix)) != 0) {
			scan += strlen(objectMarker);
			continue;
		}

		NSMutableArray *mediaBox = [NSMutableArray array];
		{
			NSString *bodyText = [[NSString alloc] initWithBytes: bytes + body.location
														  length: body.length
														encoding: NSISOLatin1StringEncoding];
			NSRange media = [bodyText rangeOfString: @"MediaBox"];
			[bodyText release];
			if (media.location != NSNotFound) {
				MADPDFCursor cursor = { bytes, length, body.location + media.location + media.length };
				MADPDFSkipSpace(&cursor);
				if (cursor.position < length && bytes[cursor.position] == '[') {
					cursor.position++;
					for (NSUInteger index = 0; index < 4; index++) {
						double value = 0;
						MADPDFReadNumber(&cursor, &value);
						[mediaBox addObject: @(value)];
					}
				}
			}
		}
		NSUInteger contents = MADPDFReferenceAfter(pdf, @"/Contents", body.location, body.location + body.length);
		NSUInteger resources = MADPDFReferenceAfter(pdf, @"/Resources", body.location, body.location + body.length);

		// The page's fonts: resource name -> (ToUnicode map, code byte width).
		NSMutableDictionary *fontMaps = [NSMutableDictionary dictionary];
		NSMutableDictionary *fontCodeBytes = [NSMutableDictionary dictionary];
		if (resources != NSNotFound) {
			NSRange resourceBody;
			if (MADPDFFindObject(pdf, resources, &resourceBody)) {
				NSString *resourceText = [[NSString alloc] initWithBytes: bytes + resourceBody.location
																  length: resourceBody.length
																encoding: NSISOLatin1StringEncoding];
				NSRange fontList = [resourceText rangeOfString: @"Font"];
				NSUInteger cursor = fontList.location == NSNotFound ? resourceText.length : fontList.location + fontList.length;
				while (cursor < resourceText.length) {
					NSRange nameRange = [resourceText rangeOfString: @"/" options: 0
															 range: NSMakeRange(cursor, resourceText.length - cursor)];
					if (nameRange.location == NSNotFound) break;
					NSUInteger nameEnd = nameRange.location + 1;
					while (nameEnd < resourceText.length) {
						unichar character = [resourceText characterAtIndex: nameEnd];
						if (character == ' ' || character == '\n' || character == '\r' ||
							character == '/' || character == '>') break;
						nameEnd++;
					}
					NSString *name = [resourceText substringWithRange:
									  NSMakeRange(nameRange.location + 1, nameEnd - nameRange.location - 1)];
					MADPDFCursor reference = { bytes, pdf.length, resourceBody.location + nameEnd };
					double fontNumber = 0;
					if (MADPDFReadNumber(&reference, &fontNumber)) {
						NSRange fontBody;
						if (MADPDFFindObject(pdf, (NSUInteger)fontNumber, &fontBody)) {
							NSUInteger toUnicode = MADPDFReferenceAfter(pdf, @"/ToUnicode",
																		fontBody.location,
																		fontBody.location + fontBody.length);
							if (toUnicode != NSNotFound) {
								NSData *cmap = MADPDFStreamData(pdf, toUnicode);
								if (cmap != nil) {
									NSUInteger codeBytes = 1;
									fontMaps[name] = MADPDFToUnicodeMap(cmap, &codeBytes);
									fontCodeBytes[name] = @(codeBytes);
								}
							}
						}
					}
					cursor = nameEnd;
				}
				[resourceText release];
			}
		}

		NSArray *runs = [NSArray array];
		if (contents != NSNotFound) {
			NSData *content = MADPDFStreamData(pdf, contents);
			if (content != nil) runs = MADPDFTextRuns(content, fontMaps, fontCodeBytes);
		}

		NSMutableDictionary *page = [NSMutableDictionary dictionary];
		page[@"mediaBox"] = mediaBox;
		page[@"runs"] = runs;
		[pages addObject: page];

		scan += strlen(objectMarker);
	}
	return pages;
}

#pragma mark - The json-report oracle

static NSString *MADPDFJSONStringAt(NSString *json, NSUInteger *position) {
	if (*position >= json.length || [json characterAtIndex: *position] != '"') return nil;
	*position += 1;
	NSMutableString *text = [NSMutableString string];
	while (*position < json.length) {
		unichar character = [json characterAtIndex: *position];
		*position += 1;
		if (character == '"') return text;
		if (character != '\\' || *position >= json.length) {
			[text appendFormat: @"%C", character];
			continue;
		}
		unichar escaped = [json characterAtIndex: *position];
		*position += 1;
		switch (escaped) {
			case 'n': [text appendString: @"\n"]; break;
			case 'r': [text appendString: @"\r"]; break;
			case 't': [text appendString: @"\t"]; break;
			case 'b': [text appendString: @"\b"]; break;
			case 'f': [text appendString: @"\f"]; break;
			case 'u': {
				unsigned int value = 0;
				if (*position + 4 <= json.length) {
					[[NSScanner scannerWithString: [json substringWithRange: NSMakeRange(*position, 4)]] scanHexInt: &value];
					*position += 4;
				}
				[text appendFormat: @"%C", (unichar)value];
				break;
			}
			default: [text appendFormat: @"%C", escaped]; break;
		}
	}
	return text;
}

/// The report's pages, each an ordered array of line dictionaries:
/// @{ @"kind": NSString, @"frame": NSArray of 4 numbers, @"text": NSString?, @"image": @YES? }.
static NSArray *MADPDFReportPages(NSString *json) {
	NSMutableArray *pages = [NSMutableArray array];
	NSRange pagesStart = [json rangeOfString: @"\"pages\": ["];
	if (pagesStart.location == NSNotFound) return pages;

	NSUInteger position = pagesStart.location + pagesStart.length;
	while (position < json.length) {
		NSRange pageMarker = [json rangeOfString: @"{ \"index\": " options: 0
										   range: NSMakeRange(position, json.length - position)];
		if (pageMarker.location == NSNotFound) break;

		NSRange nextPage = [json rangeOfString: @"{ \"index\": " options: 0
										 range: NSMakeRange(pageMarker.location + pageMarker.length,
															json.length - pageMarker.location - pageMarker.length)];
		NSUInteger pageEnd = nextPage.location == NSNotFound ? json.length : nextPage.location;
		NSMutableArray *lines = [NSMutableArray array];

		NSUInteger linePosition = pageMarker.location;
		while (linePosition < pageEnd) {
			NSRange lineMarker = [json rangeOfString: @"{\"kind\": " options: 0
											   range: NSMakeRange(linePosition, pageEnd - linePosition)];
			if (lineMarker.location == NSNotFound) break;

			// A line object is one line of the file; the next line's marker (or the
			// page's end) bounds this one, so an absent member is not found on the
			// next line.
			NSUInteger lineEnd = pageEnd;
			NSRange nextLine = [json rangeOfString: @"{\"kind\": " options: 0
											 range: NSMakeRange(lineMarker.location + lineMarker.length,
																pageEnd - lineMarker.location - lineMarker.length)];
			if (nextLine.location != NSNotFound) lineEnd = nextLine.location;

			NSUInteger cursor = lineMarker.location + lineMarker.length;
			NSString *kind = MADPDFJSONStringAt(json, &cursor);
			NSMutableDictionary *line = [NSMutableDictionary dictionary];
			if (kind != nil) line[@"kind"] = kind;

			NSRange frameMarker = [json rangeOfString: @", \"frame\": [" options: 0
											   range: NSMakeRange(cursor, lineEnd - cursor)];
			if (frameMarker.location != NSNotFound) {
				NSString *frameText = [json substringWithRange:
									   NSMakeRange(frameMarker.location + frameMarker.length,
												   MIN((NSUInteger)80, lineEnd - frameMarker.location - frameMarker.length))];
				NSRange close = [frameText rangeOfString: @"]"];
				if (close.location != NSNotFound) frameText = [frameText substringToIndex: close.location];
				NSMutableArray *values = [NSMutableArray array];
				for (NSString *piece in [frameText componentsSeparatedByString: @","]) {
					[values addObject: @(piece.doubleValue)];
				}
				if (values.count == 4) line[@"frame"] = values;
			}

			NSRange textMarker = [json rangeOfString: @", \"text\": " options: 0
											   range: NSMakeRange(cursor, lineEnd - cursor)];
			NSRange imageMarker = [json rangeOfString: @", \"image\": true" options: 0
												range: NSMakeRange(cursor, lineEnd - cursor)];
			if (textMarker.location != NSNotFound &&
				(imageMarker.location == NSNotFound || textMarker.location < imageMarker.location)) {
				NSUInteger textCursor = textMarker.location + textMarker.length;
				NSString *text = MADPDFJSONStringAt(json, &textCursor);
				if (text != nil) line[@"text"] = text;
			}
			if (imageMarker.location != NSNotFound) line[@"image"] = @YES;

			[lines addObject: line];
			linePosition = lineEnd;
		}
		[pages addObject: lines];
		position = pageEnd;
	}
	return pages;
}

// How many walked lines one drawn run covers: cairo may merge consecutive lines
// into one Tj/TJ operator; a line wider than its frame is drawn as a prefix of
// its text plus the ellipsis.  Returns 0 when the run is not the walk's text at
// `from`.
static NSUInteger MADPDFMatchedLineCount(NSString *drawn, NSArray *expected, NSUInteger from) {
	BOOL truncated = drawn.length > 0 && [drawn hasSuffix: @"…"];
	NSString *withoutEllipsis = truncated ? [drawn substringToIndex: drawn.length - 1] : drawn;
	NSMutableString *accumulated = [NSMutableString string];

	NSUInteger index = from;
	while (index < expected.count) {
		NSString *piece = expected[index];
		NSUInteger before = accumulated.length;
		[accumulated appendString: piece];

		if ([drawn isEqualToString: accumulated] || [withoutEllipsis isEqualToString: accumulated]) {
			return index - from + 1;
		}
		if ([drawn hasPrefix: accumulated]) {
			index++;
			continue;
		}
		if (truncated && [accumulated hasPrefix: withoutEllipsis]) {
			if ([piece hasPrefix: [withoutEllipsis substringFromIndex: before]]) {
				return index - from + 1;
			}
		}
		return 0;
	}
	return 0;
}

#pragma mark - Tests

static void testThePDFExporterIsAvailable(void) {
	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: @"pdf"];
	MAD_PASS(exporterClass != Nil, "pdf is registered");
	MAD_PASS([exporterClass isAvailable], "this build produces it");
	MAD_PASS([exporterClass unavailableReason] == nil, "and gives no reason why it could not");
	MAD_PASS([exporterClass requiresOutputPath], "pdf needs --out, on every platform");
	MAD_PASS_EQUAL([exporterClass fileExtension], @"pdf", "and it is a .pdf");
}

static void testThePDFIsTheWalkedPagesAndTheirText(void) {
	MAD_NEED(MADPDFExportDocument() != nil, @"could not open the London fixture");

	NSData *pdf = MADPDFExportData(@"pdf", MADReportExportOptionsDeterministic, @"london.pdf");
	if (pdf == nil) return;
	NSData *json = MADPDFExportData(@"json-report", MADReportExportOptionsDeterministic, @"london.report.json");
	if (json == nil) return;

	NSString *pdfText = [[NSString alloc] initWithData: pdf encoding: NSISOLatin1StringEncoding];
	MAD_PASS([pdfText hasPrefix: @"%PDF-1.4"], "the file is a PDF 1.4, the writer's own version");
	MAD_PASS([pdfText rangeOfString: @"/Producer (cairo "].location != NSNotFound, "cairo is the producer");
	MAD_PASS([pdfText rangeOfString: @"/Creator"].location != NSNotFound, "the creator is set");
	[pdfText release];

	NSString *jsonText = [[NSString alloc] initWithData: json encoding: NSUTF8StringEncoding];
	NSArray *oraclePages = MADPDFReportPages(jsonText);
	[jsonText release];
	MAD_PASS(oraclePages.count > 0, "the oracle has pages to compare against");

	NSArray *pages = MADPDFPages(pdf);
	MAD_PASS_EQUAL(@(pages.count), @(oraclePages.count), "the PDF has the oracle's page count");

	NSMutableArray *expectedFrames = [NSMutableArray array];
	NSUInteger pageIndex = 0;
	for (NSDictionary *page in pages) {
		if (pageIndex >= oraclePages.count) break;
		NSArray *box = page[@"mediaBox"];
		MAD_PASS(box.count == 4 &&
				 fabs([[box objectAtIndex: 2] doubleValue] - [[box objectAtIndex: 0] doubleValue] - 612.0) < 0.01 &&
				 fabs([[box objectAtIndex: 3] doubleValue] - [[box objectAtIndex: 1] doubleValue] - 792.0) < 0.01,
				 "page %lu is US Letter", (unsigned long)pageIndex);

		NSMutableArray *expected = [NSMutableArray array];
		NSMutableArray *pageFrames = [NSMutableArray array];
		for (NSDictionary *line in oraclePages[pageIndex]) {
			NSArray *frame = line[@"frame"];
			if (frame.count == 4) {
				double x = [frame[0] doubleValue], y = [frame[1] doubleValue];
				double width = [frame[2] doubleValue], height = [frame[3] doubleValue];
				MAD_PASS(x >= 1.0 - 0.01 && y >= 1.0 - 0.01 &&
						 x + width <= 611.0 + 0.01 && y + height <= 791.0 + 0.01,
						 "page %lu's %s line is inside the 1pt trim",
						 (unsigned long)pageIndex, [line[@"kind"] UTF8String]);
			}
			NSString *text = line[@"text"];
			if (line[@"image"] == nil && text.length > 0) {
				[expected addObject: text];
				[pageFrames addObject: frame ?: [NSArray array]];
			}
		}
		expectedFrames[pageIndex] = pageFrames;

		// Cairo may draw several consecutive lines in one text object, so a
		// Tj/TJ operator covers one or more walked lines; a truncated line is a
		// prefix of its text plus the ellipsis.  The run is matched against the
		// walk greedily, and its baseline is checked against the first line it
		// covers.
		NSArray *frames = expectedFrames[pageIndex];
		NSUInteger consumed = 0;
		for (NSDictionary *run in page[@"runs"]) {
			NSString *drawn = run[@"text"];
			if (drawn.length == 0) continue;

			NSUInteger count = MADPDFMatchedLineCount(drawn, expected, consumed);
			MAD_PASS(count > 0, "page %lu line %lu is the walk's text (drawn: %s)",
					 (unsigned long)pageIndex, (unsigned long)consumed, [drawn UTF8String]);
			if (count == 0) break;

			NSArray *frame = consumed < frames.count ? frames[consumed] : nil;
			if (frame.count == 4) {
				double fy = [frame[1] doubleValue];
				double fh = [frame[3] doubleValue];
				double py = [run[@"y"] doubleValue];
				// The page is drawn in cairo's y-down space; a y-up slip lands the
				// baseline on the mirrored half of the page and fails here.
				MAD_PASS(py >= fy - 1.0 && py <= fy + fh + 24.0,
						 "page %lu line %lu's baseline is at its frame's top (%.2f in [%.2f, %.2f])",
						 (unsigned long)pageIndex, (unsigned long)consumed, py, fy, fy + fh + 24.0);
			}
			consumed += count;
		}
		MAD_PASS_EQUAL(@(consumed), @(expected.count),
					   "page %lu draws every walked text line", (unsigned long)pageIndex);
		pageIndex++;
	}
}

static void testThePDFCarriesTheBarcodeAndThePictureAsImages(void) {
	MAD_NEED(MADPDFExportDocument() != nil, @"could not open the London fixture");

	NSData *pdf = MADPDFExportData(@"pdf", MADReportExportOptionsDeterministic, @"london.images.pdf");
	if (pdf == nil) return;

	NSString *text = [[NSString alloc] initWithData: pdf encoding: NSISOLatin1StringEncoding];

	// Each image XObject's own pixel size, from the dictionary around its
	// /Subtype /Image: the barcode's symbol is drawn from a 224x96 bitmap and
	// the picture is the fixture's 1x1 PNG, so their presence proves both
	// walked pictures reached the page, not merely that some image did.
	NSMutableArray<NSString *> *sizes = [NSMutableArray array];
	NSRange search = NSMakeRange(0, text.length);
	while (search.length > 0) {
		NSRange found = [text rangeOfString: @"/Subtype /Image" options: 0 range: search];
		if (found.location == NSNotFound) break;
		NSRange open = [text rangeOfString: @"<<" options: NSBackwardsSearch
									   range: NSMakeRange(0, found.location)];
		NSRange close = [text rangeOfString: @">>" options: 0
									  range: NSMakeRange(found.location, text.length - found.location)];
		if (open.location != NSNotFound && close.location != NSNotFound) {
			NSString *dict = [text substringWithRange: NSMakeRange(open.location, NSMaxRange(close) - open.location)];
			NSRange width = [dict rangeOfString: @"/Width "];
			NSRange height = [dict rangeOfString: @"/Height "];
			if (width.location != NSNotFound && height.location != NSNotFound) {
				[sizes addObject: [NSString stringWithFormat: @"%ldx%ld",
								   (long)[[dict substringFromIndex: NSMaxRange(width)] integerValue],
								   (long)[[dict substringFromIndex: NSMaxRange(height)] integerValue]]];
			}
		}
		search = NSMakeRange(NSMaxRange(found), text.length - NSMaxRange(found));
	}
	[text release];
	NSString *inventory = [sizes componentsJoinedByString: @", "];
	MAD_PASS([sizes containsObject: @"224x96"],
			 "the barcode's 224x96 symbol is an image XObject (%s)", inventory.UTF8String);
	MAD_PASS([sizes containsObject: @"1x1"],
			 "the picture's 1x1 PNG is an image XObject at its own resolution (%s)", inventory.UTF8String);
}

static void testTheDeterministicExportIsTheSameBytes(void) {
	MAD_NEED(MADPDFExportDocument() != nil, @"could not open the London fixture");

	NSData *first = MADPDFExportData(@"pdf", MADReportExportOptionsDeterministic, @"london.one.pdf");
	NSData *second = MADPDFExportData(@"pdf", MADReportExportOptionsDeterministic, @"london.two.pdf");
	if (first == nil || second == nil) return;

	MAD_PASS([first isEqualToData: second], "two deterministic exports of an unchanged report are the same bytes");

	NSString *text = [[NSString alloc] initWithData: first encoding: NSISOLatin1StringEncoding];
	MAD_PASS([text rangeOfString: @"20010112000000"].location != NSNotFound,
			 "the creation date is the pinned PDF epoch");
	[text release];
}

static void testAnOrdinaryExportStillWritesAPDF(void) {
	MAD_NEED(MADPDFExportDocument() != nil, @"could not open the London fixture");

	NSData *pdf = MADPDFExportData(@"pdf", MADReportExportOptionsNone, @"london.ordinary.pdf");
	if (pdf == nil) return;
	NSString *text = [[NSString alloc] initWithData: pdf encoding: NSISOLatin1StringEncoding];
	MAD_PASS([text hasPrefix: @"%PDF-1.4"], "a non-deterministic export is a PDF too");
	MAD_PASS([text rangeOfString: @"20010112000000"].location == NSNotFound,
			 "and it takes its creation date from the clock");
	[text release];
}

MAD_TEST_MAIN("MADPDFExportTests",
	MAD_TEST(testThePDFExporterIsAvailable),
	MAD_TEST(testThePDFIsTheWalkedPagesAndTheirText),
	MAD_TEST(testThePDFCarriesTheBarcodeAndThePictureAsImages),
	MAD_TEST(testTheDeterministicExportIsTheSameBytes),
	MAD_TEST(testAnOrdinaryExportStillWritesAPDF),
)
