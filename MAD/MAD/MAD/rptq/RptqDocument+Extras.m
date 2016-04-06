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
#import "MTDatabaseConnection.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectBarcode+Extras.h"
#import "RptqDocumentObjectChart.h"
#import "RptqDocumentObjectFormula.h"
#import "RptqDocumentObjectFormula+Extras.h"
#import "RptqDocumentObjectGroupKey.h"
#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelLink.h"

#import "MADErrorContainer.h"
#import "MTDatabaseTable.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>

@implementation RptqDocument (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    request.sortDescriptors = @[sortDescriptor];
    request.fetchLimit = 1;
    
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        identifier = ((RptqDocument *)fetchResults.lastObject).identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
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

- (RptqDatabase *)defaultDatabase {
    return self.hasDatabaseSchemas.anyObject;
}

- (MTPaperType)paperType {
    return self.papersize.unsignedShortValue;
}

- (RptqDocumentSection *)documentSectionForType:(MNSDocumentSectionType)type andLevel:(NSUInteger)level {
    
    switch (type) {
            
        case MNSDocumentSectionTypeBody:
            return self.hasDetailSection;
            break;
            
        case MNSDocumentSectionTypePageHeader:
            return self.hasPageHeaderSection;
            break;
            
        case MNSDocumentSectionTypePageFooter:
            return self.hasPageFooterSection;
            break;
            
        case MNSDocumentSectionTypeReportHeader:
            return self.hasReportHeaderSection;
            break;
            
        case MNSDocumentSectionTypeReportFooter:
            return self.hasReportFooterSection;
            break;
            
        case MNSDocumentSectionTypeGroupHeader:
            return [RptqDocumentSection groupHeaderForLevel: level query: self.defaultDatabase.defaultQuery];
            break;
        case MNSDocumentSectionTypeGroupFooter:
            return [RptqDocumentSection groupFooterForLevel: level query: self.defaultDatabase.defaultQuery];
            break;
        default:
            NSAssert(false, @"Unknown type");
            return nil;
            break;
    }
}


#pragma mark - Static

+ (instancetype)newDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext NS_RETURNS_RETAINED {
    
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
    NSEntityDescription *entityDescription  = [NSEntityDescription entityForName:rptqDocumentName inManagedObjectContext: objectContext];
    RptqDocument *document                  = [[RptqDocument alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:objectContext];

    Class sectionClass = [RptqDocumentSection class];
    NSString *rptqDocumentSection = NSStringFromClass(sectionClass);
    
    Class sectionRowsClass = [RptqDocumentSectionRows class];
    NSString *rptqDocumentSectionRows = NSStringFromClass(sectionRowsClass);

    id hasReportHeaderSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext];
    document.hasReportHeaderSection = hasReportHeaderSection;

    id hasReportFooterSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext];
    document.hasReportFooterSection = hasReportFooterSection;
    
    id hasPageHeaderSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext];
    document.hasPageHeaderSection = hasPageHeaderSection;
    
    id hasPageFooterSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext];
    document.hasPageFooterSection = hasPageFooterSection;
    
    id hasDetailSection = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSection inManagedObjectContext: objectContext];
    document.hasDetailSection = hasDetailSection;
    
    RptqDocumentSectionRows *headerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows1 = [[NSOrderedSet alloc] initWithObject: headerRow];
    document.hasReportHeaderSection.hasRows = hasRows1;
    headerRow.inSection = document.hasReportHeaderSection;

    RptqDocumentSectionRows *footerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows2 = [[NSOrderedSet alloc] initWithObject: footerRow];
    document.hasReportFooterSection.hasRows = hasRows2;
    footerRow.inSection = document.hasReportFooterSection;

    RptqDocumentSectionRows *pageHeaderRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows3 = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
    document.hasPageHeaderSection.hasRows = hasRows3;
    pageHeaderRow.inSection = document.hasPageHeaderSection;
    
    RptqDocumentSectionRows *pageFooterRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows4 = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
    document.hasPageFooterSection.hasRows = hasRows4;
    pageFooterRow.inSection = document.hasPageFooterSection;
    
    RptqDocumentSectionRows *detailSectionRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows inManagedObjectContext: objectContext];
    NSOrderedSet *hasRows5 = [[NSOrderedSet alloc] initWithObject: detailSectionRow];
    document.hasDetailSection.hasRows = hasRows5;
    detailSectionRow.inSection = document.hasDetailSection;
    
    NSNumber *headerType = @(MNSDocumentSectionTypeReportHeader);
    document.hasReportHeaderSection.type = headerType;
    
    NSNumber *footerType = @(MNSDocumentSectionTypeReportFooter);
    document.hasReportFooterSection.type = footerType;

    NSNumber *pageHeaderType = @(MNSDocumentSectionTypePageHeader);
    document.hasPageHeaderSection.type = pageHeaderType;
    
    NSNumber *pageFooterType = @(MNSDocumentSectionTypePageFooter);
    document.hasPageFooterSection.type = pageFooterType;
    
    NSNumber *bodyType = @(MNSDocumentSectionTypeBody);
    document.hasDetailSection.type = bodyType;

    [document.hasReportHeaderSection setInterfaceHeight:44.0000f];
    [document.hasReportFooterSection setInterfaceHeight:44.0000f];
    [document.hasPageHeaderSection setInterfaceHeight:44.0000f];
    [document.hasPageFooterSection setInterfaceHeight:44.0000f];
    [document.hasDetailSection setInterfaceHeight:88.0000f];

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

