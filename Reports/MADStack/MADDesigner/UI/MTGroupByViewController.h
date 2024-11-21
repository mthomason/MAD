//
//  MTGroupByViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTGroupByViewController_h
#define Reports_MTGroupByViewController_h

#import <UIKit/UITableViewController.h>
#import <UIKit/UITableView.h>

#import <CoreData/NSFetchedResultsController.h>

#import <MAD/MADAggregateFunctionGroupByType.h>

extern NSString * const MADGroupByViewControllerIdentifier;

@protocol MADGroupByViewControllerDelegate;

@class MADocument;

@interface MADGroupByViewController : UITableViewController
	<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

	@property (nonatomic, weak) id <MADGroupByViewControllerDelegate> delegate;
	@property (nonatomic, weak) MADocument *document;

	@property (nonatomic, assign, readonly) MTAggregateGroupByType aggregateGroupType;
	@property (nonatomic, assign, readonly) int32_t aggregateGroupNumber;

	- (void)selectGroupType:(MTAggregateGroupByType)groupByType
		  withSectionNumber:(int32_t)sectionNumber;

@end

#endif
