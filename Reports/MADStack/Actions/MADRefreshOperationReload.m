//
//  MADRefreshOperationReload.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationReload.h"
#import <os/log.h>
#import "UIApplication+Extras.h"

#import <MAD/MADocument.h>
#import <MAD/MADPrintPageRenderer.h>
#import <MAD/MADNotificationDidFormatPage.h>
#import <MAD/MADNotificationDidReadRows.h>
#import "MADDocumentPageController.h"
#import "MADPageViewAttributes.h"

#import "MADOperationRefreshReloadProtocol.h"


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
    
    // Update number of pages.
    [self updateNumberOfPages:document.numberOfPages];
    
    // Update records read.
    NSBlockOperation *updateRecordsRead = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:sself updateRecordsRead:document.numberOfResults];
    }];
    NSArray <__kindof NSOperation *> *operations = @[updateRecordsRead];
    [[NSOperationQueue mainQueue] addOperations: operations
                              waitUntilFinished: NO];


    if (self.cancelled) return [self finish];

    [self beginBackgroundTask];

    NSBlockOperation *setDisplayInactive = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:sself setDisplayActive:NO];
    }];
    operations = @[setDisplayInactive];
    [[NSOperationQueue mainQueue] addOperations: operations
                              waitUntilFinished: NO];

    
    [document prepareForQuery];
    
    if (self.cancelled) {
        [self endBackgroundTask];
        return [self finish];
    }

    
    [self watchFormatter: document.reportFormatter];
    
    [document format];

    [self ignoreFormatter: document.reportFormatter];

    if (self.cancelled) {
        [self endBackgroundTask];
        return [self finish];
    }
    
    NSBlockOperation *finishReload = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:nil finishReload:document];
    }];
    updateRecordsRead = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:sself updatePages:document.numberOfPages];
    }];
    operations = @[updateRecordsRead, finishReload];
    [[NSOperationQueue mainQueue] addOperations: operations
                              waitUntilFinished: YES];
    
    
    document.refreshed = NO;

    [self endBackgroundTask];
    [self finish];
}

- (void)beginBackgroundTask {
    if (self.backgroundTaskIdRefresh == UIBackgroundTaskInvalid) {
        self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    }
}

- (void)endBackgroundTask {
    if (_backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
        
        NSNumber *bgtask;
        bgtask = [[NSNumber alloc] initWithUnsignedInteger: self.backgroundTaskIdRefresh];
        _backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
        [[UIApplication sharedApplication] handoffBackground:bgtask];
    }
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
