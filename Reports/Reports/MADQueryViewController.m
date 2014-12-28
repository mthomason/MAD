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

#import "MADNavigationBarTitleView.h"
#import "AppDelegate.h"
#import "MADocument.h"

#import "MADWatermarkView.h"

#import "MTApplicationInstance.h"

#import "MTQuery.h"
#import "MTQueryBuilderAddTableViewController.h"
#import "MTQueryBuilderAddGroupViewController.h"
#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import "MTQueryBuilderPredicateFormatViewController.h"

#import "UITableViewCellInstruction.h"
#import "UITableViewCellTableName.h"
#import "UITableViewCellQueryLink.h"
#import "UITableViewCellOverride.h"
#import "UITableViewCellQueryInput.h"
#import "UITableViewCellQueryGroup.h"
#import "MTTableViewCellQueryPredicate.h"
#import "MTTableController.h"
#import "MTTableLayout.h"

#import "MTDataFormatter.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MTQueryBuilderLinkBuilderViewController.h"

#import "MADDesignerViewController.h"

#import "MTViewTableHeader.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTNavigationController.h"
#import "MTShowSqlViewController.h"

#import "UIDevice+Hack.h"
#import "UIColor+EverydayApps.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentObject.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"

#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectAggregate.h"

#import "UIViewController+tabBarItem.h"

#import "MTQueryTest.h"

#import "NSManagedObject+Extras.h"
#import "NSParagraphStyle+CommonStyles.h"

#import "UIViewController+UI.h"
#import "MACloudManager.h"

#import "MADNavigationBarTitleView.h"

typedef NS_ENUM(NSUInteger, MTQuerySections) {
    MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
    MTQuerySectionsTables = 2,
    MTQuerySectionsLinks = 3,
    MTQuerySectionsGroups = 4,
    MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6
};

NSString * const MNSIdentifierSegueShowAddTableViewController       = @"showAddTableViewController";
NSString * const MADImageBarButtonItemDatabase                      = @"UIBarButtonItemDatabase";
NSString * const MADImageBarButtonItemDatabase8                     = @"UIBarButtonItemDatabase8";
NSString * const MTSegueCloseDesigner                               = @"MTSegueCloseDesigner";
NSString * const NSFetchedResultsCacheName                          = @"NSFetchedResultsCacheName";
NSString * const NSFetchedResultsCacheTables                        = @"NSFetchedResultsCacheTables";
NSString * const NSFetchedResultsCacheLinks                         = @"NSFetchedResultsCacheLinks";
NSString * const NSFetchedResultsCacheGroups                        = @"NSFetchedResultsCacheGroups";
NSString * const NSFetchedResultsCachePredicates                    = @"NSFetchedResultsCachePredicates";
NSString * const MNSSegueShowSql                                    = @"MNSSegueShowSql";
NSString * const MTTableHeaderSectionKey                            = @"MTTableHeaderSectionKey";
NSString * const MTTableSectionRowKey                               = @"MTTableSectionRowKey";
NSString * const MTTableSectionRowHeightKey                         = @"MTTableSectionRowHeightKey";
NSString * const MTTableSectionSectionsKey                          = @"MTTableSectionSectionsKey";
NSString * const MNSIdentifierSegueShowAddLinkViewController        = @"showAddLinkViewController";
NSString * const MNSIdentifierSegueShowAddPredicateViewController   = @"showAddPredicateViewController";
NSString * const MNSIdentifierSegueShowAddGroupViewController       = @"showAddGroupViewController";
NSString * const MNSIdentifierSegueShowLayoutSettings               = @"showLayoutSettings";
NSString * const MNSIdentifierSegueShowAddDatabaseDrivers           = @"MNSIdentifierSegueShowAddDatabaseDrivers";

#pragma mark - Private Category

@interface MADQueryViewController()
    <UITableViewDataSource,
        UITableViewDelegate,
        NSFetchedResultsControllerDelegate,
        MTQueryBuilderAddLinkFirstTableDelegate,
        MTQueryBuilderAddTableDelegate,
        MTQueryBuilderAddGroupDelegate,
        MTViewControllerProtocol,
        MTQueryBuilderLinkBuilderDelegate,
        MTViewControllerProtocol,
        MTReportDesignerSectionLayoutSettingsDelegate,
        MTQueryBuilderPredicateFormatDelegate,
        MTTabBarImageProtocol>

@property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemShowSQL;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemDone;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsControllerTables;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsControllerLinks;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsControllerGroups;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsControllerPredicates;

@property (nonatomic, assign) BOOL beganUpdates;
@property (nonatomic, assign) BOOL toolbarIconShown;

@property (atomic, assign) NSInteger lastSelectedRowNumber;

@property (nonatomic, assign) CGFloat headerSectionHeight;

@property (nonatomic, assign) BOOL firstTimeTablePosition;

- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)sec;
- (NSUInteger)sectionPositionForTableSectionType:(MTQuerySections)sec;

@end

@implementation MADQueryViewController

#pragma mark - UIStateRestore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.document = [AppDelegate app].openDocument;
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark - Exit

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToQueryBuilder:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToQueryBuilder:) ?
                        self :
                        [super viewControllerForUnwindSegueAction: action
                                               fromViewController: fromViewController
                                                       withSender: sender];
}

#pragma mark - NSObject

- (void)dealloc {
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIContentSizeCategoryDidChangeNotification
                                                  object: nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [self setToolbarIconShown:NO];
        
    }
    return self;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                            CGSizeZero.width,
                                                            self.bottomLayoutGuide.length,
                                                            CGSizeZero.width);
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                   CGSizeZero.width,
                                                   self.bottomLayoutGuide.length,
                                                   CGSizeZero.width);
}

- (void)viewDidLayoutSubviews {
    if (self.firstTimeTablePosition == NO) {
        self.firstTimeTablePosition = YES;
        CGRect r = CGRectMake(CGPointZero.x,
                              CGPointZero.y,
                              self.tableView.frame.size.width,
                              1.0000f);
        [self.tableView scrollRectToVisible: r
                                   animated: NO];

    }
    [super viewDidLayoutSubviews];
}

#pragma mark - NSNotificationCenter

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)updateInterfaceForPerferedContentSizeCategory:(NSString *)preferredContentSizeCategory {
    
    if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryExtraSmall]) {
        self.headerSectionHeight = 24.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategorySmall]) {
        self.headerSectionHeight = 26.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryMedium]) {
        self.headerSectionHeight = 29.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryLarge]) {
        self.headerSectionHeight = 32.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryExtraLarge]) {
        self.headerSectionHeight = 34.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryExtraExtraLarge]) {
        self.headerSectionHeight = 36.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryExtraExtraExtraLarge]) {
        self.headerSectionHeight = 38.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryAccessibilityMedium]) {
        self.headerSectionHeight = 40.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryAccessibilityLarge]) {
        self.headerSectionHeight = 42.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryAccessibilityExtraLarge]) {
        self.headerSectionHeight = 44.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
        self.headerSectionHeight = 46.0000f;
        
    } else if ([preferredContentSizeCategory isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
        self.headerSectionHeight = 48.0000f;
        
    } else {
        self.headerSectionHeight = 29.0000f;
    }

}

