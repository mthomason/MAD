//
//  MADQueryViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryViewController.h"
#import "MADQueryViewSectionDelegate.h"
#import "MADTabBarController.h"
#import "MADQueryBuilderAddTableViewController.h"
#import "MADQueryBuilderAddGroupViewController.h"
#import "MADQueryPredicateFormatController.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryGroup.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MTTableController.h"
#import "MADQueryLinkBuilderController.h"
#import "MADTableViewHeader.h"
#import "MADDesignerSectionLayoutController.h"
#import "MADNavigationController.h"
#import "MADViewControllerSQL.h"
#import "UIViewController+tabBarItem.h"
#import "MADQueryViewDataSource.h"
#import "MADQueryBuilderAddGroupDelegate.h"
#import "MADQueryViewControllerTableLayout.h"
#import "MADQueryViewControllerLayoutSectionSelectorProtocol.h"
#import "MTStoreKitController+Features.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MADQueryViewDelegate.h"
#import "MADTabBarItemProtocol.h"
#import "MADQueryViewDatasourceProtocol.h"
#import "MADOperationGetCredentials.h"
#import "MADThemeManager.h"
#import "madlog.h"

#import <CoreData/NSManagedObjectContext.h>
#import <MADAPI/MADQuery.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/MADDatabase+Constructor.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelQuery.h>

#import <MADFoundation/MADOperationObserver.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationObserver.h>

#import <UIKit/UIPopoverPresentationController.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImage.h>

NSString * const MADImageBarButtonItemDatabase8 = @"UIBarButtonItemDatabase8";

static NSString * const MADIdentifierDefaultsViewerDesired = @"defaults.everydayapps.features.viewer.desired";

BOOL storeEnabled(void);
BOOL storeEnabled(void) {
	return [MADStoreKitController sharedObject].reportingEnabled;
}

#pragma mark - Private Category

@interface MADQueryViewController ()< UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate, MADOperationQueueDelegate, MADOperationObserver, MADQueryViewDelegateProtocol, MADQueryViewControllerLayoutSectionSelectorProtocol, MADQueryBuilderAddTableDelegate, MADQueryBuilderAddGroupDelegate, MADViewControllerStandardProtocol, MADQueryBuilderLinkBuilderDelegate, MADViewControllerStandardProtocol, MADDesignerSectionLayoutDelegate, MADQueryBuilderPredicateFormatDelegate, MADQueryViewControllerDatasourceProtocol>

@property (nonatomic, assign) NSInteger showingTableIndex;
@property (nonatomic, strong) MADQueryViewDataSource *queryViewDataSource;
@property (nonatomic, strong) MADQueryViewDelegate *queryViewDelegate;
@property (nonatomic, strong) MADQueryViewCellConfigureHandler handleConfigureCell;
@property (nonatomic, strong) MADOperationQueue *credentailsQueue;
@property (nonatomic, readonly) MADTabBarController *tabBarController;
@property (nonatomic, weak) UIPresentationController *showSQLPresentationController;

@end

@implementation MADQueryViewController {
	NSUInteger _lastSelectedRowNumber;
	CGFloat _headerSectionHeight;
	BOOL _suspendAutomaticTrackingOfChangesInManagedObjectContext;
	BOOL _firstTimeViewWillLayoutSubviews;
	BOOL _beganUpdates;
}

@synthesize title = _title;
@synthesize document = _document;

#pragma mark -
#pragma mark Static Helpers

+ (void)configureCell: (UITableViewCell *)cell
		   forSection: (MADIdentifierQueryViewSections)section
			   andRow: (NSInteger)row {
	
	switch (section) {
			
		case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
			
			UISwitch *switchQueryMode = [[UISwitch alloc] initWithFrame:CGRectZero];
			switchQueryMode.on = [[NSUserDefaults standardUserDefaults] boolForKey: MADIdentifierDefaultsViewerDesired];
			[switchQueryMode addTarget: nil action: @selector(handleToggleReportingMode:) forControlEvents: UIControlEventValueChanged];
			cell.accessoryView = switchQueryMode;
			cell.textLabel.text = switchQueryMode.on ? NSLocalizedString(@"Reporting Mode", @"Reporting Mode") : NSLocalizedString(@"Designer Mode (limited)", @"Designer Mode (limited)");
			cell.textLabel.textColor = [UIColor labelColor];
			break;
		}
			
		default: {
			break;
		}
	}
}

+ (CGFloat)SizeCategoryHeight:(NSString *)category {
	
	if ([category isEqualToString: UIContentSizeCategoryExtraSmall]) {
		return 24.0;
		
	} else if ([category isEqualToString: UIContentSizeCategorySmall]) {
		return 26.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryMedium]) {
		return 29.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryLarge]) {
		return 32.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryExtraLarge]) {
		return 34.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryExtraExtraLarge]) {
		return 36.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryExtraExtraExtraLarge]) {
		return 38.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryAccessibilityMedium]) {
		return 40.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryAccessibilityLarge]) {
		return 42.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraLarge]) {
		return 44.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
		return 46.0;
		
	} else if ([category isEqualToString: UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
		return 48.0;
		
	} else {
		return 29.0;
	}
}

+ (void)deleteCoreDataCache { }

#pragma mark -
#pragma mark NSObject

/*
+ (instancetype)newQueryViewController:(MADocument *)document {
	id bundle = [NSBundle mainBundle];
	id storybard = [UIStoryboard storyboardWithName: @"MADQuery" bundle: bundle];
	id controller = [storybard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryViewController"];
	[((typeof(self))controller) setDocument: document];
	return controller;
}
*/

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[MADQueryViewController deleteCoreDataCache];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	[self.tableView setBackgroundView:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	[MADQueryViewController deleteCoreDataCache];
	if (self = [super initWithCoder:aDecoder]) {
		_showingTableIndex = -1;
		
		_firstTimeViewWillLayoutSubviews = YES;
		
		MADQueryViewDelegate *queryViewDelegate = [[MADQueryViewDelegate alloc] init];
		queryViewDelegate.delegate = self;
		self.queryViewDelegate = queryViewDelegate;
		
		MADQueryViewCellConfigureHandler handleConfigureCell = ^(UITableViewCell *cell, MADIdentifierQueryViewSections forSection, NSInteger row) {
			
			[MADQueryViewController configureCell: cell
									   forSection: forSection
										   andRow: row];
			
		};
		self.handleConfigureCell = handleConfigureCell;
		
		MADOperationQueue *credentailsQueue = [[MADOperationQueue alloc] init];
		credentailsQueue.delegate = self;
		self.credentailsQueue = credentailsQueue;
	}
	return self;
}

