//
//  MADCLIDocument.m
//  MAD Designer
//

#import "MADCLIDocument.h"
#import "MADCLI.h"

// The refresh chain.  These live in the application target; the CLI compiles them in
// rather than copying them, so the two cannot drift.  MAD_CLI.md section 4.1 says
// they belong in the MAD framework, and they will move there.
#import "MADOperationRefresh.h"
#import "MADOperationRefreshInitialize.h"
#import "MADOperationRefreshInitalizeMainDataTable.h"

#import <MAD/MADocument.h>
#import <MAD/MADConstants.h>
#import <MAD/MADPrintPageRenderer.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADPageOptions.h>
#import <MAD/MTPaper.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>

#import <MADFoundation/MADDataTable.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADCredential.h>

#import <UIKit/UIGraphics.h>

static inline CGRect MADCLIPdfTrimBox(CGRect rect) {
	return UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0));
}

#pragma mark - Deterministic PDF metadata

static NSUInteger MADCLIFindBytes(const uint8_t *bytes, NSUInteger length, NSUInteger from, const char *needle) {
	NSUInteger needleLength = strlen(needle);
	if (needleLength == 0 || length < needleLength) return NSNotFound;
	for (NSUInteger i = from; i + needleLength <= length; i++) {
		if (memcmp(bytes + i, needle, needleLength) == 0) return i;
	}
	return NSNotFound;
}

static NSUInteger MADCLIFindBytesLast(const uint8_t *bytes, NSUInteger length, const char *needle) {
	NSUInteger needleLength = strlen(needle);
	if (needleLength == 0 || length < needleLength) return NSNotFound;
	for (NSUInteger i = length - needleLength + 1; i-- > 0; ) {
		if (memcmp(bytes + i, needle, needleLength) == 0) return i;
	}
	return NSNotFound;
}

static NSUInteger MADCLISkipToByte(const uint8_t *bytes, NSUInteger length, NSUInteger from, uint8_t byte) {
	for (NSUInteger i = from; i < length; i++) {
		if (bytes[i] == byte) return i;
	}
	return NSNotFound;
}

/// Core Graphics takes /CreationDate and /ModDate from the clock and derives the
/// trailer /ID from them, so two exports of a report that has not changed differ in
/// a handful of bytes at the end and nowhere else.  That is exactly enough to defeat
/// the byte-for-byte comparison this tool exists to make, so --deterministic pins
/// all three to constants.
///
/// Every replacement is the same length as what it replaces -- the date digits are
/// always fourteen, and the identifiers keep whatever width PDF gave them -- so the
/// cross-reference offsets in the last table stay correct and the file is still a
/// valid PDF.
static void MADCLIPinPDFMetadata(NSURL *url) {

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
		NSUInteger at = MADCLIFindBytesLast(bytes, length, dateKeys[key]);
		if (at == NSNotFound) continue;
		NSUInteger string = MADCLIFindBytes(bytes, length, at, "(D:");
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

	NSUInteger identifier = MADCLIFindBytesLast(bytes, length, "/ID");
	NSUInteger bracket = identifier == NSNotFound ? NSNotFound : MADCLISkipToByte(bytes, length, identifier, '[');
	if (bracket != NSNotFound) {
		static const char *alphabet = "0123456789abcdef";
		NSUInteger cursor = bracket;
		for (NSUInteger string = 0; string < 2; string++) {
			NSUInteger open = MADCLISkipToByte(bytes, length, cursor, '<');
			if (open == NSNotFound) break;
			NSUInteger close = MADCLISkipToByte(bytes, length, open + 1, '>');
			if (close == NSNotFound) break;
			for (NSUInteger i = open + 1; i < close; i++) {
				bytes[i] = (uint8_t)alphabet[(i - open - 1) % 16];
			}
			cursor = close + 1;
		}
	}

	[data writeToURL: url atomically: YES];
}

static NSError *MADCLIDocumentError(NSString *message) {
	return [NSError errorWithDomain: @"MADCLI" code: MADCLIExitBadDocument
						   userInfo: @{ NSLocalizedDescriptionKey: message }];
}

/// Stands in for MADOperationGetCredentials, which is a view controller.  The CLI
/// never prompts: it carries what it was given and nothing more.  It is an operation
/// because that is how MADOperationRefresh looks for credentials -- it inspects its
/// own dependencies for the protocol.
@interface MADCLICredentialsOperation : MADOperation <MADOperationHoldsCredentialsProtocol>
@property (nonatomic, strong) MADCredential *credentials;
@end

@implementation MADCLICredentialsOperation
- (BOOL)isAsynchronous { return YES; }
- (void)execute { [self finish]; }
- (BOOL)gotCredentials { return self.credentials != nil; }
- (BOOL)manuallyInputtedCredentials { return NO; }
@end

