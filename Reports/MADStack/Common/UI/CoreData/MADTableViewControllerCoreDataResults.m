//
//  MADTableViewControllerCoreDataResults.m
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2016 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewControllerCoreDataResults.h"

@interface MADTableViewControllerCoreDataResults()

    @property (nonatomic, assign) BOOL beganUpdates;

@end

@implementation MADTableViewControllerCoreDataResults

#pragma mark - Fetching

- (void)performFetch {
    if (self.fetchedResultsController) {
        NSError *error = nil;
        [self.fetchedResultsController performFetch:&error];
    }
    [self.tableView reloadData];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc {
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            [self performFetch];
        } else {
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[self.fetchedResultsController.sections[(NSUInteger)section] numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self.fetchedResultsController.sections[(NSUInteger)section] name];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.fetchedResultsController sectionIndexTitles];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableView beginUpdates];
        [self setBeganUpdates: YES];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {

        switch(type) {
            case NSFetchedResultsChangeInsert: {
                NSIndexSet *sections = [NSIndexSet indexSetWithIndex:sectionIndex];
                [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
            case NSFetchedResultsChangeDelete: {
                NSIndexSet *sections = [NSIndexSet indexSetWithIndex:sectionIndex];
                [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
            case NSFetchedResultsChangeMove:
            case NSFetchedResultsChangeUpdate:
                break;
                
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {

    NSArray <NSIndexPath *> *indexPaths = indexPath ? @[indexPath] : nil;
    NSArray <NSIndexPath *> *newIndexPaths = newIndexPath ? @[newIndexPath] : nil;
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch(type) {

            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                break;
            
            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ([self beganUpdates])
        [self.tableView endUpdates];
}

- (void)endSuspensionOfUpdatesDueToContextChanges {
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = false;
}

- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(bool)suspend {
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = true;
    } else {
        [self performSelector:@selector(endSuspensionOfUpdatesDueToContextChanges) withObject:0 afterDelay:0];
    }
}

@end
