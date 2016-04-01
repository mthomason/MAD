//
//  MADCreateDocumentOperationAddConnection.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperationImportSchema.h"

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADNotificationProgress.h>
#import <MAD/MADErrorContainer.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import "MADCreateDocumentOperationCreateDocument.h"

@interface MADCreateDocumentOperationImportSchema ()

    @property (nonatomic, assign) bool success;
    @property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

@end

@implementation MADCreateDocumentOperationImportSchema

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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADocument *document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADCreateDocumentOperationCreateDocumentProtocol)]) {
            document = ((id <MADCreateDocumentOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }

    RptqDocument *rptqDocument = [RptqDocument documentForManagedObjectContext: document.managedObjectContext];
    
    MTDatabase *database = [MTDatabase newDatabaseWithConnection:self.databaseConnection];
        document.mainDatabase = database;
        
    [rptqDocument addDatabase: document.mainDatabase forManagedObjectContext:document.managedObjectContext status: ^(NSString *message, float progress) {
        NSLog(@"%@ - %f", message, progress);
    } completion:^(BOOL success, MADErrorContainer *errorContainer) {
        if (success) {
          [self finish];
        } else {
            NSArray *errors = errorContainer.allObjects.copy;
            [self finishWithError:errors.lastObject];
        }
    }];
    
    
}

@end
