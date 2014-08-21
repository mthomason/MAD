//
//  UITableViewControllerChooseField.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderChooseFieldViewController.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "RptqFieldSelectorManager.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDatabaseSchemaField+Extras.h"

#pragma mark -
#pragma mark TableViewController


// Private TableViewController properties and methods.
@interface MTQueryBuilderChooseFieldViewController ()

@property (nonatomic, strong) NSMutableArray *sectionInfoArray;
@property (nonatomic, strong) NSIndexPath *pinchedIndexPath;
@property (nonatomic, strong) NSArray *dataTables;

@property (nonatomic, assign) NSInteger openSectionIndex;
@property (nonatomic, assign) CGFloat initialPinchHeight;

// Use the uniformRowHeight property if the pinch gesture should change all row heights simultaneously.
@property (nonatomic, assign) NSInteger uniformRowHeight;

@end

#define DEFAULT_ROW_HEIGHT 44
#define HEADER_HEIGHT 45

@implementation MTQueryBuilderChooseFieldViewController

@synthesize unwindViewController;

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return NO;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return self.unwindViewController ?
    self.unwindViewController :
    [super viewControllerForUnwindSegueAction: action
                           fromViewController: fromViewController
                                   withSender: sender];
}

#pragma mark Initialization and configuration

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer"] ||
        [[segue identifier] isEqualToString:@"MTSegueAggregateFieldSave"] ||
        [[segue identifier] isEqualToString:@"MTIdentifierSegueEditFieldExit"]) {
        
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [[self tableView] indexPathForCell: cell];
        RptqQueryField *queryField = [self queryFieldForIndexPath:indexPath];
        [self setQueryField:queryField];
    
    }
}

- (CGSize)preferredContentSize {
    return CGSizeMake(320, 480);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem] setLeftItemsSupplementBackButton:YES];
    [[self navigationItem] setHidesBackButton:NO];
    
    [[self tableView] setSectionHeaderHeight: HEADER_HEIGHT];

    _openSectionIndex = NSNotFound;
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    NSSet *queryTables = [query hasQueryTables];

    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"alias" ascending:YES];
    NSArray *queryTablesArray = [queryTables sortedArrayUsingDescriptors:@[namesAccending]];
    [self setDataTables:queryTablesArray];
    
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated]; 
	
	if (([self sectionInfoArray] == nil) || ([[self sectionInfoArray] count] != [self numberOfSectionsInTableView:[self tableView]])) {
		
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];
		
		for (RptqQueryTable *queryTable in [self dataTables]) {
			RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [[RptqDatabaseSchemaFieldSelectorManager alloc] initWithTable: queryTable];
			sectionInfo.open = NO;
			
            NSNumber *defaultRowHeight = @DEFAULT_ROW_HEIGHT;
			NSInteger countOfQuotations = [[[sectionInfo table] hasQueryFields] count];
			for (NSInteger i = 0; i < countOfQuotations; i++) {
				[sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
			}
			
			[infoArray addObject:sectionInfo];
		}
		
		[self setSectionInfoArray: infoArray];
	}
	
}

#pragma mark Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [[self dataTables] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [self sectionInfoArray][section];
	NSInteger numStoriesInSection = [[[sectionInfo table] hasQueryFields] count];
	
    return [sectionInfo open] ? numStoriesInSection : 0;
}


- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *CellIdentifier = @"UITableViewCellFieldWithType";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        
        UINib *quoteCellNib = [UINib nibWithNibName:@"UITableViewCellFieldWithType" bundle:nil];
        [quoteCellNib instantiateWithOwner:self options:nil];
        cell = [self fieldCells];
        [self setFieldCells: nil];
        
    }
    
    RptqDatabaseSchemaFieldSelectorManager *fieldSelectorManager = (RptqDatabaseSchemaFieldSelectorManager *)[self sectionInfoArray][[indexPath section]];
    NSSet *fields = [[fieldSelectorManager table] hasQueryFields];
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
    NSArray *fieldsArray = [fields sortedArrayUsingDescriptors:@[namesAccending]];

    RptqDatabaseSchemaField *field = [fieldsArray[[indexPath row]] databaseSchemaField];
    if (field) {
        [[cell textLabel] setText: [field name]];
        [[cell detailTextLabel] setText: [[field fieldTypeDisplay] lowercaseString]];
    }

    return cell;
}


- (UIView *)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [self sectionInfoArray][section];
    if (![sectionInfo headerView]) {
		NSString *name = [[sectionInfo table] alias];
        CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, [[self tableView] bounds].size.width, HEADER_HEIGHT);
        UIViewTableSectionHeaderDatabaseTable *vsht = [[UIViewTableSectionHeaderDatabaseTable alloc] initWithFrame: rect
                                                                                                             title: name
                                                                                                           section: section
                                                                                                          delegate: self];
        [sectionInfo setHeaderView: vsht];
    }
    return [sectionInfo headerView];
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [self sectionInfoArray][[indexPath section]];
    return [[sectionInfo objectInRowHeightsAtIndex:[indexPath row]] floatValue];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqQueryField *queryField = [self queryFieldForIndexPath:indexPath];
    if (queryField != nil) {
        if ([self delegate] != nil) {
            [[self delegate] tableViewControllerChooseFieldDidFinish:self withField: queryField];
        }
    }
}

- (RptqQueryField *)queryFieldForIndexPath:(NSIndexPath *)indexPath {
    RptqQueryField *queryField = nil;
    RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [self sectionInfoArray][[indexPath section]];
    if ([[[sectionInfo table] hasQueryFields] count] > [indexPath row]) {
        NSSet *fields = [[sectionInfo table] hasQueryFields];
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
        NSArray *fieldsArray = [fields sortedArrayUsingDescriptors:@[namesAccending]];
        queryField = fieldsArray[[indexPath row]];
        [self setQueryField:queryField];
    }
    return queryField;
}

#pragma mark Section header delegate

- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
	
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [self sectionInfoArray][sectionOpened];
	
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
		
		RptqDatabaseSchemaFieldSelectorManager *previousOpenSection = [self sectionInfoArray][previousOpenSectionIndex];
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
    
}


- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = [self sectionInfoArray][sectionClosed];
	
	[sectionInfo setOpen: NO];

    NSInteger countOfRowsToDelete = [[self tableView] numberOfRowsInSection:sectionClosed];
    
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [[self tableView] deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    }
    [self setOpenSectionIndex: NSNotFound];
}

@end
