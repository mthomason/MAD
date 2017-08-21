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

@end

@implementation MADRefreshOperationReload

- (instancetype)initWithDocument: (MADocument *)document
                  viewController: (NSObject <MADOperationRefreshReloadProtocol> *)viewController {
    if (self = [super init]) {
        _document = document;
        _viewController = viewController;
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
    NSUInteger recordsRead = document.numberOfResults;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:sself updateRecordsRead:recordsRead];
    }];


    if (self.cancelled) return [self finish];

    [self beginBackgroundTask];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:sself setDisplayActive:NO];
    }];

    [document prepareForQuery];
    
    if (self.cancelled) {
        [self endBackgroundTask];
        return [self finish];
    }

    
    [self watchFormatter: document.reportFormatter];
    
    document.refreshed = YES;
    [document format];

    [self ignoreFormatter: document.reportFormatter];

    if (self.cancelled) {
        [self endBackgroundTask];
        return [self finish];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:nil updateRecordsRead:document.numberOfResults];
    }];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        typeof(self) __strong sself = weakself;
        [sself.viewController operation:nil finishReload:document];
    }];


    
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
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.viewController operation:self updatePages:numberOfPages];
    }];
}

- (void)updateNumberOfRecords:(NSUInteger)numberOfRecords {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.viewController operation:self updateRecordsRead:numberOfRecords];
    }];
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

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
    [self updateNumberOfRecords: rowNumber.unsignedIntegerValue];
}


@end
