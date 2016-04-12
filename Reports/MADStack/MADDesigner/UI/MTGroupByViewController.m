//
//  MTGroupByViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTGroupByViewController.h"
#import "MADNavigationBarTitleView.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MADocument.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MADCocoaExtensions/NSError+Constructors.h>

NSString * const MTGroupByViewControllerIdentifier = @"MTGroupByViewControllerIdentifier";

@interface MTGroupByViewController ()

    @property (nonatomic, strong) NSFetchedResultsController *fetchedResultsControllerGroups;

@end

@implementation MTGroupByViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Group By", @"Title of form that allows you to choose an item to group other items by...");
    self.navigationItem.titleView = titleView;

    NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
    NSString *weight = NSStringFromSelector(@selector(weight));
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request managedObjectContext: self.document.managedObjectContext
                                                                            sectionNameKeyPath: nil cacheName: nil];
    frc.delegate = self;
    self.fetchedResultsControllerGroups = frc;
    
    NSError *error = nil;
    [self.fetchedResultsControllerGroups performFetch:&error];
    if (error != nil) {
        [NSError presentError: error onViewController: self completion: NULL];
    }
    frc = nil;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSIndexPath *)updatedIndexPath:(NSIndexPath *)indexPath {
    return [NSIndexPath indexPathForRow:indexPath.row - 2 inSection:indexPath.section];
}

- (void)setGroupType:(MTAggregateGroupByType)groupType {
    _aggregateGroupNumber = 0;
    _aggregateGroupType = groupType;
}

- (void)setGroupTypeSectionWithNumber:(NSUInteger)sectionNumber {
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
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    id <MTGroupByViewControllerDelegate> delegate = self.delegate;
    switch (indexPath.row) {
        
        case 0:
            [self setGroupType:MTAggregateGroupByTypePage];
            if (delegate != nil) {
                [delegate didSelectGroupByPage];
            }
            break;
        
        case 1:
            [self setGroupType:MTAggregateGroupByTypeReport];
            if (delegate != nil) {
                [delegate didSelectGroupByReport];
            }
            break;
        
        default:
            self.groupType = MTAggregateGroupByTypeSection;
            self.groupTypeSectionWithNumber = (NSUInteger)indexPath.row - 2;
            if (delegate != nil) {
                [delegate didSelectGroupBySectionNumber: (NSUInteger)indexPath.row - 2];
            }
            break;
    }
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
            
        default:
            [self setGroupType:MTAggregateGroupByTypeSection];
            [self setGroupTypeSectionWithNumber: (NSUInteger)indexPath.row - 2];
            break;
    }
}

- (void)selectGroupType:(MTAggregateGroupByType)groupByType withSectionNumber:(NSUInteger)sectionNumber {
    _aggregateGroupType = groupByType;
    _aggregateGroupNumber = sectionNumber;
}

- (void)selectGroupType:(MTAggregateGroupByType)groupByType {
    [self selectGroupType:groupByType withSectionNumber:0];
}

#pragma mark - Table View Datasource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.fetchedResultsControllerGroups.sections.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsControllerGroups.sections[(NSUInteger)section];
    return (NSInteger)sectionInfo.numberOfObjects + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *tableViewCellIdentifier = @"MTGroupByTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: tableViewCellIdentifier];

    switch (indexPath.row) {

        case 0:
            [[cell textLabel] setText:[RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage]];
            if (self.aggregateGroupType == MTAggregateGroupByTypePage) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            break;
        
        case 1:
            [[cell textLabel] setText:[RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport]];
            if (self.aggregateGroupType == MTAggregateGroupByTypeReport) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            break;
        
        default: {
            RptqQueryGroup *queryGroup = [[self fetchedResultsControllerGroups] objectAtIndexPath:[self updatedIndexPath:indexPath]];
            NSString *fieldNameNice = [queryGroup fieldNameNice];
            NSInteger groupLevel = [queryGroup location];
            NSString *textLabel = fieldNameNice == nil ?
                    [NSString stringWithFormat:@"Group %ld", (long)groupLevel] :
                    [NSString stringWithFormat:@"Group %ld (%@)", (long)groupLevel, fieldNameNice];
            [[cell textLabel] setText:textLabel];
            if (self.aggregateGroupType == MTAggregateGroupByTypeSection && (NSUInteger)indexPath.row - 2 == self.aggregateGroupNumber) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            break;
        }

    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsControllerGroups.sections[(NSUInteger)section];
    return sectionInfo.name;
}

- (NSArray <NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.fetchedResultsControllerGroups.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsControllerGroups sectionForSectionIndexTitle:title atIndex:index];
}

@end
