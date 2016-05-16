//
//  MTQueryReport.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryFull.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDatabase.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqQueryField.h"

#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqQueryGroup.h"

#import "MTDatabase.h"
#import "MTDatabaseField.h"

#import "MTQuerySampleDataField.h"

#import <MADDataStructures/MTGraph.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTEdge.h>
#import <MADDataStructures/MADAlgorithmElementProperties.h>

#import "MTDatabaseConnection.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSManagedObjectID.h>

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>

@interface MTQueryFull ()

    @property (nonatomic, copy) NSManagedObjectID *objectID;

@end

@implementation MTQueryFull


- (instancetype)initWithQueryObjectId: (NSManagedObjectID *)objectID
                        andQueryLimit: (NSInteger)queryLimit {
    if (self = [super init]) {
        _objectID = objectID.copy;
        _limitResults = queryLimit;
    }
    return self;
}

- (instancetype)initWithObject:(NSDictionary *)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]],
                 @"MTQueryFull expects NSDictionary with parameters.");

        NSDictionary * __weak parameters = (NSDictionary *)object;
        NSNumber *parameterScheam = [[NSNumber alloc] initWithShort: MTQueryCacheFullQuerySchema];
        
        NSNumber *numberOfResults = parameters[@"MADQueryLimit"];
        self.limitResults = numberOfResults.integerValue;
        
        RptqQuery *queryObject = parameters[parameterScheam];
        _objectID = queryObject.objectID.copy;

        
    }
    return self;
}

- (NSString *)getSqlWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                       error:(NSError * __autoreleasing *)error {
    [super getSqlWithError:error];
    return [self getSqlOnlyActiveFields:YES managedObjectContext:managedObjectContext error:error];
}