#pragma mark - UIViewController

- (NSString *)title {
    return NSLocalizedString(@"MAD Query", "MAD Query");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.firstTimeTablePosition = NO;

    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.tableView.bounds];
    self.tableView.backgroundView = watermarkView;
    [self updateInterfaceForPerferedContentSizeCategory:[UIApplication sharedApplication].preferredContentSizeCategory];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleContentSizeCategoryDidChangeNotification:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    [self.tableView registerClass: [UITableViewCellTableName class]
           forCellReuseIdentifier: @"UITableViewCellTableName"];
    
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
    [toolbarButtons removeObjectsInArray:@[self.barButtonItemShowSQL, self.barButtonItemDone]];
    [self setToolbarItems:toolbarButtons animated:NO];
    
    [self reloadDocument:self.document animated:YES];
    
    self.navigationItem.prompt = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    if (self.document) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(documentStateChanged)
                                                     name: UIDocumentStateChangedNotification
                                                   object: self.document];
    }

    if ([self toolbarIconShown] == NO && [self barButtonItemShowSQL] != nil) {   //i.e. iPad version
        __weak MADQueryViewController *blockSelf = self;
        [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
            if (isLicensedUser) {
                
                [blockSelf setToolbarIconShown:YES];
                
                NSMutableArray *toolbarButtons = [[blockSelf toolbarItems] mutableCopy];
                NSInteger index = [toolbarButtons count] - 1;
                UIBarButtonItem *barButtonItemFixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace
                                                                                                         target: self
                                                                                                         action: nil];
                [barButtonItemFixedSpace setWidth:20.0000f];
                [toolbarButtons insertObject: [blockSelf barButtonItemShowSQL]
                                     atIndex: index+1];
                [toolbarButtons insertObject: barButtonItemFixedSpace
                                     atIndex: index+1];
                
                
                [blockSelf setToolbarItems: toolbarButtons
                                  animated: animated];
            }
        }];
    }

    UIColor *barTintColor = [UIColor tintColorBlue];
    UIColor *tintColor = [UIColor tintColorWhite];
    self.navigationController.toolbar.barTintColor = barTintColor;
    self.navigationController.toolbar.tintColor = tintColor;

    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = [MTApplicationInstance madQuery];
    
    self.navigationItem.titleView = titleView;
    
    [self enableTabBarItems];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: self.document];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: MNSSegueShowSql]) {
        MTShowSqlViewController *viewController;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            viewController = (MTShowSqlViewController *)[segue.destinationViewController topViewController];
        } else {
            viewController = segue.destinationViewController;
        }
        viewController.delegate = self;
        viewController.query = self.document.mainQuery;
        [self disableTabBarItems];
        
    } else if ([segue.identifier isEqualToString: MNSIdentifierSegueShowAddTableViewController]) {
        
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            if (navControl.topViewController) {
                if ([navControl.topViewController isKindOfClass:[MTQueryBuilderAddTableViewController class]]) {
                    
                    MTQueryBuilderAddTableViewController *tvc = (MTQueryBuilderAddTableViewController *)[navControl topViewController];
                    if (tvc) {
                        tvc.delegate = self;
                    }

                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.sortDescriptors = @[sortDescriptor];

                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: self.document.managedObjectContext
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [tvc setFetchedResultsController: frc];
                }
            }
        }

    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowAddLinkViewController]) {
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderLinkBuilderViewController class]]) {
                    
                    MTQueryBuilderLinkBuilderViewController *tvc = (MTQueryBuilderLinkBuilderViewController *)navControl.topViewController;
                    tvc.document = self.document;
                    if (tvc) {
                        tvc.delegate = self;
                    }
                }
            }
        }
    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowAddPredicateViewController]) {
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            //NSLog(@"Top View Controller: %@", [navControl topViewController]);
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderPredicateFormatViewController class]]) {
                    MTQueryBuilderPredicateFormatViewController *tvc = (MTQueryBuilderPredicateFormatViewController *)navControl.topViewController;
                    if (tvc) {
                        tvc.document = self.document;
                        tvc.delegate = self;
                    }
                }
            }
        }
    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowAddGroupViewController]) {
        if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = segue.destinationViewController;
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderAddGroupViewController class]]) {
                    MTQueryBuilderAddGroupViewController *tvc = (MTQueryBuilderAddGroupViewController *)navControl.topViewController;
                    if (tvc) {
                        tvc.document = self.document;
                        tvc.delegate = self;
                    }
                }
            }
        }
    } else if ([segue.identifier isEqualToString:MNSIdentifierSegueShowLayoutSettings]) {
                if ([segue.destinationViewController isKindOfClass:[MTReportDesignerSectionLayoutSettingsViewController class]]) {
                    MTReportDesignerSectionLayoutSettingsViewController *tvc = (MTReportDesignerSectionLayoutSettingsViewController *)segue.destinationViewController;
                    if (tvc) {
                        tvc.delegate = self;
                        RptqQuery *query = [[self.document activeDocumentModel] defaultQuery];
                        
                        RptqDocumentSection *section = [query documentSectionForRow: self.lastSelectedRowNumber];
                        tvc.initalHeightValue = section.height.floatValue;
                        tvc.initalVisibility = section.visibility.boolValue;
                        tvc.initalNumberOfRows = section.numberOfRows.integerValue;
                    }
                }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerformSegueWithIdentifier = [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    if ([identifier isEqualToString:MTSegueCloseDesigner]) {
        NSError *error = nil;
        [self.document.managedObjectContext save:&error];
    }
    return shouldPerformSegueWithIdentifier;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    UIViewController *weakself = self;
    [super dismissViewControllerAnimated:YES completion:^(){
        [weakself enableTabBarItems];
    }];
}

#pragma mark - MTQueryBuilderPredicateFormatDelegate

- (void)addQueryPredicate:(RptqQueryPredicate *)predicate {
    UIViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself enableTabBarItems];
    }];
    
    [[self.document activeDocumentModel] addPredicate:predicate];
    [self.document saveContext];
}

#pragma mark - MTReportDesignerSectionLayoutSettingsDelegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    RptqDocument *document = [self.document activeDocumentModel];
    [document setHeight:height forSectionAtRow:self.lastSelectedRowNumber];
    [self.document saveContext];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    RptqDocument *document = [self.document activeDocumentModel];
    [document setVisibility: isVisible
            forSectionAtRow: self.lastSelectedRowNumber];
    [self.document saveContext];
}

- (void)layoutSettings:(MTReportDesignerSectionLayoutSettingsViewController *)layoutSettings
          newPageAfter:(BOOL)newPageAfter {
    RptqDocument *document = [self.document activeDocumentModel];
    [document setNewPageAfter: newPageAfter
              forSectionAtRow: self.lastSelectedRowNumber];
    [self.document saveContext];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    RptqDocument *document = [self.document activeDocumentModel];
    [document setNumberOfRows: numberOfRows
              forSectionAtRow: self.lastSelectedRowNumber];
    [self.document saveContext];
}

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    UIViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself enableTabBarItems];
    }];
}

