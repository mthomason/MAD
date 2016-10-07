//
//  MTQueryBuilderPredicateFormatViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderPredicateFormatViewController_h
#define Reports_MTQueryBuilderPredicateFormatViewController_h

#import "MTQueryBuilderAddPredicateViewController.h"
#import "MUIViewControllerDelegate.h"
#import "MADQueryBuilderAddPredicateDelegate.h"

@class MTQueryBuilderPredicateFormatViewController;

@protocol MTQueryBuilderPredicateFormatDelegate <MTViewControllerProtocol>
    - (void)addQueryPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MTQueryBuilderPredicateFormatViewController : UITableViewController
    <MTViewControllerProtocol,
        MADQueryAddPredicateDelegate>

@property (nonatomic, weak) id <MTQueryBuilderPredicateFormatDelegate, MTViewControllerProtocol> delegate;
@property (nonatomic, weak) MADocument *document;

- (IBAction)done:(id)sender;

@end

#endif
