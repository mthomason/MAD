//
//  MUIViewControllerQueryBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryViewController.h"
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedResultsController.h>

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImage.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADQueryViewSectionDelegate.h"

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
#import <MAD/RptqUserCredentals+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDatabaseSchemaTable.h>

#import "MADNavigationBarTitleView.h"
#import "MADTabBarController.h"
#import "MTStoreKitController+Features.h"
#import "MADWatermarkView.h"

#import "MTQueryBuilderAddTableViewController.h"
#import "MTQueryBuilderAddGroupViewController.h"
#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import "MTQueryBuilderPredicateFormatViewController.h"

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryGroup.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MTTableController.h"

#import "MTQueryBuilderLinkBuilderViewController.h"

#import "MADTableViewHeader.h"

#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MTReportDesignerSectionLayoutSettingsViewController.h"

#import "MADNavigationController.h"

#import "MADViewControllerSQL.h"

#import "UIViewController+tabBarItem.h"

#import "NSParagraphStyle+CommonStyles.h"

#import "MADQueryViewDataSource.h"

#import "MADViewTableHeader+QueryViewSectionTypes.h"

#import "MADQueryBuilderAddGroupDelegate.h"
#import "NSAttributedString+QueryViewController.h"
#import "MADQueryViewControllerTableLayout.h"

#import "MADQueryViewControllerLayoutSectionSelectorProtocol.h"

#import "MADQueryViewDelegate.h"

NSString * const MNSIdentifierSegueShowAddTableViewController       = @"showAddTableViewController";
NSString * const MADImageBarButtonItemDatabase                      = @"UIBarButtonItemDatabase";
NSString * const MADImageBarButtonItemDatabase8                     = @"UIBarButtonItemDatabase8";
NSString * const MADSegueShowSql                                    = @"MADSegueShowSql";
NSString * const MNSIdentifierSegueShowAddLinkViewController        = @"showAddLinkViewController";
NSString * const MNSIdentifierSegueShowAddPredicateViewController   = @"showAddPredicateViewController";
NSString * const MNSIdentifierSegueShowAddGroupViewController       = @"showAddGroupViewController";
NSString * const MNSIdentifierSegueShowLayoutSettings               = @"showLayoutSettings";
NSString * const MNSIdentifierSegueShowAddDatabaseDrivers           = @"MNSIdentifierSegueShowAddDatabaseDrivers";

static NSString * const NSFetchedResultsCacheName                   = @"NSFetchedResultsCacheName";
static NSString * const NSFetchedResultsCacheTables                 = @"NSFetchedResultsCacheTables";
static NSString * const NSFetchedResultsCacheLinks                  = @"NSFetchedResultsCacheLinks";
static NSString * const NSFetchedResultsCacheGroups                 = @"NSFetchedResultsCacheGroups";
static NSString * const NSFetchedResultsCachePredicates             = @"NSFetchedResultsCachePredicates";

static NSString * const TextFormatConnection =  @"You are connecting to %1$@ datasource named %2$@.";

static NSString * const MADIdentifierDefaultsViewerDesired = @"defaults.everydayapps.features.viewer.desired";

static NSString * const ViewControllerTitle = @"MAD Query";

#pragma mark - Private Category

@interface MADQueryViewController()
    <NSFetchedResultsControllerDelegate,
        MADQueryViewDelegateProtocol,
        MADQueryViewControllerLayoutSectionSelectorProtocol,
        MTQueryBuilderAddLinkFirstTableDelegate,
        MTQueryBuilderAddTableDelegate,
        MADQueryBuilderAddGroupDelegate,
        MTViewControllerProtocol,
        MTQueryBuilderLinkBuilderDelegate,
        MTViewControllerProtocol,
        MTReportDesignerSectionLayoutSettingsDelegate,
        MTQueryBuilderPredicateFormatDelegate,
        MTTabBarImageProtocol,
        MADQueryViewControllerDatasourceProtocol>

    @property (nonatomic, strong) MADQueryViewDataSource *queryViewDataSource;
    @property (nonatomic, strong) MADQueryViewDelegate *queryViewDelegate;

    @property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

    @property (nonatomic, strong) UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, strong) UIBarButtonItem *barButtonItemDone;

    @property (nonatomic, assign) BOOL beganUpdates;
    @property (nonatomic, assign) BOOL toolbarIconShown;

    @property (nonatomic, assign) NSInteger lastSelectedRowNumber;

    @property (nonatomic, assign) CGFloat headerSectionHeight;

    @property (nonatomic, copy) MADQueryViewConfigureCell handleConfigureCell;

@end

BOOL storeEnabled(void);
BOOL storeEnabled() {
    return [MTStoreKitController sharedObject].reportingEnabled;
}

@implementation MADQueryViewController

@synthesize document = _document;

#pragma mark - Exit

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToQueryBuilder:);
}

