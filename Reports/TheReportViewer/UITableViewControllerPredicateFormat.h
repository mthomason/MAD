//
//  UITableViewControllerPredicateFormat.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIModalTableViewController.h"
#import "UITableViewControllerSchemaAddPredicate.h"
#import "UIManagedDocumentQuery.h"
#import "RptqQueryPredicate.h"

@class UITableViewControllerPredicateFormat;

@protocol AddPredicateDelegate
- (void)addPredicateDidCancel:(UITableViewControllerPredicateFormat *)controller;
- (void)addPredicate:(RptqQueryPredicate *)predicate;
- (void)addPredicateWithLeft:(NSString *)leftField comparson:(MNSPredicateOperator)comparsonOperator andRightValue:(NSString *)rightValue;
@end

@interface UITableViewControllerPredicateFormat : UIModalTableViewController
    <UITableViewControllerSchemaAddPredicateDelegate>

@property (assign, nonatomic) IBOutlet id <AddPredicateDelegate> addPredicateDelegate;
@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

@end