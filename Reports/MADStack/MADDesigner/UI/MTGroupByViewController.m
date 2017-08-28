//
//  MTGroupByViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTGroupByViewController.h"
#import "MADGroupByViewControllerDelegate.h"

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UITableView.h>
#import <UIKit/UICollectionView.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

#import <MADCocoaExtensions/NSError+Constructors.h>

#import <MAD/MADocument.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>

#import "MADLabelTitle.h"

NSString * const MADGroupByViewControllerIdentifier = @"MADGroupByViewControllerIdentifier";

@interface MADGroupByViewController ()

    @property (nonatomic, strong) NSFetchedResultsController *fetchedResultsControllerGroups;

@end

@implementation MADGroupByViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;
    
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Group By",
                                       @"Title of form that allows you to choose an item to group other items by...");
    self.navigationItem.titleView = titleView;

    NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
    NSSortDescriptor *sort;
    sort = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(weight))
                                         ascending:YES];
    NSArray <NSSortDescriptor *> *sortDescriptors = [[NSArray alloc] initWithObjects:sort, nil];
    request.sortDescriptors = sortDescriptors;
    
    NSFetchedResultsController *frc;
    frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                              managedObjectContext: self.document.managedObjectContext
                                                sectionNameKeyPath: nil
                                                         cacheName: nil];
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
    return (NSInteger)self.fetchedResultsControllerGroups.sections.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo;
    sectionInfo = _fetchedResultsControllerGroups.sections[(NSUInteger)section];
    NSInteger numberOfRows = ((NSInteger)sectionInfo.numberOfObjects) + 2;
    return numberOfRows;
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
            RptqQueryGroup *queryGroup = [self.fetchedResultsControllerGroups objectAtIndexPath:[self updatedIndexPath:indexPath]];
            NSString *fieldNameNice = [queryGroup fieldNameNice];
            NSInteger groupLevel = [queryGroup location];
            NSString *textLabel = fieldNameNice == nil ?
                    [NSString stringWithFormat:@"Group %ld", (long)groupLevel] :
                    [NSString stringWithFormat:@"Group %ld (%@)", (long)groupLevel, fieldNameNice];
            (cell.textLabel).text = textLabel;
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
    id <NSFetchedResultsSectionInfo> sectionInfo =
                                _fetchedResultsControllerGroups.sections[(NSUInteger)section];
    NSString *title = sectionInfo.name.copy;
    return title;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return _fetchedResultsControllerGroups.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title
                                                                        atIndex:(NSInteger)index {
    return [_fetchedResultsControllerGroups sectionForSectionIndexTitle:title atIndex:index];
}

@end
