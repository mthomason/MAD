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
#import "MTStoreKitController+Features.h"
#import "MADWatermarkView.h"
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
#import "NSAttributedString+QueryViewController.h"
#import "MADViewTableHeader+QueryViewSectionTypes.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MADQueryViewDelegate.h"
#import "MADTabBarItemProtocol.h"
#import "MADQueryViewDatasourceProtocol.h"
#import "MADOperationGetCredentials.h"
#import "madlog.h"


#import <MADAPI/MADQuery.h>

#import <MADAPI/MADQuery.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MADCocoaExtensions/NSParagraphStyle+CommonStyles.h>

#import <MAD/MADocument.h>
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

NSString * const MADImageBarButtonItemDatabase                      = @"UIBarButtonItemDatabase";
NSString * const MADImageBarButtonItemDatabase8                     = @"UIBarButtonItemDatabase8";

static NSString * const NSFetchedResultsCacheName                   = @"NSFetchedResultsCacheName";
static NSString * const NSFetchedResultsCacheTables                 = @"NSFetchedResultsCacheTables";
static NSString * const NSFetchedResultsCacheLinks                  = @"NSFetchedResultsCacheLinks";
static NSString * const NSFetchedResultsCacheGroups                 = @"NSFetchedResultsCacheGroups";
static NSString * const NSFetchedResultsCachePredicates             = @"NSFetchedResultsCachePredicates";

static NSString * const MADIdentifierDefaultsViewerDesired = @"defaults.everydayapps.features.viewer.desired";

//static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL);
//static inline UITransitionContextViewControllerKey rightControllerKey(BOOL);
BOOL storeEnabled(void);

//static inline UITransitionContextViewControllerKey leftCntrollerKey(BOOL pushing) {
//	return pushing ? UITransitionContextFromViewControllerKey :
//					 UITransitionContextToViewControllerKey;
//}
//static inline UITransitionContextViewControllerKey rightControllerKey(BOOL pushing) {
//	return pushing ? UITransitionContextToViewControllerKey :
//					 UITransitionContextFromViewControllerKey;
//}

BOOL storeEnabled(void) {
	return [MTStoreKitController sharedObject].reportingEnabled;
}

#pragma mark - Private Category

@interface MADQueryViewController () <NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate, MADOperationQueueDelegate, MADOperationObserver, MADQueryViewDelegateProtocol, MADQueryViewControllerLayoutSectionSelectorProtocol, MADQueryBuilderAddTableDelegate, MADQueryBuilderAddGroupDelegate, MADViewControllerStandardProtocol, MADQueryBuilderLinkBuilderDelegate, MADViewControllerStandardProtocol, MADDesignerSectionLayoutDelegate, MADQueryBuilderPredicateFormatDelegate, MADQueryViewControllerDatasourceProtocol>

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
			[switchQueryMode addTarget: nil action: @selector(handleToggleReportingMode:)
					  forControlEvents: UIControlEventValueChanged];
			cell.accessoryView = switchQueryMode;
			cell.textLabel.text = switchQueryMode.on ? NSLocalizedString(@"Reporting Mode", @"Reporting Mode") : NSLocalizedString(@"Designer Mode (limited)", @"Designer Mode (limited)");
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

+ (void)deleteCoreDataCache {
	[NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
	[NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
	[NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
	[NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
	[NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
}

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
	
	self = [super initWithCoder:aDecoder];
	if (!self) return nil;

	_showingTableIndex = -1;

	_firstTimeViewWillLayoutSubviews = NO;

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
	
	return self;
}

#pragma mark -
#pragma mark Storyboard

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController *)fromViewController
						 withSender:(id)sender {
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
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear: animated];
	
	UIManagedDocument *document;
	NSManagedObjectContext *managedObjectContext;
	
	document = _document;
	managedObjectContext = document.managedObjectContext;

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleDocumentStateChanged)
												 name: UIDocumentStateChangedNotification
											   object: document];
	
	SEL handleContentSizeCategoryDidChange = @selector(handleContentSizeCategoryDidChange:);
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: handleContentSizeCategoryDidChange
												 name: UIContentSizeCategoryDidChangeNotification
											   object: nil];
	
	SEL resultHandler = @selector(handleApplicationDidBecomeActive:);
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: resultHandler
												 name: UIApplicationDidBecomeActiveNotification
											   object: nil];
	
	[self observeManagedObjectContextChanges: managedObjectContext];
	
	[self.tabBarController enableTabBarItems];
	
	self.tableView.delegate = _queryViewDelegate;
	[self reloadMainDocumentAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:YES];
	
	UIManagedDocument *document;
	NSManagedObjectContext *managedObjectContext;

	document = _document;
	managedObjectContext = document.managedObjectContext;
	
	[self ingnoreManagedObjectContextChanges: managedObjectContext];
	
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
		CGRect r = CGRectMake(CGPointZero.x, CGPointZero.y,
							  self.tableView.frame.size.width, 1.0);
		[self.tableView scrollRectToVisible: r animated: NO];
		_firstTimeViewWillLayoutSubviews = NO;
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.view.frame = self.navigationController.view.bounds;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
	}];
	
}

