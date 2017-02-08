//
//  MADCreateDocumentOperationFirstTimeSetup.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
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
    //MADocument * __weak wdoc = document;
    [private performBlockAndWait:^{
        //MADocument *doc = wdoc;
        //RptqDocument *rptqDocument = [RptqDocument newDocumentForManagedObjectContext: private];
        //doc = rptqDocument.identifier;

        NSError *error = nil;
        [private save:&error];
    }];

    [self finish];
}


@end
