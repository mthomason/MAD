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

@interface MADRefreshOperationReload ()

@property (nonatomic, weak) MADocument *document;
@property (nonatomic, weak) NSObject <MADOperationRefreshReloadProtocol> *viewController;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;
@property (nonatomic, strong) NSOperationQueue *messageQueue;

@end

@implementation MADRefreshOperationReload

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
	NSUInteger indexDependencyRefresh = [self.dependencies indexOfObjectPassingTest:^BOOL(NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		return [obj isKindOfClass:[MADOperationRefresh class]];
	}];
	
	if (indexDependencyRefresh == NSNotFound) {
		[document format];
	} else {
		[document formatContentChange];
	}
	
	[self ignoreFormatter: document.reportFormatter];

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
			NSObject <MADOperationRefreshReloadProtocol> *viewController = sself.viewController;
			[viewController operation:sself updatePages:document.numberOfPages];
			[viewController operation:nil finishReload:document];
		});
	}

	document.refreshed = NO;

	[self finish];
}

- (void)updateNumberOfPages:(NSUInteger)numberOfPages {
	MADRefreshOperationReload * __weak weakself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		MADRefreshOperationReload * __strong sself = weakself;
		if (sself) {
			[sself.viewController operation:sself updatePages:numberOfPages];
		}
	});
}

#pragma mark -
#pragma mark Report Notifications Setup

- (void)watchFormatter:(MADReportFormatter *)formatter {
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(reportFormatterDidFormatPage:)
												 name: MADNotificationDidFormatPagesName
											   object: formatter];
}

- (void)ignoreFormatter:(MADReportFormatter *)formatter {
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationDidFormatPagesName
												  object: formatter];
}

#pragma mark -
#pragma mark Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
	NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
	[self updateNumberOfPages: pageNumber.unsignedIntegerValue];
}

@end
