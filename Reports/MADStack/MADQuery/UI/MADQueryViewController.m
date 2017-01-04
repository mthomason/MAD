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
#import "MADTabBarItemProtocol.h"

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
        MADViewControllerStandardProtocol,
        MTQueryBuilderLinkBuilderDelegate,
        MADViewControllerStandardProtocol,
        MTReportDesignerSectionLayoutSettingsDelegate,
        MTQueryBuilderPredicateFormatDelegate,
        MADQueryViewControllerDatasourceProtocol>

    @property (nonatomic, assign) BOOL firstTimeViewWillLayoutSubviews;

    @property (nonatomic, assign) NSInteger lastSelectedRowNumber;

    @property (nonatomic, assign) CGFloat headerSectionHeight;

    @property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;
    @property (nonatomic, assign) BOOL beganUpdates;
    @property (nonatomic, assign) BOOL toolbarIconShown;


    @property (nonatomic, strong) MADQueryViewDataSource *queryViewDataSource;
    @property (nonatomic, strong) MADQueryViewDelegate *queryViewDelegate;

    @property (nonatomic, strong) UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, strong) UIBarButtonItem *barButtonItemDone;

    @property (nonatomic, copy) MADQueryViewCellConfigureHandler handleConfigureCell;

    @property (readonly) MADTabBarController *tabBarController;

@end

BOOL storeEnabled(void);
BOOL storeEnabled() {
    return [MTStoreKitController sharedObject].reportingEnabled;
}

@implementation MADQueryViewController

@synthesize document = _document;
@synthesize title = _title;

#pragma mark -
#pragma mark Static

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
    id result;
    result = action == @selector(unwindToQueryBuilder:) ?
            self : [super viewControllerForUnwindSegueAction: action
                                          fromViewController: fromViewController
                                                  withSender: sender];
    return result;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    
    _queryViewDelegate.delegate = nil;
    _queryViewDataSource.datasoruce = nil;

    [MADQueryViewController deleteCoreDataCache];

    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    [MADQueryViewController deleteCoreDataCache];
    
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;

    _toolbarIconShown = NO;
    _firstTimeViewWillLayoutSubviews = NO;

    UIBarButtonItem *barButtonItemEdit, *barButtonItemDone;
    barButtonItemEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                      target: self
                                                                      action: @selector(edit:)];
    self.barButtonItemEdit = barButtonItemEdit;
    
    barButtonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                      target: self
                                                                      action: @selector(edit:)];
    self.barButtonItemDone = barButtonItemDone;
    
    MADQueryViewDelegate *queryViewDelegate = [[MADQueryViewDelegate alloc] init];
    queryViewDelegate.delegate = self;
    self.queryViewDelegate = queryViewDelegate;
    
    MADQueryViewCellConfigureHandler handleConfigureCell;
    handleConfigureCell = ^(UITableViewCell *cell,
                            MADIdentifierQueryViewSections forSection,
                            NSInteger row) {
        
        [MADQueryViewController ConfigureCell: cell
                                   forSection: forSection
                                       andRow: row];
        
    };
    self.handleConfigureCell = handleConfigureCell;
    
    return self;
}

#pragma mark -
#pragma mark Property Overrides

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

#pragma mark - NSNotificationCenter

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInupdateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)updateInupdateInterfaceForPerferedContentSizeCategory:(NSString *)category {
    _headerSectionHeight = [self.class SizeCategoryHeight:category];
}

#pragma mark - UIViewController

- (NSString *)title {
    if (_title == nil) {
        NSString *title = NSLocalizedString(ViewControllerTitle, ViewControllerTitle);
        _title = title.copy;
    }
    return _title;
}

