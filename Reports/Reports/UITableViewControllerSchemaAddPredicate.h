//
//  UITableViewControllerSchemaAddPredicate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqQueryPredicate+Extras.h"
#import "UITableViewControllerOpperators.h"
#import "UIManagedDocumentReport.h"
#import "UITableViewControllerChooseField.h"
#import "UITableViewControllerEnterString.h"

typedef NS_ENUM(NSUInteger, MNSPredicatePart) {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
};

@class UITableViewControllerSchemaAddPredicate;

@protocol UITableViewControllerSchemaAddPredicateDelegate
- (void)uITableViewControllerSchemaAddPredicateDidFinish:(UITableViewControllerSchemaAddPredicate *)controller;
- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

@interface UITableViewControllerSchemaAddPredicate : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerOpperatorsDelegate,
        UITableViewControllerChooseFieldDelegate,
        UITableViewControllerEnterStringDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerSchemaAddPredicateDelegate> delegate;

@property (assign) MNSPredicatePart currentlyEditingPart;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellLeftSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellRightSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellOperator;

@property (assign) MNSPredicateOperator predicateOperator;
@property (copy) NSString *leftValue;
@property (copy) NSString *rightValue;
@property (nonatomic, retain) RptqField *fieldLeft;
@property (nonatomic, retain) RptqField *fieldRight;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end