#pragma mark -
#pragma mark Storyboard

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController *)fromViewController
							 sender:(nullable id)sender {
	return action == @selector(unwindToQueryBuilder:);
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSString *sizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
	[self updateInupdateInterfaceForPerferedContentSizeCategory: sizeCategory];
	
	[self.tableView registerClass: [MADTableViewCellQueryTableName class]
		   forCellReuseIdentifier: @"MADIdentifierCellSchemaName"];
	
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;

	self.navigationItem.prompt = nil;
	self.tableView.dataSource = self.queryViewDataSource;
	self.tableView.delegate = self.queryViewDelegate;
	
	[self reloadMainDocumentAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear: animated];

	MADocument *document = _document;
	RptqStoreContext *managedObjectContext = document.storeContext;

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleDocumentStateChanged)
												 name: UIDocumentStateChangedNotification
											   object: document];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleContentSizeCategoryDidChange:)
												 name: UIContentSizeCategoryDidChangeNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleApplicationDidBecomeActive:)
												 name: UIApplicationDidBecomeActiveNotification
											   object: nil];
	
	[self observeManagedObjectContextChanges: managedObjectContext];
	[self.tabBarController enableTabBarItems];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:YES];
	
	MADocument *document = _document;
	[self ingnoreManagedObjectContextChanges: document.storeContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIDocumentStateChangedNotification
												  object: document];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIContentSizeCategoryDidChangeNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIApplicationDidBecomeActiveNotification
												  object: nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	if (_firstTimeViewWillLayoutSubviews) {
		_firstTimeViewWillLayoutSubviews = NO;
		CGRect r = CGRectMake(CGPointZero.x, CGPointZero.y, self.tableView.frame.size.width, 1.0);
		[self.tableView scrollRectToVisible: r animated: NO];
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.view.frame = self.navigationController.view.bounds;
	} completion:nil];

}

#pragma mark -
#pragma mark Operations

- (NSArray <NSIndexPath *> *)tableView:(UITableView *)tableView
						   deleteLinks:(int64_t)relatedTableObjectID
							   section:(NSInteger)section
							   context:(RptqStoreContext *)context {

	NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
	NSArray *fetchedLinkes = self.queryViewDataSource.queryLinksController;
	NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
	
	for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
		NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		NSError *error = NULL;
		RptqObject *object = nil;
		MADTableViewCellQueryLink *cell;
		cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
		if (cell) {
			object = [context objectForEntity:NSStringFromClass([RptqQueryLinks class]) identifier:cell.linkID];
		} else {

			if (row < (NSInteger)fetchedLinkes.count) {
				object = fetchedLinkes[(NSUInteger)row];
			}

		}
		if (!error && object && [object isKindOfClass:[RptqQueryLinks class]]) {
			RptqQueryLinks *queryLink = (RptqQueryLinks *)object;
			if (queryLink.hasLeftField.inQueryTable.identifier == relatedTableObjectID ||
				queryLink.hasRightField.inQueryTable.identifier == relatedTableObjectID) {
				[context deleteObject:queryLink error:NULL];
				[cellsToDelete addObject:linkIndexPath];
			}
		}
	}
	return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)tableView:(UITableView *)tableView
						  deleteGroups:(int64_t)relatedTableObjectID
							   section:(NSInteger)section
							   context:(RptqStoreContext *)context {
	NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
	NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
	for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
		NSIndexPath *groupIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		NSError *error = nil;

		if (row < (NSInteger)self.queryViewDataSource.queryGroupsController.count) {

			RptqObject *object;
			object = self.queryViewDataSource.queryGroupsController[(NSUInteger)row];

			if (!error && object && [object isKindOfClass:[RptqQueryGroup class]]) {
				
				RptqQueryGroup *groupToRemove = (RptqQueryGroup *)object;
				if (groupToRemove.hasField.inQueryTable.identifier == relatedTableObjectID) {
					[self.document removeGroupWitObjectID: groupToRemove.identifier
								 fromManagedObjectContext: context];
					[cellsToDelete addObject:groupIndexPath];
				}
				
			}
			
		}
	}
	return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)tableView:(UITableView *)tableView
					  deletePredicates:(int64_t)relatedTableObjectID
							   section:(NSInteger)section
							   context:(RptqStoreContext *)context {
	NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
	NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];

	for (NSInteger row = 0; row < numberOfRowsInSection; row++) {

		NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		
		MADTableViewCellQueryPredicate *cell;
		cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:predicateIndexPath];
		NSError *error = nil;
		RptqObject *object = nil;
		
		if (cell) {
			object = [context objectForEntity:NSStringFromClass([RptqQueryPredicate class]) identifier:cell.predicateID];
		} else {
			NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
			object = self.queryViewDataSource.queryPredicatesController[(NSUInteger)row];
		}
		
		if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
		
			RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;

			BOOL deleted = NO;
			if (predicateToRemove.hasLeftField.inQueryTable.identifier == relatedTableObjectID) {
				[context deleteObject:predicateToRemove error:NULL];
				NSIndexPath *deleteCellAtIndex = [predicateIndexPath copy];
				[cellsToDelete addObject:deleteCellAtIndex];
				deleted = YES;
			}
			
			if (!deleted) {
				if (predicateToRemove.hasRightField.inQueryTable.identifier == relatedTableObjectID) {
					[context deleteObject:predicateToRemove error:NULL];
					NSIndexPath *deleteCellAtIndex = [predicateIndexPath copy];
					[cellsToDelete addObject:deleteCellAtIndex];
				}
			}
		}
	}
	return cellsToDelete;

}

