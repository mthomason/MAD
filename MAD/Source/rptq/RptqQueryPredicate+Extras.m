//
//  RptqQueryPredicate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"

#import "RptqDataHelper.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSError.h>

#import <os/log.h>

static os_log_t rptq_log;

@implementation RptqQueryPredicate (Extras)

+ (void)load {
	if (self == [RptqQueryPredicate class]) {
		NSString *c = NSStringFromClass([RptqQueryPredicate class]);
		rptq_log = os_log_create("com.mad", c.UTF8String);
	}
}

+ (NSString *)domain {
	return @"mad.everydayapps.com.mad.rptq.predicate";
}

#pragma mark - Overrides

#pragma mark - Static

+ (instancetype)newQueryPredicateFactoryWithLeftFieldID:(int64_t)leftFieldID
									  comparsonOperator:(MADPredicateOperator)comparsonOperator
										andRightFieldID:(int64_t)rightFieldID
								forManagedObjectContext:(RptqStoreContext *)managedObjectContext
												  error:(NSError * __autoreleasing *)error {
	if (leftFieldID == nil || rightFieldID == nil) {
		os_log_error(rptq_log, "%s Missing field.", __PRETTY_FUNCTION__);
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain] code:2340 userInfo:@{
				NSLocalizedFailureReasonErrorKey: @"Missing field.",
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: Missing field.", NSStringFromClass([self class])]
			}];
		}
		return nil;
	}
	
	NSError *fetchError = nil;
	RptqQueryField *leftField = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:leftFieldID];
	if (fetchError) {
		os_log_error(rptq_log, "Failed to fetch left field: %{public}@", fetchError);
		if (error != NULL) *error = fetchError;
		return nil;
	}
	
	RptqQueryField *rightField = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:rightFieldID];
	if (fetchError) {
		os_log_error(rptq_log, "Failed to fetch right field: %{public}@", fetchError);
		if (error != NULL) *error = fetchError;
		return nil;
	}
	
	return [self createPredicateInContext:managedObjectContext
							withLeftField:leftField
							   rightField:rightField
								leftValue:nil
							   rightValue:nil
								 operator:comparsonOperator];
}

+ (instancetype)newQueryPredicateFactoryWithLeftFieldID:(int64_t)leftFieldID
									  comparsonOperator:(MADPredicateOperator)comparsonOperator
										  andRightValue:(NSString *)rightUserValue
								forManagedObjectContext:(RptqStoreContext *)managedObjectContext
												  error:(NSError * __autoreleasing *)error {
	if (leftFieldID == nil || rightUserValue == nil) {
		NSString *message = @"Missing field or value.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain] code:2341 userInfo:@{
				NSLocalizedFailureReasonErrorKey: @"Error",
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: Missing field.", NSStringFromClass([self class])]
			}];
		}
		return nil;
	}
	
	NSError *fetchError = nil;
	RptqQueryField *leftField = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:leftFieldID];
	if (fetchError) {
		os_log_error(rptq_log, "Failed to fetch left field: %{public}@", fetchError);
		if (error != NULL) *error = fetchError;
		return nil;
	}
	
	return [self createPredicateInContext:managedObjectContext
							withLeftField:leftField
							   rightField:nil
								leftValue:nil
							   rightValue:rightUserValue
								 operator:comparsonOperator];
}

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
									comparsonOperator:(MADPredicateOperator)comparsonOperator
										andRightValue:(NSString *)rightUserValue
							  forManagedObjectContext:(RptqStoreContext *)managedObjectContext
												error:(NSError * __autoreleasing *)error {
	if (leftUserValue == nil || rightUserValue == nil) {
		NSString *message = @"Missing value.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain] code:2342 userInfo:@{
				NSLocalizedFailureReasonErrorKey: @"Error",
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: Missing value.", NSStringFromClass([self class])]
			}];
		}
		return nil;
	}
	
	return [self createPredicateInContext:managedObjectContext
							withLeftField:nil
							   rightField:nil
								leftValue:leftUserValue
							   rightValue:rightUserValue
								 operator:comparsonOperator];
}

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
									comparsonOperator:(MADPredicateOperator)comparsonOperator
									  andRightFieldID:(int64_t)rightFieldID
							  forManagedObjectContext:(RptqStoreContext *)managedObjectContext
												error:(NSError * __autoreleasing *)error {
	if (leftUserValue == nil || rightFieldID == nil) {
		NSString *message = @"Missing value or field.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain] code:2343 userInfo:@{
				NSLocalizedFailureReasonErrorKey: @"Error",
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: Missing value or field.", NSStringFromClass([self class])]
			}];
		}
		return nil;
	}
	
	NSError *fetchError = nil;
	RptqQueryField *rightField = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:rightFieldID];
	if (fetchError) {
		os_log_error(rptq_log, "Failed to fetch right field: %{public}@", fetchError);
		if (error != NULL) *error = fetchError;
		return nil;
	}
	
	return [self createPredicateInContext:managedObjectContext
							withLeftField:nil
							   rightField:rightField
								leftValue:leftUserValue
							   rightValue:nil
								 operator:comparsonOperator];
}

