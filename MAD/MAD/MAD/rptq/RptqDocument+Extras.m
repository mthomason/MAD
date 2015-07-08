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
#import "MTBarcode.h"
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

#import "MTErrorContainer.h"
#import "MTDatabaseTable.h"

#import "MTAggregateFunctionInputType.h"

@implementation RptqDocument (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
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
    return self.hasDatabaseSchemas.anyObject;
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
    RptqDocumentSection *section = [query documentSectionForRow: sectionRow];
    [section setLayoutHeight: @(height)];
}

- (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForRow: sectionRow];
    
    if (section.numberOfRows.integerValue == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > section.numberOfRows.integerValue) {
        
        //Add row
        NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray: section.hasRows.array];
        [newRowToAppend setInSection:section];
        [hasRows addObject:newRowToAppend];
        [section setHasRows:hasRows];
        
    } else if (numberOfRows < section.numberOfRows.integerValue) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray: section.hasRows.array];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [section setHasRows:hasRows];
        [rowToDelete setInSection:nil];
        
    }
    [section setNumberOfRows: [NSNumber numberWithInteger:numberOfRows]];
}

- (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForRow: sectionRow];
    section.layoutHeight = @(height);
}

- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForRow: sectionRow];
    NSNumber *visibility = @(isVisible);
    section.visibility = visibility;
}

- (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForRow: sectionRow];
    [section setProducesFormFeed:newPageAfter];
}

- (BOOL)newPageAfterSectionAtRow:(NSInteger)sectionRow {
    RptqQuery *query = [[self defaultDatabase] defaultQuery];
    RptqDocumentSection *section = [query documentSectionForRow: sectionRow];
    return [section producesFormFeed];
}