- (UIViewController *)viewControllerForUnwindSegueAction: (SEL)action
                                      fromViewController: (UIViewController *)fromViewController
                                              withSender: (id)sender {
    
    return action == @selector(unwindToQueryBuilder:) ?
                        self :
                        [super viewControllerForUnwindSegueAction: action
                                               fromViewController: fromViewController
                                                       withSender: sender];
}

#pragma mark -
#pragma mark MADQueryViewDelegateProtocol

- (MADIdentifierQueryViewSections)sectionIdentifierForDisplayIndex:(short)displayIndex {
    return [_queryViewDataSource sectionAtIndex:displayIndex];
}

- (MADQueryViewSectionDelegate *)sectionLayoutForDisplayIndex:(short)displayIndex {
    return [_queryViewDataSource layoutAtIndex:displayIndex];
}

- (CGFloat)headerHeight {
    return _headerSectionHeight;
}

- (void)handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index {
    NSIndexPath *indexPathUpdate = [NSIndexPath indexPathForRow: index inSection: 0];
    RptqQueryTable *table = [_queryViewDataSource.queryTablesController objectAtIndexPath: indexPathUpdate];
    MADTableController *tableController = [self tableControllerForTable:table];
    [self.navigationController pushViewController: tableController animated: YES];
    
}

#pragma mark -
#pragma mark Static

+ (void)deleteCoreDataCache {
    //@autoreleasepool {
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
    //}
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        //@autoreleasepool {
            [MADQueryViewController deleteCoreDataCache];
        //}
    //});
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    [MADQueryViewController deleteCoreDataCache];
    
    if (self = [super initWithCoder:aDecoder]) {
        [self setToolbarIconShown:NO];
    }
    return self;
}

#pragma mark -
#pragma mark Property Overrides

- (void)setDocument:(MADocument *)document {
    if (_document == nil) {
        [self observeManagedObjectContextChanges:document.managedObjectContext];
    }
    _document = document;
}

#pragma mark -
#pragma mark CoreData

#pragma mark NSManagedObjectContext Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSLog(@"Updated objects: %@", updatedObjects.debugDescription);

    for (id updatedObject in updatedObjects) {
        
        // Update the query view controller data model when number of tables change.
        if ([updatedObject isKindOfClass:[RptqQuery class]]) {
            RptqQuery *query = updatedObject;

            
            NSDictionary <NSString *, id> *changes = [query changedValues];
            
            NSLog(@"Changed values: %@", changes.debugDescription);
            
            for (id change in changes) {
                if ([change isEqualToString:NSStringFromSelector(@selector(hasQueryTables))]) {
                    
                    MADQueryViewDataSource *dataSource;
                    dataSource = [[MADQueryViewDataSource alloc] initWithNumberOfTables: query.numberOfTables
                                                                       reportingEnabled: [MTStoreKitController sharedObject].reportingEnabled
                                                                    handleConfigureCell: _handleConfigureCell];
                    dataSource.datasoruce = self;
                    self.tableView.dataSource = dataSource;
                    self.queryViewDataSource = dataSource;
                }
            }
        }
    }
    
    
}

- (void)ingnoreManagedObjectContextChanges:(NSManagedObjectContext *)managedObjectContext {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextObjectsDidChangeNotification
                                                  object: managedObjectContext];
}

- (void)observeManagedObjectContextChanges:(NSManagedObjectContext *)managedObjectContext {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextDidChange:)
                                                 name: NSManagedObjectContextObjectsDidChangeNotification
                                               object: managedObjectContext];
}

#pragma mark - NSNotificationCenter

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)updateInterfaceForPerferedContentSizeCategory:(NSString *)category {
    
    if ([category isEqualToString: UIContentSizeCategoryExtraSmall]) {
        _headerSectionHeight = 24.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategorySmall]) {
        _headerSectionHeight = 26.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryMedium]) {
        _headerSectionHeight = 29.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryLarge]) {
        _headerSectionHeight = 32.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryExtraLarge]) {
        _headerSectionHeight = 34.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryExtraExtraLarge]) {
        _headerSectionHeight = 36.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryExtraExtraExtraLarge]) {
        _headerSectionHeight = 38.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityMedium]) {
        _headerSectionHeight = 40.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityLarge]) {
        _headerSectionHeight = 42.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraLarge]) {
        _headerSectionHeight = 44.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
        _headerSectionHeight = 46.0000f;
        
    } else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
        _headerSectionHeight = 48.0000f;
        
    } else {
        _headerSectionHeight = 29.0000f;
    }
}

#pragma mark - UIViewController

- (NSString *)title {
    return NSLocalizedString(ViewControllerTitle, ViewControllerTitle);
}

- (void)handleApplicationDidBecomeActive:(id)sender {
    @autoreleasepool {
        [MADQueryViewController deleteCoreDataCache];
    }
}

