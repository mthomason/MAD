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

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <Foundation/NSException.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>

#import <UIKit/UIImage.h>

#import "RptqDocument+Extras.h"
#import "MADDatabaseConnection.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"

#import "RptqQueryGroup+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqQuery+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectChart.h"
#import "RptqDocumentObjectGroupKey.h"
#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelLink.h"

#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocumentObjectBarcode+Extras.h"
#import "RptqDocumentObjectFormula+Extras.h"

#import "MADErrorContainer.h"
#import "MTDatabaseTable.h"

#import "MADReportSections.h"

#import "MADDatabaseConnection.h"

@implementation RptqDocument (Extras)

#pragma mark - Overrides

- (void)willTurnIntoFault {
    [super willTurnIntoFault];
}

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
}

- (void)willChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {
    [super willChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocument class])];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: queryField
                                                                   ascending: NO];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        identifier = ((RptqDocument *)fetchResults.lastObject).identifier.unsignedIntegerValue + 1;
    }
    id identifierObj = [[NSNumber alloc] initWithUnsignedInteger: identifier];
    self.identifier = identifierObj;
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

- (RptqQuery *)mainQuery {
    RptqDatabase *defaultDatabase = [self defaultDatabase];
    RptqQuery *mainQuery = [defaultDatabase defaultQuery];
    return mainQuery;
}

- (RptqDatabase *)defaultDatabase {
    return self.hasDatabaseSchemas.anyObject;
}

- (MTPaperType)paperType {
    return self.papersize.unsignedShortValue;
}

- (RptqDocumentSection *)documentSectionForSelectedIndex:(NSUInteger)selectedIndex
                                      withNumberOfGroups:(NSUInteger)numberOfGroups {
    
    RptqDocumentSection *resultSection = nil;
    
    switch ([RptqDocumentSection getSectionTypeforRow: selectedIndex
                                   withNumberOfGroups: numberOfGroups]) {
            
        case MADDocumentSectionTypeReportHeader:
            resultSection = self.hasReportHeaderSection;
            break;
            
        case MADDocumentSectionTypePageHeader:
            resultSection = self.hasPageHeaderSection;
            break;
            
        case MADDocumentSectionTypeBody:
            resultSection = self.hasDetailSection;
            break;
            
        case MADDocumentSectionTypePageFooter:
            resultSection = self.hasPageFooterSection;
            break;
            
        case MADDocumentSectionTypeReportFooter:
            resultSection = self.hasReportFooterSection;
            break;
            
        case MADDocumentSectionTypeGroupHeader: {
            RptqQuery *query = self.mainQuery;
            RptqQueryGroup *group = [query queryGroupForIndex:
                                     queryGroupIndexForSelectedIndexOfTypeHeader(selectedIndex)];
            resultSection = [RptqDocumentSection headerSectionInSections:group.hasSection];
            break;
        }
            
        case MADDocumentSectionTypeGroupFooter: {
            RptqQuery *query = self.mainQuery;
            RptqQueryGroup *group = [query queryGroupForIndex:
                                     queryGroupIndexForSelectedIndexOfTypeFooter(selectedIndex,
                                                                                 numberOfGroups)];
            resultSection = [RptqDocumentSection footerSectionInSections:group.hasSection];
            break;
        }
            
        default:
            break;
    }
    
    return resultSection;
}

- (RptqDocumentSection *)documentSectionForType:(MADDocumentSectionType)type andLevel:(NSUInteger)level {
    
    switch (type) {
            
        case MADDocumentSectionTypeBody:
            return self.hasDetailSection;
            break;
            
        case MADDocumentSectionTypePageHeader:
            return self.hasPageHeaderSection;
            break;
            
        case MADDocumentSectionTypePageFooter:
            return self.hasPageFooterSection;
            break;
            
        case MADDocumentSectionTypeReportHeader:
            return self.hasReportHeaderSection;
            break;
            
        case MADDocumentSectionTypeReportFooter:
            return self.hasReportFooterSection;
            break;
            
        case MADDocumentSectionTypeGroupHeader:
            return [RptqDocumentSection groupHeaderForLevel: level query: self.defaultDatabase.defaultQuery];
            break;
        case MADDocumentSectionTypeGroupFooter:
            return [RptqDocumentSection groupFooterForLevel: level query: self.defaultDatabase.defaultQuery];
            break;
        default:
            NSAssert(NO, @"Unknown type");
            return nil;
            break;
    }
}

