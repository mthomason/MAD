//
//  RptqQueryPredicate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqQueryPredicate_Extras_h
#define Reports_RptqQueryPredicate_Extras_h

#import <MAD/RptqQueryPredicate.h>
#import <MAD/MADPredicateOperator.h>

@class RptqDocument;

@interface RptqQueryPredicate (Extras)

+ (instancetype)newQueryPredicateFactoryWithLeftFieldID:(NSManagedObjectID *)leftField
									  comparsonOperator:(MADPredicateOperator)comparsonOperator
										andRightFieldID:(NSManagedObjectID *)rightField
								forManagedObjectContext:(NSManagedObjectContext *)context
												  error:(NSError * __autoreleasing *)error;

+ (instancetype)newQueryPredicateFactoryWithLeftFieldID:(NSManagedObjectID *)leftField
									  comparsonOperator:(MADPredicateOperator)comparsonOperator
										  andRightValue:(NSString *)rightUserValue
								forManagedObjectContext:(NSManagedObjectContext *)context
												  error:(NSError * __autoreleasing *)error;

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
									comparsonOperator:(MADPredicateOperator)comparsonOperator
										andRightValue:(NSString *)rightUserValue
							  forManagedObjectContext:(NSManagedObjectContext *)context
												error:(NSError * __autoreleasing *)error;

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
									comparsonOperator:(MADPredicateOperator)comparsonOperator
									  andRightFieldID:(NSManagedObjectID *)rightField
							  forManagedObjectContext:(NSManagedObjectContext *)context
												error:(NSError * __autoreleasing *)error;

+ (void)deletePredicate:(RptqQueryPredicate *)predicate;
- (NSString *)symbolForComparson;
- (NSString *)symbolForDisplay;
- (NSString *)rightFieldID;

@end

#endif