+ (instancetype)documentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *docFetchRequest = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocument class])];
    docFetchRequest.fetchLimit = 1;
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
    return documents.lastObject;
}

- (void)setLayoutHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForSelectedIndex: sectionRow];
    [section setLayoutHeight: @(height)];
}

- (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForSelectedIndex: sectionRow];
    
    if (section.numberOfRows.unsignedIntegerValue == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > section.numberOfRows.unsignedIntegerValue) {
        
        //Add row
        NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray: section.hasRows.array];
        [newRowToAppend setInSection:section];
        [hasRows addObject:newRowToAppend];
        [section setHasRows:hasRows];
        
    } else if (numberOfRows < section.numberOfRows.unsignedIntegerValue) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray: section.hasRows.array];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [section setHasRows:hasRows];
        [rowToDelete setInSection:nil];
        
    }
    NSNumber *numberOfRowsObj = [NSNumber numberWithUnsignedInteger:numberOfRows];
    [section setNumberOfRows: numberOfRowsObj];
}

- (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForSelectedIndex: sectionRow];
    section.layoutHeight = @(height);
}

- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForSelectedIndex: sectionRow];
    NSNumber *visibility = @(isVisible);
    section.visibility = visibility;
}

- (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForSelectedIndex: sectionRow];
    [section setProducesFormFeed:newPageAfter];
}

- (BOOL)newPageAfterSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForSelectedIndex: sectionRow];
    return [section producesFormFeed];
}