- (void)viewControllerDidCancel:(id)sender {
    UIViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself enableTabBarItems];
    }];
}

#pragma mark - MTQueryBuilderLinkBuilderDelegate

- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)link {
    UIViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself enableTabBarItems];
    }];

    RptqDocument *document = [self.document activeDocumentModel];
    [document addQueryLink:link];
    [self.document saveContext];
    NSInteger suspectedSection = 2;
    MTQuerySections tableSection = [self tableSectionTypeForIndexPathSection: suspectedSection];
    if (tableSection == MTQuerySectionsLinks) {
        NSIndexSet *linksSection = [NSIndexSet indexSetWithIndex:suspectedSection];
        [self.tableView reloadSections: linksSection
                      withRowAnimation: UITableViewRowAnimationAutomatic];
    }
    [self.document saveToURL: self.document.fileURL
            forSaveOperation: UIDocumentSaveForOverwriting completionHandler:nil];
}

#pragma mark - MTQueryBuilderAddGroupDelegate

- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldID
                       andSortOrder:(MNSSortOrder)sortOrder {
    
    UIViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself enableTabBarItems];
    }];

    [self.document addQueryGroupWithQueryField:queryFieldID andSortOrder:sortOrder];
    
    [self performFetchGroups];
}

#pragma mark - MTQueryBuilderAddTableDelegate

- (void)viewControllerSchemaAddTableDidSelectTable:(RptqDatabaseSchemaTable *)schemaTable {
    UIViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself enableTabBarItems];
    }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

    NSIndexSet *indexSetSections = nil;

    MADocument *reportDocument = self.document;

    // Get old layout
    NSDictionary *oldLayout = [self datamodel];
    NSArray *oldLayoutSectionTypes = oldLayout[MTTableSectionSectionsKey];

    // Add new table to the query
    [reportDocument addQuerySelectSchemeTable:schemaTable];
    
    // Account for new sections in the query builder.
    NSDictionary *newLayout = [self datamodel];
    NSArray *newLayoutSectionTypes = newLayout[MTTableSectionSectionsKey];

    if (oldLayoutSectionTypes.count != newLayoutSectionTypes.count) {
        if (oldLayoutSectionTypes.count < newLayoutSectionTypes.count) { //add sections
            //Constrained that it only will work when sections being added in an index set, or next to each other.
            NSInteger secctr = 0;
            BOOL startIndexSet = NO;
            NSInteger startIndex = -1;
            NSInteger lengtho = [newLayoutSectionTypes count] - [oldLayoutSectionTypes count];
            for (NSNumber *typenum in newLayoutSectionTypes) {
                MTQuerySections stsection = [typenum integerValue];
                if (secctr < [oldLayoutSectionTypes count]) {
                    if (stsection == [oldLayoutSectionTypes[secctr] integerValue]) {
                        secctr++;
                    } else {
                        if (!startIndexSet) {
                            startIndex = secctr;
                            startIndexSet = YES;
                        }
                    }
                } else {
                    if (!startIndexSet) {
                        startIndex = secctr;
                        startIndexSet = YES;
                    }
                    secctr++;
                }
            }
            if (startIndexSet) {
                NSRange sectionRange = NSMakeRange(startIndex, lengtho);
                indexSetSections = [[NSIndexSet alloc] initWithIndexesInRange: sectionRange];
            }
        }
    }
    
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];

    [self performFetchTables];
}

