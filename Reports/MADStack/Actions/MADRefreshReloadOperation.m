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

    @property (nonatomic, readwrite, strong) MADGetCredentialsOperation *getCredentials;
    @property (nonatomic, readwrite, assign) bool completedSuccessfully;
    @property (nonatomic, readwrite, weak) MADocument *document;

@end

@implementation MADRefreshReloadOperation

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    if (self.getCredentials.gotCredentials) {
        MADCredential * __autoreleasing c = self.getCredentials.credentials.copy;
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

    [super execute];
}

- (void)addAllOperations {

    MADocument *document = _document;
    MADRefreshOperationInitalizeMainDataTable *initalizeMainDataTable = [[MADRefreshOperationInitalizeMainDataTable alloc] initWithDocument:document];
    [initalizeMainDataTable addDependency:self.getCredentials];
    
    MADRefreshOperationInitalize *initalize = [[MADRefreshOperationInitalize alloc] initWithDocument:document];
    [initalize addDependency: initalizeMainDataTable];
    [initalize addDependency: self.getCredentials];
    
    MADRefreshOperation *refresh = [[MADRefreshOperation alloc] initWithDocument:document];
    [refresh addDependency: initalizeMainDataTable];
    [refresh addDependency: self.getCredentials];
    [refresh addDependency: initalize];
    
    NSArray <__kindof NSOperation *> *operations = @[self.getCredentials, initalizeMainDataTable, initalize, refresh];
        
    MADGroupOperation * __weak wself = self;
    NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADGroupOperation *sself = wself;
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
