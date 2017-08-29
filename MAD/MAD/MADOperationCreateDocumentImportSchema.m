//
//  MADOperationCreateDocumentAddConnection.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentImportSchema.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
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

#import <os/log.h>

@interface MADOperationCreateDocumentImportSchema ()

    @property (nonatomic, assign, readwrite, getter=isSuccess) BOOL success;
    @property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentImportSchema {
    NSError *_displayError;
    NSUInteger _tag;
}

- (void)dealloc {
    //os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)init {
    return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection.copy;
        self.success = NO;
        _displayError = nil;
        _tag = self.hash;
    }
    return self;
}

#pragma mark -
#pragma mark MADOperationPromptErrorProtocol

- (BOOL)displayError {
    return _displayError != nil;
}

- (NSError *)error {
    return _displayError;
}

- (NSUInteger)tag {
    return _tag;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    //os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    if (self.cancelled) return [self finish];

    MADocument * document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
            document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }
    
    if (self.cancelled) return [self finish];

    BOOL __block success = NO;
    NSError __block * displayError = nil;
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;
    //MADocument * __weak weakdoc = document;
    
    MADOperationCreateDocumentImportSchema * __weak weakself = self;
    [private performBlockAndWait:^{
        MADOperationCreateDocumentImportSchema *strongself = weakself;

        //MADocument *doc = weakdoc;
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        
        [rptqDocument storeDatabaseConnectionDefination:document.database forManagedObjectContext:private];
        
        MADErrorContainer *errorContainer = [MADErrorContainer new];
        NSError * __autoreleasing dberror = nil;
        id dbconnection = [document.database connectWithConnection: document.database.databaseConnection
                                                        credentals: nil
                                                   connectionError: &dberror];
        
        if (dberror != nil) {
            success = NO;
            displayError = [dberror copy];
            return;
        }
        NSMutableDictionary *tablesAndFields   = [[NSMutableDictionary alloc] init];
        NSMutableArray *tables                 = [[NSMutableArray alloc] init];
        
        NSError *error = NULL;
        NSArray *resultTables = [document.database getTablesFromConnection:dbconnection
                                                                     error:&error];
        
        if (error != nil) {
            success = NO;
            displayError = error.copy;
            return;
        }
        
        [tables setArray:resultTables];
        
        NSUInteger counter = 0, numberOfTables = tables.count;
        for (MADDatabaseTable *databaseTable in tables) {
            @autoreleasepool {
                
                NSString *name = databaseTable.name.copy;
                [strongself.parentOperation updateImportProgressWithMessage: name
                                                                   progress: (counter + 1) / numberOfTables];
                
                NSError *getFieldsError = NULL;
                NSArray *fieldsForTable = [document.database fieldsForTable: databaseTable.name
                                                                 connection: dbconnection
                                                                      error: &getFieldsError];
                
                NSArray *fields = [[NSArray alloc] initWithArray:fieldsForTable];
                tablesAndFields[databaseTable.name] = fields;
                
            }
            counter++;
        }
        
        MADErrorContainer *additionalErrors;
        additionalErrors = [rptqDocument storeTablesAndFieldsForTables: tables
                                                         fieldsByTable: tablesAndFields
                                               andManagedObjectContext: private];
        [errorContainer addErrorsFromContainer:additionalErrors];
        
        
        
        [document.database closeConnection:dbconnection];
        
        success = YES;
        
        NSError * __autoreleasing saveError = nil;
        if (success) {
            if (!(success = [private save:&saveError])) {
                os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", saveError.localizedDescription.UTF8String);
            }
            if (saveError) {
                displayError = [saveError copy];
            }
        } else {
            if (!(success = [private save:&saveError])) {
                os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", saveError.localizedDescription.UTF8String);
            }
        }

    }];
    [document updateChangeCount:UIDocumentChangeDone];
    _success = success;
    if (_success) {
        [self finish];
    } else {
        [self finishWithError:displayError];
    }
}

- (void)finishWithError:(NSError *)error {
    _displayError = error.copy;
    [super finishWithError:error];
}

@end
