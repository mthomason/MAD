//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSchemaTables.h"
#import "UIViewControllerSchemaAddTable.h"
#import "UIViewControllerSchemaAddLinkFirstTable.h"
#import "UITableViewControllerSchemaAddGroup.h"
#import "Constants.h"
#import "RptqDocument.h"
#import "RptqTable.h"
#import "RptqQueryTables.h"
#import "RptqQueryLinks.h"
#import "RptqQueryGroup.h"
#import "RptqQueryPredicate.h"
#import "RptqUserCredentals.h"
#import "RptqQuery.h"

typedef enum {
	UIViewControllerSchemaTablesSectionsInstructions = 0,
    UIViewControllerSchemaTablesSectionsDatasource = 1,
	UIViewControllerSchemaTablesSectionsTables = 2,
	UIViewControllerSchemaTablesSectionsLinks = 3,
	UIViewControllerSchemaTablesSectionsGroups = 4,
	UIViewControllerSchemaTablesSectionsPredicate = 5,
    UIViewControllerSchemaTablesSectionsSql = 6
} UIViewControllerSchemaTablesSections;

#pragma mark - Private Category

@interface UIViewControllerSchemaTables()

@property (nonatomic) BOOL beganUpdates;

@property (retain) NSArray *tableSectionTitles;

@end

#pragma mark - Main

@implementation UIViewControllerSchemaTables

@synthesize debug = _debug;
@synthesize fetchedResultsControllerTables = _fetchedResultsControllerTables, fetchedResultsControllerLinks = _fetchedResultsControllerLinks, fetchedResultsControllerGroups = _fetchedResultsControllerGroups, fetchedResultsControllerPredicates = _fetchedResultsControllerPredicates;

@synthesize toolbar = _toolbar;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;

@synthesize beganUpdates = _beganUpdates, tableSectionTitles = _tableSectionTitles;

@synthesize tableMetaData = _tableMetaData;

@synthesize delegate = _delegate;
@synthesize tableViewQueryBuilder;

@synthesize uITableViewCellInstruction;
@synthesize uITableViewCellTableName;
@synthesize uITableViewCellQueryLink;
@synthesize uITableViewCellOverride;
@synthesize uITableViewCellQueryInput;

@synthesize managedDocumentQuery = _managedDocumentQuery;