- (NSString *)getSqlOnlyActiveFields: (BOOL)onlyActiveFields
                managedObjectContext: (NSManagedObjectContext *)managedObjectContext
                               error: (NSError **)error {
    
    RptqDocument *document = [RptqDocument documentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *queryObject = database.hasQueries.anyObject;

    NSMutableString *result = [[NSMutableString alloc] initWithString: @""];
    
    if (queryObject.hasQueryTables.count > 0) {
        
        MTDatabase *database = [self.dataDelegate database];
        
        NSString *selectPart = [database selectPartWithLimitedResults:self.limitResults];
        NSString *predicatePart = [self sqlWhereClauseWithQuery: queryObject];
        NSString *limitPart = [database sqlLimitClause:self.limitResults];
        
        [result appendString:selectPart];
        
        //Use a graph to represent the query: verticies are tables and edges are links.
        MTGraph *graph = [[MTGraph alloc] init];
        NSSet *hasTables = queryObject.hasQueryTables;
        
        //Add a vertex to the graph for each table.
        for (RptqDatabaseSchemaTable *table in hasTables) {
            @autoreleasepool {
                [graph addVertexWithObject: table.objectID];
            }
        }
        
        //Create an edge in the graph for each query link.
        NSSet *hasQueryLinks = queryObject.hasQueryLinks;
        NSNumber *weight = @1;
        for (RptqQueryLinks *queryLink in hasQueryLinks) {
            
            MTVertex *vertexOrigin =        [graph vertexForObject: queryLink.hasLeftField.inQueryTable.objectID];
            MTVertex *vertexDestination =   [graph vertexForObject: queryLink.hasRightField.inQueryTable.objectID];

            [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination
                              object:queryLink.objectID andWeight:weight];
        }
        
        
        // MARK: Sort the vectors topologically.
        if (error != NULL) *error = nil;
        BOOL  isDirectedAcyclicGraph;
        NSAssert(graph != nil, @"Where's the graph?");
        
        MTLinkedList *topologicalSort = [graph topologicalSortWithError:error
                                                 isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
        
        // MARK: Error on circuts or other bad query.
        if (error == nil) {
            [result setString:@""];
        } else {
            
            NSArray *topologicalSortArray = [topologicalSort toArray];
            
            // MAKR: List each field in the query.
            NSArray *sort = [topologicalSort toArray];
            NSString *sqlSelect = [self sqlSelectExpressionWithTables: sort
                                                usingOnlyActiveFields: onlyActiveFields
                                              forManagedObjectContext: managedObjectContext];
            if ([sqlSelect length] > 0) {
                [result appendString:sqlSelect];
                [result appendString:MADSqlTextFromPart];
                
                NSNumber *linkDepth = @0;
                NSMutableArray *vertexArray = [[NSMutableArray alloc] initWithCapacity: topologicalSortArray.count];
                
                for (MTPair *pair in topologicalSortArray) {
                    MTVertex *vertexTable = [pair former];
                    if (vertexTable) {
                        vertexTable.properties.vertexColor = MTColorWhite;
                        [vertexArray addObject:vertexTable];
                    }
                }
                [result appendString:[self sqlTableReferenceWithTables: vertexArray
                                                             linkDepth: &linkDepth
                                               forManagedObjectContext: managedObjectContext]];
                
            } else {
                NSString *message = NSLocalizedString(@"Empty query while using \"only active fields.\" You may need to reference some query fields.", @"Empty query while using \"only active fields.\" You may need to reference some query fields.");
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                *error = [NSError errorWithDomain:@"MTQuery" code:5774 userInfo:errorInfo];
                [result setString:@""];
            }
            
        }
        
        if (result.length > 0) {
            [result appendString:predicatePart];
            [result appendString:limitPart];
        }
        
    }
    return result;
}

- (NSString *)sqlWhereClauseWithQuery:(RptqQuery *)query {
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    NSUInteger loopCounter = 0;
    
    for (RptqQueryPredicate *queryPredicate in [query hasQueryPredicate]) {
        
        if (loopCounter == 0) {
            [result appendString:@"\nWHERE\n"];
        } else {
            [result appendString:@" AND \n"];
        }
        
        NSString *leftValue = nil;
        
        if (queryPredicate.hasLeftField != nil) {
            
            MTDatabase * __weak database = [self.dataDelegate database];
            RptqQueryField *leftField = queryPredicate.hasLeftField;
            NSString *leftTableName = [leftField.inQueryTable copyQueryAlias];
            leftValue = [database newSafeQueryField: leftField.databaseSchemaField.name
                                           andTable: leftTableName];
            
        } else if (queryPredicate.fieldleftpred != nil) {
            
            leftValue = queryPredicate.fieldleftpred;
            
        }
        
        NSString *rightValue = nil;

        if (queryPredicate.hasRightField != nil) {
            
            MTDatabase * __weak database = [self.dataDelegate database];
            RptqQueryField *rightField = queryPredicate.hasRightField;
            NSString *rightTableName = [rightField.inQueryTable copyQueryAlias];
            rightValue = [database newSafeQueryField: rightField.databaseSchemaField.name
                                            andTable: rightTableName];
            
        } else if (queryPredicate.fieldrightpred != nil) {
            
            RptqQueryField *leftField = queryPredicate.hasLeftField;
            MTDataType dataType = leftField.databaseSchemaField.dataType.shortValue;
            
            NSString * __weak fieldrightpred = queryPredicate.fieldrightpred;
            rightValue = [MTDatabaseField isNumeric:dataType] ? fieldrightpred :
                                    [[NSString alloc] initWithFormat: @"\"%@\"", fieldrightpred];
        }
        NSString *symbolForComparson = [queryPredicate symbolForComparson];
        [result appendFormat:@"\t(%@ %@ %@)", leftValue, symbolForComparson, rightValue];
        
        loopCounter++;
    }
    
    return result;
}

- (NSArray *)activeBarcodesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //Fields in barcode bitches.
    NSString *entityObjectBarcode = NSStringFromClass([RptqDocumentObjectBarcode class]);
    NSFetchRequest *fetchRequestBarcode = [[NSFetchRequest alloc] initWithEntityName:entityObjectBarcode];
    NSPredicate *predicateBarcode = [NSPredicate predicateWithValue:YES];
    fetchRequestBarcode.predicate = predicateBarcode;
    
    NSError *fetchBarcodeError = nil;
    NSArray *barcodes = [managedObjectContext executeFetchRequest: fetchRequestBarcode
                                                            error: &fetchBarcodeError];
    if (fetchBarcodeError != nil) {
        barcodes = [managedObjectContext executeFetchRequest: fetchRequestBarcode
                                                       error: &fetchBarcodeError];
    }
    return barcodes;
}

- (NSArray *)activeDataLabelsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //Fields in data label.
    NSString *entityNameObjectLabelDataField = NSStringFromClass([RptqDocumentObjectLabelDataField class]);
    NSFetchRequest *fetchRequestDataField = [[NSFetchRequest alloc] initWithEntityName:entityNameObjectLabelDataField];
    NSPredicate *predicateDataField = [NSPredicate predicateWithValue:YES];
    [fetchRequestDataField setPredicate:predicateDataField];
    NSError *fetchFieldsError = nil;
    NSArray *dataObjectFields = [managedObjectContext executeFetchRequest:fetchRequestDataField error:&fetchFieldsError];
    if (fetchFieldsError != nil) {
        dataObjectFields = [managedObjectContext executeFetchRequest:fetchRequestDataField error:&fetchFieldsError];
    }
    return dataObjectFields;
}

