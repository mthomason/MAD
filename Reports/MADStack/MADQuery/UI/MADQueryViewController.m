//
//  MUIViewControllerQueryBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryViewController.h"
#import <os/log.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSFetchRequestExpression.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSPersistentStoreResult.h>

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UIPresentationController.h>
#import <UIKit/UIPopoverPresentationController.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIStoryboard.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MAD/MADocument.h>
#import <MAD/MTQuery.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDatabaseSchemaTable.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelQuery.h>

#import "MADQueryViewSectionDelegate.h"
#import "MADLabelTitle.h"
#import "MADTabBarController.h"
#import "MTStoreKitController+Features.h"
#import "MADWatermarkView.h"

#import "MADQueryBuilderAddTableViewController.h"
#import "MTQueryBuilderAddGroupViewController.h"
#import "MADQueryPredicateFormatController.h"

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryGroup.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MTTableController.h"

#import "MADQueryLinkBuilderController.h"

#import "MADTableViewHeader.h"

#import "MADDesignerSectionLayoutController.h"

#import "MADNavigationController.h"

#import "MADViewControllerSQL.h"

#import "UIViewController+tabBarItem.h"

#import "NSParagraphStyle+CommonStyles.h"

#import "MADQueryViewDataSource.h"

#import "MADQueryBuilderAddGroupDelegate.h"
#import "MADQueryViewControllerTableLayout.h"
#import "MADQueryViewControllerLayoutSectionSelectorProtocol.h"

#import "NSAttributedString+QueryViewController.h"
#import "MADViewTableHeader+QueryViewSectionTypes.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADQueryViewDelegate.h"
#import "MADTabBarItemProtocol.h"
#import "MADQueryViewDatasourceProtocol.h"

NSString * const MADImageBarButtonItemDatabase                      = @"UIBarButtonItemDatabase";
NSString * const MADImageBarButtonItemDatabase8                     = @"UIBarButtonItemDatabase8";

static NSString * const NSFetchedResultsCacheName                   = @"NSFetchedResultsCacheName";
static NSString * const NSFetchedResultsCacheTables                 = @"NSFetchedResultsCacheTables";
static NSString * const NSFetchedResultsCacheLinks                  = @"NSFetchedResultsCacheLinks";
static NSString * const NSFetchedResultsCacheGroups                 = @"NSFetchedResultsCacheGroups";
static NSString * const NSFetchedResultsCachePredicates             = @"NSFetchedResultsCachePredicates";

static NSString * const MADIdentifierDefaultsViewerDesired = @"defaults.everydayapps.features.viewer.desired";

static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing);
static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing);
BOOL storeEnabled(void);

static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing) {
    return pushing ? UITransitionContextFromViewControllerKey :
                     UITransitionContextToViewControllerKey;
}
static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing) {
    return pushing ? UITransitionContextToViewControllerKey :
                     UITransitionContextFromViewControllerKey;
}

BOOL storeEnabled() {
    return [MTStoreKitController sharedObject].reportingEnabled;
}

#pragma mark - Private Category

@interface MADQueryViewController ()

    <NSFetchedResultsControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        UIViewControllerTransitioningDelegate,
        MADQueryViewDelegateProtocol,
        MADQueryViewControllerLayoutSectionSelectorProtocol,
        MADQueryBuilderAddTableDelegate,
        MADQueryBuilderAddGroupDelegate,
        MADViewControllerStandardProtocol,
        MTQueryBuilderLinkBuilderDelegate,
        MADViewControllerStandardProtocol,
        MADDesignerSectionLayoutDelegate,
        MTQueryBuilderPredicateFormatDelegate,
        MADQueryViewControllerDatasourceProtocol>

    @property (nonatomic, strong) MADQueryViewDataSource *queryViewDataSource;
    @property (nonatomic, strong) MADQueryViewDelegate *queryViewDelegate;

    @property (nonatomic, strong) MADQueryViewCellConfigureHandler handleConfigureCell;

    @property (nonatomic, readonly) MADTabBarController *tabBarController;

    @property (nonatomic, weak) UIPresentationController *showSQLPresentationController;

@end

@implementation MADQueryViewController {
    NSUInteger _lastSelectedRowNumber;
    CGFloat _headerSectionHeight;
    BOOL _suspendAutomaticTrackingOfChangesInManagedObjectContext;
    BOOL _firstTimeViewWillLayoutSubviews;
    BOOL _beganUpdates;
}

@synthesize title = _title;
@synthesize document = _document;

#pragma mark -
#pragma mark Static

#pragma mark -
#pragma mark Helper

+ (void)configureCell: (UITableViewCell *)cell
           forSection: (MADIdentifierQueryViewSections)section
               andRow: (NSInteger)row {
    
    switch (section) {
            
        case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
            
            UISwitch *switchQueryMode = [[UISwitch alloc] initWithFrame:CGRectZero];
            switchQueryMode.on = [[NSUserDefaults standardUserDefaults] boolForKey: MADIdentifierDefaultsViewerDesired];
            [switchQueryMode addTarget: nil action: @selector(handleToggleReportingMode:)
                      forControlEvents: UIControlEventValueChanged];
            cell.accessoryView = switchQueryMode;
            cell.textLabel.text = switchQueryMode.on ?
            @"Reporting Mode" :
            @"Designer Mode (limited)";
            break;
        }
            
        default: {
            break;
        }
    }
}

+ (CGFloat)SizeCategoryHeight:(NSString *)category {
    
    if ([category isEqualToString: UIContentSizeCategoryExtraSmall]) {
        return 24.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategorySmall]) {
        return 26.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryMedium]) {
        return 29.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryLarge]) {
        return 32.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryExtraLarge]) {
        return 34.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryExtraExtraLarge]) {
        return 36.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryExtraExtraExtraLarge]) {
        return 38.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityMedium]) {
        return 40.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityLarge]) {
        return 42.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraLarge]) {
        return 44.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
        return 46.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
        return 48.0000f;
        
    } else {
        return 29.0000f;
    }
}

+ (void)deleteCoreDataCache {
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
}

#pragma mark -
#pragma mark NSObject