- (void)storeDatabaseConnectionDefination:(MTDatabase *)database forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSNumber *connectionId = @(self.hasDatabaseSchemas.count + 1);
    RptqDatabase *rptqDatabase = [RptqDatabase newDatabaseFactoryForManagedObjectContext: managedObjectContext
                                                                              driverType: database.identifier
                                                                            connectionId: connectionId];
    
    RptqUserCredentals *userCredentals = [RptqUserCredentals newUserCredentalsForManagedObjectContext: managedObjectContext];
    
    NSString *databaseIdentifier = [[NSString alloc] initWithString:database.identifier];
    userCredentals.database_driver_type = databaseIdentifier;
    
    if ([databaseIdentifier isEqualToString:MADIdentifierDatabaseMySQL]) {
        
        if (database.databaseConnection != nil) {
        
            NSNumber *port = [[NSNumber alloc] initWithInteger:database.databaseConnection.port];
            userCredentals.mysql_port = port;

            NSNumber *databaseDriverTypeEnum = [[NSNumber alloc] initWithUnsignedInteger:MNSDatabaseTypeMySQL];
            userCredentals.inDatabase.databaseDriverTypeEnum = databaseDriverTypeEnum;

            NSString *server = [[NSString alloc] initWithString:database.databaseConnection.server];
            userCredentals.mysql_host = server;

            NSString *db = [[NSString alloc] initWithString:database.databaseConnection.database];
            userCredentals.mysql_database = db;
        }
        
    } else if ([databaseIdentifier isEqualToString:MADIdentifierDatabaseTDS]) {
        
        if (database.databaseConnection != nil) {

            NSNumber *port = [[NSNumber alloc] initWithInteger:database.databaseConnection.port];
            userCredentals.tds_port = port;

            NSNumber *databaseDriverTypeEnum = [[NSNumber alloc] initWithUnsignedInteger: MNSDatabaseTypeMicrosoftSqlServer];
            userCredentals.inDatabase.databaseDriverTypeEnum = databaseDriverTypeEnum;
 
            NSString *server = [[NSString alloc] initWithString: database.databaseConnection.server];
            userCredentals.tds_server = server;

            NSString *host = [[NSString alloc] initWithString: database.databaseConnection.server];
            userCredentals.tds_host = host;

            NSString *db  = [[NSString alloc] initWithString: database.databaseConnection.database];
            userCredentals.tds_database = db;
            
        }
        
    } else if ([databaseIdentifier isEqualToString:MADIdentifierDatabaseSqlite3]) {
        
        if (database.databaseConnection != nil) {

// FIXME: Storing Sqlite3 database url in mysql holder.
            NSString *db = [[NSString alloc] initWithString:database.databaseConnection.databaseUrl.path.lastPathComponent];
            userCredentals.mysql_database = db;

            NSNumber *databaseDriverTypeEnum = [[NSNumber alloc] initWithUnsignedInteger: MNSDatabaseTypeSqlite3];
            userCredentals.inDatabase.databaseDriverTypeEnum = databaseDriverTypeEnum;
        }
        
    }
    
    [rptqDatabase setOwnedByUser: userCredentals];
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
        NSError *gotitError                    = nil;
        
        
        NSError *error = NULL;
        NSArray *resultTables = [database getTablesFromConnection:dbconnection error:&error];

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
        
        gotitError = error;
        
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
    NSManagedObjectContext *mangedObjectContext = [self managedObjectContext];
    
    NSNumber *objectTypeObj = defination[MTDocumentObjectDefinationType];
    MTDocumentObjectType objectType = (MTDocumentObjectType)objectTypeObj.unsignedIntegerValue;
    
    NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: entityName
                                                                       inManagedObjectContext: mangedObjectContext];
    
    RptqDocumentObject *documentObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                     insertIntoManagedObjectContext: mangedObjectContext];
    documentObject.origin = CGPointZero;
    documentObject.sizewidth = @(75.0000f);
    documentObject.sizeheight = @(22.0000f);
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            NSString *entityName = NSStringFromClass([RptqDocumentObjectLabelDataField class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName inManagedObjectContext: mangedObjectContext];
            
            NSManagedObjectID *fieldObjectId = defination[MTDocumentObjectDefinationObject];
            RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId managedObjectContext: mangedObjectContext];
            
            
            RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                                       insertIntoManagedObjectContext: mangedObjectContext];
            
            documentObject.isLabelDataField = reportObject;
            documentObject.isLabelDataField.referencesQueryField = field;

            reportObject.referencesQueryField = field;
            
            documentObject.type = @(MTDocumentObjectTypeLabelDynamic);
            
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabel class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSString *labelText = defination[MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectLabel *reportObject = [[RptqDocumentObjectLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            
            documentObject.isLabel = reportObject;
            documentObject.isLabel.text = labelText;
            documentObject.type = @(MTDocumentObjectTypeLabelStatic);
            
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectAggregate class])
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
                    [reportObject setAggregateField:field];
                    [reportObject setAggregateFunction:nil];
                    break;
                }
                case MTAggregateFunctionInputTypeFormula: {
                    RptqDocumentObjectFormula *formula =  [RptqDocumentObjectFormula documentObjectForObjectID: objectId
                                                                                          managedObjectContext: mangedObjectContext];
                    [reportObject setAggregateField:nil];
                    [reportObject setAggregateFunction:formula];
                    break;
                }
                default:
                    break;
            }
            
            [documentObject setIsAggregate: reportObject];
            [documentObject setType: @(MTDocumentObjectTypeAggregate)];
            
            break;
        }
        case MTDocumentObjectTypeImage: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectImage class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            UIImage *image = defination[MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectImage *reportObject = [[RptqDocumentObjectImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            reportObject.image = image;
            documentObject.isImage = reportObject;
            documentObject.sizeheight = @(image.size.height);
            documentObject.sizewidth = @(image.size.width);
            documentObject.type = @(MTDocumentObjectTypeImage);
            
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            
            [documentObject setType: @(MTDocumentObjectTypeWhtiespace)];
            
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
            documentObject.type = @(MTDocumentObjectTypeBarcode);
            
            break;
        }
        default:
            break;
    }
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[[self hasDetailSection] hasRows][0] hasObjects]];
    [hasObjects insertObject:documentObject atIndex:0];
    [[[self hasDetailSection] hasRows][0] setHasObjects:hasObjects];
    return documentObject;
}

- (void)removeDocumentObject:(RptqDocumentObject *)documentObject {

    MTDocumentObjectType objectType = documentObject.type.unsignedIntegerValue;
    NSManagedObjectContext *managedObjectContext = documentObject.managedObjectContext;
    
    switch (objectType) {
            
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
    [managedObjectContext save:nil];
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