#pragma mark - Static

+ (instancetype)newDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSString *rptqDocumentName = NSStringFromClass([RptqDocument class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: rptqDocumentName];
    
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:request error:&error];
    
    if (!error) {
        //Delete any contents of the existing object modal.
        if (documents && documents.count > 0) {
            for (RptqDocument *document in documents) {
                [objectContext deleteObject:document];
            }
        }
    }
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: rptqDocumentName
                                                         inManagedObjectContext: objectContext];
    
    RptqDocument *document = [[RptqDocument alloc] initWithEntity: entityDescription
                                   insertIntoManagedObjectContext: objectContext];

    Class sectionClass = [RptqDocumentSection class];
    NSString *rptqDocumentSection = NSStringFromClass(sectionClass);
    
    Class sectionRowsClass = [RptqDocumentSectionRows class];
    NSString *rptqDocumentSectionRows = NSStringFromClass(sectionRowsClass);

    id hasReportHeaderSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection
                                                              inManagedObjectContext: objectContext];
    document.hasReportHeaderSection = hasReportHeaderSection;

    id hasReportFooterSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection
                                                              inManagedObjectContext: objectContext];
    document.hasReportFooterSection = hasReportFooterSection;
    
    id hasPageHeaderSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection
                                                            inManagedObjectContext: objectContext];
    document.hasPageHeaderSection = hasPageHeaderSection;
    
    id hasPageFooterSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection
                                                            inManagedObjectContext: objectContext];
    document.hasPageFooterSection = hasPageFooterSection;
    
    id hasDetailSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection
                                                        inManagedObjectContext: objectContext];
    document.hasDetailSection = hasDetailSection;
    
    RptqDocumentSectionRows *headerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                                       inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows1 = [[NSOrderedSet alloc] initWithObject: headerRow];
    document.hasReportHeaderSection.hasRows = hasRows1;
    headerRow.inSection = document.hasReportHeaderSection;

    RptqDocumentSectionRows *footerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                                       inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows2 = [[NSOrderedSet alloc] initWithObject: footerRow];
    document.hasReportFooterSection.hasRows = hasRows2;
    footerRow.inSection = document.hasReportFooterSection;

    RptqDocumentSectionRows *pageHeaderRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                                           inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows3 = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
    document.hasPageHeaderSection.hasRows = hasRows3;
    pageHeaderRow.inSection = document.hasPageHeaderSection;
    
    RptqDocumentSectionRows *pageFooterRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                                           inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows4 = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
    document.hasPageFooterSection.hasRows = hasRows4;
    pageFooterRow.inSection = document.hasPageFooterSection;
    
    RptqDocumentSectionRows *detailSectionRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                                              inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows5 = [[NSOrderedSet alloc] initWithObject: detailSectionRow];
    document.hasDetailSection.hasRows = hasRows5;
    detailSectionRow.inSection = document.hasDetailSection;
    
    NSNumber *headerType = [[NSNumber alloc] initWithShort: MADDocumentSectionTypeReportHeader];
    document.hasReportHeaderSection.type = headerType;
    
    NSNumber *footerType = [[NSNumber alloc] initWithShort: MADDocumentSectionTypeReportFooter];
    document.hasReportFooterSection.type = footerType;

    NSNumber *pageHeaderType = [[NSNumber alloc] initWithShort: MADDocumentSectionTypePageHeader];
    document.hasPageHeaderSection.type = pageHeaderType;
    
    NSNumber *pageFooterType = [[NSNumber alloc] initWithShort: MADDocumentSectionTypePageFooter];
    document.hasPageFooterSection.type = pageFooterType;
    
    NSNumber *bodyType = [[NSNumber alloc] initWithShort: MADDocumentSectionTypeBody];
    document.hasDetailSection.type = bodyType;

    [document.hasReportHeaderSection    setInterfaceHeight: 44.0000f];
    [document.hasReportFooterSection    setInterfaceHeight: 44.0000f];
    [document.hasPageHeaderSection      setInterfaceHeight: 44.0000f];
    [document.hasPageFooterSection      setInterfaceHeight: 44.0000f];
    [document.hasDetailSection          setInterfaceHeight: 88.0000f];

    NSNumber *hasReportHeaderSectionVisibility = @YES;
    document.hasReportHeaderSection.visibility = hasReportHeaderSectionVisibility;
    
    NSNumber *hasReportFooterSectionVisibility = @YES;
    document.hasReportFooterSection.visibility = hasReportFooterSectionVisibility;

    NSNumber *hasPageHeaderSectionVisibility = @YES;
    document.hasPageHeaderSection.visibility = hasPageHeaderSectionVisibility;

    NSNumber *hasPageFooterSectionVisibility = @YES;
    document.hasPageFooterSection.visibility = hasPageFooterSectionVisibility;

    NSNumber *hasDetailSectionVisibility = @YES;
    document.hasDetailSection.visibility = hasDetailSectionVisibility;
    

    return document;
}

