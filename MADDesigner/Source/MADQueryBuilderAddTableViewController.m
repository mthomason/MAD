//
//  UIViewControllerSchemaAddTable.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderAddTableViewController.h"
#import <MAD/RptqStoreContext.h>
#import <MADFoundation/madlog.h>

#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>
#import <MAD/MADModel.h>

#import <UIKit/UILabel.h>

@implementation MADQueryBuilderAddTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadTables)
												 name:MADNotificationQueryTableInsert
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadTables)
												 name:MADNotificationQueryTableDelete
											   object:nil];
	[self reloadTables];
}

- (void)reloadTables {
	// The store has no live query, so the rows are fetched and held; the table reloads
	// when the model posts its insert/delete notifications (MAD_STORE_PHASE_C.md §6).
	NSArray *tables = [self.managedObjectContext objectsForEntity:NSStringFromClass([RptqDatabaseSchemaTable class])];
	if (self.excludeResults.count > 0) {
		NSMutableSet *excluded = [NSMutableSet setWithArray:self.excludeResults];
		NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:tables.count];
		for (RptqDatabaseSchemaTable *table in tables) {
			if ([excluded containsObject:table.name]) continue;
			[filtered addObject:table];
		}
		tables = filtered;
	}
	tables = [tables sortedArrayUsingComparator:^NSComparisonResult(RptqDatabaseSchemaTable *a, RptqDatabaseSchemaTable *b) {
		return [(a.name ?: @"") compare:(b.name ?: @"")];
	}];
	self.results = tables;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
	[self.delegate viewControllerDidFinish: self];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"MADIdentifierTableViewCellAddTable";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	RptqDatabaseSchemaTable *result = self.results[(NSUInteger)indexPath.row];
	cell.textLabel.text = result.name.copy;
	return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	RptqDatabaseSchemaTable *result = self.results[(NSUInteger)indexPath.row];
	[self.delegate viewController: self addedQueryTableWithID: result.identifier];
}

@end
