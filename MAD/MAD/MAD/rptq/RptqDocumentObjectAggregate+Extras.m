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
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSBundle.h>

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
    NSArray *sortDescriptors = @[sortDescriptor];
    [request setSortDescriptors: sortDescriptors];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectAggregate *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
    self.identifier = identifierObj;
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
    return [NSString stringWithFormat:@"%@(%@)", [self functionNameShort], [self.aggregateField toStringHumanReadable]];
}

- (NSString *)functionName {
    return [RptqDocumentObjectAggregate newStringDisplayForType: self.function.unsignedIntegerValue];
}

- (NSString *)functionNameShort {
    return [RptqDocumentObjectAggregate shortDisplayStringForType: self.function.unsignedIntegerValue];
}

+ (NSString *)shortDisplayStringForType:(MTAggregateFunctionType)aggregateFunctionType {
    
    switch (aggregateFunctionType) {
            
        case MTAggregateFunctionTypeCount:
            return NSLocalizedString(@"Count", @"Count");
            break;
            
        case MTAggregateFunctionTypeFirst:
            return NSLocalizedString(@"First", @"First");
            break;
            
        case MTAggregateFunctionTypeLast:
            return NSLocalizedString(@"Last", @"Last");
            break;
            
        case MTAggregateFunctionTypeMax:
            return NSLocalizedString(@"Max", @"Max");
            break;
            
        case MTAggregateFunctionTypeMean:
            return NSLocalizedString(@"Mean", @"Mean");
            break;
            
        case MTAggregateFunctionTypeMin:
            return NSLocalizedString(@"Min", @"Min");
            break;
            
        case MTAggregateFunctionTypeSum:
            return NSLocalizedString(@"Sum", @"Sum");
            break;

        default:
            return @"";
            break;
    }
}

+ (NSString *)newStringDisplayForType:(MTAggregateFunctionType)aggregateFunctionType {

    switch (aggregateFunctionType) {

        case MTAggregateFunctionTypeCount:
            return NSLocalizedString(@"Count", @"Count");
            break;
        
        case MTAggregateFunctionTypeFirst:
            return NSLocalizedString(@"First", @"First");
            break;
        
        case MTAggregateFunctionTypeLast:
            return NSLocalizedString(@"Last", @"Last");
            break;
        
        case MTAggregateFunctionTypeMax:
            return NSLocalizedString(@"Maximum", @"Maximum");
            break;
        
        case MTAggregateFunctionTypeMean:
            return NSLocalizedString(@"Mean", @"Mean");
            break;
        
        case MTAggregateFunctionTypeMin:
            return NSLocalizedString(@"Minimum", @"Minimum");
            break;
        
        case MTAggregateFunctionTypeSum:
            return NSLocalizedString(@"Sum", @"Sum");
            break;
        
        default:
            return @"";
            break;

    }
    
}

+ (NSString *)newStringDisplayForGroupByType:(MTAggregateGroupByType)groupByType {

    switch (groupByType) {
        case MTAggregateGroupByTypeSection:
            return NSLocalizedString(@"Section: %d", @"Section: %d");
            break;
        case MTAggregateGroupByTypePage:
            return NSLocalizedString(@"Page", @"Page");
            break;
        case MTAggregateGroupByTypeReport:
            return NSLocalizedString(@"Report", @"Report");
            break;
        default:
            return @"";
            break;
    }
}

- (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
                                      inputType:(MTAggregateFunctionInputType)inputType
                                      groupType:(MTAggregateGroupByType)groupType
                                aggregateObject:(NSManagedObject *)aggregateObject  //RptqQueryField or MTAggregateFunctionInputTypeFormula
                                    groupNumber:(NSUInteger)groupNumber {
    
    NSNumber *function = @(functionType);
    self.function = function;
    
    NSNumber *group = @(groupNumber);
    self.groupNumber = group;
    
    NSNumber *gType = @(groupType);
    self.groupType = gType;
    
    switch (inputType) {
        case MTAggregateFunctionInputTypeField: {
            self.aggregateField = (RptqQueryField *)aggregateObject;
            self.aggregateFunction = nil;
            break;
        }
        case MTAggregateFunctionInputTypeFormula: {
            self.aggregateField = nil;
            self.aggregateFunction = (RptqDocumentObjectFormula *)aggregateObject;
            break;
        }
        default:
            break;
    }
    
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Function:               %@\n", self.function];
    [description appendFormat:@"Group number:           %@\n", self.groupNumber];
    [description appendFormat:@"Group type:             %@\n", self.groupType];
    [description appendFormat:@"*********"];
    return description;
}

@end
