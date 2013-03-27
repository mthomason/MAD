//
//  RptqDocumentObjectAggregate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectAggregate+Extras.h"

NSString * const MTAggregateTypeKeyGroupType = @"MTAggregateTypeKeyGroupType";
NSString * const MTAggregateTypeKeyFunctionType = @"MTAggregateTypeKeyFunctionType";
NSString * const MTAggregateTypeKeyGroupNumber = @"MTAggregateTypeKeyGroupNumber";

@implementation RptqDocumentObjectAggregate (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectAggregate class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectAggregate *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

+ (id)getElementForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectAggregate class])];
    [request setPredicate: [NSPredicate predicateWithFormat:@"self == %@", objectId]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    RptqDocumentObjectAggregate *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (NSString *)displayStringForType:(MTAggregateFunctionType)aggregateFunctionType {
    
    NSString *result = nil;
    
    switch (aggregateFunctionType) {
        case MTAggregateFunctionTypeCount:
            result = @"Count";
            break;
        case MTAggregateFunctionTypeFirst:
            result = @"First";
            break;
        case MTAggregateFunctionTypeLast:
            result = @"Last";
            break;
        case MTAggregateFunctionTypeMax:
            result = @"Maximum";
            break;
        case MTAggregateFunctionTypeMean:
            result = @"Mean";
            break;
        case MTAggregateFunctionTypeMin:
            result = @"Minimum";
            break;
        case MTAggregateFunctionTypeSum:
            result = @"Sum";
            break;
        default:
            break;
    }
    
    return result;
    
}

@end
