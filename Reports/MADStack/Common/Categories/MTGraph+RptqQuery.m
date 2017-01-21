//
//  MTGraph+RptqQuery.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTGraph+RptqQuery.h"
#import <CoreData/NSManagedObjectID.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>

@implementation MTGraph (RptqQuery)

/*- (instancetype)initWithQuery:(NSManagedObjectID *)queryObjectID
         managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    if (self = [self init]) {
        
        NSSet <RptqQueryTable *> *queryTables = query.hasQueryTables;
        
        //Add a vertex to the graph for each table.
        NSManagedObjectID *objectID;
        for (RptqDatabaseSchemaTable *table in queryTables) {
            objectID = table.objectID.copy;
            [self addVertexWithObject: objectID];
        }
        
        //Create an edge in the graph for each query link.
        NSNumber *weight = @(1);
        
        
        for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
            
            
            MTVertex *vertexOrigin =        [self vertexForObject:(MTObject *)queryLink.hasLeftField.inQueryTable.objectID];
            MTVertex *vertexDestination =   [self vertexForObject:(MTObject *)queryLink.hasRightField.inQueryTable.objectID];
            
            [self addEdgeWithOrigin: vertexOrigin
                        destination: vertexDestination
                             object: queryLink.objectID
                          andWeight: weight];
            
        }
    }
    
    return self;
}*/

- (instancetype)initWithQuery:(RptqQuery *)query {
    
    if (self = [self init]) {
        
        NSSet <RptqQueryTable *> *hasTables = query.hasQueryTables;
        
        //Add a vertex to the graph for each table.
        NSManagedObjectID *objectID;
        for (RptqQueryTable *table in hasTables) {
            objectID = table.objectID.copy;
            [self addVertexWithObject: objectID];
        }
        
        //Create an edge in the graph for each query link.
        NSNumber *weight = @(1);
        
        
        for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
            
            
            MTVertex *vertexOrigin =        [self vertexForObject:(MTObject *)queryLink.hasLeftField.inQueryTable.objectID];
            MTVertex *vertexDestination =   [self vertexForObject:(MTObject *)queryLink.hasRightField.inQueryTable.objectID];
            
            [self addEdgeWithOrigin: vertexOrigin
                        destination: vertexDestination
                             object: queryLink.objectID
                          andWeight: weight];
            
        }
    }
    
    return self;
}

@end