+ (instancetype)newQueryViewController:(MADocument *)document {
    id bundle = [NSBundle mainBundle];
    id storybard = [UIStoryboard storyboardWithName: @"MADQuery" bundle: bundle];
    id controller = [storybard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryViewController"];
    [((typeof(self))controller) setDocument: document];
    return controller;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [MADQueryViewController deleteCoreDataCache];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.tableView setBackgroundView:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    [MADQueryViewController deleteCoreDataCache];
    
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;

    _firstTimeViewWillLayoutSubviews = NO;

    MADQueryViewDelegate *queryViewDelegate = [[MADQueryViewDelegate alloc] init];
    queryViewDelegate.delegate = self;
    self.queryViewDelegate = queryViewDelegate;
    
    MADQueryViewCellConfigureHandler handleConfigureCell;
    handleConfigureCell = ^(UITableViewCell *cell,
                            MADIdentifierQueryViewSections forSection,
                            NSInteger row) {
        
        [MADQueryViewController configureCell: cell
                                   forSection: forSection
                                       andRow: row];
        
    };
    self.handleConfigureCell = handleConfigureCell;
    
    return self;
}

#pragma mark -
#pragma mark Storyboard

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToQueryBuilder:);
}

- (UIViewController *)viewControllerForUnwindSegueAction: (SEL)action
                                      fromViewController: (UIViewController *)fromViewController
                                              withSender: (id)sender {
    id result;
    result = action == @selector(unwindToQueryBuilder:) ?
            self : [super viewControllerForUnwindSegueAction: action
                                          fromViewController: fromViewController
                                                  withSender: sender];
    return result;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *sizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    [self updateInupdateInterfaceForPerferedContentSizeCategory: sizeCategory];
    
    NSString *MADIdentifierTableViewCellTableName = @"MADIdentifierCellSchemaName";
    [self.tableView registerClass: [MADTableViewCellQueryTableName class]
           forCellReuseIdentifier: MADIdentifierTableViewCellTableName];
    
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.navigationItem.prompt = nil;
    self.tableView.dataSource = self.queryViewDataSource;


}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    UIManagedDocument *document;
    NSManagedObjectContext *managedObjectContext;
    
    document = _document;
    managedObjectContext = document.managedObjectContext;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleDocumentStateChanged)
                                                 name: UIDocumentStateChangedNotification
                                               object: document];
    
    SEL handleContentSizeCategoryDidChange = @selector(handleContentSizeCategoryDidChange:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: handleContentSizeCategoryDidChange
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    SEL resultHandler = @selector(handleApplicationDidBecomeActive:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: resultHandler
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    [self observeManagedObjectContextChanges: managedObjectContext];
    
    [self.tabBarController enableTabBarItems];
    
    self.tableView.delegate = _queryViewDelegate;
    [self reloadMainDocumentAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    
    UIManagedDocument *document;
    NSManagedObjectContext *managedObjectContext;

    document = _document;
    managedObjectContext = document.managedObjectContext;
    
    [self ingnoreManagedObjectContextChanges: managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: document];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIContentSizeCategoryDidChangeNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationDidBecomeActiveNotification
                                                  object: nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                            CGSizeZero.width,
                                                            self.bottomLayoutGuide.length,
                                                            CGSizeZero.width);
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                                   self.bottomLayoutGuide.length, CGSizeZero.width);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_firstTimeViewWillLayoutSubviews) {
        CGRect r = CGRectMake(CGPointZero.x, CGPointZero.y,
                              self.tableView.frame.size.width, 1.0000f);
        [self.tableView scrollRectToVisible: r animated: NO];
        _firstTimeViewWillLayoutSubviews = NO;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.view.frame = self.navigationController.view.bounds;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
}

#pragma mark -
#pragma mark Property Overrides

- (MADTabBarController *)tabBarController {
    return (MADTabBarController *)self.navigationController.tabBarController;
}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

- (NSString *)title {
    if (_title == nil) {
        NSString *title = NSLocalizedString(@"MAD Query", @"View controller title.");
        _title = title;
    }
    return _title;
}

- (MADQueryViewDataSource *)queryViewDataSource {

    if (_queryViewDataSource == nil) {

        MADocument *document = _document;
        NSManagedObjectContext *managedObjectContext;
        NSNumber *objectID;

        managedObjectContext = document.documentModel.managedObjectContext;
        objectID = document.documentModel.databases.firstObject.queries.firstObject.objectID.copy;
        
        
        BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;
        MADQueryViewDataSource *dataSource;
        dataSource = [[MADQueryViewDataSource alloc] initWithQueryID: objectID
                                                managedObjectContext: managedObjectContext
                                                    reportingEnabled: reportingEnabled
                                                 handleConfigureCell: _handleConfigureCell];
        
        dataSource.datasoruce = self;
        _queryViewDataSource = dataSource;
    }
    return _queryViewDataSource;
}

#pragma mark -
#pragma mark MADDesignerSectionLayoutDelegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MADocument *document = self.document;
    [document.activeDocumentModel setHeight: height
                            forSectionAtRow: _lastSelectedRowNumber];
    [document saveContext];
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {

    MADocument *document = self.document;
    [document.activeDocumentModel setVisibility: isVisible
                                forSectionAtRow: _lastSelectedRowNumber];
    [document saveContext];
}

- (void)layoutSettings:(MADDesignerSectionLayoutController *)layoutSettings
          newPageAfter:(BOOL)newPageAfter {

    MADocument *document = self.document;
    [document.activeDocumentModel setNewPageAfter: newPageAfter
                                  forSectionAtRow: _lastSelectedRowNumber];
    [document saveContext];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(int32_t)numberOfRows {

    MADocument *document = self.document;
    
    
    [document.activeDocumentModel setNumberOfRows: numberOfRows
                                  forSectionAtRow: _lastSelectedRowNumber];
    [document saveContext];
}

#pragma mark -
#pragma mark MUIViewControllerDelegate

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];
}

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewController];
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewController];
}

#pragma mark -
#pragma mark MTQueryBuilderPredicateFormatDelegate

- (void)viewController:(MADQueryPredicateFormatController *)controller
   addedQueryPredicate:(RptqQueryPredicate *)predicate {
    [self dismissViewController];
}

#pragma mark -
#pragma mark MTQueryBuilderLinkBuilderDelegate