#pragma mark - Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id queryBuilderDataModel = [self datamodel];
    NSInteger numberOfSections = [queryBuilderDataModel[MTTableHeaderSectionKey] count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    MTQuerySections ts = [self tableSectionTypeForIndexPathSection: section];
    
    NSDictionary *rowsDict = [self datamodel][MTTableSectionRowKey];
    NSInteger numberOfRows = 0;
    numberOfRows = [rowsDict[[NSNumber numberWithInt: ts]] intValue];
    if (numberOfRows < 0) {
        switch (ts) {
            case MTQuerySectionsTables: {
                numberOfRows = [[self.fetchedResultsControllerTables sections][0] numberOfObjects];
                //NSLog(@"Table Rows:     %d", numberOfRows);
                break;
            }
            case MTQuerySectionsLinks: {
                numberOfRows = [[self.fetchedResultsControllerLinks sections][0] numberOfObjects];
                //NSLog(@"Link Rows:      %d", numberOfRows);
                break;
            }
            case MTQuerySectionsPredicate: {
                NSArray *sections = [[self fetchedResultsControllerPredicates] sections];
                id sectionData = sections[0];
                numberOfRows = [sectionData numberOfObjects];
                //NSLog(@"Predicate Rows: %d", numberOfRows);
                break;
            }
            case MTQuerySectionsGroups: {
                NSArray *sections = [[self fetchedResultsControllerGroups] sections];
                id sectionData = sections[0];
                numberOfRows = [sectionData numberOfObjects];
                break;
            }
            default:
                numberOfRows = 0;
                break;
        }
    }
	return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = indexPath.section;
    MTQuerySections sectionType = [self tableSectionTypeForIndexPathSection: section];
	return (sectionType == MTQuerySectionsTables ||
            sectionType == MTQuerySectionsGroups ||
            sectionType == MTQuerySectionsPredicate ||
            sectionType == MTQuerySectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self tableSectionTypeForIndexPathSection:indexPath.section] == MTQuerySectionsGroups) ? YES : NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MTQuerySections querySection = [self tableSectionTypeForIndexPathSection:indexPath.section];

    switch (editingStyle) {

        case UITableViewCellEditingStyleDelete:
            [self deleteItemFromQuerySection:querySection fromTableView:tableView atIndexPath:indexPath];
            break;

        case UITableViewCellEditingStyleInsert:
            break;

        case UITableViewCellEditingStyleNone:
            break;

        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    MTQuerySections ts = [self tableSectionTypeForIndexPathSection: toIndexPath.section];
    switch (ts) {
        case MTQuerySectionsGroups: {

            NSIndexPath *fromIndex = [NSIndexPath indexPathForRow: fromIndexPath.row inSection: 0];
            NSIndexPath *toIndex = [NSIndexPath indexPathForRow: toIndexPath.row inSection: 0];
            RptqQueryGroup *fromGroup = [[self fetchedResultsControllerGroups] objectAtIndexPath: fromIndex];
            RptqQueryGroup *toGroup = [[self fetchedResultsControllerGroups] objectAtIndexPath: toIndex];
            NSInteger fromWeight = [[toGroup weight] integerValue];
            NSInteger toWeight = [[fromGroup weight] integerValue];
            [toGroup setWeight:@(toWeight)];
            [fromGroup setWeight:@(fromWeight)];
            NSError *error = nil;
            [[[self fetchedResultsControllerGroups] managedObjectContext] save:&error];
            [self performFetchGroups];
            break;
        }
        default:
            break;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return @[];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *result = nil;

    NSInteger row = indexPath.row;
    MTQuerySections section = [self tableSectionTypeForIndexPathSection: indexPath.section];

    switch (section) {

        // MARK: Display and identify the data source and data sources
        case MTQuerySectionsDatasource: {
            static NSString *MyIdentifierUITableViewCellDataSource = @"UITableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellDataSource];

            RptqDocument *document = [self.document activeDocumentModel];
            RptqDatabase *database = [document.hasDatabaseSchemas anyObject];

            if (database.ownedByUser) {
                NSString *databaseType = [NSString stringWithFormat:@"%@", database.ownedByUser.database_driver_type];
                NSString *schemaName = [database.ownedByUser databaseSchemaName];
                NSString *localizedMessage = NSLocalizedString(@"You are connecting to a %1$@ datasource named %2$@.", @"You are connecting to %1$@ datasource named %2$@.");
                NSString *message = [NSString stringWithFormat:localizedMessage, databaseType, schemaName];
                UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
                NSDictionary *attributes = @{ NSFontAttributeName : font };
                NSRange rangeOfSchemaName = [message rangeOfString:schemaName];
                NSRange rangeOfDatabaseTypeName = [message rangeOfString:databaseType];
                UIFont *fontItalic = [UIFont italicSystemFontOfSize:font.pointSize];
                
                NSDictionary *additionalAttributeStroke = @{ NSFontAttributeName : fontItalic };
                NSMutableAttributedString *messageAttributed = [[NSMutableAttributedString alloc] initWithString: message
                                                                                                      attributes: attributes];
                [messageAttributed removeAttribute: NSFontAttributeName
                                             range: rangeOfDatabaseTypeName];
                [messageAttributed removeAttribute: NSFontAttributeName
                                             range: rangeOfSchemaName];
                [messageAttributed addAttributes: additionalAttributeStroke
                                           range: rangeOfDatabaseTypeName];
                [messageAttributed addAttributes: additionalAttributeStroke
                                           range: rangeOfSchemaName];
                result.textLabel.text = message;
                result.textLabel.attributedText = messageAttributed;
                result.detailTextLabel.text = @"";
            }
            result.textLabel.numberOfLines = 0;
            break;
        }

        // MARK: Display the table names that are used in the query
        case MTQuerySectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryTable *tablea = [self.fetchedResultsControllerTables objectAtIndexPath: path];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            result.textLabel.text = [NSString stringWithFormat:@"%@", tablea.alias];
            result.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            result.textLabel.font = font;
            result.textLabel.backgroundColor = [UIColor whiteColor];
            result.indentationLevel = 1;
            result.tintColor = [UIColor tintColorBlue];
            result.backgroundColor = [UIColor whiteColor];
            break;
        }
        
        // MARK: Display the table links or joins that are used in the query.
        case MTQuerySectionsLinks: {

            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [[self fetchedResultsControllerLinks] objectAtIndexPath: indexPath];
            
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            
            NSString *messageText = @"%@ %@ %@";
            
            NSString *pre = [[links tableleft] capitalizedString];
            NSString *post = [[links fieldleft] capitalizedString];
            NSString *leftString = [NSString stringWithFormat:@"%@.%@", pre, post];
            
            pre = links.tableright.capitalizedString;
            post = links.fieldright.capitalizedString;
            NSString *rightString = [NSString stringWithFormat:@"%@.%@", pre, post];

            [(UITableViewCellQueryLink *)result setTableID: [links objectID]];
            result.textLabel.numberOfLines = 0;

            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            paragraphStyle.headIndent = 20.0000f;
            NSString *linksDescription = [links linkDescription];
            messageText = [NSString stringWithFormat:messageText, leftString, linksDescription, rightString];
            NSDictionary *attributes = @{ NSFontAttributeName : font,
                                          NSParagraphStyleAttributeName : paragraphStyle };
            UIColor *color = [UIColor tintColorBlue];
            NSDictionary *attributesAlt = @{ NSFontAttributeName : fontCaption,
                                             NSForegroundColorAttributeName :  color};
            NSRange rangeLinkDesc = [messageText rangeOfString:linksDescription];
            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString: messageText
                                                                                        attributes: attributes];
            [message addAttributes:attributesAlt
                             range:rangeLinkDesc];
            result.textLabel.attributedText = message;

            break;
        }

        // MARK: Display the groupings used in the query.
        case MTQuerySectionsGroups: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            RptqQueryGroup *group = [[self fetchedResultsControllerGroups] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]];
            [result backgroundView].backgroundColor = [UIColor whiteColor];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            
            NSMutableParagraphStyle *paragraphStyleLeft = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            NSMutableParagraphStyle *paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            paragraphStyleLeft.alignment = NSTextAlignmentLeft;
            paragraphStyleRight.alignment = NSTextAlignmentRight;

            NSString *formatString = @"%1$@ %2$@";
            NSString *fieldName = [group fieldNameNice];
            NSString *sortFieldName = [group sortDisplayNice];
            NSString *messageText = [NSString stringWithFormat:formatString, fieldName, sortFieldName];
            NSDictionary *attributes = @{ NSFontAttributeName : font };
            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
            NSDictionary *attributesLeft = @{ NSParagraphStyleAttributeName : paragraphStyleLeft };
            UIColor *color = [UIColor tintColorBlue];
            NSDictionary *attributesRight = @{ NSParagraphStyleAttributeName : paragraphStyleLeft, NSFontAttributeName : fontCaption, NSForegroundColorAttributeName :  color };
            NSRange rangeLeft = [messageText rangeOfString:fieldName];
            NSRange rangeRange = [messageText rangeOfString:sortFieldName];
            [message addAttributes:attributesLeft range:rangeLeft];
            [message addAttributes:attributesRight range:rangeRange];
            result.textLabel.text = messageText;
            result.textLabel.attributedText = message;
            result.textLabel.numberOfLines = 0;
            [(UITableViewCellQueryGroup *)result setTableID:group.objectID];
            break;
        }
        
        // MARK: Display the predicates or conditions on the query.
        case MTQuerySectionsPredicate: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryPredicate";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryPredicate *predicate = [[self fetchedResultsControllerPredicates] objectAtIndexPath: indexPath];
            
            NSString *leftFieldDisplay = nil, *rightFieldDisplay = nil;
            if ([predicate fieldleftpred] != nil) {
                leftFieldDisplay = [predicate fieldleftpred];
            } else {
                leftFieldDisplay = [[predicate hasLeftField] toString];
            }
            
            if ([predicate fieldrightpred] != nil) {
                rightFieldDisplay = [predicate fieldrightpred];
            } else {
                rightFieldDisplay = [[predicate hasRightField] toString];
            }
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            
            NSString *formatString = @"%1$@ %2$@ %3$@";
            NSString *symbol = [predicate symbolForDisplay];
            NSString *messageText = [NSString stringWithFormat:formatString, leftFieldDisplay, symbol, rightFieldDisplay];
            NSDictionary *attributes = @{ NSFontAttributeName : font };
            UIColor *color = [UIColor tintColorBlue];
            NSDictionary *attributesCaption = @{ NSForegroundColorAttributeName :  color };

            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString: messageText
                                                                                        attributes: attributes];
            NSRange rangeMiddle = [messageText rangeOfString:symbol];
            result.textLabel.numberOfLines = 0;
            [message addAttributes: attributesCaption
                             range: rangeMiddle];
            result.textLabel.text = messageText;
            result.textLabel.attributedText = message;
            [(MTTableViewCellQueryPredicate *)result setTableID:[predicate objectID]];
            
            break;
        }
        
        case MTQuerySectionsSql: {
            switch (row) {
                case 0: {
                    static NSString *MyIdentifierUITableViewCellOverride = @"UITableViewCellOverride";
                    result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellOverride];
                    break;
                }
                default: {
                    static NSString *MyIdentifierUITableViewCellQueryInput = @"UITableViewCellQueryInput";
                    result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellQueryInput];
                    break;
                }
            }
            break;
        }
        
        default: {
            break;
        }

    }
    
    if (!result) {
        result = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCellShouldNotGetHere"];
        [result.textLabel setText: @"Err"];
    }

    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    MTViewTableHeader *result = nil;
    
    section = [self tableSectionTypeForIndexPathSection: section];
    
    switch (section) {
            
        case MTQuerySectionsDatasource: {
            result = [self tableHeaderDatabaseInfo];
            break;
        }
            
        case MTQuerySectionsTables: {
            result = [self tableHeaderTablesToSelect];
            break;
        }
            
        case MTQuerySectionsLinks: {
            result = [self tableHeaderTableJoins];
            break;
        }
            
        case MTQuerySectionsGroups: {
            result = [self tableHeaderGroupedBy];
            break;
        }
            
        case MTQuerySectionsPredicate: {
            result = [self tableHeaderPredicate];
            break;
        }
        default: {
            result = [self tableHeaderDatabaseInfo];
            break;
        }
    }
    return result;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.headerSectionHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self tableSectionTypeForIndexPathSection: indexPath.section] == MTQuerySectionsTables) {
        [self displayTableSampleDataForIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Remove", @"Remove button title.");
 }

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if ([self suspendAutomaticTrackingOfChangesInManagedObjectContext] == NO) {
        [self.tableView beginUpdates];
        [self setBeganUpdates: YES];
    }
}

