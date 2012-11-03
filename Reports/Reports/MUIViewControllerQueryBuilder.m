//
//  MUIViewControllerQueryBuilder.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerQueryBuilder.h"
#import "AppDelegate.h"

#pragma mark - Private Category

@interface MUIViewControllerQueryBuilder()

@property (retain) UIFont *boldSystemFont;
@property (retain) UIView *cellBackgroundView;
@property (retain) QueryBuilderDataModal *queryBuilderDataModal;
@property (retain) NSArray *tableSectionTitles;
@property (nonatomic) BOOL beganUpdates;

@end

#pragma mark - Main

@implementation MUIViewControllerQueryBuilder

@synthesize cellBackgroundView = _cellBackgroundView;
@synthesize debug = _debug;
@synthesize fetchedResultsControllerTables = _fetchedResultsControllerTables, fetchedResultsControllerLinks = _fetchedResultsControllerLinks, fetchedResultsControllerGroups = _fetchedResultsControllerGroups, fetchedResultsControllerPredicates = _fetchedResultsControllerPredicates;
@synthesize queryBuilderDataModal = _queryBuilderDataModal;

@synthesize toolbar = _toolbar;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;

@synthesize beganUpdates = _beganUpdates, tableSectionTitles = _tableSectionTitles;

@synthesize tableViewQueryBuilder;

@synthesize uITableViewCellInstruction;
@synthesize uITableViewCellTableName;
@synthesize uITableViewCellQueryLink;
@synthesize uITableViewCellOverride;
@synthesize uITableViewCellQueryInput;
@synthesize navigationItemMain = _navigationItemMain;

@synthesize lastSelectedRowNumber = _lastSelectedRowNumber;

@synthesize boldSystemFont = _boldSystemFont;

