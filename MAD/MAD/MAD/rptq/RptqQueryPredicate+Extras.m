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

#import "RptqQueryPredicate+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <MADFoundation/MADErrorUserInfo.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"

#import "RptqDataHelper.h"
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

- (void)awakeFromInsert {
	[super awakeFromInsert];
	if (self.managedObjectContext.parentContext && self.identifier <= 0) {
		self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
											managedObjectContext:self.managedObjectContext];
	}
}

#pragma mark - Static

+ (instancetype)newQueryPredicateFactoryWithLeftFieldID:(NSManagedObjectID *)leftFieldID
									  comparsonOperator:(MADPredicateOperator)comparsonOperator
										andRightFieldID:(NSManagedObjectID *)rightFieldID
								forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
												  error:(NSError * __autoreleasing *)error {
	if (leftFieldID == nil || rightFieldID == nil) {
		NSString *message = @"Missing field.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [[[MADErrorUserInfo alloc] initWithTitle:@"Error" andMessage:message]
					  errorWithDomain:[self domain] code:2340];
		}
		return nil;
	}
	
	NSError *fetchError = nil;
	RptqQueryField *leftField = [managedObjectContext existingObjectWithID:leftFieldID error:&fetchError];
	if (fetchError) {
		os_log_error(rptq_log, "Failed to fetch left field: %{public}@", fetchError);
		if (error != NULL) *error = fetchError;
		return nil;
	}
	
	RptqQueryField *rightField = [managedObjectContext existingObjectWithID:rightFieldID error:&fetchError];
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

+ (instancetype)newQueryPredicateFactoryWithLeftFieldID:(NSManagedObjectID *)leftFieldID
									  comparsonOperator:(MADPredicateOperator)comparsonOperator
										  andRightValue:(NSString *)rightUserValue
								forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
												  error:(NSError * __autoreleasing *)error {
	if (leftFieldID == nil || rightUserValue == nil) {
		NSString *message = @"Missing field or value.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [[[MADErrorUserInfo alloc] initWithTitle:@"Error" andMessage:message]
					  errorWithDomain:[self domain] code:2341];
		}
		return nil;
	}
	
	NSError *fetchError = nil;
	RptqQueryField *leftField = [managedObjectContext existingObjectWithID:leftFieldID error:&fetchError];
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
							  forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
												error:(NSError * __autoreleasing *)error {
	if (leftUserValue == nil || rightUserValue == nil) {
		NSString *message = @"Missing value.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [[[MADErrorUserInfo alloc] initWithTitle:@"Error" andMessage:message]
					  errorWithDomain:[self domain] code:2342];
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
									  andRightFieldID:(NSManagedObjectID *)rightFieldID
							  forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
												error:(NSError * __autoreleasing *)error {
	if (leftUserValue == nil || rightFieldID == nil) {
		NSString *message = @"Missing value or field.";
		os_log_error(rptq_log, "%{public}@", message);
		if (error != NULL) {
			*error = [[[MADErrorUserInfo alloc] initWithTitle:@"Error" andMessage:message]
					  errorWithDomain:[self domain] code:2343];
		}
		return nil;
	}
	
	NSError *fetchError = nil;
	RptqQueryField *rightField = [managedObjectContext existingObjectWithID:rightFieldID error:&fetchError];
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

+ (instancetype)createPredicateInContext:(NSManagedObjectContext *)context
						   withLeftField:(RptqQueryField *)leftField
							  rightField:(RptqQueryField *)rightField
							   leftValue:(NSString *)leftValue
							  rightValue:(NSString *)rightValue
								operator:(MADPredicateOperator)operator {
	NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([self class])
											  inManagedObjectContext:context];
	RptqQueryPredicate *predicate = [[RptqQueryPredicate alloc] initWithEntity:entity
												insertIntoManagedObjectContext:context];
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
		os_log_debug(rptq_log, "Attempted to delete nil predicate");
		return;
	}
	
	NSManagedObjectContext *context = predicate.managedObjectContext;
	if (context == nil) {
		os_log_error(rptq_log, "Predicate has no managed object context");
		return;
	}
	
	[context deleteObject:predicate];
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
