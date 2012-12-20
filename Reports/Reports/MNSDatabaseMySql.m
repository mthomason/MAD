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
    MTLinkedList *topologicalSort = [graph topologicalSort:[vertices anyObject] error:&error];
    
    if (!error) {
        
        NSInteger tableCounter = 0;
        for (MTPair *pair in topologicalSort) {
            MTVertex *queryTable = [pair former];
            NSUInteger timeFound = [[pair latter] integerValue];
            if (queryTable) {
                if (tableCounter != 0) [result appendString:@",\n"];
                NSManagedObjectID *objectID = [queryTable object];
                RptqTable *table = [RptqTable getTableForObjectID:objectID fromObjectContext:[query managedObjectContext]];
                //NSString *tableAlias = [NSString stringWithFormat:@"T%d.", timeFound];
                NSString *tableAlias = [table name];
                
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
        [result appendString:@"\nFROM\n"];

        [result appendString:[self getSqlFromPartWithTablesInList:[topologicalSort toArray] forManagedObjectContext:[query managedObjectContext]]];
        
    }
    
    [vertices release];
    [graph release];
    return [result autorelease];
}

- (NSString *)getSqlFromPartWithTablesInList:(NSArray *)tables forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    for (MTPair *pair in tables) {
        MTVertex *vertexTable = [pair former];
        if (vertexTable) {
            [result appendString:@"\t("];

            NSManagedObjectID *objectID = [vertexTable object];
            RptqTable *table = [RptqTable getTableForObjectID:objectID fromObjectContext:managedObjectContext];
            NSString *tname = [table name];
            [result appendString:tname];
            [result appendString:@" "];
            NSNumber *linkDepth = [[NSNumber alloc] initWithInteger:0];
            [result appendString:[self getSometingForThis:vertexTable linkDepth:&linkDepth forManagedObjectContext:managedObjectContext]];
            [linkDepth release];
            [result appendString:@")\n"];
        }
    }
    return [result autorelease];
}

- (NSString *)getSometingForThis:(MTVertex *)vertexTable linkDepth:(NSNumber **)linkDepth forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    //NSMutableString *prefix = [[NSMutableString alloc] initWithString:@"\n"];
    //for (NSUInteger i = 0; i < [*linkDepth integerValue] + 2; i++) {
    //    [prefix appendString:@"\t"];
    //}
    //[prefix appendString:@"("];
    
        
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    //for (NSUInteger i = 0; i < [*linkDepth integerValue] + 2; i++) {
    //    [result appendString:@"\t"];
    //}
    //[result appendString:@"("];
    
    NSInteger tableCounter = 0;
    *linkDepth = @([*linkDepth integerValue] + 1);
    if (vertexTable) {
        NSArray *incidentEdges = [vertexTable incidentEdges];
        if ([incidentEdges count] > 0) {
            
            for (MTEdge *edge in [vertexTable incidentEdges]) {
                MTVertex *vertexTableDestination = [edge destination];
                
                if (vertexTableDestination) {

                    NSManagedObjectID *queryLinkID = [edge object];
                    RptqQueryLinks *queryLink = [RptqQueryLinks getQueryLinkWithID:queryLinkID fromObjectContext:managedObjectContext];
                    if (queryLink) {
                        
                        NSUInteger ld =  [*linkDepth integerValue];
                        if (ld > 1) {
                            [result appendString:@"\n"];
                            [result appendString:[@"" stringByPaddingToLength:ld*1 withString: @"\t" startingAtIndex:0]];
                            //[result appendString:@"\t"];
                            [result appendString:@"("];
                        }
                        
                        //NSManagedObjectID *objectID = [vertexTable object];
                        //RptqTable *table = [RptqTable getTableForObjectID:objectID fromObjectContext:managedObjectContext];
                        //NSString *tname = [table name];
                        //[result appendString:tname];
                        //[result appendString:@" "];


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

                    
                    NSString *more = [self getSometingForThis:vertexTableDestination linkDepth:linkDepth forManagedObjectContext:managedObjectContext];
                    if ([more length] > 0) {
                        //[result appendString:@"("];
                        [result appendString:more];
                        //[result appendString:@")"];
                    }
                    
                    if ([*linkDepth integerValue] > 1) {
                        [result appendString:@")"];
                    }
                }
            }
        }
        tableCounter++;
    }

    
/*
    if ([result length] != 0) {

        NSMutableString *prefix = [[NSMutableString alloc] initWithString:@"\n"];
        NSMutableString *suffix = [[NSMutableString alloc] initWithString:@""];
        
        for (NSUInteger i = 0; i < [*linkDepth integerValue] + 2; i++) {
            [prefix appendString:@"\t"];
            [suffix appendString:@"\t"];
        }
        [prefix appendString:@"("];
        [suffix appendString:@")\n"];
        
        [result insertString:prefix atIndex:0];
        [result appendString:suffix];
        
        [prefix release];
        [suffix release];

    }
*/

    
    //[result appendString:@"\t\t)\n"];
    return [result autorelease];
}

- (void)getTables: (void (^)(NSArray *tables))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            MysqlServer *serv = [[MysqlServer alloc] init];

            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv];
            
            //NSInteger colctr = 0;
            
            NSMutableArray *results = nil;
            
            if (conn) {
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *resultsTableName = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        
                        for (NSDictionary *tableName in [fetch results]) {
                            NSString *tn = [tableName objectForKey:[resultsTableName name]];
                            MNSDatabaseTable *databaseTable = [[MNSDatabaseTable alloc] initWithTableName: tn];
                            [results addObject: databaseTable];
                            [databaseTable release];
                        }
                    }
                }
            }
            
            completion(results);
        });
    });
    
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