- (void)dealloc {
    [_fetchedResultsControllerTables release];
    [_fetchedResultsControllerLinks release];
    [_fetchedResultsControllerGroups release];
    [_fetchedResultsControllerPredicates release];
    [_managedDocumentQuery release];
    [_tableSectionTitles release];
    [_tableMetaData release];
    [tableViewQueryBuilder release];
    [_toolbar release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

        //These files define common attributes of the mostly static table.
        NSArray *sections = [[NSArray alloc] initWithObjects:
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsInstructions],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsDatasource],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsTables],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsLinks],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsGroups],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsPredicate],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsSql], nil];
        
        NSArray *countRowsForSection = [[NSArray alloc] initWithObjects:
                                        [NSNumber numberWithInt: 1],
                                        [NSNumber numberWithInt: 1],
                                        [NSNumber numberWithInt: -1],
                                        [NSNumber numberWithInt: -1],
                                        [NSNumber numberWithInt: -1],
                                        [NSNumber numberWithInt: -1],
                                        [NSNumber numberWithInt: 2],
                                        nil];
        NSDictionary *countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                                    forKeys: sections];
        [countRowsForSection release];
        
        NSString *h1 = NSLocalizedString(@"Overview", @"Overview");
        NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
        NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
        NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
        NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
        NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
        NSString *h7 = NSLocalizedString(@"Override the SQL", @"Override the SQL");
        
        NSArray *headersSection = [[NSArray alloc] initWithObjects:
                                   h1,
                                   [NSString stringWithFormat:@"Step %d: %@", 1, h2],
                                   [NSString stringWithFormat:@"Step %d: %@", 1, h3],
                                   [NSString stringWithFormat:@"Step %d: %@", 1, h4],
                                   [NSString stringWithFormat:@"Step %d: %@", 1, h5],
                                   [NSString stringWithFormat:@"Step %d: %@", 1, h6],
                                   [NSString stringWithFormat:@"Step %d: %@", 1, h7],                                   
                                   nil];
        NSDictionary *headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                               forKeys: sections];
        [headersSection release];
        
        NSArray *heightRowsForSection = [[NSArray alloc] initWithObjects:
                                         [NSNumber numberWithFloat: [UITableViewCellInstruction defaultHeight]],
                                         [NSNumber numberWithFloat: 44.0000f],
                                         [NSNumber numberWithFloat: [UITableViewCellTableName defaultHeight]],
                                         [NSNumber numberWithFloat: [UITableViewCellQueryLink defaultHeight]],
                                         [NSNumber numberWithFloat: 44.0000f],
                                         [NSNumber numberWithFloat: 44.0000f],
                                         [NSNumber numberWithFloat: [UITableViewCellQueryInput defaultHeight]], nil];
        NSDictionary *heightRowsForSectionDictionaryDictionary = [[NSDictionary alloc] initWithObjects: heightRowsForSection
                                                                                               forKeys: sections];
        [heightRowsForSection release];
        
        NSDictionary *tableOutline = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      headersSectionDictionary, KEY_TBL_SEC_HEADERS,
                                      countRowsForSectionDictionary, KEY_TBL_SEC_ROW_COUNT,
                                      heightRowsForSectionDictionaryDictionary, KEY_TBL_SEC_ROW_HEIGHT, nil];
        
        
        [self setTableMetaData: tableOutline];
        
        [tableOutline release];
        [heightRowsForSectionDictionaryDictionary release];
        [headersSectionDictionary release];
        [countRowsForSectionDictionary release];
        [sections release];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [self setTableViewQueryBuilder:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    //[[self tableViewQueryBuilder] setBackgroundView:nil];
    //[[self tableViewQueryBuilder] setBackgroundColor:[UIColor  clearColor]];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [[self tableViewQueryBuilder] reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDatabasesDrivers"]) {
        //Set UITableViewControllerDataSourceTypes delegate
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
                        [tvc setManagedDocumentQuery: [self managedDocumentQuery]];
                        [tvc setDelegate:self];
                    }
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqTable class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSError *error = nil;
                    NSArray *tablesResults = [[[self managedDocumentQuery] managedObjectContext] executeFetchRequest:request error:&error];
                    if (!error) {
                        NSLog(@"TableResults %@", tablesResults);
                        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                              managedObjectContext: [[self managedDocumentQuery] managedObjectContext]
                                                                                                sectionNameKeyPath: nil
                                                                                                         cacheName: nil];
                        [tvc setFetchedResultsController: frc];
                        [frc release];
                    } else {
                        NSLog(@"ERROR: %@, %@", [error localizedDescription], [error localizedFailureReason]);
                    }
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
                    [tvc setManagedDocumentQuery: [self managedDocumentQuery]];
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
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UITableViewControllerSchemaAddPredicate class]]) {
                    UITableViewControllerSchemaAddPredicate *tvc = (UITableViewControllerSchemaAddPredicate *)[navControl topViewController];
                    if (tvc) {
                        [tvc setManagedDocumentQuery: [self managedDocumentQuery]];
                        [tvc setDelegate:self];
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
                    if (tvc) [tvc setDelegate:self];
                }
            }
            [navControl release];
        }

    
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] uIViewControllerSchemaTablesDelegateDidFinish: self];
}

- (void)addTable:(id)sender {
    [self performSegueWithIdentifier: @"showAddTableViewController" sender: sender];
}

- (void)addLink:(id)sender {
    [self performSegueWithIdentifier: @"showAddLinkViewController" sender: sender];
}

- (void)addPredicate:(id)sender {
    [self performSegueWithIdentifier: @"showAddPredicateViewController" sender: sender];
}

- (void)addGroup:(id)sender {
    [self performSegueWithIdentifier: @"showAddGroupViewController" sender: sender];
}

- (IBAction)edit:(id)sender {
    BOOL editing = ![tableViewQueryBuilder isEditing];
    UIBarButtonSystemItem buttonType = editing ? UIBarButtonSystemItemDone: UIBarButtonSystemItemEdit;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                   target: self
                                                                                   action: @selector(edit:)];
    NSMutableArray *tbItems = [[NSMutableArray alloc] initWithArray:[[self toolbar] items]];
    [tbItems replaceObjectAtIndex:([tbItems count] - 1) withObject: barButtonItem];
    [[self toolbar] setItems: tbItems];
    [tbItems release];
    [[self tableViewQueryBuilder] setEditing: editing];
    [barButtonItem release];
}

#pragma mark - Model Delegates

#pragma mark - Delegates

- (void)uITableViewControllerDataSourceTypesDidFinish:(UITableViewControllerDataSourceTypes *)controller {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated: YES];
    } else {
        [self dismissModalViewControllerAnimated: YES];
        //[[self tableViewControllerDataSourceTypes] dismissPopoverAnimated:YES];
        //[self setTableViewControllerDataSourceTypes: nil];
    }
}