- (void)viewDidLoad {
    MADocument *document = self.document;
    NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    [super viewDidLoad];

    
    MADQueryViewDelegate *queryViewDelegate = [[MADQueryViewDelegate alloc] init];
    queryViewDelegate.delegate = self;

    self.tableView.delegate = queryViewDelegate;
    self.queryViewDelegate = queryViewDelegate;
    
    
    RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: document.managedObjectContext];
    RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
    RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
    
    MADQueryViewDataSource *dataSource;
    MADQueryViewConfigureCell handleConfigureCell;
    handleConfigureCell = ^(UITableViewCell *cell,
                            MADIdentifierQueryViewSections forSection,
                            NSInteger row) {
        [self configureCell:cell forSection:forSection andRow:row];
    };
    dataSource = [[MADQueryViewDataSource alloc] initWithNumberOfTables: rptqQuery.numberOfTables
                                                       reportingEnabled: [MTStoreKitController sharedObject].reportingEnabled
                                                    handleConfigureCell: handleConfigureCell];
    dataSource.datasoruce = self;
    self.handleConfigureCell = handleConfigureCell;
    
    self.tableView.dataSource = dataSource;
    self.queryViewDataSource = dataSource;
    
    MADWatermarkView *watermarkView;
    watermarkView = [[MADWatermarkView alloc] initWithFrame: self.tableView.bounds];
    self.tableView.backgroundView = watermarkView;
    
    NSString *sizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory.copy;
    [self updateInterfaceForPerferedContentSizeCategory: sizeCategory];
    
    SEL handleContentSizeCategoryDidChange =
                                        @selector(handleContentSizeCategoryDidChangeNotification:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: handleContentSizeCategoryDidChange
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    [self.tableView registerClass: [MADTableViewCellQueryTableName class]
           forCellReuseIdentifier: @"UITableViewCellTableName"];
    
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.navigationItem.prompt = nil;
    
    UIBarButtonItem *barButtonItem;
    barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                  target: self
                                                                  action: @selector(edit:)];
    
    self.barButtonItemEdit = barButtonItem;
    
    SEL resultHandler = @selector(handleApplicationDidBecomeActive:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: resultHandler
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];

    MADocument *document = self.document;
    self.navigationController.hidesBarsWhenVerticallyCompact = NO;

    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (document) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(documentStateChanged)
                                                     name: UIDocumentStateChangedNotification
                                                   object: document];
        [self observeManagedObjectContextChanges:document.managedObjectContext];
    }
    
    typeof(self.tabBarController) tabBarController = self.tabBarController;
    if (tabBarController) {
        [tabBarController enableTabBarItems];
        [tabBarController.navigationItem setRightBarButtonItem:self.barButtonItemEdit
                                                      animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    typeof(self.document) document = self.document;
    if (document) {
        [self ingnoreManagedObjectContextChanges:document.managedObjectContext];
        
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: UIDocumentStateChangedNotification
                                                      object: document];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.tabBarController.navigationItem setRightBarButtonItem:nil animated:animated];;
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
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
    if (self.firstTimeViewWillLayoutSubviews) {
        CGRect r = CGRectMake(CGPointZero.x, CGPointZero.y,
                              self.tableView.frame.size.width, 1.0000f);
        [self.tableView scrollRectToVisible: r animated: NO];
        
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: MADSegueShowSql]) {
        MADViewControllerSQL *viewController;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            viewController = (MADViewControllerSQL *)[(segue.destinationViewController) topViewController];
        } else {
            viewController = segue.destinationViewController;
        }
        MADocument *document = self.document;
        viewController.document = document;
        [self.tabBarController disableTabBarItems];
        
    } else if ([segue.identifier isEqualToString: MNSIdentifierSegueShowAddTableViewController]) {
        
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            if (navControl.topViewController) {
                if ([navControl.topViewController isKindOfClass:[MTQueryBuilderAddTableViewController class]]) {
                    
                    MTQueryBuilderAddTableViewController *tvc = (MTQueryBuilderAddTableViewController *)navControl.topViewController;
                    if (tvc) {
                        tvc.delegate = self;
                    }

                    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
                    NSString *key = NSStringFromSelector(@selector(name));
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: key
                                                                                     ascending: YES];
                    
                    request.sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];

                    MADocument *document = self.document;
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: document.managedObjectContext
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    tvc.fetchedResultsController = frc;
                }
            }
        }

    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowAddLinkViewController]) {
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            if (navControl.topViewController) {
                if ([navControl.topViewController isKindOfClass:[MTQueryBuilderLinkBuilderViewController class]]) {

                    MADocument *document = self.document;
                    MTQueryBuilderLinkBuilderViewController *tvc;
                    tvc = (MTQueryBuilderLinkBuilderViewController *)navControl.topViewController;
                    if (tvc) {
                        tvc.document = document;
                        tvc.queryLinkDelegate = self;
                    }
                }
            }
        }
    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowAddPredicateViewController]) {
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            //NSLog(@"Top View Controller: %@", [navControl topViewController]);
            if (navControl.topViewController) {
                if ([navControl.topViewController isKindOfClass:[MTQueryBuilderPredicateFormatViewController class]]) {
                    MTQueryBuilderPredicateFormatViewController *tvc;
                    tvc = (MTQueryBuilderPredicateFormatViewController *)navControl.topViewController;
                    if (tvc) {
                        MADocument *document = self.document;
                        tvc.document = document;
                        tvc.delegate = self;
                    }
                }
            }
        }
    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowAddGroupViewController]) {
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            if (navControl.topViewController) {
                if ([navControl.topViewController isKindOfClass:[MTQueryBuilderAddGroupViewController class]]) {
                    MTQueryBuilderAddGroupViewController *tvc;
                    tvc = (MTQueryBuilderAddGroupViewController *)navControl.topViewController;
                    if (tvc) {
                        MADocument *document = self.document;
                        tvc.document = document;
                        tvc.delegate = self;
                    }
                }
            }
        }
    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowLayoutSettings]) {
                if ([segue.destinationViewController isKindOfClass:[MTReportDesignerSectionLayoutSettingsViewController class]]) {
                    MTReportDesignerSectionLayoutSettingsViewController *tvc;
                    tvc = (MTReportDesignerSectionLayoutSettingsViewController *)segue.destinationViewController;
                    if (tvc) {
                        tvc.delegate = self;
                        MADocument *document = self.document;
                        RptqDocument *activeDocument = document.activeDocumentModel;
                        RptqQuery *query = activeDocument.defaultDatabase.defaultQuery;
                        
                        RptqDocumentSection *section = [activeDocument documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedRowNumber
                                                                                    withNumberOfGroups: query.hasQueryGroups.count];

                        
                        tvc.initalHeightValue = section.height.floatValue;
                        tvc.initalVisibility = section.visibility.boolValue;
                        tvc.initalNumberOfRows = section.numberOfRows.unsignedIntegerValue;
                    }
                }
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [self.tabBarController enableTabBarItems];
    [super dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        UIView *backgroundView = self.tableView.backgroundView;
        void (^ handleAnimate)(id <UIViewControllerTransitionCoordinatorContext>context);
        handleAnimate = ^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [backgroundView setNeedsDisplay];
        };
        [coordinator animateAlongsideTransition: handleAnimate completion: nil];
    }
    
}

