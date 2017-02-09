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

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIStoryboard.h>

#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSFetchRequestExpression.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSPersistentStoreResult.h>

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

static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing);
static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing);

static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing) {
    return pushing ? UITransitionContextFromViewControllerKey :
                     UITransitionContextToViewControllerKey;
}
static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing) {
    return pushing ? UITransitionContextToViewControllerKey :
                     UITransitionContextFromViewControllerKey;
}

#pragma mark - Private Category

@interface MADQueryViewController ()

    <NSFetchedResultsControllerDelegate,
        MADQueryViewDelegateProtocol,
        MADQueryViewControllerLayoutSectionSelectorProtocol,
        MTQueryBuilderAddLinkFirstTableDelegate,
        MTQueryBuilderAddTableDelegate,
        MADQueryBuilderAddGroupDelegate,
        MADViewControllerStandardProtocol,
        MTQueryBuilderLinkBuilderDelegate,
        MADViewControllerStandardProtocol,
        MADDesignerSectionLayoutDelegate,
        MTQueryBuilderPredicateFormatDelegate,
        MADQueryViewControllerDatasourceProtocol,
        UIViewControllerTransitioningDelegate>

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

    @property (nonatomic, strong) MADQueryViewCellConfigureHandler handleConfigureCell;

    @property (nonatomic, readonly) MADTabBarController *tabBarController;

@end

BOOL storeEnabled(void);
BOOL storeEnabled() {
    return [MTStoreKitController sharedObject].reportingEnabled;
}

@implementation MADQueryViewController

@synthesize title = _title;
@synthesize document = _document;
//@synthesize managedObjectContext = _managedObjectContext;

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

    //if (_handleConfigureCell) _handleConfigureCell = NULL;
    //if (_queryViewDelegate) _queryViewDelegate.delegate = nil;
    //if (_queryViewDataSource) _queryViewDataSource.datasoruce = nil;
    if (_barButtonItemEdit) _barButtonItemEdit = nil;
    if (_barButtonItemDone) _barButtonItemDone = nil;
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

- (void)handleApplicationDidBecomeActive:(id)sender {
    [MADQueryViewController deleteCoreDataCache];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *sizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory.copy;
    [self updateInupdateInterfaceForPerferedContentSizeCategory: sizeCategory];
    
    static NSString *MADIdentifierTableViewCellTableName = @"MADIdentifierCellSchemaName";
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
  
    self.tableView.delegate = _queryViewDelegate;
    self.tableView.dataSource = self.queryViewDataSource;
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
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    [self.navigationItem setLeftBarButtonItem:nil animated:animated];
    [self.navigationItem setRightBarButtonItem:nil animated:animated];
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
                    NSSortDescriptor *sort;
                    sort = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(name))
                                                         ascending: YES];
                    
                    request.sortDescriptors = [[NSArray alloc] initWithObjects:sort, nil];

                    MADocument *document = self.document;
                    NSFetchedResultsController *frc;
                    frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
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
                if ([segue.destinationViewController isKindOfClass:[MADDesignerSectionLayoutController class]]) {
                    MADDesignerSectionLayoutController *tvc;
                    tvc = (MADDesignerSectionLayoutController *)segue.destinationViewController;
                    if (tvc) {
                        tvc.delegate = self;
                        MADocument *document = self.document;
                        RptqDocument *activeDocument = document.activeDocumentModel;
                        RptqQuery *query = activeDocument.defaultDatabase.defaultQuery;
                        
                        RptqDocumentSection *section = [activeDocument documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedRowNumber
                                                                                    withNumberOfGroups: query.hasQueryGroups.count];

                        
                        tvc.initalHeightValue = section.height;
                        tvc.initalVisibility = section.visibility;
                        tvc.initalNumberOfRows = section.numberOfRows;
                    }
                }
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [self.tabBarController enableTabBarItems];
    [super dismissViewControllerAnimated:YES completion:nil];
}

//- (BOOL)animateAlongsideTransition:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
//                        completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion {
    
//}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.view.frame = self.navigationController.view.bounds;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
}

/*- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
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
        UIView *toView = [context viewForKey:UITransitionContextToViewKey];
        UIView *fromView = [context viewForKey:UITransitionContextFromViewKey];
        UIViewController *toViewController = [context viewForKey:UITransitionContextToViewControllerKey];
        UIViewController *fromViewController = [context viewForKey:UITransitionContextFromViewControllerKey];
        //[backgroundView setNeedsDisplay];
        [titleView sizeToFit];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [titleView sizeToFit];
    }];
    
}*/

/*- (void)viewWillTransitionToSize:(CGSize)size
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
    
}*/

#pragma mark -
#pragma mark Property Overrides

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

