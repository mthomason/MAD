//
//  UITableViewControllerPredicateFormat.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewController.h"
#import "MTQueryBuilderAddPredicateViewController.h"

@class MTQueryBuilderPredicateFormatViewController;

@protocol MTQueryBuilderPredicateFormatDelegate <MTViewControllerProtocol>
- (void)addQueryPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MTQueryBuilderPredicateFormatViewController : MTTableViewController
    <MTViewControllerProtocol, MTQueryBuilderAddPredicateDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderPredicateFormatDelegate, MTViewControllerProtocol> delegate;
//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;

- (IBAction)done:(id)sender;

@end
