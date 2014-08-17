//
//  RptqDocumentObjectAggregate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "Constants.h"

NSString * const MTAggregateTypeKeyGroupType = @"MTAggregateTypeKeyGroupType";
NSString * const MTAggregateTypeKeyFunctionType = @"MTAggregateTypeKeyFunctionType";
NSString * const MTAggregateTypeKeyGroupNumber = @"MTAggregateTypeKeyGroupNumber";

@implementation RptqDocumentObjectAggregate (Extras)

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value {
    return [[self parentObject] formattedString:dataType forValue:value];
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectAggregate class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
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

+ (instancetype)getElementForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return (RptqDocumentObjectAggregate *)result;
}

- (NSString *)designerRepresentationText {
    return [NSString stringWithFormat:@"%@(%@)", [self functionNameShort], [[self aggregateField] toStringHumanReadable]];
}

- (NSString *)functionName {
    return [RptqDocumentObjectAggregate displayStringForType: [[self function] integerValue]];
}

- (NSString *)functionNameShort {
    return [RptqDocumentObjectAggregate shortDisplayStringForType: [[self function] integerValue]];
}

+ (NSString *)shortDisplayStringForType:(MTAggregateFunctionType)aggregateFunctionType {
    
    NSString *result = nil;
    
    switch (aggregateFunctionType) {
            
        case MTAggregateFunctionTypeCount:
            result = NSLocalizedString(@"Count", @"Count");
            break;
            
        case MTAggregateFunctionTypeFirst:
            result = NSLocalizedString(@"First", @"First");
            break;
            
        case MTAggregateFunctionTypeLast:
            result = NSLocalizedString(@"Last", @"Last");
            break;
            
        case MTAggregateFunctionTypeMax:
            result = NSLocalizedString(@"Max", @"Max");
            break;
            
        case MTAggregateFunctionTypeMean:
            result = NSLocalizedString(@"Mean", @"Mean");
            break;
            
        case MTAggregateFunctionTypeMin:
            result = NSLocalizedString(@"Min", @"Min");
            break;
            
        case MTAggregateFunctionTypeSum:
            result = NSLocalizedString(@"Sum", @"Sum");
            break;

        default:
            break;
    }
    return result;
}

+ (NSString *)displayStringForType:(MTAggregateFunctionType)aggregateFunctionType {
    
    NSString *result = nil;
    
    switch (aggregateFunctionType) {

        case MTAggregateFunctionTypeCount:
            result = NSLocalizedString(@"Count", @"Count");
            break;
        
        case MTAggregateFunctionTypeFirst:
            result = NSLocalizedString(@"First", @"First");
            break;
        
        case MTAggregateFunctionTypeLast:
            result = NSLocalizedString(@"Last", @"Last");
            break;
        
        case MTAggregateFunctionTypeMax:
            result = NSLocalizedString(@"Maximum", @"Maximum");
            break;
        
        case MTAggregateFunctionTypeMean:
            result = NSLocalizedString(@"Mean", @"Mean");
            break;
        
        case MTAggregateFunctionTypeMin:
            result = NSLocalizedString(@"Minimum", @"Minimum");
            break;
        
        case MTAggregateFunctionTypeSum:
            result = NSLocalizedString(@"Sum", @"Sum");
            break;
        
        default:
            break;

    }
    
    return result;
    
}

+ (NSString *)displayStringForGroupByType:(MTAggregateGroupByType)groupByType {

    NSString *result = nil;
    
    switch (groupByType) {
        case MTAggregateGroupByTypeSection:
            result = NSLocalizedString(@"Section: %d", @"Section: %d");
            break;
        case MTAggregateGroupByTypePage:
            result = NSLocalizedString(@"Page", @"Page");
            break;
        case MTAggregateGroupByTypeReport:
            result = NSLocalizedString(@"Report", @"Report");
            break;
        default:
            break;
    }
    
    return result;

}

- (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
                                      inputType:(MTAggregateFunctionInputType)inputType
                                      groupType:(MTAggregateGroupByType)groupType
                                aggregateObject:(NSManagedObject *)aggregateObject  //RptqQueryField or MTAggregateFunctionInputTypeFormula
                                    groupNumber:(NSUInteger)groupNumber {
    
    NSNumber *function = @(functionType);
    [self setFunction: function];
    
    NSNumber *group = @(groupNumber);
    [self setGroupNumber: group];
    
    NSNumber *gType = @(groupType);
    [self setGroupType:gType];
    
    switch (inputType) {
        case MTAggregateFunctionInputTypeField: {
            [self setAggregateField:(RptqQueryField *)aggregateObject];
            [self setAggregateFunction:nil];
            break;
        }
        case MTAggregateFunctionInputTypeFormula: {
            [self setAggregateField:nil];
            [self setAggregateFunction:(RptqDocumentObjectFormula *)aggregateObject];
            break;
        }
        default:
            break;
    }
    
    NSError *error = nil;
    [[self managedObjectContext] save:&error];
    
}

@end
