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

#import "MADDatabaseConnection.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"

#import "RptqQueryGroup+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqQuery+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqDatabaseCredentals+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentElement+Extras.h"

#import "RptqDocumentElementChart.h"
#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementLabelLink.h"

#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "RptqDocumentElementFormula+Extras.h"

#import "MADErrorContainer.h"
#import "MTDatabaseTable.h"

#import "MADReportSectionsEnumerator.h"

#import "RptqDataHelper.h"

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
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
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
    return self.papersize;
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
            RptqDatabase *database = self.hasDatabaseSchemas.anyObject;
            RptqQuery *query = database.hasQueries.anyObject;
            RptqQueryGroup *group = [query queryGroupForIndex:
                                     queryGroupIndexForSelectedIndexOfTypeHeader(selectedIndex)];
            resultSection = [RptqDocumentSection headerSectionInSections:group.hasSection];
            break;
        }
            
        case MADDocumentSectionTypeGroupFooter: {
            RptqDatabase *database = self.hasDatabaseSchemas.anyObject;
            RptqQuery *query = database.hasQueries.anyObject;
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

    NSString *rptqDocumentSection = NSStringFromClass([RptqDocumentSection class]);
    NSString *rptqDocumentSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);

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

- (void)setLayoutHeight:(float)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    section.layoutHeight = height;
}

- (void)setNumberOfRows:(int64_t)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    
    if (section.numberOfRows == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > section.numberOfRows) {
        
        //Add row
        NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
        RptqDocumentSectionRows *newRowToAppend;
        newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                       inManagedObjectContext: managedObjectContext];
        NSArray *hasRowsArray = section.hasRows.array;
        NSMutableOrderedSet *hasRows;
        hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
                                        [[NSMutableOrderedSet alloc] init];
        newRowToAppend.inSection = section;
        [hasRows addObject:newRowToAppend];
        section.hasRows = hasRows;
        
    } else if (numberOfRows < section.numberOfRows) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
        NSArray *hasRowsArray = section.hasRows.array;
        NSMutableOrderedSet *hasRows;
        hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
                                        [[NSMutableOrderedSet alloc] init];
        [hasRows.lastObject setInSection:nil];
        [hasRows removeObjectAtIndex: hasRows.count - 1];
        section.hasRows = hasRows;
        [rowToDelete setInSection:nil];
        
    }
    section.numberOfRows = numberOfRows;
}

