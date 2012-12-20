//
//  NSObject+RptqDocument_Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+Extras.h"

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

+ (void)queryDatabaseFor: (NSManagedObjectContext *)objectContext
              completion: (void (^)(NSArray *results))completion {
    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: objectContext] retain];
    if (doc) {
        RptqDatabase *db = [[doc hasDatabaseSchemas] anyObject];
        if (db) {
            NSString *driverType = [[db database_driver_type] retain];
            if ([driverType isEqualToString: [MNSDatabaseMySql identifier]]) {

            } else if ([driverType isEqualToString: [MNSDatabaseSalesForce identifier]]) {
                
            }
            [driverType release];
        }
    }
    [doc release];
}

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    
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
    
    NSEntityDescription *ed                     = [NSEntityDescription entityForName:NSStringFromClass([RptqDocument class]) inManagedObjectContext: objectContext];
    RptqDocument *document                      = [[RptqDocument alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];

    [document setHasReportHeaderSection:          [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasReportFooterSection:          [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasPageHeaderSection:            [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasPageFooterSection:            [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasDetailSection:                [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    
    [[document hasReportHeaderSection] setType:      @(MNSDocumentSectionTypeReportHeader)];
    [[document hasReportFooterSection] setType:      @(MNSDocumentSectionTypeReportFooter)];
    [[document hasPageHeaderSection] setType:        @(MNSDocumentSectionTypePageHeader)];
    [[document hasPageFooterSection] setType:        @(MNSDocumentSectionTypePageFooter)];
    [[document hasDetailSection] setType:            @(MNSDocumentSectionTypeBody)];

    //[document setHasDatabaseSchemas:               [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDatabase class]) inManagedObjectContext: objectContext]];
    //[document setHasQuery:                        [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqQuery class]) inManagedObjectContext: objectContext]];
#warning Added Owned by User when creating the schemas.
    //[[document hasDatabaseSchema] setOwnedByUser: [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqUserCredentals class]) inManagedObjectContext: objectContext]];

    [[document hasReportHeaderSection] setHeight:@44.0000f];
    [[document hasReportFooterSection] setHeight:@44.0000f];
    [[document hasPageHeaderSection] setHeight:@44.0000f];
    [[document hasPageFooterSection] setHeight:@44.0000f];
    [[document hasDetailSection] setHeight:@44.0000f];

    [[document hasReportHeaderSection] setVisibility:@YES];
    [[document hasReportFooterSection] setVisibility:@YES];
    [[document hasPageHeaderSection] setVisibility:@YES];
    [[document hasPageFooterSection] setVisibility:@YES];
    [[document hasDetailSection] setVisibility:@YES];

    NSLog(@"Document, %@", document);
   return [document autorelease];
}

+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    RptqDocument *doc = nil;
    NSFetchRequest *docFetchRequest = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
    if (!error) {
        doc = [documents lastObject];
    } else {
        NSLog(@"Error: %@, %@", [error localizedDescription], [error localizedFailureReason]);
    }

    //Create the document if it does not exist.
    if (!doc) {
        doc = [[[RptqDocument createMainDocumentForManagedObjectContext:objectContext] retain] autorelease];
    }

    return doc;
}

+ (void)addDatabase: (MNSDatabase *)database ToMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext
         completion: (void (^)(BOOL success))completion {
    
    RptqDocument *rptqDocument = [RptqDocument getMainDocumentForManagedObjectContext: objectContext];
    
    
    NSNumber *connectionId = @([[rptqDocument hasDatabaseSchemas] count] + 1);
    
    RptqDatabase *rptqDatabase = [RptqDatabase createNewDatabaseForManagedObjectContext: objectContext
                                                                             driverType: [database identifier]
                                                                           connectionId: connectionId];
    
    RptqUserCredentals *userCredentals = [RptqUserCredentals createNewUserCredentalsForManagedObjectContext: objectContext];
    [userCredentals setDatabase_driver_type: [database identifier]];
    [rptqDatabase setOwnedByUser: userCredentals];

    [rptqDatabase addHasQueriesObject:[NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqQuery class]) inManagedObjectContext: objectContext]];
    
    [rptqDocument setHasDatabaseSchemas: [[rptqDocument hasDatabaseSchemas] setByAddingObject: rptqDatabase]];
    
    [database getTables:^(NSArray *tables) {
        
        for (MNSDatabaseTable *databaseTable in tables) {
            RptqTable *rptqTable = [RptqTable createNewTableForManagedObjectContext: objectContext
                                                                           andTable: databaseTable];
            
            RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                 withConnecitonId: connectionId];
            
            if (currentDatabase) [currentDatabase addHasTablesObject: rptqTable];
            
            [database getFieldsForTable:rptqTable completion:^(NSArray *fields) {
                
                for (MNSDatabaseField *objField in fields) {
                    RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                         withConnecitonId: connectionId];
                    
                    RptqTable *rptqTableOrigional = [RptqTable getTableForManagedObjectContext: objectContext
                                                                                      database: currentDatabase
                                                                                  andTableName: [databaseTable name]];
                    
                    RptqField *rptqField = [RptqField createNewFieldForManagedObjectContext: objectContext
                                                                                   andField: objField];
                    [rptqTableOrigional addHasFieldsObject: rptqField];
                }
             
            }];
            
        }
        
        completion(YES);
        
    }];
    
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqDocument *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end