- (void)dealloc {
    [_boldSystemFont release];
    [_cellBackgroundView release];
    [_queryBuilderDataModal release];
    [_fetchedResultsControllerTables release];
    [_fetchedResultsControllerLinks release];
    [_fetchedResultsControllerGroups release];
    [_fetchedResultsControllerPredicates release];
    [_tableSectionTitles release];
    [tableViewQueryBuilder release];
    [_toolbar release];
    [_navigationItemMain release];
    [super dealloc];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setBoldSystemFont:[[[UIFont boldSystemFontOfSize:([UIFont systemFontSize] + 3.0000f)] retain] autorelease]];
    
    UIView *bgView = [[UIView alloc] init];
    [self setCellBackgroundView: bgView];
    [bgView release];

    [[self tableViewQueryBuilder] setBackgroundColor: [UIColor paperGraphPaper]];
    [[self tableViewQueryBuilder] setOpaque: YES];
    
    QueryBuilderDataModal *qbdm = [[QueryBuilderDataModal alloc] initWithManagedDocumentQuery:[UIManagedDocumentQuery activeDocument]];
    [self setQueryBuilderDataModal:qbdm];
    [qbdm release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [[self tableViewQueryBuilder] reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController { }

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"showDatabasesDrivers"]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UITableViewControllerDataSourceTypes class]]) {
                    UITableViewControllerDataSourceTypes *tvc = (UITableViewControllerDataSourceTypes *)[[navControl topViewController] retain];
                    if (tvc) [tvc setDelegate:self];
                    [tvc release];
                }
            }
            
            [navControl release];
        }
        [[segue destinationViewController] setDelegate:self];
        
    } else if ([[segue identifier] isEqualToString: @"showAddTableViewController"]) {
        
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UIViewControllerSchemaAddTable class]]) {
                    
                    UIViewControllerSchemaAddTable *tvc = (UIViewControllerSchemaAddTable *)[navControl topViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                    }

                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqTable class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    
                    NSMutableArray *tableNames = [[NSMutableArray alloc] initWithArray: [RptqQueryTables namesForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]]];
                    if ([tableNames count]) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT name IN %@", tableNames];
                        [request setPredicate: predicate];
                    }
                    [tableNames release];
                    
                        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                              managedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]
                                                                                                sectionNameKeyPath: nil
                                                                                                         cacheName: nil];
                        [tvc setFetchedResultsController: frc];
                        [frc release];
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddLinkViewController"]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UITableViewControllerLinkBuilder class]]) {
                    
                    UITableViewControllerLinkBuilder *tvc = (UITableViewControllerLinkBuilder *)[navControl topViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                    }
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateViewController"]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            //NSLog(@"Top View Controller: %@", [navControl topViewController]);
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UITableViewControllerPredicateFormat class]]) {
                    UITableViewControllerPredicateFormat *tvc = (UITableViewControllerPredicateFormat *)[navControl topViewController];
                    if (tvc) {
                        //NSLog(@"Setting add predicate log");
                        [tvc setManagedDocumentQuery: [UIManagedDocumentQuery activeDocument]];
                        [tvc setAddPredicateDelegate: self];
                        [tvc setDelegate: self];
                        
                    }
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddGroupViewController"]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UITableViewControllerSchemaAddGroup class]]) {
                    UITableViewControllerSchemaAddGroup *tvc = (UITableViewControllerSchemaAddGroup *)[navControl topViewController];
                    if (tvc) {
                        [tvc setManagedDocumentQuery: [UIManagedDocumentQuery activeDocument]];
                        [tvc setDelegate:self];
                    }
                }
            }
            [navControl release];
        }
    } else if ([[segue identifier] isEqualToString:@"showLayoutSettings"]) {
                if ([[segue destinationViewController] isKindOfClass:[UITableViewControllerSectionLayoutSettings class]]) {
                    UITableViewControllerSectionLayoutSettings *tvc = (UITableViewControllerSectionLayoutSettings *)[segue destinationViewController];
                    if (tvc) {
                        [tvc setDelegate:self];
                        //NSLog(@"Last selected row: %d", [self lastSelectedRowNumber]);
                        RptqDocumentSection *section = [[RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                                              forManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
                        //NSLog(@"About to show section: %@", section);                        
                        //NSLog(@"Inital height: %@", [section height]);
                        //NSLog(@"Inital visibility: %@", [section visibility]);
                        [tvc setInitalStepperValue:([[section height] floatValue] * 2)];
                        [tvc setInitalSwitchValue:[[section visibility] boolValue]];
                        [section release];

                    }
                }
    } else if ([[segue identifier] isEqualToString:@"showReportLayout"]) {
        if ([[segue destinationViewController] isKindOfClass: [MUIViewControllerReportDesigner class]]) {
            [[segue destinationViewController] setDelegate: self];
            [[segue destinationViewController] setManagedDocumentQuery: [UIManagedDocumentQuery activeDocument]];
        }
    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromQuery"]) {
        [[segue destinationViewController] setDelegate: self];
        [[segue destinationViewController] setManagedDocumentQuery: [UIManagedDocumentQuery activeDocument]];
    }
}

#pragma mark - Toolbar Actions

#pragma mark Top Toolbar Actions

//Labeled as "Reports"
- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)edit:(id)sender {
    BOOL editing = ![tableViewQueryBuilder isEditing];
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

- (void)addTable:(id)sender {
    [self performSegueWithIdentifier: @"showAddTableViewController" sender: sender];
}

- (void)addLink:(id)sender {
    [self performSegueWithIdentifier: @"showAddLinkViewController" sender: sender];
}

- (void)showAddPredicateModalView:(id)sender {
    [self performSegueWithIdentifier: @"showAddPredicateViewController" sender: sender];
}

- (void)addGroup:(id)sender {
    [self performSegueWithIdentifier: @"showAddGroupViewController" sender: sender];
}

#pragma mark - Modal helper

- (UIViewControllerSchemaTablesSections)tableSectionTypeForIndexPathSection:(NSUInteger)sec {
    UIViewControllerSchemaTablesSections result = sec;
    NSArray *sectionTypes = [[[[self queryBuilderDataModal] datamodel] objectForKey: KEY_TBL_SEC_SECTIONS] retain];
    if ([sectionTypes count] >= sec) {
        result = [[sectionTypes objectAtIndex:sec] integerValue];
    }
    [sectionTypes release];
    return result;
}

- (NSUInteger)sectionPositionForTableSectionType:(UIViewControllerSchemaTablesSections)sec {
    NSInteger result = 0;
    NSArray *sectionTypes = [[[[self queryBuilderDataModal] datamodelForNumberOfTables:[[self tableViewQueryBuilder] numberOfRowsInSection: 1]] objectForKey: KEY_TBL_SEC_SECTIONS] retain];
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
    RptqDocumentSection *section = [[RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                          forManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    [section setHeight: [NSNumber numberWithFloat:height]];
    [section release];
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    RptqDocumentSection *section = [[RptqDocumentSection getDocumentSectionForRow: [self lastSelectedRowNumber]
                                                          forManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    [section setVisibility: [NSNumber numberWithBool:isVisible]];
    [section release];
    [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
    }];

}

#pragma mark - Delegates

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated: YES];
    } else {
        [self dismissModalViewControllerAnimated: YES];
    }
}

- (void)modalTableViewControllerDidFinish:(id)controller {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated: YES];
    } else {
        [self dismissModalViewControllerAnimated: YES];
    }
}

- (void)addPredicate:(RptqQueryPredicate *)predicate {
    [self dismissModalViewControllerAnimated: YES];
    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    if (doc) {
        NSLog(@"About to save it yo!  %@", [doc hasQuery]);
        [[doc hasQuery] addHasQueryPredicate:[NSSet setWithObject: predicate]];
        
        [[self tableViewQueryBuilder] reloadData];
        
        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
        }];
    }
    [doc release];
}

