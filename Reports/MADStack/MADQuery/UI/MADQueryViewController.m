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
#import "MADTabBarController.h"
#import "MTStoreKitController+Features.h"
#import "MADWatermarkView.h"
#import <MAD/MTQuery.h>
#import "MTQueryBuilderAddTableViewController.h"
#import "MTQueryBuilderAddGroupViewController.h"
#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import "MTQueryBuilderPredicateFormatViewController.h"

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryGroup.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MTTableController.h"

#import "MTDatabaseDriverSelectorViewController.h"
#import "MTQueryBuilderLinkBuilderViewController.h"

#import "MADDesignerViewController.h"

#import "MTViewTableHeader.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MADNavigationController.h"
#import "MADViewControllerSQL.h"

#import "UIViewController+tabBarItem.h"

#import "NSParagraphStyle+CommonStyles.h"

NSString * const MNSIdentifierSegueShowAddTableViewController       = @"showAddTableViewController";
NSString * const MADImageBarButtonItemDatabase                      = @"UIBarButtonItemDatabase";
NSString * const MADImageBarButtonItemDatabase8                     = @"UIBarButtonItemDatabase8";
NSString * const MADSegueShowSql                                    = @"MADSegueShowSql";
NSString * const MTTableHeaderSectionKey                            = @"MTTableHeaderSectionKey";
NSString * const MTTableSectionRowKey                               = @"MTTableSectionRowKey";
NSString * const MTTableSectionRowHeightKey                         = @"MTTableSectionRowHeightKey";
NSString * const MTTableSectionSectionsKey                          = @"MTTableSectionSectionsKey";
NSString * const MNSIdentifierSegueShowAddLinkViewController        = @"showAddLinkViewController";
NSString * const MNSIdentifierSegueShowAddPredicateViewController   = @"showAddPredicateViewController";
NSString * const MNSIdentifierSegueShowAddGroupViewController       = @"showAddGroupViewController";
NSString * const MNSIdentifierSegueShowLayoutSettings               = @"showLayoutSettings";
NSString * const MNSIdentifierSegueShowAddDatabaseDrivers           = @"MNSIdentifierSegueShowAddDatabaseDrivers";

static NSString * const NSFetchedResultsCacheName                          = @"NSFetchedResultsCacheName";
static NSString * const NSFetchedResultsCacheTables                        = @"NSFetchedResultsCacheTables";
static NSString * const NSFetchedResultsCacheLinks                         = @"NSFetchedResultsCacheLinks";
static NSString * const NSFetchedResultsCacheGroups                        = @"NSFetchedResultsCacheGroups";
static NSString * const NSFetchedResultsCachePredicates                    = @"NSFetchedResultsCachePredicates";

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

    @property (nonatomic, assign) bool suspendAutomaticTrackingOfChangesInManagedObjectContext;

    @property (nonatomic, strong) UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, strong) UIBarButtonItem *barButtonItemDone;

    @property (nonatomic, strong) NSFetchedResultsController *queryTablesController;
    @property (nonatomic, strong) NSFetchedResultsController *queryLinksController;
    @property (nonatomic, strong) NSFetchedResultsController *queryGroupsController;
    @property (nonatomic, strong) NSFetchedResultsController *queryPredicatesController;

    @property (nonatomic, assign) BOOL beganUpdates;
    @property (nonatomic, assign) BOOL toolbarIconShown;

    @property (atomic, assign) NSInteger lastSelectedRowNumber;

    @property (nonatomic, assign) CGFloat headerSectionHeight;

    - (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)sec;
    - (MTQuerySections)sectionPositionForTableSectionType:(MTQuerySections)sec;

@end

@implementation MADQueryViewController

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
                        [super viewControllerForUnwindSegueAction: action fromViewController: fromViewController
                                                       withSender: sender];
}

#pragma mark - Static

+ (void)deleteCoreDataCache {
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
}

#pragma mark - NSObject

- (void)dealloc {
    _document = nil;
    [MADQueryViewController deleteCoreDataCache];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: UIContentSizeCategoryDidChangeNotification
                                                  object: nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setToolbarIconShown:NO];
    }
    return self;
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
    NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    [super viewDidLoad];

    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.tableView.bounds];
    self.tableView.backgroundView = watermarkView;
    
    [self updateInterfaceForPerferedContentSizeCategory:[UIApplication sharedApplication].preferredContentSizeCategory];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleContentSizeCategoryDidChangeNotification:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    [self.tableView registerClass: [MADTableViewCellQueryTableName class]
           forCellReuseIdentifier: @"UITableViewCellTableName"];
    
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.navigationItem.prompt = nil;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                                   target: self
                                                                                   action: @selector(edit:)];
    
    self.barButtonItemEdit = barButtonItem;
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
    }
    [self.tabBarController enableTabBarItems];
    [self.tabBarController.navigationItem setRightBarButtonItem:self.barButtonItemEdit animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: self.document];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.firstTimeViewWillLayoutSubviews) {
        CGRect r = CGRectMake(CGPointZero.x, CGPointZero.y, self.tableView.frame.size.width, 1.0000f);
        [self.tableView scrollRectToVisible: r animated: NO];
        
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: MADSegueShowSql]) {
        MADViewControllerSQL *viewController;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            viewController = (MADViewControllerSQL *)[segue.destinationViewController topViewController];
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
                    
                    MTQueryBuilderAddTableViewController *tvc = (MTQueryBuilderAddTableViewController *)[navControl topViewController];
                    if (tvc) {
                        tvc.delegate = self;
                    }

                    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name"
                                                                                     ascending: YES];
                    request.sortDescriptors = @[sortDescriptor];

                    MADocument *document = self.document;
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: document.managedObjectContext
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

                    MADocument *document = self.document;
                    MTQueryBuilderLinkBuilderViewController *tvc = (MTQueryBuilderLinkBuilderViewController *)navControl.topViewController;
                    tvc.document = document;
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
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderAddGroupViewController class]]) {
                    MTQueryBuilderAddGroupViewController *tvc = (MTQueryBuilderAddGroupViewController *)navControl.topViewController;
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
                    MTReportDesignerSectionLayoutSettingsViewController *tvc = (MTReportDesignerSectionLayoutSettingsViewController *)segue.destinationViewController;
                    if (tvc) {
                        tvc.delegate = self;
                        MADocument *document = self.document;
                        RptqQuery *query = document.activeDocumentModel.defaultDatabase.defaultQuery;
                        RptqDocumentSection *section = [query documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedRowNumber];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.tableView.backgroundView setNeedsDisplay];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { }];
    }
}

