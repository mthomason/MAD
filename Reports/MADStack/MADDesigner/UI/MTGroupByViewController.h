//
//  MTGroupByViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTGroupByViewController_h
#define Reports_MTGroupByViewController_h

#import "MADViewController.h"
#import <CoreData/NSFetchedResultsController.h>
#import <MAD/RptqDocumentObjectAggregate.h>
#import <MAD/RptqDocumentObjectAggregate+Extras.h>

extern NSString * const MTGroupByViewControllerIdentifier;

@class MADocument;

@protocol MTGroupByViewControllerDelegate

    - (void)didSelectGroupByPage;
    - (void)didSelectGroupByReport;
    - (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber;

@end

@interface MTGroupByViewController : MADTableViewController
    <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

    @property (nonatomic, weak) id <MTGroupByViewControllerDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, assign, readonly) MTAggregateGroupByType aggregateGroupType;
    @property (nonatomic, assign, readonly) NSUInteger aggregateGroupNumber;

    - (void)selectGroupType:(MTAggregateGroupByType)groupByType withSectionNumber:(NSInteger)sectionNumber;

@end

#endif