- (void)addPredicateWithLeft:(NSString *)leftField
                   comparson:(MNSPredicateOperator)comparsonOperator
               andRightValue:(NSString *)rightValue {
    [self dismissModalViewControllerAnimated: YES];

    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    if (doc) {
        
        NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
        RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
        [queryPredicate setFieldleftpred: leftField];
        [queryPredicate setComparson: [NSNumber numberWithInt: comparsonOperator]];
        [queryPredicate setFieldrightpred: rightValue];
        
        //NSLog(@"Here");
        [[doc hasQuery] addHasQueryPredicate:[NSSet setWithObject: queryPredicate]];
        
        [queryPredicate autorelease];
        
        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
            
            
            
            NSFetchRequest *predFetchRequest = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryPredicate class])];
            NSError *error = nil;
            //NSArray *predicates = [[[UIManagedDocumentQuery activeDocument] managedObjectContext] executeFetchRequest:predFetchRequest error:&error];
            //NSLog(@"Predicates %@", predicates);
            
            
            [[self tableViewQueryBuilder] reloadData];
        }];
    }
    [doc release];
}

- (void)addPredicateDidCancel:(UITableViewControllerPredicateFormat *)controller {
    [self dismissModalViewControllerAnimated: YES];
}

- (void)viewControllerSchemaAddLinkDidSelectFirstTableName:(NSString *)firstTable
                                            firstFieldName:(NSString *)firstFieldName
                                           secondTableName:(NSString *)secondTableName
                                           secondFieldName:(NSString *)secondFieldName
                                              withJoinType:(MNSLinkType)joinType {
    [self dismissModalViewControllerAnimated: YES];

    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    if (doc) {
        NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
        
        RptqQueryLinks *queryLinks = [[RptqQueryLinks alloc] initWithEntity: rqtEd
                                             insertIntoManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]];
        [queryLinks setTableleft: firstTable];
        [queryLinks setFieldleft: firstFieldName];
        [queryLinks setTableright: secondTableName];
        [queryLinks setFieldright: secondFieldName];
        [queryLinks setJointype: [MNSLinkTypeReuseIds objectAtIndex: joinType]];
        [queryLinks setJointypeenum: [NSNumber numberWithInteger: joinType]];
        [[doc hasQuery] addHasQueryLinks: [NSSet setWithObject: queryLinks]];
        [queryLinks release];
        
    
        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
        }];
    }
    [doc release];
}

- (void)viewControllerSchemaAddLinkDidFinish:(UIViewControllerSchemaAddLinkFirstTable *)controller {
    [self dismissModalViewControllerAnimated: YES];
}

- (void)viewControllerSchemaAddTableDidFinish:(UIViewControllerSchemaAddTable *)controller {
    [self dismissModalViewControllerAnimated: YES];
}

- (void)uITableViewControllerSchemaAddGroupDidFinish:(UITableViewControllerSchemaAddGroup *)controller {
    [self dismissModalViewControllerAnimated: YES];
}

- (void)uITableViewControllerSchemaAddPredicateDidFinish:(UITableViewControllerSchemaAddPredicate *)controller {
    [self dismissModalViewControllerAnimated: YES];
}

- (void)addGroupDidAddGroupWithField:(NSString *)field andSort:(MNSSortOrder)sortOrder {

    [self dismissModalViewControllerAnimated: YES];
    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

    [[self tableViewQueryBuilder] beginUpdates];

    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    if (doc) {
        NSManagedObjectContext *moc = [[UIManagedDocumentQuery activeDocument] managedObjectContext];
        NSEntityDescription *ed = [NSEntityDescription entityForName:NSStringFromClass([RptqQueryGroup class]) inManagedObjectContext:moc];
        
        NSEntityDescription *eds = [NSEntityDescription entityForName:NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext:moc];
        
        RptqQueryGroup *rqg = [[RptqQueryGroup alloc] initWithEntity:ed insertIntoManagedObjectContext:moc];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
        NSError *error = nil;
        NSInteger groupCount = [moc countForFetchRequest:request error:&error];
        groupCount = (error) ? 0 : groupCount;
        
        [rqg setField:field];
        [rqg setSort:[NSNumber numberWithInteger:sortOrder]];
        NSInteger weight = groupCount - 1;
        [rqg setWeight:[NSNumber numberWithInteger: weight]];
        
        NSUInteger secFirstTransaction = [self sectionPositionForTableSectionType:UIViewControllerSchemaTablesSectionsGroups];
        NSUInteger rowFirstTransaction = weight;
        
        RptqDocumentSection *dsHeader = [[RptqDocumentSection alloc] initWithEntity:eds insertIntoManagedObjectContext:moc];
        [dsHeader setType: [NSNumber numberWithInteger: MNSDocumentSectionTypeGroupHeader]];
        [rqg addHasSectionObject:dsHeader];
        [dsHeader release];

        NSUInteger secSecondTransaction = [self sectionPositionForTableSectionType:UIViewControllerSchemaTablesSectionsInstructions];
        NSUInteger rowSecondTransaction = groupCount + 1;
        
        RptqDocumentSection *dsFooter = [[RptqDocumentSection alloc] initWithEntity:eds insertIntoManagedObjectContext:moc];
        [dsFooter setType: [NSNumber numberWithInteger:MNSDocumentSectionTypeGroupFooter]];
        [rqg addHasSectionObject:dsFooter];
        [dsFooter release];

        NSUInteger rowThirdTransaction = groupCount + 3;
        
        [[doc hasQuery] addHasQueryGroupsObject: rqg];

        [rqg release];
        
        [[[UIManagedDocumentQuery activeDocument] managedObjectContext] save: &error];
        if (!error) {
            NSArray *indexPaths = [[NSArray alloc] initWithObjects:
                                   [NSIndexPath indexPathForRow: rowFirstTransaction inSection: secFirstTransaction],
                                   [NSIndexPath indexPathForRow: rowSecondTransaction inSection: secSecondTransaction],
                                   [NSIndexPath indexPathForRow: rowThirdTransaction inSection: secSecondTransaction],
                                   nil];
            
            [[self tableViewQueryBuilder] insertRowsAtIndexPaths: indexPaths
                                                withRowAnimation: UITableViewRowAnimationAutomatic];
            
            [indexPaths release];
        }

        [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];

        [[self tableViewQueryBuilder] endUpdates];

        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
        }];
        
    }
    [doc release];
}

