//
//  RptqQueryGroup+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryGroup+Extras.h"

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>

#import <CoreData/NSPropertyMapping.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>

#import "RptqDatabaseSchemaField.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentSectionRows.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqQueryGroup (Extras)

+ (instancetype)newQueryGroupQueryWithSortOrder:(MADSortOrder)sortOrder
                        andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSEntityDescription *entityDescriptionQueryGroup;
    entityDescriptionQueryGroup= [NSEntityDescription entityForName: NSStringFromClass([RptqQueryGroup class])
                                             inManagedObjectContext: managedObjectContext];
    
    RptqQueryGroup *queryGroup = [[self alloc] initWithEntity: entityDescriptionQueryGroup
                               insertIntoManagedObjectContext: managedObjectContext];
    
    queryGroup.sort = sortOrder;
    queryGroup.weight = [queryGroup lastWeightWithManagedObjectContext:managedObjectContext] + 1;

    return queryGroup;
}

+ (NSString *)keyPathHasField {
    NSString *result = NSStringFromSelector(@selector(hasField));
    return result;
}

#pragma mark -
#pragma mark Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    if (self.managedObjectContext.parentContext && self.identifier <= 0) {
        self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                            managedObjectContext:self.managedObjectContext];
    }
}

#pragma mark -
#pragma mark Static

+ (NSUInteger)numberOfGroupsForQueryID:(NSManagedObjectID *)objectID
                  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    
    NSExpression *predicateExpression[2];
    NSString *keyInQuery = NSStringFromSelector(@selector(inQuery));
    //predicateExpression[0] = [NSExpression expressionForKeyPath: keyInQuery];
    //predicateExpression[1] = [NSExpression expressionForConstantValue: objectID];
    
    //NSPredicate *predicate;
    //predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
    //                                               rightExpression: predicateExpression[1]
    //                                                      modifier: NSDirectPredicateModifier
    //                                                          type: NSEqualToPredicateOperatorType
    //                                                       options: 0];

    //request.predicate = predicate;
    NSError *error = nil;
    NSUInteger result = [managedObjectContext countForFetchRequest:request error:&error];
    return result == NSNotFound ? 0 : result;
    
}

+ (NSUInteger)numberOfGroupsForQuery:(RptqQuery *)query {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", query.objectID];
    request.predicate = predicate;
    NSError *error = nil;
    NSUInteger result = [query.managedObjectContext countForFetchRequest:request error:&error];
    return (error) ? 0 : result;
}

#pragma mark -
#pragma mark Member functions

- (int16_t)lastWeightWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"weight"
                                                                   ascending: NO];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;

    NSError *error = nil;
    NSArray *queryGroupLast = [managedObjectContext executeFetchRequest: request error: &error];

    int16_t weight = 0;
    if (queryGroupLast.count > 0) {
        RptqQueryGroup *lastGroup = queryGroupLast[0];
        weight = lastGroup.weight;
    }
    return weight;
}

- (NSString *)fieldNameNice {
    return [self.hasField toStringHumanReadable];
}

- (NSString *)fieldNameQuery {
    return [self.hasField toString];
}

- (NSString *)sortDisplayNice {
    switch (self.sort) {

        case MADSortOrderAccending:
            return @"accending";
            break;
        
        case MADSortOrderDecending:
            return @"decending";
            break;
        
        default:
            return @"";
            break;
    }
}

- (NSInteger)location {
    NSArray *sortedQueryGroups = self.inQuery.sortedQueryGroups;
    RptqQueryGroup *queryGroup;
    NSInteger location = 0;
    for (queryGroup in sortedQueryGroups) {
        if ([queryGroup.objectID isEqual:self.objectID]) {
            break;
        }
        location++;
    }
    return location;
}

#pragma mark -
#pragma mark MTProtocolCompare

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:         %lld\n", self.identifier];
    [description appendFormat:@"Sort:               %d\n", self.sort];
    [description appendFormat:@"Weight              %hd\n", self.weight];
    [description appendFormat:@"Field:              %@\n", self.hasField];
    [description appendFormat:@"Section:            %@\n", self.hasSection];
    [description appendFormat:@"Query:              %@\n", self.inQuery];
    [description appendFormat:@"*********"];
    return description;
}

@end
