//
//  MTGroupByViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTGroupByViewController_h
#define Reports_MTGroupByViewController_h

#import "MADTableViewController.h"
#import <UIKit/UITableView.h>

#import <CoreData/NSFetchedResultsController.h>

#import <MAD/MADAggregateFunctionGroupByType.h>

extern NSString * const MTGroupByViewControllerIdentifier;

@protocol MADGroupByViewControllerDelegate;

@class MADocument;

@interface MTGroupByViewController : MADTableViewController
    <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

    @property (nonatomic, weak) id <MADGroupByViewControllerDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, assign, readonly) MTAggregateGroupByType aggregateGroupType;
    @property (nonatomic, assign, readonly) NSUInteger aggregateGroupNumber;

    - (void)selectGroupType:(MTAggregateGroupByType)groupByType
          withSectionNumber:(NSUInteger)sectionNumber;

@end

#endif
