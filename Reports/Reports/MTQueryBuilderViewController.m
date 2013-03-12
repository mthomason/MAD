//
//  MUIViewControllerQueryBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderViewController.h"
#import "AppDelegate.h"
#import "MTClipboardView.h"
#import "RptqDocument+ActiveDocument.h"

#pragma mark - Private Category

@interface MTQueryBuilderViewController()

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerTables;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerLinks;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerGroups;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerPredicates;

@property (retain, nonatomic) UIFont *boldSystemFont;
@property (retain, nonatomic) NSArray *tableSectionTitles;

@property (nonatomic, retain) IBOutlet MTClipboardView *viewClipboard;

@property (nonatomic, assign) BOOL beganUpdates;

@property (nonatomic, retain) NSMutableDictionary *modelWithZeroTables;
@property (nonatomic, retain) NSMutableDictionary *modelWithOneTable;
@property (nonatomic, retain) NSMutableDictionary *modelWithTwoOrMoreTables;

@end

#pragma mark - Main

@implementation MTQueryBuilderViewController

- (void)dealloc {
    [_modelWithZeroTables release];
    [_modelWithOneTable release];
    [_modelWithTwoOrMoreTables release];
    [_boldSystemFont release];
    [_fetchedResultsControllerTables release];
    [_fetchedResultsControllerLinks release];
    [_fetchedResultsControllerGroups release];
    [_fetchedResultsControllerPredicates release];
    [_tableSectionTitles release];
    [_tableViewQueryBuilder release];
    [_toolbar release];
    [_navigationItemMain release];
    [_viewClipboard release];
    [_toolbarTop release];
    [super dealloc];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self tableViewQueryBuilder].contentSize = CGSizeMake([self tableViewQueryBuilder].frame.size.width, [self tableViewQueryBuilder].contentSize.height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setBoldSystemFont:[[[UIFont boldSystemFontOfSize:([UIFont systemFontSize] + 3.0000f)] retain] autorelease]];
    
    [[self tableViewQueryBuilder] setBackgroundColor: [UIColor paperGraphPaper]];
    [[self tableViewQueryBuilder] setOpaque: YES];
    [[self tableViewQueryBuilder] setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSString *h1 = NSLocalizedString(@"Layout", @"Layout");
    NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
    NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
    NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
    NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
    NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
    
    //There are three configurations for the table.  These configurations depend on the number of schemas in the query: zero, one, or more than one.
    
    NSArray *sections = @[@(UIViewControllerSchemaTablesSectionsDatasource),
                          @(UIViewControllerSchemaTablesSectionsTables),
                          @(UIViewControllerSchemaTablesSectionsInstructions)];
    
    NSArray *countRowsForSection = @[@(1), @(-1), @(-1)];
    NSDictionary *countRowsForSectionDictionary =  [NSDictionary dictionaryWithObjects:countRowsForSection forKeys:sections];
    
    NSArray *headersSection = @[h2, h3, h1];
    NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection forKeys: sections];
    
    NSArray *heightRowsForSection = @[@(44.0000f), @([UITableViewCellTableName defaultHeight]), @([UITableViewCellInstruction defaultHeight])];
    NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection forKeys:sections];
    
    NSDictionary *tableOutline = @{KEY_TBL_SEC_SECTIONS : sections,
                                   KEY_TBL_SEC_HEADERS : headersSectionDictionary,
                                   KEY_TBL_SEC_ROW_COUNT : countRowsForSectionDictionary,
                                   KEY_TBL_SEC_ROW_HEIGHT: heightRowsForSectionDictionaryDictionary};
    
    [self setModelWithZeroTables: [NSMutableDictionary dictionaryWithDictionary:tableOutline]];
    
    //Configuration with one schema referenced in the database
    
    sections = @[@(UIViewControllerSchemaTablesSectionsDatasource),
                 @(UIViewControllerSchemaTablesSectionsTables),
                 @(UIViewControllerSchemaTablesSectionsGroups),
                 @(UIViewControllerSchemaTablesSectionsPredicate),
                 @(UIViewControllerSchemaTablesSectionsInstructions)];
    
    countRowsForSection = @[@(1), @(-1), @(-1), @(-1), @(-1)];
    countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects:countRowsForSection forKeys:sections];
    
    headersSection = @[h2, h3, h5, h6, h1];
    headersSectionDictionary = [NSDictionary dictionaryWithObjects:headersSection forKeys: sections];
    
    heightRowsForSection = @[@(44.0000f), @([UITableViewCellTableName defaultHeight]),
                             @(44.0000f), @(44.0000f), @([UITableViewCellInstruction defaultHeight])];
    heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection forKeys:sections];
    
    tableOutline = @{KEY_TBL_SEC_SECTIONS : sections,
                     KEY_TBL_SEC_HEADERS : headersSectionDictionary,
                     KEY_TBL_SEC_ROW_COUNT : countRowsForSectionDictionary,
                     KEY_TBL_SEC_ROW_HEIGHT: heightRowsForSectionDictionaryDictionary};
    
    //Configuration with two or more schemas referenced in the database
    
    [self setModelWithOneTable: [NSMutableDictionary dictionaryWithDictionary:tableOutline]];
    
    sections = @[@(UIViewControllerSchemaTablesSectionsDatasource),
                 @(UIViewControllerSchemaTablesSectionsTables),
                 @(UIViewControllerSchemaTablesSectionsLinks),
                 @(UIViewControllerSchemaTablesSectionsGroups),
                 @(UIViewControllerSchemaTablesSectionsPredicate),
                 @(UIViewControllerSchemaTablesSectionsInstructions)];
    
    countRowsForSection = @[@(1), @(-1), @(-1), @(-1), @(-1), @(-1)];
    countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects:countRowsForSection forKeys:sections];
    
    headersSection = @[h2, h3, h4, h5, h6, h1];
    headersSectionDictionary = [NSDictionary dictionaryWithObjects:headersSection forKeys:sections];
    
    
    heightRowsForSection = @[@(44.0000f), @([UITableViewCellTableName defaultHeight]), @([UITableViewCellQueryLink defaultHeight]),
                             @(44.0000f), @(44.0000f), @([UITableViewCellInstruction defaultHeight])];
    heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects:heightRowsForSection forKeys:sections];
    
    tableOutline = @{KEY_TBL_SEC_SECTIONS : sections,
                     KEY_TBL_SEC_HEADERS : headersSectionDictionary,
                     KEY_TBL_SEC_ROW_COUNT : countRowsForSectionDictionary,
                     KEY_TBL_SEC_ROW_HEIGHT: heightRowsForSectionDictionaryDictionary};
    
    [self setModelWithTwoOrMoreTables: [NSMutableDictionary dictionaryWithDictionary:tableOutline]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [[self toolbar] setTintColor:[UIColor edaBlueDark]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [[self tableViewQueryBuilder] reloadData];
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

    } else if ([[segue identifier] isEqualToString: MNSSegueShowSql]) {                                 // MARK: Prepair to show sql.
        [[segue destinationViewController] setDelegate: self];
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

                    NSMutableArray *tableNames = [[NSMutableArray alloc] initWithArray: [RptqDatabaseSchemaTable namesForTablesInQueryForManagedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]]];

                    //NSMutableArray *tableNames = [[NSMutableArray alloc] initWithArray: [RptqQueryTables namesForManagedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]]];
                    if ([tableNames count]) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT name IN %@", tableNames];
                        [request setPredicate: predicate];
                    }
                    [tableNames release];
                    
                        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                              managedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]
                                                                                                sectionNameKeyPath: nil
                                                                                                         cacheName: nil];
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
                        //NSLog(@"Setting add predicate log");
                        [tvc setAddPredicateDelegate: self];
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
                        NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
                        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                        RptqQuery *query = [[database hasQueries] anyObject];
                        RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                                                             forQuery: query];
                        [tvc setInitalStepperValue:([[section height] floatValue] * 2)];
                        [tvc setInitalSwitchValue:[[section visibility] boolValue]];
                    }
                }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowReportLayout]) {
        if ([[segue destinationViewController] isKindOfClass: [MTReportDesignerViewController class]]) {
            [[segue destinationViewController] setDelegate: self];
        }
    } else if ([[segue identifier] isEqualToString:MNSIdentifierSegueShowReportViewerFromQuery]) {
        [[segue destinationViewController] setDelegate: self];
    }
}