#pragma mark -
#pragma mark Operations

- (NSArray <NSIndexPath *> *)tableView:(UITableView *)tableView
						   deleteLinks:(NSManagedObjectID *)relatedTableObjectID
							   section:(NSInteger)section
							   context:(NSManagedObjectContext *)context {
	NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
	
	NSFetchedResultsController *fetchedLinkes = self.queryViewDataSource.queryLinksController;
	
	NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
	
	for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
		NSIndexPath *linkIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		NSError *error = NULL;
		NSManagedObject *object = nil;
		MADTableViewCellQueryLink *cell;
		cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:linkIndexPath];
		if (cell) {
			object = [context existingObjectWithID:cell.linkID error:&error];
		} else {
			
			id <NSFetchedResultsSectionInfo> sectionInfo = fetchedLinkes.sections[0];
			if (row < (NSInteger)sectionInfo.numberOfObjects) {
				NSIndexPath *testLinkIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
				object = [fetchedLinkes objectAtIndexPath:testLinkIndexPath];
			}
			
		}
		if (!error && object && [object isKindOfClass:[RptqQueryLinks class]]) {
			RptqQueryLinks *queryLink = (RptqQueryLinks *)object;
			if ([queryLink.hasLeftField.inQueryTable.objectID isEqual:relatedTableObjectID] ||
				[queryLink.hasRightField.inQueryTable.objectID isEqual:relatedTableObjectID]) {
				[context deleteObject:queryLink];
				[cellsToDelete addObject:linkIndexPath];
			}
		}
	}
	return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)tableView:(UITableView *)tableView
						  deleteGroups:(NSManagedObjectID *)relatedTableObjectID
							   section:(NSInteger)section
							   context:(NSManagedObjectContext *)context {
	NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
	NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
	for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
		NSIndexPath *groupIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		NSError *error = nil;
		
		id <NSFetchedResultsSectionInfo> sectionInfo;
		sectionInfo = (self.queryViewDataSource.queryGroupsController.sections)[0];
		if (row < (NSInteger)sectionInfo.numberOfObjects) {
			
			NSIndexPath *testGroupIndexPath;
			testGroupIndexPath = [NSIndexPath indexPathForRow: row inSection: 0];
			NSManagedObject *object;
			object = [self.queryViewDataSource.queryGroupsController objectAtIndexPath:testGroupIndexPath];
			
			if (!error && object && [object isKindOfClass:[RptqQueryGroup class]]) {
				
				RptqQueryGroup *groupToRemove = (RptqQueryGroup *)object;
				if ([groupToRemove.hasField.inQueryTable.objectID isEqual:relatedTableObjectID]) {
					[self.document removeGroupWitObjectID: groupToRemove.objectID
								 fromManagedObjectContext: context];
					[cellsToDelete addObject:groupIndexPath];
				}
				
			}
			
		}
	}
	return cellsToDelete;
}