#pragma mark - MTQueryBuilderPredicateFormatDelegate

- (void)addQueryPredicate:(RptqQueryPredicate *)predicate {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];
    MADocument *document = self.document;
    [document.activeDocumentModel addPredicate:predicate];
    [document saveContext];
}

#pragma mark - MTReportDesignerSectionLayoutSettingsDelegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MADocument *document = self.document;
    [document.activeDocumentModel setHeight:height forSectionAtRow:(NSUInteger)self.lastSelectedRowNumber];
    [document saveContext];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    MADocument *document = self.document;
    [document.activeDocumentModel setVisibility: isVisible forSectionAtRow:(NSUInteger) self.lastSelectedRowNumber];
    [document saveContext];
}

- (void)layoutSettings:(MTReportDesignerSectionLayoutSettingsViewController *)layoutSettings newPageAfter:(BOOL)newPageAfter {
    MADocument *document = self.document;
    [document.activeDocumentModel setNewPageAfter: newPageAfter forSectionAtRow:(NSUInteger) self.lastSelectedRowNumber];
    [document saveContext];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    MADocument *document = self.document;
    [document.activeDocumentModel setNumberOfRows: numberOfRows forSectionAtRow:(NSUInteger) self.lastSelectedRowNumber];
    [document saveContext];
}

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];
}

#pragma mark - MTQueryBuilderLinkBuilderDelegate

- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)link {

    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];

    MADocument *document = self.document;
    [document.activeDocumentModel addQueryLink:link];
    [document saveContext];
    NSInteger suspectedSection = 2;
    
    MTQuerySections tableSection = [self tableSectionTypeForIndexPathSection:(NSUInteger)suspectedSection];
    if (tableSection == MTQuerySectionsLinks) {
        NSIndexSet *linksSection = [NSIndexSet indexSetWithIndex:(NSUInteger)suspectedSection];
        [self.tableView reloadSections: linksSection withRowAnimation: UITableViewRowAnimationAutomatic];
    }
    [document saveToURL: document.fileURL
            forSaveOperation: UIDocumentSaveForOverwriting completionHandler:nil];
}

#pragma mark - MTQueryBuilderAddGroupDelegate

- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldID andSortOrder:(MNSSortOrder)sortOrder {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];


    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   true];
    [self.document addQueryGroupWithQueryField:queryFieldID andSortOrder:sortOrder];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   false];

    [self performFetchGroups];
}

#pragma mark - MTQueryBuilderAddTableDelegate

- (void)viewControllerSchemaAddTableDidSelectTable:(NSManagedObjectID *)objectID {

    [self dismissViewControllerAnimated:YES completion:^{
        [self.tabBarController enableTabBarItems];
    }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   true];
    [self.document addQuerySelectTableForSchemeTableWithObjectID:       objectID];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:   false];

    [self performFetchTables];
}

