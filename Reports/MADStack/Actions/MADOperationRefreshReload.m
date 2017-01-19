//
//  MADRefreshReloadOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationRefreshReload.h"
#import <Foundation/NSArray.h>
#import <MAD/MADCredential.h>
#import <MAD/MADocument.h>
#import <MAD/MADDatabaseConnection.h>

#import "MADGetCredentialsOperation.h"
#import "MADOperationRefreshInitalizeMainDataTable.h"
#import "MADOperationRefreshInitialize.h"
#import "MADOperationRefresh.h"
#import "MADOperationQueue.h"

@interface MADOperationRefreshReload ()

    @property (nonatomic, readwrite, weak) MADocument *document;
    @property (nonatomic, readwrite, strong) MADGetCredentialsOperation *getCredentials;
    @property (nonatomic, readwrite, assign) BOOL completedSuccessfully;

@end

@implementation MADOperationRefreshReload

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
}

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    MADGetCredentialsOperation *getCredentials = self.getCredentials;
    if (getCredentials.gotCredentials) {
        MADCredential *c = getCredentials.credentials.copy;
        return c;
    } else {
        return nil;
    }
}

- (instancetype)initWithDocument: (MADocument *)document
                  viewController: (UIViewController *)viewController
              databaseConnection: (MADDatabaseConnection *)databaseConnection {

    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    if (self = [super init]) {

        MADGetCredentialsOperation *getCredentials;
        getCredentials= [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                        viewController: viewController];
        self.getCredentials = getCredentials;
        
        _document = document;
        _completedSuccessfully = NO;

    }
    return self;
}

- (void)execute {
    [self addAllOperations];
    [self.internalQueue addOperation:self.finishingOperation];
    self.internalQueue.suspended = NO;
}

- (void)addAllOperations {

    MADocument *document = _document;
    MADOperationRefreshInitializeMainDataTable *initializeMainDataTable = [[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument:document];
    [initializeMainDataTable addDependency:self.getCredentials];
    
    MADOperationRefreshInitialize *initialize = [[MADOperationRefreshInitialize alloc] initWithDocument:document];
    [initialize addDependency: initializeMainDataTable];
    [initialize addDependency: self.getCredentials];
    
    MADOperationRefresh *refresh = [[MADOperationRefresh alloc] initWithDocument:document];
    [refresh addDependency: initializeMainDataTable];
    [refresh addDependency: self.getCredentials];
    [refresh addDependency: initialize];
    
    NSArray <__kindof NSOperation *> *operations = [[NSArray alloc] initWithObjects: self.getCredentials, initializeMainDataTable, initialize, refresh, nil];
        
    MADOperationRefreshReload * __weak wself = self;
    NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADOperationRefreshReload *sself = wself;
        sself.completedSuccessfully = YES;
        [sself finish];
    }];
    
    [self addOperations:operations finishingOperation:finishingOperation];
    self.internalQueue.suspended = NO;
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    //if ([operation isKindOfClass:[MADOperationRefresh class]]) {
    //    [self finish];
    //}
}

@end
