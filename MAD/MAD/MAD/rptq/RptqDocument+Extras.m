//
//  NSObject+RptqDocument_Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocument+Extras.h"

#import <os/log.h>
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

#import "MADDatabaseConnectionsPropertiesCredentals.h"
#import "MADDatabaseConnectionsPropertiesURLProtocol.h"

#import "MADDatabaseConnection.h"
#import "MTDatabase.h"

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
#import "MADDatabaseTable.h"
#import "MADReportSectionsEnumerator.h"

#import "RptqDataHelper.h"

@implementation RptqDocument (Extras)

#pragma mark - Static

+ (instancetype)newDocumentForManagedObjectContext:(NSManagedObjectContext *)context {
    
    NSString *rptqDocumentName = NSStringFromClass([RptqDocument class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: rptqDocumentName];
    
    NSError * __autoreleasing error = nil;
    NSArray *documents = [context executeFetchRequest:request error:&error];
    
    if (!error) {
        //Delete any contents of the existing object modal.
        if (documents && documents.count > 0) {
            for (RptqDocument *document in documents) {
                [context deleteObject:document];
            }
        }
    }
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: rptqDocumentName
                                                         inManagedObjectContext: context];
    
    RptqDocument *document = [[RptqDocument alloc] initWithEntity: entityDescription
                                   insertIntoManagedObjectContext: context];
    
    NSString *docSection = NSStringFromClass([RptqDocumentSection class]);
    NSString *rptqDocumentSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);

    RptqDocumentSection *hasReportHeaderSection;
    hasReportHeaderSection = [NSEntityDescription insertNewObjectForEntityForName: docSection
                                                           inManagedObjectContext: context];
    hasReportHeaderSection.identifier = 1;
    document.hasReportHeaderSection = hasReportHeaderSection;
    
    RptqDocumentSection *hasReportFooterSection;
    hasReportFooterSection = [NSEntityDescription insertNewObjectForEntityForName: docSection
                                                           inManagedObjectContext: context];
    hasReportFooterSection.identifier = 2;
    document.hasReportFooterSection = hasReportFooterSection;
    
    RptqDocumentSection *hasPageHeaderSection;
    hasPageHeaderSection = [NSEntityDescription insertNewObjectForEntityForName: docSection
                                                         inManagedObjectContext: context];
    hasPageHeaderSection.identifier = 3;
    document.hasPageHeaderSection = hasPageHeaderSection;
    
    RptqDocumentSection *hasPageFooterSection;
    hasPageFooterSection = [NSEntityDescription insertNewObjectForEntityForName: docSection
                                                         inManagedObjectContext: context];
    hasPageFooterSection.identifier = 4;
    document.hasPageFooterSection = hasPageFooterSection;
    
    RptqDocumentSection *hasDetailSection;
    hasDetailSection = [NSEntityDescription insertNewObjectForEntityForName: docSection
                                                     inManagedObjectContext: context];
    hasDetailSection.identifier = 5;
    document.hasDetailSection = hasDetailSection;
    
    RptqDocumentSectionRows *headerRow;
    headerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                              inManagedObjectContext: context];
    NSOrderedSet *hasRows1 = [[NSOrderedSet alloc] initWithObject: headerRow];
    document.hasReportHeaderSection.hasRows = hasRows1;
    headerRow.inSection = document.hasReportHeaderSection;

    RptqDocumentSectionRows *footerRow;
    footerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                              inManagedObjectContext: context];
    NSOrderedSet *hasRows2 = [[NSOrderedSet alloc] initWithObject: footerRow];
    document.hasReportFooterSection.hasRows = hasRows2;
    footerRow.inSection = document.hasReportFooterSection;

    RptqDocumentSectionRows *pageHeaderRow;
    pageHeaderRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                  inManagedObjectContext: context];
    NSOrderedSet *hasRows3 = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
    document.hasPageHeaderSection.hasRows = hasRows3;
    pageHeaderRow.inSection = document.hasPageHeaderSection;
    
    RptqDocumentSectionRows *pageFooterRow;
    pageFooterRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                  inManagedObjectContext: context];
    NSOrderedSet *hasRows4 = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
    document.hasPageFooterSection.hasRows = hasRows4;
    pageFooterRow.inSection = document.hasPageFooterSection;
    
    RptqDocumentSectionRows *detailSectionRow;
    detailSectionRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
                                                     inManagedObjectContext: context];
    NSOrderedSet *hasRows5 = [[NSOrderedSet alloc] initWithObject: detailSectionRow];
    document.hasDetailSection.hasRows = hasRows5;
    detailSectionRow.inSection = document.hasDetailSection;
    
    document.hasReportHeaderSection.type = MADDocumentSectionTypeReportHeader;
    document.hasReportFooterSection.type = MADDocumentSectionTypeReportFooter;
    document.hasPageHeaderSection.type = MADDocumentSectionTypePageHeader;
    document.hasPageFooterSection.type = MADDocumentSectionTypePageFooter;
    document.hasDetailSection.type = MADDocumentSectionTypeBody;

    [document.hasReportHeaderSection    setInterfaceHeight: 44.0000f];
    [document.hasReportFooterSection    setInterfaceHeight: 44.0000f];
    [document.hasPageHeaderSection      setInterfaceHeight: 44.0000f];
    [document.hasPageFooterSection      setInterfaceHeight: 44.0000f];
    [document.hasDetailSection          setInterfaceHeight: 88.0000f];

    document.hasReportHeaderSection.visibility = YES;
    document.hasReportFooterSection.visibility = YES;
    document.hasPageHeaderSection.visibility = YES;
    document.hasPageFooterSection.visibility = YES;
    document.hasDetailSection.visibility = YES;

    if (![hasReportHeaderSection validateForUpdate: &error]) {
        os_log_error(OS_LOG_DEFAULT, "Error: %s", error.localizedDescription.UTF8String);
    }
    
    if (![hasDetailSection validateForUpdate: &error]) {
        os_log_error(OS_LOG_DEFAULT, "Error: %s", error.localizedDescription.UTF8String);
    }
    
    error = nil;
    if (![document validateForUpdate: &error]) {
        os_log_error(OS_LOG_DEFAULT, "Error: %s", error.localizedDescription.UTF8String);
    }
    
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