- (void)addDatabase:(MTDatabase *)database
             status:(void (^)(NSString *status, CGFloat progress))status
         completion:(void (^)(BOOL success, MTErrorContainer *error))completion {
    
    __block MTErrorContainer *errorContainer = [MTErrorContainer new];
    __weak RptqDocument *rptqDocument = self;
    __weak NSManagedObjectContext *managedObjectContext = [rptqDocument managedObjectContext];
    NSNumber *connectionId = @([[rptqDocument hasDatabaseSchemas] count] + 1);
    __weak RptqDatabase *rptqDatabase = [RptqDatabase databaseFactoryForManagedObjectContext: managedObjectContext
                                                                                  driverType: database.identifier
                                                                                connectionId: connectionId];
    
    __weak RptqUserCredentals *userCredentals = [RptqUserCredentals userCredentalsFactory: managedObjectContext];
    [userCredentals setDatabase_driver_type: database.identifier];
    
    if ([database.identifier isEqualToString:MADIdentifierDatabaseMySQL]) {
        
        if (database.databaseConnection != nil) {
            NSNumber *port = @(database.databaseConnection.port);
            userCredentals.inDatabase.databaseDriverTypeEnum = @(MNSDatabaseTypeMySQL);
            userCredentals.mysql_host = database.databaseConnection.server;
            userCredentals.mysql_database = database.databaseConnection.database;
            userCredentals.mysql_port = port;
            userCredentals.mysql_username = database.databaseConnection.username;
            userCredentals.mysql_password = database.databaseConnection.password;
        }

    } else if ([database.identifier isEqualToString:MADIdentifierDatabaseTDS]) {

        if (database.databaseConnection != nil) {
            NSNumber *port = @(database.databaseConnection.port);
            userCredentals.inDatabase.databaseDriverTypeEnum = @(MNSDatabaseTypeMicrosoftSqlServer);
            userCredentals.tds_server = database.databaseConnection.server;
            userCredentals.tds_host = database.databaseConnection.server;
            userCredentals.tds_username = database.databaseConnection.username;
            userCredentals.tds_password = database.databaseConnection.password;
            userCredentals.tds_database = database.databaseConnection.database;
            userCredentals.tds_port = port;
        }

    } else if ([database.identifier isEqualToString:MADIdentifierDatabaseSqlite3]) {

        if (database.databaseConnection != nil) {
            // FIXME: Storing Sqlite3 database url in mysql holder.
            userCredentals.mysql_database = database.databaseConnection.databaseUrl.path.lastPathComponent;
            userCredentals.inDatabase.databaseDriverTypeEnum = @(MNSDatabaseTypeSqlite3);
        }
        
    }
    
    [rptqDatabase setOwnedByUser: userCredentals];

    NSString *rptqQueryId = NSStringFromClass([RptqQuery class]);
    RptqQuery *newQuery = [NSEntityDescription insertNewObjectForEntityForName: rptqQueryId
                                                        inManagedObjectContext: managedObjectContext];
    [rptqDatabase addHasQueriesObject:newQuery];
    
    NSSet *databaseSchemas = [rptqDocument.hasDatabaseSchemas setByAddingObject: rptqDatabase];
    [rptqDocument setHasDatabaseSchemas: databaseSchemas];
    
    __weak MTDatabase *weakDatabase = database;
    
    [database connectWithCredentals:database.databaseConnection completion:^(id dbconnection, BOOL success, NSError *connectionError) {
        
        if (success) {
            
            __weak id weakdbconnection = dbconnection;
            __weak MTDatabase *weakDatabase2 = weakDatabase;
            
            __block NSMutableDictionary *tablesAndFields = [[NSMutableDictionary alloc] init];
            __block NSMutableArray *tables = [NSMutableArray array];
            __block BOOL gotit = YES;
            __block NSError *gotitError = nil;
            
            dispatch_queue_t queueTables = dispatch_queue_create("com.everydayapps.mad.queue.tables", DISPATCH_QUEUE_SERIAL);
            dispatch_queue_t queueSave = dispatch_queue_create("com.everydayapps.mad.queue.save", DISPATCH_QUEUE_SERIAL);
            dispatch_queue_t queueMain = dispatch_get_main_queue();
            dispatch_set_target_queue(queueTables, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
            dispatch_set_target_queue(queueSave, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            dispatch_async(queueTables, ^{
                
                __weak MTDatabase *weakDatabase3 = weakDatabase2;
                [weakDatabase2 getTablesFromConnection:dbconnection completion:^(BOOL success, NSError *error, NSArray *resultTables) {
                    
                    NSManagedObjectContext *managedObjectContext = [rptqDocument managedObjectContext];
                    
                    if (success) {
                        [tables setArray:resultTables];
                        NSInteger counter = 0, numberOfTables = [tables count];
                        
                        for (MTDatabaseTable *databaseTable in tables) {
                            @autoreleasepool {
                                NSString *name = [databaseTable name];
                                __weak NSString *weakname = name;
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                    dispatch_sync(queueMain, ^{
                                        status(weakname, (CGFloat)(counter + 1) / numberOfTables);
                                    });
                                });
                                __block NSMutableArray *fields = [[NSMutableArray alloc] init];
                                [weakDatabase3 getFieldsForTableName:[databaseTable name] connection:weakdbconnection completion:^(BOOL success, NSError *error, NSArray *results) {
                                    if (success && error == nil) {
                                        [fields setArray:results];
                                        gotit = success; gotitError = error;
                                    } else {
                                        if (error) {
                                            [errorContainer addError:error];
                                        }
                                    }
                                    
                                }];
                                tablesAndFields[[databaseTable name]] = fields;
                            }
                            counter++;
                        }
                        
                        gotit = success; gotitError = error;
                        dispatch_sync(queueMain, ^{
                            
                            for (MTDatabaseTable *table in tables) {
                                
                                NSString *tableName = [table name];
                                NSArray *fields = tablesAndFields[tableName];
                                
                                if ([fields count]) {
                                    RptqDatabaseSchemaTable *rptqTable = [RptqDatabaseSchemaTable databaseSchemaTableFactoryForManagedObjectContext: managedObjectContext
                                                                                                                                           andTable: table];
                                    [[rptqDocument defaultDatabase] addHasTablesObject: rptqTable];
                                    
                                    NSMutableArray *schemaFields = [[NSMutableArray alloc] initWithCapacity:[fields count]];
                                    for (MTDatabaseField *field in fields) {
                                        RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField databaseSchemaFieldFactoryForManagedObjectContext: managedObjectContext
                                                                                                                                                 andField: field];
                                        [schemaFields addObject:schemaField];
                                    }
                                    
                                    NSOrderedSet *hasFields = [[NSOrderedSet alloc] initWithArray:schemaFields];
                                    [rptqTable setHasFields:hasFields];
                                    
                                    NSError *saveError = nil;
                                    [[rptqTable managedObjectContext] save:&saveError];
                                } else {
                                    NSString *failure = [NSString stringWithFormat:@"Table %@ not Added", tableName];
                                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Fields not found.",
                                                               NSLocalizedFailureReasonErrorKey : failure};
                                    NSError *error = [NSError errorWithDomain:@"MADReportDocument" code:38292 userInfo:userInfo];
                                    [errorContainer addError:error];
                                }
                                
                            }
                            
                            
                            NSError *saveError = nil;
                            [managedObjectContext save:&saveError];
                            NSAssert(saveError == nil, @"%@", saveError);
                            [weakDatabase3 closeProcess:weakdbconnection];
                            completion(gotit, errorContainer);
                        });
                        
                    } else {
                        MTErrorContainer *errorContainer = [[MTErrorContainer alloc] init];
                        [errorContainer addError:error];
                        completion(NO, errorContainer);
                    }
                }];
                
            });

            
        } else {
            MTErrorContainer *errorContainer = [[MTErrorContainer alloc] init];
            [errorContainer addError:connectionError];
            completion(NO, errorContainer);
        }
        
    }];
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
    
    MTDocumentObjectType objectType = [defination[MTDocumentObjectDefinationType] integerValue];
    
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
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: entityName
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSManagedObjectID *fieldObjectId = defination[MTDocumentObjectDefinationObject];
            RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId
                                                     managedObjectContext: mangedObjectContext];
            
            
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

    MTDocumentObjectType objectType = documentObject.type.integerValue;
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

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(RptqDocument *)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        result = [self.identifier isEqualToNumber:sender.identifier];
    }
    return result;
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