+ (instancetype)newDocumentReadFromManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSString *entityName = NSStringFromClass([RptqDocument class]);
    NSFetchRequest *docFetchRequest = [[NSFetchRequest alloc] initWithEntityName: entityName];
    docFetchRequest.fetchLimit = 1;
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
    NSAssert(error == nil, @"Got error on new document fetch: %@", error);
    id document = documents.lastObject;
    return document;
}

- (void)setLayoutHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    NSNumber *layoutHeight = [[NSNumber alloc] initWithFloat:height];
    section.layoutHeight = layoutHeight;
}

- (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    
    if (section.numberOfRows.unsignedIntegerValue == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > section.numberOfRows.unsignedIntegerValue) {
        
        //Add row
        NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
        RptqDocumentSectionRows *newRowToAppend;
        newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                       inManagedObjectContext: managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray: section.hasRows.array];
        newRowToAppend.inSection = section;
        [hasRows addObject:newRowToAppend];
        section.hasRows = hasRows;
        
    } else if (numberOfRows < section.numberOfRows.unsignedIntegerValue) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray: section.hasRows.array];
        [hasRows.lastObject setInSection:nil];
        [hasRows removeObjectAtIndex: hasRows.count - 1];
        section.hasRows = hasRows;
        [rowToDelete setInSection:nil];
        
    }
    NSNumber *numberOfRowsObj = [NSNumber numberWithUnsignedInteger:numberOfRows];
    section.numberOfRows = numberOfRowsObj;
}

- (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    NSNumber *layoutHeight = [[NSNumber alloc] initWithFloat:height];
    section.layoutHeight = layoutHeight;
}

- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    NSNumber *visibility = [[NSNumber alloc] initWithBool:isVisible];
    section.visibility = visibility;
}

- (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    [section setProducesFormFeed:newPageAfter];
}

- (BOOL)newPageAfterSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    return [section producesFormFeed];
}