#pragma mark - Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id queryBuilderDataModel = [self datamodel];
    NSInteger numberOfSections = (NSInteger)[queryBuilderDataModel[MTTableHeaderSectionKey] count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    MTQuerySections ts = [self tableSectionTypeForIndexPathSection: (NSUInteger)section];
    
    NSDictionary *rowsDict = [self datamodel][MTTableSectionRowKey];
    NSInteger numberOfRows = 0;
    numberOfRows = [rowsDict[[NSNumber numberWithInt: ts]] intValue];
    id<NSFetchedResultsSectionInfo> sectionData;
    if (numberOfRows < 0) {
        switch (ts) {
            case MTQuerySectionsTables: {
                sectionData = self.queryTablesController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MTQuerySectionsLinks: {
                sectionData = self.queryLinksController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MTQuerySectionsPredicate: {
                sectionData = self.queryPredicatesController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MTQuerySectionsGroups: {
                sectionData = self.queryGroupsController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
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
    MTQuerySections sectionType = [self tableSectionTypeForIndexPathSection: (NSUInteger)indexPath.section];
	return (sectionType == MTQuerySectionsTables ||
            sectionType == MTQuerySectionsGroups ||
            sectionType == MTQuerySectionsPredicate ||
            sectionType == MTQuerySectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self tableSectionTypeForIndexPathSection:(NSUInteger)indexPath.section] == MTQuerySectionsGroups) ? YES : NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MTQuerySections querySection = [self tableSectionTypeForIndexPathSection:(NSUInteger)indexPath.section];

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
    MTQuerySections ts = [self tableSectionTypeForIndexPathSection: (NSUInteger)toIndexPath.section];
    switch (ts) {
        case MTQuerySectionsGroups: {

            NSIndexPath *fromIndex = [NSIndexPath indexPathForRow: fromIndexPath.row inSection: 0];
            NSIndexPath *toIndex = [NSIndexPath indexPathForRow: toIndexPath.row inSection: 0];
            RptqQueryGroup *fromGroup = [self.queryGroupsController objectAtIndexPath: fromIndex];
            RptqQueryGroup *toGroup = [self.queryGroupsController objectAtIndexPath: toIndex];
            NSInteger fromWeight = [[toGroup weight] integerValue];
            NSInteger toWeight = [[fromGroup weight] integerValue];
            [toGroup setWeight:@(toWeight)];
            [fromGroup setWeight:@(fromWeight)];
            NSError *error = nil;
            [[self.queryGroupsController managedObjectContext] save:&error];
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
    MTQuerySections section = [self tableSectionTypeForIndexPathSection: (NSUInteger)indexPath.section];

    switch (section) {

        // MARK: Display and identify the data source and data sources
        case MTQuerySectionsDatasource: {
        
            static NSString *MADIdentifierTableViewCellDataSource = @"MADIdentifierTableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MADIdentifierTableViewCellDataSource];

            RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
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

                NSMutableAttributedString *messageAttributed = [[NSMutableAttributedString alloc] initWithString: message attributes: attributes];
                [messageAttributed removeAttribute: NSFontAttributeName range: rangeOfDatabaseTypeName];
                [messageAttributed removeAttribute: NSFontAttributeName range: rangeOfSchemaName];
                [messageAttributed addAttributes: additionalAttributeStroke range: rangeOfDatabaseTypeName];
                [messageAttributed addAttributes: additionalAttributeStroke range: rangeOfSchemaName];
                
                result.textLabel.text = message;
                result.textLabel.attributedText = messageAttributed;
                result.detailTextLabel.text = @"";
                result.tintColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];

            }
            result.textLabel.numberOfLines = 0;
            break;
        }

        // MARK: Display the table names that are used in the query
        case MTQuerySectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryTable *tablea = [self.queryTablesController objectAtIndexPath: path];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            result.textLabel.text = [NSString stringWithFormat:@"%@", tablea.alias];
            result.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            result.textLabel.font = font;
            result.textLabel.backgroundColor = [UIColor whiteColor];
            result.indentationLevel = 1;
            result.tintColor = [MADColorEverydayApps newColorBlue];
            result.backgroundColor = [UIColor whiteColor];
            break;
        }
        
        // MARK: Display the table links or joins that are used in the query.
        case MTQuerySectionsLinks: {

            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [self.queryLinksController objectAtIndexPath: indexPathLinks];
            
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            
            NSString *messageText = @"%@ %@ %@";
            
            NSString *leftString = [NSString stringWithFormat:@"%@.%@", links.tableleft.capitalizedString, links.fieldleft.capitalizedString];
            NSString *rightString = [NSString stringWithFormat:@"%@.%@", links.tableright.capitalizedString, links.fieldright.capitalizedString];

            [(MADTableViewCellQueryLink *)result setTableID: links.objectID];
            result.textLabel.numberOfLines = 0;

            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            paragraphStyle.headIndent = 20.0000f;
            
            NSString *linksDescription = [links linkDescription];
            messageText = [NSString stringWithFormat:messageText, leftString, linksDescription, rightString];
            NSDictionary *attributes = @{ NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle };
            UIColor *color = [MADColorEverydayApps newColorBlue];
            NSDictionary *attributesAlt = @{ NSFontAttributeName : fontCaption, NSForegroundColorAttributeName :  color};
            NSRange rangeLinkDesc = [messageText rangeOfString:linksDescription];
            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString: messageText attributes: attributes];
            [message addAttributes:attributesAlt range:rangeLinkDesc];
            result.textLabel.attributedText = message;

            break;
        }

        // MARK: Display the groupings used in the query.
        case MTQuerySectionsGroups: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            RptqQueryGroup *group = [self.queryGroupsController objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]];
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
            UIColor *color = [MADColorEverydayApps newColorBlue];
            NSDictionary *attributesRight = @{ NSParagraphStyleAttributeName : paragraphStyleLeft, NSFontAttributeName : fontCaption, NSForegroundColorAttributeName :  color };
            NSRange rangeLeft = [messageText rangeOfString:fieldName];
            NSRange rangeRange = [messageText rangeOfString:sortFieldName];
            [message addAttributes:attributesLeft range:rangeLeft];
            [message addAttributes:attributesRight range:rangeRange];
            result.textLabel.text = messageText;
            result.textLabel.attributedText = message;
            result.textLabel.numberOfLines = 0;
            [(MADTableViewCellQueryGroup *)result setTableID:group.objectID];
            break;
        }
        
        // MARK: Display the predicates or conditions on the query.
        case MTQuerySectionsPredicate: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryPredicate";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            
            NSIndexPath *indexPathPredicates = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryPredicate *predicate = [self.queryPredicatesController objectAtIndexPath: indexPathPredicates];
            
            NSString *leftFieldDisplay = nil, *rightFieldDisplay = nil;
            if ([predicate fieldleftpred] != nil) {
                leftFieldDisplay = predicate.fieldleftpred;
            } else {
                leftFieldDisplay = [predicate.hasLeftField toString];
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
            UIColor *color = [MADColorEverydayApps newColorBlue];
            NSDictionary *attributesCaption = @{ NSForegroundColorAttributeName :  color };

            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString: messageText
                                                                                        attributes: attributes];
            NSRange rangeMiddle = [messageText rangeOfString:symbol];
            result.textLabel.numberOfLines = 0;
            [message addAttributes: attributesCaption
                             range: rangeMiddle];
            result.textLabel.text = messageText;
            result.textLabel.attributedText = message;
            [(MADTableViewCellQueryPredicate *)result setTableID:[predicate objectID]];
            
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
            
        case MTQuerySectionsNumberOfQueryResults: {
            static NSString *idNumberOfQueryResults = @"UITableViewCellNumberOfQueryResultsIdentifier";
            result = [tableView dequeueReusableCellWithIdentifier: idNumberOfQueryResults];
            UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
            s.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"defaults.everydayapps.features.viewer.desired"];
            [s addTarget:self action:@selector(wantsToChangeReportingMode:) forControlEvents:UIControlEventValueChanged];
            result.accessoryView = s;
            result.textLabel.text = [[NSUserDefaults standardUserDefaults] boolForKey:@"defaults.everydayapps.features.viewer.desired"] ? @"Reporting Mode" : @"Designer Mode (limited)";
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

- (void)wantsToChangeReportingMode:(UISwitch *)switchControl {
    if (switchControl.on) {
        if ([MTStoreKitController sharedObject].isReportingEnabled) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"defaults.everydayapps.features.viewer.desired"];
        } else {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"defaults.everydayapps.features.viewer.desired"];
            [switchControl setOn:NO animated:YES];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"defaults.everydayapps.features.viewer.desired"];
    }
    // FIXME: This is a hack that I can do because I know this updates the last section in the query.  Kind of a hack.
  //  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:self.tableView.numberOfSections - 1];
    NSIndexPath *i = [NSIndexPath indexPathForItem:0 inSection:self.tableView.numberOfSections - 1];
    NSArray *paths = @[i];
    [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
//    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    
    switch ([self tableSectionTypeForIndexPathSection: (NSUInteger)section]) {
            
        case MTQuerySectionsDatasource:
            return [self tableHeaderDatabaseInfo];
            break;
            
        case MTQuerySectionsTables:
            return [self tableHeaderTablesToSelect];
            break;
            
        case MTQuerySectionsLinks:
            return [self tableHeaderTableJoins];
            break;
            
        case MTQuerySectionsGroups:
            return [self tableHeaderGroupedBy];
            break;
            
        case MTQuerySectionsPredicate:
            return [self tableHeaderPredicate];
            break;

        case MTQuerySectionsNumberOfQueryResults:
            return [self tableHeaderNumberOfQueryResults];
            break;
        
        default:
            return [self tableHeaderDatabaseInfo];
            break;
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self tableSectionTypeForIndexPathSection:(NSUInteger) indexPath.section] == MTQuerySectionsTables) {
        [self displayTableSampleDataForIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.headerSectionHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Remove", @"Remove button title.");
 }

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableView beginUpdates];
        [self setBeganUpdates: YES];
    }
}