#pragma mark - MTQueryBuilderPredicateFormatDelegate

- (void)addQueryPredicate:(RptqQueryPredicate *)predicate {
    [self dismissViewController];

    MADocument *document = self.document;
    [document.activeDocumentModel addPredicate:predicate];
    [document saveContext];
}

#pragma mark - MTReportDesignerSectionLayoutSettingsDelegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MADocument *document = self.document;
    [document.activeDocumentModel setHeight: height
                            forSectionAtRow: (NSUInteger)self.lastSelectedRowNumber];
    [document saveContext];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {

    MADocument *document = self.document;
    [document.activeDocumentModel setVisibility: isVisible
                                forSectionAtRow: (NSUInteger) self.lastSelectedRowNumber];
    [document saveContext];

}

- (void)layoutSettings:(MTReportDesignerSectionLayoutSettingsViewController *)layoutSettings
          newPageAfter:(BOOL)newPageAfter {

    MADocument *document = self.document;
    [document.activeDocumentModel setNewPageAfter: newPageAfter
                                  forSectionAtRow: (NSUInteger) self.lastSelectedRowNumber];
    [document saveContext];

}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {

    MADocument *document = self.document;
    [document.activeDocumentModel setNumberOfRows: numberOfRows
                                  forSectionAtRow: (NSUInteger) self.lastSelectedRowNumber];
    [document saveContext];

}

#pragma mark MUIViewControllerDelegate

- (void)dismissViewController {
    void (^handleCompletion)(void);
    MADTabBarController *tabBarController = self.tabBarController;
    handleCompletion = ^{ [tabBarController enableTabBarItems]; };
    [self dismissViewControllerAnimated:YES completion:handleCompletion];
}

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewController];
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewController];
}

#pragma mark - MTQueryBuilderLinkBuilderDelegate

- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)link {

    [self dismissViewController];

    MADocument *document = self.document;
    [document.activeDocumentModel addQueryLink:link];
    [document saveContext];
    
    NSInteger suspectedSection = 2;
    
    MADIdentifierQueryViewSections tableSection;
    tableSection = [self.queryViewDataSource sectionAtIndex:(short)suspectedSection];
    
    if (tableSection == MADIdentifierQueryViewSectionsLinks) {
        NSIndexSet *linksSection = [NSIndexSet indexSetWithIndex:(NSUInteger)suspectedSection];
        [self.tableView reloadSections: linksSection
                      withRowAnimation: UITableViewRowAnimationAutomatic];
    }
    
    [document saveToURL: document.fileURL
       forSaveOperation: UIDocumentSaveForOverwriting completionHandler:nil];
}