- (void)viewControllerSchemaAddLinkDidSelectFirstTableName:(NSString *)firstTable
                                            firstFieldName:(NSString *)firstFieldName
                                           secondTableName:(NSString *)secondTableName
                                           secondFieldName:(NSString *)secondFieldName
                                              withJoinType:(MNSLinkType)joinType {
    [self dismissModalViewControllerAnimated: YES];

    if ([self managedDocumentQuery]) {
        
        NSFetchRequest *docFetchRequest = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
        NSError *error = nil;
        NSArray *documents = [[[self managedDocumentQuery] managedObjectContext] executeFetchRequest:docFetchRequest error:&error];
        if ([documents count] > 0) {
            RptqDocument *doc = [documents objectAtIndex: 0];
            if (doc) {
                NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:[[self managedDocumentQuery] managedObjectContext]];
                
                RptqQueryLinks *queryLinks = [[RptqQueryLinks alloc] initWithEntity:rqtEd insertIntoManagedObjectContext:[[self managedDocumentQuery] managedObjectContext]];
                [queryLinks setTableleft: firstTable];
                [queryLinks setFieldleft: firstFieldName];
                [queryLinks setTableright: secondTableName];
                [queryLinks setFieldright: secondFieldName];
                [queryLinks setJointype: [MNSLinkTypeReuseIds objectAtIndex: joinType]];
                
                [[doc hasQuery] addHasQueryLinks:[NSSet setWithObject: queryLinks]];
                [queryLinks release];
                
                [[self tableViewQueryBuilder] reloadData];
                
                [[self managedDocumentQuery] saveToURL: [[self managedDocumentQuery] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
                }];
            } else {
                NSLog(@"Doc is nil");
            }
        }
    }

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

