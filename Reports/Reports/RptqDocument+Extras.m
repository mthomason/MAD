//
//  NSObject+RptqDocument_Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocument+Extras.h"
#import "MTDatabaseSqlite3.h"
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqQuery.h"
#import "RptqDocumentSection+Extras.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

@implementation RptqDocument (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocument *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];

}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

- (RptqQuery *)defaultQuery {
    return [[[[self hasDatabaseSchemas] anyObject] hasQueries] anyObject];
}

#pragma mark - Static

+ (RptqDocument *)documentFactoryWithManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSString *rptqDocumentName = NSStringFromClass([RptqDocument class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: rptqDocumentName];
    
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:request error:&error];
    
    if (!error) {
        //Delete any contents of the existing object modal.
        if (documents && [documents count] > 0) {
            [documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [objectContext deleteObject: obj];
            }];
        }
    }
    NSEntityDescription *entityDescription                     = [NSEntityDescription entityForName:rptqDocumentName inManagedObjectContext: objectContext];
    RptqDocument *document                      = [[RptqDocument alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:objectContext];

    Class sectionClass = [RptqDocumentSection class];
    NSString *rptqDocumentSection = NSStringFromClass(sectionClass);
    [document setHasReportHeaderSection:          [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext]];
    [document setHasReportFooterSection:          [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext]];
    [document setHasPageHeaderSection:            [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext]];
    [document setHasPageFooterSection:            [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext]];
    [document setHasDetailSection:                [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext]];

    RptqDocumentSectionRows *headerRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                       inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows1 = [[NSOrderedSet alloc] initWithObject: headerRow];
    [[document hasReportHeaderSection] setHasRows:hasRows1];
    [headerRow setInSection:[document hasReportHeaderSection]];

    RptqDocumentSectionRows *footerRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                       inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows2 = [[NSOrderedSet alloc] initWithObject: footerRow];
    [[document hasReportFooterSection] setHasRows:hasRows2];
    [footerRow setInSection:[document hasReportFooterSection]];

    RptqDocumentSectionRows *pageHeaderRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                           inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows3 = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
    [[document hasPageHeaderSection] setHasRows:hasRows3];
    [pageHeaderRow setInSection:[document hasPageHeaderSection]];
    
    RptqDocumentSectionRows *pageFooterRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                           inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows4 = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
    [[document hasPageFooterSection] setHasRows:hasRows4];
    [pageFooterRow setInSection:[document hasPageFooterSection]];
    
    RptqDocumentSectionRows *detailSectionRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                              inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows5 = [[NSOrderedSet alloc] initWithObject: detailSectionRow];
    [[document hasDetailSection] setHasRows:hasRows5];
    [detailSectionRow setInSection:[document hasDetailSection]];
    
    [[document hasReportHeaderSection] setType:      @(MNSDocumentSectionTypeReportHeader)];
    [[document hasReportFooterSection] setType:      @(MNSDocumentSectionTypeReportFooter)];
    [[document hasPageHeaderSection] setType:        @(MNSDocumentSectionTypePageHeader)];
    [[document hasPageFooterSection] setType:        @(MNSDocumentSectionTypePageFooter)];
    [[document hasDetailSection] setType:            @(MNSDocumentSectionTypeBody)];

    [[document hasReportHeaderSection] setInterfaceHeight:44.0000f];
    [[document hasReportFooterSection] setInterfaceHeight:44.0000f];
    [[document hasPageHeaderSection] setInterfaceHeight:44.0000f];
    [[document hasPageFooterSection] setInterfaceHeight:44.0000f];
    [[document hasDetailSection] setInterfaceHeight:88.0000f];

    [[document hasReportHeaderSection] setVisibility:@YES];
    [[document hasReportFooterSection] setVisibility:@YES];
    [[document hasPageHeaderSection] setVisibility:@YES];
    [[document hasPageFooterSection] setVisibility:@YES];
    [[document hasDetailSection] setVisibility:@YES];

    return document;
}

