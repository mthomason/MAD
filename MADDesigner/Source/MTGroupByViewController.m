//
//  MTGroupByViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTGroupByViewController.h"
#import "MADGroupByViewControllerDelegate.h"

#import <UIKit/UITableView.h>
#import <UIKit/UICollectionView.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqObject.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>

NSString * const MADGroupByViewControllerIdentifier = @"MADGroupByViewControllerIdentifier";

@interface MADGroupByViewController ()
@property (nonatomic, strong) NSArray <RptqQueryGroup *> *results;
@end

@implementation MADGroupByViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.navigationItem.leftItemsSupplementBackButton = YES;
	self.navigationItem.hidesBackButton = NO;

	MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
	titleView.text = NSLocalizedString(@"Group By", @"Title of form that allows you to choose an item to group other items by...");
	self.navigationItem.titleView = titleView;

	// The group list was an NSFetchedResultsController; the store has no live query,
	// so the rows are fetched once, scoped to the open query, and sorted by hand.
	// The list cannot change while this picker is on screen.
	int64_t queryID = [self.document activeDocumentModel].defaultDatabase.defaultQuery.identifier;
	NSArray *groups = [self.document.storeContext objectsForEntity:NSStringFromClass([RptqQueryGroup class])];
	groups = [groups filteredArrayUsingPredicate:
			  [NSPredicate predicateWithFormat:@"inQuery.identifier == %lld", queryID]];
	self.results = [groups sortedArrayUsingDescriptors:
					@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(weight)) ascending:YES]]];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)setGroupType:(MTAggregateGroupByType)groupType {
	_aggregateGroupNumber = 0;
	_aggregateGroupType = groupType;
}

- (void)setGroupTypeSectionWithNumber:(int32_t)sectionNumber {
	_aggregateGroupNumber = sectionNumber;
	_aggregateGroupType = MTAggregateGroupByTypeSection;
}

#pragma mark - View lifecycle



- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

#pragma mark - Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSInteger rowCount = [tableView numberOfRowsInSection:indexPath.section];

	for (NSInteger i = 0; i < rowCount; i++) {
		NSIndexPath *cellPath = [NSIndexPath indexPathForItem:i inSection:indexPath.section];
		UITableViewCell *tableViewCell = [self.tableView cellForRowAtIndexPath:cellPath];
		tableViewCell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	id <MADGroupByViewControllerDelegate> delegate = _delegate;
	if (delegate == nil) goto SkipDisplay;
	switch (indexPath.row) {
		
		case 0:
			[self setGroupType:MTAggregateGroupByTypePage];
			[delegate didSelectGroupByPage];
			break;
		
		case 1:
			[self setGroupType:MTAggregateGroupByTypeReport];
			[delegate didSelectGroupByReport];
			break;
		
		default: {
			int32_t groupNumber = (int32_t)indexPath.row - 2;
			[self setGroupType:MTAggregateGroupByTypeSection];
			[self setGroupTypeSectionWithNumber: groupNumber];
			[delegate didSelectGroupBySectionNumber: groupNumber];
			break;
		}
			
	}
	SkipDisplay:;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	UITableViewCell *cell = sender;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	switch (indexPath.row) {
			
		case 0:
			[self setGroupType:MTAggregateGroupByTypePage];
			break;
			
		case 1:
			[self setGroupType:MTAggregateGroupByTypeReport];
			break;
			
		default: {
			[self setGroupType:MTAggregateGroupByTypeSection];
			[self setGroupTypeSectionWithNumber: (int32_t)indexPath.row - 2];
			break;
		}
			
	}
	
}

- (void)selectGroupType:(MTAggregateGroupByType)groupByType
	  withSectionNumber:(int32_t)sectionNumber {
	_aggregateGroupType = groupByType;
	_aggregateGroupNumber = sectionNumber;
}

- (void)selectGroupType:(MTAggregateGroupByType)groupByType {
	[self selectGroupType:groupByType withSectionNumber:0];
}

#pragma mark - Table View Datasource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.results.count + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *tableViewCellIdentifier = @"MTGroupByTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: tableViewCellIdentifier];

	switch (indexPath.row) {

		case 0:
			(cell.textLabel).text = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
			if (self.aggregateGroupType == MTAggregateGroupByTypePage) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			break;
		
		case 1:
			(cell.textLabel).text = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
			if (self.aggregateGroupType == MTAggregateGroupByTypeReport) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			break;
		
		default: {
			RptqQueryGroup *queryGroup = self.results[(NSUInteger)indexPath.row - 2];
			NSString *fieldNameNice = [queryGroup fieldNameNice];
			NSInteger groupLevel = [queryGroup location];
			(cell.textLabel).text = fieldNameNice == nil ?
					[NSString stringWithFormat:@"Group %ld", (long)groupLevel] :
					[NSString stringWithFormat:@"Group %ld (%@)", (long)groupLevel, fieldNameNice];
			if (_aggregateGroupType == MTAggregateGroupByTypeSection &&
										indexPath.row - 2 == (NSInteger)_aggregateGroupNumber) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			break;
		}

	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title
																		atIndex:(NSInteger)index {
	return 0;
}

@end