- (void)deleteQueryTableFromTableView: (UITableView *)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	MADocument *document = self.document;
	[self ingnoreManagedObjectContextChanges:document.storeContext];

	_suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
	
	RptqStoreContext *private = document.storeContext;
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
		
		NSUInteger numberOfTables = rptqQuery.hasQueryTables.count;
		
		BOOL reportingEnabled = [MADStoreKitController sharedObject].reportingEnabled;
		MADQueryViewDataSource *oldQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
																					   reportingEnabled: reportingEnabled
																					handleConfigureCell: nil];
		
		MADQueryViewDataSource *newQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables - 1
																					   reportingEnabled: reportingEnabled
																					handleConfigureCell: nil];

		NSIndexSet *indexSetSectionsOld = oldQueryLayout.sectionTypesIndexs;
		NSMutableIndexSet *indexSetSectionsOldM = indexSetSectionsOld.mutableCopy;
		[indexSetSectionsOldM removeIndexes:newQueryLayout.sectionTypesIndexs];
		
		NSMutableSet *deletedSectionTypes = oldQueryLayout.sectionTypes.mutableCopy;
		[deletedSectionTypes minusSet:newQueryLayout.sectionTypes];
		
		NSIndexPath *tableIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 0];
		NSIndexPath *displayIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 1];
		RptqQueryTable *table = self.queryViewDataSource.queryTablesController[(NSUInteger)tableIndex.row];
		
		int64_t deleatedTableObjectId = table.identifier;
		
		NSMutableSet *hasQueryTables = rptqQuery.hasQueryTables.mutableCopy;
		
		__block id objectToDelete = nil;
		[hasQueryTables enumerateObjectsUsingBlock:^(RptqQueryTable * _Nonnull hasTable, BOOL * _Nonnull stop) {
			if (table.identifier == hasTable.identifier) {
				objectToDelete = hasTable;
			}
		}];
		
		__block short ctr = 0;
		NSMutableIndexSet *indexSetSections = [[NSMutableIndexSet alloc] init];
		[indexSetSectionsOld enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			if ([indexSetSectionsOldM containsIndex:idx]) {
				[indexSetSections addIndex:(NSUInteger)ctr];
			}
			ctr++;
		}];
		[tableView beginUpdates];
		
		[document deleteDatafieldsRelatedToTable:deleatedTableObjectId inContent:private];
		[document deleteAggregateFieldRelatedToTable:deleatedTableObjectId inContent:private];
		
		NSMutableArray <NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
		
		short numberOfSections = self.queryViewDataSource.count;
		for (short section = 0; section < numberOfSections; section++) {
			
			NSArray <NSIndexPath *> *cells = nil;
			
			switch ([self.queryViewDataSource sectionAtIndex:section]) {
				case MADIdentifierQueryViewSectionsLinks:
					cells = [self tableView: tableView
									  deleteLinks: deleatedTableObjectId
										  section: (NSInteger)section
										  context: private];
					break;
					
				case MADIdentifierQueryViewSectionsGroups:
					cells = [self tableView: tableView
									 deleteGroups: deleatedTableObjectId
										  section: (NSInteger)section
										  context: private];
					break;
					
				case MADIdentifierQueryViewSectionsPredicate:
					cells = [self tableView: tableView
								 deletePredicates: deleatedTableObjectId
										  section: (NSInteger)section
										  context: private];
					break;
					
				default:
					break;
			}
			if (cells) {
				if (![indexSetSections containsIndex:(NSUInteger)section]) {
					[cellsToDelete addObjectsFromArray:cells];
				}
			}
		}
	
		[hasQueryTables removeObject:objectToDelete];
		rptqQuery.hasQueryTables = [hasQueryTables copy];
		[private deleteObject:objectToDelete error:NULL];
		numberOfTables--;
		
		NSError *error = nil;
		BOOL success = [private save:&error];
		if (!success && error != nil) {
			os_log_error(GetDesignerLog(), "Error saving managed object: %@", error);
		} else {
			[self.queryViewDataSource numberOfTablesChanged: numberOfTables];

			NSArray <NSIndexPath *> *indexPaths;
			indexPaths = [[NSArray <NSIndexPath *> alloc] initWithObjects:displayIndex, nil];
			
			if (indexSetSections.count > 0) {
				
				[tableView deleteSections: indexSetSections
						 withRowAnimation: UITableViewRowAnimationAutomatic];
				[tableView deleteRowsAtIndexPaths: indexPaths
								 withRowAnimation: UITableViewRowAnimationAutomatic];
				
			} else {
				[tableView deleteRowsAtIndexPaths: indexPaths
								 withRowAnimation: UITableViewRowAnimationAutomatic];
			}
			if (cellsToDelete.count) {
				[tableView deleteRowsAtIndexPaths: cellsToDelete
								 withRowAnimation: UITableViewRowAnimationAutomatic];
			}

			[self.tableView endUpdates];

			[self observeManagedObjectContextChanges:private];
			self->_suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
		}
	[self observeManagedObjectContextChanges:document.storeContext];
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

- (void)deleteQueryLinksFromTableView: (UITableView *)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	MADocument *document = self.document;
	MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
	int64_t tableID = cell.linkID;
	RptqStoreContext *private = document.storeContext;
		
		RptqObject *objectToDelete = [private objectForEntity:NSStringFromClass([RptqQueryLinks class]) identifier:tableID];
		NSAssert(objectToDelete != nil, @"Need a non-nil value for %@", tableID);
		[private deleteObject:objectToDelete error:NULL];
		
		NSError *error = nil;
		BOOL successSave = [private save:&error];
		if (!successSave && error != nil) {
			os_log_error(GetDesignerLog(), "Error saving managed object: %s", error.localizedDescription.UTF8String);
		}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

- (void)deleteQueryGroupFromTableView: (UITableView *)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	
	MADocument *document = self.document;
	RptqStoreContext *private = document.storeContext;
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
		RptqQueryGroup *groupToRemove = [rptqQuery queryGroupForIndex:(NSUInteger)indexPath.row];
		[self.document removeGroupWitObjectID:groupToRemove.identifier fromManagedObjectContext:private];
		
		NSError *error = nil;
		BOOL successSave = [private save:&error];
		if (!successSave && error != nil) {
			os_log_error(GetDesignerLog(), "Error saving managed object: %s", error.localizedDescription.UTF8String);
		}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