- (MADQueryViewDataSource *)queryViewDataSource {

    if (_queryViewDataSource == nil) {
        NSManagedObjectContext *managedObjectContext;
        NSSet *hasDatabaseSchemas, *hasQueries, *hasQueryTables;
        RptqDocument *rptqDocument;
        RptqDatabase *rptqDatabase;
        RptqQuery *rptqQuery;
        
        managedObjectContext = _document.managedObjectContext;
        rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: managedObjectContext];
        hasDatabaseSchemas = rptqDocument.hasDatabaseSchemas;
        rptqDatabase = hasDatabaseSchemas.anyObject;
        hasQueries = rptqDatabase.hasQueries;
        rptqQuery = hasQueries.anyObject;
        hasQueryTables = rptqQuery.hasQueryTables;
        
        MADQueryViewDataSource *dataSource;
        dataSource = [[MADQueryViewDataSource alloc] initWithNumberOfTables: hasQueryTables.count
                                                           reportingEnabled: [MTStoreKitController sharedObject].reportingEnabled
                                                        handleConfigureCell: _handleConfigureCell];
        
        dataSource.datasoruce = self;
        
        _queryViewDataSource = dataSource;
    }
    return _queryViewDataSource;
}

- (void)handleApplicationDidBecomeActive:(id)sender {
    [MADQueryViewController deleteCoreDataCache];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADocument *document = self.document;
    //NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    if (document == nil) {
        return;
    }
    


    UITableView *tableView = self.tableView;
    tableView.delegate = _queryViewDelegate;
    tableView.dataSource = self.queryViewDataSource;
    
    MADWatermarkView *watermarkView;
    CGRect bounds = tableView.bounds;
    watermarkView = [[MADWatermarkView alloc] initWithFrame: bounds];
    tableView.backgroundView = watermarkView;
    
    NSString *sizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory.copy;
    [self updateInupdateInterfaceForPerferedContentSizeCategory: sizeCategory];
    
    static NSString *MADIdentifierTableViewCellTableName = @"UITableViewCellTableName";
    [self.tableView registerClass: [MADTableViewCellQueryTableName class] forCellReuseIdentifier: MADIdentifierTableViewCellTableName];
    
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.navigationItem.prompt = nil;


}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    UIManagedDocument *document;
    NSManagedObjectContext *managedObjectContext;
    
    document = _document;
    managedObjectContext = document.managedObjectContext;
    
    //self.navigationController.hidesBarsWhenVerticallyCompact = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(documentStateChanged)
                                                 name: UIDocumentStateChangedNotification
                                               object: document];
    
    SEL handleContentSizeCategoryDidChange = @selector(handleContentSizeCategoryDidChangeNotification:);
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
    
    id barButtonItem = self.barButtonItemEdit;
    [self.tabBarController.navigationItem setRightBarButtonItem: barButtonItem
                                                  animated: NO];
    
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.tabBarController.navigationItem setRightBarButtonItem:nil animated:animated];;
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
        self.firstTimeViewWillLayoutSubviews = NO;
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

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];

    //short circuit
    if (!self.isViewLoaded) return;
    
    UITableView *tableView;
    UINavigationItem *navigationItem;
    UIView __weak *backgroundView, __weak *titleView;
    
    tableView = self.tableView;
    navigationItem = self.navigationItem;
    backgroundView = tableView.backgroundView;
    titleView = navigationItem.titleView;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [backgroundView setNeedsDisplay];
        [titleView sizeToFit];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [titleView sizeToFit];
    }];
    
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (CGSizeEqualToSize(size, self.view.bounds.size)) return;
    
    UIView __weak *backgroundView;
    backgroundView = self.tableView.backgroundView;
    
    void (^ handleAnimate)(id <UIViewControllerTransitionCoordinatorContext>context);
    handleAnimate = ^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [backgroundView setNeedsDisplay];
    };
    [coordinator animateAlongsideTransition: handleAnimate completion: nil];
    
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

    [self.queryViewDataSource performFetchGroups];
}

#pragma mark - MTQueryBuilderAddTableDelegate

- (void)viewControllerSchemaAddTableDidSelectTable:(NSManagedObjectID *)objectID {

    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   YES];
    [self.document addQuerySelectTableForSchemeTableWithObjectID:       objectID];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   NO];

    [self.queryViewDataSource performFetchTables];
}

