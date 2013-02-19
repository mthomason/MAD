//
//  UITableViewControllerOpperators.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@class UITableViewControllerOpperators;

@protocol UITableViewControllerOpperatorsDelegate
- (void)uITableViewControllerOpperatorsDidSelectOperator:(MNSPredicateOperator)operatorType;
@optional
- (void)uITableViewControllerOpperatorsDidFinish:(UITableViewControllerOpperators *)controller;
@end

@interface UITableViewControllerOpperators : UITableViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerOpperatorsDelegate> delegate;

@end