- (NSMutableArray *)sectionsUsedByFetchedResultsController: (NSFetchedResultsController *)controller {

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

    NSNumber *sectionNumber;
    if ([controller isEqual:self.queryTablesController]) {
        
        sectionNumber = [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: MTQuerySectionsTables]];
        [result addObject: sectionNumber];

    } else if ([controller isEqual:[self queryLinksController]]) {

        sectionNumber = [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: MTQuerySectionsLinks]];
        [result addObject: sectionNumber];

    } else if ([controller isEqual:self.queryGroupsController]) {

        NSInteger sectionGroup = [self sectionPositionForTableSectionType: MTQuerySectionsGroups];
        sectionNumber = @(sectionGroup);
        [result addObject: sectionNumber];
    
    } else if ([controller isEqual:self.queryPredicatesController]) {
    
        NSInteger section = [self sectionPositionForTableSectionType: MTQuerySectionsPredicate];
        sectionNumber = @(section);
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
            MTQuerySections updateSection = section.unsignedIntegerValue;
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


- (void)controller: (NSFetchedResultsController *)controller didChangeObject: (id)anObject
	   atIndexPath: (NSIndexPath *)indexPath forChangeType: (NSFetchedResultsChangeType)type
	  newIndexPath: (NSIndexPath *)newIndexPath {
    
    NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
    
    for (NSNumber *section in sections) {
        MTQuerySections updateSection = section.unsignedIntegerValue;
        
        NSIndexPath *path = [NSIndexPath indexPathForRow: indexPath.row
                                               inSection: updateSection];
        if (path) {
            if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
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
    [self performFetchWithController:self.queryTablesController];
}

- (void)performFetchLinks {
    [self performFetchWithController:[self queryLinksController]];
}

- (void)performFetchGroups {
    [self performFetchWithController:self.queryGroupsController];
}

- (void)performFetchPredicate {
    [self performFetchWithController:self.queryPredicatesController];
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
    
    BOOL editing = !self.tableView.isEditing;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: !editing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone
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
        
        {
            
            RptqDatabase *database = reportDocument.activeDocumentModel.hasDatabaseSchemas.anyObject;
            RptqQuery *query = database.hasQueries.anyObject;
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", query.objectID];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias"
                                                                             ascending: YES];
            [request setSortDescriptors: @[sortDescriptor]];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = self;
            [self setQueryTablesController: frc];
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
            [self setQueryLinksController: frc];
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
            [self setQueryGroupsController: frc];
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
            [self setQueryPredicatesController: frc];
            [self performFetchPredicate];
            frc = nil;
        }
        [self.tableView reloadData];
    }
}

- (NSMutableDictionary *)datamodel {
    
    RptqDatabase *database = [self.document.activeDocumentModel defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    
    NSDictionary *datamodelForNumberOfTables = [self datamodelForNumberOfTables:(NSInteger)query.hasQueryTables.count];
    NSMutableDictionary * __autoreleasing result = [[NSMutableDictionary alloc] initWithDictionary:datamodelForNumberOfTables];
    return result;
}

- (NSDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables {
    
    NSDictionary *result;
    
    NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
    NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
    NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
    NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
    NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
    NSString *h7 = NSLocalizedString(@"Reporting Mode", @"Reporting Mode");

    NSNumber *one = @(1);
    NSNumber *unknown = @(-1);
    NSNumber *datasource = @(MTQuerySectionsDatasource);
    NSNumber *tables = @(MTQuerySectionsTables);
    NSNumber *resultCount = @(MTQuerySectionsNumberOfQueryResults);

    BOOL reportingEnabled = [[MTStoreKitController sharedObject] isReportingEnabled];
    switch (numberOfTables) {
        case 0: { //There are three configurations for the table.  These configurations depend on the number of schemas in the query: zero, one, or more than one.
            
            NSArray *sections = reportingEnabled ? @[datasource, tables, resultCount] :
                                                   @[datasource, tables];
            NSArray *countRowsForSection = reportingEnabled ? @[one, unknown, one] : @[one, unknown];
            NSDictionary *countRowsForSectionDictionary =  [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                       forKeys: sections];
            
            NSArray *headersSection = reportingEnabled ? @[h2, h3, h7] : @[h2, h3];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                 forKeys: sections];
            NSNumber *height1 = @(50.0000f);
            NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
            NSArray *heightRowsForSection = reportingEnabled ? @[height1, height2, height1] : @[height1, height2]; 
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
                                                                                                 forKeys: sections];
            result = @{MTTableSectionSectionsKey : sections,
                       MTTableHeaderSectionKey : headersSectionDictionary,
                       MTTableSectionRowKey : countRowsForSectionDictionary,
                       MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};
            
            
            break;
        }
        case 1: {   //Only one table in query.  No ability to add links.
            
            NSNumber *groups = @(MTQuerySectionsGroups);
            NSNumber *predicate = @(MTQuerySectionsPredicate);

            NSArray *sections = reportingEnabled ? @[datasource, tables, groups, predicate, resultCount] :
                                                   @[datasource, tables, groups, predicate];
            
            NSArray *countRowsForSection = reportingEnabled ? @[one, unknown, unknown, unknown, one] :
                                                              @[one, unknown, unknown, unknown];
            NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                      forKeys: sections];
            
            NSArray *headersSection = reportingEnabled ? @[h2, h3, h5, h6, h7] : @[h2, h3, h5, h6];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                 forKeys: sections];
            
            NSNumber *height1 = @(44.0000f);
            NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
            NSArray *heightRowsForSection = reportingEnabled ? @[height1, height2, height1, height1, height1] :
                                                               @[height1, height2, height1, height1];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
                                                                                                 forKeys: sections];
            
            result = @{MTTableSectionSectionsKey : sections,
                       MTTableHeaderSectionKey : headersSectionDictionary,
                       MTTableSectionRowKey : countRowsForSectionDictionary,
                       MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};
            
            break;
        }
        default: {   //Two more more tables in query.  All features available.
            
            NSNumber *links = @(MTQuerySectionsLinks);
            NSNumber *groups = @(MTQuerySectionsGroups);
            NSNumber *predicate = @(MTQuerySectionsPredicate);

            NSArray *sections = reportingEnabled ? @[datasource, tables, links, groups, predicate, resultCount] :
                                                   @[datasource, tables, links, groups, predicate];
            
            NSArray *countRowsForSection = reportingEnabled ? @[one, unknown, unknown, unknown, unknown, one] :
                                                              @[one, unknown, unknown, unknown, unknown];
            NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                      forKeys: sections];
            
            NSArray *headersSection = reportingEnabled ? @[h2, h3, h4, h5, h6, h7] :
                                                         @[h2, h3, h4, h5, h6];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                 forKeys: sections];
            NSNumber *height1 = @(44.0000f);
            NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
            NSNumber *height3 = @([MADTableViewCellQueryLink defaultHeight]);    //50.0000f
            NSArray *heightRowsForSection = reportingEnabled ? @[height1, height2, height3, height1, height1, height1] :
                                                               @[height1, height2, height3, height1, height1];
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
    header.buttonAdd.isAccessibilityElement = NO;
    return header;
}

