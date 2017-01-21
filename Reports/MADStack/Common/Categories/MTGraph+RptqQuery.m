//
//  MTGraph+RptqQuery.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTGraph+RptqQuery.h"
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedPropertyDescription.h>
#import <CoreData/NSPropertyDescription.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>


@implementation MTGraph (RptqQuery)

- (instancetype)initWithQuery:(NSManagedObjectID *)queryID
         managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    if (self = [self init]) {
        
        id result;
        NSError * __autoreleasing *error = NULL;
        NSString *expressionDescriptionHasQueryTables = @"madQT";
        NSFetchRequest *request;
        NSComparisonPredicate *predicate;
        NSExpression *expression[2];
        NSExpressionDescription *descHasQueryTables;
        NSExpression *keyPathHasQueryTables;
        
        NSExpressionDescription *descObjectID = [[NSExpressionDescription alloc] init];
        descObjectID.name = NSStringFromSelector(@selector(objectID));
        descObjectID.expression = [NSExpression expressionForEvaluatedObject];
        descObjectID.expressionResultType = NSObjectIDAttributeType;
        
        NSExpressionDescription *descQueryTables;
        descQueryTables = [[NSExpressionDescription alloc] init];
        descObjectID.name = expressionDescriptionHasQueryTables.copy;
        descObjectID.expression = [NSExpression expressionForSubquery:[NSExpression expressionForKeyPath:NSStringFromSelector(@selector(hasQueryTables))]
                                                usingIteratorVariable:NSStringFromSelector(@selector(objectID))
                                                            predicate:[NSPredicate predicateWithValue:YES]];
        descObjectID.expressionResultType = NSManagedObjectIDResultType;
        
        NSArray *keyPathQueryTables;
        
        descHasQueryTables = [[NSExpressionDescription alloc] init];
        descHasQueryTables.name = expressionDescriptionHasQueryTables.copy;
        keyPathHasQueryTables = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(hasQueryTables))];
        keyPathQueryTables = [[NSArray alloc] initWithObjects:keyPathHasQueryTables, nil];
        descHasQueryTables.expression = [NSExpression expressionForFunction: @"count:"
                                                                  arguments: keyPathQueryTables];
        
        expression[0] = [NSExpression expressionForEvaluatedObject];
        expression[1] = [NSExpression expressionForConstantValue: queryID];
        predicate= [NSComparisonPredicate predicateWithLeftExpression: expression[0]
                                                      rightExpression: expression[1]
                                                             modifier: NSDirectPredicateModifier
                                                                 type: NSEqualToPredicateOperatorType
                                                              options: 0];
        
        NSEntityDescription *entityDescription;
        NSArray *propertiesToFetch;
        
        entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQuery class])
                                        inManagedObjectContext: managedObjectContext];
        request = [[NSFetchRequest alloc] init];
        
        propertiesToFetch = [[NSArray alloc] initWithObjects:descHasQueryTables,
                             descObjectID, nil];
        request.propertiesToFetch = propertiesToFetch;
        request.entity = entityDescription;
        request.fetchLimit = 1;
        request.predicate = predicate;
        request.resultType = NSDictionaryResultType;
        request.includesSubentities = NO;
        
        result = [managedObjectContext executeFetchRequest:request error:error];
        /*
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
            
        }*/
    }
    
    return self;
}

