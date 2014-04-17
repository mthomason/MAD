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

#import "Constants.h"

#import "MTGraph.h"

#import "RptqQuery.h"
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

#import "MTDataTable.h"
#import "MTDatabaseConnection.h"
#import "RptqDatabase.h"

@interface MTQueryFull ()

@end

@implementation MTQueryFull


- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[RptqQuery class]], @"MTQueryReport expects RptqQuery.");
        
        NSManagedObjectID *objectId = [object objectID];
        NSUInteger hash = [[[objectId URIRepresentation] absoluteString] hash];
        MTDataTable *datatable = [[MTDataTable alloc] initWithId:hash];
        [self setDatatable:datatable];
        RptqUserCredentals *userCredentals = [[(RptqQuery *)object inDatabase] ownedByUser];
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
        MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    return [self getSqlOnlyActiveFields:YES error:error];
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    
    if ([[[self queryObject] hasQueryTables] count] > 0) {
        
        [result appendString:[[self database] selectPart]];
        
        //Use a graph to represent the query: verticies are tables and edges are links.
        MTGraph *graph = [[MTGraph alloc] init];
        NSSet *hasTables = [[self queryObject] hasQueryTables];
        
        //Add a vertex to the graph for each table.
        for (RptqDatabaseSchemaTable *table in hasTables) {
            [graph addVertexWithObject:[table objectID]];
        }
        
        //Create an edge in the graph for each query link.
        NSSet *hasQueryLinks = [[self queryObject] hasQueryLinks];
        for (RptqQueryLinks *queryLink in hasQueryLinks) {
            
            RptqQueryTable *tableOrigin =        [[queryLink  hasLeftField] inQueryTable];
            RptqQueryTable *tableDestination =   [[queryLink hasRightField] inQueryTable];
            
            id objectOrigin =               [tableOrigin objectID];
            id objectDestination =          [tableDestination objectID];
            id objectQueryLink =            [queryLink objectID];
            
            MTVertex *vertexOrigin =        [graph vertexForObject:objectOrigin];
            MTVertex *vertexDestination =   [graph vertexForObject:objectDestination];
            
            NSNumber *weight = @(1);
            [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination object:objectQueryLink andWeight:weight];
        }
        
        
        // MARK: Sort the vectors topologically.
        if (error != NULL) *error = nil;
        MTLinkedList *topologicalSort = [graph topologicalSortWithError:error];
        
        // MARK: Error on circuts or other bad query.
        if (error == nil) {
            [result setString:@""];
        } else {
            
            NSArray *topologicalSortArray = [topologicalSort toArray];
            
            // MAKR: List each field in the query.
            NSString *sqlSelectExpression = [self sqlSelectExpressionWithTables:[topologicalSort toArray]
                                                          usingOnlyActiveFields:onlyActiveFields
                                                        forManagedObjectContext:[[self queryObject] managedObjectContext]];
            if ([sqlSelectExpression length] > 0) {
                [result appendString:sqlSelectExpression];
                
                [result appendString:MTSqlFrom];
                
                NSNumber *linkDepth = [[NSNumber alloc] initWithInteger:0];
                NSMutableArray *vertexArray = [[NSMutableArray alloc] initWithCapacity:[topologicalSortArray count]];
                
                for (MTPair *pair in topologicalSortArray) {
                    MTVertex *vertexTable = [pair former];
                    if (vertexTable) {
                        [vertexTable setSortVertexColor: MTColorWhite];
                        [vertexArray addObject:vertexTable];
                    }
                }
                [result appendString:[self sqlTableReferenceWithTables:vertexArray linkDepth:&linkDepth
                                               forManagedObjectContext:[[self queryObject] managedObjectContext]]];
                
            } else {
                NSString *message = NSLocalizedString(@"Empty query while using \"only active fields.\" You may need to reference some query fields.", @"Empty query while using \"only active fields.\" You may need to reference some query fields.");
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                *error = [NSError errorWithDomain:@"MTQuery" code:5774 userInfo:errorInfo];
                [result setString:@""];
            }
            
        }
        
        if ([result length] > 0) {
            [result appendString:[self sqlWhereClauseWithQuery:[self queryObject]]];
            [result appendString:[[self database] sqlLimitClause]];
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
            
            leftValue = [[self database] safeQueryField:leftField];
            
        } else if ([queryPredicate fieldleftpred] != nil) {
            
            leftValue = [queryPredicate fieldleftpred];
            
        }
        
        if ([queryPredicate hasRightField] != nil) {
            
            RptqQueryField *rightField = [queryPredicate hasRightField];
            
            rightValue = [[self database] safeQueryField:rightField];
            
        } else if ([queryPredicate fieldrightpred] != nil) {
            MTDataType dataType = [[[[queryPredicate hasLeftField] databaseSchemaField] dataType] integerValue];
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

- (NSString *)sqlSelectExpressionWithTables:(NSArray *)tables usingOnlyActiveFields:(BOOL)onlyActiveFields forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    if (onlyActiveFields) {
        
        //Logic to return only needed fields.
        
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
        
        //Fields in query groups.
        NSString *entityObjectQueryGroup = NSStringFromClass([RptqQueryGroup class]);
        NSFetchRequest *fetchRequestQueryGroup = [[NSFetchRequest alloc] initWithEntityName:entityObjectQueryGroup];
        NSPredicate *predicateQueryGroups = [NSPredicate predicateWithValue:YES];
        [fetchRequestQueryGroup setPredicate:predicateQueryGroups];
        NSError *fetchQueryGroupError = nil;
        NSArray *queryGroups = [managedObjectContext executeFetchRequest:fetchRequestQueryGroup error:&fetchQueryGroupError];
        if (fetchAggregateError != nil) {
            queryGroups = [managedObjectContext executeFetchRequest:fetchRequestQueryGroup error:&fetchQueryGroupError];
        }
        
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
            RptqQueryField *queryFieldLeft = [queryLink hasLeftField];
            if (queryFieldLeft != nil) {
                [queryFields addObject:queryFieldLeft];
            }
            RptqQueryField *queryFieldRight = [queryLink hasRightField];
            if (queryFieldRight != nil) {
                [queryFields addObject:queryFieldRight];
            }
        }
        
        NSUInteger fieldCounter = 0;
        for (RptqQueryField *queryField in queryFields) {
            RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
            if (fieldCounter != 0)  [result appendString:@",\n"];
            
            NSString *tableName = [[queryField inQueryTable] queryAlias];
            NSString *safeTableName = [[self database] safeIdentifier:tableName];
            NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
            NSString *fieldName = [[self database] safeIdentifier: [field name]];
            NSString *fieldAlias = [tableAlias stringByAppendingString:fieldName];
            [result appendFormat: @"\t%@", fieldAlias];
            [[self fields] setObject:field forKey:fieldAlias];
            [[self fieldKeys] addObject:fieldAlias];
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
            RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:objectID fromObjectContext:managedObjectContext];
            if (table != nil) {
                if (tableCounter != 0) [result appendString:@",\n"];
                
                NSString *tableName = [table queryAlias];
                NSString *safeTableName = [[self database] safeIdentifier:tableName];
                NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                
                NSUInteger fieldCounter = 0;
                for (RptqQueryField *queryField in [table hasQueryFields]) {
                    RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
                    if (fieldCounter != 0)  [result appendString:@",\n"];
                    NSString *fieldName = [field name];
                    NSString *safeFieldName = [[self database] safeIdentifier:fieldName];
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
            RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:objectID fromObjectContext:managedObjectContext];
            
            if ([vertexTable sortVertexColor] == MTColorWhite || [vertexTable sortVertexColor] == MTColorGray) {
                
                NSArray *incidentEdges = [vertexTable incidentEdges];
                
                if (tableCounter > 0) {
                    if ([*linkDepth integerValue] == 0){
                        [result appendString:@","];
                    }
                    [result appendString:@"\n\t"];
                }
                
                if ([vertexTable sortVertexColor] == MTColorWhite) {
                    if ([result length] <= 0) {
                        [result appendString:@"\t"];
                    }
                    NSString *ogTableName = [[table databaseSchemaTable] name];
                    NSString *safeOgTableName = [[self database] safeIdentifier:ogTableName];
                    [result appendString:safeOgTableName];
                    [result appendString:[[self database] tableAliasConnector]];
                    NSString *tableName = [table queryAlias];
                    NSString *safeTableName = [[self database] safeIdentifier:tableName];
                    [result appendString:safeTableName];
                }
                
                [vertexTable setSortVertexColor: MTColorBlack];
                
                for (MTEdge *edge in incidentEdges) {
                    MTVertex *vertexTableDestination = [edge destination];
                    if (vertexTableDestination) {
                        if ([vertexTableDestination sortVertexColor] == MTColorWhite) {
                            
                            [vertexTableDestination setSortVertexColor:MTColorGray];
                            
                            NSManagedObjectID *queryLinkID = [edge object];
                            RptqQueryLinks *queryLink = [RptqQueryLinks getQueryLinkWithID:queryLinkID fromObjectContext:managedObjectContext];
                            
                            
                            if (queryLink) {
                                [result appendString:@"\n\t"];
                                for (NSUInteger i = 0; i <= [*linkDepth integerValue]; i++) {
                                    [result appendString:@"\t"];
                                }
                                switch ([[queryLink jointypeenum] integerValue]) {
                                    case MNSLinkTypeInnerJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeInnerJoin]];
                                        break;
                                    case MNSLinkTypeEquiJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeEquiJoin]];
                                        break;
                                    case MNSLinkTypeNaturalJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeNaturalJoin]];
                                        break;
                                    case MNSLinkTypeCrossJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeCrossJoin]];
                                        break;
                                    case MNSLinkTypeLeftOuterJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeLeftOuterJoin]];
                                        break;
                                    case MNSLinkTypeRightOuterJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeRightOuterJoin]];
                                        break;
                                    case MNSLinkTypeFullOuterJoin:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeFullOuterJoin]];
                                        break;
                                    default:
                                        [result appendFormat:@" %@ ",[MNSLinkTypeSqlRepresentation objectAtIndex:MNSLinkTypeInnerJoin]];
                                        break;
                                }
                                
                                RptqQueryField *rightField = [queryLink hasRightField];
                                RptqQueryTable *rightTable = [rightField inQueryTable];
                                NSString *ogTableName = [[rightTable databaseSchemaTable] name];
                                NSString *safeOgTableName = [[self database] safeIdentifier:ogTableName];
                                [result appendString:safeOgTableName];
                                [result appendString:[[self database] tableAliasConnector]];
                                NSString *ogRightTable = [rightTable queryAlias];
                                NSString *safeOgRightTable = [[self database] safeIdentifier:ogRightTable];
                                [result appendString:safeOgRightTable];
                                [result appendString:@"\n\t"];
                                for (NSUInteger i = 0; i <= [*linkDepth integerValue] + 1; i++) {
                                    [result appendString:@"\t"];
                                }
                                
                                [result appendString:@"ON "];
                                
                                RptqQueryField *leftField = [queryLink hasLeftField];
                                if (leftField) {
                                    NSString *s = [[self database] safeQueryField:leftField];
                                    [result appendString: s];
                                }
                                [result appendString:@" = "];
                                if (rightField) {
                                    NSString *s = [[self database] safeQueryField:rightField];
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
                    
                    if (NO) {   //I would think to group these in parentheses, but some databases don't like that.
                        [result insertString:@"\t(" atIndex:0];
                        [result appendString:@")\n\t"];
                    } else {
                        [result insertString:@"\t" atIndex:0];
                        [result appendString:@"\n\t"];
                    }
                    
                    for (NSUInteger i = 0; i < [*linkDepth integerValue]; i++) {
                        [result appendFormat:@"\t"];
                    }
                    [result appendString:tableFactor];
                }
                
                *linkDepth = @([*linkDepth integerValue] - 1);
                
                tableCounter++;
            }
        }
    }
    return result;
}

- (NSArray *)sortedHasQueryGroups {
    NSSet *hasQueryGroups = [[self queryObject] hasQueryGroups];
    
    NSString *sortKey = NSStringFromSelector(@selector(weight));
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey ascending: YES];
    return [hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (NSArray *)sortDescriptors {

    NSArray *sortedHasQueryGroups = [self sortedHasQueryGroups];

    NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
    
    for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
        
        BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
        RptqQueryField *groupField = [queryGroup hasField];
        
        NSString *queryTable = [[groupField inQueryTable] queryAlias];
        NSString *safeQueryTable = [[self database] safeIdentifier:queryTable];
        NSString *fieldName = [[groupField databaseSchemaField] name];
        NSString *safeFieldName = [[self database] safeIdentifier:fieldName];
        NSString *key = [NSString stringWithFormat:@"%@.%@", safeQueryTable, safeFieldName];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                       ascending: sortAscending];
        [sortedSortDescriptorsGroup addObject:sortDescriptor];
    }
    
    return sortedSortDescriptorsGroup;
}

@end