- (void)viewController:(MADQueryLinkBuilderController *)controller
        addedQueryLink:(NSManagedObjectID *)linkID {

    [self dismissViewController];
    
    NSInteger suspectedSection = 2;
    
    MADIdentifierQueryViewSections tableSection;
    tableSection = [self.queryViewDataSource sectionAtIndex:(short)suspectedSection];
    
    if (tableSection == MADIdentifierQueryViewSectionsLinks) {
        NSIndexSet *linksSection;
        linksSection = [NSIndexSet indexSetWithIndex:(NSUInteger)suspectedSection];
        [self.tableView reloadSections: linksSection
                      withRowAnimation: UITableViewRowAnimationAutomatic];
    }
    
    //[document saveToURL: document.fileURL
    //   forSaveOperation: UIDocumentSaveForOverwriting completionHandler:nil];
}

#pragma mark -
#pragma mark MTQueryBuilderAddGroupDelegate

- (void)viewController: (MTQueryBuilderAddGroupViewController *)viewController
addedGroupOnQueryField: (NSManagedObjectID *)queryFieldID
          andSortOrder: (MADSortOrder)sortOrder {
    
    [self dismissViewController];

    [self.document addQueryGroupWithQueryField: queryFieldID
                                  andSortOrder: sortOrder];
}

#pragma mark -
#pragma mark MADQueryBuilderAddTableDelegate

- (void)viewController: (MADQueryBuilderAddTableViewController *)viewController
      addedTableWithID: (NSManagedObjectID *)objectID {

    [self dismissViewController];
    [self.document addQuerySelectTableForSchemeTableWithObjectID: objectID];
}

#pragma mark -
#pragma mark Event handlers

- (void)handleApplicationDidBecomeActive:(id)sender {
    [MADQueryViewController deleteCoreDataCache];
}

- (void)handleToggleReportingMode:(UISwitch *)switchControl {
    if (switchControl.on) {
        if ([MTStoreKitController sharedObject].isReportingEnabled) {
            [[NSUserDefaults standardUserDefaults] setBool: YES
                                                    forKey: MADIdentifierDefaultsViewerDesired];
        } else {
            [[NSUserDefaults standardUserDefaults] setBool: NO
                                                    forKey: MADIdentifierDefaultsViewerDesired];
            [switchControl setOn:NO animated:YES];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] setBool: NO
                                                forKey: MADIdentifierDefaultsViewerDesired];
    }
}

#pragma mark UIDocumentStateChangedNotification