- (NSMutableArray *)sectionsUsedByFetchedResultsController: (NSFetchedResultsController *)controller {

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

    if ([controller isEqual:self.fetchedResultsControllerTables]) {
        
        NSNumber *n = [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: MTQuerySectionsTables]];
        [result addObject: n];

    } else if ([controller isEqual:[self fetchedResultsControllerLinks]]) {

        NSNumber *n = [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: MTQuerySectionsLinks]];
        [result addObject: n];

    } else if ([controller isEqual:[self fetchedResultsControllerGroups]]) {

        NSInteger sectionGroup = [self sectionPositionForTableSectionType: MTQuerySectionsGroups];
        NSNumber *numberSectionGroup = @(sectionGroup);
        [result addObject: numberSectionGroup];
    
    } else if ([controller isEqual:[self fetchedResultsControllerPredicates]]) {
    
        NSInteger section = [self sectionPositionForTableSectionType: MTQuerySectionsPredicate];
        NSNumber *sectionNumber = @(section);
        [result addObject: sectionNumber];
    }
    
    return result;

}

- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex
	 forChangeType: (NSFetchedResultsChangeType)type {

    
    NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
    
    for (NSNumber *section in sections) {
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            MTQuerySections updateSection = [section integerValue];
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
        MTQuerySections updateSection = [section integerValue];
        
        NSIndexPath *path = [NSIndexPath indexPathForRow: indexPath.row
                                               inSection: updateSection];
        if (path) {
            if ([self suspendAutomaticTrackingOfChangesInManagedObjectContext] == NO) {
                NSArray *indexPaths = @[path];
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ([self beganUpdates]) {
        [self.tableView endUpdates];
    }
    [self setBeganUpdates:NO];
}

#pragma mark - Fetching

- (void)performFetchAll {
    [self performFetchTables];
    [self performFetchLinks];
    [self performFetchGroups];
    [self performFetchPredicate];
}

- (void)performFetchTables {
    [self performFetchWithController:self.fetchedResultsControllerTables];
}

- (void)performFetchLinks {
    [self performFetchWithController:[self fetchedResultsControllerLinks]];
}

- (void)performFetchGroups {
    [self performFetchWithController:[self fetchedResultsControllerGroups]];
}

- (void)performFetchPredicate {
    [self performFetchWithController:[self fetchedResultsControllerPredicates]];
}

- (void)performFetchWithController:(NSFetchedResultsController *)controller {
    if (controller) {
        [controller performFetch:nil];
    }
    [self.tableView reloadData];
}


#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

#pragma mark - Actions

- (IBAction)edit:(id)sender {
    
    BOOL editing = ![self.tableView isEditing];
    
    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        UIBarButtonSystemItem buttonType = !editing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
        SEL toggleEditModeQueryDesigner = @selector(edit:);
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                       target: self
                                                                                       action: toggleEditModeQueryDesigner];
        
        
        [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
        [self setBarButtonItemEdit:barButtonItem];
    }
    
    [self.tableView setEditing: editing];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)addConnection:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddDatabaseDrivers
                              sender: sender];
    [self disableTabBarItems];
}

- (void)addTable:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddTableViewController
                              sender: sender];
    [self disableTabBarItems];
}

- (void)addLink:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddLinkViewController
                              sender: sender];
    [self disableTabBarItems];
}

- (void)addPredicate:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddPredicateViewController
                              sender: sender];
    [self disableTabBarItems];
}

- (void)addGroup:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddGroupViewController
                              sender: sender];
    [self disableTabBarItems];
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

- (void)removeGroup:(RptqQueryGroup *)groupToRemove {
    if (groupToRemove) {
        RptqQuery *query = [groupToRemove inQuery];
        NSManagedObjectContext *managedObjectContext = [query managedObjectContext];
        
        NSSet *sectionsToRemove = [groupToRemove hasSection];
        NSArray *sections = [sectionsToRemove allObjects];
        if ([sections count] == 2) {
            [groupToRemove removeHasSectionObject: sections[0]];
            [groupToRemove removeHasSectionObject: sections[1]];
        }
        [[query managedObjectContext] deleteObject: groupToRemove];
        [query removeHasQueryGroupsObject: groupToRemove];
        [managedObjectContext save:nil];
        
        //Reweight Groups
        NSString *weight = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
        NSArray *sortDescriptors = @[sortDescriptor];
        NSArray *sortedQueryGroups = [[query hasQueryGroups] sortedArrayUsingDescriptors:sortDescriptors];
        NSUInteger counter = 0;
        for (RptqQueryGroup *group in sortedQueryGroups) {
            NSNumber *counterWrapper = @(counter);
            group.weight = counterWrapper;
            counter++;
        }
        NSError *error = nil;
        [managedObjectContext save:&error];
        NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
    }
}

