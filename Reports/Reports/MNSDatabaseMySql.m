//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabaseMySql.h"

@interface MNSDatabaseMySql ()

@property (nonatomic, retain) MNSDatabaseConnection *databaseConnection;

@end

@implementation MNSDatabaseMySql

- (void)dealloc {
    [_databaseConnection release];
    [super dealloc];
}

- (id)initWithConnectionSettings: (MNSDatabaseConnection *)connectionSettings {
    self = [super init];
    if (self) {
        [self setDatabaseConnection:connectionSettings];
    }
    return self;
}

- (NSString *)getSqlForQuery:(RptqQuery *)query {
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"SELECT\n"];
    
    // MARK: Use a graph to represent the query: verticies are tables and edges are links.
    MTGraph *graph = [[MTGraph alloc] init];
    NSSet *hasTables = [query hasTables];
    NSMutableSet *vertices = [[NSMutableSet alloc] initWithCapacity:[hasTables count]];
    
    // MARK: Create vertex in the graph for each query table.
    for (RptqTable *table in hasTables) {
        [graph addVertexWithObject:[table objectID]];
    }
    
    // MARK: Create an edge in the graph for each query link.
    NSSet *hasQueryLinks = [query hasQueryLinks];
    for (RptqQueryLinks *queryLink in hasQueryLinks) {
        
        RptqTable *tableOrigin =        [[queryLink  hasLeftField] inTable];
        RptqTable *tableDestination =   [[queryLink hasRightField] inTable];
        
        id objectOrigin =               [tableOrigin objectID];
        id objectDestination =          [tableDestination objectID];
        id objectQueryLink =            [queryLink objectID];
        
        MTVertex *vertexOrigin =        [graph vertexForObject:objectOrigin];
        MTVertex *vertexDestination =   [graph vertexForObject:objectDestination];
        
        [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination object:objectQueryLink andWeight:@(1)];
        
    }
    
    NSError *error = nil;

    // MARK: Sort the vectors topologically.
    MTLinkedList *topologicalSort = [graph topologicalSort:[vertices anyObject] error:&error];
    
    // MARK: Error on circuts or other bad query.
    if (error) {
        [result setString:[error localizedDescription]];
    } else {
        NSInteger tableCounter = 0;
        
        // MAKR: List each field in the query.
        for (MTPair *pair in topologicalSort) {
            MTVertex *queryTable = [pair former];
            //NSUInteger timeFound = [[pair latter] integerValue];
            if (queryTable) {
                if (tableCounter != 0) [result appendString:@",\n"];
                NSManagedObjectID *objectID = [queryTable object];
                RptqTable *table = [RptqTable getTableForObjectID:objectID fromObjectContext:[query managedObjectContext]];
                NSString *tableAlias = [[table name] stringByAppendingString:@"."];
                
                NSUInteger fieldCounter = 0;
                for (RptqField *field in [table hasFields]) {
                    if (fieldCounter != 0)  [result appendString:@",\n"];
                    NSString *fieldAlias = [tableAlias stringByAppendingString:[field name]];
                    [result appendFormat: @"\t%@", fieldAlias];
                    fieldCounter++;
                }
                tableCounter++;
            }
        };
        
        // MARK: Get from part of the query.
        [result appendString:@"\nFROM\n"];
        
        NSNumber *linkDepth = [[NSNumber alloc] initWithInteger:0];
        NSArray *topologicalSortArray = [topologicalSort toArray];
        NSMutableArray *vertexArray = [[NSMutableArray alloc] initWithCapacity:[topologicalSortArray count]];
        for (MTPair *pair in topologicalSortArray) {
            MTVertex *vertexTable = [pair former];
            if (vertexTable) {
                [vertexTable setSortVertexColor: MTColorWhite];
                [vertexArray addObject:vertexTable];
            }
        }
        [result appendString:[self getSqlFromClauseWithTables:vertexArray linkDepth:&linkDepth forManagedObjectContext:[query managedObjectContext]]];
        [vertexArray release];
        [linkDepth release];
    }
    
    [vertices release];
    [graph release];
    return [result autorelease];
}

- (NSString *)getSqlFromClauseWithTables:(NSArray *)tables linkDepth:(NSNumber **)linkDepth forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSInteger tableCounter = 0;
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    for (MTVertex *vertexTable in tables) {
        if (vertexTable) {
            if ([vertexTable sortVertexColor] == MTColorWhite) {
                [vertexTable setSortVertexColor: MTColorBlack];
                NSArray *incidentEdges = [vertexTable incidentEdges];
                if (tableCounter > 0) [result appendString:@",\n"];
                NSManagedObjectID *objectID = [vertexTable object];
                RptqTable *table = [RptqTable getTableForObjectID:objectID fromObjectContext:managedObjectContext];
                NSString *tname = [table name];
                [result appendString:tname];

                for (MTEdge *edge in incidentEdges) {
                    MTVertex *vertexTableDestination = [edge destination];
                    if (vertexTableDestination) {
                        if ([vertexTableDestination sortVertexColor] == MTColorWhite) {
                            
                            [vertexTableDestination setSortVertexColor:MTColorBlack];
                            
                            NSManagedObjectID *queryLinkID = [edge object];
                            RptqQueryLinks *queryLink = [RptqQueryLinks getQueryLinkWithID:queryLinkID fromObjectContext:managedObjectContext];
                            
                            
                            if (queryLink) {                                
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
                                
                                RptqField *rightField = [queryLink hasRightField];
                                RptqTable *rightTable = [rightField inTable];
                                
                                [result appendString:[rightTable name]];
                                [result appendString:@" ON "];
                                
                                RptqField *leftField = [queryLink hasLeftField];
                                if (leftField) {
                                    [result appendString: [leftField toStringHumanReadable]];
                                }
                                [result appendString:@" = "];
                                if (rightField) {
                                    [result appendString: [rightField toStringHumanReadable]];
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
                NSString *newDip = [self getSqlFromClauseWithTables:destinationVertices linkDepth:linkDepth forManagedObjectContext:managedObjectContext];
                if ([newDip length] > 0) {
                    [result appendString:newDip];
                }
                [destinationVertices release];

                tableCounter++;
            }
        }
    }
    return [result autorelease];
}

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv];
            
            NSMutableArray *results = nil;
            
            if (conn) {
                NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", [table name]];
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:command onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *fieldMetaData = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        
                        for (NSDictionary *field in [fetch results]) {
                            NSString *fn = [field objectForKey:[fieldMetaData name]];
                            MNSDatabaseField *databaseField = [[MNSDatabaseField alloc] initWithName: fn];
                            [results addObject: databaseField];
                            [databaseField release];
                        }
                    }
                }
            }
            
            completion(results);
        });
    });
    
    
}

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion {
    
}

- (NSString *)identifier {
    return [MNSDatabaseMySql identifier];
}

+ (NSString *)identifier {
    return @"MySQL";
}

@end