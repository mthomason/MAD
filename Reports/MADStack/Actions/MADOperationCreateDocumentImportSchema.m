//
//  MADOperationCreateDocumentAddConnection.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentImportSchema.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDatabaseTable.h>
#import <MAD/MADDatabaseField.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADNotificationProgress.h>
#import <MAD/MADErrorContainer.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/MADDatabaseConnection.h>

#import "MADOperationCreateDocumentCreateDocument.h"

@interface MADOperationCreateDocumentImportSchema ()

    @property (nonatomic, assign) BOOL success;
    @property (nonatomic, strong) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentImportSchema

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

    BOOL __block success = NO;
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;
    MADocument * __weak weakdoc = document;
    [private performBlockAndWait:^{
        MADocument *doc = weakdoc;
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        
        [rptqDocument storeDatabaseConnectionDefination:document.database forManagedObjectContext:private];
        
        MADErrorContainer *errorContainer = [MADErrorContainer new];
        
        id dbconnection = [document.database connectWithConnection:document.database.databaseConnection credentals:nil];
        
        NSMutableDictionary *tablesAndFields   = [[NSMutableDictionary alloc] init];
        NSMutableArray *tables                 = [NSMutableArray array];
        
        NSError *error = NULL;
        NSArray *resultTables = [document.database getTablesFromConnection:dbconnection error:&error];
        
        [tables setArray:resultTables];
        
        NSUInteger counter = 0, numberOfTables = tables.count;
        for (MADDatabaseTable *databaseTable in tables) {
            @autoreleasepool {
                
                NSString *name = databaseTable.name.copy;
                [self.parentOperation updateImportProgressWithMessage:name progress:(counter + 1) / numberOfTables];
                                
                NSError *getFieldsError = NULL;
                NSArray *fieldsForTable = [document.database fieldsForTable: databaseTable.name
                                                                 connection: dbconnection
                                                                      error: &getFieldsError];
                
                NSArray *fields = [[NSArray alloc] initWithArray:fieldsForTable];
                tablesAndFields[databaseTable.name] = fields;
                
            }
            counter++;
        }
        
        MADErrorContainer *additionalErrors = [rptqDocument storeTablesAndFieldsForTables:tables fieldsByTable:tablesAndFields andManagedObjectContext:private];
        [errorContainer addErrorsFromContainer:additionalErrors];
        
        [document.database closeProcess:dbconnection];
        
        NSError *saveError = nil;
        success = [private save:&saveError];
        

    }];
    
    if (success) {
        [self finish];
    } else {
        [self finishWithError:nil];
    }
    
}

@end