- (MTViewTableHeader *)tableHeaderTablesToSelect {
    NSString *title = NSLocalizedString(@"Tables", @"Tables");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self
                         action: @selector(addTable:)
               forControlEvents: UIControlEventTouchUpInside];
    header.buttonAdd.isAccessibilityElement = YES;
    header.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
    header.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table.", @"Adds a new table.");
    return header;
}

- (MTViewTableHeader *)tableHeaderTableJoins {
    NSString *title = NSLocalizedString(@"Joins", @"Joins");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self
                         action: @selector(addLink:)
               forControlEvents: UIControlEventTouchUpInside];
    header.buttonAdd.isAccessibilityElement = YES;
    header.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
    header.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table join.", @"Adds a new table join.");
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
    header.buttonAdd.isAccessibilityElement = YES;
    header.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
    header.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new query grouping.", @"Adds a new query grouping.");
    return header;
}

- (MTViewTableHeader *)tableHeaderNumberOfQueryResults {
    NSString *title = NSLocalizedString(@"Limit Query Results", @"Limit Query Reuslts");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    header.buttonAdd.enabled = NO;
    header.buttonAdd.hidden = YES;
    [header.labelTitle sizeToFit];
    header.buttonAdd.isAccessibilityElement = NO;
    return header;
}

- (MTViewTableHeader *)tableHeaderPredicate {
    SEL selector = @selector(addPredicate:);
    NSString *title = NSLocalizedString(@"Having Specified Criteria", @"Having Specified Criteria");
    MTViewTableHeader *header = [self tableHeader];
    header.labelTitle.text = title;
    [header.buttonAdd addTarget: self action: selector forControlEvents: UIControlEventTouchUpInside];
    [header.labelTitle sizeToFit];
    header.buttonAdd.isAccessibilityElement = YES;
    header.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
    header.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a predicate to filter the query results.", @"Adds a predicate to filter the query results.");
    return header;
}