- (void)storeDatabaseConnectionDefination:(MTDatabase *)database forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSNumber *connectionId = @(self.hasDatabaseSchemas.count + 1);
    RptqDatabase *rptqDatabase = [RptqDatabase newDatabaseFactoryForManagedObjectContext: managedObjectContext
                                                                              driverType: database.identifier
                                                                            connectionId: connectionId];
    
    RptqUserCredentals *userCredentals = [RptqUserCredentals newUserCredentalForManagedObjectContext: managedObjectContext];
    
    NSString *databaseIdentifier = [[NSString alloc] initWithString:database.identifier];
    userCredentals.database_driver_type = databaseIdentifier;

    if (database.databaseConnection != nil) {
        
        switch (database.databaseConnection.databaseType) {
            case MADDatabaseTypeMySQL: {
                MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *databaseConnection;
                databaseConnection = (MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *)database.databaseConnection;
                NSNumber *port = [[NSNumber alloc] initWithInteger:databaseConnection.port];
                userCredentals.mysql_port = port;
                
                NSNumber *databaseDriverTypeEnum = [[NSNumber alloc] initWithShort:MADDatabaseTypeMySQL];
                userCredentals.inDatabase.databaseDriverTypeEnum = databaseDriverTypeEnum;
                
                NSString *server = [[NSString alloc] initWithString:databaseConnection.server];
                userCredentals.mysql_host = server;
                
                NSString *db = [[NSString alloc] initWithString:databaseConnection.database];
                userCredentals.mysql_database = db;
                break;
            }

            case MADDatabaseTypeSqlite3: {
                MADDatabaseConnection *databaseConnection;
                databaseConnection = database.databaseConnection;
                userCredentals.mysql_database = ((id <MADDatabaseConnectionsPropertiesURL>)databaseConnection).databaseUrl.path.lastPathComponent.copy;
                
                NSNumber *databaseDriverTypeEnum = [[NSNumber alloc] initWithShort: MADDatabaseTypeSqlite3];
                userCredentals.inDatabase.databaseDriverTypeEnum = databaseDriverTypeEnum;

                break;
            }

            case MADDatabaseTypeTDS: {
                MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *databaseConnection;
                databaseConnection = (MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *)database.databaseConnection;
                NSNumber *port = [[NSNumber alloc] initWithInteger:databaseConnection.port];
                userCredentals.tds_port = port;
                
                NSNumber *databaseDriverTypeEnum = [[NSNumber alloc] initWithShort: MADDatabaseTypeTDS];
                userCredentals.inDatabase.databaseDriverTypeEnum = databaseDriverTypeEnum;
                
                NSString *server = [[NSString alloc] initWithString: databaseConnection.server];
                userCredentals.tds_server = server;
                
                NSString *host = [[NSString alloc] initWithString: databaseConnection.server];
                userCredentals.tds_host = host;
                
                NSString *db  = [[NSString alloc] initWithString: databaseConnection.database];
                userCredentals.tds_database = db;
                break;
            }
                
            default:
                break;
        }
    }
    
    rptqDatabase.ownedByUser = userCredentals;
    NSString *rptqQueryId = NSStringFromClass([RptqQuery class]);
    RptqQuery *newQuery = [NSEntityDescription insertNewObjectForEntityForName: rptqQueryId
                                                        inManagedObjectContext: managedObjectContext];
    [rptqDatabase addHasQueriesObject:newQuery];
    
    
    NSSet *databaseSchemas = [self.hasDatabaseSchemas setByAddingObject: rptqDatabase];
    NSSet *dbs = [[NSSet alloc] initWithSet:databaseSchemas];
    self.hasDatabaseSchemas = dbs;

}

