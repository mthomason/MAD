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
#import "madlog.h"

#import <MAD/RptqDatabaseSchemaTable+Extras.h>

#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSExpressionDescription.h>
#import <UIKit/UILabel.h>

@implementation MADQueryBuilderAddTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (NSFetchedResultsController *)fetchedResultsController {
	NSManagedObjectContext *managedObjectContext;
	if (_fetchedResultsController == nil &&
		((managedObjectContext = _managedObjectContext)) != nil) {
		
		NSFetchRequest *request = [RptqDatabaseSchemaTable fetchRequestSortTables];
		NSFetchedResultsController *controller;
		controller = [[NSFetchedResultsController alloc] initWithFetchRequest: request
														 managedObjectContext: managedObjectContext
														   sectionNameKeyPath: nil
																	cacheName: nil];
		
		NSError *error = nil;
		[controller performFetch:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "Error: %@ (%@)", error.localizedDescription, error.localizedFailureReason);
		}
		controller.delegate = self;
		_fetchedResultsController = controller;
	}
	return _fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
	[self.delegate viewControllerDidFinish: self];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"MADIdentifierTableViewCellAddTable";
	static NSString *keyName;
	if (keyName == nil) keyName = NSStringFromSelector(@selector(name));
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	RptqDatabaseSchemaTable *result = [self.fetchedResultsController objectAtIndexPath: indexPath];
	NSString *name = result.name;
	cell.textLabel.text = name.copy;
	return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSManagedObject *result = [self.fetchedResultsController objectAtIndexPath: indexPath];
	[self.delegate viewController: self addedQueryTableWithID: result.objectID];
}

@end