#pragma mark - Overrides

- (void)willTurnIntoFault {
    [super willTurnIntoFault];
}

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
}

- (void)willChangeValueForKey:(NSString *)inKey
              withSetMutation:(NSKeyValueSetMutationKind)inMutationKind
                 usingObjects:(NSSet *)inObjects {
    [super willChangeValueForKey: inKey
                 withSetMutation: inMutationKind
                    usingObjects: inObjects];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = 1;
    if (self.managedObjectContext.parentContext && self.identifier <= 0) {
        [[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
        self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                            managedObjectContext:self.managedObjectContext];
        [[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
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

- (RptqDocumentSection *)documentSectionForType:(MADDocumentSectionType)type
                                       andLevel:(NSUInteger)level {
    
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
            return [RptqDocumentSection groupHeaderForLevel: level
                                                      query: self.defaultDatabase.defaultQuery];
            break;
        case MADDocumentSectionTypeGroupFooter:
            return [RptqDocumentSection groupFooterForLevel: level
                                                      query: self.defaultDatabase.defaultQuery];
            break;
        default:
            NSAssert(NO, @"Unknown type: %lld at level %ld", type, level);
            return nil;
            break;
    }
}

- (void)setLayoutHeight:(float)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    section.layoutHeight = height;
}

- (void)setNumberOfRows:(int32_t)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = self.defaultDatabase.defaultQuery;
    RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
                                                      withNumberOfGroups: query.hasQueryGroups.count];
    
    if (section.numberOfRows == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > section.numberOfRows) {
        
        //Add row
        NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
        NSString *entityNameSectionRows;
        RptqDocumentSectionRows *newRowToAppend;

        entityNameSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);
        newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: entityNameSectionRows
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

- (void)setHeight:(double)height forSectionAtRow:(NSUInteger)sectionRow {
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

- (void)storeDatabaseConnectionDefination:(MTDatabase *)database
                  forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    int64_t cid = (int64_t)self.hasDatabaseSchemas.count + 1;
    RptqDatabase *rptqDB = [RptqDatabase newDatabaseFactoryForManagedObjectContext: managedObjectContext
                                                                              driverType: database.identifier
                                                                            connectionId: cid];
    
    RptqDatabaseCredentals *credentals;
    credentals = [RptqDatabaseCredentals newDatabaseCredental: managedObjectContext];
    
    NSString *databaseIdentifier = [[NSString alloc] initWithString:database.identifier];
    credentals.driverID = databaseIdentifier;

    if (database.databaseConnection != nil) {
        
        switch (database.databaseConnection.databaseType) {
            case MADDatabaseTypeMySQL: {
                MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *databaseConnection;
                databaseConnection = (MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *)database.databaseConnection;
                credentals.port = databaseConnection.port;
                credentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
                credentals.host = databaseConnection.server.copy;
                credentals.dbname = databaseConnection.database.copy;
                break;
            }

            case MADDatabaseTypeSqlite3: {
                MADDatabaseConnection *databaseConnection;
                databaseConnection = database.databaseConnection;
                credentals.dbname = ((id <MADDatabaseConnectionsPropertiesURL>)databaseConnection).databaseUrl.path.lastPathComponent.copy;
                credentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
                break;
            }

            case MADDatabaseTypeTDS: {
                MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *databaseConnection;
                databaseConnection = (MADDatabaseConnection <MADDatabaseConnectionsPropertiesCredentals> *)database.databaseConnection;
                credentals.port = databaseConnection.port;
                credentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeTDS;
                credentals.server = databaseConnection.server.copy;
                credentals.host = databaseConnection.server.copy;
                credentals.dbname = databaseConnection.database.copy;
                break;
            }
                
            default:
                break;
        }
    }
    
    rptqDB.ownedByUser = credentals;
    NSString *rptqQueryId = NSStringFromClass([RptqQuery class]);
    RptqQuery *newQuery = [NSEntityDescription insertNewObjectForEntityForName: rptqQueryId
                                                        inManagedObjectContext: managedObjectContext];
    [rptqDB addHasQueriesObject:newQuery];
    
    
    NSSet *databaseSchemas = [self.hasDatabaseSchemas setByAddingObject: rptqDB];
    NSSet *dbs = [[NSSet alloc] initWithSet:databaseSchemas];
    self.hasDatabaseSchemas = dbs;

}

- (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables
                                       fieldsByTable:(NSDictionary *)fieldsByTable
                             andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    MADErrorContainer * __autoreleasing errorContainer = [[MADErrorContainer alloc] init];
    for (MADDatabaseTable *table in tables) {
        
        NSArray *fields = fieldsByTable[table.name];
        
        if (fields.count) {
            
            RptqDatabaseSchemaTable *rptqTable;
            rptqTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext: managedObjectContext
                                                                                             andTable: table];
            [self.defaultDatabase addHasTablesObject: rptqTable];
            
            NSMutableArray <RptqDatabaseSchemaField *> *schemaFields;
            schemaFields = [[NSMutableArray alloc] initWithCapacity:fields.count];
            RptqDatabaseSchemaField *schemaField;
            for (MADDatabaseField *field in fields) {
                schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext: managedObjectContext
                                                                                                   andField: field];
                [schemaFields addObject:schemaField];
            }
            
            NSOrderedSet *hasFields = [[NSOrderedSet alloc] initWithArray:schemaFields];
            rptqTable.hasFields = hasFields;
            
            BOOL success = NO;
            NSError * __autoreleasing saveError = nil;
            if (!(success = [rptqTable.managedObjectContext save:&saveError])) {
                os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", saveError.localizedDescription.UTF8String);
            }

        } else {
            
            NSString *failureFormat = NSLocalizedString(@"Table %@ not Added.", @"Table %@ not Added.");
            NSString *description = NSLocalizedString(@"Fields not found.", @"Fields not found.");
            NSString *failure = [[NSString alloc] initWithFormat:failureFormat, table.name];
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
    
    NSString *entityName;
    
    RptqDocumentElement *reportObject;
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            NSManagedObjectID *fieldObjectID;
            RptqQueryField *field;
            
            entityName = NSStringFromClass([RptqDocumentElementLabelDataField class]);
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: managedObjectContext];
            
            fieldObjectID = defination[MTDocumentObjectDefinationObject];
            field = (RptqQueryField *)[managedObjectContext objectWithID:fieldObjectID];
            
            
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
            ((RptqDocumentElementAggregate *)reportObject).groupNumber = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotNumber] intValue];
            ((RptqDocumentElementAggregate *)reportObject).groupType = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotType] shortValue];
            ((RptqDocumentElementAggregate *)reportObject).functionType = [aggregateOptions[MTDocumentObjectDefinationAggregateType] shortValue];
            
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

- (id)debugQuickLookObject {
    NSMutableString *document = [[NSMutableString alloc] init];
    [document appendFormat:@"*********\n"];
    [document appendFormat:@"Number of sections %lu\n", (unsigned long)[((RptqQuery *)((RptqDatabase *)self.hasDatabaseSchemas.anyObject).hasQueries.anyObject) sectionCount]];
    [document appendFormat:@"Identifier:        %lld\n", self.identifier];
    [document appendFormat:@"Papersize:         %hd\n", self.papersize];
    [document appendFormat:@"Database schemas:  %@\n", self.hasDatabaseSchemas];
    [document appendFormat:@"Page header:       %@\n", self.hasPageHeaderSection];
    [document appendFormat:@"Page footer:       %@\n", self.hasPageFooterSection];
    [document appendFormat:@"Report header:     %@\n", self.hasReportHeaderSection];
    [document appendFormat:@"Report footer:     %@\n", self.hasReportFooterSection];
    [document appendFormat:@"*********"];
    return document;
}

@end
