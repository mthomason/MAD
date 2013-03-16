//
//  UITableViewControllerPredicateFormat.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewController.h"
#import "MTQueryBuilderAddPredicateViewController.h"
#import "MTManagedDocumentReport.h"
#import "RptqQueryPredicate.h"

@class MTQueryBuilderPredicateFormatViewController;

@protocol MTQueryBuilderPredicateFormatDelegate <MUIViewControllerProtocol>
- (void)addPredicateDidCancel:(MTQueryBuilderPredicateFormatViewController *)controller;
- (void)addRptqPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MTQueryBuilderPredicateFormatViewController : MTTableViewController
    <MUIViewControllerProtocol, MTQueryBuilderAddPredicateDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderPredicateFormatDelegate> addPredicateDelegate;

- (IBAction)done:(id)sender;

@end
