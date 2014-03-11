//
//  MUIViewControllerQueryBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderViewController.h"
#import "MTQueryBuilderAddTableViewController.h"
#import "MTQueryBuilderAddGroupViewController.h"
#import "MTQueryBuilderPredicateFormatViewController.h"
#import "UITableViewCellInstruction.h"
#import "UITableViewCellTableName.h"
#import "UITableViewCellQueryLink.h"
#import "UITableViewCellOverride.h"
#import "UITableViewCellQueryInput.h"
#import "UITableViewCellQueryGroup.h"
#import "MTTableViewCellQueryPredicate.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MTQueryBuilderLinkBuilderViewController.h"
#import "MTReportDesignerViewController.h"
#import "MTViewTableHeader.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

NSString * const MTSegueCloseDesigner               = @"MTSegueCloseDesigner";
NSString * const NSFetchedResultsCacheName          = @"NSFetchedResultsCacheName";
NSString * const NSFetchedResultsCacheTables        = @"NSFetchedResultsCacheTables";
NSString * const NSFetchedResultsCacheLinks         = @"NSFetchedResultsCacheLinks";
NSString * const NSFetchedResultsCacheGroups        = @"NSFetchedResultsCacheGroups";
NSString * const NSFetchedResultsCachePredicates    = @"NSFetchedResultsCachePredicates";

#pragma mark - Private Category

@interface MTQueryBuilderViewController()
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
        MTQueryBuilderPredicateFormatDelegate>

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemShowSQL;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemDone;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsControllerTables;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsControllerLinks;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsControllerGroups;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsControllerPredicates;

@property (nonatomic, retain) UIFont *boldSystemFont;

@property (nonatomic, assign) BOOL beganUpdates;
@property (nonatomic, assign) BOOL toolbarIconShown;

@property (assign) NSInteger lastSelectedRowNumber;

@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsDocumentGroups;
@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsDatasource;
@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsTables;
@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsLinks;
@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsGroups;
@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsPredicate;
@property (nonatomic, retain) MTViewTableHeader *viewTableHeaderQuerySectionsSql;


- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)sec;
- (NSUInteger)sectionPositionForTableSectionType:(MTQuerySections)sec;

@end

#pragma mark - Main

@implementation MTQueryBuilderViewController