@interface MADCLIDocument ()
@property (nonatomic, strong) MADocument *document;
@property (nonatomic, assign) NSUInteger pageCount;
@end

@implementation MADCLIDocument

+ (instancetype)documentWithURL:(NSURL *)url error:(NSError **)error {

	MADocument *document = [[MADocument alloc] initWithFileURL: url];
	document.limitResultsDesignMode = NO;

	__block BOOL finished = NO;
	__block BOOL success = NO;
	[document openWithCompletionHandler: ^(BOOL opened) {
		success = opened;
		finished = YES;
	}];

	// UIDocument opens asynchronously and delivers its completion on the main queue,
	// so the run loop has to turn while we wait.  A CLI has no other use for it.
	while (!finished) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
									 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
		}
	}

	if (!success) {
		if (error) *error = MADCLIDocumentError([NSString stringWithFormat: @"Could not open %@.", url.lastPathComponent]);
		return nil;
	}

	MADCLIDocument *cli = [[MADCLIDocument alloc] init];
	cli.document = document;
	return cli;
}

#pragma mark - Refresh

- (BOOL)refreshWithCredentials:(MADCredential *)credentials error:(NSError **)error {

	MADocument *document = self.document;
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;

	MADOperationRefreshInitializeMainDataTable *initializeTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument: document];

	MADOperationRefreshInitialize *initialize =
		[[MADOperationRefreshInitialize alloc] initWithDocument: document];
	[initialize addDependency: initializeTable];

	MADOperationRefresh *refresh = [[MADOperationRefresh alloc] initWithDocument: document];
	[refresh addDependency: initializeTable];
	[refresh addDependency: initialize];

	[queue addOperation: initializeTable];
	[queue addOperation: initialize];

	if (credentials != nil) {
		MADCLICredentialsOperation *holder = [[MADCLICredentialsOperation alloc] init];
		holder.credentials = credentials;
		[refresh addDependency: holder];
		[queue addOperation: holder];
	}

	[queue addOperation: refresh];

	while (queue.operationCount > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
									 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
		}
	}

	// The credentials holder is not an NSOperation, so it cannot sit in the queue
	// directly; see the note on MADCLICredentialsOperation above.
	if (refresh.errors.count > 0) {
		if (error) *error = refresh.errors.firstObject;
		return NO;
	}
	return YES;
}

#pragma mark - Export

- (BOOL)writePDFToURL:(NSURL *)url deterministic:(BOOL)deterministic error:(NSError **)error {

	MADocument *document = self.document;
	CGRect letterRect = [[MTPaper alloc] initWithType: MTPaperTypeLetter].bounds;
	NSDictionary *options = @{ (__bridge NSString *)kCGPDFContextCreator: @"MAD® Designer" };

	// The reload the viewer runs after a refresh, which the CLI has no view controller
	// to run for it: sort the rows, then lay the report out.
	//
	// MADPrintPageRenderer draws from document.reportFormatter -- not from the
	// separate formatter MADActivityItemProviderPdf builds alongside it -- so it is
	// the document's own formatter that has to be formatted.  Building a second one,
	// as the application does, leaves the one being drawn from unformatted and every
	// page comes out empty.  The application gets away with it only because its
	// viewer has already reloaded; here nothing has.
	[document prepareForQuery];

	MADReportFormatter *reportFormatter = document.reportFormatter;
	reportFormatter.overrideIdentifier = @"madpreview";
	reportFormatter.didRefresh = YES;
	reportFormatter.layoutSize = letterRect.size;
	[reportFormatter setMarginUsingPrintableRect: MADCLIPdfTrimBox(letterRect)];
	[document format];

	self.pageCount = reportFormatter.numberOfPages;

	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource: document];

	CGRect trimBox = MADCLIPdfTrimBox(letterRect);
	NSDictionary *boxInfo = @{ (__bridge NSString *)kCGPDFContextTrimBox: [NSValue valueWithCGRect: trimBox] };

	UIGraphicsBeginPDFContextToFile(url.path, letterRect, options);
	for (NSUInteger page = 0; page < reportFormatter.numberOfPages; page++) {
		@autoreleasepool {
			UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
			[renderer drawPageAtIndex: (NSInteger)page inRect: trimBox];
		}
	}
	UIGraphicsEndPDFContext();

	if (deterministic) {
		MADCLIPinPDFMetadata(url);
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath: url.path]) {
		if (error) *error = [NSError errorWithDomain: @"MADCLI" code: MADCLIExitExportFailed
											userInfo: @{ NSLocalizedDescriptionKey: @"No PDF was written." }];
		return NO;
	}
	return YES;
}

@end
