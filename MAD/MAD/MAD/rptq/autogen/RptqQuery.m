//
//  RptqQuery+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqQueryTable.h"

#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequestExpression.h>

#import <Foundation/NSExpression.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSComparisonPredicate.h>

@implementation RptqQuery

@end

@implementation RptqQuery (CoreDataProperties)

+ (NSFetchRequest<RptqQuery *> *)fetchRequest {
    NSString *entityName = NSStringFromClass([RptqQuery class]);
    return [[NSFetchRequest alloc] initWithEntityName:entityName];
}

+ (NSFetchRequest *)fetchRequestTableCount:(NSNumber *)queryIdentifier
                             objectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request;
    NSComparisonPredicate *predicate;
    NSExpression *expression[2];
    NSExpressionDescription *expressionDescriptionQueryTableCount;
    NSExpressionDescription *expressionDescriptionQueryObjectID;
    NSExpression *expressionHasQueryTables;
    
    expressionDescriptionQueryObjectID = [[NSExpressionDescription alloc] init];
    expressionDescriptionQueryObjectID.name = NSStringFromSelector(@selector(objectID));
    expressionDescriptionQueryObjectID.expression = [NSExpression expressionForEvaluatedObject];
    expressionDescriptionQueryObjectID.expressionResultType = NSObjectIDAttributeType;
    
    NSArray *keyPathQueryTables;
    NSString *keyPathHasQueryTables = NSStringFromSelector(@selector(hasQueryTables));
    
    expressionDescriptionQueryTableCount = [[NSExpressionDescription alloc] init];
    expressionDescriptionQueryTableCount.name = @"madQTC";//keyPathHasQueryTables.copy;
    expressionDescriptionQueryTableCount.expressionResultType = NSInteger32AttributeType;
    
    expressionHasQueryTables = [NSExpression expressionForKeyPath:keyPathHasQueryTables];
    keyPathQueryTables = [[NSArray alloc] initWithObjects:expressionHasQueryTables, nil];
    
    
    expressionDescriptionQueryTableCount.expression = [NSExpression expressionForFunction: @"count:"
                                                                                arguments: keyPathQueryTables];
    
    expression[0] = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))];
    expression[1] = [NSExpression expressionForConstantValue: queryIdentifier];
    predicate= [NSComparisonPredicate predicateWithLeftExpression: expression[0]
                                                  rightExpression: expression[1]
                                                         modifier: NSDirectPredicateModifier
                                                             type: NSEqualToPredicateOperatorType
                                                          options: 0];
    
    NSEntityDescription *entityDescription;
    NSArray *propertiesToFetch;
    
    entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQuery class])
                                    inManagedObjectContext: context];
    request = [[NSFetchRequest alloc] init];
    
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescriptionQueryTableCount,
                         //expressionDescriptionQueryObjectID, nil];
                         nil];
    request.propertiesToFetch = propertiesToFetch;
    request.entity = entityDescription;
    request.fetchLimit = 1;
    request.predicate = predicate;
    request.resultType = NSDictionaryResultType;
    request.includesSubentities = NO;
    return request;
}

@dynamic cachedText;
@dynamic identifier;
@dynamic override;
@dynamic overrideText;
@dynamic hasFields;
@dynamic hasQueryGroups;
@dynamic hasQueryLinks;
@dynamic hasQueryPredicate;
@dynamic hasQuerySort;
@dynamic hasQueryTables;
@dynamic inDatabase;

@end