- (NSString *)title {
    if (_title == nil) {
        NSString *title = NSLocalizedString(ViewControllerTitle, ViewControllerTitle);
        _title = title.copy;
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

#pragma mark - MTQueryBuilderPredicateFormatDelegate

- (void)addQueryPredicate:(RptqQueryPredicate *)predicate {
    [self dismissViewController];

    MADocument *document = self.document;
    [document.activeDocumentModel addPredicate:predicate];
    [document saveContext];
}

#pragma mark - MADDesignerSectionLayoutDelegate

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

- (void)layoutSettings:(MADDesignerSectionLayoutController *)layoutSettings
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
                       andSortOrder:(MADSortOrder)sortOrder {
    
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

- (IBAction)done:(id)sender {
    [((MADNavigationController *)self.navigationController) done:sender];
    //[self dismissViewControllerAnimated:YES completion:^{
        
    //}];
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
        
        
        NSFetchedResultsController * (^newFetchedResultsController)(NSString *,
                                                                    NSPredicate *,
                                                                    NSSortDescriptor *,
                                                                    id <NSFetchedResultsControllerDelegate>,
                                                                    NSManagedObjectContext *);
        newFetchedResultsController = ^NSFetchedResultsController *(NSString *entityName,
                                                                    NSPredicate *predicate,
                                                                    NSSortDescriptor *sortDescriptor,
                                                                    id <NSFetchedResultsControllerDelegate> delegate,
                                                                    NSManagedObjectContext *managedObjectContext) {

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
        NSManagedObjectContext *context;
        context = reportDocument.documentModel.managedObjectContext;
        MADQueryViewDataSource *queryViewDataSource = self.queryViewDataSource;
        
        {
            //managedObjectContext = reportDocument.documentModel.managedObjectContext;
            NSManagedObjectID *objectID;
            objectID = reportDocument.documentModel.databases.firstObject.queries.firstObject.objectID.copy;
            
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            
            NSString *key = NSStringFromSelector(@selector(alias));
            NSString *keyInQuery = NSStringFromSelector(@selector(inQuery));
            NSString *format = [keyInQuery stringByAppendingString:@" == %@"];
            id predicate = [NSPredicate predicateWithFormat:format, objectID];
            NSSortDescriptor *sortDescriptor;
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                         ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, predicate, sortDescriptor, self, context);
            
            queryViewDataSource.queryTablesController = frc;
            [queryViewDataSource performFetchTables];
            frc = nil;
        }
        
        {
            NSString *key = NSStringFromSelector(@selector(tableLeftID));
            NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
            NSSortDescriptor *sortDescriptor;
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                         ascending: YES];

            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self, context);
            queryViewDataSource.queryLinksController = frc;
            [queryViewDataSource performFetchLinks];
            frc = nil;
        }
        
        {
            NSString *key = NSStringFromSelector(@selector(weight));
            NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
            NSSortDescriptor *sortDescriptor;
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                         ascending: YES];

            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self, context);
            queryViewDataSource.queryGroupsController = frc;
            [queryViewDataSource performFetchGroups];
            frc = nil;
            
        }
        
        {
            NSString *key = NSStringFromSelector(@selector(leftFieldID));
            NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self, context);
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
        NSError *error = NULL;
        NSManagedObject *object = nil;
        MADTableViewCellQueryLink *tableViewCellLink;
        tableViewCellLink = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
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
    NSManagedObject *predicate = [document.managedObjectContext objectWithID:objid];
    [document.managedObjectContext deleteObject:predicate];
    [document.managedObjectContext save:nil];
}

- (void)reloadQueryViewData {
    //NSLog(@"Reload query view data.");
    //[self.tableView reloadData];
}

- (void)deleteItemFromQuerySection:(MADIdentifierQueryViewSections)querySection
                     fromTableView:(UITableView *)tableView
                       atIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"Delete item %ld from section %ld-%hd.", indexPath.item, indexPath.section, querySection);
    
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
        
    NSError * __autoreleasing *error = nil;
    BOOL success = [context save:error];
    //success = [private.parentContext save:error];
    if (success) {
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
        
        self.suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
        
        //}];
    }
    
    //}];
}

- (void)deleteQueryLinksFromTableView: (UITableView *)tableView
                          atIndexPath: (NSIndexPath *)indexPath {
    
    MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *tableID = cell.tableID;
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    [private performBlockAndWait:^{
        
        NSManagedObject *table = [private objectWithID:tableID];
        NSAssert(table != nil, @"Need a non-nil value for %@", tableID);
        [private deleteObject:table];
        
        NSError * __autoreleasing *error = nil;
        [private save:error];
        
    }];
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

- (void)ingnoreManagedObjectContextChanges:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextObjectsDidChangeNotification
                                                  object: context];
}

- (void)observeManagedObjectContextChanges:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextDidChange:)
                                                 name: NSManagedObjectContextObjectsDidChangeNotification
                                               object: context];
}

#pragma mark NSNotificationCenter

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInupdateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)updateInupdateInterfaceForPerferedContentSizeCategory:(NSString *)category {
    _headerSectionHeight = [self.class SizeCategoryHeight:category];
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

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
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

/*- (BOOL)accessibilityPerformEscape {
    [self.delegate viewControllerDidFinish:nil];
    return YES;
}*/

@end

@interface MADAnimatedTransitioningPop : NSObject <UIViewControllerAnimatedTransitioning>

@end

@implementation MADAnimatedTransitioningPop

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

//static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing);
//static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing);

//static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing) {
//    return pushing ? UITransitionContextFromViewControllerKey : UITransitionContextToViewControllerKey;
//}
//static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing) {
//    return pushing ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey;
//}

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
