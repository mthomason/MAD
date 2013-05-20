//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseMySql.h"

@interface MTDatabaseMySql ()

@property (readwrite, nonatomic, retain) MTDatabaseConnection *databaseConnection;

@end

@implementation MTDatabaseMySql
 
- (void)dealloc {
    [_databaseConnection release];
    [super dealloc];
}

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings {
    self = [super init];
    if (self) {
        [self setDatabaseConnection:connectionSettings];
    }
    return self;
}

- (NSString *)getSqlForQuery:(RptqQuery *)query {
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"SELECT\n"];
    
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

        [result appendString:@"\nFROM\n"];
        
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
    
    return [result autorelease];
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

            leftValue = [[[queryPredicate hasLeftField] toString] retain];
            
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

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *error = nil;
            
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&error];
            NSMutableArray *results = nil;
            BOOL success = conn != nil;
            
            if (success) {
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *resultsTableName = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        
                        for (NSDictionary *tableName in [fetch results]) {
                            NSString *tn = [tableName objectForKey:[resultsTableName name]];
                            MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: tn];
                            [results addObject: databaseTable];
                            [databaseTable release];
                        }
                    }
                }
            }
            
            completion(success, error, results);
        });
    });
    
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];

            NSError *error = nil;
            MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&error];
            
            NSMutableArray *results = nil;
            BOOL success = conn != nil;
            
            NSMutableDictionary *resultsDictionary = nil;
            
            if (success) {
                NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", [table name]];
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:command onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *fieldMetaData = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:[[fetch results] count]];
                        
                        for (NSDictionary *field in [fetch results]) {
                            NSString *fieldName = [field objectForKey:[fieldMetaData name]];
                            
                            MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName: fieldName];
                            //[databaseField setDatatype:[field objectForKey:@"Type"]];
                            [results addObject: databaseField];
                            [resultsDictionary setObject:databaseField forKey:fieldName];
                            [databaseField release];
                        }
                    }
                }

                NSString *command2 = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0;", [table name]];
                MysqlFetch *fetch2 = [MysqlFetch fetchWithCommand:command2 onConnection:conn];
                if (fetch) {
                    //NSLog(@"Fetch %@", fetch);
                    if ([[fetch2 fields] count] > 0) {
                        
                        for (MysqlFetchField *field in [fetch2 fields]) {
                            
                            MTDatabaseField *databaseField = [[resultsDictionary objectForKey:[field name]] retain];
                            [databaseField setFieldTypeNative:[field fieldType]];
                            [databaseField setFieldType:[self dataTypeForMySqlType:[field fieldType]]];
                            [databaseField setWidth:[field width]];
                            [databaseField setDecimals:[field decimals]];
                            [databaseField setPrimaryKey:[field primaryKey]];
                            [databaseField release];
                        }
                    }
                }
            } else {
                [error presentErrorToUser];
            }
//            [resultsDictionary autorelease];
            [results release];
            NSArray *resultsArray = [[resultsDictionary allValues] retain];
            [resultsDictionary release];
            completion(success, error, [resultsArray autorelease]);
        });
    });
    
    
}

- (MTDataType)dataTypeForMySqlType:(NSInteger)mySqlFieldTypes {
    MTDataType result;
    switch (mySqlFieldTypes) {
        case MAX_NO_FIELD_TYPES:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_BIT:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_BLOB:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_DATE:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_DATETIME:
            result = MDDataTypeDate;
            break;
        case MYSQL_TYPE_DECIMAL:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_DOUBLE:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_ENUM:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_FLOAT:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_GEOMETRY:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_INT24:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_LONG:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_LONG_BLOB:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_LONGLONG:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_MEDIUM_BLOB:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_NEWDATE:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_NULL:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_SET:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_SHORT:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_STRING:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_TIME:
            result = MDDataTypeDate;
            break;
        case MYSQL_TYPE_TIMESTAMP:
            result = MDDataTypeDate;
            break;
        case MYSQL_TYPE_TINY:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_TINY_BLOB:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_VAR_STRING:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_VARCHAR:
             result = MTDataTypeString;
            break;
        case MYSQL_TYPE_YEAR:
            result = MTDataTypeString;
            break;
        default:
            result = MTDataTypeString;
            break;
    }
    return result;
}

- (void)cacheReportQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                     completion:(void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *query = [mnsDatabase getSqlForQuery:rquery];
    query = [NSString stringWithFormat:@"%@ LIMIT 220", query];

    RptqQueryCache *queryCache = nil;
    MysqlServer *serv = [[MysqlServer alloc] init];
    
    [serv setHost:      [[self databaseConnection] server]];
    [serv setUser:      [[self databaseConnection] username]];
    [serv setPassword:  [[self databaseConnection] password]];
    [serv setSchema:    [[self databaseConnection] database]];
    
    NSError *error = nil;
    MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&error];
    if (conn) {
        MysqlFetch *fetch = [MysqlFetch fetchWithCommand:query onConnection:conn extendedNames:YES];
        
        //NSArray *results = [[NSArray alloc] initWithArray:[fetch results]];
        
        //if (results != nil) {
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
            RptqQuery *query = [[database hasQueries] anyObject];
            queryCache = [RptqQueryCache initObjectForManagedObjectContext:managedObjectContext];
            [query setHasQueryCache:queryCache];
            
            //[queryCache removeHasValues:[queryCache hasQueryResults]];
            NSUInteger resultCounter = 0;
            for (NSDictionary *result in [fetch results]) {
                //NSLog(@"%@", result);
                
                if (resultCounter == 0) {
                    NSUInteger fieldCounter = 0;
                    for (NSString *key in [result keyEnumerator]) {
                        //NSLog(@"Field %@", key);
                        RptqQueryResultFields *queryResultField = [RptqQueryResultFields initObjectForManagedObjectContext:managedObjectContext];
                        [queryResultField setFieldname:key];
                        [queryResultField setResultOrder:@(fieldCounter)];
                        [queryCache addHasQueryResultFieldsObject:queryResultField];
                        fieldCounter++;
                    }
                }
                
                for (RptqQueryResultFields *queryResultField in [[queryCache hasQueryResultFields] objectEnumerator]) {
                    id object = [result objectForKey:[queryResultField fieldname]];
                    RptqQueryResultValues *queryResultValue = [RptqQueryResultValues initObjectForManagedObjectContext:managedObjectContext];
                    [queryResultValue setRowId:@(resultCounter)];
                    [queryResultValue setCachedValue: object];
                    [queryResultField addHasValuesObject:queryResultValue];
                    
                }
                
                resultCounter++;
            }
        //}
        //[results release];
        NSError *error = nil;
        [managedObjectContext save:&error];
    } else {
        [error presentErrorToUser];
    }
    completion(self, queryCache);
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *error = nil;
            MysqlFetch *fetch = nil;
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&error];
            BOOL success = conn != nil;
            if (success) {
                NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                                                                @"FROM %@ "
                                                                @"LIMIT 100;",
                                 schemaField.name, schemaField.inTable.name];
                fetch = [[[MysqlFetch fetchWithCommand:sql onConnection:conn] retain] autorelease];
            }
            
            completion(success, error, [[[fetch results] retain] autorelease]);
        });
    });

}

- (NSString *)identifier {
    return [MTDatabaseMySql identifier];
}

+ (NSString *)identifier {
    return @"MySQL";
}

- (id)connectionSettings {
    return [self databaseConnection];
}

@end
