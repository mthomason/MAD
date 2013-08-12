//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabase.h"
#import "MTDatabaseMySql.h"
//#import "MTDatabaseSalesForce.h"
#import "MTDatabaseConnection.h"
#import "RptqDatabase.h"
#import "RptqUserCredentals.h"

@interface MTDatabase ()

@property (nonatomic, assign, readwrite) BOOL isLicensedUser;

@end

@implementation MTDatabase

+ (id)databaseObjectForRptqDatabase:(RptqDatabase *)database {
    //RptqUserCredentals *userCredentals = [database ownedByUser];
    return [MTDatabase databaseForRptqDatabase:database];
}

+ (id)databaseForRptqDatabase:(RptqDatabase *)database {
    id result = nil;
    RptqUserCredentals *userCredentals = [database ownedByUser];    

    if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseMySql identifier]]) {

        MTDatabaseConnection *databaseConnection = [[MTDatabaseConnection alloc] init];
        [databaseConnection setUsername:    [[userCredentals mysql_username] copy]];
        [databaseConnection setPassword:    [[userCredentals mysql_password] copy]];
        [databaseConnection setServer:      [[userCredentals mysql_host] copy]];
        [databaseConnection setDatabase:    [[userCredentals mysql_database] copy]];
        [databaseConnection setPort:        [[userCredentals mysql_port] integerValue]];
        MTDatabaseMySql *databaseMySql = [[MTDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];
        result = databaseMySql;
        [databaseMySql autorelease];
        [databaseConnection release];

    } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseSqlServer identifier]]) {

        MTDatabaseConnection *databaseConnection = [[MTDatabaseConnection alloc] init];
        [databaseConnection setUsername:    [[userCredentals tds_username] copy]];
        [databaseConnection setPassword:    [[userCredentals tds_password] copy]];
        [databaseConnection setServer:      [[userCredentals tds_server] copy]];
        [databaseConnection setHost:        [[userCredentals tds_host] copy]];
        [databaseConnection setDatabase:    [[userCredentals tds_database] copy]];
        [databaseConnection setPort:        [[userCredentals tds_port] integerValue]];
        MTDatabaseSqlServer *databaseTds = [[MTDatabaseSqlServer alloc] initWithConnectionSettings:databaseConnection];
        result = databaseTds;
        [databaseTds autorelease];
        [databaseConnection release];
        
    }
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (NSString *)getSqlForQuery:(RptqQuery *)query {
    
    __block NSMutableString *result = [[NSMutableString alloc] initWithString:@""];

    dispatch_semaphore_t semaphoreIsLicensed = dispatch_semaphore_create(0);
    
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        
        [self setIsLicensedUser:isLicensedUser];
                
        if ([[query hasQueryTables] count] > 0) {
            
            [result appendString:[self selectPart]];
            
            //Use a graph to represent the query: verticies are tables and edges are links.
            MTGraph *graph = [[MTGraph alloc] init];
            NSSet *hasTables = [query hasQueryTables];
            
            //Add a vertex to the graph for each edge.
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
                
                MTVertex *vertexOrigin =        [[graph vertexForObject:objectOrigin] retain];
                MTVertex *vertexDestination =   [[graph vertexForObject:objectDestination] retain];
                
                [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination object:objectQueryLink andWeight:@(1)];
                
                [vertexOrigin release];
                [vertexDestination release];
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
                [result appendString:[self sqlSelectExpressionWithTables:[topologicalSort toArray]
                                                 forManagedObjectContext:[query managedObjectContext]]];
                
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
                [vertexArray release];
                [linkDepth release];
            }
            
            [graph release];
            
            [result appendString:[self sqlWhereClauseWithQuery:query]];
            [result appendString:[self sqlLimitClause]];
            
        }
        dispatch_semaphore_signal(semaphoreIsLicensed);
    }];
    
    dispatch_semaphore_wait(semaphoreIsLicensed, DISPATCH_TIME_FOREVER);
    dispatch_release(semaphoreIsLicensed);
    
    
    return [result autorelease];
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
        
        MTDataType leftFieldDataType = MTDataTypeUnknown;
        
        if ([queryPredicate hasLeftField] != nil) {
            
            RptqQueryField *leftField = [queryPredicate hasLeftField];
            leftValue = [[leftField toString] retain];
            MTDatabaseField *dbField = [RptqDatabaseSchemaField databaseFieldForSchemaField:[leftField databaseSchemaField]];
            leftFieldDataType = [dbField fieldType];
            
        } else if ([queryPredicate fieldleftpred] != nil) {
            
            leftValue = [[queryPredicate fieldleftpred] retain];
            
        }
        
        if ([queryPredicate hasRightField] != nil) {
            
            rightValue = [[[queryPredicate hasRightField] toString] retain];
            
        } else if ([queryPredicate fieldrightpred] != nil) {
            
            rightValue = [[queryPredicate fieldrightpred] retain];
            
        }
        
        
        [leftValue release];
        [rightValue release];
        
        [result appendFormat:@"\t(%@ %@ %@)", leftValue, [queryPredicate symbolForComparson], rightValue];
        
        loopCounter++;
    }
    
    return [result autorelease];
}

