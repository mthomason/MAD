//
//  RptqQueryPredicate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryPredicate_Extras_h
#define Reports_RptqQueryPredicate_Extras_h

#import "RptqQueryPredicate.h"
#import "RptqDocument+Extras.h"
#import "UITableViewControllerOpperators.h"
#import "MTProtocolCompare.h"

@interface RptqQueryPredicate (Extras) <MTProtocolCompare>

+ (id)createPredicateWithLeftField:(RptqQueryField *)leftField
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightField:(RptqQueryField *)rightField
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id)createPredicateWithLeftField:(RptqQueryField *)leftField
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightValue:(NSString *)rightUserValue
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id)createPredicateWithLeftValue:(NSString *)leftUserValue
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightValue:(NSString *)rightUserValue
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id)createPredicateWithLeftValue:(NSString *)leftUserValue
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightField:(RptqQueryField *)rightField
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)addPredicate:(RptqQueryPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