- (void)deleteQueryPredicateFromTableView: (UITableView *)tableView
							  atIndexPath: (NSIndexPath *)indexPath {
	MADocument *document = self.document;
	MADTableViewCellQueryPredicate *cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath];
	int64_t objid = cell.predicateID;
	RptqQueryPredicate *predicate = [document.storeContext objectForEntity:NSStringFromClass([RptqQueryPredicate class]) identifier:objid];
	[document.storeContext deleteObject:predicate error:NULL];

	NSError *error = nil;
	BOOL successSave = [document.storeContext save:&error];
	if (!successSave && error != nil) {
		os_log_error(GetDesignerLog(), "Error saving managed object context: %@", error);
	}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

#pragma mark -
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
	
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
	return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
	[(MADTabBarController *)self.tabBarController enableTabBarItems];
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController
		  willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView  * __nonnull __autoreleasing * __nonnull)view {
	
}

#pragma mark -
#pragma mark MADQueryBuilderPredicateFormatDelegate

- (void)viewController:(MADQueryPredicateFormatController *)controller addedQueryPredicate:(RptqQueryPredicate *)predicate {
	[self dismissViewController];
}

#pragma mark -
#pragma mark MADQueryBuilderLinkBuilderDelegate

- (void)viewController:(MADQueryLinkBuilderController *)controller addedQueryLink:(int64_t)linkID {
	
	[self dismissViewController];
	
	NSInteger suspectedSection = 2;
	
	MADIdentifierQueryViewSections tableSection = [self.queryViewDataSource sectionAtIndex:(short)suspectedSection];
	
	if (tableSection == MADIdentifierQueryViewSectionsLinks) {
		[self.tableView reloadSections: [NSIndexSet indexSetWithIndex:(NSUInteger)suspectedSection]
					  withRowAnimation: UITableViewRowAnimationAutomatic];
	}
	
	//[document saveToURL: document.fileURL
	//   forSaveOperation: UIDocumentSaveForOverwriting completionHandler:nil];
}

#pragma mark -
#pragma mark MADQueryBuilderAddGroupDelegate

- (void)viewController:(MADQueryBuilderAddGroupViewController *)vc addedGroupOnQueryField:(int64_t)objectID
		  andSortOrder:(MADSortOrder)sortOrder {
	[self dismissViewController];
	[self.document addQueryGroupWithQueryField: objectID andSortOrder: sortOrder];
}

#pragma mark -
#pragma mark MADQueryBuilderAddTableDelegate

- (NSIndexSet *)newSectionsTableCountStart:(NSUInteger)numberOfTables
							 tableCountEnd:(NSUInteger)numberOfTablesEnd
						  reportingEnabled:(BOOL)reportingEnabled {

	MADQueryViewDataSource *oldQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
																				   reportingEnabled: reportingEnabled
																				handleConfigureCell: nil];
	
	MADQueryViewDataSource *newQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTablesEnd
																				   reportingEnabled: reportingEnabled
																				handleConfigureCell: nil];
	NSMutableIndexSet *indexesToAdd = newQueryLayout.sectionTypesIndexs.mutableCopy;
	[indexesToAdd removeIndexes:oldQueryLayout.sectionTypesIndexs];
	__block short ctr = 0;
	NSMutableIndexSet *indexSetSections = [[NSMutableIndexSet alloc] init];
	[newQueryLayout.sectionTypesIndexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
		if ([indexesToAdd containsIndex:idx]) {
			[indexSetSections addIndex:(NSUInteger)ctr];
		}
		ctr++;
	}];
	return indexSetSections;
}

- (void)viewController:(MADQueryBuilderAddTableViewController *)vc addedQueryTableWithID:(int64_t)objectID {
	
	MADocument *document = self.document;

	[self dismissViewController];

	_suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;

	RptqStoreContext *private = document.storeContext;

	RptqDatabaseSchemaTable *schemaTable = (RptqDatabaseSchemaTable *)[private objectForEntity:NSStringFromClass([RptqDatabaseSchemaTable class]) identifier:objectID];
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *query = rptqDatabase.hasQueries.anyObject;

		NSUInteger numberOfTablesOld = query.hasQueryTables.count;
		NSUInteger numberOfTables = numberOfTablesOld + 1;
		BOOL reportingEnabled = [MADStoreKitController sharedObject].reportingEnabled;

		RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
																		   database: rptqDatabase
															forManagedObjectContext: private];
		
		NSMutableSet <RptqQueryTable *> *tablesInQuery = query.hasQueryTables.mutableCopy;
		NSMutableSet <RptqQueryField *> *newQueryFields = [[NSMutableSet alloc] initWithCapacity: schemaTable.hasFields.count];
		
		for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
			@autoreleasepool {
				RptqQueryField *newQueryField = [RptqQueryField newQueryField:private];
				newQueryField.inQueryTable = newQueryTable;
				newQueryField.databaseSchemaField = field;
				[newQueryFields addObject:newQueryField];
			}
		}
		newQueryTable.hasQueryFields = newQueryFields;
		
		[tablesInQuery addObject:newQueryTable];
		query.hasQueryTables = tablesInQuery;
		
		NSError *errorSave = nil;
		[private save:&errorSave];
		if (errorSave != nil) {
			os_log_error(GetDesignerLog(), "Error saving managed object: %@", errorSave);
		} else {
			[self.queryViewDataSource numberOfTablesChanged: numberOfTables];
			[self.queryViewDataSource performFetchTables];
			NSUInteger tableIndex = [self.queryViewDataSource.queryTablesController indexOfObjectPassingTest:^BOOL(RptqQueryTable *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				return newQueryTable.identifier == obj.identifier;
			}];

			NSIndexSet *indexSetSections = [self newSectionsTableCountStart: numberOfTablesOld
															  tableCountEnd: numberOfTables
														   reportingEnabled: reportingEnabled];

			[self tableView: self.tableView insertTable:tableIndex andSection:indexSetSections];
		}

		[tablesInQuery removeAllObjects];
		[newQueryFields removeAllObjects];

	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL success) {
		[self.queryViewDataSource performFetchTables];
	}];
	_suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
	
}

