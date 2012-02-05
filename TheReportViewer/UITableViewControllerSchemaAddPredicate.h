//
//  UITableViewControllerSchemaAddPredicate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqQueryPredicate.h"
#import "UITableViewControllerOpperators.h"
#import "UITableViewControllerFieldOrCustomValue.h"

@class UITableViewControllerSchemaAddPredicate;

@protocol UITableViewControllerSchemaAddPredicateDelegate
- (void)uITableViewControllerSchemaAddPredicateDidFinish:(UITableViewControllerSchemaAddPredicate *)controller;
- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

@interface UITableViewControllerSchemaAddPredicate : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerFieldOrCustomValueDelegate,
        UITableViewControllerOpperatorsDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerSchemaAddPredicateDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellLeftSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellRightSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellOperator;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end