- (NSString *)sqlGroupByExpressionWithQuery:(RptqQuery *)query {
    //Group is done on the reporting client side, so we do not add group by information here.
    return @"";
}

- (NSString *)sqlSelectExpressionWithTables:(NSArray *)tables forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSUInteger tableCounter = 0;
    for (MTPair *pair in tables) {
        
        MTVertex *queryTable = [pair former];
        NSManagedObjectID *objectID = [queryTable object];
        RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:objectID fromObjectContext:managedObjectContext];
        if (table != nil) {
            if (tableCounter != 0) [result appendString:@",\n"];
            
            NSString *tableAlias = [[table queryAlias] stringByAppendingString:@"."];
            
            NSUInteger fieldCounter = 0;
            for (RptqQueryField *queryField in [table hasQueryFields]) {
                RptqDatabaseSchemaField *field = [queryField databaseSchemaField];
                if (fieldCounter != 0)  [result appendString:@",\n"];
                NSString *fieldAlias = [tableAlias stringByAppendingString:[field name]];
                [result appendFormat: @"\t%@", fieldAlias];
                fieldCounter++;
            }
            tableCounter++;
        }
        
        
    };
    return [result autorelease];
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
                    [result appendString:[[table databaseSchemaTable] name]];
                    [result appendString:@" AS "];
                    [result appendString:[table queryAlias]];
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
                                [result appendString:[[rightTable databaseSchemaTable] name]];
                                [result appendString:@" AS "];
                                [result appendString:[rightTable queryAlias]];
                                [result appendString:@"\n\t"];
                                for (NSUInteger i = 0; i <= [*linkDepth integerValue] + 1; i++) {
                                    [result appendString:@"\t"];
                                }
                                
                                [result appendString:@"ON "];
                                
                                RptqQueryField *leftField = [queryLink hasLeftField];
                                if (leftField) {
                                    [result appendString: [leftField toString]];
                                }
                                [result appendString:@" = "];
                                if (rightField) {
                                    [result appendString: [rightField toString]];
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
                    [result setString: [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    [result insertString:@"\t(" atIndex:0];
                    [result appendString:@")\n\t"];
                    for (NSUInteger i = 0; i < [*linkDepth integerValue]; i++) {
                        [result appendFormat:@"\t"];
                    }
                    [result appendString:tableFactor];
                }
                
                *linkDepth = @([*linkDepth integerValue] - 1);
                [destinationVertices release];
                
                tableCounter++;
            }
        }
    }
    return [result autorelease];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)cacheReportQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
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

- (NSString *)identifier {
    return [MTDatabase identifier];
}

+ (NSString *)identifier {
    return @"NONE";
}

- (id)connectionSettings {
    return nil;
}

@end
