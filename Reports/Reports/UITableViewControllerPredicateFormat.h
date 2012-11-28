//
//  UITableViewControllerPredicateFormat.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUITableViewController.h"
#import "UITableViewControllerSchemaAddPredicate.h"
#import "UIManagedDocumentReport.h"
#import "RptqQueryPredicate.h"

@class UITableViewControllerPredicateFormat;

@protocol AddPredicateDelegate <MUIViewControllerDelegate>
- (void)addPredicateDidCancel:(UITableViewControllerPredicateFormat *)controller;
- (void)addPredicate:(RptqQueryPredicate *)predicate;
- (void)addPredicateWithLeft:(NSString *)leftField comparson:(MNSPredicateOperator)comparsonOperator andRightValue:(NSString *)rightValue;
@end

@interface UITableViewControllerPredicateFormat : MUITableViewController
    <MUIViewControllerDelegate>

@property (assign, nonatomic) IBOutlet id <AddPredicateDelegate> addPredicateDelegate;

@end