- (void)tableView:(UITableView *)tableView insertTable:(NSUInteger)tableIndex andSection:(NSIndexSet *)sections {
	
	NSIndexPath *tablePath = [NSIndexPath indexPathForRow: (NSInteger)tableIndex inSection: 1];
	NSArray <NSIndexPath *> *tablePaths = [[NSArray <NSIndexPath *> alloc] initWithObjects: tablePath, nil];
	[tableView beginUpdates];
	[tableView insertRowsAtIndexPaths: tablePaths withRowAnimation: UITableViewRowAnimationAutomatic];
	if (sections.count > 0) {
		[tableView insertSections: sections withRowAnimation: UITableViewRowAnimationAutomatic];
	}
	[tableView endUpdates];
}

#pragma mark -
#pragma mark Property Overrides

- (MADTabBarController *)tabBarController {
	return (MADTabBarController *)self.navigationController.tabBarController;
}

- (void)setDocument:(MADocument *)document {
	if (_document != document) {
		_document = document;
	}
}

- (NSString *)title {
	if (_title == nil) {
		_title = NSLocalizedString(@"MAD Query", @"Query view controller title.");
	}
	return _title;
}

- (MADQueryViewDataSource *)queryViewDataSource {
	if (_queryViewDataSource == nil) {
		MADocument *document = _document;
		RptqStoreContext *managedObjectContext = document.documentModel.managedObjectContext;
		NSNumber *objectID = @(document.documentModel.databases.firstObject.queries.firstObject.identifier);
		MADQueryViewDataSource *dataSource = [[MADQueryViewDataSource alloc] initWithQueryID: objectID
																		managedObjectContext: managedObjectContext
																			reportingEnabled: [MADStoreKitController sharedObject].reportingEnabled
																		 handleConfigureCell: _handleConfigureCell];
		dataSource.datasoruce = self;
		_queryViewDataSource = dataSource;
	}
	return _queryViewDataSource;
}

#pragma mark -
#pragma mark MADDesignerSectionLayoutDelegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
	MADocument *document = self.document;
	[document.activeDocumentModel setHeight: height forSectionAtRow: _lastSelectedRowNumber];
	[document saveContext];
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
	MADocument *document = self.document;
	[document.activeDocumentModel setVisibility: isVisible forSectionAtRow: _lastSelectedRowNumber];
	[document saveContext];
}

- (void)layoutSettings:(MADDesignerSectionLayoutController *)layoutSettings newPageAfter:(BOOL)newPageAfter {
	MADocument *document = self.document;
	[document.activeDocumentModel setNewPageAfter: newPageAfter
								  forSectionAtRow: _lastSelectedRowNumber];
	[document saveContext];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(int32_t)numberOfRows {
	MADocument *document = self.document;
	[document.activeDocumentModel setNumberOfRows: numberOfRows
								  forSectionAtRow: _lastSelectedRowNumber];
	[document saveContext];
}

#pragma mark -
#pragma mark MUIViewControllerDelegate

- (void)dismissViewController {
	[self dismissViewControllerAnimated:YES completion:^{
		[self.tabBarController enableTabBarItems];
	}];
}

- (void)viewControllerDidFinish:(id)sender {
	[self dismissViewController];
}

- (void)viewControllerDidCancel:(id)sender {
	[self dismissViewController];
}

#pragma mark -
#pragma mark Event handlers

- (void)handleApplicationDidBecomeActive:(id)sender {
	[MADQueryViewController deleteCoreDataCache];
}

- (void)handleToggleReportingMode:(UISwitch *)switchControl {
	if (switchControl.on) {
		if ([MADStoreKitController sharedObject].isReportingEnabled) {
			[[NSUserDefaults standardUserDefaults] setBool: YES
													forKey: MADIdentifierDefaultsViewerDesired];
		} else {
			[[NSUserDefaults standardUserDefaults] setBool: NO
													forKey: MADIdentifierDefaultsViewerDesired];
			[switchControl setOn:NO animated:YES];
		}
	} else {
		[[NSUserDefaults standardUserDefaults] setBool: NO
												forKey: MADIdentifierDefaultsViewerDesired];
	}
}

#pragma mark UIDocumentStateChangedNotification

- (void)handleDocumentStateChanged {
	
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
#pragma mark -
#pragma mark MTTabBarImageProtocol

+ (UIImage *)TabBarImage {
	return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

#pragma mark -
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
	if ([controller isEqual:self.showSQLPresentationController]) {
		return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIModalPresentationNone : UIModalPresentationOverFullScreen;
	} else {
		return UIModalPresentationOverCurrentContext;
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)actionToggleDisplay:(id)sender {
	
}

- (IBAction)edit:(id)sender {
	self.tableView.editing = !self.tableView.isEditing;
}

- (IBAction)done:(id)sender {
	[((MADNavigationController *)self.navigationController) done:sender];
}

- (IBAction)displaySQL:(id)sender {
	UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"MADQuery" bundle:nil] instantiateViewControllerWithIdentifier:@"MADQuerySQLNavigationController"];
	navigationController.modalPresentationStyle = UIModalPresentationPopover;
	MADViewControllerSQL *viewController = (MADViewControllerSQL *)navigationController.topViewController;
	viewController.document = self.document;
	viewController.delegate = self;
	UIPopoverPresentationController *ppc = navigationController.popoverPresentationController;
	ppc.backgroundColor = [UIColor clearColor];
	ppc.delegate = self;
	ppc.barButtonItem = sender;
	
	self.showSQLPresentationController = ppc;
	[MADThemeManager applyAppearanceToNavigationController:navigationController traitCollection:self.traitCollection];
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addTable:(id)sender {
	UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"MADQueryAddTable" bundle:nil] instantiateInitialViewController];
	navigationController.modalPresentationStyle = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIModalPresentationFormSheet : UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	
	MADQueryBuilderAddTableViewController *tvc = (MADQueryBuilderAddTableViewController *)navigationController.topViewController;
	tvc.delegate = self;
	tvc.managedObjectContext = self.document.storeContext;
	[MADThemeManager applyAppearanceToNavigationController:navigationController traitCollection:self.traitCollection];
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addLink:(id)sender {
	UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"MADQueryAddJoin" bundle:nil] instantiateInitialViewController];
	navigationController.modalPresentationStyle = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIModalPresentationFormSheet : UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	MADQueryLinkBuilderController *tvc = (MADQueryLinkBuilderController *)navigationController.topViewController;
	tvc.queryLinkDelegate = self;
	tvc.document = self.document;
	[MADThemeManager applyAppearanceToNavigationController:navigationController traitCollection:self.traitCollection];
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addPredicate:(id)sender {
	UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"MADQueryAddPredicate" bundle:nil] instantiateInitialViewController];
	navigationController.modalPresentationStyle = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIModalPresentationFormSheet : UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	MADQueryPredicateFormatController *tvc = (MADQueryPredicateFormatController *)navigationController.topViewController;
	tvc.delegate = self;
	tvc.document = self.document;
	[MADThemeManager applyAppearanceToNavigationController:navigationController traitCollection:self.traitCollection];
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addGroup:(id)sender {
	UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"MADQueryAddGroup" bundle:nil] instantiateInitialViewController];
	navigationController.modalPresentationStyle = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIModalPresentationFormSheet : UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	MADQueryBuilderAddGroupViewController *tvc = (MADQueryBuilderAddGroupViewController *)navigationController.topViewController;
	tvc.delegate = self;
	tvc.document = self.document;
	[MADThemeManager applyAppearanceToNavigationController:navigationController traitCollection:self.traitCollection];
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