- (MTViewTableHeader *)tableHeader {
    MTViewTableHeader *tableHeader = [[MTViewTableHeader alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 320.0000f, self.headerSectionHeight)];
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
    
    UIFont *fontb = [UIFont fontWithName: @"HelveticaNeue-Light" size: 20.0000f];
    UIFont *fonti = [UIFont fontWithName: @"HelveticaNeue-LightItalic" size: 18.0000f];
    
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
    
    NSIndexPath *indexPathUpdate = [NSIndexPath indexPathForRow: indexPath.row inSection: 0];
    RptqQueryTable *table = [self.queryTablesController objectAtIndexPath: indexPathUpdate];
    MTTableController *tableController = [self tableControllerForTable:table];
    [self.navigationController pushViewController: tableController animated: YES];

}

- (NSArray <__kindof NSIndexPath *> *)deleteLinksRelatedToSectionIndex:(NSInteger)section table:(NSManagedObjectID *)deleatedTableObjectId
                                                           inTableView:(UITableView *)tableView numberOfTables:(NSInteger)numberOfTables
                                                             inContext:(NSManagedObjectContext *)context {
    
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    
    NSFetchedResultsController *fetchedLinkes = self.queryLinksController;
    
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
    
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = nil;
        NSManagedObject *object = nil;
        MADTableViewCellQueryLink *tableViewCellLink = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
        if (tableViewCellLink) {
            object = [context existingObjectWithID:[tableViewCellLink tableID] error:&error];
        } else {
            
            id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedLinkes sections] objectAtIndex:0];
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
                NSIndexPath *deleteCellAtIndex = linkIndexPath.copy;
                [cellsToDelete addObject:deleteCellAtIndex];
            }
        }
    }
    return cellsToDelete;
}

- (NSArray <__kindof NSIndexPath *> *)deleteGroupsRelatedToSectionIndex:(NSInteger)section table:(NSManagedObjectID *)deleatedTableObjectId
                                                            inTableView:(UITableView *)tableView numberOfTables:(NSInteger)numberOfTables
                                                              inContext:(NSManagedObjectContext *)context {
    
    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
        NSIndexPath *groupIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        NSError *error = nil;

        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.queryGroupsController sections] objectAtIndex:0];
        if (row < (NSInteger)sectionInfo.numberOfObjects) {
            NSIndexPath *testGroupIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            NSManagedObject *object = [self.queryGroupsController objectAtIndexPath:testGroupIndexPath];
            
            if (!error && object && [object isKindOfClass:[RptqQueryGroup class]]) {
                RptqQueryGroup *groupToRemove = (RptqQueryGroup *)object;
                
                if ([groupToRemove.hasField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {
                    [self.document removeGroup:groupToRemove fromManagedObjectContext:context];
                    NSIndexPath *deleteCellAtIndex = groupIndexPath.copy;
                    [cellsToDelete addObject:deleteCellAtIndex];
                }
            }

        }
    }
    return cellsToDelete;
}

