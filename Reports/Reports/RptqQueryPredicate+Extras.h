//
//  RptqQueryPredicate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryPredicate.h"
#import "RptqDocument+Extras.h"
#import "UITableViewControllerOpperators.h"

@interface RptqQueryPredicate (Extras)

+ (id)createPredicateWithLeftField:(NSString *)leftField comparsonOperator:(MNSPredicateOperator)comparsonOperator andRightValue:(NSString *)rightValue forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)addPredicate:(RptqQueryPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end