//
//  MADRefreshOperationReload.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADRefreshOperationReload.h"

#import "MADOperationRefreshReloadProtocol.h"
#import "MADOperationRefresh.h"
#import "madlog.h"

#import <MAD/MADocument.h>
#import <MAD/MADNotificationDidFormatPage.h>
#import <MAD/MADReportFormatter.h>

@interface MADRefreshOperationReload ()

@property (nonatomic, weak) MADocument *document;
@property (nonatomic, weak) NSObject <MADOperationRefreshReloadProtocol> *viewController;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;
@property (nonatomic, strong) NSOperationQueue *messageQueue;
// Coalescing state for the per-page formatting progress.  Every access is under
// @synchronized(self): posts arrive on the formatting thread while deliveries run on
// the main queue.
@property (nonatomic, strong) NSNumber *latestFormattedPage;
@property (nonatomic, strong) NSDate *lastFormattingProgressDate;
@property (nonatomic, assign) BOOL formattingDeliveryScheduled;
@property (nonatomic, assign) BOOL formattingProgressEnded;

@end

@implementation MADRefreshOperationReload

// The format posts a page at every throttled page break -- 1,321 posts for the
// 9,212-page sample report -- and each delivery costs the main thread a number
// format, a string build and a label re-render.  Forwarding every one kept the
// main run loop too busy to commit a frame for the whole format, so the status
// label showed nothing until the page position landed.  Only the newest page
// matters, so posts coalesce (last one wins) and deliveries are floored at the
// rate the label already re-renders at, the same 10 Hz timer behind
// -updateTimeSinceLastRefresh: (see BUGS.md, "Give the status label one
// consistent story per line").  The records path coalesces the same way in
// MADOperationRefreshReload -updateNumberOfRecords:.
static const NSTimeInterval MADFormattingProgressMinimumInterval = 0.1;

// The portable store context is main-queue-owned.  Marshal store reads onto
// the main queue (inline when already there) rather than taking a lock in
// every accessor.  See BUGS.md "The refresh path reads the shared store
// context from operation-queue threads".
static void MADRefreshOperationReloadRunOnMain(dispatch_block_t block) {
	if ([NSThread isMainThread]) block();
	else dispatch_sync(dispatch_get_main_queue(), block);
}

- (instancetype)initWithDocument: (MADocument *)document
				  viewController: (NSObject <MADOperationRefreshReloadProtocol> *)viewController {
	if (self = [super init]) {
		_document = document;
		_viewController = viewController;
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];
		queue.maxConcurrentOperationCount = 1;
		self.messageQueue = queue;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) return [self finish];
	
	MADRefreshOperationReload * __weak weakself = self;
	MADocument *document = _document;
	
	NSBlockOperation *updateRecordsRead = [NSBlockOperation blockOperationWithBlock:^{
		MADRefreshOperationReload * __strong sself = weakself;
		if (sself) {
			[sself.viewController operation:sself updateRecordsRead:document.numberOfResults];
		}
	}];
	NSArray <__kindof NSOperation *> *operations = @[updateRecordsRead];
	[[NSOperationQueue mainQueue] addOperations: operations waitUntilFinished: NO];
	
	
	if (self.cancelled) return [self finish];

	// -readCurrentSortDescriptors walks the store (document -> query -> sort
	// descriptors), so it runs on main like the rest of the refresh path's
	// store reads.
	MADRefreshOperationReloadRunOnMain(^{
		[document prepareForQuery];
	});

	if (self.cancelled) {
		return [self finish];
	}
	
	[self watchFormatter: document.reportFormatter];

	// The status line changes to the formatting phase before the format starts, not when
	// the first page posts: the formatter can spend seconds fetching its layout and rows
	// before the first page break, and that window has to show the phase rather than the
	// previous refresh's page position.
	NSObject <MADOperationRefreshReloadProtocol> *viewController = self.viewController;
	[viewController operationDidBeginFormatting:self];

	NSUInteger indexDependencyRefresh = [self.dependencies indexOfObjectPassingTest:^BOOL(NSOperation * _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
		return [obj isKindOfClass:[MADOperationRefresh class]];
	}];
	
	if (indexDependencyRefresh == NSNotFound) {
		[document format];
	} else {
		// The refresh operation set document.refreshed, which lands didRefresh on
		// whatever formatter the document held at that moment.  The formatter is
		// not a stable instance (-activeDocumentModel nils it on first access and
		// the initialize step replaces it), so re-assert the flag on the formatter
		// that is about to format -- otherwise a recreated formatter reloads the
		// old layout from the index cache and the format is skipped entirely.
		document.reportFormatter.didRefresh = YES;
		[document formatContentChange];
	}

	[self ignoreFormatter: document.reportFormatter];

	// The format is over.  Retire the formatting progress before the page position is
	// dispatched below: a delivery the throttle has parked would otherwise be able to
	// land after -updatePages: and leave "Formatting page N." as the label's last word.
	@synchronized (self) {
		self.formattingProgressEnded = YES;
	}

	if (self.cancelled) {
		os_log_debug(OS_LOG_DEFAULT, "%s: CANCELLED after format -- finishing without the UI updates",
					 __PRETTY_FUNCTION__);
		return [self finish];
	}

	os_log_debug(OS_LOG_DEFAULT, "%s: format done, dispatching updatePages/finishReload",
				 __PRETTY_FUNCTION__);
	MADRefreshOperationReload * __strong sself = weakself;
	if (sself) {
		dispatch_async(dispatch_get_main_queue(), ^{
			// The flush comes first, in this same dispatch: the label's own hop puts the
			// "Formatting page N." write ahead of the page position -updatePages: queues,
			// so the position is still the last word.
			[sself flushFormattingProgress];
			NSObject <MADOperationRefreshReloadProtocol> *viewController = sself.viewController;
			[viewController operation:sself updatePages:document.numberOfPages];
			[viewController operation:nil finishReload:document];
		});
	}

	document.refreshed = NO;

	[self finish];
}

