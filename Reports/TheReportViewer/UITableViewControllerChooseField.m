//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerChooseField.h"
#import "RptqFieldSelectorManager.h"
#import "UIViewTableSectionHeaderDatabaseTable.h"

#import "RptqTable.h"
#import "RptqQueryTables.h"
#import "RptqQueryTables+Extras.h"

#pragma mark -
#pragma mark TableViewController


// Private TableViewController properties and methods.
@interface UITableViewControllerChooseField ()

@property (retain) NSMutableArray* sectionInfoArray;
@property (retain) NSIndexPath* pinchedIndexPath;
@property (assign) NSInteger openSectionIndex;
@property (assign) CGFloat initialPinchHeight;

@property (retain) NSArray* dataTables;

// Use the uniformRowHeight property if the pinch gesture should change all row heights simultaneously.
@property (nonatomic, assign) NSInteger uniformRowHeight;

-(void)updateForPinchScale:(CGFloat)scale atIndexPath:(NSIndexPath*)indexPath;

-(void)emailMenuButtonPressed:(UIMenuController*)menuController;
-(void)sendEmailForEntryAtIndexPath:(NSIndexPath*)indexPath;

@end

#define DEFAULT_ROW_HEIGHT 44
#define HEADER_HEIGHT 45

@implementation UITableViewControllerChooseField

@synthesize dataTables=plays_, sectionInfoArray=sectionInfoArray_, fieldCells=newsCell_, pinchedIndexPath=pinchedIndexPath_, uniformRowHeight=rowHeight_, openSectionIndex=openSectionIndex_, initialPinchHeight=initialPinchHeight_;

@synthesize delegate = _delegate;

@synthesize managedDocumentQuery = _managedDocumentQuery;
@synthesize excludeTables = _excludeTables;

- (void)dealloc {
    if (_managedDocumentQuery) [_managedDocumentQuery release];
    [_excludeTables release];
    [super dealloc];
}

#pragma mark Initialization and configuration

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up default values.
    self.tableView.sectionHeaderHeight = HEADER_HEIGHT;
    rowHeight_ = DEFAULT_ROW_HEIGHT;
    openSectionIndex_ = NSNotFound;

    NSMutableArray *tableNames = [[NSMutableArray alloc] initWithArray: [RptqQueryTables namesForManagedObjectContext: [[self managedDocumentQuery] managedObjectContext]]];
    [tableNames removeObjectsInArray:[self excludeTables]];


    if ([tableNames count] > 0) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqTable class])];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name IN %@", tableNames];
        [request setPredicate: predicate];
        
        NSError *error = nil;
        NSArray *tablesResults = [[[self managedDocumentQuery] managedObjectContext] executeFetchRequest:request error:&error];
        [self setDataTables: (!error ? tablesResults : [NSArray array]) ]; 

    } else {
        [self setDataTables:[NSArray array]];
    }
        
    [tableNames release];

}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated]; 
	
	if (([self sectionInfoArray] == nil) || ([[self sectionInfoArray] count] != [self numberOfSectionsInTableView:[self tableView]])) {
		
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];
		
		for (RptqTable *table in self.dataTables) {
			
			RptqFieldSelectorManager *sectionInfo = [[RptqFieldSelectorManager alloc] initWithTable: table];			
			sectionInfo.table = table;
			sectionInfo.open = NO;
			
            NSNumber *defaultRowHeight = [NSNumber numberWithInteger:DEFAULT_ROW_HEIGHT];
			NSInteger countOfQuotations = [[sectionInfo.table hasFields] count];
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
    return [self.dataTables count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    
	RptqFieldSelectorManager *sectionInfo = [self.sectionInfoArray objectAtIndex:section];
	NSInteger numStoriesInSection = [[sectionInfo.table hasFields] count];
	
    return sectionInfo.open ? numStoriesInSection : 0;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *CellIdentifier = @"UITableViewCellFieldWithType";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        
        UINib *quoteCellNib = [UINib nibWithNibName:@"UITableViewCellFieldWithType" bundle:nil];
        [quoteCellNib instantiateWithOwner:self options:nil];
        cell = self.fieldCells;
        self.fieldCells = nil;
        
    }
    
    RptqFieldSelectorManager *table = (RptqFieldSelectorManager *)[self.sectionInfoArray objectAtIndex:indexPath.section];
    RptqField *field = [[table fields] objectAtIndex:indexPath.row];
    if (field) {
        [[cell textLabel] setText: [field name]];
        [[cell detailTextLabel] setText: [[field datatype] lowercaseString]];
    }
    
    return cell;
}


- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	RptqFieldSelectorManager *sectionInfo = [self.sectionInfoArray objectAtIndex:section];
    if (!sectionInfo.headerView) {
		NSString *playName = sectionInfo.table.name;
        UIViewTableSectionHeaderDatabaseTable *vsht = [[UIViewTableSectionHeaderDatabaseTable alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, HEADER_HEIGHT) title:playName section:section delegate:self];
        [sectionInfo setHeaderView: vsht];
        [vsht release];
    }
    return sectionInfo.headerView;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
	RptqFieldSelectorManager *sectionInfo = [self.sectionInfoArray objectAtIndex:indexPath.section];
    return [[sectionInfo objectInRowHeightsAtIndex:indexPath.row] floatValue];
    // Alternatively, return rowHeight.
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqFieldSelectorManager *sectionInfo = [self.sectionInfoArray objectAtIndex:[indexPath section]];
    if ([[sectionInfo fields] count] > [indexPath row]) {
        RptqField *field = [[sectionInfo fields] objectAtIndex: [indexPath row]];
        [[self delegate] tableViewControllerChooseFieldDidFinish:self withField: field];
    }
}


#pragma mark Section header delegate

- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
	
	RptqFieldSelectorManager *sectionInfo = [self.sectionInfoArray objectAtIndex:sectionOpened];
	
	sectionInfo.open = YES;
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSInteger countOfRowsToInsert = [sectionInfo.fields count];
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
		
		RptqFieldSelectorManager *previousOpenSection = [self.sectionInfoArray objectAtIndex:previousOpenSectionIndex];
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
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    self.openSectionIndex = sectionOpened;
    
    [indexPathsToDelete release];
    [indexPathsToInsert release];
    
}


- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
	RptqFieldSelectorManager *sectionInfo = [self.sectionInfoArray objectAtIndex:sectionClosed];
	
    sectionInfo.open = NO;
    NSInteger countOfRowsToDelete = [self.tableView numberOfRowsInSection:sectionClosed];
    
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
        [indexPathsToDelete release];
    }
    self.openSectionIndex = NSNotFound;
}

@end