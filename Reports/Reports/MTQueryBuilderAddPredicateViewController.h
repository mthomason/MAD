//
//  UITableViewControllerSchemaAddPredicate.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqQueryPredicate+Extras.h"
#import "UITableViewControllerOpperators.h"
#import "MTManagedDocumentReport.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "UITableViewControllerEnterString.h"
#import "MTActiveDocument.h"

typedef NS_ENUM(NSUInteger, MNSPredicatePart) {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
};

@class MTQueryBuilderAddPredicateViewController;

@protocol MTQueryBuilderAddPredicateDelegate
- (void)uITableViewControllerSchemaAddPredicateDidFinish:(MTQueryBuilderAddPredicateViewController *)controller;
- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MTQueryBuilderAddPredicateViewController : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerOpperatorsDelegate,
        MTQueryBuilderChooseFieldDelegate,
        UITableViewControllerEnterStringDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddPredicateDelegate> delegate;

@property (assign) MNSPredicatePart currentlyEditingPart;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellLeftSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellRightSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellOperator;

@property (assign) MNSPredicateOperator predicateOperator;
@property (copy) NSString *leftValue;
@property (copy) NSString *rightValue;
@property (nonatomic, retain) RptqDatabaseSchemaField *fieldLeft;
@property (nonatomic, retain) RptqDatabaseSchemaField *fieldRight;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end