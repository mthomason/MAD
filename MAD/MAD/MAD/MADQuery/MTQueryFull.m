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

@interface MTQueryFull ()

    @property (nonatomic, copy) NSManagedObjectID *objectID;

@end

@implementation MTQueryFull


- (instancetype)initWithQueryObjectId:(NSManagedObjectID *)objectID andQueryLimit:(NSInteger)queryLimit {
    if (self = [super init]) {
        _objectID = objectID.copy;
        _limitResults = queryLimit;
    }
    return self;
}

- (instancetype)initWithObject:(NSDictionary *)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryFull expects NSDictionary with parameters.");

        NSDictionary *parameters = (NSDictionary *)object;
        NSNumber *parameterScheam = @(MTQueryCacheFullQuerySchema);
        
        NSNumber *numberOfResults = parameters[@"MADQueryLimit"];
        self.limitResults = numberOfResults.integerValue;
        
        RptqQuery *queryObject = parameters[parameterScheam];
        _objectID = queryObject.objectID.copy;

        
    }
    return self;
}

- (NSString *)getSqlWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error {
    [super getSqlWithError:error];
    return [self getSqlOnlyActiveFields:YES managedObjectContext:managedObjectContext error:error];
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields managedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error {
    RptqDocument *document = [RptqDocument documentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *queryObject = database.hasQueries.anyObject;

    NSMutableString *result = [[NSMutableString alloc] initWithString: @""];
    
    if (queryObject.hasQueryTables.count > 0) {
        
        MTDatabase *database = [self.dataDelegate database];
        
        NSString *selectPart = [database selectPartWithLimitedResults:self.limitResults];
        NSString *predicatePart = [self sqlWhereClauseWithQuery: queryObject];
        NSString *limitPart = [[self.dataDelegate database] sqlLimitClause:self.limitResults];
        
        [result appendString:selectPart];
        
        //Use a graph to represent the query: verticies are tables and edges are links.
        MTGraph *graph = [[MTGraph alloc] init];
        NSSet *hasTables = [queryObject hasQueryTables];
        
        //Add a vertex to the graph for each table.
        for (RptqDatabaseSchemaTable *table in hasTables) {
            @autoreleasepool {
                [graph addVertexWithObject: table.objectID];
            }
        }
        
        //Create an edge in the graph for each query link.
        NSSet *hasQueryLinks = queryObject.hasQueryLinks;
        NSNumber *weight = @(1);
        for (RptqQueryLinks *queryLink in hasQueryLinks) {
            
            MTVertex *vertexOrigin =        [graph vertexForObject: queryLink.hasLeftField.inQueryTable.objectID];
            MTVertex *vertexDestination =   [graph vertexForObject: queryLink.hasRightField.inQueryTable.objectID];

            [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination object:queryLink.objectID andWeight:weight];
        }
        
        
        // MARK: Sort the vectors topologically.
        if (error != NULL) *error = nil;
        BOOL  isDirectedAcyclicGraph;
        NSAssert(graph != nil, @"Where's the graph?");
        MTLinkedList *topologicalSort = [graph topologicalSortWithError:error isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
        
        // MARK: Error on circuts or other bad query.
        if (error == nil) {
            [result setString:@""];
        } else {
            
            NSArray *topologicalSortArray = [topologicalSort toArray];
            
            // MAKR: List each field in the query.
            NSString *sqlSelectExpression = [self sqlSelectExpressionWithTables:[topologicalSort toArray]
                                                          usingOnlyActiveFields:onlyActiveFields
                                                        forManagedObjectContext:managedObjectContext];
            if ([sqlSelectExpression length] > 0) {
                [result appendString:sqlSelectExpression];
                
                [result appendString:MADSqlTextFromPart];
                
                NSNumber *linkDepth = @0;
                NSMutableArray *vertexArray = [[NSMutableArray alloc] initWithCapacity:[topologicalSortArray count]];
                
                for (MTPair *pair in topologicalSortArray) {
                    MTVertex *vertexTable = [pair former];
                    if (vertexTable) {
                        vertexTable.properties.vertexColor = MTColorWhite;
                        [vertexArray addObject:vertexTable];
                    }
                }
                [result appendString:[self sqlTableReferenceWithTables:vertexArray linkDepth:&linkDepth
                                               forManagedObjectContext:managedObjectContext]];
                
            } else {
                NSString *message = NSLocalizedString(@"Empty query while using \"only active fields.\" You may need to reference some query fields.", @"Empty query while using \"only active fields.\" You may need to reference some query fields.");
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                *error = [NSError errorWithDomain:@"MTQuery" code:5774 userInfo:errorInfo];
                [result setString:@""];
            }
            
        }
        
        if ([result length] > 0) {
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
        NSString *rightValue = nil;
        
        if ([queryPredicate hasLeftField] != nil) {
            
            RptqQueryField *leftField = [queryPredicate hasLeftField];
            
            leftValue = [self.dataDelegate.database safeQueryField: leftField.databaseSchemaField.name
                                                          andTable: leftField.inQueryTable.queryAlias];
            
        } else if ([queryPredicate fieldleftpred] != nil) {
            
            leftValue = [queryPredicate fieldleftpred];
            
        }
        
        if ([queryPredicate hasRightField] != nil) {
            
            RptqQueryField *rightField = [queryPredicate hasRightField];
            
            rightValue = [self.dataDelegate.database safeQueryField: rightField.databaseSchemaField.name
                                                           andTable: rightField.inQueryTable.queryAlias];
            
        } else if ([queryPredicate fieldrightpred] != nil) {
            
            MTDataType dataType = queryPredicate.hasLeftField.databaseSchemaField.dataType.unsignedIntegerValue;
            BOOL isNumeric = [MTDatabaseField isNumeric:dataType];
            
            if (isNumeric == NO) {
                rightValue = [NSString stringWithFormat:@"\"%@\"",[queryPredicate fieldrightpred]];
            } else {
                rightValue = [queryPredicate fieldrightpred];
            }
            
        }

        [result appendFormat:@"\t(%@ %@ %@)", leftValue, [queryPredicate symbolForComparson], rightValue];
        
        loopCounter++;
    }
    
    return result;
}

- (NSArray *)activeBarcodesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //Fields in barcode bitches.
    NSString *entityObjectBarcode = NSStringFromClass([RptqDocumentObjectBarcode class]);
    NSFetchRequest *fetchRequestBarcode = [[NSFetchRequest alloc] initWithEntityName:entityObjectBarcode];
    NSPredicate *predicateBarcode = [NSPredicate predicateWithValue:YES];
    [fetchRequestBarcode setPredicate:predicateBarcode];
    NSError *fetchBarcodeError = nil;
    NSArray *barcodes = [managedObjectContext executeFetchRequest:fetchRequestBarcode error:&fetchBarcodeError];
    if (fetchBarcodeError != nil) {
        barcodes = [managedObjectContext executeFetchRequest:fetchRequestBarcode error:&fetchBarcodeError];
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
    NSArray *aggregateObjectFields = [managedObjectContext executeFetchRequest:fetchRequestAggregate error:&fetchAggregateError];
    if (fetchAggregateError != nil) {
        aggregateObjectFields = [managedObjectContext executeFetchRequest:fetchRequestAggregate error:&fetchAggregateError];
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
    NSArray *queryGroups = [managedObjectContext executeFetchRequest:fetchRequestQueryGroup error:&fetchQueryGroupError];
    if (fetchQueryGroupError != nil) {
        queryGroups = [managedObjectContext executeFetchRequest:fetchRequestQueryGroup error:&fetchQueryGroupError];
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
    NSArray *queryLinks = [managedObjectContext executeFetchRequest:fetchRequestQueryLinks error:&fetchQueryLinksError];
    if (fetchQueryLinksError != nil) {
        queryLinks = [managedObjectContext executeFetchRequest:fetchRequestQueryLinks error:&fetchQueryLinksError];
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

- (NSString *)sqlSelectExpressionWithTables:(NSArray *)tables usingOnlyActiveFields:(BOOL)onlyActiveFields forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    if (onlyActiveFields) {
        
        NSSet *queryFields = [NSSet setWithSet:[self activeQueryFieldsForManagedObjectContext:managedObjectContext]];
        
        NSUInteger fieldCounter = 0;
        for (RptqQueryField *queryField in queryFields) {
            RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
            if (fieldCounter != 0)  [result appendString:@",\n"];
            
            NSString *tableName = [[queryField inQueryTable] queryAlias];
            NSString *safeTableName = [[self.dataDelegate database] safeIdentifier:tableName];
            NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
            NSString *fieldName = [[self.dataDelegate database] safeIdentifier: [field name]];
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
            MTVertex *queryTable = [pair former];
            NSManagedObjectID *objectID = [queryTable object];
            RptqQueryTable *table = [RptqQueryTable queryTableWithObjectID:objectID managedObjectContext:managedObjectContext];
            if (table != nil) {
                if (tableCounter != 0) [result appendString:@",\n"];
                
                NSString *tableName = [table queryAlias];
                NSString *safeTableName = [[self.dataDelegate database] safeIdentifier:tableName];
                NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                
                NSUInteger fieldCounter = 0;
                for (RptqQueryField *queryField in [table hasQueryFields]) {
                    RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
                    if (fieldCounter != 0)  [result appendString:@",\n"];
                    NSString *fieldName = [field name];
                    NSString *safeFieldName = [[self.dataDelegate database] safeIdentifier:fieldName];
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

- (NSString *)sqlTableReferenceWithTables:(NSArray *)tables linkDepth:(NSNumber **)linkDepth forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSInteger tableCounter = 0;
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    for (MTVertex *vertexTable in tables) {
        if (vertexTable) {
            
            NSManagedObjectID *objectID = [vertexTable object];
            RptqQueryTable *table = [RptqQueryTable queryTableWithObjectID:objectID managedObjectContext:managedObjectContext];
            
            if (vertexTable.properties.vertexColor == MTColorWhite || vertexTable.properties.vertexColor == MTColorGray) {
                
                NSArray *incidentEdges = [vertexTable incidentEdges];
                
                if (tableCounter > 0) {
                    if ([*linkDepth integerValue] == 0){
                        [result appendString:@","];
                    }
                    [result appendString:@"\n\t"];
                }
                
                if (vertexTable.properties.vertexColor == MTColorWhite) {
                    if ([result length] <= 0) {
                        [result appendString:@"\t"];
                    }
                    NSString *ogTableName = [[table databaseSchemaTable] name];
                    NSString *safeOgTableName = [[self.dataDelegate database] safeIdentifier:ogTableName];
                    [result appendString:safeOgTableName];
                    [result appendString:[[self.dataDelegate database] tableAliasConnector]];
                    NSString *tableName = [table queryAlias];
                    NSString *safeTableName = [[self.dataDelegate database] safeIdentifier:tableName];
                    [result appendString:safeTableName];
                }
                
                vertexTable.properties.vertexColor = MTColorBlack;
                
                for (MTEdge *edge in incidentEdges) {
                    MTVertex *vertexTableDestination = [edge destination];
                    if (vertexTableDestination) {
                        if (vertexTableDestination.properties.vertexColor == MTColorWhite) {
                            
                            vertexTableDestination.properties.vertexColor = MTColorGray;
                            
                            NSManagedObjectID *queryLinkID = [edge object];
                            RptqQueryLinks *queryLink = (RptqQueryLinks *)[managedObjectContext objectRegisteredForID:queryLinkID];
                            
                            
                            if (queryLink) {
                                [result appendString:@"\n\t"];
                                for (NSUInteger i = 0; i <= [*linkDepth unsignedIntegerValue]; i++) {
                                    [result appendString:@"\t"];
                                }
                                NSString *sqlForLink = [RptqQueryLinks SqlForLinkType:queryLink.jointypeenum.unsignedCharValue];
                                [result appendFormat:@" %@ ", sqlForLink];
                                
                                RptqQueryField *rightField = queryLink.hasRightField;
                                RptqQueryTable *rightTable = [rightField inQueryTable];
                                NSString *ogTableName = [[rightTable databaseSchemaTable] name];
                                NSString *safeOgTableName = [[self.dataDelegate database] safeIdentifier:ogTableName];
                                [result appendString:safeOgTableName];
                                [result appendString:[[self.dataDelegate database] tableAliasConnector]];
                                NSString *ogRightTable = [rightTable queryAlias];
                                NSString *safeOgRightTable = [[self.dataDelegate database] safeIdentifier:ogRightTable];
                                [result appendString:safeOgRightTable];
                                [result appendString:@"\n\t"];
                                for (NSUInteger i = 0; i <= [*linkDepth unsignedIntegerValue] + 1; i++) {
                                    [result appendString:@"\t"];
                                }
                                
                                [result appendString:@"ON "];
                                
                                RptqQueryField *leftField = queryLink.hasLeftField;
                                if (leftField) {
                                    NSString *s = [self.dataDelegate.database safeQueryField: leftField.databaseSchemaField.name
                                                                                    andTable: leftField.inQueryTable.queryAlias];
                                    [result appendString: s];
                                }
                                [result appendString:@" = "];
                                if (rightField) {
                                    NSString *s = [self.dataDelegate.database safeQueryField: rightField.databaseSchemaField.name
                                                                                    andTable: rightField.inQueryTable.queryAlias];
                                    [result appendString: s];
                                }
                            }
                        }
                    }
                }
                
                // MARK: Destination vertices.
                NSMutableArray *destinationVertices = [[NSMutableArray alloc] initWithCapacity:[[vertexTable incidentEdges] count]];
                for (MTEdge *edge in [vertexTable incidentEdges]) {
                    MTVertex *vertexTableDestination = [edge destination];
                    [destinationVertices addObject:vertexTableDestination];
                }
                *linkDepth = @([*linkDepth integerValue] + 1);
                NSString *tableFactor = [self sqlTableReferenceWithTables:destinationVertices linkDepth:linkDepth forManagedObjectContext:managedObjectContext];
                if ([tableFactor length] > 0) {
                    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    [result setString: [result stringByTrimmingCharactersInSet:charSet]];
                    
                    for (NSUInteger i = 0; i < [*linkDepth unsignedIntegerValue]; i++) {
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
                
                *linkDepth = @([*linkDepth integerValue] - 1);
                
                tableCounter++;
            }
        }
    }
    return result;
}

@end
