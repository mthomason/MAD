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

#import <CoreData/CoreData.h>

#import "RptqDocument+Extras.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"
#import "MTBarcode.h"
#import "Constants.h"
#import "RptqQuery.h"
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

#import "SectionEnumerator.h"

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

- (RptqDatabase *)defaultDatabase {
    return [[self hasDatabaseSchemas] anyObject];
}

- (RptqQuery *)defaultQuery {
    return [[self defaultDatabase] defaultQuery];
}

- (RptqDocumentSection *)documentSectionForType:(MNSDocumentSectionType)type andLevel:(NSUInteger)level {
    
    RptqDocumentSection *documentSection = nil;
    switch (type) {
            
        case MNSDocumentSectionTypeBody:
            documentSection = [self hasDetailSection];
            break;
            
        case MNSDocumentSectionTypePageHeader:
            documentSection = [self hasPageHeaderSection];
            break;
            
        case MNSDocumentSectionTypePageFooter:
            documentSection = [self hasPageFooterSection];
            break;
            
        case MNSDocumentSectionTypeReportHeader:
            documentSection = [self hasReportHeaderSection];
            break;
            
        case MNSDocumentSectionTypeReportFooter:
            documentSection = [self hasReportFooterSection];
            break;
            
        case MNSDocumentSectionTypeGroupHeader: {
            RptqQuery *query = [[self defaultDatabase] defaultQuery];
            documentSection = [RptqDocumentSection groupHeaderForLevel: level
                                                                 query: query];
            break;
        }
        case MNSDocumentSectionTypeGroupFooter: {
            RptqQuery *query = [[self defaultDatabase] defaultQuery];
            documentSection = [RptqDocumentSection groupFooterForLevel: level
                                                                 query: query];
            break;
        }
        default:
            NSAssert(false, @"Unknown type");
            break;
    }
    return documentSection;
}


#pragma mark - Static

+ (instancetype)documentFactory:(NSManagedObjectContext *)objectContext {
    
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

+ (instancetype)documentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    Class docClass = [RptqDocument class];
    NSString *entityName = NSStringFromClass(docClass);
    NSFetchRequest *docFetchRequest = [[NSFetchRequest alloc] initWithEntityName: entityName];
    [docFetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
    return [documents lastObject];
}

- (void)setLayoutHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [RptqDocumentSection documentSectionForRow: sectionRow query: query];
    [section setLayoutHeight: @(height)];
}

- (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [RptqDocumentSection documentSectionForRow: sectionRow query: query];
    
    if ([[section numberOfRows] integerValue] == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > [[section numberOfRows] integerValue]) {
        
        //Add row
        NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[section hasRows] array]];
        [newRowToAppend setInSection:section];
        [hasRows addObject:newRowToAppend];
        [section setHasRows:hasRows];
        
    } else if (numberOfRows < [[section numberOfRows] integerValue]) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = [[section hasRows] lastObject];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[section hasRows] array]];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [section setHasRows:hasRows];
        [rowToDelete setInSection:nil];
        
    }
    [section setNumberOfRows: [NSNumber numberWithInteger:numberOfRows]];
}

- (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [RptqDocumentSection documentSectionForRow: sectionRow query: query];
    [section setLayoutHeight: @(height)];
}

- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [RptqDocumentSection documentSectionForRow: sectionRow query: query];
    NSNumber *visibility = [NSNumber numberWithBool:isVisible];
    [section setVisibility: visibility];
}

- (NSDictionary *)layoutHeightsBySectionKey {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithDocument:self];
    NSString *marginLeftMethod = NSStringFromSelector(@selector(marginLeft));
    for (RptqDocumentSection *sec in enumerator) {
        @autoreleasepool {
            [sec valueForKey:marginLeftMethod]; //Fire fault
            NSString *sectionKey = [sec sectionKey];
            dictionary[sectionKey] = @([sec layoutHeightCalculated]);
        }
    }
    return dictionary;
}