- (NSArray <NSIndexPath *> *)tableView:(UITableView *)tableView
					  deletePredicates:(NSManagedObjectID *)relatedTableObjectID
							   section:(NSInteger)section
							   context:(NSManagedObjectContext *)context {
	NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
	NSMutableArray <__kindof NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];

	for (NSInteger row = 0; row < numberOfRowsInSection; row++) {

		NSIndexPath *predicateIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		
		MADTableViewCellQueryPredicate *cell;
		cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:predicateIndexPath];
		NSError *error = nil;
		NSManagedObject *object = nil;
		
		if (cell) {
			object = [context existingObjectWithID: cell.predicateID
											 error: &error];
		} else {
			NSIndexPath *testPredicateIndexPath = [NSIndexPath indexPathForRow: row
																	 inSection: 0];
			object = [self.queryViewDataSource.queryPredicatesController objectAtIndexPath: testPredicateIndexPath];
		}
		
		if (!error && object && [object isKindOfClass:[RptqQueryPredicate class]]) {
		
			RptqQueryPredicate *predicateToRemove = (RptqQueryPredicate *)object;

			BOOL deleted = NO;
			if ([predicateToRemove.hasLeftField.inQueryTable.objectID isEqual:relatedTableObjectID]) {

				[context deleteObject:predicateToRemove];
				
				NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
				[cellsToDelete addObject:deleteCellAtIndex];
				deleted = YES;
			}
			
			if (!deleted) {
				if ([predicateToRemove.hasRightField.inQueryTable.objectID isEqual:relatedTableObjectID]) {
				
					[context deleteObject:predicateToRemove];

					NSIndexPath *deleteCellAtIndex = predicateIndexPath.copy;
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
	MADocument * __weak weakDocument = document;
	[self ingnoreManagedObjectContextChanges:document.managedObjectContext];

	_suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
	
	NSManagedObjectContext *private;
	private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	
	typeof(self) __weak weakself = self;
	[private performBlockAndWait:^{
		typeof(self) strongself = weakself;
		MADocument *strongDocument = weakDocument;
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
		
		NSUInteger numberOfTables = rptqQuery.hasQueryTables.count;
		
		BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;
		MADQueryViewDataSource *oldQueryLayout, *newQueryLayout;
		oldQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
															   reportingEnabled: reportingEnabled
															handleConfigureCell: nil];
		
		newQueryLayout = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables - 1
															   reportingEnabled: reportingEnabled
															handleConfigureCell: nil];
		
		NSIndexSet *indexSetSectionsOld = oldQueryLayout.sectionTypesIndexs;
		NSMutableIndexSet *indexSetSectionsOldM = indexSetSectionsOld.mutableCopy;
		[indexSetSectionsOldM removeIndexes:newQueryLayout.sectionTypesIndexs];
		
		NSMutableSet *deletedSectionTypes = oldQueryLayout.sectionTypes.mutableCopy;
		[deletedSectionTypes minusSet:newQueryLayout.sectionTypes];
		
		NSIndexPath *tableIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 0];
		NSIndexPath *displayIndex = [NSIndexPath indexPathForRow: indexPath.row inSection: 1];
		RptqQueryTable *table = [strongself.queryViewDataSource.queryTablesController objectAtIndexPath: tableIndex];
		
		NSManagedObjectID *deleatedTableObjectId = table.objectID.copy;
		
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
		
		[strongDocument deleteDatafieldsRelatedToTable:deleatedTableObjectId inContent:private];
		[strongDocument deleteAggregateFieldRelatedToTable:deleatedTableObjectId inContent:private];
		
		NSMutableArray <NSIndexPath *> *cellsToDelete = [[NSMutableArray alloc] init];
		
		short numberOfSections = strongself.queryViewDataSource.count;
		
		for (short section = 0; section < numberOfSections; section++) {
			
			NSArray <NSIndexPath *> *cells = nil;
			
			switch ([strongself.queryViewDataSource sectionAtIndex:section]) {
				case MADIdentifierQueryViewSectionsLinks:
					cells = [strongself tableView: tableView
									  deleteLinks: deleatedTableObjectId
										  section: (NSInteger)section
										  context: private];
					break;
					
				case MADIdentifierQueryViewSectionsGroups:
					cells = [strongself tableView: tableView
									 deleteGroups: deleatedTableObjectId
										  section: (NSInteger)section
										  context: private];
					break;
					
				case MADIdentifierQueryViewSectionsPredicate:
					cells = [strongself tableView: tableView
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
		rptqQuery.hasQueryTables = hasQueryTables.copy;
		[private deleteObject:objectToDelete];
		numberOfTables--;
		
		NSError * __autoreleasing error = NULL;
		BOOL success = NO;
		if (!(success = [private save:&error])) {
			os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
		} else {
			[strongself.queryViewDataSource numberOfTablesChanged: numberOfTables];

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

			[strongself.tableView endUpdates];
			
			[strongself observeManagedObjectContextChanges:private];
			strongself->_suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
		}
	}];
	NSError * __autoreleasing error = NULL;
	BOOL success = NO;
	if (!(success = [document.managedObjectContext save:&error])) {
		os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
	}
	[self observeManagedObjectContextChanges:document.managedObjectContext];
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

- (void)deleteQueryLinksFromTableView: (UITableView *)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	UIManagedDocument *document = self.document;
	MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
	NSManagedObjectID *tableID = cell.linkID;
	NSManagedObjectContext *private;
	private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	
	[private performBlockAndWait:^{
		
		NSManagedObject *objectToDelete = [private objectWithID:tableID];
		NSAssert(objectToDelete != nil, @"Need a non-nil value for %@", tableID);
		[private deleteObject:objectToDelete];
		
		NSError * __autoreleasing error = NULL;
		BOOL successSave = NO;
		if (!(successSave = [private save:&error])) {
			os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
		}
	}];
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

- (void)deleteQueryGroupFromTableView: (UITableView *)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	
	UIManagedDocument *document = self.document;
	NSManagedObjectContext *private;
	private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	
	typeof(self) __weak weakself = self;
	[private performBlockAndWait:^{
		typeof(self) strongself = weakself;
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
		RptqQueryGroup *groupToRemove = [rptqQuery queryGroupForIndex:(NSUInteger)indexPath.row];
		[strongself.document removeGroupWitObjectID:groupToRemove.objectID fromManagedObjectContext:private];
		
		NSError * __autoreleasing error = NULL;
		BOOL successSave = NO;
		if (!(successSave = [private save:&error])) {
			os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
		}
	}];
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL successAutosave) { }];
}