+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    Class docClass = [RptqDocument class];
    NSString *entityName = NSStringFromClass(docClass);
    NSFetchRequest *docFetchRequest = [[NSFetchRequest alloc] initWithEntityName: entityName];
    [docFetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
    return [documents lastObject];
}

- (RptqDatabase *)databaseWithConnectionID:(NSNumber *)connectionId {
    RptqDatabase *currentDatabase = nil;
    NSInteger connectionVal = [connectionId integerValue];
    for (RptqDatabase *db in [self hasDatabaseSchemas]) {
        if ([[db identifier] integerValue] == connectionVal) {
            currentDatabase = db;
            break;
        }
    }
    return currentDatabase;
}

- (void)addDatabase:(MTDatabase *)database
             status:(void (^)(NSString *readStatus))status
         completion:(void (^)(BOOL success, NSError *error))completion {
    
    NSNumber *connectionId = @([[self hasDatabaseSchemas] count] + 1);
    RptqDatabase *rptqDatabase = [RptqDatabase createNewDatabaseForManagedObjectContext: self.managedObjectContext
                                                                             driverType: [database identifier]
                                                                           connectionId: connectionId];

    RptqUserCredentals *userCredentals = [RptqUserCredentals createNewUserCredentalsForManagedObjectContext: self.managedObjectContext];
    [userCredentals setDatabase_driver_type: [database identifier]];
    
    if ([[database identifier] isEqualToString:[MTDatabaseMySql identifier]]) {
        
        MTDatabaseConnection *connectionSettings = [database databaseConnection];
        
        if (connectionSettings != nil) {
            [[userCredentals inDatabase] setDatabaseDriverTypeEnum:@(MNSDatabaseTypeMySQL)];
            [userCredentals setMysql_host:      [connectionSettings server]];
            [userCredentals setMysql_database:  [connectionSettings database]];
            [userCredentals setMysql_port:    @([connectionSettings port])];
            [userCredentals setMysql_username:  [connectionSettings username]];
            [userCredentals setMysql_password:  [connectionSettings password]];
        }
        
    } else if ([[database identifier] isEqualToString:[MTDatabaseSqlServer identifier]]) {
        MTDatabaseConnection *connectionSettings = [database databaseConnection];
        
        if (connectionSettings != nil) {
            [[userCredentals inDatabase] setDatabaseDriverTypeEnum:@(MNSDatabaseTypeMicrosoftSqlServer)];
            [userCredentals setTds_server:      [connectionSettings server]];
            [userCredentals setTds_host:        [connectionSettings server]];
            [userCredentals setTds_username:    [connectionSettings username]];
            [userCredentals setTds_password:    [connectionSettings password]];
            [userCredentals setTds_database:    [connectionSettings database]];
            [userCredentals setTds_port:      @([connectionSettings port])];
        }
        
    } else if ([[database identifier] isEqualToString:[MTDatabaseSqlite3 identifier]]) {
        
        MTDatabaseConnection *connectionSettings = [database databaseConnection];
        if (connectionSettings != nil) {
            // FIXME: Storing Sqlite3 database url in mysql holder.
            NSString *path = [[connectionSettings databaseUrl] path];
            NSString *filename = [path lastPathComponent];
            [userCredentals setMysql_database:      filename];
            [[userCredentals inDatabase] setDatabaseDriverTypeEnum:@(MNSDatabaseTypeSqlite3)];
        }
        
    }
    
    [rptqDatabase setOwnedByUser: userCredentals];
    
    NSString *rptqQueryId = NSStringFromClass([RptqQuery class]);
    RptqQuery *newQuery = [NSEntityDescription insertNewObjectForEntityForName: rptqQueryId inManagedObjectContext: self.managedObjectContext];
    [rptqDatabase addHasQueriesObject:newQuery];
    
    NSSet *databaseSchemas = [[self hasDatabaseSchemas] setByAddingObject: rptqDatabase];
    [self setHasDatabaseSchemas: databaseSchemas];
    
    __weak MTDatabase *weakDatabase = database;
    __weak RptqDocument *weakself = self;

    NSString *statusQueryingTables = NSLocalizedString(@"Querying tables.", @"Querying tables.");
    status(statusQueryingTables);
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __weak MTDatabase *weakDatabase2 = weakDatabase;
        __weak RptqDocument *weakself2 = weakself;
        
        [weakDatabase getTables:^(BOOL success, NSError *error, NSArray *tables) {
            
            //__weak MTDatabase *weakDatabase3 = weakDatabase2;
            //__weak RptqDocument *weakself3 = weakself2;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                if (success) {
                    
                    __block NSUInteger tableCounter = 0;
                    NSUInteger numberOfTables = [tables count];
                    
                    for (MTDatabaseTable *table in tables) {
                        
                        @autoreleasepool {
                            
                            RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable databaseSchemaTableFactoryWithManagedObjectContext: weakself2.managedObjectContext
                                                                                                                                    andTable: table];
                            RptqDatabase *currentDatabase = [weakself2 databaseWithConnectionID: connectionId];
                            if (currentDatabase) [currentDatabase addHasTablesObject: rptqTable];
                            
//                            NSError *error = nil;
                            [weakself2.managedObjectContext performSelectorOnMainThread:@selector(save:) withObject:nil waitUntilDone:YES];
                            
                            NSString *tableName = [rptqTable name];
                            
                            NSString *fieldsForTable = NSLocalizedString(@"Querying fields for %@.", @"Querying fields for %@.");
                            NSString *statusQueryingFieldsForTable = [NSString stringWithFormat:fieldsForTable, tableName];
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                status(statusQueryingFieldsForTable);
                            });
                            
                            __weak RptqDatabaseSchemaTable *weaktable = rptqTable;
                            __weak MTDatabase *weakDatabase4 = weakDatabase2;
                            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//                                __weak RptqDatabaseSchemaTable *weaktable2 = weaktable;
                                [weakDatabase4 getFieldsForTableName:tableName completion:^(BOOL success, NSError *error, NSArray *fields) {
                                    __weak RptqDatabaseSchemaTable *weaktable3 = weaktable;
                                    //dispatch_sync(dispatch_get_main_queue(), ^{
                                        if (success) {
                                            
                                            for (MTDatabaseField *field in fields) {
                                                @autoreleasepool {
                                                    
                                                    NSString *addingField = NSLocalizedString(@"Adding %1@ from %2@.", @"Adding %1@ from %2@.");
                                                    NSString *statusAddingField = [NSString stringWithFormat:addingField, tableName, [field name]];
                                                    status(statusAddingField);
                                                    
                                                    RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField databaseSchemaFieldFactoryForManagedObjectContext: weaktable3.managedObjectContext
                                                                                                                                                             andField: field];
                                                    
                                                    NSMutableOrderedSet *fieldSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:[weaktable3 hasFields]];
                                                    [fieldSet addObject:schemaField];
                                                    [weaktable3 setHasFields:fieldSet];
                                                }
                                            }
                                            
  //                                          NSError *saveError = nil;
                                            [weaktable3.managedObjectContext performSelectorOnMainThread:@selector(save:) withObject:nil waitUntilDone:YES];
//                                            [weaktable3.managedObjectContext save:&saveError];
                                         //   NSAssert(saveError == nil, @"%@", saveError);
                                            
                                            if (tableCounter == numberOfTables - 1) {
                                                dispatch_sync(dispatch_get_main_queue(), ^{
                                                    completion(YES, nil);
                                                });
                                            }
                                            tableCounter++;
                                        } else {
                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                                completion(NO, error);
                                            });
                                        }
                                    //});
                                }];
                            //});
                        }
                    }
                    
                } else {
                    completion(success, error);
                }
            });

        }];
   // });
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqDocument *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