- (void)addDatabase:(MTDatabase *)database forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
             status:(void (^)(NSString *status, float progress))status
         completion:(void (^)(BOOL success, MADErrorContainer *error))completion {

    [self storeDatabaseConnectionDefination:database forManagedObjectContext:managedObjectContext];
    
    MADErrorContainer *errorContainer = [MADErrorContainer new];
    
    id dbconnection = [database connectWithConnection:database.databaseConnection credentals:nil];
    
    if (dbconnection) {
        
        NSMutableDictionary *tablesAndFields   = [[NSMutableDictionary alloc] init];
        NSMutableArray *tables                 = [NSMutableArray array];
        BOOL gotit                             = YES;
        //NSError *gotitError                    = nil;
        
        
        NSError *error = NULL;
        NSArray *resultTables = [database getTablesFromConnection:dbconnection error:&error];

        [tables setArray:resultTables];
        NSUInteger counter = 0, numberOfTables = tables.count;
        for (MTDatabaseTable *databaseTable in tables) {
            @autoreleasepool {
                
                NSString *name = databaseTable.name.copy;
                
                status(name, (counter + 1) / numberOfTables);
                
                NSError *getFieldsError = NULL;
                NSArray *fieldsForTable = [database fieldsForTable: databaseTable.name
                                                        connection: dbconnection
                                                             error: &getFieldsError];
                
                NSArray *fields = [[NSArray alloc] initWithArray:fieldsForTable];
                tablesAndFields[databaseTable.name] = fields;
                
            }
            counter++;
        }
        
        //gotitError = error;
        
        MADErrorContainer *additionalErrors = [self storeTablesAndFieldsForTables:tables fieldsByTable:tablesAndFields andManagedObjectContext:managedObjectContext];
        [errorContainer addErrorsFromContainer:additionalErrors];
        
        [database closeProcess:dbconnection];
        completion(gotit, errorContainer);
        
        
        /*
        [database enumerateTablesFromConnection:dbconnection usingBlock:^(MTDatabaseTable *databaseTable, NSUInteger index, BOOL *stop) {
            //NSString *name = databaseTable.name.copy;
            
            //status(name, (index + 1) / numberOfTables);
            
            NSError *getFieldsError = NULL;
            NSArray *fieldsForTable = [database fieldsForTable:databaseTable.name connection:dbconnection error:&getFieldsError];
            
            NSArray *fields = [[NSArray alloc] initWithArray:fieldsForTable];
            tablesAndFields[databaseTable.name] = fields;

        } completion:^(BOOL success, NSError *errors, NSArray *results) {
            
        }];*/
        
        /*[database getTablesFromConnection:dbconnection completion:^(BOOL success, NSError *error, NSArray *resultTables) {
            
            if (success) {
                
                [tables setArray:resultTables];
                NSUInteger counter = 0, numberOfTables = tables.count;
                for (MTDatabaseTable *databaseTable in tables) {
                    @autoreleasepool {
                        
                        NSString *name = databaseTable.name.copy;
                        
                        status(name, (counter + 1) / numberOfTables);
                        
                        NSError *getFieldsError = NULL;
                        NSArray *fieldsForTable = [database fieldsForTable:databaseTable.name connection:dbconnection error:&getFieldsError];
                        
                        NSArray *fields = [[NSArray alloc] initWithArray:fieldsForTable];
                        tablesAndFields[databaseTable.name] = fields;
                        
                    }
                    counter++;
                }
                
                gotit = success; gotitError = error;
                
                MADErrorContainer *additionalErrors = [self storeTablesAndFieldsForTables:tables fieldsByTable:tablesAndFields];
                [errorContainer addErrorsFromContainer:additionalErrors];
                
                [database closeProcess:dbconnection];
                completion(gotit, errorContainer);
                
            } else {
                MADErrorContainer *errorContainer = [[MADErrorContainer alloc] init];
                [errorContainer addError:error];
                completion(NO, errorContainer);
            }
        }];*/
        
    } else {
        completion(NO, nil);
    }
    
}

- (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables fieldsByTable:(NSDictionary *)fieldsByTable andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    MADErrorContainer * __autoreleasing errorContainer = [[MADErrorContainer alloc] init];
    for (MTDatabaseTable *table in tables) {
        
        NSString *tableName = table.name;
        NSArray *fields = fieldsByTable[table.name];
        
        if (fields.count) {
            
            RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext: managedObjectContext andTable: table];
            [self.defaultDatabase addHasTablesObject: rptqTable];
            
            NSMutableArray *schemaFields = [[NSMutableArray alloc] initWithCapacity:fields.count];
            for (MTDatabaseField *field in fields) {
                RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext: managedObjectContext andField: field];
                [schemaFields addObject:schemaField];
            }
            
            NSOrderedSet *hasFields = [[NSOrderedSet alloc] initWithArray:schemaFields];
            rptqTable.hasFields = hasFields;
            
            NSError *saveError = nil;
            [rptqTable.managedObjectContext save:&saveError];
            
        } else {
            
            NSString *failureFormat = NSLocalizedString(@"Table %@ not Added.", @"Table %@ not Added.");
            NSString *description = NSLocalizedString(@"Fields not found.", @"Fields not found.");
            NSString *failure = [[NSString alloc] initWithFormat:failureFormat, tableName];
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description,
                                       NSLocalizedFailureReasonErrorKey : failure};
            NSError *error = [NSError errorWithDomain:@"MADReportDocument" code:38292 userInfo:userInfo];
            [errorContainer addError:error];
            
        }
    }
    return errorContainer;
}

- (void)addQueryLink:(RptqQueryLinks *)queryLink {
    NSSet *linkSet = [NSSet setWithObject: queryLink];
    [self.defaultDatabase.defaultQuery addHasQueryLinks: linkSet];
}

- (void)addPredicate:(RptqQueryPredicate *)predicate {
    
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    NSSet *predicates = [NSSet setWithObject: predicate];
    [query addHasQueryPredicate:predicates];
    
}

