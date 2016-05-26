//
//  MADRefreshReloadOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshReloadOperation.h"
#import <Foundation/NSArray.h>
#import <MAD/MADCredential.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabaseConnection.h>

#import "MADGetCredentialsOperation.h"
#import "MADRefreshOperationInitalizeMainDataTable.h"
#import "MADRefreshOperationInitalize.h"
#import "MADRefreshOperation.h"
#import "MADOperationQueue.h"

@interface MADRefreshReloadOperation ()

    @property (nonatomic, readwrite, weak) MADocument *document;
    @property (nonatomic, readwrite, strong) MADGetCredentialsOperation *getCredentials;
    @property (nonatomic, readwrite, assign) bool completedSuccessfully;

@end

@implementation MADRefreshReloadOperation

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    MADGetCredentialsOperation *getCredentials = self.getCredentials;
    if (getCredentials.gotCredentials) {
        MADCredential *c = getCredentials.credentials.copy;
        return c;
    } else {
        return nil;
    }
}

- (instancetype)initWithDocument: (MADocument *)document viewController:(UIViewController *)viewController
              databaseConnection: (MTDatabaseConnection *)databaseConnection {

    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    if (self = [super init]) {

        MADGetCredentialsOperation *getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                     viewController: viewController];
        self.getCredentials = getCredentials;
        
        _document = document;
        _completedSuccessfully = false;

    }
    return self;
}

- (void)execute {
    [self addAllOperations];
    self.internalQueue.suspended = NO;
    [self.internalQueue addOperation:self.finishingOperation];
}

- (void)addAllOperations {

    MADocument *document = _document;
    MADRefreshOperationInitalizeMainDataTable *initializeMainDataTable = [[MADRefreshOperationInitalizeMainDataTable alloc] initWithDocument:document];
    [initializeMainDataTable addDependency:self.getCredentials];
    
    MADRefreshOperationInitalize *initialize = [[MADRefreshOperationInitalize alloc] initWithDocument:document];
    [initialize addDependency: initializeMainDataTable];
    [initialize addDependency: self.getCredentials];
    
    MADRefreshOperation *refresh = [[MADRefreshOperation alloc] initWithDocument:document];
    [refresh addDependency: initializeMainDataTable];
    [refresh addDependency: self.getCredentials];
    [refresh addDependency: initialize];
    
    NSArray <__kindof NSOperation *> *operations = [[NSArray alloc] initWithObjects: self.getCredentials, initializeMainDataTable, initialize, refresh, nil];
        
    MADRefreshReloadOperation * __weak wself = self;
    NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADRefreshReloadOperation *sself = wself;
        sself.completedSuccessfully = true;
        [sself finish];
    }];
    
    [self addOperations:operations finishingOperation:finishingOperation];
    self.internalQueue.suspended = NO;
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    //if ([operation isKindOfClass:[MADRefreshOperation class]]) {
    //    [self finish];
    //}
}

@end