- (void)handleDocumentStateChanged {
    
    switch (self.document.documentState) {
        case UIDocumentStateClosed:
            [self disableUserInteraction];
            break;
        case UIDocumentStateInConflict:
            [self enableUserInteraction];
            break;
        case UIDocumentStateSavingError:
            [self enableUserInteraction];
            break;
        case UIDocumentStateEditingDisabled:
            [self disableUserInteraction];
            break;
        case UIDocumentStateNormal:
        default:
            [self enableUserInteraction];
            break;
    }
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (NSMutableArray *)sectionsUsedByFetchedResultsController:(NSFetchedResultsController *)controller {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

    NSNumber *sectionNumber;
    if ([controller isEqual:self.queryViewDataSource.queryTablesController]) {
        
        sectionNumber = [[NSNumber alloc] initWithShort: [self sectionIndexForTables]];
        [result addObject: sectionNumber];

    } else if ([controller isEqual:self.queryViewDataSource.queryLinksController]) {

        sectionNumber = [[NSNumber alloc] initWithShort: [self sectionIndexForLinks]];
        [result addObject: sectionNumber];

    } else if ([controller isEqual:self.queryViewDataSource.queryGroupsController]) {

        sectionNumber = [[NSNumber alloc] initWithShort: [self sectionIndexForGroups]];
        [result addObject: sectionNumber];
    
    } else if ([controller isEqual:self.queryViewDataSource.queryPredicatesController]) {

        sectionNumber = [[NSNumber alloc] initWithShort:[self sectionIndexForPredicate]];
        [result addObject: sectionNumber];
    }
    
    return result;

}

- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex
     forChangeType: (NSFetchedResultsChangeType)type {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
    NSNumber *section;
    for (section in sections) {
        if (!_suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            MADIdentifierQueryViewSections updateSection = section.shortValue;
            switch(type) {
                case NSFetchedResultsChangeInsert: {
                    NSIndexSet *updatedIndex = [NSIndexSet indexSetWithIndex: updateSection];
                    [self.tableView insertSections: updatedIndex
                                    withRowAnimation: UITableViewRowAnimationFade];
                    break;
                }
                    
                case NSFetchedResultsChangeDelete: {
                    NSIndexSet *updatedIndex = [NSIndexSet indexSetWithIndex: updateSection];
                    [self.tableView deleteSections: updatedIndex
                                  withRowAnimation: UITableViewRowAnimationFade];
                    break;
                }
                    
                case NSFetchedResultsChangeMove:
                    break;
                case NSFetchedResultsChangeUpdate:
                    break;
            }
        }
        
    }
    
}


- (void)controller: (NSFetchedResultsController *)controller
   didChangeObject: (id)anObject
       atIndexPath: (NSIndexPath *)indexPath
     forChangeType: (NSFetchedResultsChangeType)type
      newIndexPath: (NSIndexPath *)newIndexPath {
    NSLog(@"%s (%ld, %ld)", __PRETTY_FUNCTION__, indexPath.section, indexPath.row);

    if (_suspendAutomaticTrackingOfChangesInManagedObjectContext) return;
    
    NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
    
    NSArray *indexPaths;
    NSIndexPath *path;
    NSNumber *section;
    for (section in sections) {
        switch(type) {
            case NSFetchedResultsChangeInsert: {
                path = [NSIndexPath indexPathForRow: (long)[controller.fetchedObjects indexOfObject: anObject]
                                          inSection: section.shortValue];
                indexPaths = [[NSArray alloc] initWithObjects: path, nil];
                [self.tableView insertRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;
            }
            case NSFetchedResultsChangeDelete: {
                path = [NSIndexPath indexPathForRow: indexPath.row
                                          inSection: section.shortValue];
                indexPaths = [[NSArray alloc] initWithObjects: path, nil];
                [self.tableView deleteRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;
            }
            case NSFetchedResultsChangeUpdate: {
                path = [NSIndexPath indexPathForRow: indexPath.row
                                          inSection: section.shortValue];
                indexPaths = [[NSArray alloc] initWithObjects: path, nil];
                [self.tableView reloadRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;
            }
            case NSFetchedResultsChangeMove: {
                path = [NSIndexPath indexPathForRow: indexPath.row
                                          inSection: section.shortValue];
                indexPaths = [[NSArray alloc] initWithObjects: path, nil];
                [self.tableView deleteRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths: indexPaths
                                      withRowAnimation: UITableViewRowAnimationFade];
                break;
            }
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (!_suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableView beginUpdates];
        _beganUpdates = YES;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (_beganUpdates) {
        [self.tableView endUpdates];
    }
    _beganUpdates = NO;
}

#pragma mark -
#pragma mark MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

#pragma mark -
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
                                            (UIPresentationController *)controller {
    
    UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
    if ([controller isEqual:self.showSQLPresentationController]) {
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            style = UIModalPresentationNone;
        } else {
            style = UIModalPresentationOverFullScreen;
        }
    }
    
    return style;
}

#pragma mark -
#pragma mark Actions

- (IBAction)edit:(id)sender {
    self.tableView.editing = !self.tableView.isEditing;
}

- (IBAction)done:(id)sender {
    [((MADNavigationController *)self.navigationController) done:sender];
}

- (IBAction)displaySQL:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQuery" bundle:nil];
    UINavigationController *navigationController;
    navigationController = [storyboard instantiateViewControllerWithIdentifier:@"MADQuerySQLNavigationController"];
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    MADViewControllerSQL *viewController;
    viewController = (MADViewControllerSQL *)navigationController.topViewController;
    viewController.document = self.document;
    viewController.delegate = self;
    UIPopoverPresentationController *ppc = navigationController.popoverPresentationController;
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    
    self.showSQLPresentationController = ppc;
    [self presentViewController:navigationController animated:YES completion:^{
        [self.tabBarController disableTabBarItems];
    }];
}

- (void)addTable:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddTable" bundle:nil];
    UINavigationController *navigationController;
    navigationController = [storyboard instantiateInitialViewController];
    navigationController.modalPresentationStyle =
                self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
                                                        UIModalPresentationFormSheet :
                                                        UIModalPresentationOverFullScreen;
    UIPresentationController *pc = navigationController.presentationController;
    pc.delegate = self;
    
    
    MADQueryBuilderAddTableViewController *tvc;
    tvc = (MADQueryBuilderAddTableViewController *)navigationController.topViewController;
    tvc.delegate = self;
    tvc.managedObjectContext = self.document.managedObjectContext;
    [self presentViewController:navigationController animated:YES completion:^{
        [self.tabBarController disableTabBarItems];
    }];
}

- (void)addLink:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddJoin" bundle:nil];
    UINavigationController *navigationController;
    navigationController = [storyboard instantiateInitialViewController];
    navigationController.modalPresentationStyle =
                self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
                                                        UIModalPresentationFormSheet :
                                                        UIModalPresentationOverFullScreen;
    UIPresentationController *pc = navigationController.presentationController;
    pc.delegate = self;
    MADQueryLinkBuilderController *tvc;
    tvc = (MADQueryLinkBuilderController *)navigationController.topViewController;
    tvc.queryLinkDelegate = self;
    tvc.document = self.document;
    [self presentViewController:navigationController animated:YES completion:^{
        [self.tabBarController disableTabBarItems];
    }];
}

- (void)addPredicate:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddPredicate" bundle:nil];
    UINavigationController *navigationController;
    navigationController = [storyboard instantiateInitialViewController];
    navigationController.modalPresentationStyle =
                self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
                                                        UIModalPresentationFormSheet :
                                                        UIModalPresentationOverFullScreen;
    UIPresentationController *pc = navigationController.presentationController;
    pc.delegate = self;
    MADQueryPredicateFormatController *tvc;
    tvc = (MADQueryPredicateFormatController *)navigationController.topViewController;
    tvc.delegate = self;
    tvc.document = self.document;
    [self presentViewController:navigationController animated:YES completion:^{
        [self.tabBarController disableTabBarItems];
    }];
}

- (void)addGroup:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddGroup" bundle:nil];
    UINavigationController *navigationController;
    navigationController = [storyboard instantiateInitialViewController];
    navigationController.modalPresentationStyle =
                self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
                                                        UIModalPresentationFormSheet :
                                                        UIModalPresentationOverFullScreen;
    UIPresentationController *pc = navigationController.presentationController;
    pc.delegate = self;
    MTQueryBuilderAddGroupViewController *tvc;
    tvc = (MTQueryBuilderAddGroupViewController *)navigationController.topViewController;
    tvc.delegate = self;
    tvc.document = self.document;
    [self presentViewController:navigationController animated:YES completion:^{
        [self.tabBarController disableTabBarItems];
    }];
}

#pragma mark -
#pragma mark Helper functions

- (void)updateInupdateInterfaceForPerferedContentSizeCategory:(NSString *)category {
    _headerSectionHeight = [self.class SizeCategoryHeight:category];
}

#pragma mark Section Indexes

- (MADIdentifierQueryViewSections)sectionIndexForTables {
    return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsTables];
}

- (MADIdentifierQueryViewSections)sectionIndexForLinks {
    return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsLinks];
}

- (MADIdentifierQueryViewSections)sectionIndexForGroups {
    return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsGroups];
}

- (MADIdentifierQueryViewSections)sectionIndexForPredicate {
    return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsPredicate];
}

- (MADIdentifierQueryViewSections)sectionIndexForSectionType:(MADIdentifierQueryViewSections)sec {
    MADIdentifierQueryViewSections result = 0;
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection: 1];
    MADQueryViewControllerTableLayout *tableLayout;
    tableLayout = [[MADQueryViewControllerTableLayout alloc] initWithNumberOfTables:numberOfRows
                                                                   reportingEnabled:storeEnabled()];
    NSArray *sectionTypes = [tableLayout sectionTypes].copy;
    NSInteger secPos = 0;
    
    for (NSNumber *num in sectionTypes) {
        if (num.unsignedIntegerValue == sec) {
            result = (MADIdentifierQueryViewSections)secPos;
            break;
        }
        secPos++;
    }
    return result;
}

#pragma mark User Interface

- (void)enableUserInteraction {
    [self.tableView setUserInteractionEnabled:YES];
}