- (void)reloadDocument:(MADocument *)reportDocument animated:(BOOL)animated {
    
    if (reportDocument) {
        
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        
        {
            
            
            RptqDocument *document = [reportDocument activeDocumentModel];
            RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
            RptqQuery *query = [database.hasQueries anyObject];
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias"
                                                                             ascending: YES];
            [request setSortDescriptors: @[sortDescriptor]];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = self;
            [self setFetchedResultsControllerTables: frc];
            [self performFetchTables];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"tableleft" ascending:YES];
            [request setSortDescriptors: @[sortDescriptor]];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = self;
            [self setFetchedResultsControllerLinks: frc];
            [self performFetchLinks];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"weight" ascending:YES];
            [request setSortDescriptors: @[sortDescriptor]];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = self;
            [self setFetchedResultsControllerGroups: frc];
            [self performFetchGroups];
            frc = nil;
            
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: entityName];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fieldleftpred" ascending:YES];
            NSArray *sortDescriptors = @[sortDescriptor];
            [request setSortDescriptors: sortDescriptors];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = self;
            [self setFetchedResultsControllerPredicates: frc];
            [self performFetchPredicate];
            frc = nil;
        }
        [self.tableView reloadData];
    }
    
}

- (NSMutableDictionary *)datamodel {
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = [document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    NSInteger numberOfTablesInQuery = [query numberOfTables];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:[self datamodelForNumberOfTables:numberOfTablesInQuery]];
    return result;
}

- (NSDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables {
    
    NSDictionary *result;
    
    NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
    NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
    NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
    NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
    NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
    
    switch (numberOfTables) {
        case 0: { //There are three configurations for the table.  These configurations depend on the number of schemas in the query: zero, one, or more than one.
            
            NSNumber *datasource = @(MTQuerySectionsDatasource);
            NSNumber *tables = @(MTQuerySectionsTables);
            NSArray *sections = @[datasource, tables];
            
            NSNumber *count1 = @(1);
            NSNumber *count2 = @(-1);
            NSArray *countRowsForSection = @[count1, count2];
            NSDictionary *countRowsForSectionDictionary =  [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                       forKeys: sections];
            
            NSArray *headersSection = @[h2, h3];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                 forKeys: sections];
            NSNumber *height1 = @(50.0000f);
            NSNumber *height2 = @([UITableViewCellTableName defaultHeight]);
            NSArray *heightRowsForSection = @[height1, height2];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
                                                                                                 forKeys: sections];
            result = @{MTTableSectionSectionsKey : sections,
                       MTTableHeaderSectionKey : headersSectionDictionary,
                       MTTableSectionRowKey : countRowsForSectionDictionary,
                       MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};
            
            
            break;
        }
        case 1: {   //Only one table in query.  No ability to add links.
            
            NSNumber *datasource = @(MTQuerySectionsDatasource);
            NSNumber *tables = @(MTQuerySectionsTables);
            NSNumber *groups = @(MTQuerySectionsGroups);
            NSNumber *predicate = @(MTQuerySectionsPredicate);

            NSArray *sections = @[datasource, tables, groups, predicate];
            
            NSArray *countRowsForSection = @[@(1), @(-1), @(-1), @(-1)];
            NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                      forKeys: sections];
            
            NSArray *headersSection = @[h2, h3, h5, h6];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                 forKeys: sections];
            
            NSNumber *height1 = @(44.0000f);
            NSNumber *height2 = @([UITableViewCellTableName defaultHeight]);
            NSNumber *height3 = @(44.0000f);
            NSNumber *height4 = @(44.0000f);
            NSArray *heightRowsForSection = @[height1, height2, height3, height4];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
                                                                                                 forKeys: sections];
            
            result = @{MTTableSectionSectionsKey : sections,
                       MTTableHeaderSectionKey : headersSectionDictionary,
                       MTTableSectionRowKey : countRowsForSectionDictionary,
                       MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};
            
            break;
        }
        default: {   //Two more more tables in query.  All features available.
            
            NSNumber *datasource = @(MTQuerySectionsDatasource);
            NSNumber *tables = @(MTQuerySectionsTables);
            NSNumber *links = @(MTQuerySectionsLinks);
            NSNumber *groups = @(MTQuerySectionsGroups);
            NSNumber *predicate = @(MTQuerySectionsPredicate);
            NSArray *sections = @[datasource, tables, links, groups, predicate];
            
            NSNumber *count1 = @(1);
            NSNumber *count2 = @(-1);
            NSNumber *count3 = @(-1);
            NSNumber *count4 = @(-1);
            NSNumber *count5 = @(-1);
            NSArray *countRowsForSection = @[count1, count2, count3, count4, count5];
            NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                      forKeys: sections];
            
            NSArray *headersSection = @[h2, h3, h4, h5, h6];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                 forKeys: sections];
            NSNumber *height1 = @(44.0000f);
            NSNumber *height2 = @([UITableViewCellTableName defaultHeight]);
            NSNumber *height3 = @([UITableViewCellQueryLink defaultHeight]);    //50.0000f
            NSNumber *height4 = @(44.0000f);
            NSNumber *height5 = @(44.0000f);
            NSArray *heightRowsForSection = @[height1, height2, height3, height4, height5];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection
                                                                                                 forKeys:sections];
            
            result = @{MTTableSectionSectionsKey : sections,
                       MTTableHeaderSectionKey : headersSectionDictionary,
                       MTTableSectionRowKey : countRowsForSectionDictionary,
                       MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};
            
            break;
        }
    }
    return result;
}

- (MTViewTableHeader *)tableHeaderDatabaseInfo {
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = NSLocalizedString(@"Database Information", @"Database Information");
    header.labelTitle.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    header.buttonAdd.hidden = YES;
    return header;
}

- (MTViewTableHeader *)tableHeaderTablesToSelect {
    NSString *title = NSLocalizedString(@"Tables", @"Tables");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self
                         action: @selector(addTable:)
               forControlEvents: UIControlEventTouchUpInside];
    return header;
}

- (MTViewTableHeader *)tableHeaderTableJoins {
    NSString *title = NSLocalizedString(@"Joins", @"Joins");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self
                         action: @selector(addLink:)
               forControlEvents: UIControlEventTouchUpInside];
    return header;
}

- (MTViewTableHeader *)tableHeaderGroupedBy {
    SEL selector = @selector(addGroup:);
    NSString *title = NSLocalizedString(@"Grouped By", @"Grouped By");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self
                         action: selector
               forControlEvents: UIControlEventTouchUpInside];
    return header;
}

- (MTViewTableHeader *)tableHeaderPredicate {
    SEL selector = @selector(addPredicate:);
    NSString *title = NSLocalizedString(@"Having Specified Criteria", @"Next to the button to add database tables.");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self
                         action: selector
               forControlEvents: UIControlEventTouchUpInside];
    [header.labelTitle sizeToFit];
    return header;
}

- (MTViewTableHeader *)tableHeader {
    CGRect rect = CGRectMake(0.0000f, 0.0000f, 320.0000f, self.headerSectionHeight);
    MTViewTableHeader *tableHeader = [[MTViewTableHeader alloc] initWithFrame:rect];
    return tableHeader;
}