#pragma mark -
#pragma mark Helper functions

- (void)updateInupdateInterfaceForPerferedContentSizeCategory:(NSString *)category {
	_headerSectionHeight = [self.class SizeCategoryHeight:category];
}

#pragma mark Section Indexes

- (MADIdentifierQueryViewSections)sectionIndexForTables {
	return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsTables];
}

- (MADIdentifierQueryViewSections)sectionIndexForLinks {
	return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsLinks];
}

- (MADIdentifierQueryViewSections)sectionIndexForGroups {
	return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsGroups];
}

- (MADIdentifierQueryViewSections)sectionIndexForPredicate {
	return [self sectionIndexForSectionType: MADIdentifierQueryViewSectionsPredicate];
}

- (MADIdentifierQueryViewSections)sectionIndexForSectionType:(MADIdentifierQueryViewSections)sec {
	MADIdentifierQueryViewSections result = 0;
	MADQueryViewControllerTableLayout *tableLayout  = [[MADQueryViewControllerTableLayout alloc] initWithNumberOfTables:[self.tableView numberOfRowsInSection: 1]
																									   reportingEnabled:storeEnabled()];
	NSInteger secPos = 0;
	for (NSNumber *num in [tableLayout sectionTypes]) {
		if (num.shortValue == sec) {
			result = (MADIdentifierQueryViewSections)secPos;
			break;
		}
		secPos++;
	}
	return result;
}

#pragma mark User Interface

- (void)enableUserInteraction {
	[self.tableView setUserInteractionEnabled:YES];
}

- (void)disableUserInteraction {
	[self.tableView setUserInteractionEnabled:NO];
}

- (void)reloadMainDocumentAnimated:(BOOL)animated {
	MADocument *reportDocument = self.document;
	NSAssert(reportDocument != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
	[self.queryViewDataSource performFetchAll];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark MADQueryViewControllerDatasourceProtocol

- (void)reloadQueryViewData {
	[self.tableView reloadData];
}

- (void)queryDatasource:(NSObject <MADQueryViewControllerDatasourceProtocol> *)datasource
			  tableView:(UITableView *)tableView
			 deleteItem:(NSIndexPath *)item
			fromSection:(MADIdentifierQueryViewSections)section {
	switch (section) {
		case MADIdentifierQueryViewSectionsTables:
			[self deleteQueryTableFromTableView: tableView atIndexPath: item];
			break;
			
		case MADIdentifierQueryViewSectionsLinks:
			[self deleteQueryLinksFromTableView: tableView atIndexPath: item];
			break;
			
		case MADIdentifierQueryViewSectionsGroups:
			[self deleteQueryGroupFromTableView: tableView atIndexPath: item];
			break;
			
		case MADIdentifierQueryViewSectionsPredicate:
			[self deleteQueryPredicateFromTableView: tableView atIndexPath: item];
			break;
			
		default:
			break;
	}
}

#pragma mark -
#pragma mark MADQueryViewDelegateProtocol

- (MADIdentifierQueryViewSections)sectionIdentifierForDisplayIndex:(short)displayIndex {
	return [self.queryViewDataSource sectionAtIndex:displayIndex];
}

- (MADQueryViewSectionDelegate *)sectionLayoutForDisplayIndex:(short)displayIndex {
	return [self.queryViewDataSource layoutAtIndex:displayIndex];
}

- (CGFloat)headerHeight {
	return _headerSectionHeight;
}

- (void)queryViewDelegate:(MADQueryViewDelegate *)delegate handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index {

	NSArray <RptqDatabase *> *results = [self.queryViewDataSource.managedObjectContext objectsForEntity:NSStringFromClass([RptqDatabase class])];
	if (results.count == 0) {
		os_log_error(GetDesignerLog(), "%s Error fetching NSArray <RptqDatabase *>: no rows", __PRETTY_FUNCTION__);
	}

	RptqDatabaseCredentals *databaseCredentals = ((RptqDatabase *) results.firstObject).ownedByUser;
	MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnection:databaseCredentals];
	MADOperationGetCredentials *operationGetCredentials = [[MADOperationGetCredentials alloc] initWithDatabaseConnection:databaseConnection
																										  viewController:self];
	self.credentailsQueue.maxConcurrentOperationCount = 1;
	[self.credentailsQueue addOperation:operationGetCredentials];
	_showingTableIndex = index;
}

- (void)finishUserRequestForSampleData:(MADCredential *)credentials {
	NSIndexPath *indexPathUpdate = [NSIndexPath indexPathForRow: self.showingTableIndex inSection: 0];
	self.showingTableIndex = -1;
	
	MADQueryViewDataSource *queryViewDataSource = self.queryViewDataSource;
	NSArray *queryTablesResultsController = queryViewDataSource.queryTablesController;
	
	RptqQueryTable *table = queryTablesResultsController[(NSUInteger)indexPathUpdate.row];
	
	MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnection:table.databaseSchemaTable.inDatabase.ownedByUser];
	
	MADDatabase *db = [MADDatabase newDatabaseWithConnection:databaseConnection];
	
	MADQuery <MADQueryDatabaseProtocol, MADQueryCredentialProtocol, MADQueryDatabaseRangeProtocol> *rquery = (MADQuery <MADQueryDatabaseProtocol, MADQueryCredentialProtocol, MADQueryDatabaseRangeProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeSampleDataTableRange
																																											  object: table.databaseSchemaTable];
	rquery.credential = [credentials copy];
	if ([rquery conformsToProtocol:@protocol(MADDatabaseResultsProtocol)]) {
		db.delegate = ((NSObject <MADDatabaseResultsProtocol> *)rquery);
	}
	
	MADTableController *tableController = [[MADTableController alloc] initWithQuery:rquery
																		   database:db
																			tableID:table.databaseSchemaTable.identifier];
	[[self displayController] showDetailViewController:tableController sender:self];
}