- (void)viewControllerSchemaAddTableDidSelectTable:(RptqTable *)table {
    [self dismissModalViewControllerAnimated: YES];

    if ([self managedDocumentQuery]) {
        
        NSFetchRequest *docFetchRequest = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
        NSError *error = nil;
        NSArray *documents = [[[self managedDocumentQuery] managedObjectContext] executeFetchRequest:docFetchRequest error:&error];
        if ([documents count] > 0) {
            RptqDocument *doc = [documents objectAtIndex: 0];
            if (doc) {
                NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTables class]) inManagedObjectContext:[[self managedDocumentQuery] managedObjectContext]];
                RptqQueryTables *tab = [[RptqQueryTables alloc] initWithEntity:rqtEd insertIntoManagedObjectContext:[[self managedDocumentQuery] managedObjectContext]];
                [tab setName: [table name]];
                [[doc hasQuery] addHasQueryTablesObject:tab];
                NSLog(@"Added query table name %@", [tab name]);
                [tab release];

                [[self tableViewQueryBuilder] reloadData];
                
                NSLog(@"[[self managedDocumentQuery] fileURL]: %@", [[self managedDocumentQuery] fileURL]);
                [[self managedDocumentQuery] saveToURL: [[self managedDocumentQuery] fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
                    if (!success) {
                        NSLog(@"FAIL");
                    } else {
                        NSLog(@"SAVE");
                    }
                }];
            } else {
                NSLog(@"Doc is nil");
            }
        }
    }

}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[self tableMetaData] objectForKey: KEY_TBL_SEC_HEADERS] count];
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 
 }
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([indexPath section] == UIViewControllerSchemaTablesSectionsTables || [indexPath section] == UIViewControllerSchemaTablesSectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([indexPath section] == UIViewControllerSchemaTablesSectionsGroups) ? YES : NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    
    UITableViewCell *result = nil;
    
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
            break;
        }
        case UIViewControllerSchemaTablesSectionsDatasource: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellDataSource" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellTableName];
                [self setUITableViewCellTableName:nil];
            }
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqUserCredentals class])];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"database_driver_type" ascending:YES];
            request.sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
            NSError *error = nil;
            NSArray *connections = [[[[self managedDocumentQuery] managedObjectContext] executeFetchRequest:request error:&error] retain];
            if (!error) {
                if ([connections count] >= 1) {
                    RptqUserCredentals *connection = [[connections objectAtIndex: 0] retain];
                    [[result textLabel] setText:[connection database_driver_type]];
                    [[result detailTextLabel] setText:@""];
                    [connection release];
                }
            } else {
                NSLog(@"ERROR: %@, %@", [error localizedDescription], [error userInfo]);
            }
            [request release];
            [connections release];
            break;
        }
        case UIViewControllerSchemaTablesSectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellTableName" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellTableName];
                [self setUITableViewCellTableName:nil];
            }
            RptqQueryTables *tablea = [[[self fetchedResultsControllerTables] objectAtIndexPath: [NSIndexPath indexPathForRow: row inSection: 0]] retain];
            [[result textLabel] setText: [tablea name]];
            [tablea release];
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
            
            [[(UITableViewCellQueryLink *)result labelTableLeft] setText: [links tableleft]];
            [[(UITableViewCellQueryLink *)result labelTableRight] setText: [links tableright]];
            [[(UITableViewCellQueryLink *)result labelFieldLeft] setText: [links fieldleft]];
            [[(UITableViewCellQueryLink *)result labelFieldRight] setText: [links fieldright]];
            [[(UITableViewCellQueryLink *)result labelJoinDesc] setText: [links jointype]];
            //[[(UITableViewCellQueryLink *)result labelTableLeft] setText: [links tableleft]];
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
            [[(UITableViewCellQueryGroup *)result labelDetail] setText: [NSString stringWithFormat:@"Sort %d",[group sort]]];
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
            
            [[(UITableViewCellQueryPredicate *)result labelMain] setText: [predicate fieldleft]];
            [[(UITableViewCellQueryPredicate *)result labelDetail] setText: [predicate fieldright]];
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
    
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSDictionary *rowsDict = [[self tableMetaData] objectForKey: KEY_TBL_SEC_ROW_COUNT];
    NSInteger numberOfRows = 0;
    [rowsDict objectForKey: [NSNumber numberWithInt: section]];
    numberOfRows = [[rowsDict objectForKey:[NSNumber numberWithInt: section]] intValue];
    if (numberOfRows < 0) {
        switch (section) {
            case UIViewControllerSchemaTablesSectionsTables: {
                numberOfRows = [[[self.fetchedResultsControllerTables sections] objectAtIndex: 0] numberOfObjects];
                break;
            }
            case UIViewControllerSchemaTablesSectionsLinks: {
                numberOfRows = [[[self.fetchedResultsControllerLinks sections] objectAtIndex: 0] numberOfObjects];
                break;
            }
            default:
                numberOfRows = 0;
                break;
        }
    }
	return numberOfRows;
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
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    
    switch (section) {
        case UIViewControllerSchemaTablesSectionsInstructions: {
            result = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderBuildQuery"] view];
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
                        [button addTarget:self action:@selector(addPredicate:) forControlEvents:UIControlEventTouchUpInside];
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

    return result;
}


#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 29.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = UITABLEVIEWCELL_HEIGHT_DEFAULT;
    NSInteger section = [indexPath section];
    if (section == UIViewControllerSchemaTablesSectionsSql) {
        result = [indexPath row] == 0 ? [UITableViewCellOverride defaultHeight] : [UITableViewCellQueryInput defaultHeight];
    } else {
        NSDictionary *tableMetaHeight = [[self tableMetaData] objectForKey:KEY_TBL_SEC_ROW_HEIGHT];
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

/*
 - (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


/*
 - (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

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

- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex
	 forChangeType: (NSFetchedResultsChangeType)type {

    NSUInteger newSectionIndex = sectionIndex;
    newSectionIndex++;
    newSectionIndex++;
    if (![controller isEqual:[self fetchedResultsControllerTables]]) {
        newSectionIndex++;
    }
    
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [self.tableViewQueryBuilder insertSections:[NSIndexSet indexSetWithIndex:newSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableViewQueryBuilder deleteSections:[NSIndexSet indexSetWithIndex:newSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}


- (void)controller: (NSFetchedResultsController *)controller
   didChangeObject: (id)anObject
	   atIndexPath: (NSIndexPath *)indexPath
	 forChangeType: (NSFetchedResultsChangeType)type
	  newIndexPath: (NSIndexPath *)newIndexPath {
    
    NSIndexPath *adjustedIndexPath;
    NSIndexPath *adjustedNewIndexPath;
    
    if ([controller isEqual:[self fetchedResultsControllerTables]]) {
        adjustedIndexPath = [NSIndexPath indexPathForRow: [indexPath row] inSection:[indexPath section] + 2];
        adjustedNewIndexPath = [NSIndexPath indexPathForRow: [newIndexPath row] inSection:[newIndexPath section] + 2];
    } else {
        adjustedIndexPath = [NSIndexPath indexPathForRow: [indexPath row] inSection:[indexPath section] + 3];
        adjustedNewIndexPath = [NSIndexPath indexPathForRow: [newIndexPath row] inSection:[newIndexPath section] + 3];
    }
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [self.tableViewQueryBuilder insertRowsAtIndexPaths:[NSArray arrayWithObject:adjustedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableViewQueryBuilder deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjustedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self.tableViewQueryBuilder reloadRowsAtIndexPaths:[NSArray arrayWithObject:adjustedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeMove:
                [self.tableViewQueryBuilder deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjustedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableViewQueryBuilder insertRowsAtIndexPaths:[NSArray arrayWithObject:adjustedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
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

@end