#pragma mark - Toolbar Actions

#pragma mark Top Toolbar Actions

//Labeled as "Reports"
- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)edit:(id)sender {
    BOOL editing = ![[self tableViewQueryBuilder] isEditing];
    UIBarButtonSystemItem buttonType = editing ? UIBarButtonSystemItemDone: UIBarButtonSystemItemEdit;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                   target: self
                                                                                   action: @selector(edit:)];
    [[self navigationItem] setRightBarButtonItem:barButtonItem];
    /*
     NSMutableArray *tbItems = [[NSMutableArray alloc] initWithArray:[[self toolbar] items]];
     [tbItems replaceObjectAtIndex:([tbItems count] - 1) withObject: barButtonItem];
     [[self toolbar] setItems: tbItems];
     [tbItems release];
     */
    [[self tableViewQueryBuilder] setEditing: editing];
    [barButtonItem release];
}

#pragma mark Table Header Actions

- (void)addConnection:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddDatabaseDrivers sender: sender];
}

- (void)addTable:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddTableViewController sender: sender];
}

- (void)addLink:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddLinkViewController sender: sender];
}

- (void)addPredicate:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddPredicateViewController sender: sender];
}

- (void)addGroup:(id)sender {
    [self performSegueWithIdentifier: MNSIdentifierSegueShowAddGroupViewController sender: sender];
}

#pragma mark - Modal helper

- (UIViewControllerSchemaTablesSections)tableSectionTypeForIndexPathSection:(NSUInteger)sec {
    UIViewControllerSchemaTablesSections result = sec;
    NSArray *sectionTypes = [[[self datamodel] objectForKey: KEY_TBL_SEC_SECTIONS] retain];
    if ([sectionTypes count] >= sec) {
        result = [[sectionTypes objectAtIndex:sec] integerValue];
    }
    [sectionTypes release];
    return result;
}

