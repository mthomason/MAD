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
	
	typeof(self) __weak weakself = self;
	MADocument *document = _document;

	[self updateNumberOfPages:document.numberOfPages];
	
	NSBlockOperation *updateRecordsRead = [NSBlockOperation blockOperationWithBlock:^{
		typeof(self) __strong sself = weakself;
		[sself.viewController operation:sself updateRecordsRead:document.numberOfResults];
	}];
	NSArray <__kindof NSOperation *> *operations = @[updateRecordsRead];
	[[NSOperationQueue mainQueue] addOperations: operations waitUntilFinished: NO];
	
	
	if (self.cancelled) return [self finish];
	
	[document prepareForQuery];
	
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
		return [self finish];
	}
	
	NSBlockOperation *finishReload = [NSBlockOperation blockOperationWithBlock:^{
		typeof(self) __strong sself = weakself;
		[sself.viewController operation:nil finishReload:document];
	}];
	NSBlockOperation *opUpdateRecordsRead = [NSBlockOperation blockOperationWithBlock:^{
		typeof(self) __strong sself = weakself;
		[sself.viewController operation:sself updatePages:document.numberOfPages];
	}];
	[finishReload addDependency:opUpdateRecordsRead];
	
	NSArray <__kindof NSOperation *> *opsFinished = @[opUpdateRecordsRead, finishReload];
	[[NSOperationQueue mainQueue] addOperations: opsFinished waitUntilFinished: YES];
	
	document.refreshed = NO;
	
	[self finish];
}

- (void)updateNumberOfPages:(NSUInteger)numberOfPages {
	if ([NSOperationQueue mainQueue].operationCount < 2) {
		typeof(self) __weak weakself = self;
		[self.messageQueue addOperationWithBlock:^{
			NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
				typeof(self) sself = weakself;
				[sself.viewController operation:sself updatePages:numberOfPages];
			}];
			NSArray *ops = @[op];
			[[NSOperationQueue mainQueue] addOperations:ops waitUntilFinished:YES];
			usleep((useconds_t)floor((1/11)*1000)); //delay updates... 1/11th of a second
		}];
	}
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