- (UIViewController *)displayController {
	return self.parentViewController.parentViewController;
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray<NSError *> *)errors {
	if (errors.count > 0) {
		for (NSError *error in errors) {
			os_log_error(GetDesignerLog(), "%s: Error: %@", __PRETTY_FUNCTION__, error);
		}
	}
}

- (void)operationQueue:(MADOperationQueue *)operationQueue
	  willAddOperation:(NSOperation *)operation { }

- (void)operationQueue:(MADOperationQueue *)operationQueue
	operationDidFinish:(NSOperation *)operation
			withErrors:(NSArray<NSError *> *)errors {
	if (_showingTableIndex >= 0 && [operationQueue isKindOfClass:[MADOperationQueue class]] &&
		[operation isKindOfClass:[MADOperationGetCredentials class]]) {
		
		MADCredential *credentials = ((MADOperationGetCredentials *)operation).credentials;
		__weak MADQueryViewController *wself = self;
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			__strong MADQueryViewController *sself = wself;
			[sself finishUserRequestForSampleData:credentials];
		}];
	}
}

#pragma mark -
#pragma mark CoreData

#pragma mark -
#pragma mark Notifications
#pragma mark NSManagedObjectContext Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
	if (_suspendAutomaticTrackingOfChangesInManagedObjectContext) return;

	NSDictionary *userInfo = notification.userInfo;
	NSSet *inserted = userInfo[NSInsertedObjectsKey];
	NSSet *deleted = userInfo[NSDeletedObjectsKey];
	NSSet *updated = userInfo[NSUpdatedObjectsKey];

	// The query lists track the query's tables, links, groups, and predicates: a
	// change to any of them reloads every list.
	BOOL queryChanged = NO;
	NSArray *trackedClasses = @[
		[RptqQueryTable class], [RptqQueryLinks class], [RptqQueryGroup class],
		[RptqQueryPredicate class], [RptqQuery class]
	];
	for (id object in inserted) {
		for (Class tracked in trackedClasses) {
			if ([object isKindOfClass:tracked]) { queryChanged = YES; break; }
		}
		if (queryChanged) break;
	}
	if (!queryChanged) {
		for (id object in deleted) {
			for (Class tracked in trackedClasses) {
				if ([object isKindOfClass:tracked]) { queryChanged = YES; break; }
			}
			if (queryChanged) break;
		}
	}
	if (!queryChanged) {
		for (id object in updated) {
			for (Class tracked in trackedClasses) {
				if ([object isKindOfClass:tracked]) { queryChanged = YES; break; }
			}
			if (queryChanged) break;
		}
	}
	if (!queryChanged) return;

	[self.queryViewDataSource performFetchAll];
	[self.tableView reloadData];
}

- (void)ingnoreManagedObjectContextChanges:(RptqStoreContext *)context {
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSManagedObjectContextObjectsDidChangeNotification
												  object: context];
}

- (void)observeManagedObjectContextChanges:(RptqStoreContext *)context {
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidChange:)
												 name: NSManagedObjectContextObjectsDidChangeNotification
											   object: context];
}

#pragma mark -
#pragma mark UIContentSizeCategoryDidChangeNotification

- (void)handleContentSizeCategoryDidChange:(NSNotification *)notification {
	NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
	[self updateInupdateInterfaceForPerferedContentSizeCategory:contentSize];
	[self.view setNeedsLayout];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
	return nil;
}
- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
	return nil;
}
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
																			presentingController:(UIViewController *)presenting
																				sourceController:(UIViewController *)source {
	return self;
}


- (void)presentationTransitionWillBegin {
	// Add a custom dimming view behind the presented view controller's view
	
	// Use the transition coordinator to set up the animations.
	id <UIViewControllerTransitionCoordinator> transitionCoordinator =
	[[self presentingViewController] transitionCoordinator];
	
	// Fade in the dimming view during the transition.
	[self.tableView.backgroundView setAlpha:0.0];
	[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		 [self.tableView.backgroundView setAlpha:1.0];
	 } completion:nil];
}