#pragma mark -
#pragma mark Helper Methods

+ (instancetype)createPredicateInContext:(RptqStoreContext *)context
						   withLeftField:(RptqQueryField *)leftField
							  rightField:(RptqQueryField *)rightField
							   leftValue:(NSString *)leftValue
							  rightValue:(NSString *)rightValue
								operator:(MADPredicateOperator)operator {
	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:NSStringFromClass([self class]) identifier:0];
	predicate.hasLeftField = leftField;
	predicate.hasRightField = rightField;
	predicate.leftFieldID = leftValue ? leftValue.copy : nil;
	predicate.rightFieldID = rightValue ? rightValue.copy : nil;
	predicate.comparson = operator;
	return predicate;
}

#pragma mark - Public Methods

+ (void)deletePredicate:(RptqQueryPredicate *)predicate {
	if (predicate == nil) {
		os_log_error(rptq_log, "Attempted to delete nil predicate");
		return;
	}
	
	RptqStoreContext *context = predicate.storeContext;
	if (context == nil) {
		os_log_error(rptq_log, "Predicate has no managed object context");
		return;
	}
	
	[context deleteObject:predicate error:NULL];
}

#pragma mark -
#pragma mark Public

- (NSString *)symbolForDisplay {
	switch (self.comparson) {
		case 0:
			return @"==";
			break;
		case 1:
			return @"!=";
			break;
		case 2:
			return @">";
			break;
		case 3:
			return @">=";
			break;
		case 4:
			return @"<";
			break;
		case 5:
			return @"<=";
			break;
		default:
			return @"==";
			break;
	}
}

- (NSString *)symbolForComparson {
	switch (self.comparson) {
		case 0:
			return @"=";
			break;
		case 1:
			return @"<>";
			break;
		case 2:
			return @">";
			break;
		case 3:
			return @">=";
			break;
		case 4:
			return @"<";
			break;
		case 5:
			return @"<=";
			break;
		default:
			return @"==";
			break;
	}
}

- (NSString *)rightFieldID {
	return self.rigthFieldID;
}

- (void)setRightFieldID:(NSString *)rightFieldID {
	self.rigthFieldID = rightFieldID;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:         %lld\n", self.identifier];
	[description appendFormat:@"Sort:               %hd\n", self.comparson];
	[description appendFormat:@"Right field:        %@\n", self.hasRightField];
	[description appendFormat:@"Right pred:         %@\n", self.rightFieldID];
	[description appendFormat:@"Left field:         %@\n", self.hasLeftField];
	[description appendFormat:@"Left pred:          %@\n", self.leftFieldID];
	[description appendFormat:@"Query:              %@\n", self.inQuery];
	[description appendFormat:@"*********"];
	return description;
}

@end