- (void)addDatabase:(MTDatabase *)database
             status:(void (^)(NSString *readStatus))status
         completion:(void (^)(BOOL success, NSError *error))completion {
    
    __weak RptqDocument *rptqDocument = self;
    __weak NSManagedObjectContext *managedObjectContext = [rptqDocument managedObjectContext];
    
    NSNumber *connectionId = @([[rptqDocument hasDatabaseSchemas] count] + 1);
    __weak RptqDatabase *rptqDatabase = [RptqDatabase databaseFactoryForManagedObjectContext: managedObjectContext
                                                                             driverType: [database identifier]
                                                                           connectionId: connectionId];
    __weak RptqUserCredentals *userCredentals = [RptqUserCredentals userCredentalsFactory: managedObjectContext];
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
    __weak NSManagedObjectContext *weakManagedObjectContext = managedObjectContext;
    __weak RptqDatabase *weakRptqDatabase = rptqDatabase;
    
    [database connectWithCredentals:[database databaseConnection] completion:^(id dbconnection, BOOL success, NSError *connectionError) {
        
        __weak id weakdbconnection = dbconnection;
        __weak MTDatabase *weakDatabase2 = weakDatabase;
        
        [weakDatabase getTablesFromConnection:dbconnection completion:^(BOOL success, NSError *error, NSArray *tables) {
            
            if (success) {
            
                __block NSUInteger tableCounter = 0;
                NSUInteger numberOfTables = [tables count];
                
                for (MTDatabaseTable *databaseTable in tables) {
                    
                    @autoreleasepool {
                        
                        RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable databaseSchemaTableFactoryForManagedObjectContext: weakManagedObjectContext andTable: databaseTable];
                        [weakRptqDatabase addHasTablesObject: rptqTable];
                        
                        NSError *error = nil;
                        [[weakRptqDatabase managedObjectContext] save:&error];
                        
                        __weak NSManagedObjectContext *weakManagedObjectContext2 = weakManagedObjectContext;
                        __weak NSString *weakTableName = [databaseTable name];
                        __weak RptqDatabaseSchemaTable *weakRptqTable = rptqTable;
                        
                        [weakDatabase2 getFieldsForTableName:weakTableName connection:weakdbconnection completion:^(BOOL success, NSError *error, NSArray *fields) {
                            if (success) {
                                for (MTDatabaseField *objField in fields) {
                                    @autoreleasepool {

                                        RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField databaseSchemaFieldFactoryForManagedObjectContext: weakManagedObjectContext2 andField: objField];
                                        
                                        NSMutableOrderedSet *fieldSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:[weakRptqTable hasFields]];
                                        [fieldSet addObject:schemaField];
                                        [weakRptqTable setHasFields:fieldSet];
                                        
                                        NSError *saveError = nil;
                                        [[schemaField managedObjectContext] save:&saveError];
                                        NSAssert(saveError == nil, @"%@", saveError);
                                        status([NSString stringWithFormat:@"Whatup count %d", tableCounter]);
                                    }
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
                }
            } else {
                completion(success, error);
            }
            [weakDatabase2 closeProcess:weakdbconnection];
        }];
    }];
}

- (void)addQueryLink:(RptqQueryLinks *)queryLink {
    NSSet *linkSet = [NSSet setWithObject: queryLink];
    [[[self defaultDatabase] defaultQuery] addHasQueryLinks: linkSet];
}

- (void)addPredicate:(RptqQueryPredicate *)predicate {
    
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    NSSet *predicates = [NSSet setWithObject: predicate];
    [query addHasQueryPredicate:predicates];
    
}

- (RptqDocumentObject *)addDocumentObject:(NSDictionary *)defination {
    NSManagedObjectContext *mangedObjectContext = [self managedObjectContext];
    
    MTDocumentObjectType objectType = [[defination objectForKey:MTDocumentObjectDefinationType] integerValue];
    
    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: mangedObjectContext];
    
    RptqDocumentObject *documentObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                     insertIntoManagedObjectContext: mangedObjectContext];
    [documentObject setOrigin:CGPointZero];
    [documentObject setSizewidth: @(75.0000f)];
    [documentObject setSizeheight: @(22.0000f)];
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabelDataField class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSManagedObjectID *fieldObjectId = [defination objectForKey: MTDocumentObjectDefinationObject];
            RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId
                                                     managedObjectContext: mangedObjectContext];
            
            
            RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                                       insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsLabelDataField: reportObject];
            [[documentObject isLabelDataField] setReferencesQueryField: field];
            
            [reportObject setReferencesQueryField: field];
            
            [documentObject setType: @(MTDocumentObjectTypeLabelDynamic)];
            
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabel class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSString *labelText = [defination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectLabel *reportObject = [[RptqDocumentObjectLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsLabel: reportObject];
            [[documentObject isLabel] setText: labelText];
            
            [documentObject setType: @(MTDocumentObjectTypeLabelStatic)];
            
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectAggregate class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSDictionary *aggregateOptions = [defination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectAggregate *reportObject = [[RptqDocumentObjectAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                             insertIntoManagedObjectContext: [self managedObjectContext]];
            
            NSNumber *groupTypeContainer = [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregatePivotType];
            NSNumber *functionInputType = [aggregateOptions objectForKey:MTDocumentObjectDefinationAggregateFunctionInputType];
            
            MTAggregateFunctionInputType functionType = [functionInputType integerValue];
            [reportObject setGroupNumber:   [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregatePivotNumber]];
            [reportObject setGroupType:     groupTypeContainer];
            [reportObject setFunction:      [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregateType]];
            
            NSManagedObjectID *objectId = [aggregateOptions objectForKey:MTDocumentObjectDefinationAggregateObjectId];
            
            switch (functionType) {
                case MTAggregateFunctionInputTypeField: {
                    RptqQueryField *field = [RptqQueryField queryFieldForObjectID:objectId managedObjectContext:mangedObjectContext];
                    [reportObject setAggregateField:field];
                    [reportObject setAggregateFunction:nil];
                    break;
                }
                case MTAggregateFunctionInputTypeFormula: {
                    RptqDocumentObjectFormula *formula =  [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:mangedObjectContext];
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
            
            UIImage *image = [defination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectImage *reportObject = [[RptqDocumentObjectImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            [reportObject setImage:image];
            [documentObject setIsImage: reportObject];
            [documentObject setSizeheight:@([image size].height)];
            [documentObject setSizewidth:@([image size].width)];
            [documentObject setType: @(MTDocumentObjectTypeImage)];
            
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            
            [documentObject setType: @(MTDocumentObjectTypeWhtiespace)];
            
            break;
        }
        case MTDocumentObjectTypeBarcode: {
            
            MTBarcode *barcode = [defination objectForKey:MTDocumentObjectDefinationObject];
            NSManagedObjectID *field1ObjectId = [defination objectForKey:MTDocumentObjectDefinationField1];
            NSManagedObjectID *field2ObjectId = [defination objectForKey:MTDocumentObjectDefinationField2];
            RptqQueryField *field1 = [RptqQueryField queryFieldForObjectID:field1ObjectId managedObjectContext:mangedObjectContext];
            RptqQueryField *field2 = [RptqQueryField queryFieldForObjectID:field2ObjectId managedObjectContext:mangedObjectContext];
            RptqDocumentObjectBarcode *reportObject = [RptqDocumentObjectBarcode barcodeWithMtBarcode:barcode queryFieldOne:field1 queryFieldTwo:field2];
            
            [documentObject setIsBarcode: reportObject];
            [documentObject setType: @(MTDocumentObjectTypeBarcode)];
            
            break;
        }
        default:
            break;
    }
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[[[self hasDetailSection] hasRows] objectAtIndex:0] hasObjects]];
    [hasObjects insertObject:documentObject atIndex:0];
    [[[[self hasDetailSection] hasRows] objectAtIndex:0] setHasObjects:hasObjects];
    return documentObject;
}

- (void)removeDocumentObject:(RptqDocumentObject *)documentObject {
    MTDocumentObjectType objectType = [[documentObject type] integerValue];
    NSManagedObjectContext *managedObjectContext = [documentObject managedObjectContext];
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            [managedObjectContext deleteObject:[documentObject isLabelDataField]];
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            [managedObjectContext deleteObject:[documentObject isLabel]];
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            [managedObjectContext deleteObject:[documentObject isAggregate]];
            break;
        }
        case MTDocumentObjectTypeImage: {
            [managedObjectContext deleteObject:[documentObject isImage]];
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            break;
        }
        case MTDocumentObjectTypeBarcode: {
            [managedObjectContext deleteObject:[documentObject isBarcode]];
            break;
        }
        default:
            break;
    }
    [managedObjectContext deleteObject: documentObject];
    [managedObjectContext save:nil];
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