- (void)disableUserInteraction {
    [self.tableView setUserInteractionEnabled:NO];
}

- (void)reloadMainDocumentAnimated:(BOOL)animated {
    
    MADocument *reportDocument = self.document;
    NSAssert(reportDocument != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    self.queryViewDataSource.queryTablesController.delegate = self;
    self.queryViewDataSource.queryLinksController.delegate = self;
    self.queryViewDataSource.queryGroupsController.delegate = self;
    self.queryViewDataSource.queryPredicatesController.delegate = self;

    [self.queryViewDataSource performFetchAll];
    [self.tableView reloadData];
}

- (NSArray <NSIndexPath *> *)deleteLinksRelatedToSectionIndex:(NSInteger)section
                                                        table:(NSManagedObjectID *)deleatedObjectID
                                                  inTableView:(UITableView *)tableView
                                                    inContext:(NSManagedObjectContext *)context {
    
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    
    NSFetchedResultsController *fetchedLinkes = self.queryViewDataSource.queryLinksController;
    
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
    
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = NULL;
        NSManagedObject *object = nil;
        MADTableViewCellQueryLink *cell;
        cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
        if (cell) {
            object = [context existingObjectWithID:cell.tableID error:&error];
        } else {
            
            id <NSFetchedResultsSectionInfo> sectionInfo = fetchedLinkes.sections[0];
            if (row < (NSInteger)sectionInfo.numberOfObjects) {
                NSIndexPath *testLinkIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
                object = [fetchedLinkes objectAtIndexPath:testLinkIndexPath];
            }
            
        }
        if (!error && object && [object isKindOfClass:[RptqQueryLinks class]]) {
            RptqQueryLinks *queryLink = (RptqQueryLinks *)object;
            if ([queryLink.hasLeftField.inQueryTable.objectID isEqual:deleatedObjectID] ||
                [queryLink.hasRightField.inQueryTable.objectID isEqual:deleatedObjectID]) {
                [context deleteObject:queryLink];
                
                [cellsToDelete addObject:linkIndexPath];
                
            }
        }
    }
    return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)deleteGroupsRelatedToSectionIndex:(NSInteger)section
                                                         table:(NSManagedObjectID *)deleatedObjectID
                                                   inTableView:(UITableView *)tableView
                                                     inContext:(NSManagedObjectContext *)context {
    
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *groupIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = nil;

        id <NSFetchedResultsSectionInfo> sectionInfo;
        sectionInfo = (self.queryViewDataSource.queryGroupsController.sections)[0];
        if (row < (NSInteger)sectionInfo.numberOfObjects) {
            
            NSIndexPath *testGroupIndexPath;
            testGroupIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            NSManagedObject *object;
            object = [self.queryViewDataSource.queryGroupsController objectAtIndexPath:testGroupIndexPath];
            
            if (!error && object && [object isKindOfClass:[RptqQueryGroup class]]) {
            
                RptqQueryGroup *groupToRemove = (RptqQueryGroup *)object;
                if ([groupToRemove.hasField.inQueryTable.objectID isEqual:deleatedObjectID]) {
                    [self.document removeGroupWitObjectID: groupToRemove.objectID
                                 fromManagedObjectContext: context];
                    [cellsToDelete addObject:groupIndexPath];
                }
                
            }

        }
    }
    return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)deletePredicateRelatedToSectionIndex: (NSInteger)section
                                                            table: (NSManagedObjectID *)deleatedObjectID
                                                      inTableView: (UITableView *)tableView
                                                        inContext: (NSManagedObjectContext *)context {

    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];

    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {

        NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        
        MADTableViewCellQueryPredicate *cell;
        cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:predicateIndexPath];
        NSError *error = nil;
        NSManagedObject *object = nil;
        
        if (cell) {
            object = [context existingObjectWithID: cell.tableID
                                             error: &error];
        } else {
            NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row
                                                                     inSection: 0];
            object = [self.queryViewDataSource.queryPredicatesController objectAtIndexPath: testPredicateIndexPath];
        }
        
        if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
        
            RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;

            BOOL deleted = NO;
            if ([predicateToRemove.hasLeftField.inQueryTable.objectID isEqual:deleatedObjectID]) {

                [context deleteObject:predicateToRemove];
                
                NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
                [cellsToDelete addObject:deleteCellAtIndex];
                deleted = YES;
            }
            
            if (!deleted) {
                if ([predicateToRemove.hasRightField.inQueryTable.objectID isEqual:deleatedObjectID]) {
                
                    [context deleteObject:predicateToRemove];

                    NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
                    [cellsToDelete addObject:deleteCellAtIndex];
                }
            }
        }
    }
    return cellsToDelete;
}

#pragma mark -
#pragma mark MADQueryViewControllerDatasourceProtocol

- (void)reloadQueryViewData {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.tableView reloadData];
}

- (void)deleteQueryPredicateFromTableView: (UITableView *)tableView
                              atIndexPath: (NSIndexPath *)indexPath {
    MADocument *document = self.document;
    MADTableViewCellQueryPredicate *cell;
    cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *objid = cell.tableID;
    NSManagedObject *predicate = [document.managedObjectContext objectWithID:objid];
    [document.managedObjectContext deleteObject:predicate];
    NSError *error = NULL;
    if ([document.managedObjectContext save:&error])
        NSLog(@"Error saving managed object context: %@", error);
    [document updateChangeCount: UIDocumentChangeDone];
}

- (void)deleteItemFromQuerySection: (MADIdentifierQueryViewSections)section
                     fromTableView: (UITableView *)tableView
                       atIndexPath: (NSIndexPath *)indexPath {
    //NSLog(@"Delete item %ld from section %ld-%hd.", indexPath.item, indexPath.section, querySection);
    
    switch (section) {
        case MADIdentifierQueryViewSectionsTables:
            [self deleteQueryTableFromTableView: tableView atIndexPath: indexPath];
            break;
            
        case MADIdentifierQueryViewSectionsLinks:
            [self deleteQueryLinksFromTableView: tableView atIndexPath: indexPath];
            break;
            
        case MADIdentifierQueryViewSectionsGroups:
            [self deleteQueryGroupFromTableView: tableView atIndexPath: indexPath];
            break;
            
        case MADIdentifierQueryViewSectionsPredicate:
            [self deleteQueryPredicateFromTableView: tableView atIndexPath: indexPath];
            break;
            
        default:
            break;
    }
}