#pragma mark - MTQueryBuilderAddGroupDelegate

- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldID
                       andSortOrder:(MNSSortOrder)sortOrder {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   YES];
    [self.document addQueryGroupWithQueryField: queryFieldID
                                  andSortOrder: sortOrder];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   NO];

    [_queryViewDataSource performFetchGroups];
}

#pragma mark - MTQueryBuilderAddTableDelegate

- (void)viewControllerSchemaAddTableDidSelectTable:(NSManagedObjectID *)objectID {

    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   YES];
    [self.document addQuerySelectTableForSchemeTableWithObjectID:       objectID];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   NO];

    [_queryViewDataSource performFetchTables];
}

#pragma mark -
#pragma mark Helper

- (void)configureCell:(UITableViewCell *)cell forSection:(MADIdentifierQueryViewSections)section
               andRow:(NSInteger)row {
    
    switch (section) {
            
            // MARK: Display and identify the data source and data sources
        case MADIdentifierQueryViewSectionsDatasource: {
            
            RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
            if (database.ownedByUser) {
                
                id databaseType = database.ownedByUser.database_driver_type.copy;
                id schemaName = [database.ownedByUser copyDatabaseSchemaName];
                id localizedMessage = NSLocalizedString(TextFormatConnection, TextFormatConnection);
                id message = [NSAttributedString newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
                                                                                        databaseType: databaseType
                                                                                          schemaName: schemaName];
                
                cell.textLabel.attributedText = message;
                cell.detailTextLabel.text = @"";
                cell.tintColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];
                
            }
            cell.textLabel.numberOfLines = 0;
            break;
        }
            
            // MARK: Display the table names that are used in the query
        case MADIdentifierQueryViewSectionsTables: {
            
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.textLabel.font = font;
            cell.textLabel.backgroundColor = [UIColor whiteColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.indentationLevel = 1;
            cell.tintColor = [MADColorEverydayApps newColorBlue];
            cell.backgroundColor = [UIColor whiteColor];
            break;
        }
            
            // MARK: Display the table links or joins that are used in the query.
        case MADIdentifierQueryViewSectionsLinks:
            
            cell.textLabel.numberOfLines = 0;
            break;
            
            // MARK: Display the groupings used in the query.
        case MADIdentifierQueryViewSectionsGroups:

            cell.textLabel.numberOfLines = 0;
            break;
        
            
            // MARK: Display the predicates or conditions on the query.
        case MADIdentifierQueryViewSectionsPredicate:
            
            cell.textLabel.numberOfLines = 0;
            break;
            
        case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
            
            UISwitch *switchQueryMode = [[UISwitch alloc] initWithFrame:CGRectZero];
            switchQueryMode.on = [[NSUserDefaults standardUserDefaults] boolForKey:MADIdentifierDefaultsViewerDesired];
            [switchQueryMode addTarget: self action: @selector(handleToggleReportingMode:)
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

#pragma mark -
#pragma mark Event handlers

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
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MADIdentifierDefaultsViewerDesired];
    }
    
    // FIXME: This is a hack that I can do because I know this updates the last section in the query.  Kind of a hack.
    //  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:self.tableView.numberOfSections - 1];
    NSIndexPath *i = [NSIndexPath indexPathForItem:0 inSection:self.tableView.numberOfSections - 1];
    NSArray *paths = [[NSArray alloc] initWithObjects: i, nil];
    [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    //  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (MADIdentifierQueryViewSections)sectionPositionForTableSectionType:(MADIdentifierQueryViewSections)sec {
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

- (NSMutableArray *)sectionsUsedByFetchedResultsController:(NSFetchedResultsController *)controller {

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

    NSNumber *sectionNumber;
    if ([controller isEqual:self.queryViewDataSource.queryTablesController]) {
        
        sectionNumber = [[NSNumber alloc] initWithShort: [self sectionPositionForTableSectionType: MADIdentifierQueryViewSectionsTables]];
        [result addObject: sectionNumber];

    } else if ([controller isEqual:self.queryViewDataSource.queryLinksController]) {

        sectionNumber = [[NSNumber alloc] initWithShort: [self sectionPositionForTableSectionType: MADIdentifierQueryViewSectionsLinks]];
        [result addObject: sectionNumber];

    } else if ([controller isEqual:self.queryViewDataSource.queryGroupsController]) {

        short sectionGroup = [self sectionPositionForTableSectionType: MADIdentifierQueryViewSectionsGroups];
        sectionNumber = [[NSNumber alloc] initWithShort: sectionGroup];
        [result addObject: sectionNumber];
    
    } else if ([controller isEqual:self.queryViewDataSource.queryPredicatesController]) {
    
        short section = [self sectionPositionForTableSectionType: MADIdentifierQueryViewSectionsPredicate];
        sectionNumber = [[NSNumber alloc] initWithShort:section];
        [result addObject: sectionNumber];
    }
    
    return result;

}

- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex forChangeType: (NSFetchedResultsChangeType)type {

    
    NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
    
    for (NSNumber *section in sections) {
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
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
    
    NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
    
    for (NSNumber *section in sections) {
        MADIdentifierQueryViewSections updateSection = section.shortValue;
        
        NSIndexPath *path = [NSIndexPath indexPathForRow: indexPath.row
                                               inSection: updateSection];
        if (path) {
            if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
                NSArray *indexPaths = [[NSArray alloc] initWithObjects: path, nil];
                switch(type) {
                    case NSFetchedResultsChangeInsert: {
                        [self.tableView insertRowsAtIndexPaths: indexPaths
                                              withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeDelete: {
                        [self.tableView deleteRowsAtIndexPaths: indexPaths
                                              withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeUpdate: {
                        [self.tableView reloadRowsAtIndexPaths: indexPaths
                                              withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeMove: {
                        [self.tableView deleteRowsAtIndexPaths: indexPaths
                                              withRowAnimation: UITableViewRowAnimationFade];
                        [self.tableView insertRowsAtIndexPaths: indexPaths
                                              withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                }
            }
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableView beginUpdates];
        [self setBeganUpdates: YES];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates) {
        [self.tableView endUpdates];
    }
    [self setBeganUpdates:NO];
}

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

#pragma mark - Actions

- (IBAction)edit:(id)sender {
    
    BOOL editing = !self.tableView.isEditing;
    NSInteger systemType = !editing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
    id barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: systemType
                                                                     target: self
                                                                     action: @selector(edit:)];
    [self.tabBarController.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    self.barButtonItemEdit = barButtonItem;
    self.tableView.editing = editing;
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)addConnection:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddDatabaseDrivers
                              sender: sender];
    [self.tabBarController disableTabBarItems];
}

- (void)addTable:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddTableViewController
                              sender: sender];
    [self.tabBarController disableTabBarItems];
}

- (void)addLink:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddLinkViewController
                              sender: sender];
    [self.tabBarController disableTabBarItems];
}

- (void)addPredicate:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddPredicateViewController
                              sender: sender];
    [self.tabBarController disableTabBarItems];
}

- (void)addGroup:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddGroupViewController
                              sender: sender];
    [self.tabBarController disableTabBarItems];
}