- (MTTableController *)tableControllerForTable:(RptqQueryTable *)table {
    RptqDatabaseSchemaTable *schemaTable = [table databaseSchemaTable];
    MTQuery *rquery = [[MTQuery alloc] initWithQueryType:MTQueryTypeSampleDataTable object:schemaTable];
    MTTableController *tableController = [[MTTableController alloc] initWithQuery:rquery];
    
    MADNavigationBarTitleView *sampleDataTitleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];

    sampleDataTitleView.text = schemaTable.name;
    
    tableController.navigationItem.title = schemaTable.name;
    tableController.navigationItem.titleView = sampleDataTitleView;
    return tableController;
}

- (NSAttributedString *)saveDataViewTitleWithTableName:(NSString *)tableName {
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle titleBarStyle];
    
    NSString *firstPart = @"Data Sample";
    NSString *titleString = [NSString stringWithFormat:@"%1@ %2@", firstPart, tableName];
    
    NSRange rangeFirstPart = NSMakeRange(0, firstPart.length);
    NSRange rangeSecondPart = NSMakeRange(firstPart.length, titleString.length - firstPart.length);
    
    UIFont *fontb = [UIFont fontWithName: @"HelveticaNeue-Light"
                                    size: 20.0000f];
    UIFont *fonti = [UIFont fontWithName: @"HelveticaNeue-LightItalic"
                                    size: 18.0000f];
    
    UIColor *foregroundColor = [UIColor whiteColor];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                 NSForegroundColorAttributeName: foregroundColor};
    NSMutableAttributedString *titleViewText = [[NSMutableAttributedString alloc] initWithString:titleString
                                                                                      attributes:attributes];
    
    [titleViewText addAttribute:NSFontAttributeName value:fontb range:rangeFirstPart];
    [titleViewText addAttribute:NSFontAttributeName value:fonti range:rangeSecondPart];
    
    return titleViewText;
}

- (void)displayTableSampleDataForIndexPath:(NSIndexPath *)indexPath {
    
    RptqQueryTable *table = [self.fetchedResultsControllerTables objectAtIndexPath: [NSIndexPath indexPathForRow: indexPath.row inSection: 0]];
    MTTableController *tableController = [self tableControllerForTable:table];
//    [tableController.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController pushViewController: tableController
                                         animated: YES];

}

// MARK: Deleting items from table view

- (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId inContent:(NSManagedObjectContext *)context {
    NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
    NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *documentObjectsPredicate = [NSPredicate predicateWithFormat:@"isLabelDataField.referencesQueryField.inQueryTable == %@", deleatedTableObjectId];
    fetchReqest.predicate = documentObjectsPredicate;
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [context executeFetchRequest:fetchReqest error:&fetchError];
    if (fetchError == nil) {
        for (RptqDocumentObject *documentObject in objectsToDelete) {
            [context deleteObject:[documentObject isLabelDataField]];
            [context deleteObject:documentObject];
        }
        [context save:&fetchError];
    }
}

- (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId inContent:(NSManagedObjectContext *)context {
    NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
    NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *documentObjectsPredicate = [NSPredicate predicateWithFormat:@"isAggregate.aggregateField.inQueryTable == %@", deleatedTableObjectId];
    [fetchReqest setPredicate:documentObjectsPredicate];
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [context executeFetchRequest:fetchReqest error:&fetchError];
    if (fetchError == nil) {
        for (RptqDocumentObject *documentObject in objectsToDelete) {
            [context deleteObject:[documentObject isAggregate]];
            [context deleteObject:documentObject];
        }
        [context save:&fetchError];
    }
}

- (NSArray *)deleteLinksRelatedToSection:(MTQuerySections)querySection
                            sectionIndex:(NSInteger)section
                                   table:(NSManagedObjectID *)deleatedTableObjectId
                             inTableView:(UITableView *)tableView
                          numberOfTables:(NSInteger)numberOfTables
                               inContext:(NSManagedObjectContext *)context {
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSFetchedResultsController *fetchedLinkes = [self fetchedResultsControllerLinks];
    NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = nil;
        NSManagedObject *object = nil;
        UITableViewCellQueryLink *tableViewCellLink = (UITableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
        if (tableViewCellLink) {
            object = [context existingObjectWithID:[tableViewCellLink tableID] error:&error];
        } else {
            
            id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedLinkes sections] objectAtIndex:0];
            if (row < sectionInfo.numberOfObjects) {
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
    NSError *error = nil;
    [context save:&error];
    return cellsToDelete;
}

- (NSArray *)deleteGroupsRelatedToSection:(MTQuerySections)querySection
                             sectionIndex:(NSInteger)section
                                    table:(NSManagedObjectID *)deleatedTableObjectId
                              inTableView:(UITableView *)tableView
                           numberOfTables:(NSInteger)numberOfTables
                                inContext:(NSManagedObjectContext *)context {
    
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *groupIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = nil;

        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsControllerGroups sections] objectAtIndex:0];
        if (row < sectionInfo.numberOfObjects) {
            NSIndexPath *testGroupIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            NSManagedObject *object = [self.fetchedResultsControllerGroups objectAtIndexPath:testGroupIndexPath];
            
            if (!error && object && [object isKindOfClass:[RptqQueryGroup class]]) {
                RptqQueryGroup *groupToRemove = (RptqQueryGroup *)object;
                
                if ([groupToRemove.hasField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
                    [self removeGroup:groupToRemove];
                    [cellsToDelete addObject:groupIndexPath];
                }
            }

        }
    }
    return cellsToDelete;
}

- (NSArray *)deletePredicateRelatedToSection:(MTQuerySections)querySection
                             sectionIndex:(NSInteger)section
                                    table:(NSManagedObjectID *)deleatedTableObjectId
                              inTableView:(UITableView *)tableView
                           numberOfTables:(NSInteger)numberOfTables
                                inContext:(NSManagedObjectContext *)context {

    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        
        
        MTTableViewCellQueryPredicate *tableViewCellPredicate = (MTTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:predicateIndexPath];
        NSError *error = nil;
        NSManagedObject *object = nil;
        if (tableViewCellPredicate) {
            object = [context existingObjectWithID:[tableViewCellPredicate tableID] error:&error];
        } else {
            NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            object = [[self fetchedResultsControllerPredicates] objectAtIndexPath: testPredicateIndexPath];
        }
        if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
            RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;
            BOOL deleted = NO;
            if ([predicateToRemove.hasLeftField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
                [RptqQueryPredicate deletePredicate:predicateToRemove];
                [cellsToDelete addObject:predicateIndexPath];
                deleted = YES;
            }
            if (deleted == NO) {
                if ([predicateToRemove.hasRightField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
                    [RptqQueryPredicate deletePredicate:predicateToRemove];
                    [cellsToDelete addObject:predicateIndexPath];
                }
            }
        }
    }
    return cellsToDelete;
}

- (NSArray *)deleteLinksGroupsPredicatesRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                           inTableView:(UITableView *)tableView
                                        numberOfTables:(NSInteger)numberOfTables
                                             inContext:(NSManagedObjectContext *)context {
    
    NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger section = 0; section < [tableView numberOfSections]; section++) {
        
        NSArray *cells;
        MTQuerySections querySection = [self tableSectionTypeForIndexPathSection: section
                                                              withNumberOfTables: numberOfTables + 1];
        if (querySection == MTQuerySectionsLinks) {
            cells = [self deleteLinksRelatedToSection:querySection sectionIndex:section table:deleatedTableObjectId inTableView:tableView numberOfTables:numberOfTables inContext:context];
        } else if (querySection == MTQuerySectionsGroups) {
            cells = [self deleteGroupsRelatedToSection:querySection sectionIndex:section table:deleatedTableObjectId inTableView:tableView numberOfTables:numberOfTables inContext:context];
        } else if (querySection == MTQuerySectionsPredicate) {
            cells = [self deletePredicateRelatedToSection:querySection sectionIndex:section table:deleatedTableObjectId inTableView:tableView numberOfTables:numberOfTables inContext:context];
        }
        [cellsToDelete addObjectsFromArray:cells];
    }
    return cellsToDelete;
}

