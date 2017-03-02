//
//  RptqQueryPredicate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryPredicate_Extras_h
#define Reports_RptqQueryPredicate_Extras_h

#import "RptqQueryPredicate.h"
#import "MADPredicateOperator.h"

@class RptqDocument;

@interface RptqQueryPredicate (Extras)

+ (instancetype)newQueryPredicateFactoryWithLeftField:(RptqQueryField *)leftField
                                    comparsonOperator:(MADPredicateOperator)comparsonOperator
                                        andRightField:(RptqQueryField *)rightField
                              forManagedObjectContext:(NSManagedObjectContext *)context;

+ (instancetype)newQueryPredicateFactoryWithLeftField:(RptqQueryField *)leftField
                                    comparsonOperator:(MADPredicateOperator)comparsonOperator
                                        andRightValue:(NSString *)rightUserValue
                              forManagedObjectContext:(NSManagedObjectContext *)context;

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
                                    comparsonOperator:(MADPredicateOperator)comparsonOperator
                                        andRightValue:(NSString *)rightUserValue
                              forManagedObjectContext:(NSManagedObjectContext *)context;

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
                                    comparsonOperator:(MADPredicateOperator)comparsonOperator
                                        andRightField:(RptqQueryField *)rightField
                              forManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)deletePredicate:(RptqQueryPredicate *)predicate;
- (NSString *)symbolForComparson;
- (NSString *)symbolForDisplay;
- (NSString *)rightFieldID;

@end

#endif