#pragma mark - Helper functions

- (void)documentStateChanged {
    
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

- (void)enableUserInteraction {
    [self.tableView setUserInteractionEnabled:YES];
}

- (void)disableUserInteraction {
    [self.tableView setUserInteractionEnabled:NO];
}

- (void)reloadMainDocumentAnimated:(BOOL)animated {
    
    MADocument *reportDocument = self.document;
    NSAssert(reportDocument != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    if (reportDocument) {
        
        NSManagedObjectContext *managedObjectContext = reportDocument.managedObjectContext;
        
        NSFetchedResultsController * (^newFetchedResultsController)(NSString *, NSPredicate *, NSSortDescriptor *, id <NSFetchedResultsControllerDelegate>);
        newFetchedResultsController = ^NSFetchedResultsController *(NSString *entityName,
                                                                    NSPredicate *predicate,
                                                                    NSSortDescriptor *sortDescriptor,
                                                                    id <NSFetchedResultsControllerDelegate> delegate) {

            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            request.predicate = predicate;
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
            request.sortDescriptors = sortDescriptors;
            
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = delegate;
            return frc;
        };
        
        {
            RptqDatabase *database = reportDocument.activeDocumentModel.hasDatabaseSchemas.anyObject;
            RptqQuery *query = database.hasQueries.anyObject;
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            id predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", query.objectID];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"alias"
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, predicate, sortDescriptor, self);
            
            self.queryViewDataSource.queryTablesController = frc;
            [_queryViewDataSource performFetchTables];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"tableleft"
                                                                           ascending: YES];

            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            self.queryViewDataSource.queryLinksController = frc;
            [_queryViewDataSource performFetchLinks];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"weight"
                                                                           ascending: YES];

            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            self.queryViewDataSource.queryGroupsController = frc;
            [_queryViewDataSource performFetchGroups];
            frc = nil;
            
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fieldleftpred"
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            self.queryViewDataSource.queryPredicatesController = frc;
            [_queryViewDataSource performFetchPredicate];
            frc = nil;
        }
        [self.tableView reloadData];
    }
}

