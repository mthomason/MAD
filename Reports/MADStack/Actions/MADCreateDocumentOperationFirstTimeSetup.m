//
//  MADCreateDocumentOperationFirstTimeSetup.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperationFirstTimeSetup.h"
//#import <Foundation/Foundation.h>
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDataTableFast.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/MADSectionLayoutManager.h>
#import "MADCreateDocumentOperationCreateDocument.h"

@interface MADCreateDocumentOperationFirstTimeSetup ()

    @property (nonatomic, assign) bool success;
    @property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

@end

@implementation MADCreateDocumentOperationFirstTimeSetup

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)init {
    return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection;
        self.success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    MADocument * document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADCreateDocumentOperationCreateDocumentProtocol)]) {
            document = ((id <MADCreateDocumentOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;
    MADocument * __weak wdoc = document;
    [private performBlockAndWait:^{
        MADocument *doc = wdoc;
        RptqDocument *rptqDocument = [RptqDocument newDocumentForManagedObjectContext: private];
        doc.documentObjectID = rptqDocument.objectID;

        NSError *error = nil;
        if (![private save:&error]) NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
    }];

    [self finish];
}


@end
