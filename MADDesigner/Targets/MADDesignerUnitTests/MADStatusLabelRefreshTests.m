//
//  MADStatusLabelRefreshTests.m
//  MADDesignerUnitTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  The per-page "Formatting page N." status message, driven end to end without a
//  database.  The app's path is:
//
//    MADReportFormatter -formatDocumentForcePageBreakWithFooterHeight:      (MAD)
//      -> MADNotificationDidFormatPage -reportFormatter:formattedPage:      (MAD, post)
//      -> MADRefreshOperationReload -reportFormatterDidFormatPage:          (app, observe)
//      -> -updateFormattingPage:                                            (app, hop to main)
//      -> MADViewerController -operation:didFormatPage:                     (app, protocol)
//      -> MADLabelStatus -updateRecordsReadStatusWithNumberOfPagesFormatted:
//      -> -updateStatusWithFormattingPage:                                  (hop to main)
//      -> -updateDisplay
//
//  with -operationDidBeginFormatting: announcing the phase before the first post, and at
//  the end of the run -operation:updatePages: -> -updatePageStatus: writes the same label
//  line with the final page position.  The operation coalesces the posts -- newest page,
//  floored at 10 Hz, flushed once before the page position -- so the label is told a
//  bounded number of times.
//
//  MADLabelStatus and MADRefreshOperationReload are compiled into the app target, and the
//  test bundle's header search path does not include MADDesigner/Source, so their
//  interfaces are declared below and the symbols resolve against the running app -- the
//  same arrangement MADAppLogicTests.m uses for its app classes.
//
//  The label records every string it is ever asked to display, by overriding
//  -setAttributedText:.  That is what tells "never set" apart from "set, then immediately
//  replaced", which is the distinction a screenshot cannot make: -updateDisplay rebuilds
//  one mutable attributed string and assigns it whole, so each state lands in the history
//  even when it is on screen for less than a frame.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MAD/MADocument.h>
#import <MAD/MADNotificationDidFormatPage.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <UIKit/UIApplication.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphicsImageRenderer.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIWindowScene.h>

#pragma mark - App interfaces (reached through the host)

