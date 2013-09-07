//
//  MTGroupByViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RptqQueryGroup+Extras.h"
#import "MTActiveDocument.h"
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