- (void)deleteQueryTableFromTableView: (UITableView *)tableView
                          atIndexPath: (NSIndexPath *)indexPath {
    NSLog(@"%s: (%ld, %ld)", __PRETTY_FUNCTION__, indexPath.section, indexPath.row);
    
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    
    //NSManagedObjectContext *private;
    //private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    NSManagedObjectContext *context = self.document.managedObjectContext;
    //[self observeManagedObjectContextChanges: managedObjectContext];
    [self ingnoreManagedObjectContextChanges:context];
    
    //private.parentContext = managedObjectContext;

    //[private performBlockAndWait:^{
        
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: context];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
        
        NSUInteger numberOfTables = rptqQuery.hasQueryTables.count;
        
        BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;
        MADQueryViewDataSource *oldQueryLayout, *newQueryLayout;
        oldQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
                                                               reportingEnabled: reportingEnabled
                                                            handleConfigureCell: nil];
        
        newQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables - 1
                                                               reportingEnabled: reportingEnabled
                                                            handleConfigureCell: nil];
        
        NSIndexSet *oldIndexesSectionTypes = oldQueryLayout.sectionTypesIndexs;
        NSMutableIndexSet *oldIndexes = oldIndexesSectionTypes.mutableCopy;
        [oldIndexes removeIndexes:newQueryLayout.sectionTypesIndexs];
        
        NSMutableSet *deletedSectionTypes = oldQueryLayout.sectionTypes.mutableCopy;
        [deletedSectionTypes minusSet:newQueryLayout.sectionTypes];
        
        NSIndexPath *tableIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 0];
        NSIndexPath *displayIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 1];
        RptqQueryTable *table = [self.queryViewDataSource.queryTablesController objectAtIndexPath: tableIndex];
        
        NSManagedObjectID *deleatedTableObjectId = table.objectID.copy;
        
        NSMutableSet *hasQueryTables = rptqQuery.hasQueryTables.mutableCopy;
        
        __block id objectToDelete = nil;
        [hasQueryTables enumerateObjectsUsingBlock:^(RptqQueryTable * _Nonnull hasTable, BOOL * _Nonnull stop) {
            if (table.identifier == hasTable.identifier) {
                objectToDelete = hasTable;
            }
        }];
        [hasQueryTables removeObject:objectToDelete];
        rptqQuery.hasQueryTables = hasQueryTables.copy;
        
        numberOfTables--;
        
        __block short ctr = 0;
        NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
        [oldIndexesSectionTypes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            if ([oldIndexes containsIndex:idx]) {
                [indexesToRemove addIndex:(NSUInteger)ctr];
            }
            ctr++;
        }];
        [self.tableView beginUpdates];
        
        MADocument *document =  self.document;
        [document deleteDatafieldsRelatedToTable:deleatedTableObjectId inContent:context];
        [document deleteAggregateFieldRelatedToTable:deleatedTableObjectId inContent:context];
        
        NSMutableArray <NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
        
        short numberOfSections = self.queryViewDataSource.count;
        
        for (short section = 0; section < numberOfSections; section++) {
            
            NSArray <NSIndexPath *> *cells = nil;
            
            switch ([self.queryViewDataSource sectionAtIndex:section]) {
                case MADIdentifierQueryViewSectionsLinks:
                    cells = [self deleteLinksRelatedToSectionIndex: (NSInteger)section
                                                             table: deleatedTableObjectId
                                                       inTableView: tableView
                                                         inContext: context];
                    break;
                    
                case MADIdentifierQueryViewSectionsGroups:
                    cells = [self deleteGroupsRelatedToSectionIndex: (NSInteger)section
                                                              table: deleatedTableObjectId
                                                        inTableView: tableView
                                                          inContext: context];
                    break;
                    
                case MADIdentifierQueryViewSectionsPredicate:
                    cells = [self deletePredicateRelatedToSectionIndex: (NSInteger)section
                                                                 table: deleatedTableObjectId
                                                           inTableView: tableView
                                                             inContext: context];
                    break;
                    
                default:
                    break;
            }
            if (cells) {
                if (![indexesToRemove containsIndex:(NSUInteger)section]) {
                    [cellsToDelete addObjectsFromArray:cells];
                }
            }
        }
        
    NSError * __autoreleasing error = NULL;
    BOOL success = NO;
    if (!(success = [context save:&error])) {
        os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
    } else {
        [self.queryViewDataSource numberOfTablesChanged: numberOfTables];
        //[[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        //[self.tableView beginUpdates];
        
        NSArray <NSIndexPath *> *indexPaths;
        indexPaths = [[NSArray <NSIndexPath *> alloc] initWithObjects:displayIndex, nil];
        
        if (indexesToRemove.count > 0) {
            
            [self.tableView deleteSections: indexesToRemove
                          withRowAnimation: UITableViewRowAnimationAutomatic];
            [self.tableView deleteRowsAtIndexPaths: indexPaths
                                  withRowAnimation: UITableViewRowAnimationAutomatic];
            
        } else {
            [self.tableView deleteRowsAtIndexPaths: indexPaths
                                  withRowAnimation: UITableViewRowAnimationAutomatic];
        }
        if (cellsToDelete.count) {
            [self.tableView deleteRowsAtIndexPaths: cellsToDelete
                                  withRowAnimation: UITableViewRowAnimationAutomatic];
        }
        
        
        [self.tableView endUpdates];
        
        //[self observeManagedObjectContextChanges:self.document.managedObjectContext];
        [self observeManagedObjectContextChanges:context];
        
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
        
        //}];
    }
    [document updateChangeCount: UIDocumentChangeDone];

    //}];
}

- (void)deleteQueryLinksFromTableView: (UITableView *)tableView
                          atIndexPath: (NSIndexPath *)indexPath {
    UIManagedDocument *document = self.document;
    MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *tableID = cell.tableID;
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;
    
    [private performBlockAndWait:^{
        
        NSManagedObject *table = [private objectWithID:tableID];
        NSAssert(table != nil, @"Need a non-nil value for %@", tableID);
        [private deleteObject:table];
        
        NSError * __autoreleasing error = NULL;
        BOOL successSave = NO;
        if (!(successSave = [private save:&error])) {
            os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
        }
    }];
    [document updateChangeCount: UIDocumentChangeDone];
}