- (MADTableController *)tableControllerForTable:(RptqQueryTable *)table {
    RptqDatabaseSchemaTable *schemaTable = table.databaseSchemaTable;
    MTQuery *rquery = [[MTQuery alloc] initWithQueryType:MADQueryTypeSampleDataTable object:schemaTable];
    MADTableController *tableController = [[MADTableController alloc] initWithQuery:rquery];
    
    MADNavigationBarTitleView *sampleDataTitleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];

    sampleDataTitleView.text = schemaTable.name;
    
    tableController.navigationItem.title = schemaTable.name;
    tableController.navigationItem.titleView = sampleDataTitleView;
    return tableController;
}

- (NSArray <NSIndexPath *> *)deleteLinksRelatedToSectionIndex:(NSInteger)section
                                                        table:(NSManagedObjectID *)deleatedTableObjectId
                                                  inTableView:(UITableView *)tableView
                                                    inContext:(NSManagedObjectContext *)context {
    
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    
    NSFetchedResultsController *fetchedLinkes = self.queryViewDataSource.queryLinksController;
    
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
    
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = nil;
        NSManagedObject *object = nil;
        MADTableViewCellQueryLink *tableViewCellLink = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
        if (tableViewCellLink) {
            object = [context existingObjectWithID:tableViewCellLink.tableID error:&error];
        } else {
            
            id <NSFetchedResultsSectionInfo> sectionInfo = fetchedLinkes.sections[0];
            if (row < (NSInteger)sectionInfo.numberOfObjects) {
                NSIndexPath *testLinkIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
                object = [fetchedLinkes objectAtIndexPath:testLinkIndexPath];
            }
            
        }
        if (!error && object && [object isKindOfClass:[RptqQueryLinks class]]) {
            RptqQueryLinks *queryLink = (RptqQueryLinks *)object;
            if ([queryLink.hasLeftField.inQueryTable.objectID isEqual:deleatedTableObjectId] ||
                [queryLink.hasRightField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
                [context deleteObject:queryLink];
                
                [cellsToDelete addObject:linkIndexPath];
                
            }
        }
    }
    return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)deleteGroupsRelatedToSectionIndex:(NSInteger)section
                                                         table:(NSManagedObjectID *)deleatedTableObjectId
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
                if ([groupToRemove.hasField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
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
                                                            table: (NSManagedObjectID *)deleatedTableObjectId
                                                      inTableView: (UITableView *)tableView
                                                        inContext: (NSManagedObjectContext *)context {

    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];

    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {

        NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        
        MADTableViewCellQueryPredicate *tableViewCellPredicate;
        tableViewCellPredicate = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:predicateIndexPath];
        NSError *error = nil;
        NSManagedObject *object = nil;
        
        if (tableViewCellPredicate) {
            object = [context existingObjectWithID: tableViewCellPredicate.tableID
                                             error: &error];
        } else {
            NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row
                                                                     inSection: 0];
            object = [self.queryViewDataSource.queryPredicatesController objectAtIndexPath: testPredicateIndexPath];
        }
        
        if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
        
            RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;

            BOOL deleted = NO;
            if ([predicateToRemove.hasLeftField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {

                [context deleteObject:predicateToRemove];
                
                NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
                [cellsToDelete addObject:deleteCellAtIndex];
                deleted = YES;
            }
            
            if (!deleted) {
                if ([predicateToRemove.hasRightField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
                
                    [context deleteObject:predicateToRemove];

                    NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
                    [cellsToDelete addObject:deleteCellAtIndex];
                }
            }
        }
    }
    return cellsToDelete;
}

- (void)deleteQueryPredicateFromTableView: (UITableView *)tableView
                              atIndexPath: (NSIndexPath *)indexPath {
    MADocument *document = self.document;
    MADTableViewCellQueryPredicate *cell;
    cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *objid = cell.tableID;
    NSManagedObject *predicate = [document.managedObjectContext objectRegisteredForID:objid];
    [document.managedObjectContext deleteObject:predicate];
    [document.managedObjectContext save:nil];
}

- (void)reloadQueryViewData {
    [self.tableView reloadData];
}

- (void)deleteItemFromQuerySection:(MADIdentifierQueryViewSections)querySection
                     fromTableView:(UITableView *)tableView
                       atIndexPath:(NSIndexPath *)indexPath {
    
    switch (querySection) {
            
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
    self.suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [self observeManagedObjectContextChanges:private];
    
    private.parentContext = self.document.managedObjectContext;
    [private performBlockAndWait:^{
        
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
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
        RptqQueryTable *table = [self.queryViewDataSource.queryTablesController objectAtIndexPath: tableIndex];
        
        NSManagedObjectID *deleatedTableObjectId = table.objectID.copy;
        
        NSMutableSet *hasQueryTables = rptqQuery.hasQueryTables.mutableCopy;
        
        __block id objectToDelete = nil;
        void (^testHasQueryTables)(RptqQueryTable *, BOOL *);
        testHasQueryTables = ^(RptqQueryTable * _Nonnull hasTable, BOOL * _Nonnull stop) {
            if (table.identifier.unsignedIntegerValue == hasTable.identifier.unsignedIntegerValue) {
                objectToDelete = hasTable;
            }
        };
        [hasQueryTables enumerateObjectsUsingBlock:testHasQueryTables];
        [hasQueryTables removeObject:objectToDelete];
        rptqQuery.hasQueryTables = hasQueryTables.copy;
        
        numberOfTables--;
        
        __block short ctr = 0;
        NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
        void (^testIsOldIndex)(NSUInteger idx, BOOL *stop);
        testIsOldIndex = ^(NSUInteger idx, BOOL * _Nonnull stop) {
            if ([oldIndexes containsIndex:idx]) {
                [indexesToRemove addIndex:(NSUInteger)ctr];
            }
            ctr++;
        };
        [oldIndexesSectionTypes enumerateIndexesUsingBlock:testIsOldIndex];
        [tableView beginUpdates];
        
        MADocument *document =  self.document;
        [document deleteDatafieldsRelatedToTable:deleatedTableObjectId inContent:private];
        [document deleteAggregateFieldRelatedToTable:deleatedTableObjectId inContent:private];
        
        NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
        
        short numberOfSections = self.queryViewDataSource.count;
        
        for (short section = 0; section < numberOfSections; section++) {
            
            NSArray <NSIndexPath *> *cells = nil;
            
            switch ([self.queryViewDataSource sectionAtIndex:section]) {
                case MADIdentifierQueryViewSectionsLinks:
                    cells = [self deleteLinksRelatedToSectionIndex: (NSInteger)section
                                                             table: deleatedTableObjectId
                                                       inTableView: tableView
                                                         inContext: private];
                    break;
                    
                case MADIdentifierQueryViewSectionsGroups:
                    cells = [self deleteGroupsRelatedToSectionIndex: (NSInteger)section
                                                              table: deleatedTableObjectId
                                                        inTableView: tableView
                                                          inContext: private];
                    break;
                    
                case MADIdentifierQueryViewSectionsPredicate:
                    cells = [self deletePredicateRelatedToSectionIndex: (NSInteger)section
                                                                 table: deleatedTableObjectId
                                                           inTableView: tableView
                                                             inContext: private];
                    break;
                    
                default:
                    break;
            }
            if (cells) {
                [cellsToDelete addObjectsFromArray:cells];
            }
        }
        
        NSError * __autoreleasing *error = nil;
        BOOL success = [private save:error];
        if (success) {
            
            void (^updateTable)(void) = ^{
                
                NSArray <NSIndexPath *> *indexPaths;
                indexPaths = [[NSArray <NSIndexPath *> alloc] initWithObjects:indexPath, nil];
                if (indexesToRemove.count > 0) {
                    [tableView deleteSections: indexesToRemove
                             withRowAnimation: UITableViewRowAnimationAutomatic];
                    [tableView deleteRowsAtIndexPaths: indexPaths
                                     withRowAnimation: UITableViewRowAnimationAutomatic];
                } else {
                    [tableView deleteRowsAtIndexPaths: indexPaths
                                     withRowAnimation: UITableViewRowAnimationAutomatic];
                }
                
                if (cellsToDelete.count) {
                    [tableView deleteRowsAtIndexPaths: cellsToDelete
                                     withRowAnimation: UITableViewRowAnimationAutomatic];
                }
                
                [tableView endUpdates];
                
                [self ingnoreManagedObjectContextChanges:private];
                
                self.suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
                
            };
            [[NSOperationQueue mainQueue] addOperationWithBlock:updateTable];
        }
        
    }];
}

- (void)deleteQueryLinksFromTableView: (UITableView *)tableView
                          atIndexPath: (NSIndexPath *)indexPath {
    
    MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *tableID = cell.tableID;
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    void (^deleteLinks)(void) = ^{
        
        NSManagedObject *table = [private objectRegisteredForID:tableID];
        [private deleteObject:table];
        
        NSError * __autoreleasing *error = nil;
        [private save:error];
        
    };
    
    [private performBlockAndWait:deleteLinks];
}

- (void)deleteQueryGroupFromTableView: (UITableView *)tableView
                          atIndexPath: (NSIndexPath *)indexPath {
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    void (^deleteGroup)(void) = ^{
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
        RptqQueryGroup *groupToRemove = [rptqQuery queryGroupForIndex:(NSUInteger)indexPath.row];
        [self.document removeGroupWitObjectID:groupToRemove.objectID fromManagedObjectContext:private];
        
        NSError * __autoreleasing * error = NULL;
        [private save:error];
    };
    [private performBlockAndWait:deleteGroup];
}

#pragma mark - UIAccessibility

- (BOOL)accessibilityPerformEscape {
    [self.delegate viewControllerDidFinish:nil];
    return YES;
}

@end
