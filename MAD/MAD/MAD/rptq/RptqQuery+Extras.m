//
//  RptqQuery+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQuery+Extras.h"

#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <MADFoundation/NSString+Common.h>

#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MTDatabase.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqQuery.h"

#import "RptqQueryGroup.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqDatabase.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "MADSortOrder.h"

#import "RptqDataHelper.h"

#import "NSPredicate+Creators.h"

static inline unsigned long MADSectionCountWithGroupCount(unsigned long);
static inline unsigned long MADSectionCountWithGroupCount(unsigned long groupCount) {
    return 5 + groupCount * 2;
}

@implementation RptqQuery (Extras)

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return [key isEqualToString:NSStringFromSelector(@selector(hasQueryGroups))];
}

+ (NSUInteger)sectionCountFectch:(NSManagedObjectID *)queryObjectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSString *keyPath = NSStringFromSelector(@selector(inQuery));
    NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID:queryObjectID
                                                               atKeyPath:keyPath];
    NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
    request.predicate = predicate;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    NSError * __autoreleasing *error = NULL;
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:error];
    return MADSectionCountWithGroupCount(count);
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

- (NSUInteger)sectionCount { return MADSectionCountWithGroupCount(self.hasQueryGroups.count); }

#pragma mark -
#pragma mark Actions

- (RptqQueryGroup *)firstQueryGroup {
    NSArray *queryGroups = [self sortedQueryGroups];
    return (queryGroups.count >= 1) ? queryGroups[0] : nil;
}

- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index {
    NSArray *queryGroups = [self sortedQueryGroups];
    return (index < queryGroups.count) ? queryGroups[index] : nil;
}

- (NSArray <RptqQueryGroup *> *)sortedQueryGroups {
    NSString *weight = NSStringFromSelector(@selector(weight));
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:weight ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    NSArray *sortedArray = [self.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}

- (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)database {

    NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
    
    MADSafeQueryField *nameTablePart, *nameFieldPart;
    NSString *keyForSort, *valueInQueryTableAlias;
    NSSortDescriptor *sort;
    BOOL sortDirectionIsAscending;
    for (RptqQueryGroup *queryGroup in [self sortedQueryGroups]) {
        @autoreleasepool {
            sortDirectionIsAscending = (queryGroup.sort == MADSortOrderAccending);
            RptqQueryField *groupField = queryGroup.hasField;
            
            valueInQueryTableAlias = [groupField.inQueryTable queryAlias];

            nameTablePart = [database newSafeIdentifier: valueInQueryTableAlias];
            nameFieldPart = [database newSafeIdentifier: groupField.databaseSchemaField.name];
            
            keyForSort = [nameTablePart stringByAppendingPeriod];
            keyForSort = [keyForSort stringByAppendingString: nameFieldPart];
            
            SEL sel = MADDataTypeSelectorForSorting(groupField.databaseSchemaField.dataType);
            sort = [[NSSortDescriptor alloc] initWithKey: keyForSort
                                               ascending: sortDirectionIsAscending
                                                selector: sel];
            [sortedSortDescriptorsGroup addObject:sort];
        }
    }
    return sortedSortDescriptorsGroup;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:         %lld\n", self.identifier];
    [description appendFormat:@"Cached text:        %@\n", self.cachedText];
    [description appendFormat:@"Override:           %@\n", self.override ? @"YES" : @"NO"];
    [description appendFormat:@"Override text:      %@\n", self.overrideText];
    [description appendFormat:@"Fields:             %@\n", self.hasFields];
    [description appendFormat:@"Database:           %@\n", self.inDatabase];
    [description appendFormat:@"Query tables (%lu): %@\n", (unsigned long)self.hasQueryTables.count, self.hasQueryTables];
    [description appendFormat:@"Query groups (%lu): %@\n", (unsigned long)self.hasQueryGroups.count, self.hasQueryGroups];
    
    NSArray *sortedQueryGroups = [self sortedQueryGroups];
    for (RptqQueryGroup *group in sortedQueryGroups) {
        [description appendFormat:@"\t\t- %@", group];
    }
    
    [description appendFormat:@"Query links:        %@\n", self.hasQueryLinks];
    [description appendFormat:@"Query predicate:    %@\n", self.hasQueryPredicate];
    [description appendFormat:@"Query sort:         %@\n", self.hasQuerySort];
    [description appendFormat:@"*********"];
    return description;
}

@end
