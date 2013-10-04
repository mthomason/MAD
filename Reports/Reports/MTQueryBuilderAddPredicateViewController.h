//
//  UITableViewControllerSchemaAddPredicate.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RptqQueryPredicate+Extras.h"
#import "RptqQueryField+Extras.h"
#import "UITableViewControllerOpperators.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MTActiveDocument.h"
#import "MTViewControllerValueBasedOnField.h"
#import "MTTableViewController.h"

typedef NS_ENUM(NSUInteger, MNSPredicatePart) {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
};

@class MTQueryBuilderAddPredicateViewController;

@protocol MTQueryBuilderAddPredicateDelegate
- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MTQueryBuilderAddPredicateViewController : MTTableViewController
    <UITableViewDelegate,
        UITableViewControllerOpperatorsDelegate,
        MTQueryBuilderChooseFieldDelegate,
        MTViewControllerValueBasedOnFieldDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddPredicateDelegate, MTViewControllerProtocol> delegate;

@property (assign) MNSPredicatePart currentlyEditingPart;

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellLeftSide;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellRightSide;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellOperator;

@property (assign) MNSPredicateOperator predicateOperator;
@property (copy) NSString *leftValue;
@property (copy) NSString *rightValue;
@property (nonatomic, retain) RptqQueryField *fieldLeft;
@property (nonatomic, retain) RptqQueryField *fieldRight;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end