- (NSArray *)activeAggregateObjectsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //Fields in aggregate function.
    NSString *entityObjectAggregate = NSStringFromClass([RptqDocumentObjectAggregate class]);
    NSFetchRequest *fetchRequestAggregate = [[NSFetchRequest alloc] initWithEntityName:entityObjectAggregate];
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    [fetchRequestAggregate setPredicate:predicate];
    NSError *fetchAggregateError = nil;
    id aggregateObjectFields = [managedObjectContext executeFetchRequest:fetchRequestAggregate
                                                                   error:&fetchAggregateError];
    if (fetchAggregateError != nil) {
        aggregateObjectFields = [managedObjectContext executeFetchRequest:fetchRequestAggregate
                                                                    error:&fetchAggregateError];
    }
    return aggregateObjectFields;
}

- (NSArray *)activeGroupedObjectsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //Fields in query groups.
    NSString *entityObjectQueryGroup = NSStringFromClass([RptqQueryGroup class]);
    NSFetchRequest *fetchRequestQueryGroup = [[NSFetchRequest alloc] initWithEntityName:entityObjectQueryGroup];
    NSPredicate *predicateQueryGroups = [NSPredicate predicateWithValue:YES];
    [fetchRequestQueryGroup setPredicate:predicateQueryGroups];
    NSError *fetchQueryGroupError = nil;
    id queryGroups = [managedObjectContext executeFetchRequest:fetchRequestQueryGroup
                                                         error:&fetchQueryGroupError];
    if (fetchQueryGroupError != nil) {
        queryGroups = [managedObjectContext executeFetchRequest:fetchRequestQueryGroup
                                                          error:&fetchQueryGroupError];
    }
    return queryGroups;
}

- (NSArray *)activeQueryLinkObjectsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //Fields in query links.
    NSString *entityObjectQueryLinks = NSStringFromClass([RptqQueryLinks class]);
    NSFetchRequest *fetchRequestQueryLinks = [[NSFetchRequest alloc] initWithEntityName:entityObjectQueryLinks];
    NSPredicate *predicateQueryLinks = [NSPredicate predicateWithValue:YES];
    [fetchRequestQueryLinks setPredicate:predicateQueryLinks];
    NSError *fetchQueryLinksError = nil;
    id queryLinks = [managedObjectContext executeFetchRequest:fetchRequestQueryLinks
                                                        error:&fetchQueryLinksError];
    if (fetchQueryLinksError != nil) {
        queryLinks = [managedObjectContext executeFetchRequest:fetchRequestQueryLinks
                                                         error:&fetchQueryLinksError];
    }
    return queryLinks;
}

- (NSSet *)activeQueryFieldsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSArray *barcodes = [NSArray arrayWithArray:[self activeBarcodesForManagedObjectContext:managedObjectContext]];
    NSArray *dataObjectFields = [NSArray arrayWithArray:[self activeDataLabelsForManagedObjectContext:managedObjectContext]];
    NSArray *aggregateObjectFields = [NSArray arrayWithArray:[self activeAggregateObjectsForManagedObjectContext:managedObjectContext]];;
    NSArray *queryGroups = [NSArray arrayWithArray:[self activeGroupedObjectsForManagedObjectContext:managedObjectContext]];
    NSArray *queryLinks = [NSArray arrayWithArray:[self activeQueryLinkObjectsForManagedObjectContext:managedObjectContext]];
    
    NSUInteger estimatedSetSize = [dataObjectFields count] + [aggregateObjectFields count] + [queryGroups count];
    NSMutableSet *queryFields = [[NSMutableSet alloc] initWithCapacity:estimatedSetSize];
    
    for (RptqDocumentObjectBarcode *dataField in barcodes) {
        RptqQueryField *queryField = [dataField referencesField1];
        if (queryField != nil) {
            [queryFields addObject:queryField];
        }
        RptqQueryField *queryField2 = [dataField referencesField2];
        if (queryField2 != nil) {
            [queryFields addObject:queryField2];
        }
    }
    
    for (RptqDocumentObjectLabelDataField *dataField in dataObjectFields) {
        RptqQueryField *queryField = [dataField referencesQueryField];
        if (queryField != nil) {
            [queryFields addObject:queryField];
        }
    }
    
    for (RptqDocumentObjectAggregate *dataField in aggregateObjectFields) {
        RptqQueryField *queryField = [dataField aggregateField];
        if (queryField != nil) {
            [queryFields addObject:queryField];
        }
    }
    
    for (RptqQueryGroup *queryGroup in queryGroups) {
        RptqQueryField *queryField = [queryGroup hasField];
        if (queryField != nil) {
            [queryFields addObject:queryField];
        }
    }
    
    for (RptqQueryLinks *queryLink in queryLinks) {
        RptqQueryField *queryFieldLeft = queryLink.hasLeftField;
        if (queryFieldLeft != nil) {
            [queryFields addObject:queryFieldLeft];
        }
        RptqQueryField *queryFieldRight = queryLink.hasRightField;
        if (queryFieldRight != nil) {
            [queryFields addObject:queryFieldRight];
        }
    }

    return queryFields;
}

