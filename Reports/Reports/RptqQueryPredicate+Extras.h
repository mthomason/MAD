//
//  RptqQueryPredicate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryPredicate_Extras_h
#define Reports_RptqQueryPredicate_Extras_h

typedef NS_ENUM(NSUInteger, MNSPredicateOperator) {
	MNSPredicateOperatorEqual = 0,
	MNSPredicateOperatorNotEqual,
	MNSPredicateOperatorGreaterThan,
	MNSPredicateOperatorGreaterThanOrEqualTo,
	MNSPredicateOperatorLessThan,
	MNSPredicateOperatorLessThanOrEqualTo
};

#define MNSPredicateOperatorReuseIds [NSArray arrayWithObjects: @"UITableViewCellPredicateOperatorEqual", @"UITableViewCellPredicateOperatorNotEqual", @"UITableViewCellPredicateOperatorGreaterThan", @"UITableViewCellPredicateOperatorGreaterThanOrEqualTo", @"UITableViewCellPredicateOperatorLessThan", @"UITableViewCellPredicateOperatorLessThanOrEqualTo", nil]

#define MNSPredicateOperatorNames [NSArray arrayWithObjects: NSLocalizedString(@"Equal", @"Equal"), NSLocalizedString(@"Not Equal", @"Not Equal"), NSLocalizedString(@"Greater Than", @"Greater Than"), NSLocalizedString(@"Greater Than or Equal To", @"Greater Than or Equal To"), NSLocalizedString(@"Less Than", @"Less Than"), NSLocalizedString(@"Less Than or Equal To", @"Less Than or Equal To"), nil]

#define MNSPredicateOperatorSymbols [NSArray arrayWithObjects: @"==", @"<>", @">", @">=", @"<", @"<=", nil]

#import "RptqQueryPredicate.h"
#import "RptqDocument+Extras.h"
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
+ (void)deletePredicateWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)deletePredicate:(RptqQueryPredicate *)predicate;
- (NSString *)symbolForComparson;

@end

#endif