@interface MADLabelStatus : UILabel
- (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs;
- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs;
- (void)updatePageStatus:(MADReportPosition)reportPosition;
- (void)updateStatusWithTime:(NSString *)timeMessage;
- (void)updateRefreshStarted;
- (void)updateFormattingStarted;
@end

@interface MADRefreshOperationReload : NSOperation
- (instancetype)initWithDocument:(MADocument *)document
				  viewController:(id)viewController;
@end

// MADViewerController's half of MADOperationRefreshReloadProtocol.  The protocol header is
// app source too, so the message set is repeated here; the reload operation only ever
// sends these six selectors.
@protocol MADRefreshReloadObserverProtocol <NSObject>
- (void)operation:(MADOperation *)operation updatePages:(NSUInteger)numberOfPages;
- (void)operation:(MADOperation *)operation updateRecordsRead:(NSUInteger)records;
- (void)operation:(MADOperation *)operation setDisplayActive:(BOOL)active;
- (void)operation:(MADOperation *)operation finishReload:(MADocument *)document;
- (void)operation:(MADOperation *)operation didReadRows:(NSNotification *)sender;
- (void)operation:(MADOperation *)operation didFormatPage:(NSNotification *)sender;
- (void)operationDidBeginFormatting:(MADOperation *)operation;
@end

#pragma mark - Recording label

@interface MADRecordingLabelStatus : MADLabelStatus
@property (nonatomic, strong) NSMutableArray<NSString *> *displayHistory;
@end

@implementation MADRecordingLabelStatus

- (NSMutableArray<NSString *> *)displayHistory {
	if (_displayHistory == nil) {
		_displayHistory = [[NSMutableArray alloc] init];
	}
	return _displayHistory;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
	// -updateDisplay hands the label the same NSMutableAttributedString every time and
	// mutates it in place, so the string has to be copied here -- recording the
	// reference makes every entry show the *last* state instead of the one assigned.
	NSString *text = [attributedText.string copy];
	if (text != nil) {
		[self.displayHistory addObject:text];
	}
	[super setAttributedText:attributedText];
}

@end

#pragma mark - Test doubles

// The reload operation's document, cut down to the six things it reads: -prepareForQuery,
// -reportFormatter, -format / -formatContentChange, -numberOfPages, -numberOfResults and
// the -refreshed flag.  Its format stands in for MADReportFormatter's, posting the same
// MADNotificationDidFormatPagesName the formatter posts at each page break; the
// formatter's own posting is pinned by the MAD framework suite, so what is under test here
// is the app-side hand-off from that post to the label.
@interface MADTestReloadDocument : MADocument
@property (nonatomic, assign) NSUInteger testNumberOfPages;
@property (nonatomic, assign) NSUInteger testNumberOfResults;
@property (nonatomic, assign) NSUInteger formatCallCount;
// The pause between page breaks, so a test can give the format a wall-clock window
// the way a large report has one.  0 formats as fast as the loop runs.
@property (nonatomic, assign) NSTimeInterval testPostInterval;
@end

@implementation MADTestReloadDocument

- (void)prepareForQuery { }

- (void)format {
	self.formatCallCount = self.formatCallCount + 1;
	[self testPostFormatPages];
}

- (void)formatContentChange {
	self.formatCallCount = self.formatCallCount + 1;
	[self testPostFormatPages];
}

- (void)testPostFormatPages {
	// The real singleton, so the per-post throttle behaves as it does in the app.
	for (NSUInteger page = 1; page <= self.testNumberOfPages; page++) {
		[[MADNotificationDidFormatPage sharedObject] reportFormatter:nil formattedPage:page];
		if (self.testPostInterval > 0.0) {
			[NSThread sleepForTimeInterval:self.testPostInterval];
		}
	}
}

- (NSUInteger)numberOfPages { return self.testNumberOfPages; }
- (NSUInteger)numberOfResults { return self.testNumberOfResults; }

@end

// The viewer's side of the protocol, which is the only object the reload operation talks
// to.  The two calls that matter are copied from MADViewerController:
// -operation:didFormatPage: hands each posted page number to the label, and
// -operation:updatePages: hands it the final page position, which is what replaces the
// formatting line when the format finishes.
@interface MADRecordingStatusViewController : NSObject <MADRefreshReloadObserverProtocol>
@property (nonatomic, strong) MADRecordingLabelStatus *label;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *formattedPages;
@property (nonatomic, assign) BOOL finishedReload;
@property (nonatomic, assign) BOOL sawFormattingBegin;
@end

@implementation MADRecordingStatusViewController

- (NSMutableArray<NSNumber *> *)formattedPages {
	if (_formattedPages == nil) {
		_formattedPages = [[NSMutableArray alloc] init];
	}
	return _formattedPages;
}

- (void)operation:(MADOperation * __unused)operation didFormatPage:(NSNotification *)sender {
	NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
	[self.formattedPages addObject:(pageNumber ?: @0)];
	[self.label updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)operationDidBeginFormatting:(MADOperation * __unused)operation {
	self.sawFormattingBegin = YES;
	[self.label updateFormattingStarted];
}

- (void)operation:(MADOperation * __unused)operation updatePages:(NSUInteger)numberOfPages {
	[self.label updatePageStatus:MADReportPositionMake(0, numberOfPages)];
}

- (void)operation:(MADOperation * __unused)operation updateRecordsRead:(NSUInteger)records {
	[self.label updateRecordsReadStatusWithNumberOfRecordsRead:@(records)];
}

- (void)operation:(MADOperation * __unused)operation finishReload:(MADocument * __unused)document {
	self.finishedReload = YES;
}

- (void)operation:(MADOperation * __unused)operation setDisplayActive:(BOOL __unused)active { }

- (void)operation:(MADOperation * __unused)operation didReadRows:(NSNotification * __unused)sender { }

@end

#pragma mark - Main-thread heartbeat

// Counts how often the main run loop gets to fire a 10 ms repeating timer.  Drawing
// happens on the main run loop, so a format that floods the main queue with label
// work shows up here as a run with almost no beats -- the UI is not drawing no matter
// what the label's attributed text says.  Ten a second is the rate the run loop is
// expected to service; the test floors the count rather than pinning it.
@interface MADMainThreadHeartbeat : NSObject
@property (nonatomic, assign) NSUInteger beats;
- (void)start;
- (void)stop;
@end

@implementation MADMainThreadHeartbeat {
	NSTimer *_timer;
}

- (void)start {
	[_timer invalidate];
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.01
											 target:self
										   selector:@selector(beat:)
										   userInfo:nil
											repeats:YES];
}

- (void)stop {
	[_timer invalidate];
	_timer = nil;
}

- (void)beat:(NSTimer * __unused)timer {
	self.beats = self.beats + 1;
}

@end

#pragma mark - Tests

@interface MADStatusLabelRefreshTests : XCTestCase
@end

@implementation MADStatusLabelRefreshTests

#pragma mark - Helpers

// Runs the main run loop for a while, which is what drains the main-queue hops the reload
// path dispatches through.  A test must never block the main thread waiting on the
// operation: the operation marshals -prepareForQuery onto the main queue, so a blocked
// main thread deadlocks it.
- (void)runMainLoopFor:(NSTimeInterval)seconds {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:seconds];
	while (deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
}

- (MADTestReloadDocument *)newReloadDocumentWithPages:(NSUInteger)pages {
	NSURL *url = [NSURL fileURLWithPath:
				  [NSTemporaryDirectory() stringByAppendingPathComponent:@"MADStatusLabelRefreshTests.mad"]];
	MADTestReloadDocument *document = [[MADTestReloadDocument alloc] initWithFileURL:url];
	document.testNumberOfPages = pages;
	document.testNumberOfResults = 1234;
	return document;
}

// Pumps the main run loop until the operation finishes, which is what the app's run
// loop does for the same window.  The test thread must pump, never block on the
// operation: the operation marshals -prepareForQuery onto the main queue.
- (void)waitForOperation:(NSOperation *)operation timeout:(NSTimeInterval)timeout {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
	while (operation.isFinished == NO && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
}

- (BOOL)history:(NSArray<NSString *> *)history containsSubstring:(NSString *)substring {
	for (NSString *displayed in history) {
		if ([displayed containsString:substring]) {
			return YES;
		}
	}
	return NO;
}

- (NSString *)transcriptForLabel:(MADRecordingLabelStatus *)label
			  formattedPageCount:(NSUInteger)formattedPageCount {
	NSMutableString *report = [[NSMutableString alloc] init];
	[report appendFormat:@"didFormatPage: deliveries: %lu\n", (unsigned long)formattedPageCount];
	[report appendFormat:@"label display history (%lu states):\n", (unsigned long)label.displayHistory.count];
	for (NSString *displayed in label.displayHistory) {
		NSString *oneLine = [displayed stringByReplacingOccurrencesOfString:@"\n" withString:@" / "];
		[report appendFormat:@"  %@\n", oneLine];
	}
	return report;
}

#pragma mark - The label itself

// If this fails, the formatting string never reaches the label's attributed text and no
// amount of operation wiring can put it on screen.
- (void)testFormattingPageMessageReachesTheLabel {
	MADRecordingLabelStatus *label = [[MADRecordingLabelStatus alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];

	[label updateRefreshStarted];
	[self runMainLoopFor:0.25];
	XCTAssertTrue([self history:label.displayHistory containsSubstring:@"Refreshing…"],
				  @"the label never displayed the refresh phase");

	[label updateRecordsReadStatusWithNumberOfPagesFormatted:@7];
	[self runMainLoopFor:0.25];

	NSLog(@"%@", [self transcriptForLabel:label formattedPageCount:1]);

	NSString *displayed = label.displayHistory.lastObject;
	XCTAssertNotNil(displayed, @"the label was never given attributed text");
	XCTAssertTrue([displayed containsString:@"Formatting page 7."],
				  @"the label displayed '%@', not the formatting message", displayed);
}

#pragma mark - The reload operation's hand-off

// Drives the real MADRefreshOperationReload against a document that posts the format
// notifications, with a viewer stand-in that forwards them to a real label exactly the way
// MADViewerController does.
- (void)testReloadOperationDeliversFormattingPagesToTheLabel {
	MADTestReloadDocument *document = [self newReloadDocumentWithPages:40];
	MADRecordingLabelStatus *label = [[MADRecordingLabelStatus alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
	MADRecordingStatusViewController *viewer = [[MADRecordingStatusViewController alloc] init];
	viewer.label = label;

	MADRefreshOperationReload *reload = [[MADRefreshOperationReload alloc] initWithDocument:document
																			viewController:viewer];
	// MADOperationQueue, not a bare NSOperationQueue: MADOperation only leaves its
	// Initialized state (and so only becomes -isReady) on -willEnqueue, which the
	// MADOperationQueue sends.  This is the queue class the viewer's refreshQueue is.
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	[queue addOperation:reload];

	[self waitForOperation:reload timeout:10.0];
	// Let the reload's last dispatches land: -updatePages: is queued after the format,
	// and the label's write is one more main-queue hop behind that.
	[self runMainLoopFor:0.25];

	NSLog(@"%@", [self transcriptForLabel:label formattedPageCount:viewer.formattedPages.count]);

	XCTAssertTrue(reload.isFinished, @"the reload operation did not finish within 10 s");
	XCTAssertGreaterThan(document.formatCallCount, (NSUInteger)0,
						 @"the reload operation never formatted the document");
	XCTAssertTrue(viewer.sawFormattingBegin, @"the formatting phase was never announced");
	XCTAssertTrue([self history:label.displayHistory containsSubstring:@"Formatting…"],
				  @"the label never displayed the formatting phase");
	XCTAssertGreaterThan(viewer.formattedPages.count, (NSUInteger)0,
						 @"no didFormatPage: reached the viewer stand-in");
	XCTAssertTrue([self history:label.displayHistory containsSubstring:@"Formatting page"],
				  @"the label never displayed a formatting message");
	XCTAssertTrue([self history:label.displayHistory containsSubstring:@"Read 1,234 records."],
				  @"the label never displayed the records count");
	// The first line is the label's initial placeholder, never given a time string here.
	XCTAssertEqualObjects(label.displayHistory.lastObject, @" \nRead 1,234 records.\nPage 1 of 40 pages.",
						  @"the label's final state is not the records count over the page position");
	XCTAssertTrue(viewer.finishedReload, @"finishReload: was never delivered");
}

#pragma mark - Coalescing at report scale

// The app-scale case with the shape of the real thing: 9,212 pages, which the poster's
// own throttle turns into ~1,321 posts, spread over a format window, with the main run
// loop ticking as it does in the app.  The operation forwards a bounded number of
// deliveries -- newest page, floored at the label's own 10 Hz re-render rate -- rather
// than one per post, and the phase message goes out before the format starts, so the
// status line is populated for the whole window and then refined by the page numbers.
- (void)testFormattingProgressIsCoalescedAtReportScale {
	MADTestReloadDocument *document = [self newReloadDocumentWithPages:9212];
	document.testPostInterval = 0.00004;         // ~0.5 s of formatting

	MADRecordingLabelStatus *label = [[MADRecordingLabelStatus alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
	MADRecordingStatusViewController *viewer = [[MADRecordingStatusViewController alloc] init];
	viewer.label = label;

	MADRefreshOperationReload *reload = [[MADRefreshOperationReload alloc] initWithDocument:document
																			viewController:viewer];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];

	MADMainThreadHeartbeat *heartbeat = [[MADMainThreadHeartbeat alloc] init];
	[heartbeat start];
	[queue addOperation:reload];
	[self waitForOperation:reload timeout:30.0];
	[self runMainLoopFor:0.25];
	[heartbeat stop];

	NSLog(@"%@", [self transcriptForLabel:label formattedPageCount:viewer.formattedPages.count]);
	NSLog(@"main-thread heartbeats during the format: %lu", (unsigned long)heartbeat.beats);

	XCTAssertTrue(reload.isFinished, @"the reload operation did not finish");

	// The poster's throttle made ~1,321 posts out of 9,212 pages; the operation must
	// coalesce them to one per delivery interval, not forward them one for one.
	XCTAssertLessThan(viewer.formattedPages.count, (NSUInteger)64,
					  @"the formatting progress was delivered one-for-one (no coalescing)");
	XCTAssertGreaterThanOrEqual(viewer.formattedPages.count, (NSUInteger)2,
								@"the formatting progress was not delivered at all");
	// What lands is the newest page, not a stale one.
	XCTAssertGreaterThan(viewer.formattedPages.lastObject.unsignedIntegerValue, (NSUInteger)1000,
						 @"the delivered formatting progress is stale");

	// The run loop kept beating -- the difference between the label being set and the
	// label being shown.
	XCTAssertGreaterThanOrEqual(heartbeat.beats, (NSUInteger)5,
								@"the main run loop was starved during the format");

	// The phase message is the first thing on the line, before any page number: the
	// status line is populated from the start of the format, not from the first post.
	NSUInteger phaseIndex = [label.displayHistory indexOfObjectPassingTest:^BOOL(NSString *displayed, NSUInteger __unused idx, BOOL * __unused stop) {
		return [displayed containsString:@"Formatting…"];
	}];
	NSUInteger pageIndex = [label.displayHistory indexOfObjectPassingTest:^BOOL(NSString *displayed, NSUInteger __unused idx, BOOL * __unused stop) {
		return [displayed containsString:@"Formatting page"];
	}];
	XCTAssertNotEqual(phaseIndex, (NSUInteger)NSNotFound, @"the formatting phase never displayed");
	XCTAssertNotEqual(pageIndex, (NSUInteger)NSNotFound, @"no formatting page number displayed");
	XCTAssertLessThan(phaseIndex, pageIndex, @"the page numbers preceded the phase message");

	// The page position is still the label's last word, and the formatting deliveries
	// never land after it.
	XCTAssertEqualObjects(label.displayHistory.lastObject, @" \nRead 1,234 records.\nPage 1 of 9,212 pages.",
						  @"the label's final state is not the records count over the page position");
}

#pragma mark - Drawn, not merely set

// Renders the label's current backing store (whatever it last drew) as pixels.
- (NSData *)renderedPixelsOfView:(UIView *)view {
	UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size];
	UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
		[view.layer renderInContext:context.CGContext];
	}];
	return UIImagePNGRepresentation(image);
}

// What the user sees: the label's text is set, but the screen does not change during the
// format.  The tests above record what the label is told; this renders it.  The label goes
// in a window, gets the app's own update calls with a run loop turn between them, and the
// drawn pixels have to differ -- a label that is set but never redrawn looks exactly like
// this failing.  The last step is a control: a fresh immutable string must change the
// pixels, so a failure above cannot be blamed on the harness not rendering at all.
- (void)testFormattingProgressIsDrawnWhilePagesFormat {
	UIWindowScene *scene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;
	UIWindow *window = scene != nil ? [[UIWindow alloc] initWithWindowScene:scene]
									: [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	window.frame = CGRectMake(0, 0, 320, 44);

	MADRecordingLabelStatus *label = [[MADRecordingLabelStatus alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
	[window addSubview:label];
	[window makeKeyAndVisible];
	[self runMainLoopFor:0.2];

	[label updateRecordsReadStatusWithNumberOfPagesFormatted:@1];
	[self runMainLoopFor:0.2];
	NSData *firstPage = [self renderedPixelsOfView:label];

	[label updateRecordsReadStatusWithNumberOfPagesFormatted:@2];
	[self runMainLoopFor:0.2];
	NSData *secondPage = [self renderedPixelsOfView:label];

	label.attributedText = [[NSAttributedString alloc] initWithString:@"control"];
	[self runMainLoopFor:0.2];
	NSData *control = [self renderedPixelsOfView:label];

	window.hidden = YES;

	XCTAssertNotNil(firstPage, @"nothing rendered");
	XCTAssertNotEqualObjects(firstPage, control, @"the harness cannot see label redraws at all");
	XCTAssertNotEqualObjects(firstPage, secondPage,
							 @"the formatting page update was set but never drawn");
}

@end
