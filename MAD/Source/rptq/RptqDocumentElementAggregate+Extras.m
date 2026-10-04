//
//  RptqDocumentElementAggregate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocumentElementAggregate+Extras.h"

#import <os/log.h>
#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>

#import "RptqDocument.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDataHelper.h"
#import <os/log.h>

static os_log_t rptq_log;

NSString * const MTAggregateTypeKeyGroupType = @"MTAggregateTypeKeyGroupType";
NSString * const MTAggregateTypeKeyFunctionType = @"MTAggregateTypeKeyFunctionType";
NSString * const MTAggregateTypeKeyGroupNumber = @"MTAggregateTypeKeyGroupNumber";

@implementation RptqDocumentElementAggregate (Extras)

#pragma mark -
#pragma mark Static

+ (void)load {
	if (self == [RptqDocumentElementAggregate class]) {
		NSString *c = NSStringFromClass([RptqDocumentElementAggregate class]);
		rptq_log = os_log_create("com.mad", c.UTF8String);
	}
}

#pragma mark - Overrides

+ (instancetype)getElementForObjectID: (int64_t)objectId
					fromObjectContext: (RptqStoreContext *)managedObjectContext {
	RptqObject *result = [managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class])
												   identifier:objectId];
	if (!result) {
		os_log_error(rptq_log, "Error loading object with ID: %lld", objectId);
	}
	return (RptqDocumentElementAggregate *)result;
}

- (NSString *)designerRepresentationText {
	NSString *toStringHumanReadable = [self.aggregateField toStringHumanReadable];
	NSString *functionNameShort = [RptqDocumentElementAggregate shortDisplayStringForType: self.functionType];
	return [[NSString alloc] initWithFormat:@"%@(%@)", functionNameShort, toStringHumanReadable];
}

- (NSString *)functionName {
	return [RptqDocumentElementAggregate newStringDisplayForType: self.functionType];
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
		case MTAggregateFunctionTypeCount: return NSLocalizedString(@"Count", @"Count");
		case MTAggregateFunctionTypeFirst: return NSLocalizedString(@"First", @"First");
		case MTAggregateFunctionTypeLast: return NSLocalizedString(@"Last", @"Last");
		case MTAggregateFunctionTypeMax: return NSLocalizedString(@"Maximum", @"Maximum");
		case MTAggregateFunctionTypeMean: return NSLocalizedString(@"Mean", @"Mean");
		case MTAggregateFunctionTypeMin: return NSLocalizedString(@"Minimum", @"Minimum");
		case MTAggregateFunctionTypeSum: return NSLocalizedString(@"Sum", @"Sum");
		default: return @"";
	}
	
}

+ (NSString *)newStringDisplayForGroupByType:(MTAggregateGroupByType)groupByType {

	switch (groupByType) {
		case MTAggregateGroupByTypeSection: return NSLocalizedString(@"Section: %d", @"Section: %d");
		case MTAggregateGroupByTypePage: return NSLocalizedString(@"Page", @"Page");
		case MTAggregateGroupByTypeReport: return NSLocalizedString(@"Report", @"Report");
		default: return @"";
	}
}

- (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
									  inputType:(MTAggregateFunctionInputType)inputType
									  groupType:(MTAggregateGroupByType)groupType
							  aggregateObjectID:(int64_t)aggregateObjectID  //RptqQueryField or MTAggregateFunctionInputTypeFormula
									groupNumber:(int32_t)groupNumber {
	RptqStoreContext * storeContext = self.storeContext;
	
	self.functionType = functionType;
	self.groupNumber = groupNumber;
	self.groupType = groupType;
	
	RptqObject *aggregateObject = [storeContext objectForEntity:NSStringFromClass([RptqDocumentElement class])
														 identifier:aggregateObjectID];
	if (!aggregateObject) {
		os_log_error(rptq_log, "Error loading aggregate object with ID: %lld", aggregateObjectID);
	}
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
	
	NSError * __autoreleasing saveError = nil;
	if (![storeContext save:&saveError]) {
		os_log_error(rptq_log, "Error saving managed object: %s", saveError.localizedDescription.UTF8String);
	}
	
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Function:               %hd\n", self.functionType];
	[description appendFormat:@"Group number:           %d\n", self.groupNumber];
	[description appendFormat:@"Group type:             %hd\n", self.groupType];
	[description appendFormat:@"*********"];
	return description;
}

@end