#pragma mark -
#pragma mark Report Notifications Setup

- (void)watchFormatter:(MADReportFormatter *)formatter {
	os_log_debug(OS_LOG_DEFAULT, "%s: watching formatter=%p", __PRETTY_FUNCTION__, formatter);
	// Observe without an object filter.  The document's formatter is not a stable
	// instance: -activeDocumentModel (reached through -prepareForQuery) calls
	// -resetReportFormatter, and the refresh's initialize step replaces it with a
	// fresh one, so a watch keyed to the instance can end up listening to a
	// formatter that is no longer the one that formats -- the page-count updates
	// then never arrive even though the format runs.  The reload operation only
	// ever cares about its own document's format, so the unfiltered observation
	// cannot pick up anything it should ignore.
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(reportFormatterDidFormatPage:)
												 name: MADNotificationDidFormatPagesName
											   object: nil];
}

- (void)ignoreFormatter:(MADReportFormatter *)formatter {
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationDidFormatPagesName
												  object: nil];
}

#pragma mark -
#pragma mark Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
	NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
	@synchronized (self) {
		if (self.formattingProgressEnded) {
			return;
		}
		self.latestFormattedPage = pageNumber;
		if (self.formattingDeliveryScheduled) {
			return;
		}
		self.formattingDeliveryScheduled = YES;
	}
	[self scheduleFormattingDelivery];
}

- (void)scheduleFormattingDelivery {
	NSDate *lastDelivery = nil;
	@synchronized (self) {
		lastDelivery = self.lastFormattingProgressDate;
	}

	NSTimeInterval delay = 0.0;
	if (lastDelivery != nil) {
		NSTimeInterval sinceLastDelivery = -lastDelivery.timeIntervalSinceNow;
		if (sinceLastDelivery < MADFormattingProgressMinimumInterval) {
			delay = MADFormattingProgressMinimumInterval - sinceLastDelivery;
		}
	}

	MADRefreshOperationReload * __weak weakself = self;
	dispatch_block_t deliver = ^{ [weakself deliverFormattingProgress]; };
	if (delay > 0.0) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
					   dispatch_get_main_queue(), deliver);
	} else {
		dispatch_async(dispatch_get_main_queue(), deliver);
	}
}

- (void)deliverFormattingProgress {
	NSNumber *pageNumber = nil;
	@synchronized (self) {
		pageNumber = self.latestFormattedPage;
		self.formattingDeliveryScheduled = NO;
		if (pageNumber == nil || self.formattingProgressEnded) {
			// The format has ended: leave the page to -flushFormattingProgress, which
			// runs ahead of the page position and is the delivery that counts.
			return;
		}
		self.latestFormattedPage = nil;
		self.lastFormattingProgressDate = [NSDate date];
	}
	[self deliverPageNumber:pageNumber];
}

// The format is over: send the newest page that never got out, so the label was told
// about the formatting progress at least once and the page position that follows in
// the same dispatch is still the last word.  Runs on the main queue, before
// -updatePages:, which is what keeps that order.
- (void)flushFormattingProgress {
	NSNumber *pageNumber = nil;
	@synchronized (self) {
		pageNumber = self.latestFormattedPage;
		self.latestFormattedPage = nil;
		self.formattingDeliveryScheduled = NO;
	}
	if (pageNumber == nil) {
		return;
	}
	[self deliverPageNumber:pageNumber];
}

- (void)deliverPageNumber:(NSNumber *)pageNumber {
	if (self.cancelled) {
		return;
	}
	os_log_debug(OS_LOG_DEFAULT, "%s: page=%@ thread=%@", __PRETTY_FUNCTION__,
				 pageNumber, NSThread.currentThread.description);

	// The viewer's -operation:didFormatPage: reads the page number out of the
	// notification's userInfo, so the coalesced page travels in a notification of the
	// same shape the formatter posts.  Only the operation's own viewer sees this one:
	// the real posts still go out from MADNotificationDidFormatPage to whatever else
	// observes them (the PDF export path, for one).
	NSDictionary *parameters = @{ MTDatabaseNumberOfPagesFormattedKey: pageNumber };
	NSNotification *notification = [NSNotification notificationWithName: MADNotificationDidFormatPagesName
																object: nil
															  userInfo: parameters];
	NSObject <MADOperationRefreshReloadProtocol> *viewController = self.viewController;
	[viewController operation:self didFormatPage:notification];
}

@end