- (NSString *)sqlSelectExpressionWithTables:(NSArray *)tables
                      usingOnlyActiveFields:(BOOL)onlyActiveFields
                    forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    MTDatabase * __weak database = self.dataDelegate.database;
    if (onlyActiveFields) {
        
        NSSet *queryFields = [NSSet setWithSet:[self activeQueryFieldsForManagedObjectContext:managedObjectContext]];
        
        
        NSUInteger fieldCounter = 0;
        for (RptqQueryField *queryField in queryFields) {
            
            
            RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
            if (fieldCounter != 0)  [result appendString:@",\n"];
            
            NSString *tableName = [queryField.inQueryTable copyQueryAlias];
            MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
            NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
            MADSafeQueryField *fieldName = [database newSafeIdentifier: field.name];
            NSString *fieldAlias = [tableAlias stringByAppendingString:fieldName];
            [result appendFormat: @"\t%@", fieldAlias];
            
            self.fields[fieldAlias] = field;
            [self.fieldKeys addObject:fieldAlias];
            fieldCounter++;
        }
        if (fieldCounter == 0) {
            result = nil;
        }
    } else {
        
        // Logic to return all fields.
        NSUInteger tableCounter = 0;
        for (MTPair *pair in tables) {
            MTVertex *queryTable = pair.former;
            NSManagedObjectID *objectID = queryTable.object;
            
            RptqQueryTable *table = [RptqQueryTable queryTableWithObjectID:objectID
                                                      managedObjectContext:managedObjectContext];
            if (table != nil) {
                if (tableCounter != 0) [result appendString:@",\n"];
                
                NSString *tableName = [table copyQueryAlias];
                MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
                NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                
                NSUInteger fieldCounter = 0;
                
                for (RptqQueryField *queryField in table.hasQueryFields) {
                    RptqDatabaseSchemaField *field = queryField.databaseSchemaField;
                    if (fieldCounter != 0)  [result appendString:@",\n"];
                    NSString *fieldName = field.name;
                    MADSafeQueryField *safeFieldName = [database newSafeIdentifier:fieldName];
                    NSString *fieldAlias = [tableAlias stringByAppendingString:safeFieldName];
                    [result appendFormat: @"\t%@", fieldAlias];
                    fieldCounter++;
                }
                tableCounter++;
            }
        }
    }
    
    return result;
}

