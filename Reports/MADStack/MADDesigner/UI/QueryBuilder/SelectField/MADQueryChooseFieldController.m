//
//  MADQueryChooseFieldController.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryChooseFieldController.h"

#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSExpressionDescription.h>

#import <UIKit/UIAccessibility.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UILabel.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MAD/MADSchemaFieldSelectorModel.h>

#import <MAD/RptqQueryTable.h>

#import <MAD/RptqDocument.h>

#import <MAD/RptqDatabase.h>

#import <MAD/RptqDatabaseSchemaTable+Extras.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/MADocument.h>

#import "MADQueryChooseFieldProtocol.h"

#import "MADDatabaseTableSectionHeaderView.h"

//#import "MADNavigationItemTitleView.h"


typedef NSArray <MADSchemaFieldSelectorModel *> MADSectionInfoArray;

static inline double heightForSectionInfo(NSUInteger numTables, NSUInteger numFields);
static inline  double heightForSectionInfo(NSUInteger numTables, NSUInteger numFields) {
    return ((numTables * MADHeaderHeight) + (numFields * MAD_44));
}

static inline double PreferredContentHeightForUpdate(NSUInteger, NSUInteger);
static inline double PreferredContentHeightForUpdate(NSUInteger count, NSUInteger index) {
    return heightForSectionInfo(count, index);
}

static inline CGSize PreferredContentSizeForUpdate(NSUInteger, NSUInteger);
static inline CGSize PreferredContentSizeForUpdate(NSUInteger count, NSUInteger index) {
    return CGSizeMake(MADFloat_320,
                      (CGFloat)PreferredContentHeightForUpdate(count, index));
}

@interface MADQueryChooseFieldController ()

    @property (nonatomic, strong) NSMutableArray <MADSchemaFieldSelectorModel *> *sectionInfoArray;
    @property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation MADQueryChooseFieldController {
    NSInteger _openSectionIndex;
}

@synthesize unwindViewController;

+ (instancetype)newQueryBuilderChooseFieldViewController {
    NSString * ObjectSelector = @"MADDesignerObjectSelector";
    NSString * MainIdentifier = @"UITableViewControllerChooseFieldDataObject";
    id bundle, viewController, storyboard;
    bundle = [NSBundle mainBundle];
    storyboard = [UIStoryboard storyboardWithName: ObjectSelector bundle: bundle];
    viewController = [storyboard instantiateViewControllerWithIdentifier: MainIdentifier];
    return viewController;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

#pragma mark Initialization and configuration

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *reuseID = NSStringFromClass([MADDatabaseTableSectionHeaderView class]);
    [self.tableView registerClass:[MADDatabaseTableSectionHeaderView class] forHeaderFooterViewReuseIdentifier:reuseID];
    
    _openSectionIndex = NSNotFound;
    
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated]; 
    self.tableView.sectionHeaderHeight = MADFloatHeaderHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.isAccessibilityElement = NO;
    [self updateSize];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark -
#pragma mark Storyboard

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer"] ||
        [segue.identifier isEqualToString:@"MTSegueAggregateFieldSave"] ||
        [segue.identifier isEqualToString:@"MTIdentifierSegueEditFieldExit"]) {
        
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell: cell];
        NSManagedObjectID *fieldID = [self queryFieldObjectIDForIndexPath:indexPath];
        self.queryFieldID = fieldID.copy;
    
    }
}

#pragma mark -
#pragma mark Lazy load

- (NSMutableArray <MADSchemaFieldSelectorModel *> *)sectionInfoArray {
    if (_sectionInfoArray == nil) {
        NSMutableArray <MADSchemaFieldSelectorModel *> *infoArray;
        NSUInteger sectionCount = self.resultsController.sections.count;
        infoArray = [[NSMutableArray alloc] initWithCapacity:sectionCount];
        MADSchemaFieldSelectorModel *sectionInfo;
        for (NSUInteger i = 0; i<sectionCount; i++) {
            sectionInfo = [[MADSchemaFieldSelectorModel alloc] init];
            [infoArray addObject:sectionInfo];
        }
        _sectionInfoArray = infoArray;
    }
    return _sectionInfoArray;
}

