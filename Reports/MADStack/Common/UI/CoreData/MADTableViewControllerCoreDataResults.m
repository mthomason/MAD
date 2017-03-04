//
//  MADTableViewControllerCoreDataResults.m
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewControllerCoreDataResults.h"
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchedResultsController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@interface MADTableViewControllerCoreDataResults()
    <NSFetchedResultsControllerDelegate>
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
        NSString *oldEntityName = oldfrc.fetchRequest.entity.name.copy;
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldEntityName]) &&
            (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name.copy;
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
    return (NSInteger)(self.fetchedResultsController.sections[(NSUInteger)section]).numberOfObjects;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return (self.fetchedResultsController.sections[(NSUInteger)section]).name;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index {
	return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return (self.fetchedResultsController).sectionIndexTitles;
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

    NSArray <NSIndexPath *> *indexPaths, *newIndexPaths;
    NSIndexPath *indexPathCopy;
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        indexPathCopy = indexPath.copy;
        indexPaths = indexPath ?
                            [[NSArray alloc] initWithObjects:indexPathCopy, nil] :
                            [[NSArray alloc] init];

        indexPathCopy = newIndexPath.copy;
        newIndexPaths = newIndexPath ?
                            [[NSArray alloc] initWithObjects:indexPathCopy, nil] :
                            [[NSArray alloc] init];

        switch(type) {

            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths: newIndexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;
            
            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths: newIndexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates)
        [self.tableView endUpdates];
}

- (void)endSuspensionOfUpdatesDueToContextChanges {
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
}

- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(BOOL)suspend {
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    } else {
        [self performSelector:@selector(endSuspensionOfUpdatesDueToContextChanges) withObject:0 afterDelay:0];
    }
}

@end
