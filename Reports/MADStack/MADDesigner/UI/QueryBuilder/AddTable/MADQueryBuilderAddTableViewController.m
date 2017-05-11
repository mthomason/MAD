//
//  UIViewControllerSchemaAddTable.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderAddTableViewController.h"
#import <CoreData/NSFetchedResultsController.h>
#import <UIKit/UILabel.h>
#import <MAD/RptqDatabaseSchemaTable.h>

@implementation MADQueryBuilderAddTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (NSFetchedResultsController *)fetchedResultsController {
    NSManagedObjectContext *managedObjectContext;
    if (_fetchedResultsController == nil && ((managedObjectContext = _managedObjectContext)) != nil) {
        NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
        NSFetchRequest *request;
        NSSortDescriptor *sort;
        NSString *keyPathName;
        request = [NSFetchRequest fetchRequestWithEntityName: entityName];
        keyPathName = NSStringFromSelector(@selector(name));
        
        sort = [NSSortDescriptor sortDescriptorWithKey: keyPathName
                                             ascending: YES];
        
        request.sortDescriptors = [[NSArray alloc] initWithObjects:sort, nil];
        
        NSFetchedResultsController *fetchedResultsController;
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                  managedObjectContext: managedObjectContext
                                                    sectionNameKeyPath: nil
                                                             cacheName: nil];
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Error: (%@, %@)", error.localizedDescription, error.localizedFailureReason);
        }
        
        _fetchedResultsController = fetchedResultsController;
    }
    return _fetchedResultsController;
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
    RptqDatabaseSchemaTable *table = [self.fetchedResultsController objectAtIndexPath: indexPath];
    cell.textLabel.text = table.name.copy;
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s (%ld, %ld)", __PRETTY_FUNCTION__, indexPath.section, indexPath.row);

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqDatabaseSchemaTable *tablea = [self.fetchedResultsController objectAtIndexPath: indexPath];
    [self.delegate viewController:self addedTableWithID: tablea.objectID];
}

@end
