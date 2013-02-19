//
//  UITableViewControllerPredicateFormat.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewController.h"
#import "UITableViewControllerSchemaAddPredicate.h"
#import "MTManagedDocumentReport.h"
#import "RptqQueryPredicate.h"

@class UITableViewControllerPredicateFormat;

@protocol AddPredicateDelegate <MUIViewControllerDelegate>
- (void)addPredicateDidCancel:(UITableViewControllerPredicateFormat *)controller;
- (void)addRptqPredicate:(RptqQueryPredicate *)predicate;
@end

@interface UITableViewControllerPredicateFormat : MTTableViewController
    <MUIViewControllerDelegate, UITableViewControllerSchemaAddPredicateDelegate>

@property (assign, nonatomic) IBOutlet id <AddPredicateDelegate> addPredicateDelegate;

- (IBAction)done:(id)sender;

@end