- (NSUInteger)sectionPositionForTableSectionType:(UIViewControllerSchemaTablesSections)sec {
    NSInteger result = 0;
    NSArray *sectionTypes = [[[self datamodelForNumberOfTables:[[self tableViewQueryBuilder] numberOfRowsInSection: 1]] objectForKey: KEY_TBL_SEC_SECTIONS] retain];
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


#pragma mark - Delegates

#pragma mark Layout Settings Delegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                                         forQuery: query];
    [section setHeight: [NSNumber numberWithFloat:height]];
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                                         forQuery: query];
    [section setVisibility: [NSNumber numberWithBool:isVisible]];
    [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
}

#pragma mark - Delegates

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    //if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    //} else {
    //    [self dismissViewControllerAnimated:YES completion:nil];
    //}
}

- (void)modalTableViewControllerDidFinish:(id)controller {
    //if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    //} else {
    //    [self dismissViewControllerAnimated:YES completion:nil];
    //}
}

- (void)addRptqPredicate:(RptqQueryPredicate *)predicate {
    [self dismissViewControllerAnimated:YES completion:nil];

    [RptqQueryPredicate addPredicate:predicate forManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];

    [[self tableViewQueryBuilder] reloadData];
    [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
}

- (void)addPredicateDidCancel:(MTQueryBuilderPredicateFormatViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)link {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [RptqQueryLinks insertQueryLink:link intoManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];    
    [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
}

- (void)viewControllerSchemaAddLinkDidFinish:(MTQueryBuilderAddLinkFirstTableViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewControllerSchemaAddTableDidFinish:(MTQueryBuilderAddTableViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)uITableViewControllerSchemaAddGroupDidFinish:(MTQueryBuilderAddGroupViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)uITableViewControllerSchemaAddPredicateDidFinish:(MTQueryBuilderAddPredicateViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addGroupDidAddGroupWithField:(RptqDatabaseSchemaField *)field andSort:(MNSSortOrder)sortOrder {

    [self dismissViewControllerAnimated:YES completion:nil];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

//    [[self tableViewQueryBuilder] beginUpdates];

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];

    RptqQueryGroup *queryGroup = [RptqQueryGroup createQueryGroupFor:field andSort:sortOrder inManagedObjectContext:managedObjectContext];
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    [query addHasQueryGroupsObject: queryGroup];

    
    NSError *error = nil;
    NSInteger groupCount = [RptqQueryGroup numberOfGroupsForQuery:query];
    NSInteger weight = groupCount - 1;
    NSUInteger secFirstTransaction = [self sectionPositionForTableSectionType:UIViewControllerSchemaTablesSectionsGroups];
    NSUInteger rowFirstTransaction = weight;
    NSUInteger secSecondTransaction = [self sectionPositionForTableSectionType:UIViewControllerSchemaTablesSectionsInstructions];
    NSUInteger rowSecondTransaction = groupCount + 1;
    NSUInteger rowThirdTransaction = groupCount + 3;
    
    [managedObjectContext save: &error];
    //if (!error) {
    NSArray *indexPaths = [NSArray arrayWithObjects:
                           [NSIndexPath indexPathForRow: rowFirstTransaction inSection: secFirstTransaction],
                           [NSIndexPath indexPathForRow: rowSecondTransaction inSection: secSecondTransaction],
                           [NSIndexPath indexPathForRow: rowThirdTransaction inSection: secSecondTransaction],
                           nil];
    
    [[self tableViewQueryBuilder] insertRowsAtIndexPaths: indexPaths
                                        withRowAnimation: UITableViewRowAnimationAutomatic];
    
    //[[self tableViewQueryBuilder] endUpdates];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
    [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
}

- (void)viewControllerSchemaAddTableDidSelectTable:(RptqDatabaseSchemaTable *)table {
    [self dismissViewControllerAnimated:YES completion:nil];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

    NSIndexSet *indexSetSections = nil;
    MTReportDocument *reportDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSDictionary *oldLayout = [[self datamodel] retain];
    NSArray *oldLayoutSectionTypes = [[oldLayout objectForKey:KEY_TBL_SEC_SECTIONS] retain];
    [RptqDatabaseSchemaTable addTableToQuery:table forManagedObjectContext:[reportDocument managedObjectContext]];

    //Find the position of the table that was added, so it may be inserted at the right index.
    RptqQuery *query = [[table inQuery] anyObject];
    NSSet *tables = [[query hasTables] retain];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *tablesSorted = [[tables sortedArrayUsingDescriptors:@[sortDescriptor]] retain];
    NSUInteger indexCounter = 0;
    for (RptqDatabaseSchemaTable *foundTable in tablesSorted) {
        if ([foundTable objectID] == [table objectID]) {
            break;
        }
        indexCounter++;
    }
    NSUInteger sectionPosition = [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsTables];
    NSIndexPath *insertedRowIndexPath = [[NSIndexPath indexPathForRow:indexCounter inSection:sectionPosition] retain];
    
    [tablesSorted release];
    [tables release];
    
    NSDictionary *newLayout = [[self datamodel] retain];
    NSArray *newLayoutSectionTypes = [[newLayout objectForKey:KEY_TBL_SEC_SECTIONS] retain];

    if ([oldLayoutSectionTypes count] != [newLayoutSectionTypes count]) {
        if ([oldLayoutSectionTypes count] < [newLayoutSectionTypes count]) { //add sections
            //Constrained that it only will work when sections being added in an index set, or next to each other.
            NSInteger secctr = 0;
            BOOL startIndexSet = NO;
            NSInteger startIndex = -1;
            NSInteger lengtho = [newLayoutSectionTypes count] - [oldLayoutSectionTypes count];
            for (NSNumber *typenum in newLayoutSectionTypes) {
                UIViewControllerSchemaTablesSections stsection = [typenum integerValue];
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

    if (indexSetSections != nil) {
        [[self tableViewQueryBuilder] beginUpdates];
        [[self tableViewQueryBuilder] insertSections: indexSetSections
                                    withRowAnimation: UITableViewRowAnimationAutomatic];
        [[self tableViewQueryBuilder] endUpdates];
    }
    
    [reportDocument saveContext];
    
    [[self tableViewQueryBuilder] beginUpdates];
    [[self tableViewQueryBuilder] insertRowsAtIndexPaths: @[insertedRowIndexPath]
                                        withRowAnimation: UITableViewRowAnimationAutomatic];
    [[self tableViewQueryBuilder] endUpdates];

    
    
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];

    [newLayoutSectionTypes release];
    [oldLayoutSectionTypes release];
    [oldLayout release];
    [newLayout release];
    [reportDocument release];
    [indexSetSections release];
    [insertedRowIndexPath release];
    
}

#pragma mark - Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id queryBuilderDataModel = [self datamodel];
    NSInteger numberOfSections = [[queryBuilderDataModel objectForKey: KEY_TBL_SEC_HEADERS] count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    UIViewControllerSchemaTablesSections ts = [self tableSectionTypeForIndexPathSection: section];
    
    NSDictionary *rowsDict = [[[self datamodel] objectForKey: KEY_TBL_SEC_ROW_COUNT] retain];
    NSInteger numberOfRows = 0;
    numberOfRows = [[rowsDict objectForKey:[NSNumber numberWithInt: ts]] intValue];
    if (numberOfRows < 0) {
        switch (ts) {
            case UIViewControllerSchemaTablesSectionsInstructions: {
                //The sections are report header, report footer, page header, page footer,
                //  body, group header, and group footer
                NSInteger numberOfGroups = [[[self.fetchedResultsControllerGroups sections] objectAtIndex: 0] numberOfObjects];
                numberOfRows = (2 * numberOfGroups) + 5;
                //NSLog(@"Section Rows:   %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsTables: {
                numberOfRows = [[[self.fetchedResultsControllerTables sections] objectAtIndex: 0] numberOfObjects];
                //NSLog(@"Table Rows:     %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsLinks: {
                numberOfRows = [[[self.fetchedResultsControllerLinks sections] objectAtIndex: 0] numberOfObjects];
                //NSLog(@"Link Rows:      %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsPredicate: {
                numberOfRows = [[[self.fetchedResultsControllerPredicates sections] objectAtIndex: 0] numberOfObjects];
                //NSLog(@"Predicate Rows: %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsGroups: {
                numberOfRows = [[[self.fetchedResultsControllerGroups sections] objectAtIndex: 0] numberOfObjects];
                //NSLog(@"Group Rows:     %d", numberOfRows);
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
    UIViewControllerSchemaTablesSections sectionType = [self tableSectionTypeForIndexPathSection: section];
	return (sectionType == UIViewControllerSchemaTablesSectionsTables ||
            sectionType == UIViewControllerSchemaTablesSectionsGroups ||
            sectionType == UIViewControllerSchemaTablesSectionsPredicate ||
            sectionType == UIViewControllerSchemaTablesSectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self tableSectionTypeForIndexPathSection:[indexPath section]] == UIViewControllerSchemaTablesSectionsGroups) ? YES : NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewControllerSchemaTablesSections ts = [self tableSectionTypeForIndexPathSection:[indexPath section]];

	switch (editingStyle) {

        // MARK: UITableViewCellEditingStyleDelete
        case UITableViewCellEditingStyleDelete: {
            switch (ts) {
                    
                // MARK: Delete UIViewControllerSchemaTablesSectionsTables
                case UIViewControllerSchemaTablesSectionsTables: {
                    
                    NSArray *deleteRows = nil;
                    NSIndexSet *deleteSections = nil;
                    
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:YES];
                    
                    MTReportDocument *reportDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
                    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                    
                    // FIXME: Only allow table to be deleted if it's not linked or otherwise used in the query.
                    
                    NSInteger numberOfTables = [RptqDatabaseSchemaTable countOfTablesInQueryForManagedObjectContext:managedObjectContext];
                    NSDictionary *oldTableLayout = [[NSDictionary alloc] initWithDictionary:[self datamodelForNumberOfTables: numberOfTables]];

                    RptqDatabaseSchemaTable *table = [[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: [indexPath row] inSection: 0]];
                    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
                    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                    RptqQuery *query = [[database hasQueries] anyObject];
                    [query removeHasTablesObject:table];

                    deleteRows = [[NSArray alloc] initWithObjects:indexPath, nil];
                    numberOfTables = numberOfTables - 1;

                    NSDictionary *newTableLayout = [[NSDictionary alloc] initWithDictionary: [self datamodelForNumberOfTables: numberOfTables]];
                    NSArray *oldLayoutSectionTypes = [oldTableLayout objectForKey:KEY_TBL_SEC_SECTIONS];
                    NSArray *newLayoutSectionTypes = [newTableLayout objectForKey:KEY_TBL_SEC_SECTIONS];
                    
                    if ([oldLayoutSectionTypes count] > [newLayoutSectionTypes count]) {
                        NSInteger secctr = 0;
                        BOOL startIndexSet = NO;
                        NSInteger startIndex = -1;
                        NSInteger lengtho = [oldLayoutSectionTypes count] - [newLayoutSectionTypes count];
                        for (NSNumber *typenum in oldLayoutSectionTypes) {
                            UIViewControllerSchemaTablesSections stsection = [typenum integerValue];
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
                    
                    if (deleteSections != nil) {
                        [tableView beginUpdates];
                        [tableView deleteSections: deleteSections withRowAnimation: UITableViewRowAnimationAutomatic];
                        [tableView endUpdates];
                    }
                    [reportDocument saveContext];
                    [tableView beginUpdates];
                    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [tableView endUpdates];
                    
                    [reportDocument save:nil];
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                    [deleteRows release];
                    [deleteSections release];
                    [reportDocument release];
                    [oldTableLayout release];
                    break;
                }

                // MARK: Delete UIViewControllerSchemaTablesSectionsLinks
                case UIViewControllerSchemaTablesSectionsLinks: {
                    UITableViewCellQueryLink *tvcLink = (UITableViewCellQueryLink *)[[tableView cellForRowAtIndexPath:indexPath] retain];
                    if (tvcLink) {
                        NSManagedObjectID *objid = [tvcLink tableID];
                        [RptqQueryLinks deleteLinkWithID:objid fromObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
                        [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
                    }
                    [tvcLink release];
                    break;
                }
                    
                // MARK: Delete UIViewControllerSchemaTablesSectionsGroups
                case UIViewControllerSchemaTablesSectionsGroups: {
                    
                    MTReportDocument *activateDocument = [[MTActiveDocument sharedDocument] activeDocument];
                    NSManagedObjectContext *managedObjectContext = [activateDocument managedObjectContext];
                    
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];
                    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
                    NSError *error = nil;
                    NSInteger result = [managedObjectContext countForFetchRequest:request error:&error];
                    NSInteger numberOfGroups = error ? 0 : result;

                    if (document) {
                        RptqQuery *query = [[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                        NSSet *groups = [[query hasQueryGroups] retain];
                        NSInteger weightToRemove = [indexPath row];

                        RptqQueryGroup *groupToRemove = nil;
                        for (RptqQueryGroup *group in groups) {
                            if ([[group weight] integerValue] > weightToRemove) {
                                [group setWeight:[NSNumber numberWithInteger:([[group weight] integerValue] - 1)]];
                            } else if ([[group weight] integerValue] == weightToRemove) {
                                groupToRemove = group;
                            }
                        }
                                                
                        if (groupToRemove) {
                            NSSet *sectionsToRemove = [[groupToRemove hasSection] retain];
                            NSArray *sections = [[sectionsToRemove allObjects] retain];
                            if ([sections count] == 2) {
                                //[managedObjectContext deleteObject: [sections objectAtIndex: 0]];
                                [groupToRemove removeHasSectionObject: [sections objectAtIndex: 0]];
                                //[managedObjectContext deleteObject: [sections objectAtIndex: 1]];
                                [groupToRemove removeHasSectionObject: [sections objectAtIndex: 1]];
                            }
                            [sections release];
                            [sectionsToRemove release];
                            [managedObjectContext deleteObject: groupToRemove];
                            [query removeHasQueryGroupsObject: groupToRemove];
                            
                            [activateDocument saveContext];
                                NSInteger section = [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsInstructions];
                                NSInteger headerSectionRow = weightToRemove + 2;
                                NSInteger footerSectionRow = 5 + (numberOfGroups * 2) - 1 - 2 - weightToRemove;
                                //NSLog(@"Index paths: %@, %@, %@", indexPath, [NSIndexPath indexPathForRow: headerSectionRow inSection: section], [NSIndexPath indexPathForRow: footerSectionRow inSection: section]);
                                NSArray *indexPaths = [[NSArray alloc] initWithObjects:
                                                       indexPath,
                                                       [NSIndexPath indexPathForRow: headerSectionRow inSection: section],
                                                       [NSIndexPath indexPathForRow: footerSectionRow inSection: section],
                                                       nil];
                                [[self tableViewQueryBuilder] deleteRowsAtIndexPaths: indexPaths
                                                                    withRowAnimation: UITableViewRowAnimationAutomatic];
                                [indexPaths release];
                        }
                        
                        [groups release];
                        
                    }

                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                    [activateDocument save:^(BOOL success) {

                    }];
                    
                    
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

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [NSArray array];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *result = nil;

    NSInteger row = [indexPath row];
    UIViewControllerSchemaTablesSections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];

    switch (section) {

        // MARK: Display optional instructions about query builder.
        case UIViewControllerSchemaTablesSectionsInstructions: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellInstruction";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            NSInteger numberOfGroups = [[[self.fetchedResultsControllerGroups sections] objectAtIndex: 0] numberOfObjects];
            NSString *sectionName = [[RptqDocumentSection getDocumentSectionNameForRow: row withNumberOfGroups:numberOfGroups] retain];
            NSInteger sectionIndentLevel = [RptqDocumentSection getDocumentSectionIndentLevelForRow:row withNumberOfGroups:numberOfGroups];
            [[(UITableViewCellInstruction *) result labelGroupType] setText:[NSString stringWithFormat:@"◦ %@", sectionName]];
            [[(UITableViewCellInstruction *) result labelGroupType] setBackgroundColor:[UIColor clearColor]];
            [[(UITableViewCellInstruction *) result labelGroupType] setFont:[self boldSystemFont]];
            [(UITableViewCellInstruction *) result setIndentationLevel: (sectionIndentLevel+1)];
            [sectionName release];
            break;
        }

        // MARK: Display and identify the data source and data sources
        case UIViewControllerSchemaTablesSectionsDatasource: {
            static NSString *MyIdentifierUITableViewCellDataSource = @"UITableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellDataSource];
            NSArray *connections = [RptqUserCredentals userCredentalsForManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
            if (connections) {
                [connections retain];
                if ([connections count] >= 1) {
                    RptqUserCredentals *connection = [[connections objectAtIndex: 0] retain];
                    [[result textLabel] setText:[NSString stringWithFormat:@"◦ %@", [connection database_driver_type]]];
                    [[result textLabel] setFont:[self boldSystemFont]];
                    [[result detailTextLabel] setText:@""];
                    [connection release];
                }
                [connections release];
            }
            [[result textLabel] setBackgroundColor:[UIColor clearColor]];
            [[result detailTextLabel] setBackgroundColor:[UIColor clearColor]];
            break;
        }

        // MARK: Display the table names that are used in the query
        case UIViewControllerSchemaTablesSectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            UITableViewCellTableName *resultR = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            RptqDatabaseSchemaTable *tablea = [[[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            [[resultR textLabel] setText: [NSString stringWithFormat:@"◦ %@", [tablea name]]];
            [[resultR textLabel] setFont: [self boldSystemFont]];
            
            [[resultR textLabel] setBackgroundColor:[UIColor clearColor]];
            [resultR setIndentationLevel: 1];
            [tablea release];
            result = resultR;
            break;
        }
        
        // MARK: Display the table links or joins that are used in the query.
        case UIViewControllerSchemaTablesSectionsLinks: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            RptqQueryLinks *links = [[[self fetchedResultsControllerLinks] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            
            [[(UITableViewCellQueryLink *)result labelTableLeft] setText:
             [NSString stringWithFormat:@"%@.%@", [links tableleft], [links fieldleft]]];
            [[(UITableViewCellQueryLink *)result labelTableRight] setText:
             [NSString stringWithFormat:@"%@.%@", [links tableright], [links fieldright]]];
            [[(UITableViewCellQueryLink *)result labelJoinDesc] setText: [NSString stringWithFormat:@"%@ (%@)", [MNSLinkTypeSymbols objectAtIndex: [[links jointypeenum] integerValue]], [MNSLinkTypeNames objectAtIndex: [[links jointypeenum] integerValue]]]];
            [(UITableViewCellQueryLink *)result setTableID: [links objectID]];
            [links release];
            break;
        }

        // MARK: Display the groupings used in the query.
        case UIViewControllerSchemaTablesSectionsGroups: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            RptqQueryGroup *group = [[self fetchedResultsControllerGroups] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]];
//            [result setBackgroundColor:[UIColor whiteColor]];
            [[result backgroundView] setBackgroundColor:[UIColor whiteColor]];
            [[(UITableViewCellQueryGroup *)result labelMain] setText: [group fieldNameNice]];
            [[(UITableViewCellQueryGroup *)result labelDetail] setText: [group sortDisplayNice]];
            break;
        }
        
        // MARK: Display the predicates or conditions on the query.
        case UIViewControllerSchemaTablesSectionsPredicate: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryPredicate";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            RptqQueryPredicate *predicate = [[[self fetchedResultsControllerPredicates] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            
            NSString *leftFieldDisplay = nil, *rightFieldDisplay = nil;
            if ([predicate fieldleftpred] != nil) {
                leftFieldDisplay = [[predicate fieldleftpred] retain];
            } else {
                leftFieldDisplay = [[[predicate hasLeftField] toString] retain];
            }
            
            if ([predicate fieldrightpred] != nil) {
                rightFieldDisplay = [[predicate fieldrightpred] retain];
            } else {
                rightFieldDisplay = [[[predicate hasRightField] toString] retain];
            }
            
            
            [[(UITableViewCellQueryPredicate *)result labelMain] setText: leftFieldDisplay];
            [[(UITableViewCellQueryPredicate *)result labelDetail] setText: rightFieldDisplay];
            
            [leftFieldDisplay release];
            [rightFieldDisplay release];
            [predicate release];
            break;
        }
        
        case UIViewControllerSchemaTablesSectionsSql: {
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
    
    //[result setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    //[[self cellBackgroundView] setFrame:[result bounds]];

    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *result = nil;
    if ([AppDelegate isPad] == NO || YES) {
        MTViewTableHeader *headerView = [[MTViewTableHeader alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 320.0000f, 29.0000f)];
//        MTViewTableHeader *headerView = [[MTViewTableHeader alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, tableView.frame.size.width, 29.0000f)];
        if ([AppDelegate isPad]) {
            [headerView setBackgroundColor:[UIColor clearColor]];
        }
        section = [self tableSectionTypeForIndexPathSection: section];
        
        switch (section) {
                
            case UIViewControllerSchemaTablesSectionsInstructions: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Report Sections", @"Sections")];
                [[headerView buttonAdd] setHidden:YES];
                break;
            }
                
            case UIViewControllerSchemaTablesSectionsDatasource: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Datasource", @"Datasource")];
                [[headerView buttonAdd] setHidden:YES];
                break;
            }
                
            case UIViewControllerSchemaTablesSectionsTables: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Tables", @"Next to the button to add database tables.")];
                [[headerView buttonAdd] addTarget:self action:@selector(addTable:) forControlEvents:UIControlEventTouchUpInside];
                break;
            }
                
            case UIViewControllerSchemaTablesSectionsLinks: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Links", @"Next to the button to add database tables.")];
                [[headerView buttonAdd] addTarget:self action:@selector(addLink:) forControlEvents:UIControlEventTouchUpInside];
                break;
            }
                
            case UIViewControllerSchemaTablesSectionsGroups: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Groups", @"Next to the button to add database tables.")];
                [[headerView buttonAdd] addTarget:self action:@selector(addGroup:) forControlEvents:UIControlEventTouchUpInside];
                break;
            }
                
            case UIViewControllerSchemaTablesSectionsPredicate: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Predicate", @"Next to the button to add database tables.")];
                [[headerView buttonAdd] addTarget:self action:@selector(addPredicate:) forControlEvents:UIControlEventTouchUpInside];
                break;
            }
            case UIViewControllerSchemaTablesSectionsSql: {
                [[headerView labelTitle] setText:NSLocalizedString(@"Build Query", @"Build Query")];
                [[headerView buttonAdd] setHidden:YES];
                break;
            }
            default: {
                [[headerView labelTitle] setText:@""];
                [[headerView buttonAdd] setHidden:YES];
                break;
            }
                
        }
        result = [headerView autorelease];
    }
    return result;
}


#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewControllerSchemaTablesSections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];
    if (section == UIViewControllerSchemaTablesSectionsInstructions && [AppDelegate isPad] == NO) {
        [self setLastSelectedRowNumber: [indexPath row]];
        [self performSegueWithIdentifier:MNSIdentifierSegueShowLayoutSettings sender:self];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 29.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = MNSTableViewCellHeightDefault;
    UIViewControllerSchemaTablesSections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];
    if (section == UIViewControllerSchemaTablesSectionsSql) {
        result = [indexPath row] == 0 ? [UITableViewCellOverride defaultHeight] : [UITableViewCellQueryInput defaultHeight];
    } else if (section == UIViewControllerSchemaTablesSectionsGroups) {
        result = [UITableViewCellOverride defaultHeight] * 1.6;
    } else {
        NSDictionary *tableMetaHeight = [[self datamodel] objectForKey:KEY_TBL_SEC_ROW_HEIGHT];
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

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

/*
- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
*/

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

 
/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

#pragma mark - NSFetchedResultsSetup

- (void)reloadDocument:(MTReportDocument *)documentReport {
    NSManagedObjectContext *managedObjectContext = [[documentReport managedDocument] managedObjectContext];
    
    {
        RptqQuery *query = [RptqDocument queryForActiveDocument];
        
        NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
        request.predicate = [NSPredicate predicateWithFormat:@"ANY inQuery == %@", [query objectID]];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
        [request setSortDescriptors: @[sortDescriptor]];
        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                              managedObjectContext: managedObjectContext
                                                                                sectionNameKeyPath: nil
                                                                                         cacheName: nil];
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
                                                                                         cacheName: nil];
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
                                                                                         cacheName: nil];
        [frc setDelegate:self];
        [self setFetchedResultsControllerGroups: frc];
        [self performFetchGroups];
        [frc release];
        frc = nil;
        
    }
    
    {
        NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fieldleftpred" ascending:YES];
        [request setSortDescriptors: @[sortDescriptor]];
        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                              managedObjectContext: managedObjectContext
                                                                                sectionNameKeyPath: nil
                                                                                         cacheName: nil];
        [frc setDelegate:self];
        [self setFetchedResultsControllerPredicates: frc];
        [self performFetchPredicate];
        [frc release];
        
        frc = nil;
    }
    [[self tableViewQueryBuilder] reloadData];
}

- (NSMutableDictionary *)datamodel {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    NSInteger numberOfTablesInQuery = [RptqDatabaseSchemaTable countOfTablesInQueryForManagedObjectContext:managedObjectContext];
    return [self datamodelForNumberOfTables:numberOfTablesInQuery];
}

- (NSMutableDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables {
    NSMutableDictionary *result;
    switch (numberOfTables) {
        case 0:
            result = [self modelWithZeroTables];
            break;
        case 1:
            result = [self modelWithOneTable];
            break;
        default:
            result = [self modelWithTwoOrMoreTables];
            break;
    }
    return result;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (![self suspendAutomaticTrackingOfChangesInManagedObjectContext]) {
        [[self tableViewQueryBuilder] beginUpdates];
        [self setBeganUpdates: YES];
    }
}

- (NSMutableArray *)sectionsUsedByFetchedResultsController: (NSFetchedResultsController *)controller {

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

    if ([controller isEqual:[self fetchedResultsControllerTables]]) {
        [result addObject: [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsTables]]];
    } else if ([controller isEqual:[self fetchedResultsControllerLinks]]) {
        [result addObject: [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsLinks]]];
    } else if ([controller isEqual:[self fetchedResultsControllerGroups]]) {
        [result addObject: [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsInstructions]]]; //Once for group header settings
        [result addObject: [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsInstructions]]]; //Once for group footer settings
        [result addObject: [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsGroups]]];
    } else if ([controller isEqual:[self fetchedResultsControllerPredicates]]) {
        [result addObject: [NSNumber numberWithInteger: [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsPredicate]]];
    }
    
    return [result autorelease];

}

- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex
	 forChangeType: (NSFetchedResultsChangeType)type {

    
    NSMutableArray *sections = [[self sectionsUsedByFetchedResultsController: controller] retain];
    
    for (NSNumber *section in sections) {
        UIViewControllerSchemaTablesSections updateSection = [section integerValue];
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    [[self tableViewQueryBuilder] insertSections: [NSIndexSet indexSetWithIndex:updateSection]
                                              withRowAnimation: UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [[self tableViewQueryBuilder] deleteSections:
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
        UIViewControllerSchemaTablesSections updateSection = [section integerValue];
        
        NSIndexPath *path = [NSIndexPath indexPathForRow: [indexPath row]
                                               inSection: updateSection];
        
        if (path) {
            if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
                switch(type) {
                    case NSFetchedResultsChangeInsert: {
                        [[self tableViewQueryBuilder] insertRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeDelete: {
                        [[self tableViewQueryBuilder] deleteRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeUpdate: {
                        [[self tableViewQueryBuilder] reloadRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeMove: {
                        [[self tableViewQueryBuilder] deleteRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        [[self tableViewQueryBuilder] insertRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                }
            }
        }
    }
    
    [sections release];
    //[sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

    //    NSNumber *section = obj;
        
    //}];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates) [[self tableViewQueryBuilder] endUpdates];
}

- (void)endSuspensionOfUpdatesDueToContextChanges {
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
}

- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(BOOL)suspend {
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    } else {
        [self performSelector:@selector(endSuspensionOfUpdatesDueToContextChanges) withObject:0 afterDelay:0];
    }
}

#pragma mark - Fetching

- (void)performFetchTables {
    if (self.fetchedResultsControllerTables) {
        if (self.fetchedResultsControllerTables.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerTables.fetchRequest.entityName, self.fetchedResultsControllerTables.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerTables.fetchRequest.entityName);
        }
        NSError *error = nil;
        [self.fetchedResultsControllerTables performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [[self tableViewQueryBuilder] reloadData];
}

- (void)performFetchLinks {
    if (self.fetchedResultsControllerLinks) {
        if (self.fetchedResultsControllerLinks.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerLinks.fetchRequest.entityName, self.fetchedResultsControllerLinks.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerLinks.fetchRequest.entityName);
        }
        NSError *error = nil;
        [self.fetchedResultsControllerLinks performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [[self tableViewQueryBuilder] reloadData];
}

- (void)performFetchGroups {
    if (self.fetchedResultsControllerGroups) {
        if (self.fetchedResultsControllerGroups.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerGroups.fetchRequest.entityName, self.fetchedResultsControllerLinks.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerGroups.fetchRequest.entityName);
        }
        NSError *error = nil;
        [self.fetchedResultsControllerGroups performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [[self tableViewQueryBuilder] reloadData];
}

- (void)performFetchPredicate {
    if (self.fetchedResultsControllerPredicates) {
        if (self.fetchedResultsControllerPredicates.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerPredicates.fetchRequest.entityName, self.fetchedResultsControllerPredicates.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsControllerPredicates.fetchRequest.entityName);
        }
        NSError *error = nil;
        [self.fetchedResultsControllerPredicates performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [[self tableViewQueryBuilder] reloadData];
}

@end