- (RptqDocumentObject *)addDocumentObject:(NSDictionary *)defination {
    NSManagedObjectContext *mangedObjectContext = self.managedObjectContext;
    
    NSNumber *objectTypeObj = defination[MTDocumentObjectDefinationType];
    MTDocumentObjectType objectType = (MTDocumentObjectType)objectTypeObj.unsignedIntegerValue;
    
    NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: entityName
                                                                       inManagedObjectContext: mangedObjectContext];
    
    RptqDocumentObject *documentObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                     insertIntoManagedObjectContext: mangedObjectContext];
    documentObject.origin = CGPointZero;

    id size = [[NSNumber alloc] initWithFloat:75.0000f];
    documentObject.sizewidth = size;
    
    size = [[NSNumber alloc] initWithFloat:22.0000f];
    documentObject.sizeheight = size;
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            entityName = NSStringFromClass([RptqDocumentObjectLabelDataField class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSManagedObjectID *fieldObjectId = defination[MTDocumentObjectDefinationObject];
            RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId managedObjectContext: mangedObjectContext];
            
            
            RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                                       insertIntoManagedObjectContext: mangedObjectContext];
            
            documentObject.isLabelDataField = reportObject;
            documentObject.isLabelDataField.referencesQueryField = field;

            reportObject.referencesQueryField = field;
            
            id type = [[NSNumber alloc] initWithShort:MTDocumentObjectTypeLabelDynamic];
            documentObject.type = type;
            
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            
            entityName = NSStringFromClass([RptqDocumentObjectLabel class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSString *labelText = defination[MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectLabel *reportObject = [[RptqDocumentObjectLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            
            documentObject.isLabel = reportObject;
            documentObject.isLabel.text = labelText;

            id type = [[NSNumber alloc] initWithShort:MTDocumentObjectTypeLabelStatic];
            documentObject.type = type;
            
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            
            entityName = NSStringFromClass([RptqDocumentObjectAggregate class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSDictionary *aggregateOptions = defination[MTDocumentObjectDefinationObject];
            RptqDocumentObjectAggregate *reportObject = [[RptqDocumentObjectAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                             insertIntoManagedObjectContext: self.managedObjectContext];
            
            NSNumber *functionInputType = aggregateOptions[MTDocumentObjectDefinationAggregateFunctionInputType];
            reportObject.groupNumber = aggregateOptions[MTDocumentObjectDefinationAggregatePivotNumber];
            reportObject.groupType = aggregateOptions[MTDocumentObjectDefinationAggregatePivotType];
            reportObject.function = aggregateOptions[MTDocumentObjectDefinationAggregateType];
            
            NSManagedObjectID *objectId = aggregateOptions[MTDocumentObjectDefinationAggregateObjectId];
            
            switch ((MTAggregateFunctionInputType)functionInputType.integerValue) {
                case MTAggregateFunctionInputTypeField: {
                    RptqQueryField *field = [RptqQueryField queryFieldForObjectID: objectId
                                                             managedObjectContext: mangedObjectContext];
                    reportObject.aggregateField = field;
                    [reportObject setAggregateFunction:nil];
                    break;
                }
                case MTAggregateFunctionInputTypeFormula: {
                    RptqDocumentObjectFormula *formula =  [mangedObjectContext objectWithID: objectId];
                    [reportObject setAggregateField:nil];
                    reportObject.aggregateFunction = formula;
                    break;
                }
                default:
                    break;
            }
            
            documentObject.isAggregate = reportObject;
            
            id type = [[NSNumber alloc] initWithShort:MTDocumentObjectTypeAggregate];
            documentObject.type = type;
            
            break;
        }
        case MTDocumentObjectTypeImage: {
            
            entityName = NSStringFromClass([RptqDocumentObjectImage class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: mangedObjectContext];
            
            UIImage *image = defination[MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectImage *reportObject = [[RptqDocumentObjectImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            reportObject.image = image;
            documentObject.isImage = reportObject;

            id number = [[NSNumber alloc] initWithFloat:image.size.height];
            documentObject.sizeheight = number;
            
            number = [[NSNumber alloc] initWithFloat:image.size.width];
            documentObject.sizewidth = number;
            
            number = [[NSNumber alloc] initWithShort:MTDocumentObjectTypeImage];
            documentObject.type = number;
            
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            
            id type = [[NSNumber alloc] initWithShort:MTDocumentObjectTypeWhtiespace];
            documentObject.type = type;
            
            break;
        }
        case MTDocumentObjectTypeBarcode: {
            
            MTBarcode *barcode = defination[MTDocumentObjectDefinationObject];
            NSManagedObjectID *field1ObjectId = defination[MTDocumentObjectDefinationField1];
            NSManagedObjectID *field2ObjectId = defination[MTDocumentObjectDefinationField2];
            RptqQueryField *field1 = [RptqQueryField queryFieldForObjectID: field1ObjectId
                                                      managedObjectContext: mangedObjectContext];
            RptqQueryField *field2 = [RptqQueryField queryFieldForObjectID: field2ObjectId
                                                      managedObjectContext: mangedObjectContext];
            RptqDocumentObjectBarcode *reportObject = [RptqDocumentObjectBarcode barcodeWithMtBarcode:barcode
                                                                                        queryFieldOne:field1
                                                                                        queryFieldTwo:field2];
            documentObject.isBarcode = reportObject;
            id type = [[NSNumber alloc] initWithShort:MTDocumentObjectTypeBarcode];
            documentObject.type = type;
            
            break;
        }
        default:
            break;
    }
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[self.hasDetailSection.hasRows[0] hasObjects]];
    [hasObjects insertObject:documentObject atIndex:0];
    [self.hasDetailSection.hasRows[0] setHasObjects:hasObjects];
    return documentObject;
}

+ (void)removeDocumentObject:(RptqDocumentObject *)documentObject
    fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    switch (documentObject.type.shortValue) {
            
        case MTDocumentObjectTypeLabelDynamic: {
            [managedObjectContext deleteObject:documentObject.isLabelDataField];
            break;
        }
            
        case MTDocumentObjectTypeLabelStatic: {
            [managedObjectContext deleteObject:documentObject.isLabel];
            break;
        }
            
        case MTDocumentObjectTypeAggregate: {
            [managedObjectContext deleteObject:documentObject.isAggregate];
            break;
        }
            
        case MTDocumentObjectTypeImage: {
            [managedObjectContext deleteObject:documentObject.isImage];
            break;
        }
            
        case MTDocumentObjectTypeWhtiespace: {
            break;
        }
            
        case MTDocumentObjectTypeBarcode: {
            [managedObjectContext deleteObject:documentObject.isBarcode];
            break;
        }
            
        default:
            break;
            
    }
    [managedObjectContext deleteObject: documentObject];
}

- (id)debugQuickLookObject {
    NSMutableString *document = [[NSMutableString alloc] init];
    [document appendFormat:@"*********\n"];
    [document appendFormat:@"Name:              %@\n", self.name];
    [document appendFormat:@"URL:               %@\n", self.author_name];
    [document appendFormat:@"Number of sections %lu\n", (unsigned long)[((RptqQuery *)((RptqDatabase *)self.hasDatabaseSchemas.anyObject).hasQueries.anyObject) sectionCount]];
    [document appendFormat:@"Comment:           %@\n", self.comment];
    [document appendFormat:@"Copyright:         %@\n", self.copyright];
    [document appendFormat:@"Identifier:        %@\n", self.identifier];
    [document appendFormat:@"Organization:      %@\n", self.organization];
    [document appendFormat:@"Override:          %@\n", self.override];
    [document appendFormat:@"Override text:     %@\n", self.overrideText];
    [document appendFormat:@"Papersize:         %@\n", self.papersize];
    [document appendFormat:@"Database schemas:  %@\n", self.hasDatabaseSchemas];
    [document appendFormat:@"Page header:       %@\n", self.hasPageHeaderSection];
    [document appendFormat:@"Page footer:       %@\n", self.hasPageFooterSection];
    [document appendFormat:@"Report header:     %@\n", self.hasReportHeaderSection];
    [document appendFormat:@"Report footer:     %@\n", self.hasReportFooterSection];
    [document appendFormat:@"*********"];
    return document;
}

@end