- (NSArray <__kindof NSIndexPath *> *)deletePredicateRelatedToSectionIndex:(NSInteger)section table:(NSManagedObjectID *)deleatedTableObjectId
                                                               inTableView:(UITableView *)tableView numberOfTables:(NSInteger)numberOfTables
                                                                 inContext:(NSManagedObjectContext *)context {

    NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
    NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];

    for (NSInteger row = 0; row < numberOfRowsInSection; row++) {

        NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        
        
        MADTableViewCellQueryPredicate *tableViewCellPredicate = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:predicateIndexPath];
        NSError *error = nil;
        NSManagedObject *object = nil;
        
        if (tableViewCellPredicate) {
            object = [context existingObjectWithID:[tableViewCellPredicate tableID] error:&error];
        } else {
            NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            object = [self.queryPredicatesController objectAtIndexPath: testPredicateIndexPath];
        }
        
        if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
        
            RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;

            bool deleted = false;
            if ([predicateToRemove.hasLeftField.inQueryTable.objectID isEqual:deleatedTableObjectId]) {

                [context deleteObject:predicateToRemove];
                
                NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
                [cellsToDelete addObject:deleteCellAtIndex];
                deleted = true;
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

- (NSArray *)deleteLinksGroupsPredicatesRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                           inTableView:(UITableView *)tableView
                                        numberOfTables:(NSInteger)numberOfTables
                                             inContext:(NSManagedObjectContext *)private {
    
    NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
    for (NSUInteger section = 0; section < (NSUInteger)tableView.numberOfSections; section++) {
        
        NSArray *cells;
        MTQuerySections querySection = [self tableSectionTypeForIndexPathSection: section withNumberOfTables: numberOfTables + 1];

        if (querySection == MTQuerySectionsLinks) {
            
            cells = [self deleteLinksRelatedToSectionIndex: (NSInteger)section table: deleatedTableObjectId
                                               inTableView: tableView
                                            numberOfTables: numberOfTables
                                                 inContext: private];
            
        } else if (querySection == MTQuerySectionsGroups) {

            cells = [self deleteGroupsRelatedToSectionIndex: (NSInteger)section table: deleatedTableObjectId
                                                inTableView: tableView
                                             numberOfTables: numberOfTables
                                                  inContext: private];
            
        } else if (querySection == MTQuerySectionsPredicate) {
            
            cells = [self deletePredicateRelatedToSectionIndex: (NSInteger)section table: deleatedTableObjectId
                                                   inTableView: tableView
                                                numberOfTables: numberOfTables
                                                     inContext: private];
            
        }
        [cellsToDelete addObjectsFromArray:cells];
    }
    return cellsToDelete;
}

- (NSIndexSet *)deleteSections:(NSArray *)oldLayoutSectionTypes newSections:(NSArray *)newLayoutSectionTypes {

    NSIndexSet *deleteSections = nil;
    if (oldLayoutSectionTypes.count > newLayoutSectionTypes.count) {
        NSInteger secctr = 0;
        bool startIndexSet = false;
        NSInteger startIndex = -1;
        
        NSInteger lengtho = (NSInteger)(oldLayoutSectionTypes.count - newLayoutSectionTypes.count);
        for (NSNumber *typenum in oldLayoutSectionTypes) {
        
            MTQuerySections stsection = typenum.unsignedIntegerValue;
            if (secctr < (NSInteger)newLayoutSectionTypes.count) {
            
                if (stsection == ((NSNumber *)newLayoutSectionTypes[(NSUInteger)secctr]).integerValue) {
                
                    secctr++;
                    
                } else {
                    if (!startIndexSet) {
                        startIndex = secctr;
                        startIndexSet = true;
                    }
                }
            } else {
                if (!startIndexSet) {
                    startIndex = secctr;
                    startIndexSet = true;
                }
                secctr++;
            }
        }
        
        if (startIndex >= 0 && lengtho > 0) {
            NSRange sectionRange = NSMakeRange((NSUInteger)startIndex, (NSUInteger)lengtho);
            deleteSections = [[NSIndexSet alloc] initWithIndexesInRange: sectionRange];
        }
    }
    return deleteSections;
}

- (void)deleteQueryPredicateFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    MADocument *document = self.document;
    MADTableViewCellQueryPredicate *cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *objid = cell.tableID;
    NSManagedObject *predicate = [document.managedObjectContext objectRegisteredForID:objid];
    [document.managedObjectContext deleteObject:predicate];
    [document.managedObjectContext save:nil];
}

- (void)deleteItemFromQuerySection:(MTQuerySections)querySection fromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    switch (querySection) {
            
        case MTQuerySectionsTables:
            [self deleteQueryTableFromTableView: tableView atIndexPath: indexPath];
            break;
            
        case MTQuerySectionsLinks:
            [self deleteQueryLinksFromTableView: tableView atIndexPath: indexPath];
            break;
            
        case MTQuerySectionsGroups:
            [self deleteQueryGroupFromTableView: tableView atIndexPath: indexPath];
            break;
            
        case MTQuerySectionsPredicate:
            [self deleteQueryPredicateFromTableView: tableView atIndexPath: indexPath];
            break;
            
        default:
            break;
    }
}