- (void)deleteQueryPredicateFromTableView: (UITableView *)tableView
							  atIndexPath: (NSIndexPath *)indexPath {
	MADocument *document = self.document;
	MADTableViewCellQueryPredicate *cell;
	cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath];
	NSManagedObjectID *objid = cell.predicateID;
	NSManagedObject *predicate = [document.managedObjectContext objectWithID:objid];
	[document.managedObjectContext deleteObject:predicate];
	NSError *error = NULL;
	if ([document.managedObjectContext save:&error])
		NSLog(@"Error saving managed object context: %@", error);
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

- (void)viewController:(MADQueryPredicateFormatController *)controller
   addedQueryPredicate:(RptqQueryPredicate *)predicate {
	[self dismissViewController];
}

#pragma mark -
#pragma mark MADQueryBuilderLinkBuilderDelegate

- (void)viewController:(MADQueryLinkBuilderController *)controller
		addedQueryLink:(NSManagedObjectID *)linkID {
	
	[self dismissViewController];
	
	NSInteger suspectedSection = 2;
	
	MADIdentifierQueryViewSections tableSection;
	tableSection = [self.queryViewDataSource sectionAtIndex:(short)suspectedSection];
	
	if (tableSection == MADIdentifierQueryViewSectionsLinks) {
		[self.tableView reloadSections: [NSIndexSet indexSetWithIndex:(NSUInteger)suspectedSection]
					  withRowAnimation: UITableViewRowAnimationAutomatic];
	}
	
	//[document saveToURL: document.fileURL
	//   forSaveOperation: UIDocumentSaveForOverwriting completionHandler:nil];
}

#pragma mark -
#pragma mark MADQueryBuilderAddGroupDelegate

- (void)viewController:(MADQueryBuilderAddGroupViewController *)vc addedGroupOnQueryField:(NSManagedObjectID *)objectID
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

- (void)viewController:(MADQueryBuilderAddTableViewController *)vc addedQueryTableWithID:(NSManagedObjectID *)objectID {
	
	MADocument *document = self.document;
	typeof(self) __weak weakself = self;
	
	[self dismissViewController];
	
	_suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
	
	NSManagedObjectContext *private;
	private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	[private performBlockAndWait: ^{
		typeof(self) strongself = weakself;
		
		
		RptqDatabaseSchemaTable *schemaTable = [private objectWithID:objectID];
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *query = rptqDatabase.hasQueries.anyObject;

		NSUInteger numberOfTablesOld = query.hasQueryTables.count;
		NSUInteger numberOfTables = numberOfTablesOld + 1;
		BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;

		RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
																		   database: rptqDatabase
															forManagedObjectContext: private];
		
		NSMutableSet <RptqQueryTable *> *tablesInQuery;
		NSMutableSet <RptqQueryField *> *newQueryFields;
		tablesInQuery = query.hasQueryTables.mutableCopy;
		newQueryFields = [[NSMutableSet alloc] initWithCapacity: schemaTable.hasFields.count];
		
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
		
		NSError * __autoreleasing error = NULL;
		if (![private save:&error]) {
			os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s",
						error.localizedDescription.UTF8String);
		} else {
			error = NULL;
			NSManagedObjectContext *parentContext = [private parentContext];
			[parentContext performBlockAndWait:^{
				NSError * __autoreleasing errorParent = NULL;
				if (![parentContext save:&errorParent]) {
					os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s",
								errorParent.localizedDescription.UTF8String);
				}
			}];
			[strongself.queryViewDataSource numberOfTablesChanged: numberOfTables];
			[strongself.queryViewDataSource performFetchTables];

			NSUInteger tableIndex = [strongself.queryViewDataSource.queryTablesController.fetchedObjects indexOfObjectPassingTest:^BOOL(RptqQueryTable *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				return newQueryTable.identifier == obj.identifier;
			}];
			
			NSIndexSet *indexSetSections = [self newSectionsTableCountStart: numberOfTablesOld
															  tableCountEnd: numberOfTables
														   reportingEnabled: reportingEnabled];
			
			[self tableView: strongself.tableView insertTable:tableIndex andSection:indexSetSections];

		}
		[private refreshObject:newQueryTable mergeChanges:NO];
		
		for (RptqQueryField *field in newQueryFields) {
			RptqQueryTable *table = field.inQueryTable;
			if (field.inQueryTable != nil) {
				[private refreshObject: table mergeChanges:NO];
			}
			RptqDatabaseSchemaField *schemaField = field.databaseSchemaField;
			[private refreshObject: schemaField    mergeChanges:NO];
			[private refreshObject: field          mergeChanges:NO];
		}
		
		for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
			[private refreshObject:field mergeChanges:NO];
		}
		
		[private refreshObject:query mergeChanges:NO];
		[private refreshObject:rptqDatabase mergeChanges:NO];
		[private refreshObject:rptqDocument mergeChanges:NO];
		
		[tablesInQuery removeAllObjects];
		[newQueryFields removeAllObjects];
		
	}];
	
	NSError * __autoreleasing error = NULL;
	if (![document.managedObjectContext save:&error]) {
		os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
	}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL success) {
		[self.queryViewDataSource performFetchTables];
	}];
	_suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
	
}

