//
//  MTQuery.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery.h"
#import "MTCache.h"
#import "MTDatabase.h"
#import "MTDatabaseField.h"

#import "MTGraph.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"

#import "NSError+UserInterface.h"

#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseSqlServer.h"

#import "MTQueryMySql.h"
#import "MTQuerySqlServer.h"
#import "MTQuerySqlite3.h"

@interface MTQuery ()

@property (nonatomic, strong) MTCache *cache;
@property (nonatomic, strong, readwrite) MTDatabase *database;

@end

@implementation MTQuery

- (id)initWithDatabase:(RptqDatabase *)database {
    self = [super init];
    if (self) {

        MTDatabase *db = [MTDatabase databaseForRptqDatabase:database];
        [self setDatabase:db];

    }
    return self;
}

+ (id)queryForRptqQuery:(RptqQuery *)rptqQuery {
    RptqDatabase *database = [rptqQuery inDatabase];
    RptqUserCredentals *userCredentals = [database ownedByUser];
    id result = nil;
    if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseMySql identifier]]) {
        
        result = [[MTQueryMySql alloc] initWithDatabase:database];
        
    } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseSqlServer identifier]]) {
        
        result = [[MTQuerySqlServer alloc] initWithDatabase:database];
        
    } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseSqlite3 identifier]]) {
        
        result = [[MTQuerySqlite3 alloc] initWithDatabase:database];

    }
    return result;
}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(BOOL success, NSError *error, id results))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)tableAliasConnector {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MTQuery; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MTQuery; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)safeIdentifier:(NSString *)s {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MTQuery; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (NSString *)getSqlForQuery:(RptqQuery *)query {
    return [self getSqlForQuery:query onlyActiveFields:YES];
}

- (NSString *)getSqlForQuery:(RptqQuery *)query onlyActiveFields:(BOOL)onlyActiveFields {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    
    if ([[query hasQueryTables] count] > 0) {
        
        [result appendString:[self selectPart]];
        
        //Use a graph to represent the query: verticies are tables and edges are links.
        MTGraph *graph = [[MTGraph alloc] init];
        NSSet *hasTables = [query hasQueryTables];
        
        //Add a vertex to the graph for each table.
        for (RptqDatabaseSchemaTable *table in hasTables) {
            [graph addVertexWithObject:[table objectID]];
        }
        
        //Create an edge in the graph for each query link.
        NSSet *hasQueryLinks = [query hasQueryLinks];
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
        NSError *error = nil;
        MTLinkedList *topologicalSort = [graph topologicalSortWithError:&error];
        
        // MARK: Error on circuts or other bad query.
        if (error) {
            [error presentErrorToUserWithCompletion:^(BOOL success) {}];
            [result setString:@""];
        } else {
            
            NSArray *topologicalSortArray = [topologicalSort toArray];
            
            // MAKR: List each field in the query.
            NSString *sqlSelectExpression = [self sqlSelectExpressionWithTables:[topologicalSort toArray]
                                                          usingOnlyActiveFields:onlyActiveFields
                                                        forManagedObjectContext:[query managedObjectContext]];
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
                                               forManagedObjectContext:[query managedObjectContext]]];
                
            } else {
                [result setString:@""];
            }
            
        }
        
        if ([result length] > 0) {
            [result appendString:[self sqlWhereClauseWithQuery:query]];
            [result appendString:[self sqlLimitClause]];
        }
        
    }

    return result;
}

- (NSString *)sqlLimitClause {
    return @"";
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
        
        //MTDataType leftFieldDataType = MTDataTypeUnknown;
        
        if ([queryPredicate hasLeftField] != nil) {
            
            RptqQueryField *leftField = [queryPredicate hasLeftField];
            
            leftValue = [self safeQueryField:leftField];
            
            //MTDatabaseField *dbField = [RptqDatabaseSchemaField databaseFieldForSchemaField:[leftField databaseSchemaField]];
            //leftFieldDataType = [dbField fieldType];
            
        } else if ([queryPredicate fieldleftpred] != nil) {
            
            leftValue = [queryPredicate fieldleftpred];
            
        }
        
        if ([queryPredicate hasRightField] != nil) {
            
            RptqQueryField *rightField = [queryPredicate hasRightField];
            
            rightValue = [self safeQueryField:rightField];
            
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

- (NSString *)sqlGroupByExpressionWithQuery:(RptqQuery *)query {
    //Group is done on the reporting client side, so we do not add group by information here.
    return @"";
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
            NSString *safeTableName = [self safeIdentifier:tableName];
            NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
            NSString *fieldName = [self safeIdentifier: [field name]];
            NSString *fieldAlias = [tableAlias stringByAppendingString:fieldName];
            [result appendFormat: @"\t%@", fieldAlias];
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
                NSString *safeTableName = [self safeIdentifier:tableName];
                NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                
                NSUInteger fieldCounter = 0;
                for (RptqQueryField *queryField in [table hasQueryFields]) {
                    RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
                    if (fieldCounter != 0)  [result appendString:@",\n"];
                    NSString *fieldName = [field name];
                    NSString *safeFieldName = [self safeIdentifier:fieldName];
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
                    NSString *safeOgTableName = [self safeIdentifier:ogTableName];
                    [result appendString:safeOgTableName];
                    [result appendString:[self tableAliasConnector]];
                    NSString *tableName = [table queryAlias];
                    NSString *safeTableName = [self safeIdentifier:tableName];
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
                                NSString *safeOgTableName = [self safeIdentifier:ogTableName];
                                [result appendString:safeOgTableName];
                                [result appendString:[self tableAliasConnector]];
                                NSString *ogRightTable = [rightTable queryAlias];
                                NSString *safeOgRightTable = [self safeIdentifier:ogRightTable];
                                [result appendString:safeOgRightTable];
                                [result appendString:@"\n\t"];
                                for (NSUInteger i = 0; i <= [*linkDepth integerValue] + 1; i++) {
                                    [result appendString:@"\t"];
                                }
                                
                                [result appendString:@"ON "];
                                
                                RptqQueryField *leftField = [queryLink hasLeftField];
                                if (leftField) {
                                    NSString *s = [self safeQueryField:leftField];
                                    [result appendString: s];
                                }
                                [result appendString:@" = "];
                                if (rightField) {
                                    NSString *s = [self safeQueryField:rightField];
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

@end