- (instancetype)initWithQuery:(RptqQuery *)query {
    
    if (self = [self init]) {
        
        NSManagedObjectContext *managedObjectContext = query.managedObjectContext;
        NSManagedObjectID *queryID = query.objectID;
        NSExpression *expression1[2];
        expression1[0] = [NSExpression expressionForKeyPath:@"inQuery"];
        expression1[1] = [NSExpression expressionForConstantValue: queryID];

        NSPredicate *predicate1 = [NSComparisonPredicate predicateWithLeftExpression: expression1[0]
                                                      rightExpression: expression1[1]
                                                             modifier: NSDirectPredicateModifier
                                                                 type: NSEqualToPredicateOperatorType
                                                              options: 0];

        NSExpression *expression2[2];
        expression2[0] = [NSExpression expressionForEvaluatedObject];
        expression2[1] = [NSExpression expressionForConstantValue: queryID];
        NSPredicate *predicate2 = [NSComparisonPredicate predicateWithLeftExpression: expression1[0]
                                                                     rightExpression: expression1[1]
                                                                            modifier: NSDirectPredicateModifier
                                                                                type: NSEqualToPredicateOperatorType
                                                                             options: 0];

        NSFetchRequest *request1;
        request1 = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryTable class])];

        NSExpressionDescription *expSelf = [[NSExpressionDescription alloc] init];
        expSelf.name = @"T1";
        expSelf.expression = [NSExpression expressionForEvaluatedObject];
        expSelf.expressionResultType = NSManagedObjectIDResultType;

        NSArray *propertiesToFetch1 = [[NSArray alloc] initWithObjects:expSelf, @"inQuery", nil];
        
        request1.propertiesToFetch = propertiesToFetch1;
        request1.resultType = NSDictionaryResultType;
        request1.predicate = predicate1;
        
        NSError * __autoreleasing *error1 = NULL;
        NSArray *results = [managedObjectContext executeFetchRequest:request1 error:error1];

        
        
        
        id result;
        NSError * __autoreleasing *error = NULL;
        NSString *expressionDescriptionHasQueryTables = @"QT";
        NSFetchRequest *request;
        NSComparisonPredicate *predicate;
        NSExpression *expression[2];
        //NSExpression *keyPathHasQueryTables;
        
        NSExpressionDescription *descObjectID = [[NSExpressionDescription alloc] init];
        descObjectID.name = NSStringFromSelector(@selector(objectID));
        descObjectID.expression = [NSExpression expressionForEvaluatedObject];
        descObjectID.expressionResultType = NSObjectIDAttributeType;
        
        
        NSExpressionDescription *descQueryTables;
        descQueryTables = [[NSExpressionDescription alloc] init];
        descQueryTables.name = expressionDescriptionHasQueryTables.copy;
        NSEntityDescription *entityDescription, *entityDescriptionQueryTable;
        entityDescriptionQueryTable = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTable class])
                                        inManagedObjectContext: managedObjectContext];
        descQueryTables.expression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(hasQueryTables))];
        descQueryTables.expressionResultType = NSManagedObjectIDResultType;
        NSPredicate *paaa = [NSPredicate predicateWithValue:YES];
        //descQueryTables.validationWarnings = @[paaa];

        NSExpressionDescription *hasQueryTablesExpression = [[NSExpressionDescription alloc] init];
        hasQueryTablesExpression.name = @"hasQueryTables";
        hasQueryTablesExpression.expression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(hasQueryTables))];
        hasQueryTablesExpression.expressionResultType = NSManagedObjectIDResultType;
        /*
        NSExpressionDescription *descSubQuery = [[NSExpressionDescription alloc] init];
        descSubQuery.name = @"Subquery Name";
        descSubQuery.expression = [NSExpression expressionForSubquery: [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(hasQueryTables))]
                                                   usingIteratorVariable: @"Subquery" // NSStringFromSelector(@selector(objectID))
                                                               predicate: [NSPredicate predicateWithValue:YES]];
        descSubQuery.expressionResultType = NSManagedObjectIDResultType;
        */
        expression[0] = [NSExpression expressionForEvaluatedObject];
        expression[1] = [NSExpression expressionForConstantValue: queryID];
        predicate= [NSComparisonPredicate predicateWithLeftExpression: expression[0]
                                                      rightExpression: expression[1]
                                                             modifier: NSDirectPredicateModifier
                                                                 type: NSEqualToPredicateOperatorType
                                                              options: 0];
        //NSPredicate *predicate2;
        predicate2= [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForEvaluatedObject]
                                                       rightExpression: [NSExpression expressionForKeyPath:expressionDescriptionHasQueryTables]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSInPredicateOperatorType
                                                               options: 0];
        NSPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, predicate2]];
        NSArray *propertiesToFetch;
        NSPredicate *pa = [NSPredicate predicateWithValue:YES];
        entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQuery class])
                                        inManagedObjectContext: managedObjectContext];
        request = [[NSFetchRequest alloc] init];
        
        propertiesToFetch = [[NSArray alloc] initWithObjects:descQueryTables, descObjectID, hasQueryTablesExpression, nil];
        request.propertiesToFetch = propertiesToFetch;
        request.entity = entityDescription;
        //request.fetchLimit = 1;
        pa = [NSPredicate predicateWithFormat:@"ANY %@ in hasQueryTables", @"queryTable.inQuery", queryID];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"objectID" ascending:YES];
        request.sortDescriptors = @[sd];
        request.predicate = pa;
        request.resultType = NSDictionaryResultType;
        request.includesSubentities = YES;
        
        
        result = [managedObjectContext executeFetchRequest:request error:error];
        
        
        
        
        
        
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