- (NSFetchedResultsController *)resultsController {
    if (_resultsController == nil) {
        
        NSString *keyInQueryTableAlias = [RptqQueryField keyInQueryTableAlias];
        NSString *keySchemaFieldName = [RptqQueryField keySchemaFieldName];
        
        NSSortDescriptor *sortTable, *sortField;
        sortTable = [NSSortDescriptor sortDescriptorWithKey: keyInQueryTableAlias
                                                  ascending: YES];
        
        sortField = [NSSortDescriptor sortDescriptorWithKey: keySchemaFieldName
                                                  ascending: YES];
        
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortTable, sortField, nil];
        
        NSFetchRequest *request;
        request = [RptqQueryField fetchRequestFields:1];
        request.sortDescriptors = sortDescriptors;
        
        NSFetchedResultsController *resultsController;
        resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                managedObjectContext: self.document.managedObjectContext
                                                                  sectionNameKeyPath: keyInQueryTableAlias
                                                                           cacheName: nil];
        
        NSError *error = nil;
        if (![resultsController performFetch: &error]) {
            NSLog(@"requestError: %@\n%@", error.localizedDescription, error.localizedFailureReason);
        }
        
        _resultsController = resultsController;
    }
    return _resultsController;
}

#pragma mark -
#pragma mark Table view datasource and delegate

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    MADSchemaFieldSelectorModel *state = self.sectionInfoArray[(NSUInteger)section];
    id <NSFetchedResultsSectionInfo> data = self.resultsController.sections[(NSUInteger)section];
    return state.open ? (NSInteger)data.numberOfObjects : 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return (NSInteger)self.resultsController.sections.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    MADSchemaFieldSelectorModel *state = self.sectionInfoArray[(NSUInteger)section];
    id <NSFetchedResultsSectionInfo> data = self.resultsController.sections[(NSUInteger)section];
    return state.open ? (NSInteger)data.numberOfObjects : 0;
}


- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *identifier = @"UITableViewCellFieldWithType";
    static NSString *keyFieldName, *keyDataType;
    if (keyFieldName == nil) keyFieldName = [RptqQueryField keyFieldName];
    if (keyDataType == nil) keyDataType = [RptqQueryField keySchemaFieldDataType];
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    cell.isAccessibilityElement = YES;
    cell.accessibilityTraits = cell.accessibilityTraits | UIAccessibilityTraitButton;
    
    if (self.resultsController.sections.count >= (NSUInteger)indexPath.section) {
        
        int16_t dataType;
        id <NSFetchedResultsSectionInfo> secinfo = self.resultsController.sections[(NSUInteger)indexPath.section];
        NSDictionary *object = secinfo.objects[(NSUInteger)indexPath.row];
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)object[keyDataType], kCFNumberSInt16Type, &dataType);
        
        NSString *name = object[keyFieldName];
        NSString *dataTypeDisplay = [RptqDatabaseSchemaField dataTypeDisplay:dataType];
        
        cell.textLabel.text = name.copy;
        cell.detailTextLabel.text = dataTypeDisplay.lowercaseString;
        cell.accessibilityLabel = name.copy;
        cell.accessibilityHint = NSLocalizedString(@"Selects field.", @"Selects field.");
    }

    return cell;
}

- (UIView *)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    
    static NSString *identifier;
    if (identifier == nil) identifier = NSStringFromClass([MADDatabaseTableSectionHeaderView class]);
    MADDatabaseTableSectionHeaderView *vsht = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y,
                             self.tableView.bounds.size.width, MADFloatHeaderHeight);
    
    id <NSFetchedResultsSectionInfo> secinfo = self.resultsController.sections[(NSUInteger)section];
    [vsht setSection:section];
    [vsht setDelegate:self];
    [vsht setTitle:secinfo.name];
    [vsht setFrame:rect];
    return vsht;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return MADFloatHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MAD_44;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSManagedObjectID *fieldID = [self queryFieldObjectIDForIndexPath:indexPath];
    [self.delegate tableViewControllerChooseFieldDidFinish: self withFieldID: fieldID];
}

#pragma mark -
#pragma mark Helpers

- (NSManagedObjectID *)queryFieldObjectIDForIndexPath:(NSIndexPath *)indexPath {
    NSManagedObjectID *result;
    id <NSFetchedResultsSectionInfo> section = self.resultsController.sections[(NSUInteger)indexPath.section];
    NSDictionary *rowData = section.objects[(NSUInteger)indexPath.row];
    NSString *keySelf = NSStringFromSelector(@selector(self));
    result = rowData[keySelf];
    return result;
}

#pragma mark -
#pragma mark Section header delegate

