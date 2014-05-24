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

#pragma mark - Static

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
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

+ (void)addDatabase: (MTDatabase *)database toDocument:(RptqDocument *)document
         completion: (void (^)(BOOL success, NSError *error))completion {
    
    __weak RptqDocument *rptqDocument = document;
    __weak NSManagedObjectContext *managedObjectContext = [rptqDocument managedObjectContext];
    
    NSNumber *connectionId = @([[rptqDocument hasDatabaseSchemas] count] + 1);
    __weak RptqDatabase *rptqDatabase = [RptqDatabase createNewDatabaseForManagedObjectContext: managedObjectContext
                                                                             driverType: [database identifier]
                                                                           connectionId: connectionId];
    __weak RptqUserCredentals *userCredentals = [RptqUserCredentals createNewUserCredentalsForManagedObjectContext: managedObjectContext];
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
    RptqQuery *newQuery = [NSEntityDescription insertNewObjectForEntityForName: rptqQueryId inManagedObjectContext: managedObjectContext];
    [rptqDatabase addHasQueriesObject:newQuery];
    
    NSSet *databaseSchemas = [[rptqDocument hasDatabaseSchemas] setByAddingObject: rptqDatabase];
    [rptqDocument setHasDatabaseSchemas: databaseSchemas];
    
    __weak MTDatabase *weakDatabase = database;
    __weak NSNumber *weakConnectionId = connectionId;
    [weakDatabase getTables:^(BOOL success, NSError *error, NSArray *tables) {
        if (success) {
            __block NSUInteger tableCounter = 0;
            NSUInteger numberOfTables = [tables count];

            for (MTDatabaseTable *databaseTable in tables) {
            
                RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable createNewTableForManagedObjectContext: managedObjectContext
                                                                                                           andTable: databaseTable];
                RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                     withConnecitonId: weakConnectionId];

                if (currentDatabase) [currentDatabase addHasTablesObject: rptqTable];
                NSError *error = nil;
                [[currentDatabase managedObjectContext] save:&error];
                
                NSString *tableName = [rptqTable name];
                
                NSNumber *weakConnectionId2 = connectionId;
                [weakDatabase getFieldsForTableName:tableName completion:^(BOOL success, NSError *error, NSArray *fields) {
                    if (success) {
                        for (MTDatabaseField *objField in fields) {
                            RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                                 withConnecitonId: weakConnectionId2];
                            
                            RptqDatabaseSchemaTable *rptqTableOrigional = [RptqDatabaseSchemaTable getTableForDatabase: currentDatabase
                                                                                          andTableName: [databaseTable name]];
                            
                            RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField createNewFieldForManagedObjectContext: managedObjectContext
                                                                                                                       andField: objField];
                            
                            NSMutableOrderedSet *fieldSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:[rptqTableOrigional hasFields]];
                            [fieldSet addObject:schemaField];
                            [rptqTableOrigional setHasFields:fieldSet];

                            NSError *saveError = nil;
                            [[schemaField managedObjectContext] save:&saveError];
                            NSAssert(saveError == nil, @"%@", saveError);
                        }
                        if (tableCounter == numberOfTables - 1) {
                            completion(YES, nil);
                        }
                        tableCounter++;
                    } else {
                        completion(NO, error);
                    }
                }];
                
            }

        } else {
            completion(success, error);
        }
        
        
        
    }];
    
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