- (void)deleteQueryGroupFromTableView: (UITableView *)tableView
                          atIndexPath: (NSIndexPath *)indexPath {
    
    UIManagedDocument *document = self.document;
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;
    
    void (^deleteGroup)(void) = ^{
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
        RptqQueryGroup *groupToRemove = [rptqQuery queryGroupForIndex:(NSUInteger)indexPath.row];
        [self.document removeGroupWitObjectID:groupToRemove.objectID fromManagedObjectContext:private];
        
        NSError * __autoreleasing error = NULL;
        BOOL successSave = NO;
        if (!(successSave = [private save:&error])) {
            os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
        }
    };
    [private performBlockAndWait:deleteGroup];
    [document updateChangeCount: UIDocumentChangeDone];
}

#pragma mark -
#pragma mark MADQueryViewDelegateProtocol

- (MADIdentifierQueryViewSections)sectionIdentifierForDisplayIndex:(short)displayIndex {
    MADIdentifierQueryViewSections sectionIdentifier;
    sectionIdentifier = [self.queryViewDataSource sectionAtIndex:displayIndex];
    return sectionIdentifier;
}

- (MADQueryViewSectionDelegate *)sectionLayoutForDisplayIndex:(short)displayIndex {
    id queryViewSectionDelegate = [self.queryViewDataSource layoutAtIndex:displayIndex];
    return queryViewSectionDelegate;
}

- (CGFloat)headerHeight {
    return _headerSectionHeight;
}

- (void)handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index {
    NSLog(@"%s: (%ld)", __PRETTY_FUNCTION__, index);

    NSIndexPath *indexPathUpdate;
    MADTableController *tableController;
    //MADLabelTitle *titleView;
    RptqQueryTable *table, *tableWrapped;
    MTQuery *rquery;
    RptqDatabaseSchemaTable *schemaTable;
    //NSString *name;
    NSFetchedResultsController *queryTablesResultsController;
    MADQueryViewDataSource *queryViewDataSource;
    
    indexPathUpdate = [NSIndexPath indexPathForRow: index inSection: 0];
    queryViewDataSource = self.queryViewDataSource;
    queryTablesResultsController = queryViewDataSource.queryTablesController;
    
    tableWrapped = [queryTablesResultsController objectAtIndexPath: indexPathUpdate];
    
    table = tableWrapped;
    schemaTable = table.databaseSchemaTable;
    
    rquery = [[MTQuery alloc] initWithQueryType:MADQueryTypeSampleDataTable object:schemaTable];
    tableController = [[MADTableController alloc] initWithQuery:rquery];
    
    //titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
    
    //name = schemaTable.name;
    //titleView.text = name.copy;
    
    //tableController.navigationItem.title = name.copy;
    //tableController.navigationItem.titleView = titleView;
    
    [self.navigationController pushViewController: tableController animated: YES];
    
}


#pragma mark -
#pragma mark CoreData

#pragma mark -
#pragma mark Notifications
#pragma mark NSManagedObjectContext Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSDictionary *userInfo = notification.userInfo;
    NSSet *updatedObjects = userInfo[NSUpdatedObjectsKey];
    
    for (id updatedObject in updatedObjects) {
        
        // Update the query view controller data model when number of tables change.
        if ([updatedObject isKindOfClass:[RptqQuery class]]) {
            
            RptqQuery *query;
            NSDictionary <NSString *, id> *changes;

            query = updatedObject;
            changes = [query changedValues];
            
            NSString *selectorHasQueryTables = NSStringFromSelector(@selector(hasQueryTables));
            BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;
            NSUInteger numberOfTables = query.hasQueryTables.count;
            for (id change in changes) {
                if ([change isEqualToString: selectorHasQueryTables]) {
                    
                    //MADQueryViewDataSource *dataSource;
                    //dataSource = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
                    //                                                   reportingEnabled: reportingEnabled
                    //                                                handleConfigureCell: _handleConfigureCell];
                    //dataSource.datasoruce = self;
                    //self.tableView.dataSource = dataSource;
                    //self.queryViewDataSource.datasoruce = nil;
                    //self.queryViewDataSource = dataSource;
                    
                }
            }
        }
    }
}

- (void)ingnoreManagedObjectContextChanges:(NSManagedObjectContext *)context {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextObjectsDidChangeNotification
                                                  object: context];
}

- (void)observeManagedObjectContextChanges:(NSManagedObjectContext *)context {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextDidChange:)
                                                 name: NSManagedObjectContextObjectsDidChangeNotification
                                               object: context];
}

#pragma mark -
#pragma mark UIContentSizeCategoryDidChangeNotification

- (void)handleContentSizeCategoryDidChange:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInupdateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}
- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                            presentingController:(UIViewController *)presenting
                                                                                sourceController:(UIViewController *)source {
    return self;
}


- (void)presentationTransitionWillBegin {
    // Add a custom dimming view behind the presented view controller's view
    //[[self containerView] addSubview:_dimmingView];
    //[_dimmingView addSubview:[[self presentedViewController] view]];
    
    // Use the transition coordinator to set up the animations.
    id <UIViewControllerTransitionCoordinator> transitionCoordinator =
    [[self presentingViewController] transitionCoordinator];
    
    // Fade in the dimming view during the transition.
    [self.tableView.backgroundView setAlpha:0.0];
    [transitionCoordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         [self.tableView.backgroundView setAlpha:1.0];
     } completion:nil];
}

