//
//  MADRefreshReloadOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationRefreshReload.h"
#import <os/log.h>
#import <Foundation/NSArray.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperationQueue.h>

#import <MADAPI/MADNotificationDidReadRows.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MAD/MADocument.h>

#import "MADOperationGetCredentials.h"
#import "MADOperationRefreshInitalizeMainDataTable.h"
#import "MADOperationRefreshInitialize.h"
#import "MADOperationRefresh.h"
#import "MADRefreshOperationReload.h"
#import "MADOperationRefreshReloadProtocol.h"

@interface MADOperationRefreshReload ()

    @property (nonatomic, readwrite, weak) MADocument *document;
    @property (nonatomic, readwrite, strong) MADOperationGetCredentials *getCredentials;
    @property (nonatomic, readwrite, assign) BOOL completedSuccessfully;
    @property (nonatomic, readwrite, strong) id /* UIViewController * */ <MADOperationRefreshReloadProtocol> viewController;
    @property (nonatomic, readwrite, strong) MADDatabaseConnection *databaseConnection;

    @property (nonatomic, strong) NSOperationQueue *messageQueue;

@end

@implementation MADOperationRefreshReload {
    NSUInteger _skipCount, _displayCount;
}

- (void)dealloc { }

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    MADOperationGetCredentials *getCredentials = self.getCredentials;
    if (getCredentials.gotCredentials) {
        MADCredential *c = getCredentials.credentials.copy;
        return c;
    } else {
        return nil;
    }
}

- (instancetype)initWithDocument: (MADocument *)document
                  viewController: (UIViewController <MADOperationRefreshReloadProtocol> *)viewController
              databaseConnection: (MADDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        _skipCount = 0, _displayCount = 0;
        _databaseConnection = databaseConnection;
        _viewController = viewController;
        _document = document;
        _completedSuccessfully = NO;
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        self.messageQueue = queue;
    }
    return self;
}

- (void)execute {
    
    if (self.cancelled) {
        return [self finish];
    }

    MADOperationGetCredentials *getCredentials;
    getCredentials= [[MADOperationGetCredentials alloc] initWithDatabaseConnection: _databaseConnection
                                                                    viewController: (UIViewController *)_viewController];
    MADocument *document = _document;
    
    
    MADOperationRefreshInitializeMainDataTable *initializeMainDataTable;
    initializeMainDataTable = [[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument:document];
    [initializeMainDataTable addDependency: getCredentials];
    
    MADOperationRefreshInitialize *initialize;
    initialize = [[MADOperationRefreshInitialize alloc] initWithDocument:document];
    [initialize addDependency: initializeMainDataTable];
    [initialize addDependency: getCredentials];
    
    MADOperationRefresh *refresh = [[MADOperationRefresh alloc] initWithDocument:document];
    [refresh addDependency: initializeMainDataTable];
    [refresh addDependency: getCredentials];
    [refresh addDependency: initialize];
    
    MADRefreshOperationReload *reload = [[MADRefreshOperationReload alloc] initWithDocument: document
                                                                             viewController: (NSObject <MADOperationRefreshReloadProtocol> *)_viewController];
    [reload addDependency:refresh];
    
    NSArray <__kindof NSOperation *> *operations;
    operations = [[NSArray alloc] initWithObjects: getCredentials,
                                                   initializeMainDataTable,
                                                   initialize,
                                                   reload,
                                                   refresh, nil];
        
    MADOperationRefreshReload * __weak wself = self;
    NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADOperationRefreshReload *sself = wself;
        MADocument *sdocument = sself.document;
        [sself ignoreDatabase:sdocument.database];
        [sself updateNumberOfRecords:sdocument.numberOfResults];
        sself.viewController = nil;
        sself.databaseConnection = nil;
        sself.completedSuccessfully = YES;
        [sself.messageQueue cancelAllOperations];
        sself.messageQueue = nil;
        [sself finish];
    }];
    
    [self watchDatabase:document.database];
    
    [self addOperations:operations finishingOperation:finishingOperation];

    self.getCredentials = getCredentials;

    [super execute];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
    [self updateNumberOfRecords:rowNumber.unsignedIntegerValue];
}

- (void)updateNumberOfRecords:(NSUInteger)numberOfRecords {
    if (self.messageQueue.operationCount < 2) {
        typeof(self) __weak weakself = self;
        [self.messageQueue addOperationWithBlock:^{
            NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
                typeof(self) sself = weakself;
                [sself.viewController operation:sself updateRecordsRead:numberOfRecords];
            }];
            NSArray *ops = @[op];
            [[NSOperationQueue mainQueue] addOperations:ops waitUntilFinished:YES];
            usleep((useconds_t)floor((1/11)*1000)); //delay updates... 1/11th of a second
        }];
    }
    
}

- (void)watchDatabase:(MADDatabase *)database {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reportDocumentDidReadRows:)
                                                 name: MADNotificationDidReadRowsName
                                               object: database];
}

- (void)ignoreDatabase:(MADDatabase *)database {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADNotificationDidReadRowsName
                                                  object: database];
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors { }

@end