- (void)sectionHeaderView:(MADDatabaseTableSectionHeaderView *)sectionHeaderView
            sectionOpened:(NSInteger)sectionOpened {
	
	MADSchemaFieldSelectorModel *sectionInfo = self.sectionInfoArray[(NSUInteger)sectionOpened];
    sectionInfo.open = YES;
    
    id <NSFetchedResultsSectionInfo> data = self.resultsController.sections[(NSUInteger)sectionOpened];

    /*
     Create an array containing the index paths of the rows to insert: These correspond to the
        rows for each quotation in the current section.
     */
    NSUInteger countOfRowsToInsert = data.numberOfObjects;
    NSMutableArray <NSIndexPath *> *indexPathsToInsert;
    indexPathsToInsert = [[NSMutableArray alloc] initWithCapacity:countOfRowsToInsert];
    for (NSUInteger i = 0; i < countOfRowsToInsert; i++) {
        @autoreleasepool {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow: (NSInteger)i
                                                        inSection: sectionOpened];
            [indexPathsToInsert addObject:indexPath];
        }
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the
        rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray <NSIndexPath *> *indexPathsToDelete = [[NSMutableArray alloc] init];

    NSInteger previousOpenSectionIndex = _openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
		
		MADSchemaFieldSelectorModel *previousOpenSection =
                                        self.sectionInfoArray[(NSUInteger)previousOpenSectionIndex];
        id <NSFetchedResultsSectionInfo> previousData = self.resultsController.sections[(NSUInteger)previousOpenSectionIndex];

        previousOpenSection.open = NO;

        MADDatabaseTableSectionHeaderView *headerView;
        headerView = (MADDatabaseTableSectionHeaderView *)[self.tableView headerViewForSection:previousOpenSectionIndex];
        if (headerView) {
            [headerView toggleOpenWithUserAction:NO];
        }
        NSUInteger countOfRowsToDelete = previousData.objects.count;
        for (NSUInteger i = 0; i < countOfRowsToDelete; i++) {
            @autoreleasepool {
                NSIndexPath *path = [NSIndexPath indexPathForRow: (NSInteger)i
                                                       inSection: previousOpenSectionIndex];
                [indexPathsToDelete addObject:path];
            }
        }
    }
    
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    } else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
    
    // Apply the updates.
    UITableView *tableView = self.tableView;
    [tableView beginUpdates];
    [tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [tableView endUpdates];
    
    _openSectionIndex = sectionOpened;
    [self updateSize];
}

- (void)sectionHeaderView:(MADDatabaseTableSectionHeaderView *)sectionHeaderView
            sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed,
        then delete those rows from the table view.
     */
	MADSchemaFieldSelectorModel *sectionInfo = self.sectionInfoArray[(NSUInteger)sectionClosed];
    sectionInfo.open = NO;

    id <NSFetchedResultsSectionInfo> data = self.resultsController.sections[(NSUInteger)sectionClosed];
    NSInteger countOfRowsToDelete = (NSInteger)data.numberOfObjects;
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:sectionClosed];
            [indexPathsToDelete addObject:path];
        }
        [self.tableView deleteRowsAtIndexPaths: indexPathsToDelete
                              withRowAnimation: UITableViewRowAnimationTop];
    }
    _openSectionIndex = NSNotFound;
    [self updateSize];
}

- (void)updateSize {
    self.preferredContentSize = PreferredContentSizeForUpdate(self.sectionInfoArray.count, _openSectionIndex == NSNotFound ? 0 : self.resultsController.sections[(NSUInteger)_openSectionIndex].objects.count);
    self.navigationController.preferredContentSize = PreferredContentSizeForUpdate(self.sectionInfoArray.count, _openSectionIndex == NSNotFound ? 0 : self.resultsController.sections[(NSUInteger)_openSectionIndex].objects.count);
}

#pragma mark -
#pragma mark Accessibility

/*- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return (NSInteger)self.sectionInfoArray.count;
}

- (NSArray *)accessibilityElements {
    NSMutableArray *accessibilityElements;
    
    accessibilityElements = [[NSMutableArray alloc] initWithCapacity:self.sectionInfoArray.count];
    for (MADSchemaFieldSelectorModel *sectionInfo in self.sectionInfoArray) {
        [accessibilityElements addObject: sectionInfo.headerView];
    }
    
    return accessibilityElements;
}*/

@end
