//
//  MADCreateDocumentOperationFirstTimeSetup.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/31/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentFirstTimeSetup.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADocument.h>
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import "MADOperationCreateDocumentCreateDocument.h"
#import <os/log.h>

@interface MADOperationCreateDocumentFirstTimeSetup ()

    @property (nonatomic, assign) BOOL success;
    @property (nonatomic, strong) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentFirstTimeSetup

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
}

- (instancetype)init {
    return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection;
        self.success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Create document first time setup:", __PRETTY_FUNCTION__);

    MADocument * document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
            document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;
    [private performBlockAndWait:^{
        BOOL success = [RptqDocument newDocumentForManagedObjectContext: private] != nil;
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Save:", __PRETTY_FUNCTION__);
        NSError *error = nil;
        if (success) {
            success = [private save:&error];
        } else {
            [private save:&error];
        }
    }];
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish:", __PRETTY_FUNCTION__);

    [self finish];
}


@end