- (void)setHeight:(float)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    section.layoutHeight = height;
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

    int64_t cid = (int64_t)self.hasDatabaseSchemas.count + 1;
    RptqDatabase *rptqDatabase = [RptqDatabase newDatabaseFactoryForManagedObjectContext: managedObjectContext
                                                                              driverType: database.identifier
                                                                            connectionId: cid];
    
    RptqDatabaseCredentals *userCredentals = [RptqDatabaseCredentals newUserCredentalForManagedObjectContext: managedObjectContext];
    
    NSString *databaseIdentifier = [[NSString alloc] initWithString:database.identifier];
    userCredentals.driver_type = databaseIdentifier;

    if (database.databaseConnection != nil) {
        
        switch (database.databaseConnection.databaseType) {
            case MADDatabaseTypeMySQL: {
                MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *databaseConnection;
                databaseConnection = (MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *)database.databaseConnection;
                userCredentals.port = databaseConnection.port;
                userCredentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
                userCredentals.host = databaseConnection.server.copy;
                userCredentals.database = databaseConnection.database.copy;
                break;
            }

            case MADDatabaseTypeSqlite3: {
                MADDatabaseConnection *databaseConnection;
                databaseConnection = database.databaseConnection;
                userCredentals.database = ((id <MADDatabaseConnectionsPropertiesURL>)databaseConnection).databaseUrl.path.lastPathComponent.copy;
                userCredentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
                break;
            }

            case MADDatabaseTypeTDS: {
                MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *databaseConnection;
                databaseConnection = (MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *)database.databaseConnection;
                userCredentals.port = databaseConnection.port;
                userCredentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeTDS;
                userCredentals.server = databaseConnection.server.copy;
                userCredentals.host = databaseConnection.server.copy;
                userCredentals.database = databaseConnection.database.copy;
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

- (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables
                                       fieldsByTable:(NSDictionary *)fieldsByTable
                             andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    MADErrorContainer * __autoreleasing errorContainer = [[MADErrorContainer alloc] init];
    for (MTDatabaseTable *table in tables) {
        
        NSString *tableName = table.name;
        NSArray *fields = fieldsByTable[table.name];
        
        if (fields.count) {
            
            RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext: managedObjectContext andTable: table];
            [self.defaultDatabase addHasTablesObject: rptqTable];
            
            NSMutableArray <MTDatabaseField *> *schemaFields;
            schemaFields = [[NSMutableArray alloc] initWithCapacity:fields.count];
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

- (RptqDocumentElement *)addDocumentObject:(NSDictionary *)defination {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    
    NSNumber *objectTypeObj = defination[MTDocumentObjectDefinationType];
    MTDocumentObjectType objectType = (MTDocumentObjectType)objectTypeObj.unsignedIntegerValue;
    
    NSString *entityName = NSStringFromClass([RptqDocumentElement class]);
    
    RptqDocumentElement *reportObject;
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            NSManagedObjectID *fieldObjectId;
            RptqQueryField *field;
            
            entityName = NSStringFromClass([RptqDocumentElementLabelDataField class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: managedObjectContext];
            
            fieldObjectId = defination[MTDocumentObjectDefinationObject];
            field = (RptqQueryField *)[managedObjectContext objectWithID:fieldObjectId];
            
            
            reportObject = [[RptqDocumentElementLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                     insertIntoManagedObjectContext: managedObjectContext];
            
            ((RptqDocumentElementLabelDataField *)reportObject).referencesQueryField = field;

            ((RptqDocumentElementLabelDataField *)reportObject).referencesQueryField = field;
            
            reportObject.type = MTDocumentObjectTypeLabelDynamic;
            
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            
            entityName = NSStringFromClass([RptqDocumentElementLabel class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: managedObjectContext];
            
            NSString *labelText = defination[MTDocumentObjectDefinationObject];
            
            reportObject = [[RptqDocumentElementLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                             insertIntoManagedObjectContext: managedObjectContext];
            
            ((RptqDocumentElementLabel *)reportObject).text = labelText;

            reportObject.type = MTDocumentObjectTypeLabelStatic;
            
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            
            entityName = NSStringFromClass([RptqDocumentElementAggregate class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: managedObjectContext];
            
            NSDictionary *aggregateOptions = defination[MTDocumentObjectDefinationObject];
            reportObject = [[RptqDocumentElementAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                             insertIntoManagedObjectContext: self.managedObjectContext];
            
            NSNumber *functionInputType = aggregateOptions[MTDocumentObjectDefinationAggregateFunctionInputType];
            ((RptqDocumentElementAggregate *)reportObject).groupNumber = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotNumber] integerValue];
            ((RptqDocumentElementAggregate *)reportObject).groupType = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotType] integerValue];
            ((RptqDocumentElementAggregate *)reportObject).functionType = [aggregateOptions[MTDocumentObjectDefinationAggregateType] integerValue];
            
            NSManagedObjectID *objectId = aggregateOptions[MTDocumentObjectDefinationAggregateObjectId];
            
            switch ((MTAggregateFunctionInputType)functionInputType.integerValue) {
                case MTAggregateFunctionInputTypeField: {
                    RptqQueryField *field = [RptqQueryField queryFieldForObjectID: objectId
                                                             managedObjectContext: managedObjectContext];
                    ((RptqDocumentElementAggregate *)reportObject).aggregateField = field;
                    [((RptqDocumentElementAggregate *)reportObject) setAggregateFunction:nil];
                    break;
                }
                case MTAggregateFunctionInputTypeFormula: {
                    RptqDocumentElementFormula *formula =  [managedObjectContext objectWithID: objectId];
                    [((RptqDocumentElementAggregate *)reportObject) setAggregateField:nil];
                    ((RptqDocumentElementAggregate *)reportObject).aggregateFunction = formula;
                    break;
                }
                default:
                    break;
            }
            
            reportObject.type = MTDocumentObjectTypeAggregate;
            
            break;
        }
        case MTDocumentObjectTypeImage: {
            
            entityName = NSStringFromClass([RptqDocumentElementImage class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: managedObjectContext];
            
            UIImage *image = defination[MTDocumentObjectDefinationObject];
            
            reportObject = [[RptqDocumentElementImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                            insertIntoManagedObjectContext: managedObjectContext];
            ((RptqDocumentElementImage *)reportObject).image = image;

            [((RptqDocumentElementImage *)reportObject) setSizeValue: image.size];
            ((RptqDocumentElementImage *)reportObject).type = MTDocumentObjectTypeImage;
            
            image = nil;
            
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            reportObject.type = MTDocumentObjectTypeWhtiespace;
            
            break;
        }
        case MTDocumentObjectTypeBarcode: {
            
            MTBarcode *barcode = defination[MTDocumentObjectDefinationObject];
            NSManagedObjectID *field1ObjectId = defination[MTDocumentObjectDefinationField1];
            NSManagedObjectID *field2ObjectId = defination[MTDocumentObjectDefinationField2];
            RptqQueryField *field1 = [RptqQueryField queryFieldForObjectID: field1ObjectId
                                                      managedObjectContext: managedObjectContext];
            RptqQueryField *field2 = [RptqQueryField queryFieldForObjectID: field2ObjectId
                                                      managedObjectContext: managedObjectContext];
            reportObject = [RptqDocumentElementBarcode barcodeWithMtBarcode: barcode
                                                             queryFieldOne: field1
                                                             queryFieldTwo: field2];
            reportObject.type = MTDocumentObjectTypeBarcode;
            
            break;
        }
        default:
            break;
    }
    [reportObject setOriginPoint:CGPointZero];
    [reportObject setSizeWidth:75.0000f height:22.0000f];
    
    NSMutableOrderedSet *hasObjects = [self.hasDetailSection.hasRows[0] hasObjects].mutableCopy;
    [hasObjects insertObject:reportObject atIndex:0];
    [self.hasDetailSection.hasRows[0] setHasObjects:hasObjects];
    return reportObject;
}

+ (void)removeDocumentObject:(RptqDocumentElement *)documentObject
    fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

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
