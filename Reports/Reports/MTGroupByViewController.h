//
//  MTGroupByViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTGroupByViewController_h
#define Reports_MTGroupByViewController_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RptqDocumentObjectAggregate+Extras.h"

extern NSString * const MTGroupByViewControllerIdentifier;

@protocol MTGroupByViewControllerDelegate
- (void)didSelectGroupByPage;
- (void)didSelectGroupByReport;
- (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber;
@end

@interface MTGroupByViewController : UITableViewController
    <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, assign) id <MTGroupByViewControllerDelegate> delegate;

@property (nonatomic, assign, readonly) MTAggregateGroupByType aggregateGroupType;
@property (nonatomic, assign, readonly) NSUInteger aggregateGroupNumber;

- (void)selectGroupType:(MTAggregateGroupByType)groupByType withSectionNumber:(NSInteger)sectionNumber;

@end

#endif