- (void)tableView:(UITableView *)tableView
	  insertTable:(NSUInteger)tableIndex
	   andSection:(NSIndexSet *)sections {
	
	NSArray <NSIndexPath *> *tablePaths;
	NSIndexPath *tablePath = [NSIndexPath indexPathForRow: (NSInteger)tableIndex
												inSection: 1];
	tablePaths = [[NSArray <NSIndexPath *> alloc] initWithObjects: tablePath, nil];
	
	[tableView beginUpdates];
	[tableView insertRowsAtIndexPaths: tablePaths
					 withRowAnimation: UITableViewRowAnimationAutomatic];
	if (sections.count > 0) {
		[tableView insertSections: sections
				 withRowAnimation: UITableViewRowAnimationAutomatic];
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
		NSString *title = NSLocalizedString(@"MAD Query", @"View controller title.");
		_title = title;
	}
	return _title;
}

- (MADQueryViewDataSource *)queryViewDataSource {

	if (_queryViewDataSource == nil) {

		MADocument *document = _document;
		NSManagedObjectContext *managedObjectContext;
		NSNumber *objectID;

		managedObjectContext = document.documentModel.managedObjectContext;
		objectID = document.documentModel.databases.firstObject.queries.firstObject.objectID.copy;
		
		
		BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;
		MADQueryViewDataSource *dataSource;
		dataSource = [[MADQueryViewDataSource alloc] initWithQueryID: objectID
												managedObjectContext: managedObjectContext
													reportingEnabled: reportingEnabled
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
	[document.activeDocumentModel setHeight: height
							forSectionAtRow: _lastSelectedRowNumber];
	[document saveContext];
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {

	MADocument *document = self.document;
	[document.activeDocumentModel setVisibility: isVisible
								forSectionAtRow: _lastSelectedRowNumber];
	[document saveContext];
}

- (void)layoutSettings:(MADDesignerSectionLayoutController *)layoutSettings
		  newPageAfter:(BOOL)newPageAfter {

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
		if ([MTStoreKitController sharedObject].isReportingEnabled) {
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
#pragma mark NSFetchedResultsControllerDelegate

- (NSMutableArray *)sectionsUsedByFetchedResultsController:(NSFetchedResultsController *)controller {
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity: 3];

	NSNumber *sectionNumber;
	if ([controller isEqual:self.queryViewDataSource.queryTablesController]) {
		
		sectionNumber = [[NSNumber alloc] initWithShort: [self sectionIndexForTables]];
		[result addObject: sectionNumber];

	} else if ([controller isEqual:self.queryViewDataSource.queryLinksController]) {

		sectionNumber = [[NSNumber alloc] initWithShort: [self sectionIndexForLinks]];
		[result addObject: sectionNumber];

	} else if ([controller isEqual:self.queryViewDataSource.queryGroupsController]) {

		sectionNumber = [[NSNumber alloc] initWithShort: [self sectionIndexForGroups]];
		[result addObject: sectionNumber];
	
	} else if ([controller isEqual:self.queryViewDataSource.queryPredicatesController]) {

		sectionNumber = [[NSNumber alloc] initWithShort:[self sectionIndexForPredicate]];
		[result addObject: sectionNumber];
	}
	
	return result;

}

- (void)controller: (NSFetchedResultsController *)controller didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex: (NSUInteger)sectionIndex forChangeType: (NSFetchedResultsChangeType)type {
	NSMutableArray<NSNumber *> *sections = [self sectionsUsedByFetchedResultsController: controller];
	NSNumber *section;
	
	if (sections.count <= 0) return;
	
	for (section in sections) {

		if (!_suspendAutomaticTrackingOfChangesInManagedObjectContext) {

			switch(type) {
				case NSFetchedResultsChangeInsert: {
					NSAssert(section.shortValue >= 0, @"Expect section to be a positive integer.");
					NSIndexSet *updatedIndex = [NSIndexSet indexSetWithIndex: (NSUInteger)section.shortValue];
					[self.tableView insertSections: updatedIndex
									withRowAnimation: UITableViewRowAnimationFade];
					break;
				}
					
				case NSFetchedResultsChangeDelete: {
					NSAssert(section.shortValue >= 0, @"Expect section to be a positive integer.");
					NSIndexSet *updatedIndex = [NSIndexSet indexSetWithIndex: (NSUInteger)section.shortValue];
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


- (void)controller: (NSFetchedResultsController *)controller
   didChangeObject: (id)anObject
	   atIndexPath: (NSIndexPath *)indexPath
	 forChangeType: (NSFetchedResultsChangeType)type
	  newIndexPath: (NSIndexPath *)newIndexPath {
	if (_suspendAutomaticTrackingOfChangesInManagedObjectContext) return;
	
	NSMutableArray *sections = [self sectionsUsedByFetchedResultsController: controller];
	
	NSArray *indexPaths;
	NSIndexPath *path;
	NSNumber *section;
	for (section in sections) {
		switch(type) {
			case NSFetchedResultsChangeInsert: {
				path = [NSIndexPath indexPathForRow: (long)[controller.fetchedObjects indexOfObject: anObject]
										  inSection: section.shortValue];
				indexPaths = [[NSArray alloc] initWithObjects: path, nil];
				[self.tableView insertRowsAtIndexPaths: indexPaths
									  withRowAnimation: UITableViewRowAnimationFade];
				break;
			}
			case NSFetchedResultsChangeDelete: {
				path = [NSIndexPath indexPathForRow: indexPath.row
										  inSection: section.shortValue];
				indexPaths = [[NSArray alloc] initWithObjects: path, nil];
				[self.tableView deleteRowsAtIndexPaths: indexPaths
									  withRowAnimation: UITableViewRowAnimationFade];
				break;
			}
			case NSFetchedResultsChangeUpdate: {
				path = [NSIndexPath indexPathForRow: indexPath.row
										  inSection: section.shortValue];
				indexPaths = [[NSArray alloc] initWithObjects: path, nil];
				[self.tableView reloadRowsAtIndexPaths: indexPaths
									  withRowAnimation: UITableViewRowAnimationFade];
				break;
			}
			case NSFetchedResultsChangeMove: {
				path = [NSIndexPath indexPathForRow: indexPath.row
										  inSection: section.shortValue];
				indexPaths = [[NSArray alloc] initWithObjects: path, nil];
				[self.tableView deleteRowsAtIndexPaths: indexPaths
									  withRowAnimation: UITableViewRowAnimationFade];
				[self.tableView insertRowsAtIndexPaths: indexPaths
									  withRowAnimation: UITableViewRowAnimationFade];
				break;
			}
		}
	}
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	if (!_suspendAutomaticTrackingOfChangesInManagedObjectContext) {
		[self.tableView beginUpdates];
		_beganUpdates = YES;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (_beganUpdates) {
		[self.tableView endUpdates];
	}
	_beganUpdates = NO;
}

#pragma mark -
#pragma mark MTTabBarImageProtocol

+ (UIImage *)TabBarImage {
	return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

#pragma mark -
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
											(UIPresentationController *)controller {
	
	UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
	if ([controller isEqual:self.showSQLPresentationController]) {
		
		if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			style = UIModalPresentationNone;
		} else {
			style = UIModalPresentationOverFullScreen;
		}
	}
	
	return style;
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
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQuery" bundle:nil];
	UINavigationController *navigationController;
	navigationController = [storyboard instantiateViewControllerWithIdentifier:@"MADQuerySQLNavigationController"];
	navigationController.modalPresentationStyle = UIModalPresentationPopover;
	MADViewControllerSQL *viewController;
	viewController = (MADViewControllerSQL *)navigationController.topViewController;
	viewController.document = self.document;
	viewController.delegate = self;
	UIPopoverPresentationController *ppc = navigationController.popoverPresentationController;
	ppc.backgroundColor = [UIColor clearColor];
	ppc.delegate = self;
	ppc.barButtonItem = sender;
	
	self.showSQLPresentationController = ppc;
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addTable:(id)sender {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddTable" bundle:nil];
	UINavigationController *navigationController;
	navigationController = [storyboard instantiateInitialViewController];
	navigationController.modalPresentationStyle =
				self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
														UIModalPresentationFormSheet :
														UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	
	
	MADQueryBuilderAddTableViewController *tvc;
	tvc = (MADQueryBuilderAddTableViewController *)navigationController.topViewController;
	tvc.delegate = self;
	tvc.managedObjectContext = self.document.managedObjectContext;
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addLink:(id)sender {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddJoin" bundle:nil];
	UINavigationController *navigationController;
	navigationController = [storyboard instantiateInitialViewController];
	navigationController.modalPresentationStyle =
				self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
														UIModalPresentationFormSheet :
														UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	MADQueryLinkBuilderController *tvc;
	tvc = (MADQueryLinkBuilderController *)navigationController.topViewController;
	tvc.queryLinkDelegate = self;
	tvc.document = self.document;
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addPredicate:(id)sender {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddPredicate" bundle:nil];
	UINavigationController *navigationController;
	navigationController = [storyboard instantiateInitialViewController];
	navigationController.modalPresentationStyle =
				self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
														UIModalPresentationFormSheet :
														UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	MADQueryPredicateFormatController *tvc;
	tvc = (MADQueryPredicateFormatController *)navigationController.topViewController;
	tvc.delegate = self;
	tvc.document = self.document;
	[self presentViewController:navigationController animated:YES completion:^{
		[self.tabBarController disableTabBarItems];
	}];
}

- (void)addGroup:(id)sender {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQueryAddGroup" bundle:nil];
	UINavigationController *navigationController;
	navigationController = [storyboard instantiateInitialViewController];
	navigationController.modalPresentationStyle =
				self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
														UIModalPresentationFormSheet :
														UIModalPresentationOverFullScreen;
	UIPresentationController *pc = navigationController.presentationController;
	pc.delegate = self;
	MADQueryBuilderAddGroupViewController *tvc;
	tvc = (MADQueryBuilderAddGroupViewController *)navigationController.topViewController;
	tvc.delegate = self;
	tvc.document = self.document;
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
	NSInteger numberOfRows = [self.tableView numberOfRowsInSection: 1];
	MADQueryViewControllerTableLayout *tableLayout  = [[MADQueryViewControllerTableLayout alloc] initWithNumberOfTables:numberOfRows
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
	self.queryViewDataSource.queryTablesController.delegate = self;
	self.queryViewDataSource.queryLinksController.delegate = self;
	self.queryViewDataSource.queryGroupsController.delegate = self;
	self.queryViewDataSource.queryPredicatesController.delegate = self;

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
	MADIdentifierQueryViewSections sectionIdentifier;
	sectionIdentifier = [self.queryViewDataSource sectionAtIndex:displayIndex];
	return sectionIdentifier;
}

- (MADQueryViewSectionDelegate *)sectionLayoutForDisplayIndex:(short)displayIndex {
	id queryViewSectionDelegate = [self.queryViewDataSource layoutAtIndex:displayIndex];
	return queryViewSectionDelegate;
}

- (CGFloat)headerHeight {
	return _headerSectionHeight;
}

- (void)queryViewDelegate:(MADQueryViewDelegate *)delegate handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index {

	NSString *ownedByUser = NSStringFromSelector(@selector(ownedByUser));
	NSString *entityName = NSStringFromClass([RptqDatabase class]);
	NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:entityName];
	fr.fetchLimit = 1;
	fr.relationshipKeyPathsForPrefetching = @[ownedByUser];
	fr.resultType = NSManagedObjectResultType;

	NSError *error = nil;
	NSArray <RptqDatabase *> *results = [self.queryViewDataSource.managedObjectContext executeFetchRequest:fr error:&error];
	if (error != nil) {
		os_log_error(GetDesignerLog(), "%s Error fetching NSArray <RptqDatabase *>: %@", __PRETTY_FUNCTION__, error);
	}

	RptqDatabaseCredentals *databaseCredentals = ((RptqDatabase *) results.firstObject).ownedByUser;

	MADDatabaseConnection *databaseConnection;
	databaseConnection = [MADDatabaseConnection newDatabaseConnection:databaseCredentals];
	
	MADOperationGetCredentials *operationGetCredentials;
	operationGetCredentials = [[MADOperationGetCredentials alloc] initWithDatabaseConnection:databaseConnection
																			  viewController:self];
	self.credentailsQueue.maxConcurrentOperationCount = 1;
	[self.credentailsQueue addOperation:operationGetCredentials];
	
	_showingTableIndex = index;
}

- (void)finishUserRequestForSampleData:(MADCredential *)credentials {
	NSIndexPath *indexPathUpdate;
	MADTableController *tableController;
	
	RptqQueryTable *table;
	
	NSFetchedResultsController *queryTablesResultsController;
	MADQueryViewDataSource *queryViewDataSource;
	
	indexPathUpdate = [NSIndexPath indexPathForRow: self.showingTableIndex inSection: 0];
	self.showingTableIndex = -1;
	
	queryViewDataSource = self.queryViewDataSource;
	queryTablesResultsController = queryViewDataSource.queryTablesController;
	
	table = [queryTablesResultsController objectAtIndexPath: indexPathUpdate];
	
	MADDatabaseConnection *databaseConnection;
	databaseConnection = [MADDatabaseConnection newDatabaseConnection:table.databaseSchemaTable.inDatabase.ownedByUser];
	
	MADDatabase *db = [MADDatabase newDatabaseWithConnection:databaseConnection];
	
	MADQuery <MADQueryDatabaseProtocol, MADQueryCredentialProtocol> *rquery;
	rquery = (MADQuery <MADQueryDatabaseProtocol, MADQueryCredentialProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeSampleDataTable
																											 object: table.databaseSchemaTable];
	rquery.credential = credentials.copy;
	if ([rquery conformsToProtocol:@protocol(MADDatabaseResultsProtocol)]) {
		db.delegate = ((NSObject <MADDatabaseResultsProtocol> *)rquery);
	}
	
	tableController = [[MADTableController alloc] initWithQuery:rquery
													   database:db
														tableID:table.databaseSchemaTable.objectID];
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

}

- (void)operationQueue:(MADOperationQueue *)operationQueue
	  willAddOperation:(NSOperation *)operation { }

- (void)operationQueue:(MADOperationQueue *)operationQueue
	operationDidFinish:(NSOperation *)operation
			withErrors:(NSArray<NSError *> *)errors {
	if (_showingTableIndex >= 0 && [operationQueue isKindOfClass:[MADOperationQueue class]] &&
		[operation isKindOfClass:[MADOperationGetCredentials class]]) {
		
		MADCredential *credentials = ((MADOperationGetCredentials *)operation).credentials;
		__weak typeof(self) wself = self;
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			typeof(self) sself = wself;
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
	
	NSDictionary *userInfo = notification.userInfo;
	NSSet *updatedObjects = userInfo[NSUpdatedObjectsKey];
	
	for (id updatedObject in updatedObjects) {
		
		// Update the query view controller data model when number of tables change.
		if ([updatedObject isKindOfClass:[RptqQuery class]]) {
			
			RptqQuery *query;
			NSDictionary <NSString *, id> *changes;

			query = updatedObject;
			changes = [query changedValues];
			
			NSString *selectorHasQueryTables = NSStringFromSelector(@selector(hasQueryTables));
			//BOOL reportingEnabled = [MTStoreKitController sharedObject].reportingEnabled;
			//NSUInteger numberOfTables = query.hasQueryTables.count;
			for (id change in changes) {
				if ([change isEqualToString: selectorHasQueryTables]) {
					
					//MADQueryViewDataSource *dataSource;
					//dataSource = [[MADQueryViewDataSource alloc] initWithNumberOfTables: numberOfTables
					//                                                   reportingEnabled: reportingEnabled
					//                                                handleConfigureCell: _handleConfigureCell];
					//dataSource.datasoruce = self;
					//self.tableView.dataSource = dataSource;
					//self.queryViewDataSource.datasoruce = nil;
					//self.queryViewDataSource = dataSource;
					
				}
			}
		}
	}
}

- (void)ingnoreManagedObjectContextChanges:(NSManagedObjectContext *)context {
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSManagedObjectContextObjectsDidChangeNotification
												  object: context];
}

- (void)observeManagedObjectContextChanges:(NSManagedObjectContext *)context {
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidChange:)
												 name: NSManagedObjectContextObjectsDidChangeNotification
											   object: context];
}

#pragma mark -
#pragma mark UIContentSizeCategoryDidChangeNotification

- (void)handleContentSizeCategoryDidChange:(NSNotification *)notification {
	NSLog(@"%s", __PRETTY_FUNCTION__);

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
	//[[self containerView] addSubview:_dimmingView];
	//[_dimmingView addSubview:[[self presentedViewController] view]];
	
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