- (void)viewControllerSchemaAddTableDidSelectTable:(RptqTable *)table {
    
    [self dismissModalViewControllerAnimated: YES];

    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];

    [[self tableViewQueryBuilder] beginUpdates];

    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
    if (doc) {
        NSDictionary *oldLayout = [[[self queryBuilderDataModal] datamodel] retain];
        NSArray *oldLayoutSectionTypes = [[oldLayout objectForKey:KEY_TBL_SEC_SECTIONS] retain];
        NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTables class]) inManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];

        RptqQueryTables *tab = [[RptqQueryTables alloc] initWithEntity:rqtEd insertIntoManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
        [tab setName: [table name]];
        [[doc hasQuery] addHasQueryTablesObject:tab];
        [tab release];
        
        NSDictionary *newLayout = [[[self queryBuilderDataModal] datamodel] retain];
        
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
                    [[self tableViewQueryBuilder] insertSections: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(startIndex, lengtho)]
                                                withRowAnimation: UITableViewRowAnimationAutomatic];
                }                    
            }
        }
        [[self tableViewQueryBuilder] endUpdates];
        [newLayoutSectionTypes release];
        [oldLayoutSectionTypes release];
        [oldLayout release];
        [newLayout release];
        
        //[self.fetchedResultsControllerTables performFetch:nil];
        [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
        
        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL]
                              forSaveOperation: UIDocumentSaveForOverwriting
                             completionHandler: ^(BOOL success) {
                             }];
    }
    [doc release];
}