#pragma mark -
#pragma mark Helper

+ (void)ConfigureCell: (UITableViewCell *)cell
           forSection: (MADIdentifierQueryViewSections)section
               andRow: (NSInteger)row {
    
    switch (section) {
            
            // MARK: Display and identify the data source and data sources
        case MADIdentifierQueryViewSectionsDatasource: {
            cell.detailTextLabel.text = @"";
            cell.tintColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];
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
    
    BOOL editing;
    id barButtonItem;
    
    editing = !self.tableView.isEditing;
    
    barButtonItem = !editing ? self.barButtonItemEdit : self.barButtonItemDone;
    [self.tabBarController.navigationItem setRightBarButtonItem:barButtonItem animated:YES];

    self.tableView.editing = editing;

}

/*- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}*/

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
        
        MADQueryViewDataSource *queryViewDataSource = self.queryViewDataSource;
        
        {
            RptqDatabase *database = reportDocument.activeDocumentModel.hasDatabaseSchemas.anyObject;
            RptqQuery *query = database.hasQueries.anyObject;
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            
            id predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", query.objectID];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"alias"
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, predicate, sortDescriptor, self);
            
            queryViewDataSource.queryTablesController = frc;
            [queryViewDataSource performFetchTables];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"tableleft"
                                                                           ascending: YES];

            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            queryViewDataSource.queryLinksController = frc;
            [queryViewDataSource performFetchLinks];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"weight"
                                                                           ascending: YES];

            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            queryViewDataSource.queryGroupsController = frc;
            [queryViewDataSource performFetchGroups];
            frc = nil;
            
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fieldleftpred"
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            queryViewDataSource.queryPredicatesController = frc;
            [queryViewDataSource performFetchPredicate];
            frc = nil;
        }
        [self.tableView reloadData];
    }
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
    
    NSIndexPath *indexPathUpdate;
    MADTableController *tableController;
    MADLabelTitle *titleView;
    RptqQueryTable *table, *tableWrapped;
    MTQuery *rquery;
    RptqDatabaseSchemaTable *schemaTable;
    NSString *name;
    NSFetchedResultsController *queryTablesResultsController;
    MADQueryViewDataSource *queryViewDataSource;
    
    indexPathUpdate = [NSIndexPath indexPathForRow: index inSection: 0];
    queryViewDataSource = self.queryViewDataSource;
    queryTablesResultsController = queryViewDataSource.queryTablesController;
    
    tableWrapped = [queryTablesResultsController objectAtIndexPath: indexPathUpdate];
    
    table = tableWrapped.copy;
    schemaTable = table.databaseSchemaTable.copy;
    
    rquery = [[MTQuery alloc] initWithQueryType:MADQueryTypeSampleDataTable object:schemaTable];
    tableController = [[MADTableController alloc] initWithQuery:rquery];
    
    titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
    
    name = schemaTable.name;
    titleView.text = name.copy;
    
    tableController.navigationItem.title = name.copy;
    tableController.navigationItem.titleView = titleView;
    
    [self.navigationController pushViewController: tableController animated: YES];
    
}


#pragma mark -
#pragma mark CoreData

#pragma mark NSManagedObjectContext Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {

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
            NSUInteger numberOfTables = query.numberOfTables;
            for (id change in changes) {
                if ([change isEqualToString: selectorHasQueryTables]) {
                    
                    MADQueryViewDataSource *dataSource;
                    dataSource = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
                                                                       reportingEnabled: reportingEnabled
                                                                    handleConfigureCell: _handleConfigureCell];
                    dataSource.datasoruce = self;
                    self.tableView.dataSource = dataSource;
                    self.queryViewDataSource.datasoruce = nil;
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

#pragma mark - UIAccessibility

/*- (BOOL)accessibilityPerformEscape {
    [self.delegate viewControllerDidFinish:nil];
    return YES;
}*/

@end
