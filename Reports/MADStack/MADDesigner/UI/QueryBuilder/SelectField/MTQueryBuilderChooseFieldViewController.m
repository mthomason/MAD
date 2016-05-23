//
//  MTQueryBuilderChooseFieldViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderChooseFieldViewController.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITableView.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MAD/RptqFieldSelectorManager.h>

#import <MAD/RptqQueryTable.h>

#import <MAD/RptqDocument.h>

#import <MAD/RptqDatabase.h>

#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryField.h>

#import <MAD/MADocument.h>

#import "MADNavigationBarTitleView.h"

#import "MTQueryBuilderChooseFieldDelegate.h"

#import "MADDatabaseTableSectionHeaderView.h"

typedef NSMutableArray <RptqDatabaseSchemaFieldSelectorManager *> MADSectionInfoArray;

static inline double heightForSectionInfo(NSUInteger numTables, NSUInteger numFields);
static inline  double heightForSectionInfo(NSUInteger numTables, NSUInteger numFields) {
    return ((numTables * MADHeaderHeight) + (numFields * MAD_44));
}

static inline double
PreferredContentHeightForUpdate(MADSectionInfoArray *sectionInfoArray,
                                RptqDatabaseSchemaFieldSelectorManager *sectionInfo);
static inline double
PreferredContentHeightForUpdate(MADSectionInfoArray *sectionInfoArray,
                                RptqDatabaseSchemaFieldSelectorManager *sectionInfo) {
    return heightForSectionInfo(sectionInfoArray.count,
                                sectionInfo == nil ?
                                0 : sectionInfo.table.hasQueryFields.count);
}

static inline CGSize
PreferredContentSizeForUpdate(MADSectionInfoArray *sectionInfoArray,
                              RptqDatabaseSchemaFieldSelectorManager *sectionInfo);
static inline CGSize
PreferredContentSizeForUpdate(MADSectionInfoArray *sectionInfoArray,
                              RptqDatabaseSchemaFieldSelectorManager *sectionInfo) {
    return CGSizeMake(MADFloat_320,
                      (CGFloat)PreferredContentHeightForUpdate(sectionInfoArray, sectionInfo));
}

@interface MTQueryBuilderChooseFieldViewController ()

    @property (nonatomic, strong) MADSectionInfoArray *sectionInfoArray;
    @property (nonatomic, strong) NSIndexPath *pinchedIndexPath;
    @property (nonatomic, strong) NSArray *dataTables;

    @property (nonatomic, assign) NSInteger openSectionIndex;
    @property (nonatomic, assign) CGFloat initialPinchHeight;

    @property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTQueryBuilderChooseFieldViewController

@synthesize unwindViewController;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        NSSortDescriptor *namesAccending =
                            [[NSSortDescriptor alloc] initWithKey: @"databaseSchemaField.name"
                                                        ascending: YES];
        NSArray *descriptors = [[NSArray alloc] initWithObjects:namesAccending, nil];
        self.sortDescriptors = descriptors;
    }
    return self;
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return NO;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    UIViewController *viewController = self.unwindViewController;
    return viewController ? viewController :
                        [super viewControllerForUnwindSegueAction: action
                                               fromViewController: fromViewController
                                                       withSender: sender];
}

#pragma mark Initialization and configuration

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer"] ||
        [segue.identifier isEqualToString:@"MTSegueAggregateFieldSave"] ||
        [segue.identifier isEqualToString:@"MTIdentifierSegueEditFieldExit"]) {
        
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell: cell];
        RptqQueryField *queryField = [self queryFieldForIndexPath:indexPath];
        [self setQueryField:queryField];
    
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;
    
    [self.tableView setSectionHeaderHeight: MADHeaderHeight];

    self.openSectionIndex = NSNotFound;
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;

    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey: @"alias"
                                                                   ascending: YES];
    NSArray *names = [[NSArray alloc] initWithObjects:namesAccending, nil];
    NSArray *dataTables = [query.hasQueryTables sortedArrayUsingDescriptors:names];
    
    self.dataTables = dataTables;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Select Field",
                                       @"Title of form that allows you to choose "
                                       @"the name of a database field.");
    self.navigationItem.titleView = titleView;
    self.tableView.isAccessibilityElement = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated]; 
	
	if (self.sectionInfoArray == nil || self.sectionInfoArray.count <= 0) {
		
        NSArray *dataTables = self.dataTables;
		NSMutableArray *infoArray = [[NSMutableArray alloc] initWithCapacity:dataTables.count];
		for (RptqQueryTable *queryTable in dataTables) {
			RptqDatabaseSchemaFieldSelectorManager *sectionInfo =
                        [[RptqDatabaseSchemaFieldSelectorManager alloc] initWithTable: queryTable];
			sectionInfo.open = NO;
			
            NSNumber *defaultRowHeight = [[NSNumber alloc] initWithDouble: MAD_44];
			NSUInteger countOfQuotations = sectionInfo.table.hasQueryFields.count;
			for (NSUInteger i = 0; i < countOfQuotations; i++) {
				[sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
			}
			
			[infoArray addObject:sectionInfo];
		}
		
		[self setSectionInfoArray: infoArray];
	}
    
   
    [self updateSize];
	
}

#pragma mark Table view data source and delegate

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    RptqDatabaseSchemaFieldSelectorManager *sectionInfo = _sectionInfoArray[(NSUInteger)section];
    return sectionInfo.open ? (NSInteger)sectionInfo.table.hasQueryFields.count : 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return (NSInteger)self.dataTables.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsInSection:section];
}


- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *CellIdentifier = @"UITableViewCellFieldWithType";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.isAccessibilityElement = YES;
    cell.accessibilityTraits = cell.accessibilityTraits | UIAccessibilityTraitButton;
    RptqDatabaseSchemaFieldSelectorManager *fieldSelectorManager = self.sectionInfoArray[(NSUInteger)indexPath.section];
    NSArray *fieldsArray = [fieldSelectorManager.table.hasQueryFields sortedArrayUsingDescriptors:self.sortDescriptors];

    RptqQueryField *field = fieldsArray[(NSUInteger)indexPath.row];
    RptqDatabaseSchemaField *schemaField = field.databaseSchemaField;
    if (field) {
        cell.textLabel.text = schemaField.name;
        cell.detailTextLabel.text = schemaField.fieldTypeDisplay.lowercaseString;
        cell.accessibilityLabel = cell.textLabel.text;
        cell.accessibilityHint = NSLocalizedString(@"Selects field.", @"Selects field.");
    }

    return cell;
}


- (UIView *)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = self.sectionInfoArray[(NSUInteger)section];
    if (!sectionInfo.headerView) {
        CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y,
                                 self.tableView.bounds.size.width, MADHeaderHeight);
        id vsht = [[MADDatabaseTableSectionHeaderView alloc] initWithFrame: rect
                                                                     title: sectionInfo.table.alias
                                                                   section: section
                                                                  delegate: self];
        sectionInfo.headerView = vsht;
    }
    return [sectionInfo headerView];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo = self.sectionInfoArray[(NSUInteger)indexPath.section];
    return [[sectionInfo objectInRowHeightsAtIndex:(NSUInteger)indexPath.row] floatValue];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqQueryField *queryField = [self queryFieldForIndexPath:indexPath];
    if (queryField != nil) {
        id <MTQueryBuilderChooseFieldDelegate> d = self.delegate;
        if (d != nil) {
            [d tableViewControllerChooseFieldDidFinish: self withField: queryField];
        }
    }
}

- (RptqQueryField *)queryFieldForIndexPath:(NSIndexPath *)indexPath {
    RptqQueryField *queryField = nil;
    RptqDatabaseSchemaFieldSelectorManager *sectionInfo = self.sectionInfoArray[(NSUInteger)indexPath.section];
    NSInteger row = indexPath.row;
    if (sectionInfo.table.hasQueryFields.count > (NSUInteger)row) {
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey: @"databaseSchemaField.name"
                                                                       ascending: YES];
        id sortDescriptors = [[NSArray alloc] initWithObjects:namesAccending, nil];
        NSArray *fieldsArray = [sectionInfo.table.hasQueryFields sortedArrayUsingDescriptors:sortDescriptors];
        queryField = fieldsArray[(NSUInteger)indexPath.row];
        [self setQueryField:queryField];
    }
    return queryField;
}

#pragma mark Section header delegate

- (void)sectionHeaderView:(MADDatabaseTableSectionHeaderView *)sectionHeaderView
            sectionOpened:(NSInteger)sectionOpened {
	
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo =
                                                self.sectionInfoArray[(NSUInteger)sectionOpened];
    sectionInfo.open = YES;
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the
        rows for each quotation in the current section.
     */
    NSUInteger countOfRowsToInsert = sectionInfo.fields.count;
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < countOfRowsToInsert; i++) {
        @autoreleasepool {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow: (NSInteger)i
                                                        inSection: sectionOpened];
            [indexPathsToInsert addObject:indexPath];
        }
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the
        rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];

    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
		
		RptqDatabaseSchemaFieldSelectorManager *previousOpenSection =
                                        self.sectionInfoArray[(NSUInteger)previousOpenSectionIndex];
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:false];
        NSUInteger countOfRowsToDelete = previousOpenSection.fields.count;
        for (NSUInteger i = 0; i < countOfRowsToDelete; i++) {
            @autoreleasepool {
                NSIndexPath *path = [NSIndexPath indexPathForRow: (NSInteger)i
                                                       inSection: previousOpenSectionIndex];
                [indexPathsToDelete addObject:path];
            }
        }
    }
    
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    } else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
    
    // Apply the updates.
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    self.openSectionIndex = sectionOpened;
    [self updateSize];
}

- (void)updateSize {
    RptqDatabaseSchemaFieldSelectorManager *sectionInfo = self.openSectionIndex == NSNotFound ?
                                    nil : self.sectionInfoArray[(NSUInteger)self.openSectionIndex];
    self.preferredContentSize = PreferredContentSizeForUpdate(self.sectionInfoArray, sectionInfo);
    self.navigationController.preferredContentSize =
                                PreferredContentSizeForUpdate(self.sectionInfoArray, sectionInfo);
}

- (void)sectionHeaderView:(MADDatabaseTableSectionHeaderView *)sectionHeaderView
            sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed,
        then delete those rows from the table view.
     */
	RptqDatabaseSchemaFieldSelectorManager *sectionInfo =
                                                self.sectionInfoArray[(NSUInteger)sectionClosed];
    sectionInfo.open = NO;

    NSInteger countOfRowsToDelete = [self.tableView numberOfRowsInSection:sectionClosed];
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:sectionClosed];
            [indexPathsToDelete addObject:path];
        }
        [self.tableView deleteRowsAtIndexPaths: indexPathsToDelete
                              withRowAnimation: UITableViewRowAnimationTop];
    }
    self.openSectionIndex = NSNotFound;
    [self updateSize];
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return (NSInteger)self.sectionInfoArray.count;
}

- (NSArray *)accessibilityElements {
    NSMutableArray *accessibilityElements;
    accessibilityElements = [[NSMutableArray alloc] initWithCapacity:self.sectionInfoArray.count];
    for (RptqDatabaseSchemaFieldSelectorManager *sectionInfo in self.sectionInfoArray) {
        [accessibilityElements addObject: sectionInfo.headerView];
    }
    return accessibilityElements;
}

@end
