//
//  NSObject+RptqDocument_Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+Extras.h"
#import "MTDatabaseSqlite3.h"

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
    NSOrderedSet *hasRows = [[NSOrderedSet alloc] initWithObject: headerRow];
    [[document hasReportHeaderSection] setHasRows:hasRows];
    [headerRow setInSection:[document hasReportHeaderSection]];
    [hasRows release]; hasRows = nil;

    RptqDocumentSectionRows *footerRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                       inManagedObjectContext: objectContext];
    hasRows = [[NSOrderedSet alloc] initWithObject: footerRow];
    [[document hasReportFooterSection] setHasRows:hasRows];
    [footerRow setInSection:[document hasReportFooterSection]];
    [hasRows release]; hasRows = nil;

    RptqDocumentSectionRows *pageHeaderRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                           inManagedObjectContext: objectContext];
    hasRows = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
    [[document hasPageHeaderSection] setHasRows:hasRows];
    [pageHeaderRow setInSection:[document hasPageHeaderSection]];
    [hasRows release]; hasRows = nil;
    
    RptqDocumentSectionRows *pageFooterRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                           inManagedObjectContext: objectContext];
    hasRows = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
    [[document hasPageFooterSection] setHasRows:hasRows];
    [pageFooterRow setInSection:[document hasPageFooterSection]];
    [hasRows release]; hasRows = nil;
    
    RptqDocumentSectionRows *detailSectionRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                              inManagedObjectContext: objectContext];
    hasRows = [[NSOrderedSet alloc] initWithObject: detailSectionRow];
    [[document hasDetailSection] setHasRows:hasRows];
    [detailSectionRow setInSection:[document hasDetailSection]];
    [hasRows release]; hasRows = nil;
    
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

    return [document autorelease];
}

+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    Class docClass = [RptqDocument class];
    NSString *entityName = NSStringFromClass(docClass);
    NSFetchRequest *docFetchRequest = [[NSFetchRequest alloc] initWithEntityName: entityName];
    [docFetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *documents = [[objectContext executeFetchRequest:docFetchRequest error:&error] retain];
    [docFetchRequest release];
    RptqDocument *result = [[documents lastObject] retain];
    [documents release];
    return [result autorelease];
}

+ (void)addDatabase: (MTDatabase *)database toDocument:(RptqDocument *)document
         completion: (void (^)(BOOL success, NSError *error))completion {
    
    __block RptqDocument *rptqDocument = document;
    __block NSManagedObjectContext *managedObjectContext = [rptqDocument managedObjectContext];
    
    NSNumber *connectionId = @([[rptqDocument hasDatabaseSchemas] count] + 1);
    __block RptqDatabase *rptqDatabase = [RptqDatabase createNewDatabaseForManagedObjectContext: managedObjectContext
                                                                             driverType: [database identifier]
                                                                           connectionId: connectionId];
    __block RptqUserCredentals *userCredentals = [RptqUserCredentals createNewUserCredentalsForManagedObjectContext: managedObjectContext];
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
    
    [database getTables:^(BOOL success, NSError *error, NSArray *tables) {
        if (success) {
            __block NSUInteger tableCounter = 0;
            NSUInteger numberOfTables = [tables count];

            for (MTDatabaseTable *databaseTable in tables) {
            
                RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable createNewTableForManagedObjectContext: managedObjectContext
                                                                                                           andTable: databaseTable];
                RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                     withConnecitonId: connectionId];

                if (currentDatabase) [currentDatabase addHasTablesObject: rptqTable];
                NSError *error = nil;
                [[currentDatabase managedObjectContext] save:&error];
                
                [database getFieldsForTableSchema:rptqTable completion:^(BOOL success, NSError *error, NSArray *fields) {
                    if (success) {
                        for (MTDatabaseField *objField in fields) {
                            RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                                 withConnecitonId: connectionId];
                            
                            RptqDatabaseSchemaTable *rptqTableOrigional = [RptqDatabaseSchemaTable getTableForManagedObjectContext: managedObjectContext
                                                                                              database: currentDatabase
                                                                                          andTableName: [databaseTable name]];
                            
                            RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField createNewFieldForManagedObjectContext: managedObjectContext
                                                                                                                       andField: objField];
                            
                            NSMutableOrderedSet *fieldSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:[rptqTableOrigional hasFields]];
                            [fieldSet addObject:schemaField];
                            [rptqTableOrigional setHasFields:fieldSet];
                            [fieldSet release];

                            NSError *saveError = nil;
                            [[schemaField managedObjectContext] save:&saveError];

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