- (void)deleteQueryTableFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    self.suspendAutomaticTrackingOfChangesInManagedObjectContext = true;
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    [private performBlockAndWait:^{
        
        RptqDocument *rptqDocument = [RptqDocument documentForManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
        
        NSInteger numberOfTables = (NSInteger)rptqQuery.hasQueryTables.count;
        
        NSDictionary *oldTableLayoutResult = [self datamodelForNumberOfTables: numberOfTables];
        NSDictionary *oldTableLayout = [[NSDictionary alloc] initWithDictionary:oldTableLayoutResult];
        
        NSIndexPath *tableIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 0];
        RptqQueryTable *table = [self.queryTablesController objectAtIndexPath: tableIndex];
        
        NSManagedObjectID *deleatedTableObjectId = table.objectID.copy;
        [rptqQuery removeHasQueryTablesObject:table];
        numberOfTables--;
        
        NSDictionary *newTableLayoutResult = [self datamodelForNumberOfTables: numberOfTables];
        
        NSDictionary *newTableLayout = [[NSDictionary alloc] initWithDictionary: newTableLayoutResult];
        
        NSArray *oldLayoutSectionTypes = oldTableLayout[MTTableSectionSectionsKey];
        NSArray *newLayoutSectionTypes = newTableLayout[MTTableSectionSectionsKey];
        
        NSIndexSet *deleteSections = [self deleteSections:oldLayoutSectionTypes newSections:newLayoutSectionTypes];
        
        [tableView beginUpdates];
        
        MADocument *document =  self.document;
        [document deleteDatafieldsRelatedToTable:deleatedTableObjectId inContent:private];
        [document deleteAggregateFieldRelatedToTable:deleatedTableObjectId inContent:private];
        
        NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
        for (NSUInteger section = 0; section < (NSUInteger)tableView.numberOfSections; section++) {
            
            NSArray *cells;
            MTQuerySections querySection = [self tableSectionTypeForIndexPathSection: section withNumberOfTables: numberOfTables + 1];
            
            if (querySection == MTQuerySectionsLinks) {
                
                cells = [self deleteLinksRelatedToSectionIndex: (NSInteger)section table: deleatedTableObjectId
                                                   inTableView: tableView
                                                numberOfTables: numberOfTables
                                                     inContext: private];
                
            } else if (querySection == MTQuerySectionsGroups) {
                
                cells = [self deleteGroupsRelatedToSectionIndex: (NSInteger)section table: deleatedTableObjectId
                                                    inTableView: tableView
                                                 numberOfTables: numberOfTables
                                                      inContext: private];
                
            } else if (querySection == MTQuerySectionsPredicate) {
                
                cells = [self deletePredicateRelatedToSectionIndex: (NSInteger)section table: deleatedTableObjectId
                                                       inTableView: tableView
                                                    numberOfTables: numberOfTables
                                                         inContext: private];
                
            }
            [cellsToDelete addObjectsFromArray:cells];
        }
        
        NSError * __autoreleasing *error = nil;
        [private save:error];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            NSArray *indexPaths = @[indexPath];
            if (deleteSections != nil) {
                [tableView deleteSections: deleteSections withRowAnimation: UITableViewRowAnimationAutomatic];
                [tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            if (cellsToDelete.count) {
                [tableView deleteRowsAtIndexPaths:cellsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            [tableView endUpdates];
            
            self.suspendAutomaticTrackingOfChangesInManagedObjectContext = false;
            
        }];
        
    }];
}

- (void)deleteQueryLinksFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
    NSManagedObjectID *tableID = cell.tableID;
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    [private performBlockAndWait:^{
        
        NSManagedObject *table = [private objectRegisteredForID:tableID];
        [private deleteObject:table];
        
        NSError * __autoreleasing *error = nil;
        [private save:error];
        
    }];
}

- (void)deleteQueryGroupFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    [private performBlockAndWait:^{
    
        RptqDocument *rptqDocument = [RptqDocument documentForManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
        RptqQueryGroup *groupToRemove = [rptqQuery queryGroupForIndex:(NSUInteger)indexPath.row];
        [self.document removeGroup:groupToRemove fromManagedObjectContext:private];
        
        NSError * __autoreleasing * error = NULL;
        [private save:error];

    }];
}

// MARK: Modal helper

- (MTQuerySections)tableSectionTypeForIndexPathSection:(MTQuerySections)section withNumberOfTables:(NSInteger)numberOfTables {
    MTQuerySections result = section;
    NSDictionary *dataModel = [self datamodelForNumberOfTables:numberOfTables];
    NSArray *sectionTypes = dataModel[MTTableSectionSectionsKey];
    if ([sectionTypes count] >= section) {
        NSNumber *sectionType = sectionTypes[section];
        result = sectionType.unsignedIntegerValue;
    }
    return result;
}

- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)section {
    MTQuerySections result = section;
    NSDictionary *datamodel = [self datamodel];
    NSArray *sectionTypes = datamodel[MTTableSectionSectionsKey];
    if (sectionTypes.count >= section) {
        NSNumber *sectionType = sectionTypes[section];
        result = sectionType.unsignedIntegerValue;
    }
    return result;
}

- (MTQuerySections)sectionPositionForTableSectionType:(MTQuerySections)sec {
    MTQuerySections result = 0;
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection: 1];
    NSDictionary *datamodel = [self datamodelForNumberOfTables:numberOfRows];
    NSArray *sectionTypes = datamodel[MTTableSectionSectionsKey];
    NSInteger secPos = 0;
    
    for (NSNumber *num in sectionTypes) {
        if (num.unsignedIntegerValue == sec) {
            result = (MTQuerySections)secPos;
            break;
        }
        secPos++;
    }
    return result;
}

#pragma mark - UIAccessibility

- (BOOL)accessibilityPerformEscape {
    [self.delegate viewControllerDidFinish:nil];
    return YES;
}

@end
