//
//  MTQuerySelect.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheSelect.h"
#import "MTDatabaseConnection.h"

// FIXME: Remove dependency on MTDatabaseSqlite3
#import "MTDatabaseSqlite3.h"

@interface MTQueryCacheSelect ()

@property (nonatomic, strong) MTDatabaseConnection *databaseConnection;
@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *fieldKeys;
@property (nonatomic, strong) NSArray *predicates;
@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, assign) NSUInteger offset;
@property (nonatomic, assign) NSUInteger limit;

//- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;

@end

@implementation MTQueryCacheSelect

@dynamic fieldKeys;

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQuerySelect expects NSDictionary.");
        
        NSNumber *keyMTQuerySelectConnection = @(MTQuerySelectConnection);
        NSNumber *keyMTQuerySelectTableName = @(MTQuerySelectTableName);
        NSNumber *keyMTQuerySelectFieldKeys = @(MTQuerySelectFieldKeys);
        NSNumber *keyMTQuerySelectLimit = @(MTQuerySelectLimit);
        NSNumber *keyMTQuerySelectOffset = @(MTQuerySelectOffset);
        NSNumber *keyMTQuerySelectPredicates = @(MTQuerySelectPredicates);
        NSNumber *keyMTQuerySelectSortDescriptors = @(MTQuerySelectSortDescriptors);
    
        MTDatabaseConnection *databaseConnection = object[keyMTQuerySelectConnection];
        NSString *tableName = object[keyMTQuerySelectTableName];
        NSArray *fieldKeys = [[NSArray alloc] initWithArray:object[keyMTQuerySelectFieldKeys]];

        NSUInteger limit = [object[keyMTQuerySelectLimit] integerValue];
        NSUInteger offset = [object[keyMTQuerySelectOffset] integerValue];
        
        NSArray *predicates = [[NSArray alloc] initWithArray:object[keyMTQuerySelectPredicates]];
        NSArray *sortDescriptors = [[NSArray alloc] initWithArray:object[keyMTQuerySelectSortDescriptors]];
        
        [self setDatabaseConnection:databaseConnection];
        [self setTableName:tableName];
        [self setFieldKeys:fieldKeys];
        [self setLimit:limit];
        [self setOffset:offset];
        [self setPredicates:predicates];
        [self setSortDescriptors:sortDescriptors];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
/*
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
            RptqQueryTable *tableDestination =   [queryLink.hasRightField inQueryTable];
            
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
    */
    return result;
}

- (BOOL)returnsResults {
    return YES;
}

@end
