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

@interface MADRefreshReloadOperation ()
    @property (nonatomic, readwrite, strong) MADGetCredentialsOperation *getCredentials;
@end

@implementation MADRefreshReloadOperation

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    if (self.getCredentials.gotCredentials) {
        MADCredential * __autoreleasing c = self.getCredentials.credentials.copy;
        return c;
    } else {
        return nil;
    }
}

- (instancetype)initWithDocument: (MADocument *)document viewController:(UIViewController *)viewController
              databaseConnection: (MTDatabaseConnection *)databaseConnection {
    if (self = [super init]) {

        MADGetCredentialsOperation *getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                     viewController: viewController];
        self.getCredentials = getCredentials;
        
        MADRefreshOperationInitalizeMainDataTable *initalizeMainDataTable = [[MADRefreshOperationInitalizeMainDataTable alloc] initWithDocument:document];
        
        
        

    }
    return self;
}

@end