#pragma mark - Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[[self queryBuilderDataModal] datamodel] objectForKey: KEY_TBL_SEC_HEADERS] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    UIViewControllerSchemaTablesSections ts = [self tableSectionTypeForIndexPathSection: section];
    
    NSDictionary *rowsDict = [[[[self queryBuilderDataModal] datamodel] objectForKey: KEY_TBL_SEC_ROW_COUNT] retain];
    NSInteger numberOfRows = 0;
    numberOfRows = [[rowsDict objectForKey:[NSNumber numberWithInt: ts]] intValue];
    if (numberOfRows < 0) {
        switch (ts) {
            case UIViewControllerSchemaTablesSectionsInstructions: {
                //The sections are report header, report footer, page header, page footer,
                //  body, group header, and group footer
                NSInteger numberOfGroups = [[[self.fetchedResultsControllerGroups sections] objectAtIndex: 0] numberOfObjects];
                numberOfRows = (2 * numberOfGroups) + 5;
                NSLog(@"Section Rows: %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsTables: {
                numberOfRows = [[[self.fetchedResultsControllerTables sections] objectAtIndex: 0] numberOfObjects];
                NSLog(@"Table Rows: %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsLinks: {
                numberOfRows = [[[self.fetchedResultsControllerLinks sections] objectAtIndex: 0] numberOfObjects];
                NSLog(@"Link Rows: %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsPredicate: {
                numberOfRows = [[[self.fetchedResultsControllerPredicates sections] objectAtIndex: 0] numberOfObjects];
                NSLog(@"Predicate Rows: %d", numberOfRows);
                break;
            }
            case UIViewControllerSchemaTablesSectionsGroups: {
                numberOfRows = [[[self.fetchedResultsControllerGroups sections] objectAtIndex: 0] numberOfObjects];
                NSLog(@"Group Rows: %d", numberOfRows);
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
        case UITableViewCellEditingStyleDelete: {
            switch (ts) {
                case UIViewControllerSchemaTablesSectionsTables: {
#warning Only allow table to be deleted if it's not linked or otherwise used in the query.
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext:YES];
                    [[self tableViewQueryBuilder] beginUpdates];
                    
                    NSInteger qtCtr = [RptqQueryTables countForManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
                    NSDictionary *oldLayout = [[[self queryBuilderDataModal] datamodelForNumberOfTables: (qtCtr)] retain];
                    
                    
                    RptqQueryTables *tablea = [[[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: [indexPath row] inSection: 0]] retain];
                    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
                    [[doc hasQuery] removeHasQueryTablesObject: tablea];
                    [[[UIManagedDocumentQuery activeDocument] managedObjectContext] deleteObject: tablea];
                    
                    
                    
                    NSError *error = nil;
                    [[[UIManagedDocumentQuery activeDocument] managedObjectContext] save: &error];
                    if (error) {
                        [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                        [[self tableViewQueryBuilder] endUpdates];
                        NSLog(@"Error: %@", error);
                    } else {
                        [[self tableViewQueryBuilder] deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL]
                                              forSaveOperation: UIDocumentSaveForOverwriting
                                             completionHandler: ^(BOOL success) {
                                                 
                                                 NSInteger qtCtr = [RptqQueryTables countForManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
                                                 NSDictionary *newLayout = [[[self queryBuilderDataModal] datamodelForNumberOfTables: (qtCtr)] retain];
                                                 
                                                 NSArray *oldLayoutSectionTypes = [[oldLayout objectForKey:KEY_TBL_SEC_SECTIONS] retain];
                                                 NSArray *newLayoutSectionTypes = [[newLayout objectForKey:KEY_TBL_SEC_SECTIONS] retain];
                                                 
                                                 if ([oldLayoutSectionTypes count] != [newLayoutSectionTypes count]) {
                                                     
                                                     if ([oldLayoutSectionTypes count] > [newLayoutSectionTypes count]) { //remove sections
                                                         
                                                         
                                                         
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
                                                             [[self tableViewQueryBuilder] deleteSections:[NSIndexSet indexSetWithIndexesInRange: NSMakeRange(startIndex, lengtho)]
                                                                                         withRowAnimation: UITableViewRowAnimationAutomatic];
                                                         }
                                                     }
                                                 }
                                                 
                                                 [newLayoutSectionTypes release];
                                                 [oldLayoutSectionTypes release];
                                                 [newLayout release];
                                                 
                                                 [[self tableViewQueryBuilder] endUpdates];
                                                 
                                                 [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                                             }];

                    }
                    [oldLayout release];
                    [doc release];
                    [tablea release];
                    
                    
                    
                    break;
                }
                case UIViewControllerSchemaTablesSectionsLinks: {
                    UITableViewCellQueryLink *tvcLink = (UITableViewCellQueryLink *)[[tableView cellForRowAtIndexPath:indexPath] retain];
                    if (tvcLink) {
                        NSManagedObjectID *objid = [[tvcLink tableID] retain];
                        [RptqQueryLinks deleteLinkWithID:objid fromObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]];
                        [objid release];
                        
                        [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
                        }];
                    }
                    [tvcLink release];
                    break;
                }
                case UIViewControllerSchemaTablesSectionsGroups: {
                    [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: YES];
                    [[self tableViewQueryBuilder] beginUpdates];
                    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentQuery activeDocument] managedObjectContext]] retain];
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
                    NSError *error = nil;
                    NSInteger result = [[[UIManagedDocumentQuery activeDocument] managedObjectContext] countForFetchRequest:request error:&error];
                    NSInteger ctrGroups = (error) ? 0 : result;

                    if (doc) {
                        RptqQuery *query = [[doc hasQuery] retain];
                        
                        NSSet *groups = [[query hasQueryGroups] retain];
                        NSInteger weightToRemove = [indexPath row];
                        RptqQueryGroup *groupToRemove = nil;
                        
                        for (RptqQueryGroup *group in groups) {
                            if ([[group weight] integerValue] > weightToRemove) {
                                [group setWeight:[NSNumber numberWithInteger:([[group weight] integerValue] - 1)]];
                            } else if ([[group weight] integerValue] == weightToRemove) {
                                groupToRemove = [group retain];
                            }
                        }
                                                
                        if (groupToRemove) {
                            NSSet *sectionsToRemove = [[groupToRemove hasSection] retain];
                            NSArray *sections = [[sectionsToRemove allObjects] retain];
                            if ([sections count] == 2) {
                                [[[UIManagedDocumentQuery activeDocument] managedObjectContext] deleteObject: [sections objectAtIndex: 0]];
                                [groupToRemove removeHasSectionObject: [sections objectAtIndex: 0]];
                                [[[UIManagedDocumentQuery activeDocument] managedObjectContext] deleteObject: [sections objectAtIndex: 1]];
                                [groupToRemove removeHasSectionObject: [sections objectAtIndex: 1]];
                            }
                            [sections release];
                            [sectionsToRemove release];
                            [[[UIManagedDocumentQuery activeDocument] managedObjectContext] deleteObject: groupToRemove];
                            [query removeHasQueryGroupsObject: groupToRemove];

                            NSError *error = nil;
                            [[[UIManagedDocumentQuery activeDocument] managedObjectContext] save: &error];
                            if (!error) {
                                
                                NSInteger section = [self sectionPositionForTableSectionType: UIViewControllerSchemaTablesSectionsInstructions];
                                NSInteger headerSectionRow = weightToRemove + 2;
                                NSInteger footerSectionRow = 5 + (ctrGroups * 2) - 1 - 2 - weightToRemove;
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
                            [groupToRemove release];
                        }
                        
                        [groups release];
                        
                        [query release];
                    }

                    [doc release];
                    
                    [[UIManagedDocumentQuery activeDocument] saveToURL: [[UIManagedDocumentQuery activeDocument] fileURL]
                                          forSaveOperation: UIDocumentSaveForOverwriting
                                         completionHandler: ^(BOOL success) {
                                             [[self tableViewQueryBuilder] endUpdates];
                                             [self setSuspendAutomaticTrackingOfChangesInManagedObjectContext: NO];
                                         }];
                    break;
                }
                default: {
                    break;
                }
            }
            break;
        }
        case UITableViewCellEditingStyleInsert: {
            break;
        }
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
        case UIViewControllerSchemaTablesSectionsInstructions: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellInstruction";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellInstruction" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellInstruction];
                [self setUITableViewCellInstruction:nil];
            }
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
        case UIViewControllerSchemaTablesSectionsDatasource: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellDataSource" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellTableName];
                [result setIndentationLevel: 1];
                [self setUITableViewCellTableName:nil];
            }
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqUserCredentals class])];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"database_driver_type" ascending:YES];
            request.sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
            NSError *error = nil;
            NSArray *connections = [[[[UIManagedDocumentQuery activeDocument] managedObjectContext] executeFetchRequest:request error:&error] retain];
            if (!error) {
                if ([connections count] >= 1) {
                    RptqUserCredentals *connection = [[connections objectAtIndex: 0] retain];
                    [[result textLabel] setText:[NSString stringWithFormat:@"◦ %@", [connection database_driver_type]]];
                    [[result textLabel] setFont:[self boldSystemFont]];
                    [[result detailTextLabel] setText:@""];
                    [connection release];
                }
            } else {
                //NSLog(@"ERROR: %@, %@", [error localizedDescription], [error userInfo]);
            }
            [[result textLabel] setBackgroundColor:[UIColor clearColor]];
            [[result detailTextLabel] setBackgroundColor:[UIColor clearColor]];

            [request release];
            [connections release];
            break;
        }
        case UIViewControllerSchemaTablesSectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            UITableViewCellTableName *resultR = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            if (!resultR) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellTableName" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                resultR = [self uITableViewCellTableName];
                [self setUITableViewCellTableName:nil];
            }

            RptqQueryTables *tablea = [[[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            [[resultR textLabel] setText: [NSString stringWithFormat:@"◦ %@", [tablea name]]];
            [[resultR textLabel] setFont: [self boldSystemFont]];
            
            [[resultR textLabel] setBackgroundColor:[UIColor clearColor]];
            [resultR setIndentationLevel: 1];
            [tablea release];
            result = resultR;
            break;
        }
        case UIViewControllerSchemaTablesSectionsLinks: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellQueryLink" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellQueryLink];
                [self setUITableViewCellQueryLink:nil];
            }
            RptqQueryLinks *links = [[[self fetchedResultsControllerLinks] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            
            [[(UITableViewCellQueryLink *)result labelTableLeft] setText:
             [NSString stringWithFormat:@"%@.%@", [links tableleft], [links fieldleft]]];
            [[(UITableViewCellQueryLink *)result labelTableRight] setText:
             [NSString stringWithFormat:@"%@.%@", [links tableright], [links fieldright]]];
            [[(UITableViewCellQueryLink *)result labelFieldLeft] setText: @""];
            [[(UITableViewCellQueryLink *)result labelFieldRight] setText: @""];
            [[(UITableViewCellQueryLink *)result labelJoinDesc] setText: [NSString stringWithFormat:@"%@ (%@)", [MNSLinkTypeSymbols objectAtIndex: [[links jointypeenum] integerValue]], [MNSLinkTypeNames objectAtIndex: [[links jointypeenum] integerValue]]]];
            [(UITableViewCellQueryLink *)result setTableID: [links objectID]];
            [links release];
            break;
        }
        case UIViewControllerSchemaTablesSectionsGroups: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellQueryGroup" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellQueryLink];
                [self setUITableViewCellQueryLink:nil];
            }
            RptqQueryGroup *group = [[[self fetchedResultsControllerGroups] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            
            [[(UITableViewCellQueryGroup *)result labelMain] setText: [group field]];
            NSString *sort;
            MNSSortOrder sortOrder = [[group sort] integerValue];
            switch (sortOrder) {
                case MNSSortOrderAccending:
                    sort = @"accending";
                    break;
                case MNSSortOrderDecending:
                    sort = @"decending";
                    break;
                default:
                    sort = @"";
                    break;
            }
            [[(UITableViewCellQueryGroup *)result labelDetail] setText: [sort lowercaseString]];
            [group release];
            break;
        }
        case UIViewControllerSchemaTablesSectionsPredicate: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryPredicate";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellQueryPredicate" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellQueryLink];
                [self setUITableViewCellQueryLink:nil];
            }
            RptqQueryPredicate *predicate = [[[self fetchedResultsControllerPredicates] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            
            [[(UITableViewCellQueryPredicate *)result labelMain] setText: [predicate fieldleftpred]];
            [[(UITableViewCellQueryPredicate *)result labelDetail] setText: [predicate fieldrightpred]];
            [predicate release];
            break;
        }
        case UIViewControllerSchemaTablesSectionsSql: {
            switch (row) {
                case 0: {
                    static NSString *MyIdentifierUITableViewCellOverride = @"UITableViewCellOverride";
                    result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellOverride];
                    if (!result) {
                        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellOverride" bundle:nil];
                        [resultCellNib instantiateWithOwner:self options:nil];
                        result = [self uITableViewCellOverride];
                        [self setUITableViewCellOverride:nil];
                    }
                    break;
                }
                default: {
                    static NSString *MyIdentifierUITableViewCellQueryInput = @"UITableViewCellQueryInput";
                    result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellQueryInput];
                    if (!result) {
                        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellQueryInput" bundle:nil];
                        [resultCellNib instantiateWithOwner:self options:nil];
                        result = [self uITableViewCellQueryInput];
                        [self setUITableViewCellQueryInput:nil];
                    }
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
    
    [[self cellBackgroundView] setFrame:[result bounds]];

    return result;
}

/*
 - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 NSString *result;
 switch (section) {
 case 0:
 result = @"";
 break;
 case 1:
 result = @"";
 break;
 default:
 result = @"";
 break;
 }
 return result;
 }
 */

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *result = nil;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ReportDesignerPhone" bundle:nil];
    
    section = [self tableSectionTypeForIndexPathSection: section];

    switch (section) {
        case UIViewControllerSchemaTablesSectionsInstructions: {
            result = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderLayout"] view];
            break;
        }
        case UIViewControllerSchemaTablesSectionsDatasource: {
            result = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderDatasource"] view];
            break;
        }
        case UIViewControllerSchemaTablesSectionsTables: {
            UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderTables"];
            for (id subview in [[vc view] subviews]) {
                if ([subview isKindOfClass: [UIButton class]]) {
                    UIButton *button = subview;
                    if (button) {
                        [button addTarget:self action:@selector(addTable:) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
            result = [vc view];
            break;
        }
        case UIViewControllerSchemaTablesSectionsLinks: {

            UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderLinks"];
            for (id subview in [[vc view] subviews]) {
                if ([subview isKindOfClass: [UIButton class]]) {
                    UIButton *button = subview;
                    if (button) {
                        [button addTarget:self action:@selector(addLink:) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
            result = [vc view];
            break;
        }

        case UIViewControllerSchemaTablesSectionsGroups: {
            
            UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderGroups"];
            for (id subview in [[vc view] subviews]) {
                if ([subview isKindOfClass: [UIButton class]]) {
                    UIButton *button = subview;
                    if (button) {
                        [button addTarget:self action:@selector(addGroup:) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
            result = [vc view];
            break;
        }

        case UIViewControllerSchemaTablesSectionsPredicate: {
            
            UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderPredicate"];
            for (id subview in [[vc view] subviews]) {
                if ([subview isKindOfClass: [UIButton class]]) {
                    UIButton *button = subview;
                    if (button) {
                        [button addTarget:self action:@selector(showAddPredicateModalView:) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
            result = [vc view];
            break;
        }

        
        case UIViewControllerSchemaTablesSectionsSql: {
            result = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderQuery"] view];
            break;
        }
        default: {
            break;
        }
    }
    
    [result setBackgroundColor: [UIColor edaTableHeaderBackground]];

    return result;
}


#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewControllerSchemaTablesSections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];
    if (section == UIViewControllerSchemaTablesSectionsInstructions) {
        [self setLastSelectedRowNumber: [indexPath row]];
        [self performSegueWithIdentifier:@"showLayoutSettings" sender:self];
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
    CGFloat result = UITABLEVIEWCELL_HEIGHT_DEFAULT;
    UIViewControllerSchemaTablesSections section = [self tableSectionTypeForIndexPathSection: [indexPath section]];
    if (section == UIViewControllerSchemaTablesSectionsSql) {
        result = [indexPath row] == 0 ? [UITableViewCellOverride defaultHeight] : [UITableViewCellQueryInput defaultHeight];
    } else {
        NSDictionary *tableMetaHeight = [[[self queryBuilderDataModal] datamodel] objectForKey:KEY_TBL_SEC_ROW_HEIGHT];
        if (tableMetaHeight) result = [[tableMetaHeight objectForKey: [NSNumber numberWithInt: section]] floatValue];
    }
    return result;
}


/*
 - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
 */

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
 */

/*
 
 - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */
/*
 - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 
 }
*/

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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableViewQueryBuilder beginUpdates];
        self.beganUpdates = YES;
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
                    [self.tableViewQueryBuilder insertSections: [NSIndexSet indexSetWithIndex:updateSection]
                                              withRowAnimation: UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [self.tableViewQueryBuilder deleteSections:
                     [NSIndexSet indexSetWithIndex:updateSection] withRowAnimation:UITableViewRowAnimationFade];
                    break;
            }
        }

    }
    
    [sections release];
}


- (void)controller: (NSFetchedResultsController *)controller
   didChangeObject: (id)anObject
	   atIndexPath: (NSIndexPath *)indexPath
	 forChangeType: (NSFetchedResultsChangeType)type
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
                        [self.tableViewQueryBuilder insertRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeDelete: {
                        [self.tableViewQueryBuilder deleteRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeUpdate: {
                        [self.tableViewQueryBuilder reloadRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        break;
                    }
                    case NSFetchedResultsChangeMove: {
                        [self.tableViewQueryBuilder deleteRowsAtIndexPaths: [NSArray arrayWithObject:path]
                                                          withRowAnimation: UITableViewRowAnimationFade];
                        [self.tableViewQueryBuilder insertRowsAtIndexPaths: [NSArray arrayWithObject:path]
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
    if (self.beganUpdates) [self.tableViewQueryBuilder endUpdates];
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
    [self.tableViewQueryBuilder reloadData];
}

- (void)setFetchedResultsControllerTables:(NSFetchedResultsController *)newfrc {
    NSFetchedResultsController *oldfrc = _fetchedResultsControllerTables;
    if (newfrc != oldfrc) {
        [_fetchedResultsControllerTables release];
        [newfrc retain];
        _fetchedResultsControllerTables = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            NSLog(@"Test %@", self.debug ? @"YES" : @"NO");
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetchTables];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableViewQueryBuilder reloadData];
        }
    }
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
    [self.tableViewQueryBuilder reloadData];
}

- (void)setFetchedResultsControllerLinks:(NSFetchedResultsController *)newfrc {
    NSFetchedResultsController *oldfrc = _fetchedResultsControllerLinks;
    if (newfrc != oldfrc) {
        [_fetchedResultsControllerLinks release];
        [newfrc retain];
        _fetchedResultsControllerLinks = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            NSLog(@"Test %@", self.debug ? @"YES" : @"NO");
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetchLinks];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableViewQueryBuilder reloadData];
        }
    }
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
    [self.tableViewQueryBuilder reloadData];
}

- (void)setFetchedResultsControllerGroups:(NSFetchedResultsController *)fetchedResultsControllerGroups {
    NSFetchedResultsController *oldfrc = _fetchedResultsControllerGroups;
    if (fetchedResultsControllerGroups != oldfrc) {
        [_fetchedResultsControllerGroups release];
        [fetchedResultsControllerGroups retain];
        _fetchedResultsControllerGroups = fetchedResultsControllerGroups;
        fetchedResultsControllerGroups.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = fetchedResultsControllerGroups.fetchRequest.entity.name;
        }
        if (fetchedResultsControllerGroups) {
            NSLog(@"Test %@", self.debug ? @"YES" : @"NO");
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetchGroups];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableViewQueryBuilder reloadData];
        }
    }
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
    [self.tableViewQueryBuilder reloadData];
}

- (void)setFetchedResultsControllerPredicates:(NSFetchedResultsController *)fetchedResultsControllerPredicates {
    NSFetchedResultsController *oldfrc = _fetchedResultsControllerPredicates;
    if (fetchedResultsControllerPredicates != oldfrc) {
        [_fetchedResultsControllerPredicates release];
        [fetchedResultsControllerPredicates retain];
        _fetchedResultsControllerPredicates = fetchedResultsControllerPredicates;
        fetchedResultsControllerPredicates.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = fetchedResultsControllerPredicates.fetchRequest.entity.name;
        }
        if (fetchedResultsControllerPredicates) {
            NSLog(@"Test %@", self.debug ? @"YES" : @"NO");
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetchPredicate];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableViewQueryBuilder reloadData];
        }
    }
}

@end