- (void)presentationTransitionDidEnd:(BOOL)completed {
	// Remove the dimming view if the presentation was aborted.
	if (!completed) {
		[self.tableView.backgroundView removeFromSuperview];
	}
}
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
/*
	UIViewController *leftViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	BOOL fromIsQueryView = [leftViewController isKindOfClass:[MADQueryViewController class]];
	BOOL pushing = fromIsQueryView;

	UIViewController *rightViewController;
	if (pushing) {
		rightViewController = [transitionContext viewControllerForKey:UITransitionContextToViewKey];
		leftViewController =
	} else {
		rightViewController = leftViewController;
	}
	
	UIView *containerView = transitionContext.containerView;
	UIView *tableViewQuery, *collectionViewGrid;

	UIViewController *leftController = [transitionContext viewControllerForKey: leftCntrollerKey(pushing)];
	UIViewController *toViewController = [transitionContext viewControllerForKey: rightControllerKey(pushing)];

	tableViewQuery = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextFromViewKey : UITransitionContextToViewKey];
	collectionViewGrid = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextToViewKey : UITransitionContextFromViewKey];
	
	CGRect queryFrameInital = [transitionContext initialFrameForViewController:fromViewController];
	
	CGRect toFrameInital = [transitionContext initialFrameForViewController:toViewController];
	CGRect fromFrameFinal = [transitionContext finalFrameForViewController:fromViewController];
	CGRect toFrameFinal = [transitionContext finalFrameForViewController:toViewController];
	
	CGVector offset;
	offset = CGVectorMake(1.f, 0.f);
	[containerView addSubview:toView];

	if (!fromIsQueryView) {
		
	} else {
		toView.frame = CGRectMake(toFrameFinal.origin.x + toFrameFinal.size.width, toFrameFinal.origin.y, toFrameFinal.size.width, toFrameFinal.size.height);
		toFrameFinal = CGRectMake(toFrameFinal.origin.x, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
	}
	
	NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
	if (!fromIsQueryView) {
		
		MADWatermarkView *watermarkView;
		CGRect bounds = self.tableView.bounds;
		watermarkView = [[MADWatermarkView alloc] initWithFrame: bounds];
		watermarkView.alpha = 0.0;
		((UITableView *)toView).backgroundView = watermarkView;

	} else {
		((UITableView *)fromView).alpha = 1.0;
	}
   // toView.frame = toFrameFinal;
	[UIView animateWithDuration:transitionDuration animations:^{
		if (fromIsQueryView) {
			[((UITableView *)fromView).backgroundView setAlpha:0.0];
		} else {
			[((UITableView *)toView).backgroundView setAlpha:1.0];
		}
		//[toView setFrame:self.navigationController.view.bounds];
		
		fromView.frame = CGRectMake(fromFrameFinal.origin.x - fromFrameFinal.size.width, fromFrameFinal.origin.y, fromFrameFinal.size.width, fromFrameFinal.size.height);
		toView.frame = toFrameFinal;
	} completion:^(BOOL finished) {

		BOOL wasCancelled = [transitionContext transitionWasCancelled];
		if (!wasCancelled) {

			if (fromIsQueryView) {
				[((UITableView *)fromView) setBackgroundView:nil];
			}

		}
		[transitionContext completeTransition:!wasCancelled];
	}];*/
}

#pragma mark - UIAccessibility

@end

@interface MADAnimatedTransitioningPop : NSObject <UIViewControllerAnimatedTransitioning>

@end

@implementation MADAnimatedTransitioningPop

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	
	//UIViewController *leftViewController = [transitionContext viewControllerForKey: UITransitionContextToViewControllerKey];
	//UIViewController *rightViewController = [transitionContext viewControllerForKey: UITransitionContextFromViewControllerKey];
	//CGRect leftFrameFinal = [transitionContext finalFrameForViewController:leftViewController];
	//CGRect rightFrameFinal = [transitionContext finalFrameForViewController:rightViewController];
	//CGRect leftFrameInital = [transitionContext initialFrameForViewController:leftViewController];
	//CGRect rightFrameInital = [transitionContext initialFrameForViewController:rightViewController];

	/*
	UIViewController *rightViewController;
	if (pushing) {
		rightViewController = [transitionContext viewControllerForKey:UITransitionContextToViewKey];
		leftViewController =
	} else {
		rightViewController = leftViewController;
	}
	
	UIView *containerView = transitionContext.containerView;
	UIView *tableViewQuery, *collectionViewGrid;
	
	//UIViewController *leftController = [transitionContext viewControllerForKey: leftCntrollerKey(pushing)];
	//UIViewController *toViewController = [transitionContext viewControllerForKey: rightControllerKey(pushing)];
	
	//tableViewQuery = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextFromViewKey : UITransitionContextToViewKey];
	//collectionViewGrid = [transitionContext viewForKey: fromIsQueryView ? UITransitionContextToViewKey : UITransitionContextFromViewKey];
	
	CGRect queryFrameInital = [transitionContext initialFrameForViewController:fromViewController];
	
	leftFrameInital = CGRectMake(leftFrameFinal.origin.x, leftFrameFinal.origin.y, leftFrameFinal.size.width, leftFrameFinal.size.height);
	//[transitionContext initialFrameForViewController:toViewController];
	CGRect fromFrameFinal = [transitionContext finalFrameForViewController:fromViewController];
	CGRect toFrameFinal = [transitionContext finalFrameForViewController:toViewController];
	
	CGVector offset;
	offset = CGVectorMake(1.f, 0.f);
	[containerView addSubview:toView];
	
	if (!fromIsQueryView) {
		
	} else {
		toView.frame = CGRectMake(toFrameFinal.origin.x + toFrameFinal.size.width, toFrameFinal.origin.y, toFrameFinal.size.width, toFrameFinal.size.height);
		toFrameFinal = CGRectMake(toFrameFinal.origin.x, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
	}
	
	NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
	if (!fromIsQueryView) {
		
		MADWatermarkView *watermarkView;
		CGRect bounds = self.tableView.bounds;
		watermarkView = [[MADWatermarkView alloc] initWithFrame: bounds];
		watermarkView.alpha = 0.0;
		((UITableView *)toView).backgroundView = watermarkView;
		
	} else {
		((UITableView *)fromView).alpha = 1.0;
	}*/
	// toView.frame = toFrameFinal;
	[UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
		//if (fromIsQueryView) {
		//    [((UITableView *)fromView).backgroundView setAlpha:0.0];
		//} else {
		//    [((UITableView *)toView).backgroundView setAlpha:1.0];
		//}
		//[toView setFrame:self.navigationController.view.bounds];
		
		//fromView.frame = CGRectMake(fromFrameFinal.origin.x - fromFrameFinal.size.width, fromFrameFinal.origin.y, fromFrameFinal.size.width, fromFrameFinal.size.height);
		//toView.frame = toFrameFinal;
	} completion:^(BOOL finished) {
		
		BOOL wasCancelled = [transitionContext transitionWasCancelled];
		if (!wasCancelled) {
			
		  //  if (fromIsQueryView) {
		  //      [((UITableView *)fromView) setBackgroundView:nil];
		  //  }
			
		}
		[transitionContext completeTransition:!wasCancelled];
	}];
}

@end