- (NSString *)sqlTableReferenceWithTables:(NSArray *)tables linkDepth:(NSNumber **)linkDepth
                  forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];

    NSInteger tableCounter = 0;
    MTDatabase * __weak database = [self.dataDelegate database];

    for (MTVertex *vertexTable in tables) {
        if (vertexTable) {
            
            NSManagedObjectID *objectID = [vertexTable object];
            RptqQueryTable *table = [RptqQueryTable queryTableWithObjectID:objectID
                                                      managedObjectContext:managedObjectContext];
            
            if (vertexTable.properties.vertexColor == MTColorWhite ||
                vertexTable.properties.vertexColor == MTColorGray) {
                
                NSArray <MTEdge *> *incidentEdges = vertexTable.incidentEdges;
                
                if (tableCounter > 0) {
                    if ((*linkDepth).integerValue == 0){
                        [result appendString:@","];
                    }
                    [result appendString:@"\n\t"];
                }
                
                if (vertexTable.properties.vertexColor == MTColorWhite) {
                    
                    if (result.length <= 0) {
                        [result appendString:@"\t"];
                    }
                    
                    NSString *ogTableName = table.databaseSchemaTable.name;
                    MADSafeQueryField *safeOgTableName = [database newSafeIdentifier:ogTableName];
                    [result appendString:safeOgTableName];
                    
                    NSString *tableConnector = [database tableAliasConnector];
                    [result appendString:tableConnector];
                    
                    NSString *tableName = [table copyQueryAlias];
                    MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
                    [result appendString:safeTableName];
                }
                
                vertexTable.properties.vertexColor = MTColorBlack;
                
                for (MTEdge *edge in incidentEdges) {
                    MTVertex *vertexTableDestination = edge.destination;
                    if (vertexTableDestination &&
                        vertexTableDestination.properties.vertexColor == MTColorWhite) {

                        
                        vertexTableDestination.properties.vertexColor = MTColorGray;
                        
                        NSManagedObjectID *queryLinkID = edge.object;
                        RptqQueryLinks *queryLink = [managedObjectContext objectWithID:queryLinkID];
                        
                        
                        if (queryLink) {
                            static NSString * const NewLineTab = @"\n\t";
                            static NSString * const Tab = @"\t";

                            [result appendString:NewLineTab];
                            for (NSInteger i = 0; i <= (*linkDepth).integerValue; i++) {
                                [result appendString:Tab];
                            }
                            
                            NSString *sqlForLink = [RptqQueryLinks SqlForLinkType:queryLink.jointypeenum.unsignedCharValue];
                            [result appendFormat:@" %@ ", sqlForLink];
                            
                            RptqQueryField *rightField = queryLink.hasRightField;
                            RptqQueryTable *rightTable = rightField.inQueryTable;
                            
                            NSString *databaseSchemaTable = rightTable.databaseSchemaTable.name;
                            MADSafeQueryField *safeDatabaseSchemaTable = [database newSafeIdentifier:databaseSchemaTable];
                            [result appendString:safeDatabaseSchemaTable];
                            
                            NSString *tableAliasConnector = [database tableAliasConnector];
                            [result appendString:tableAliasConnector];
                            
                            NSString *ogRightTable = [rightTable copyQueryAlias];
                            MADSafeQueryField *safeOgRightTable = [database newSafeIdentifier:ogRightTable];
                            [result appendString:safeOgRightTable];
                            [result appendString:NewLineTab];
                            
                            for (NSInteger i = 0; i <= (*linkDepth).integerValue + 1; i++) {
                                [result appendString:Tab];
                            }
                            
                            [result appendString:@"ON "];
                            
                            RptqQueryField *leftField = queryLink.hasLeftField;
                            
                            NSString *lft = [leftField.inQueryTable copyQueryAlias];
                            MADSafeQueryField *safeField = [database newSafeQueryField: leftField.databaseSchemaField.name
                                                                              andTable: lft];
                            [result appendString: safeField];
                            
                            [result appendString:@" = "];
                            
                            NSString *rft = [rightField.inQueryTable copyQueryAlias];
                            safeField = [database newSafeQueryField: rightField.databaseSchemaField.name
                                                           andTable: rft];
                            [result appendString: safeField];
                        }
                    }
                }
                
                // MARK: Destination vertices.
                NSMutableArray *destinationVertices = [[NSMutableArray alloc] initWithCapacity:vertexTable.numberOfIncidentEdges];
                NSArray *edges = vertexTable.incidentEdges;
                for (MTEdge *edge in edges) {
                    MTVertex *vertexTableDestination = edge.destination;
                    [destinationVertices addObject:vertexTableDestination];
                }

                *linkDepth = [[NSNumber alloc] initWithInteger:(*linkDepth).integerValue + 1];

                NSString *tableFactor = [self sqlTableReferenceWithTables:destinationVertices linkDepth:linkDepth forManagedObjectContext:managedObjectContext];
                if (tableFactor.length > 0) {
                
                    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    
                    [result setString: [result stringByTrimmingCharactersInSet:charSet]];
                    
                    for (NSUInteger i = 0; i < (*linkDepth).unsignedIntegerValue; i++) {
                        [result appendFormat:@"\t"];
                    }
                    [result appendString:tableFactor];
                    
                    // FIXME: I would think to group these in parentheses, but some databases don't like that.
                    //          Maybe make this optional based on DB type.
                    //    [result insertString:@"\t(" atIndex:0];
                    //    [result appendString:@")\n\t"];
                    [result insertString:@"\t" atIndex:0];
                    [result appendString:@"\n\t"];

                }
                
                *linkDepth = [[NSNumber alloc] initWithInteger:(*linkDepth).integerValue - 1];
                
                tableCounter++;
            }
        }
    }
    return result;
}

@end