- (void)dealloc {
    [_boldSystemFont release];
    [_barButtonItemShowSQL release];
    [_barButtonItemEdit release];
    [_barButtonItemDone release];
    
    [_viewTableHeaderQuerySectionsDocumentGroups release];
    [_viewTableHeaderQuerySectionsDatasource release];
    [_viewTableHeaderQuerySectionsTables release];
    [_viewTableHeaderQuerySectionsLinks release];
    [_viewTableHeaderQuerySectionsGroups release];
    [_viewTableHeaderQuerySectionsPredicate release];
    [_viewTableHeaderQuerySectionsSql release];

    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];

    [_fetchedResultsControllerTables release];
    [_fetchedResultsControllerLinks release];
    [_fetchedResultsControllerGroups release];
    [_fetchedResultsControllerPredicates release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action {
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[[self navigationItem] titleView] sizeToFit];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [self setToolbarIconShown:NO];
        
        CGRect headerRect = CGRectMake(0.0000f, 0.0000f, 320.0000f, 29.0000f);
        
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        UIColor *color = [UIColor whiteColor];
        
        MTViewTableHeader *viewTableHeaderDocumentGroups = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        [[viewTableHeaderDocumentGroups labelTitle] setText:NSLocalizedString(@"Report Sections", @"Sections")];
        [[viewTableHeaderDocumentGroups labelTitle] setFont:font];
        [[viewTableHeaderDocumentGroups buttonAdd] setHidden:YES];
        [[viewTableHeaderDocumentGroups labelTitle] setTextColor:color];
        [self setViewTableHeaderQuerySectionsDocumentGroups:viewTableHeaderDocumentGroups];
        [viewTableHeaderDocumentGroups release];
        
        MTViewTableHeader *viewTableHeaderDatasource = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        NSString *datasource = NSLocalizedString(@"Query Datasource", @"Query Datasource");
        [[viewTableHeaderDatasource labelTitle] setText:datasource];
        [[viewTableHeaderDatasource labelTitle] setFont:font];
        [[viewTableHeaderDatasource labelTitle] setTextColor:color];
        [[viewTableHeaderDatasource buttonAdd] setHidden:YES];
        [self setViewTableHeaderQuerySectionsDatasource:viewTableHeaderDatasource];
        [viewTableHeaderDatasource release];
        
        MTViewTableHeader *viewTableHeaderTables = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        NSString *queryTables = NSLocalizedString(@"Tables to Select", @"Tables to Select");
        [[viewTableHeaderTables labelTitle] setText:queryTables];
        [[viewTableHeaderTables labelTitle] setFont:font];
        [[viewTableHeaderTables labelTitle] setTextColor:color];
        [[viewTableHeaderTables buttonAdd] addTarget:self action:@selector(addTable:) forControlEvents:UIControlEventTouchUpInside];
        [self setViewTableHeaderQuerySectionsTables:viewTableHeaderTables];
        [viewTableHeaderTables release];
        
        MTViewTableHeader *viewTableHeaderLinks = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        NSString *queryLinks = NSLocalizedString(@"Table Joins", @"Table Joins");
        [[viewTableHeaderLinks labelTitle] setText:queryLinks];
        [[viewTableHeaderLinks labelTitle] setFont:font];
        [[viewTableHeaderLinks labelTitle] setTextColor:color];
        [[viewTableHeaderLinks buttonAdd] addTarget:self action:@selector(addLink:) forControlEvents:UIControlEventTouchUpInside];
        [self setViewTableHeaderQuerySectionsLinks:viewTableHeaderLinks];
        [viewTableHeaderLinks release];
        
        MTViewTableHeader *viewTableHeaderGroups = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        [[viewTableHeaderGroups labelTitle] setText:NSLocalizedString(@"Grouped By", @"Grouped By")];
        [[viewTableHeaderGroups labelTitle] setFont:font];
        [[viewTableHeaderGroups labelTitle] setTextColor:color];
        [[viewTableHeaderGroups buttonAdd] addTarget:self action:@selector(addGroup:) forControlEvents:UIControlEventTouchUpInside];
        [self setViewTableHeaderQuerySectionsGroups:viewTableHeaderGroups];
        [viewTableHeaderGroups release];
        
        MTViewTableHeader *viewTableHeaderPredicate = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        [[viewTableHeaderPredicate labelTitle] setText:NSLocalizedString(@"Having Specified Criteria", @"Next to the button to add database tables.")];
        [[viewTableHeaderPredicate labelTitle] setFont:font];
        [[viewTableHeaderPredicate labelTitle] setTextColor:color];
        [[viewTableHeaderPredicate buttonAdd] addTarget:self action:@selector(addPredicate:) forControlEvents:UIControlEventTouchUpInside];
        [self setViewTableHeaderQuerySectionsPredicate:viewTableHeaderPredicate];
        [viewTableHeaderPredicate release];
        
        MTViewTableHeader *viewTableHeaderSql = [[MTViewTableHeader alloc] initWithFrame:headerRect];
        [[viewTableHeaderSql labelTitle] setText:NSLocalizedString(@"Build Query", @"Build Query")];
        [[viewTableHeaderSql labelTitle] setFont:font];
        [[viewTableHeaderSql labelTitle] setTextColor:color];
        [[viewTableHeaderSql buttonAdd] setHidden:YES];
        [self setViewTableHeaderQuerySectionsSql:viewTableHeaderSql];
        [viewTableHeaderSql release];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIDevice isPad] == NO) {
        
        UIColor *barTintColor = [UIColor tintColor];
        UIColor *tintColor = [UIColor tintColor2];
        UIToolbar *toolbar = [[self navigationController] toolbar];
        [toolbar setBarTintColor:barTintColor];
        [toolbar setTintColor:tintColor];
        
        UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
        [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        NSAttributedString *attributedString = [[MTApplicationInstance localizedAttributedApplicationNameMadQuery] retain];
        [labelMadDesigner setAttributedText:attributedString];
        [[self navigationItem] setTitleView:labelMadDesigner];
        [[[self navigationItem] titleView] sizeToFit];
        [attributedString release];
        [labelMadDesigner release];
    }
    
    [self setBoldSystemFont:[[[UIFont boldSystemFontOfSize:([UIFont systemFontSize] + 3.0000f)] retain] autorelease]];
    
    //[self disableUserInteraction];
    
    NSMutableArray *toolbarButtons = [[self toolbarItems] mutableCopy];
    [toolbarButtons removeObjectsInArray:@[[self barButtonItemShowSQL], [self barButtonItemDone]]];
    [self setToolbarItems:toolbarButtons animated:NO];
    [toolbarButtons release];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [[applicationInstance activeDocument] retain];

    if (reportDocument) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentStateChanged)
                                                     name:UIDocumentStateChangedNotification
                                                   object:reportDocument];
    }

    if ([self toolbarIconShown] == NO && [self barButtonItemShowSQL] != nil) {   //i.e. iPad version
        __block MTQueryBuilderViewController *blockSelf = self;
        [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
            if (isLicensedUser) {
                
                [blockSelf setToolbarIconShown:YES];
                
                NSMutableArray *toolbarButtons = [[blockSelf toolbarItems] mutableCopy];
                NSInteger index = [toolbarButtons count] - 1;
                UIBarButtonItem *barButtonItemFlexableSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
                UIBarButtonItem *barButtonItemFixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
                [barButtonItemFixedSpace setWidth:20.0000f];
                [toolbarButtons insertObject:[blockSelf barButtonItemShowSQL] atIndex:index+1];
                //[toolbarButtons insertObject:barButtonItemFlexableSpace atIndex:index];
                [toolbarButtons insertObject:barButtonItemFixedSpace atIndex:index+1];
                
                
                [blockSelf setToolbarItems:toolbarButtons animated:animated];
                [toolbarButtons release];
                [barButtonItemFlexableSpace release];
            }
        }];
    }
    [reportDocument release];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [[self tableView] reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: reportDocument];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController { }

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowDatabasesDrivers]) {                  // MARK: Prepair to show database drivers.
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTDatabaseDriverSelectorViewController class]]) {
                    MTDatabaseDriverSelectorViewController *tvc = (MTDatabaseDriverSelectorViewController *)[[navControl topViewController] retain];
                    if (tvc) [tvc setDelegate:self];
                    [tvc release];
                }
            }
            [navControl release];
        }
        [[segue destinationViewController] setDelegate:self];

    } else if ([[segue identifier] isEqualToString: MNSSegueShowSql]) {                                 // MARK:
        MTViewController *viewController;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            viewController = (MTViewController *)[[segue destinationViewController] topViewController];
        } else {
            viewController = [segue destinationViewController];
        }
        [viewController setDelegate:self];
        
    } else if ([[segue identifier] isEqualToString: MNSIdentifierSegueShowAddTableViewController]) {    // MARK: Prepair to show database drivers.
        
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderAddTableViewController class]]) {
                    
                    MTQueryBuilderAddTableViewController *tvc = (MTQueryBuilderAddTableViewController *)[navControl topViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                    }

                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

                    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                    MAReportDocument *reportDocument = [applicationInstance activeDocument];

                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [reportDocument managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: NSFetchedResultsCacheName];
                    [tvc setFetchedResultsController: frc];
                    [frc release];
                }
            }
            [navControl release];
        }

    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowAddLinkViewController]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderLinkBuilderViewController class]]) {
                    
                    MTQueryBuilderLinkBuilderViewController *tvc = (MTQueryBuilderLinkBuilderViewController *)[navControl topViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                    }
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowAddPredicateViewController]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            //NSLog(@"Top View Controller: %@", [navControl topViewController]);
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderPredicateFormatViewController class]]) {
                    MTQueryBuilderPredicateFormatViewController *tvc = (MTQueryBuilderPredicateFormatViewController *)[navControl topViewController];
                    if (tvc) {
                        [tvc setDelegate: self];
                    }
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowAddGroupViewController]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderAddGroupViewController class]]) {
                    MTQueryBuilderAddGroupViewController *tvc = (MTQueryBuilderAddGroupViewController *)[navControl topViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                    }
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowLayoutSettings]) {
                if ([[segue destinationViewController] isKindOfClass:[MTReportDesignerSectionLayoutSettingsViewController class]]) {
                    MTReportDesignerSectionLayoutSettingsViewController *tvc = (MTReportDesignerSectionLayoutSettingsViewController *)[segue destinationViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                        
                        RptqQuery *query = [AppDelegate activeRptqQuery];
                        RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                                                             forQuery: query];
                        [tvc setInitalStepperValue:([[section height] floatValue])];
                        [tvc setInitalSwitchValue:[[section visibility] boolValue]];
                        [tvc setInitalNumberOfRows:[[section numberOfRows] integerValue]];
                    }
                }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowReportLayout]) {
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            [(MTViewController *)[[segue destinationViewController] topViewController] setDelegate: self];
        } else {
            [[segue destinationViewController] setDelegate: self];
        }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowReportViewerFromQuery]) {
        [[segue destinationViewController] setDelegate: self];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerformSegueWithIdentifier = [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    if ([identifier isEqualToString:MTSegueCloseDesigner]) {
        NSError *error = nil;

        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];

        [[reportDocument managedObjectContext] save:&error];
        if (error != nil) {
            [[reportDocument managedObjectContext] save:&error];
        }
    }
    return shouldPerformSegueWithIdentifier;
}

- (void)documentStateChanged {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    UIDocumentState state = [reportDocument documentState];
    switch (state) {
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
    [[self tableView] setUserInteractionEnabled:YES];
}

- (void)disableUserInteraction {
    [[self tableView] setUserInteractionEnabled:NO];
}

#pragma mark - Toolbar Actions

#pragma mark Top Toolbar Actions

- (IBAction)edit:(id)sender {
    
    BOOL editing = ![[self tableView] isEditing];
    
    if ([UIDevice isPad] == NO) {
        UIBarButtonSystemItem buttonType = !editing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
        SEL toggleEditModeQueryDesigner = @selector(edit:);
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                       target: self
                                                                                       action: toggleEditModeQueryDesigner];
        
        
        [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
        [self setBarButtonItemEdit:barButtonItem];
        [barButtonItem release];
    }

    [[self tableView] setEditing: editing];
}

#pragma mark Table Header Actions

- (void)addConnection:(id)sender {
    // FIXME: Show in popover.
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddDatabaseDrivers sender: sender];
}

- (void)addTable:(id)sender {
    // FIXME: Show in popover.
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddTableViewController sender: sender];
}

- (void)addLink:(id)sender {
    // FIXME: Show in popover.
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddLinkViewController sender: sender];
}

- (void)addPredicate:(id)sender {
    // FIXME: Show in popover.
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddPredicateViewController sender: sender];
}

- (void)addGroup:(id)sender {
    // FIXME: Show in popover.
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddGroupViewController sender: sender];
}

- (void)showPopoverWtihController:(UIViewController *)controller fromView:(UIView *)view {
    
}

#pragma mark - Modal helper

- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)section withNumberOfTables:(NSInteger)numberOfTables {
    MTQuerySections result = section;
    NSDictionary *dataModel = [self datamodelForNumberOfTables:numberOfTables];
    NSArray *sectionTypes = [[dataModel objectForKey: MTTableSectionSectionsKey] retain];
    if ([sectionTypes count] >= section) {
        result = [[sectionTypes objectAtIndex:section] integerValue];
    }
    [sectionTypes release];
    return result;
}

- (MTQuerySections)tableSectionTypeForIndexPathSection:(NSUInteger)sec {
    MTQuerySections result = sec;
    NSDictionary *datamodel = [self datamodel];
    NSArray *sectionTypes = [[datamodel objectForKey: MTTableSectionSectionsKey] retain];
    if ([sectionTypes count] >= sec) {
        result = [[sectionTypes objectAtIndex:sec] integerValue];
    }
    [sectionTypes release];
    return result;
}

- (NSUInteger)sectionPositionForTableSectionType:(MTQuerySections)sec {
    NSInteger result = 0;
    NSArray *sectionTypes = [[[self datamodelForNumberOfTables:[[self tableView] numberOfRowsInSection: 1]] objectForKey: MTTableSectionSectionsKey] retain];
    NSInteger secPos = 0;
    for (NSNumber *num in sectionTypes) {
        if ([num integerValue] == sec) {
            result = secPos;
            break;
        }
        secPos++;
    }
    [sectionTypes release];
    return result;
}

#pragma mark - Layout Settings Delegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    [RptqDocumentSection setHeight:height forSectionAtRow:[self lastSelectedRowNumber]
                        inDocument:document];
    [reportDocument saveContext];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    [RptqDocumentSection setVisibility:isVisible forSectionAtRow:[self lastSelectedRowNumber]
                            inDocument:document];
    [reportDocument saveContext];
    
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    [RptqDocumentSection setNumberOfRows:numberOfRows forSectionAtRow:[self lastSelectedRowNumber]
                              inDocument:document];
    [reportDocument saveContext];
}

#pragma mark - Delegates

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}


- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

- (void)addQueryPredicate:(RptqQueryPredicate *)predicate {
    [self dismissViewControllerAnimated:YES completion:^{ }];

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    [RptqQueryPredicate addPredicate:predicate toDocument:[reportDocument activeDocument]];
    [reportDocument saveContext];
    [reportDocument quickSave];
}

- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)link {
    [self dismissViewControllerAnimated:YES completion:^{ }];

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    [RptqQueryLinks insertQueryLink:link intoDocument:document];
    [reportDocument saveContext];
    NSInteger suspectedSection = 2;
    MTQuerySections tableSection = [self tableSectionTypeForIndexPathSection: suspectedSection];
    if (tableSection == MTQuerySectionsLinks) {
        NSIndexSet *linksSection = [NSIndexSet indexSetWithIndex:suspectedSection];
        [[self tableView] reloadSections:linksSection withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [reportDocument quickSave];
}

- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldId andSortOrder:(MNSSortOrder)sortOrder {

    [self dismissViewControllerAnimated:YES completion:^{ }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqQueryField *queryField = [RptqQueryField getQueryFieldForObjectID:queryFieldId fromObjectContext:managedObjectContext];
    RptqQueryGroup *queryGroup = [RptqQueryGroup createQueryGroupFor:queryField andSort:sortOrder inManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    [query addHasQueryGroupsObject: queryGroup];

    
    NSInteger groupCount = [[query hasQueryGroups] count];
    NSInteger weight = groupCount - 1;
    NSUInteger secFirstTransaction = [self sectionPositionForTableSectionType:MTQuerySectionsGroups];
    NSUInteger rowFirstTransaction = weight;
    
    [[self tableView] beginUpdates];
    [[self tableView] insertRowsAtIndexPaths: @[[NSIndexPath indexPathForRow: rowFirstTransaction inSection: secFirstTransaction]]
                                        withRowAnimation: UITableViewRowAnimationAutomatic];
    [reportDocument saveContext];
    [[self tableView] endUpdates];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
    [reportDocument quickSave];
}

- (void)viewControllerSchemaAddTableDidSelectTable:(RptqDatabaseSchemaTable *)table {
    [self dismissViewControllerAnimated:YES completion:^{ }];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

    NSIndexSet *indexSetSections = nil;

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocument *document = [reportDocument activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];

    NSDictionary *oldLayout = [[self datamodel] retain];
    NSArray *oldLayoutSectionTypes = [[oldLayout objectForKey:MTTableSectionSectionsKey] retain];
    
    RptqQueryTable *newQueryTable = [RptqDatabaseSchemaTable addTableToQuery:table forManagedObjectContext:managedObjectContext];
    
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"alias" ascending:YES];
    NSArray *queryTablesArray = [[[query hasQueryTables] sortedArrayUsingDescriptors:@[namesAccending]] retain];

    NSUInteger indexCounter = 0;
    for (RptqQueryTable *queryTable in queryTablesArray) {
        if ([[queryTable alias] compare:[newQueryTable alias]] == NSOrderedAscending) {
            indexCounter++;
        }
    }
    
    [queryTablesArray release];
    
    //NSUInteger indexCounter = [[query hasQueryTables] count] - 1;
    
    NSUInteger sectionPosition = [self sectionPositionForTableSectionType: MTQuerySectionsTables];
    NSIndexPath *insertedRowIndexPath = [[NSIndexPath indexPathForRow:indexCounter inSection:sectionPosition] retain];
    
    NSDictionary *newLayout = [[self datamodel] retain];
    NSArray *newLayoutSectionTypes = [[newLayout objectForKey:MTTableSectionSectionsKey] retain];

    if ([oldLayoutSectionTypes count] != [newLayoutSectionTypes count]) {
        if ([oldLayoutSectionTypes count] < [newLayoutSectionTypes count]) { //add sections
            //Constrained that it only will work when sections being added in an index set, or next to each other.
            NSInteger secctr = 0;
            BOOL startIndexSet = NO;
            NSInteger startIndex = -1;
            NSInteger lengtho = [newLayoutSectionTypes count] - [oldLayoutSectionTypes count];
            for (NSNumber *typenum in newLayoutSectionTypes) {
                MTQuerySections stsection = [typenum integerValue];
                if (secctr < [oldLayoutSectionTypes count]) {
                    if (stsection == [[oldLayoutSectionTypes objectAtIndex:secctr] integerValue]) {
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
    //NSLog(@"Add table at %@", insertedRowIndexPath);
    if (indexSetSections != nil) {

        [[self tableView] beginUpdates];
        [[self tableView] insertRowsAtIndexPaths: @[insertedRowIndexPath]
                                            withRowAnimation: UITableViewRowAnimationAutomatic];
        [[self tableView] insertSections: indexSetSections
                                    withRowAnimation: UITableViewRowAnimationAutomatic];
        [managedObjectContext save:nil];
        [[self tableView] endUpdates];

    } else {

        [[self tableView] beginUpdates];
        [[self tableView] insertRowsAtIndexPaths: @[insertedRowIndexPath]
                                            withRowAnimation: UITableViewRowAnimationAutomatic];
        [managedObjectContext save:nil];
        [[self tableView] endUpdates];
    }
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];

    [reportDocument quickSave];

    [newLayoutSectionTypes release];
    [oldLayoutSectionTypes release];
    [oldLayout release];
    [newLayout release];
    [indexSetSections release];
    [insertedRowIndexPath release];
    [namesAccending release];
    
}

#pragma mark - Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id queryBuilderDataModel = [self datamodel];
    NSInteger numberOfSections = [[queryBuilderDataModel objectForKey: MTTableHeaderSectionKey] count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    MTQuerySections ts = [self tableSectionTypeForIndexPathSection: section];
    
    NSDictionary *rowsDict = [[[self datamodel] objectForKey: MTTableSectionRowKey] retain];
    NSInteger numberOfRows = 0;
    numberOfRows = [[rowsDict objectForKey:[NSNumber numberWithInt: ts]] intValue];
    if (numberOfRows < 0) {
        switch (ts) {
            case MTQuerySectionsDocumentGroups: {
                //The sections are report header, report footer, page header, page footer,
                //  body, group header, and group footer
                NSInteger numberOfGroups = [[[self.fetchedResultsControllerGroups sections] objectAtIndex: 0] numberOfObjects];
                numberOfRows = (2 * numberOfGroups) + 5;
                //NSLog(@"Section Rows:   %d", numberOfRows);
                break;
            }
            case MTQuerySectionsTables: {
                numberOfRows = [[[self.fetchedResultsControllerTables sections] objectAtIndex: 0] numberOfObjects];
                //NSLog(@"Table Rows:     %d", numberOfRows);
                break;
            }
            case MTQuerySectionsLinks: {
                numberOfRows = [[[self.fetchedResultsControllerLinks sections] objectAtIndex: 0] numberOfObjects];
                //NSLog(@"Link Rows:      %d", numberOfRows);
                break;
            }
            case MTQuerySectionsPredicate: {
                NSArray *sections = [[self fetchedResultsControllerPredicates] sections];
                id sectionData = [sections objectAtIndex: 0];
                numberOfRows = [sectionData numberOfObjects];
                //NSLog(@"Predicate Rows: %d", numberOfRows);
                break;
            }
            case MTQuerySectionsGroups: {
                NSArray *sections = [[self fetchedResultsControllerGroups] sections];
                id sectionData = [sections objectAtIndex: 0];
                numberOfRows = [sectionData numberOfObjects];
                break;
            }
            default:
                numberOfRows = 0;
                break;
        }
    }
    [rowsDict release];
	return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [indexPath section];
    MTQuerySections sectionType = [self tableSectionTypeForIndexPathSection: section];
	return (sectionType == MTQuerySectionsTables ||
            sectionType == MTQuerySectionsGroups ||
            sectionType == MTQuerySectionsPredicate ||
            sectionType == MTQuerySectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self tableSectionTypeForIndexPathSection:[indexPath section]] == MTQuerySectionsGroups) ? YES : NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    MTQuerySections querySection = [self tableSectionTypeForIndexPathSection:[indexPath section]];

	switch (editingStyle) {

        // MARK: UITableViewCellEditingStyleDelete
        case UITableViewCellEditingStyleDelete: {
            switch (querySection) {
                    
                // MARK: Delete MTQuerySectionsTables
                case MTQuerySectionsTables: {
                    
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:YES];
                    
                    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                    MAReportDocument *reportDocument = [applicationInstance activeDocument];

                    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                    
                    NSArray *deleteRows = nil;
                    NSIndexSet *deleteSections = nil;
                    RptqDocument *document = [reportDocument activeDocument];
                    NSInteger numberOfTables = [RptqQueryTable countOfTablesInQueryForDocument:document];
                    NSDictionary *oldTableLayout = [[NSDictionary alloc] initWithDictionary:[self datamodelForNumberOfTables: numberOfTables]];
                    
                    RptqQueryTable *table = [[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: [indexPath row] inSection: 0]];
                    NSManagedObjectID *deleatedTableObjectId = [[table objectID] retain];
                    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                    RptqQuery *query = [[database hasQueries] anyObject];
                    [query removeHasQueryTablesObject:table];
                    deleteRows = [[NSArray alloc] initWithObjects:indexPath, nil];
                    numberOfTables--;
                    
                    NSDictionary *newTableLayout = [[NSDictionary alloc] initWithDictionary: [self datamodelForNumberOfTables: numberOfTables]];
                    NSArray *oldLayoutSectionTypes = [oldTableLayout objectForKey:MTTableSectionSectionsKey];
                    NSArray *newLayoutSectionTypes = [newTableLayout objectForKey:MTTableSectionSectionsKey];
                    
                    if ([oldLayoutSectionTypes count] > [newLayoutSectionTypes count]) {
                        NSInteger secctr = 0;
                        BOOL startIndexSet = NO;
                        NSInteger startIndex = -1;
                        NSInteger lengtho = [oldLayoutSectionTypes count] - [newLayoutSectionTypes count];
                        for (NSNumber *typenum in oldLayoutSectionTypes) {
                            MTQuerySections stsection = [typenum integerValue];
                            if (secctr < [newLayoutSectionTypes count]) {
                                if (stsection == [[newLayoutSectionTypes objectAtIndex:secctr] integerValue]) {
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
                    [newTableLayout release];
                    
                    
                    [tableView beginUpdates];
                    
                    //Delete document data fields related to the table being deleted.
                    {
                        NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
                        NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
                        NSPredicate *documentObjectsPredicate = [NSPredicate predicateWithFormat:@"isLabelDataField.referencesQueryField.inQueryTable == %@", deleatedTableObjectId];
                        
                        [fetchReqest setPredicate:documentObjectsPredicate];
                        NSError *fetchError = nil;
                        NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest error:&fetchError];
                        if (fetchError == nil) {
                            for (RptqDocumentObject *documentObject in objectsToDelete) {
                                [managedObjectContext deleteObject:[documentObject isLabelDataField]];
                                [managedObjectContext deleteObject:documentObject];
                            }
                            [managedObjectContext save:&fetchError];
                        }
                    }
                    //Delete document data objects related to the table being deleted.
                    {
                        NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
                        NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
                        NSPredicate *documentObjectsPredicate = [NSPredicate predicateWithFormat:@"isAggregate.aggregateField.inQueryTable == %@", deleatedTableObjectId];
                        
                        [fetchReqest setPredicate:documentObjectsPredicate];
                        NSError *fetchError = nil;
                        NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest error:&fetchError];
                        if (fetchError == nil) {
                            for (RptqDocumentObject *documentObject in objectsToDelete) {
                                [managedObjectContext deleteObject:[documentObject isAggregate]];
                                [managedObjectContext deleteObject:documentObject];
                            }
                            [managedObjectContext save:&fetchError];
                        }
                    }
                    
                    //Delete links, groups, and predicates related to the table being deleted.
                    
                    NSMutableArray *cellsToDelete = [[NSMutableArray alloc] init];
                    for (NSInteger section = 0; section < [tableView numberOfSections]; section++) {
                        NSInteger numberOfTablesPlusOne = numberOfTables + 1;
                        MTQuerySections querySection = [self tableSectionTypeForIndexPathSection:section withNumberOfTables:numberOfTablesPlusOne];

                        if (querySection == MTQuerySectionsLinks) {
                            
                            NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
                            NSFetchedResultsController *fetchedLinkes = [[self fetchedResultsControllerLinks] retain];
                            for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
                                NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                                NSError *error = nil;
                                NSManagedObject *object = nil;
                                UITableViewCellQueryLink *tableViewCellLink = (UITableViewCellQueryLink *)[[tableView cellForRowAtIndexPath:linkIndexPath] retain];
                                if (tableViewCellLink) {
                                    object = [[[managedObjectContext existingObjectWithID:[tableViewCellLink tableID] error:&error] retain] autorelease];
                                } else {
                                    NSIndexPath *testLinkIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
                                    
                                    object = [[[fetchedLinkes objectAtIndexPath:testLinkIndexPath] retain] autorelease];
                                }
                                if (!error && object && [object isKindOfClass:[RptqQueryLinks class]]) {
                                    RptqQueryLinks *queryLink = (RptqQueryLinks *)object;
                                    NSManagedObjectID *tableLeftObjectId = [[[queryLink hasLeftField] inQueryTable] objectID];
                                    NSManagedObjectID *tableRightObjectId = [[[queryLink hasRightField] inQueryTable] objectID];
                                    if ([tableLeftObjectId isEqual:deleatedTableObjectId] ||
                                        [tableRightObjectId isEqual:deleatedTableObjectId]
                                        ) {
                                        [RptqQueryLinks deleteLinkWithID:[queryLink objectID] fromObjectContext:managedObjectContext];
                                        [cellsToDelete addObject:linkIndexPath];
                                    }
                                }
                                [tableViewCellLink release];
                            }
                            NSError *error = nil;
                            [managedObjectContext save:&error];

                            [fetchedLinkes release];
                            
                        } else if (querySection == MTQuerySectionsGroups) {
                            
                            NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
                            for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
                                NSIndexPath *groupIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                                NSError *error = nil;
                                NSManagedObject *object = nil;

                                UITableViewCellQueryGroup *tableViewCellGroup = (UITableViewCellQueryGroup *)[[tableView cellForRowAtIndexPath:groupIndexPath] retain];
                                if (tableViewCellGroup) {
                                    NSError *error = nil;
                                    object = [[[managedObjectContext existingObjectWithID:[tableViewCellGroup tableID] error:&error] retain] autorelease];
                                } else {
                                    NSIndexPath *testGroupIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
                                    object = [[[[self fetchedResultsControllerGroups] objectAtIndexPath:testGroupIndexPath] retain] autorelease];
                                }
                                if (!error && object && [object isKindOfClass:[RptqQueryGroup class]]) {
                                    RptqQueryGroup *groupToRemove = (RptqQueryGroup *)object;
                                    NSManagedObjectID *tableObjectId = [[[groupToRemove hasField] inQueryTable] objectID];
                                    if ([tableObjectId isEqual:deleatedTableObjectId]) {
                                        [self removeGroup:groupToRemove];
                                        [cellsToDelete addObject:groupIndexPath];
                                    }
                                }
                                [tableViewCellGroup release];
                            
                            }
                            
                        } else if (querySection == MTQuerySectionsPredicate) {
                            
                            NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
                            for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
                                NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                                

                                MTTableViewCellQueryPredicate *tableViewCellPredicate = [(MTTableViewCellQueryPredicate *)[[tableView cellForRowAtIndexPath:predicateIndexPath] retain] autorelease];
                                NSError *error = nil;
                                NSManagedObject *object = nil;
                                if (tableViewCellPredicate) {
                                    object = [[[managedObjectContext existingObjectWithID:[tableViewCellPredicate tableID] error:&error] retain] autorelease];
                                } else {
                                    NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
                                    object = [[[[self fetchedResultsControllerPredicates] objectAtIndexPath: testPredicateIndexPath] retain] autorelease];
                                }
                                if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
                                    RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;
                                    NSManagedObjectID *leftTableObjectId = [[[predicateToRemove hasLeftField] inQueryTable] objectID];
                                    NSManagedObjectID *rightTableObjectId = [[[predicateToRemove hasRightField] inQueryTable] objectID];
                                    BOOL deleted = NO;
                                    if (leftTableObjectId) {
                                        if ([leftTableObjectId isEqual:deleatedTableObjectId]) {
                                            [RptqQueryPredicate deletePredicate:predicateToRemove];
                                            [cellsToDelete addObject:predicateIndexPath];
                                            deleted = YES;
                                        }
                                    }
                                    if (deleted == NO) {
                                        if (rightTableObjectId) {
                                            if ([rightTableObjectId isEqual:deleatedTableObjectId]) {
                                                [RptqQueryPredicate deletePredicate:predicateToRemove];
                                                [cellsToDelete addObject:predicateIndexPath];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    [managedObjectContext save:nil];
                    if (deleteSections != nil) {
                        [tableView deleteSections: deleteSections withRowAnimation: UITableViewRowAnimationAutomatic];
                        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    } else {
                        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    if ([cellsToDelete count]) {
                        [tableView deleteRowsAtIndexPaths:cellsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    [tableView endUpdates];
                    
                    [cellsToDelete release];


                    [deleteRows release];
                    [deleteSections release];
                    [oldTableLayout release];

                    // FIXME: Only allow table to be deleted if it's not linked or otherwise used in the query.
                    
                    [deleatedTableObjectId release];
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                    

                    break;
                }

                // MARK: Delete MTQuerySectionsLinks
                case MTQuerySectionsLinks: {
                    UITableViewCellQueryLink *tvcLink = (UITableViewCellQueryLink *)[[tableView cellForRowAtIndexPath:indexPath] retain];
                    if (tvcLink) {
                        NSManagedObjectID *objid = [tvcLink tableID];

                        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                        MAReportDocument *reportDocument = [applicationInstance activeDocument];

                        [RptqQueryLinks deleteLinkWithID:objid fromObjectContext:[reportDocument managedObjectContext]];
                        [reportDocument saveContext];
                    }
                    [tvcLink release];
                    break;
                }
                    
                // MARK: Delete MTQuerySectionsGroups
                case MTQuerySectionsGroups: {
                    
                    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                    MAReportDocument *reportDocument = [applicationInstance activeDocument];

                    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                    
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

                    RptqDocument *document = [reportDocument activeDocument];

                    if (document) {
                        RptqQuery *query = [[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                        NSInteger weightToRemove = [indexPath row];

                        RptqQueryGroup *groupToRemove = nil;
                        for (RptqQueryGroup *group in [query hasQueryGroups]) {
                            if ([[group weight] integerValue] > weightToRemove) {
                                [group setWeight:[NSNumber numberWithInteger:([[group weight] integerValue] - 1)]];
                            } else
                                if ([[group weight] integerValue] == weightToRemove) {
                                groupToRemove = group;
                            }
                        }
                        
                        if (groupToRemove) {
                            NSSet *sectionsToRemove = [[groupToRemove hasSection] retain];
                            NSArray *sections = [[sectionsToRemove allObjects] retain];
                            if ([sections count] == 2) {
                                [groupToRemove removeHasSectionObject: [sections objectAtIndex: 0]];
                                [groupToRemove removeHasSectionObject: [sections objectAtIndex: 1]];
                            }
                            [sections release];
                            [sectionsToRemove release];
                            [managedObjectContext deleteObject: groupToRemove];
                            [query removeHasQueryGroupsObject: groupToRemove];
                            
                            //Reweight Groups
                            
                            [tableView beginUpdates];
                            [[self tableView] deleteRowsAtIndexPaths: @[indexPath]
                                                                withRowAnimation: UITableViewRowAnimationAutomatic];
                            [[query managedObjectContext] save:nil];
                            NSString *weight = NSStringFromSelector(@selector(weight));
                            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
                            NSArray *sortedQueryGroups = [[query hasQueryGroups] sortedArrayUsingDescriptors:@[sortDescriptor]];
                            NSUInteger counter = 0;
                            for (RptqQueryGroup *group in sortedQueryGroups) {
                                [group setWeight:@(counter)];
                                counter++;
                            }
                            [[query managedObjectContext] save:nil];
                            [tableView endUpdates];
                        }
                    }
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                    break;
                }
                
                case MTQuerySectionsPredicate: {

                    MTTableViewCellQueryPredicate *tvcPred = (MTTableViewCellQueryPredicate *)[[tableView cellForRowAtIndexPath:indexPath] retain];
                    
                    if (tvcPred) {
                        NSManagedObjectID *objid = [tvcPred tableID];
                        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                        MAReportDocument *reportDocument = [applicationInstance activeDocument];

                        [RptqQueryPredicate deletePredicateWithID:objid fromObjectContext:[reportDocument managedObjectContext]];
                        [reportDocument saveContext];
                    }
                    [tvcPred release];

                    break;
                }
                default: {
                    break;
                }
                
            }
            break;
        }
        // MARK: UITableViewCellEditingStyleInsert
        case UITableViewCellEditingStyleInsert: {
            break;
        }
        // MARK: UITableViewCellEditingStyleNone
        case UITableViewCellEditingStyleNone: {
            break;
        }
        default:
            break;
    }
}

- (void)removeGroup:(RptqQueryGroup *)groupToRemove {
    if (groupToRemove) {
        RptqQuery *query = [[groupToRemove inQuery] retain];
        NSManagedObjectContext *managedObjectContext = [[query managedObjectContext] retain];
        
        NSSet *sectionsToRemove = [[groupToRemove hasSection] retain];
        NSArray *sections = [[sectionsToRemove allObjects] retain];
        if ([sections count] == 2) {
            [groupToRemove removeHasSectionObject: [sections objectAtIndex: 0]];
            [groupToRemove removeHasSectionObject: [sections objectAtIndex: 1]];
        }
        [sections release];
        [sectionsToRemove release];
        [[query managedObjectContext] deleteObject: groupToRemove];
        [query removeHasQueryGroupsObject: groupToRemove];
        [managedObjectContext save:nil];
        
        //Reweight Groups
        NSString *weight = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
        NSArray *sortedQueryGroups = [[query hasQueryGroups] sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSUInteger counter = 0;
        for (RptqQueryGroup *group in sortedQueryGroups) {
            [group setWeight:@(counter)];
            counter++;
        }
        [managedObjectContext save:nil];
        [query release];
        [managedObjectContext release];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    MTQuerySections ts = [self tableSectionTypeForIndexPathSection: toIndexPath.section];
    switch (ts) {
        case MTQuerySectionsGroups: {

            [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];
            NSIndexPath *fromIndex = [NSIndexPath indexPathForRow: fromIndexPath.row inSection: 0];
            NSIndexPath *toIndex = [NSIndexPath indexPathForRow: toIndexPath.row inSection: 0];
            RptqQueryGroup *fromGroup = [[self fetchedResultsControllerGroups] objectAtIndexPath: fromIndex];
            RptqQueryGroup *toGroup = [[self fetchedResultsControllerGroups] objectAtIndexPath: toIndex];
            NSInteger fromWeight = [[toGroup weight] integerValue];
            NSInteger toWeight = [[fromGroup weight] integerValue];
            [toGroup setWeight:@(toWeight)];
            [fromGroup setWeight:@(fromWeight)];

            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            [reportDocument saveContext];
            [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];

            MTLog(@"%@->%@", fromIndexPath, toIndexPath);
            break;
        }
        default:
            break;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [NSArray array];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *result = nil;

    NSInteger row = [indexPath row];
    MTQuerySections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];

    switch (section) {

        // MARK: Display optional instructions about query builder.
        case MTQuerySectionsDocumentGroups: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellInstruction";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            NSInteger numberOfGroups = [[[[self fetchedResultsControllerGroups] sections] objectAtIndex: 0] numberOfObjects];
            NSString *sectionName = [[RptqDocumentSection getDocumentSectionNameForRow: row withNumberOfGroups:numberOfGroups] retain];
            NSInteger sectionIndentLevel = [RptqDocumentSection getDocumentSectionIndentLevelForRow:row withNumberOfGroups:numberOfGroups];
            [[(UITableViewCellInstruction *) result labelGroupType] setText:[NSString stringWithFormat:@"%@", sectionName]];
            [[(UITableViewCellInstruction *) result labelGroupType] setBackgroundColor:[UIColor clearColor]];
            [[(UITableViewCellInstruction *) result labelGroupType] setFont:[self boldSystemFont]];
            [(UITableViewCellInstruction *) result setIndentationLevel: (sectionIndentLevel+1)];
            [sectionName release];
            break;
        }

        // MARK: Display and identify the data source and data sources
        case MTQuerySectionsDatasource: {
            static NSString *MyIdentifierUITableViewCellDataSource = @"UITableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellDataSource];

            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            NSArray *connections = [RptqUserCredentals userCredentalsForManagedObjectContext:[reportDocument managedObjectContext]];
            
            if (connections) {
                [connections retain];
                if ([connections count] >= 1) {
                    RptqUserCredentals *connection = [[connections objectAtIndex: 0] retain];
                    
                    NSString *databaseType = [NSString stringWithFormat:@"%@", [connection database_driver_type]];
                    NSString *schemaName = [connection databaseSchemaName];
                    NSString *localizedMessage = NSLocalizedString(@"You are connecting to a %1$@ datasource named %2$@.", @"You are connecting to %1$@ datasource named %2$@.");
                    NSString *message = [NSString stringWithFormat:localizedMessage, databaseType, schemaName];
                    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                    NSDictionary *attributes = @{ NSFontAttributeName : font };
                    NSRange rangeOfSchemaName = [message rangeOfString:schemaName];
                    NSRange rangeOfDatabaseTypeName = [message rangeOfString:databaseType];
                    UIFont *fontItalic = [UIFont italicSystemFontOfSize:[font pointSize]];
                    NSDictionary *additionalAttributeStroke = @{ NSFontAttributeName : fontItalic };
                    NSMutableAttributedString *messageAttributed = [[NSMutableAttributedString alloc] initWithString:message attributes:attributes];

                    [messageAttributed removeAttribute:NSFontAttributeName range:rangeOfDatabaseTypeName];
                    [messageAttributed removeAttribute:NSFontAttributeName range:rangeOfSchemaName];
                    [messageAttributed addAttributes:additionalAttributeStroke range:rangeOfDatabaseTypeName];
                    [messageAttributed addAttributes:additionalAttributeStroke range:rangeOfSchemaName];
                    
                    [[result textLabel] setText:message];
                    [[result textLabel] setAttributedText:messageAttributed];
                    //[[result textLabel] setFont:font];
                    [[result detailTextLabel] setText:@""];
                    [connection release];
                    [messageAttributed release];
                }
                [connections release];
            }
            [[result textLabel] setNumberOfLines:2];
            break;
        }

        // MARK: Display the table names that are used in the query
        case MTQuerySectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            UITableViewCellTableName *resultR = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            RptqQueryTable *tablea = [[[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            [[resultR textLabel] setText: [NSString stringWithFormat:@"%@", [tablea alias]]];
            [[resultR textLabel] setFont: font];
            
            [[resultR textLabel] setBackgroundColor:[UIColor clearColor]];
            [resultR setIndentationLevel: 1];
            [tablea release];
            result = resultR;
            break;
        }
        
        // MARK: Display the table links or joins that are used in the query.
        case MTQuerySectionsLinks: {

            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [[self fetchedResultsControllerLinks] objectAtIndexPath: indexPath];
            
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            
            NSString *messageText = @"%@ %@ %@";
            
            NSString *pre = [[links tableleft] capitalizedString];
            NSString *post = [[links fieldleft] capitalizedString];
            NSString *leftString = [NSString stringWithFormat:@"%@.%@", pre, post];
            pre = [[links tableright] capitalizedString];
            post = [[links fieldright] capitalizedString];
            NSString *rightString = [NSString stringWithFormat:@"%@.%@", pre, post];

            [(UITableViewCellQueryLink *)result setTableID: [links objectID]];
            [[result textLabel] setNumberOfLines:2];

            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [paragraphStyle setHeadIndent:20.0000f];
            NSString *linksDescription = [links linkDescription];
            messageText = [NSString stringWithFormat:messageText, leftString, linksDescription, rightString];
            NSDictionary *attributes = @{ NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle };
            UIColor *color = [UIColor tintColor];
            NSDictionary *attributesAlt = @{ NSFontAttributeName : fontCaption, NSForegroundColorAttributeName :  color};
            NSRange rangeLinkDesc = [messageText rangeOfString:linksDescription];
            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
            [message addAttributes:attributesAlt range:rangeLinkDesc];
            [[result textLabel] setAttributedText: message];
            [message release];
            [paragraphStyle release];

            break;
        }

        // MARK: Display the groupings used in the query.
        case MTQuerySectionsGroups: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            RptqQueryGroup *group = [[self fetchedResultsControllerGroups] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]];
            [[result backgroundView] setBackgroundColor:[UIColor whiteColor]];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            
            NSMutableParagraphStyle *paragraphStyleLeft = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            NSMutableParagraphStyle *paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [paragraphStyleLeft setAlignment:NSTextAlignmentLeft];
            [paragraphStyleRight setAlignment:NSTextAlignmentRight];

            NSString *formatString = @"%1$@ %2$@";
            NSString *fieldName = [group fieldNameNice];
            NSString *sortFieldName = [group sortDisplayNice];
            NSString *messageText = [NSString stringWithFormat:formatString, fieldName, sortFieldName];
            NSDictionary *attributes = @{ NSFontAttributeName : font };
            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
            NSDictionary *attributesLeft = @{ NSParagraphStyleAttributeName : paragraphStyleLeft };
            UIColor *color = [UIColor tintColor];
            NSDictionary *attributesRight = @{ NSParagraphStyleAttributeName : paragraphStyleLeft, NSFontAttributeName : fontCaption, NSForegroundColorAttributeName :  color };
            NSRange rangeLeft = [messageText rangeOfString:fieldName];
            NSRange rangeRange = [messageText rangeOfString:sortFieldName];
            [message addAttributes:attributesLeft range:rangeLeft];
            [message addAttributes:attributesRight range:rangeRange];
            [[result textLabel] setText:messageText];
            [[result textLabel] setAttributedText:message];
            [[result textLabel] setNumberOfLines:2];
            [paragraphStyleLeft release];
            [paragraphStyleRight release];
            [message release];
            [(UITableViewCellQueryGroup *)result setTableID:[group objectID]];
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
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            
            NSString *formatString = @"%1$@ %2$@ %3$@";
            NSString *symbol = [predicate symbolForDisplay];
            NSString *messageText = [NSString stringWithFormat:formatString, leftFieldDisplay, symbol, rightFieldDisplay];
            NSDictionary *attributes = @{ NSFontAttributeName : font };
            UIColor *color = [UIColor tintColor];
            NSDictionary *attributesCaption = @{ NSForegroundColorAttributeName :  color };

            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
            //NSRange rangeLeft = [messageText rangeOfString:leftFieldDisplay];
            //NSRange rangeRight = [messageText rangeOfString:rightFieldDisplay];
            NSRange rangeMiddle = [messageText rangeOfString:symbol];
            [[result textLabel] setNumberOfLines:2];
            [message addAttributes:attributesCaption range:rangeMiddle];
            [[result textLabel] setText:messageText];
            [[result textLabel] setAttributedText:message];
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
        result = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCellShouldNotGetHere"] autorelease];
        [[result textLabel] setText: @"Err"];
    }

    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    MTViewTableHeader *result = nil;
    
    section = [self tableSectionTypeForIndexPathSection: section];
    
    switch (section) {
        case MTQuerySectionsDocumentGroups: {
            
            result = [self viewTableHeaderQuerySectionsDocumentGroups];
            break;
        }
            
        case MTQuerySectionsDatasource: {
            result = [self viewTableHeaderQuerySectionsDatasource];
            break;
        }
            
        case MTQuerySectionsTables: {
            result = [self viewTableHeaderQuerySectionsTables];
            break;
        }
            
        case MTQuerySectionsLinks: {
            result = [self viewTableHeaderQuerySectionsLinks];
            break;
        }
            
        case MTQuerySectionsGroups: {
            result = [self viewTableHeaderQuerySectionsGroups];
            break;
        }
            
        case MTQuerySectionsPredicate: {
            result = [self viewTableHeaderQuerySectionsPredicate];
            break;
        }
        case MTQuerySectionsSql: {
            result = [self viewTableHeaderQuerySectionsSql];
            break;
        }
        default: {
            result = [self viewTableHeaderQuerySectionsDatasource];
            break;
        }
    }
    return [[result retain] autorelease];
}


#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MTQuerySections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];
    if (section == MTQuerySectionsDocumentGroups && [UIDevice isPad] == NO) {
        [self setLastSelectedRowNumber: [indexPath row]];
        [self performSegueWithIdentifier:MNSIdentifierSegueShowLayoutSettings sender:self];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 29.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = MNSTableViewCellHeightDefault;
    MTQuerySections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];
    if (section == MTQuerySectionsSql) {
        result = [indexPath row] == 0 ? [UITableViewCellOverride defaultHeight] : [UITableViewCellQueryInput defaultHeight];
    } else {
        NSDictionary *datamodel = [self datamodel];
        NSDictionary *tableMetaHeight = [datamodel objectForKey:MTTableSectionRowHeightKey];
        if (tableMetaHeight) result = [[tableMetaHeight objectForKey: [NSNumber numberWithInt: section]] floatValue];
    }
    return result;
}


// MARK: - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
// MARK: - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
// MARK: - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath { }
// MARK: - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath { }
// MARK: - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath { }


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Remove", @"Remove button title.");
 }

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark - NSFetchedResultsSetup

- (void)reloadActiveDocumentAnimated:(BOOL)animated {
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    [self reloadDocument:reportDocument animated:animated];
}

- (void)reloadDocument:(MAReportDocument *)reportDocument animated:(BOOL)animated {
    
    if (reportDocument) {
        
        [reportDocument retain];
        NSManagedObjectContext *managedObjectContext = [[reportDocument managedObjectContext] retain];
        
        {
            
            
            RptqDocument *document = [reportDocument activeDocument];
            RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
            RptqQuery *query = [[database hasQueries] anyObject];
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias" ascending:YES];
            [request setSortDescriptors: @[sortDescriptor]];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: NSFetchedResultsCacheTables];
            [frc setDelegate:self];
            [self setFetchedResultsControllerTables: frc];
            [self performFetchTables];
            [frc release];
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
                                                                                             cacheName: NSFetchedResultsCacheLinks];
            [frc setDelegate:self];
            [self setFetchedResultsControllerLinks: frc];
            [self performFetchLinks];
            [frc release];
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
                                                                                             cacheName: NSFetchedResultsCacheGroups];
            [frc setDelegate:self];
            [self setFetchedResultsControllerGroups: frc];
            [self performFetchGroups];
            [frc release];
            frc = nil;
            
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: entityName];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fieldleftpred" ascending:YES];
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
            [request setSortDescriptors: sortDescriptors];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: NSFetchedResultsCachePredicates];
            [frc setDelegate:self];
            [self setFetchedResultsControllerPredicates: frc];
            [self performFetchPredicate];
            [frc release];
            [sortDescriptor release];
            [sortDescriptors release];
            [request release];
            frc = nil;
        }
        [managedObjectContext release];
        [reportDocument release];
        [[self tableView] reloadData];
    }

}

- (NSMutableDictionary *)datamodel {

    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    NSInteger numberOfTablesInQuery = [RptqQueryTable countOfTablesInQueryForDocument:document];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:[self datamodelForNumberOfTables:numberOfTablesInQuery]];
    return [result autorelease];
}

- (NSDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables {

    NSDictionary *result;

    NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
    NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
    NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
    NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
    NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");

    switch (numberOfTables) {
        case 0: {
            
            //There are three configurations for the table.  These configurations depend on the number of schemas in the query: zero, one, or more than one.
            
            NSArray *sections = @[@(MTQuerySectionsDatasource),
                                  @(MTQuerySectionsTables)];
            
            NSArray *countRowsForSection = @[@(1), @(-1)];
            NSDictionary *countRowsForSectionDictionary =  [NSDictionary dictionaryWithObjects:countRowsForSection forKeys:sections];
            
            NSArray *headersSection = @[h2, h3];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection forKeys: sections];
            
            NSArray *heightRowsForSection = @[@(50.0000f), @([UITableViewCellTableName defaultHeight])];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection forKeys:sections];
            
            result = @{MTTableSectionSectionsKey : sections,
                                           MTTableHeaderSectionKey : headersSectionDictionary,
                                           MTTableSectionRowKey : countRowsForSectionDictionary,
                                           MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};

            
            break;
        }
        case 1: {
            
            NSArray *sections = @[@(MTQuerySectionsDatasource),
                         @(MTQuerySectionsTables),
                         @(MTQuerySectionsGroups),
                         @(MTQuerySectionsPredicate)];
            
            NSArray *countRowsForSection = @[@(1), @(-1), @(-1), @(-1)];
            NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects:countRowsForSection forKeys:sections];
            
            NSArray *headersSection = @[h2, h3, h5, h6];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects:headersSection forKeys: sections];
            
            NSArray *heightRowsForSection = @[@(44.0000f), @([UITableViewCellTableName defaultHeight]),
                                     @(44.0000f), @(44.0000f)];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection forKeys:sections];
            
            result = @{MTTableSectionSectionsKey : sections,
                             MTTableHeaderSectionKey : headersSectionDictionary,
                             MTTableSectionRowKey : countRowsForSectionDictionary,
                             MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};

            break;
        }
        default: {

            NSArray *sections = @[@(MTQuerySectionsDatasource),
                                  @(MTQuerySectionsTables),
                                  @(MTQuerySectionsLinks),
                                  @(MTQuerySectionsGroups),
                                  @(MTQuerySectionsPredicate)];
            
            NSArray *countRowsForSection = @[@(1), @(-1), @(-1), @(-1), @(-1)];
            NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects:countRowsForSection forKeys:sections];
            
            NSArray *headersSection = @[h2, h3, h4, h5, h6];
            NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects:headersSection forKeys: sections];
            
            
            NSArray *heightRowsForSection = @[@(44.0000f), @([UITableViewCellTableName defaultHeight]), @([UITableViewCellQueryLink defaultHeight]),
                                     @(44.0000f), @(44.0000f)];
            NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection forKeys:sections];
            
            result = @{MTTableSectionSectionsKey : sections,
                             MTTableHeaderSectionKey : headersSectionDictionary,
                             MTTableSectionRowKey : countRowsForSectionDictionary,
                             MTTableSectionRowHeightKey: heightRowsForSectionDictionaryDictionary};
            
            break;
        }
    }
    return result;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if ([self suspendAutomaticTrackingOfChangesInManagedObjectContext] == NO) {
        [[self tableView] beginUpdates];
        [self setBeganUpdates: YES];
    }
}

- (NSMutableArray *)sectionsUsedByFetchedResultsController: (NSFetchedResultsController *)controller {

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

    if ([controller isEqual:[self fetchedResultsControllerTables]]) {
        
        NSNumber *n = [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: MTQuerySectionsTables]];
        [result addObject: n];

    } else if ([controller isEqual:[self fetchedResultsControllerLinks]]) {

        NSNumber *n = [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: MTQuerySectionsLinks]];
        [result addObject: n];

    } else if ([controller isEqual:[self fetchedResultsControllerGroups]]) {

        NSInteger sectionDocumentGroup = [self sectionPositionForTableSectionType: MTQuerySectionsDocumentGroups];
        NSInteger sectionGroup = [self sectionPositionForTableSectionType: MTQuerySectionsGroups];
        NSNumber *numberSectionDocumentGroup = @(sectionDocumentGroup);
        NSNumber *numberSectionDocumentGroup2 = @(sectionDocumentGroup);
        NSNumber *numberSectionGroup = @(sectionGroup);
        [result addObject: numberSectionDocumentGroup]; //Once for group header settings
        [result addObject: numberSectionDocumentGroup2]; //Once for group footer settings
        [result addObject: numberSectionGroup];
    
    } else if ([controller isEqual:[self fetchedResultsControllerPredicates]]) {
    
        NSInteger section = [self sectionPositionForTableSectionType: MTQuerySectionsPredicate];
        NSNumber *sectionNumber = @(section);
        [result addObject: sectionNumber];
    }
    
    return [result autorelease];

}

- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex
	 forChangeType: (NSFetchedResultsChangeType)type {

    
    NSMutableArray *sections = [[self sectionsUsedByFetchedResultsController: controller] retain];
    
    for (NSNumber *section in sections) {
        MTQuerySections updateSection = [section integerValue];
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    [[self tableView] insertSections: [NSIndexSet indexSetWithIndex:updateSection]
                                              withRowAnimation: UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [[self tableView] deleteSections:
                     [NSIndexSet indexSetWithIndex:updateSection] withRowAnimation:UITableViewRowAnimationFade];
                    break;
            }
        }

    }
    
    [sections release];
}


- (void)controller: (NSFetchedResultsController *)controller didChangeObject: (id)anObject
	   atIndexPath: (NSIndexPath *)indexPath forChangeType: (NSFetchedResultsChangeType)type
	  newIndexPath: (NSIndexPath *)newIndexPath {
    
    NSMutableArray *sections = [[self sectionsUsedByFetchedResultsController: controller] retain];
    
    for (NSNumber *section in sections) {
        MTQuerySections updateSection = [section integerValue];
        
        NSIndexPath *path = [NSIndexPath indexPathForRow: [indexPath row]
                                               inSection: updateSection];
        
        if (path) {
            if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
                switch(type) {
                    case NSFetchedResultsChangeInsert: {
                        [[self tableView] insertRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeDelete: {
                        [[self tableView] deleteRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeUpdate: {
                        [[self tableView] reloadRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeMove: {
                        [[self tableView] deleteRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        [[self tableView] insertRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                }
            }
        }
    }
    [sections release];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates) [[self tableView] endUpdates];
    [self setBeganUpdates:NO];
}

- (void)endSuspensionOfUpdatesDueToContextChanges {
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
}

- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(BOOL)suspend {
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    } else {
        SEL selEndSuspensionOfUpdates = @selector(endSuspensionOfUpdatesDueToContextChanges);
        [self performSelector:selEndSuspensionOfUpdates withObject:0 afterDelay:0];
    }
}

#pragma mark - Fetching

- (void)performFetchTables {
    NSFetchedResultsController *controller = [self fetchedResultsControllerTables];
    if (controller) {
        [controller performFetch:nil];
    }
    [[self tableView] reloadData];
}

- (void)performFetchLinks {
    NSFetchedResultsController *controller = [self fetchedResultsControllerLinks];
    if (controller) {
        [controller performFetch:nil];
    }
    [[self tableView] reloadData];
}

- (void)performFetchGroups {
    NSFetchedResultsController *controller = [self fetchedResultsControllerGroups];
    if (controller) {
        [controller performFetch:nil];
    }
    [[self tableView] reloadData];
}

- (void)performFetchPredicate {
    NSFetchedResultsController *controller = [self fetchedResultsControllerPredicates];
    if (controller) {
        [controller performFetch:nil];
    }
    [[self tableView] reloadData];
}

@end
