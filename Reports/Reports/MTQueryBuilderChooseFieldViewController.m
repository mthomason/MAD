//
//  UITableViewControllerChooseField.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderChooseFieldViewController.h"
#import "AppDelegate.h"

#pragma mark -
#pragma mark TableViewController


// Private TableViewController properties and methods.
@interface MTQueryBuilderChooseFieldViewController ()

@property (retain) NSMutableArray* sectionInfoArray;
@property (retain) NSIndexPath* pinchedIndexPath;
@property (assign) NSInteger openSectionIndex;
@property (assign) CGFloat initialPinchHeight;

@property (retain) NSArray *dataTables;

// Use the uniformRowHeight property if the pinch gesture should change all row heights simultaneously.
@property (nonatomic, assign) NSInteger uniformRowHeight;

@end

#define DEFAULT_ROW_HEIGHT 44
#define HEADER_HEIGHT 45

@implementation MTQueryBuilderChooseFieldViewController

@synthesize dataTables=plays_,
            sectionInfoArray=sectionInfoArray_,
            fieldCells=newsCell_,
            pinchedIndexPath=pinchedIndexPath_,
            uniformRowHeight=rowHeight_,
            openSectionIndex=openSectionIndex_,
            initialPinchHeight=initialPinchHeight_;
@synthesize delegate = _delegate;
@synthesize excludeTables = _excludeTables;

- (void)dealloc {
    [_excludeTables release];
    [super dealloc];
}

#pragma mark Initialization and configuration

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[self tableView] setSectionHeaderHeight: HEADER_HEIGHT];

    rowHeight_ = DEFAULT_ROW_HEIGHT;
    openSectionIndex_ = NSNotFound;

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    NSSet *queryTables = [[query hasQueryTables] retain];

    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"alias" ascending:YES];
    NSArray *queryTablesArray = [[queryTables sortedArrayUsingDescriptors:@[namesAccending]] retain];
    [self setDataTables:queryTablesArray];
    [queryTablesArray release];
    [queryTables release];
    
/*
    //NSArray *rptqQueryTables = [RptqDatabaseSchemaTable namesForTablesInQueryForManagedObjectContext:managedObjectContext];
    //NSMutableArray *tableNames = [[NSMutableArray alloc] initWithArray: rptqQueryTables];

    // FIXME: Excluded tables are broken.
    //    [tableNames removeObjectsInArray:[self excludeTables]];

    if ([tableNames count] > 0) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name IN %@", tableNames];
        [request setPredicate: predicate];
        
        NSError *error = nil;
        NSArray *tablesResults = [[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext] executeFetchRequest:request error:&error];
        [self setDataTables: (!error ? tablesResults : [NSArray array]) ]; 

    } else {
        [self setDataTables:[NSArray array]];
    }
 
    [tableNames release];
*/
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated]; 
	
	if (([self sectionInfoArray] == nil) || ([[self sectionInfoArray] count] != [self numberOfSectionsInTableView:[self tableView]])) {
		
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];
		
		for (RptqQueryTable *queryTable in [self dataTables]) {
			RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[RptqDatabaseSchemaFieldSelectorManager alloc] initWithTable: queryTable];
			sectionInfo.open = NO;
			
            NSNumber *defaultRowHeight = [NSNumber numberWithInteger:DEFAULT_ROW_HEIGHT];
			NSInteger countOfQuotations = [[[sectionInfo table] hasQueryFields] count];
			for (NSInteger i = 0; i < countOfQuotations; i++) {
				[sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
			}
			
			[infoArray addObject:sectionInfo];
            [sectionInfo release];
		}
		
		[self setSectionInfoArray: infoArray];

        [infoArray release];
	}
	
}

#pragma mark Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [[self dataTables] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[self sectionInfoArray] objectAtIndex:section];
	NSInteger numStoriesInSection = [[[sectionInfo table] hasQueryFields] count];
	
    return [sectionInfo open] ? numStoriesInSection : 0;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *CellIdentifier = @"UITableViewCellFieldWithType";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        
        UINib *quoteCellNib = [UINib nibWithNibName:@"UITableViewCellFieldWithType" bundle:nil];
        [quoteCellNib instantiateWithOwner:self options:nil];
        cell = [self fieldCells];
        [self setFieldCells: nil];
        
    }
    
    RptqDatabaseSchemaFieldSelectorManager *fieldSelectorManager = (RptqDatabaseSchemaFieldSelectorManager *)[[self sectionInfoArray] objectAtIndex:[indexPath section]];
    NSSet *fields = [[fieldSelectorManager table] hasQueryFields];
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
    NSArray *fieldsArray = [fields sortedArrayUsingDescriptors:@[namesAccending]];

    RptqDatabaseSchemaField *field = [[fieldsArray objectAtIndex:[indexPath row]] databaseSchemaField];
    if (field) {
        [[cell textLabel] setText: [field name]];
        [[cell detailTextLabel] setText: [[field fieldTypeDisplay] lowercaseString]];
    }
    
    return cell;
}


- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[self sectionInfoArray] objectAtIndex:section];
    if (![sectionInfo headerView]) {
		NSString *name = [[sectionInfo table] alias];
        CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, [[self tableView] bounds].size.width, HEADER_HEIGHT);
        UIViewTableSectionHeaderDatabaseTable *vsht = [[UIViewTableSectionHeaderDatabaseTable alloc] initWithFrame: rect
                                                                                                             title: name
                                                                                                           section: section
                                                                                                          delegate: self];
        [sectionInfo setHeaderView: vsht];
        [vsht release];
    }
    return [sectionInfo headerView];
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[self sectionInfoArray] objectAtIndex:[indexPath section]];
    return [[sectionInfo objectInRowHeightsAtIndex:[indexPath row]] floatValue];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[self sectionInfoArray] objectAtIndex:[indexPath section]];
    if ([[[sectionInfo table] hasQueryFields] count] > [indexPath row]) {
        NSSet *fields = [[sectionInfo table] hasQueryFields];
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
        NSArray *fieldsArray = [fields sortedArrayUsingDescriptors:@[namesAccending]];
        RptqQueryField *queryField = [fieldsArray objectAtIndex: [indexPath row]];
        [[self delegate] tableViewControllerChooseFieldDidFinish:self withField: queryField];
    }
}


#pragma mark Section header delegate

- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
	
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[self sectionInfoArray] objectAtIndex:sectionOpened];
	
	[sectionInfo setOpen: YES];
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSInteger countOfRowsToInsert = [[sectionInfo fields] count];
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < countOfRowsToInsert; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];

    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
		
		RptqDatabaseSchemaFieldSelectorManager *previousOpenSection = [[self sectionInfoArray] objectAtIndex:previousOpenSectionIndex];
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        NSInteger countOfRowsToDelete = [previousOpenSection.fields count];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }
    
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    }
    else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
    
    // Apply the updates.
    [[self tableView] beginUpdates];
    [[self tableView] insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [[self tableView] deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [[self tableView] endUpdates];
    [self setOpenSectionIndex: sectionOpened];
    
    [indexPathsToDelete release];
    [indexPathsToInsert release];
    
}


- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[self sectionInfoArray] objectAtIndex:sectionClosed];
	
	[sectionInfo setOpen: NO];

    NSInteger countOfRowsToDelete = [self.tableView numberOfRowsInSection:sectionClosed];
    
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [[self tableView] deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
        [indexPathsToDelete release];
    }
    [self setOpenSectionIndex: NSNotFound];
}

@end