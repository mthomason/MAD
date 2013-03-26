//
//  MTGroupByViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTGroupByViewController.h"

NSString * const MTGroupByViewControllerIdentifier = @"MTGroupByViewControllerIdentifier";

@interface MTGroupByViewController ()

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerGroups;

@end

@implementation MTGroupByViewController

- (void)dealloc {
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"weight" ascending:YES];
        [request setSortDescriptors: @[sortDescriptor]];
        NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                              managedObjectContext: managedObjectContext
                                                                                sectionNameKeyPath: nil
                                                                                         cacheName: nil];
        [frc setDelegate:self];
        [self setFetchedResultsControllerGroups: frc];

        NSError *error = nil;
        [[self fetchedResultsControllerGroups] performFetch:&error];
        if (error != nil) {
            [error presentErrorToUser];
        }
        [frc release];
        frc = nil;
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

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
}

#pragma mark - Table View Datasource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[[self fetchedResultsControllerGroups] sections] count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsControllerGroups] sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *MyIdentifierUITableViewCellInstruction = @"MTGroupByTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
    RptqQueryGroup *queryGroup = [[self fetchedResultsControllerGroups] objectAtIndexPath:indexPath];
    NSString *textLabel = [NSString stringWithFormat:@"Section: %d", [[queryGroup weight] integerValue]];
    [[cell textLabel] setText:textLabel];
    // Configure the cell with data from the managed object.
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsControllerGroups] sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[self fetchedResultsControllerGroups] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [[self fetchedResultsControllerGroups] sectionForSectionIndexTitle:title atIndex:index];
}

@end