- (NSIndexSet *)deleteSections:(NSArray *)oldLayoutSectionTypes newSections:(NSArray *)newLayoutSectionTypes {

    NSIndexSet *deleteSections = nil;
    if (oldLayoutSectionTypes.count > newLayoutSectionTypes.count) {
        NSInteger secctr = 0;
        BOOL startIndexSet = NO;
        NSInteger startIndex = -1;
        NSInteger lengtho = [oldLayoutSectionTypes count] - [newLayoutSectionTypes count];
        for (NSNumber *typenum in oldLayoutSectionTypes) {
            MTQuerySections stsection = [typenum integerValue];
            if (secctr < [newLayoutSectionTypes count]) {
                if (stsection == [newLayoutSectionTypes[secctr] integerValue]) {
                    secctr++;
                } else {
                    if (!startIndexSet) {
                        startIndex = secctr;
                        startIndexSet = YES;
                    }
                }
            } else {
                if (!startIndexSet) {
                    startIndex = secctr;
                    startIndexSet = YES;
                }
                secctr++;
            }
        }
        
        if (startIndex >= 0 && lengtho > 0) {
            NSRange sectionRange = NSMakeRange(startIndex, lengtho);
            deleteSections = [[NSIndexSet alloc] initWithIndexesInRange: sectionRange];
        }
    }
    return deleteSections;
}

- (void)deleteQueryTableFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:YES];
    
    RptqDocument *document = [self.document activeDocumentModel];
    NSManagedObjectContext *managedObjectContext = [document managedObjectContext];

    RptqDatabase *database = [document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    NSInteger numberOfTables = [query numberOfTables];
    
    NSDictionary *oldTableLayoutResult = [self datamodelForNumberOfTables: numberOfTables];
    NSDictionary *oldTableLayout = [[NSDictionary alloc] initWithDictionary:oldTableLayoutResult];
    
    NSIndexPath *tableIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 0];
    RptqQueryTable *table = [self.fetchedResultsControllerTables objectAtIndexPath: tableIndex];
    
    NSManagedObjectID *deleatedTableObjectId = [table objectID];
    [query removeHasQueryTablesObject:table];
    numberOfTables--;
    
    NSDictionary *newTableLayoutResult = [self datamodelForNumberOfTables: numberOfTables];
    NSDictionary *newTableLayout = [[NSDictionary alloc] initWithDictionary: newTableLayoutResult];
    NSArray *oldLayoutSectionTypes = oldTableLayout[MTTableSectionSectionsKey];
    NSArray *newLayoutSectionTypes = newTableLayout[MTTableSectionSectionsKey];
    
    NSIndexSet *deleteSections = [self deleteSections:oldLayoutSectionTypes newSections:newLayoutSectionTypes];

    [tableView beginUpdates];

    [self deleteDatafieldsRelatedToTable:deleatedTableObjectId inContent:managedObjectContext];
    [self deleteAggregateFieldRelatedToTable:deleatedTableObjectId inContent:managedObjectContext];
    
    NSArray *cellsToDelete = [self deleteLinksGroupsPredicatesRelatedToTable: deleatedTableObjectId
                                                                 inTableView: tableView
                                                              numberOfTables: numberOfTables
                                                                   inContext: managedObjectContext];
    
    NSError *error = nil;
    [managedObjectContext save:&error];
    if (error) {
        NSLog(@"Error %@", error);
    }
    
    if (deleteSections != nil) {
        [tableView deleteSections: deleteSections withRowAnimation: UITableViewRowAnimationAutomatic];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    if ([cellsToDelete count]) {
        [tableView deleteRowsAtIndexPaths:cellsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [tableView endUpdates];
    
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
}

- (void)deleteQueryLinksFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellQueryLink *cell = (UITableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObject *obj = [self.document.managedObjectContext objectRegisteredForID:cell.tableID];
    [self.document.managedObjectContext deleteObject: obj];
    [self.document.managedObjectContext save:nil];
}

- (void)deleteQueryGroupFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    RptqDocument *document = [self.document activeDocumentModel];
    [[document defaultQuery] deleteQueryGroupAtIndex:indexPath.row];
}

- (void)deleteQueryPredicateFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObjectID *objid = [(MTTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath] tableID];
    RptqDocument *doc = [self.document activeDocumentModel];
    NSManagedObject *predicate = [doc.managedObjectContext objectRegisteredForID:objid];
    [doc.managedObjectContext deleteObject:predicate];
    [doc.managedObjectContext save:nil];
}

- (void)deleteItemFromQuerySection:(MTQuerySections)querySection fromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    switch (querySection) {
            
        case MTQuerySectionsTables:
            [self deleteQueryTableFromTableView:tableView atIndexPath:indexPath];
            break;
            
        case MTQuerySectionsLinks:
            [self deleteQueryLinksFromTableView:tableView atIndexPath:indexPath];
            break;
            
        case MTQuerySectionsGroups:
            [self deleteQueryGroupFromTableView:tableView atIndexPath:indexPath];
            break;
            
        case MTQuerySectionsPredicate:
            [self deleteQueryPredicateFromTableView:tableView atIndexPath:indexPath];
            break;
            
        default:
            break;
    }
}

// MARK: Modal helper

- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)section withNumberOfTables:(NSInteger)numberOfTables {
    MTQuerySections result = section;
    NSDictionary *dataModel = [self datamodelForNumberOfTables:numberOfTables];
    NSArray *sectionTypes = dataModel[MTTableSectionSectionsKey];
    if ([sectionTypes count] >= section) {
        result = [sectionTypes[section] integerValue];
    }
    return result;
}

- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)sec {
    MTQuerySections result = sec;
    NSDictionary *datamodel = [self datamodel];
    NSArray *sectionTypes = datamodel[MTTableSectionSectionsKey];
    if ([sectionTypes count] >= sec) {
        result = [sectionTypes[sec] integerValue];
    }
    return result;
}

- (NSUInteger)sectionPositionForTableSectionType:(MTQuerySections)sec {
    NSInteger result = 0;
    NSArray *sectionTypes = [self datamodelForNumberOfTables:[self.tableView numberOfRowsInSection: 1]][MTTableSectionSectionsKey];
    NSInteger secPos = 0;
    for (NSNumber *num in sectionTypes) {
        if ([num integerValue] == sec) {
            result = secPos;
            break;
        }
        secPos++;
    }
    return result;
}

@end