- (void)presentationTransitionDidEnd:(BOOL)completed {
    // Remove the dimming view if the presentation was aborted.
    if (!completed) {
        [self.tableView.backgroundView removeFromSuperview];
    }
}
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
/*
    UIViewController *leftViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    BOOL fromIsQueryView = [leftViewController isKindOfClass:[MADQueryViewController class]];
    BOOL pushing = fromIsQueryView;

    UIViewController *rightViewController;
    if (pushing) {
        rightViewController = [transitionContext viewControllerForKey:UITransitionContextToViewKey];
        leftViewController =
    } else {
        rightViewController = leftViewController;
    }
    
    UIView *containerView = transitionContext.containerView;
    UIView *tableViewQuery, *collectionViewGrid;

    UIViewController *leftController = [transitionContext viewControllerForKey: leftCntrollerKey(pushing)];
    UIViewController *toViewController = [transitionContext viewControllerForKey: rightControllerKey(pushing)];

    tableViewQuery = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextFromViewKey : UITransitionContextToViewKey];
    collectionViewGrid = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextToViewKey : UITransitionContextFromViewKey];
    
    CGRect queryFrameInital = [transitionContext initialFrameForViewController:fromViewController];
    
    CGRect toFrameInital = [transitionContext initialFrameForViewController:toViewController];
    CGRect fromFrameFinal = [transitionContext finalFrameForViewController:fromViewController];
    CGRect toFrameFinal = [transitionContext finalFrameForViewController:toViewController];
    
    CGVector offset;
    offset = CGVectorMake(1.f, 0.f);
    [containerView addSubview:toView];

    if (!fromIsQueryView) {
        
    } else {
        toView.frame = CGRectMake(toFrameFinal.origin.x + toFrameFinal.size.width, toFrameFinal.origin.y, toFrameFinal.size.width, toFrameFinal.size.height);
        toFrameFinal = CGRectMake(toFrameFinal.origin.x, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
    }
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    if (!fromIsQueryView) {
        
        MADWatermarkView *watermarkView;
        CGRect bounds = self.tableView.bounds;
        watermarkView = [[MADWatermarkView alloc] initWithFrame: bounds];
        watermarkView.alpha = 0.0;
        ((UITableView *)toView).backgroundView = watermarkView;

    } else {
        ((UITableView *)fromView).alpha = 1.0;
    }
   // toView.frame = toFrameFinal;
    [UIView animateWithDuration:transitionDuration animations:^{
        if (fromIsQueryView) {
            [((UITableView *)fromView).backgroundView setAlpha:0.0];
        } else {
            [((UITableView *)toView).backgroundView setAlpha:1.0];
        }
        //[toView setFrame:self.navigationController.view.bounds];
        
        fromView.frame = CGRectMake(fromFrameFinal.origin.x - fromFrameFinal.size.width, fromFrameFinal.origin.y, fromFrameFinal.size.width, fromFrameFinal.size.height);
        toView.frame = toFrameFinal;
    } completion:^(BOOL finished) {

        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        if (!wasCancelled) {

            if (fromIsQueryView) {
                [((UITableView *)fromView) setBackgroundView:nil];
            }

        }
        [transitionContext completeTransition:!wasCancelled];
    }];*/
}

#pragma mark - UIAccessibility

@end

@interface MADAnimatedTransitioningPop : NSObject <UIViewControllerAnimatedTransitioning>

@end

@implementation MADAnimatedTransitioningPop

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *leftViewController = [transitionContext viewControllerForKey: UITransitionContextToViewControllerKey];
    UIViewController *rightViewController = [transitionContext viewControllerForKey: UITransitionContextFromViewControllerKey];
    CGRect leftFrameFinal = [transitionContext finalFrameForViewController:leftViewController];
    CGRect rightFrameFinal = [transitionContext finalFrameForViewController:rightViewController];
    CGRect leftFrameInital = [transitionContext initialFrameForViewController:leftViewController];
    CGRect rightFrameInital = [transitionContext initialFrameForViewController:rightViewController];

    /*
    UIViewController *rightViewController;
    if (pushing) {
        rightViewController = [transitionContext viewControllerForKey:UITransitionContextToViewKey];
        leftViewController =
    } else {
        rightViewController = leftViewController;
    }
    
    UIView *containerView = transitionContext.containerView;
    UIView *tableViewQuery, *collectionViewGrid;
    
    //UIViewController *leftController = [transitionContext viewControllerForKey: leftCntrollerKey(pushing)];
    //UIViewController *toViewController = [transitionContext viewControllerForKey: rightControllerKey(pushing)];
    
    //tableViewQuery = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextFromViewKey : UITransitionContextToViewKey];
    //collectionViewGrid = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextToViewKey : UITransitionContextFromViewKey];
    
    CGRect queryFrameInital = [transitionContext initialFrameForViewController:fromViewController];
    
    leftFrameInital = CGRectMake(leftFrameFinal.origin.x, leftFrameFinal.origin.y, leftFrameFinal.size.width, leftFrameFinal.size.height);
    //[transitionContext initialFrameForViewController:toViewController];
    CGRect fromFrameFinal = [transitionContext finalFrameForViewController:fromViewController];
    CGRect toFrameFinal = [transitionContext finalFrameForViewController:toViewController];
    
    CGVector offset;
    offset = CGVectorMake(1.f, 0.f);
    [containerView addSubview:toView];
    
    if (!fromIsQueryView) {
        
    } else {
        toView.frame = CGRectMake(toFrameFinal.origin.x + toFrameFinal.size.width, toFrameFinal.origin.y, toFrameFinal.size.width, toFrameFinal.size.height);
        toFrameFinal = CGRectMake(toFrameFinal.origin.x, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
    }
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    if (!fromIsQueryView) {
        
        MADWatermarkView *watermarkView;
        CGRect bounds = self.tableView.bounds;
        watermarkView = [[MADWatermarkView alloc] initWithFrame: bounds];
        watermarkView.alpha = 0.0;
        ((UITableView *)toView).backgroundView = watermarkView;
        
    } else {
        ((UITableView *)fromView).alpha = 1.0;
    }*/
    // toView.frame = toFrameFinal;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        //if (fromIsQueryView) {
        //    [((UITableView *)fromView).backgroundView setAlpha:0.0];
        //} else {
        //    [((UITableView *)toView).backgroundView setAlpha:1.0];
        //}
        //[toView setFrame:self.navigationController.view.bounds];
        
        //fromView.frame = CGRectMake(fromFrameFinal.origin.x - fromFrameFinal.size.width, fromFrameFinal.origin.y, fromFrameFinal.size.width, fromFrameFinal.size.height);
        //toView.frame = toFrameFinal;
    } completion:^(BOOL finished) {
        
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        if (!wasCancelled) {
            
          //  if (fromIsQueryView) {
          //      [((UITableView *)fromView) setBackgroundView:nil];
          //  }
            
        }
        [transitionContext completeTransition:!wasCancelled];
    }];
}

@end

@interface MADAnimatedTransitioningPush : NSObject <UIViewControllerAnimatedTransitioning>

@end

@implementation MADAnimatedTransitioningPush

@end
