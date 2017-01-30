//
//  RptqDocumentElementAggregate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementAggregate+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSBundle.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument+CoreDataClass.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqQueryField+Extras.h"

#import "RptqDataHelper.h"

NSString * const MTAggregateTypeKeyGroupType = @"MTAggregateTypeKeyGroupType";
NSString * const MTAggregateTypeKeyFunctionType = @"MTAggregateTypeKeyFunctionType";
NSString * const MTAggregateTypeKeyGroupNumber = @"MTAggregateTypeKeyGroupNumber";

@implementation RptqDocumentElementAggregate (Extras)

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [self formattedString:dataType forValue:value];
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    int64_t identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
    CFNumberRef n = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &identifier);
    self.identifier = (__bridge NSNumber * _Nullable)(n);
    CFRelease(n);
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

+ (instancetype)getElementForObjectID: (NSManagedObjectID *)objectId
                    fromObjectContext: (NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectWithID:objectId];
    return (RptqDocumentElementAggregate *)result;
}

- (NSString *)copyDesignerRepresentationText {
    NSString *toStringHumanReadable = [self.aggregateField toStringHumanReadable];
    NSString *functionNameShort = [self functionNameShort];
    id result = [[NSString alloc] initWithFormat:@"%@(%@)",
                                                 functionNameShort, toStringHumanReadable];
    return result;
}

- (NSString *)functionName {
    return [RptqDocumentElementAggregate newStringDisplayForType: self.function.shortValue];
}

- (NSString *)functionNameShort {
    return [RptqDocumentElementAggregate shortDisplayStringForType: self.function.shortValue];
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
    
    id value;
    value = [[NSNumber alloc] initWithUnsignedInteger: functionType];
    self.function = value;
    
    value = [[NSNumber alloc] initWithUnsignedInteger: groupNumber];
    self.groupNumber = value;
    
    value = [[NSNumber alloc] initWithUnsignedInteger: groupType];
    self.groupType = value;
    
    switch (inputType) {
        case MTAggregateFunctionInputTypeField: {
            self.aggregateField = (RptqQueryField *)aggregateObject;
            self.aggregateFunction = nil;
            break;
        }
        case MTAggregateFunctionInputTypeFormula: {
            self.aggregateField = nil;
            self.aggregateFunction = (RptqDocumentElementFormula *)aggregateObject;
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
