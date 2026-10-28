//
//  MADQueryViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryViewController_Private.h"
#import "MADQueryViewController+BuilderDelegates.h"

NSString * const MADImageBarButtonItemDatabase8 = @"UIBarButtonItemDatabase8";

static NSString * const MADIdentifierDefaultsViewerDesired = @"defaults.everydayapps.features.viewer.desired";

@implementation MADQueryViewController

@synthesize title = _title;
@synthesize document = _document;

#pragma mark -
#pragma mark Static Helpers

+ (void)configureCell: (UITableViewCell *)cell
		   forSection: (MADIdentifierQueryViewSections)section
			   andRow: (NSInteger __unused)row {
	
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

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue * __unused)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController * __unused)fromViewController
							 sender:(nullable id __unused)sender {
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

- (void)viewWillDisappear:(BOOL __unused)animated {
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
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		self.view.frame = self.navigationController.view.bounds;
	} completion:nil];
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
#pragma mark Event handlers

- (void)handleApplicationDidBecomeActive:(id __unused)sender {
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
#pragma mark Actions

- (IBAction)actionToggleDisplay:(id __unused)sender {
}

- (IBAction)edit:(id __unused)sender {
	self.tableView.editing = !self.tableView.isEditing;
}

- (IBAction)done:(id)sender {
	[((MADNavigationController *)self.navigationController) done:sender];
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
	MADQueryViewControllerTableLayout *tableLayout = [[MADQueryViewControllerTableLayout alloc] initWithNumberOfTables:[self.tableView numberOfRowsInSection: 1]
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

- (void)reloadMainDocumentAnimated:(BOOL __unused)animated {
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

- (void)queryDatasource:(NSObject <MADQueryViewControllerDatasourceProtocol> * __unused)datasource
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

- (void)queryViewDelegate:(MADQueryViewDelegate * __unused)delegate handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index {

	NSArray <RptqDatabase *> *results = (NSArray<RptqDatabase *> *)[self.queryViewDataSource.managedObjectContext objectsForEntity:NSStringFromClass([RptqDatabase class])];
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

- (void)operationDidStart:(MADOperation * __unused)operation { }

- (void)operation:(MADOperation * __unused)operation didProduceOperation:(NSOperation * __unused)newOperation { }

- (void)operationDidFinish:(MADOperation * __unused)operation errors:(NSArray<NSError *> *)errors {
	if (errors.count > 0) {
		for (NSError *error in errors) {
			os_log_error(GetDesignerLog(), "%s: Error: %@", __PRETTY_FUNCTION__, error);
		}
	}
}

- (void)operationQueue:(MADOperationQueue * __unused)operationQueue
	  willAddOperation:(NSOperation * __unused)operation { }

- (void)operationQueue:(MADOperationQueue *)operationQueue
	operationDidFinish:(NSOperation *)operation
			withErrors:(NSArray<NSError *> * __unused)errors {
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
#pragma mark Store Context Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
	if (_suspendAutomaticTrackingOfChangesInManagedObjectContext) return;

	NSDictionary *userInfo = notification.userInfo;
	NSSet *inserted = userInfo[RptqStoreContextInsertedObjectsKey];
	NSSet *deleted = userInfo[RptqStoreContextDeletedObjectsKey];
	NSSet *updated = userInfo[RptqStoreContextUpdatedObjectsKey];

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
													name: RptqStoreContextObjectsDidChangeNotification
												  object: context];
}

- (void)observeManagedObjectContextChanges:(RptqStoreContext *)context {
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidChange:)
												 name: RptqStoreContextObjectsDidChangeNotification
											   object: context];
}

#pragma mark -
#pragma mark UIContentSizeCategoryDidChangeNotification

- (void)handleContentSizeCategoryDidChange:(NSNotification *)notification {
	NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
	[self updateInupdateInterfaceForPerferedContentSizeCategory:contentSize];
	[self.view setNeedsLayout];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning> __unused)animator {
	return nil;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning> __unused)animator {
	return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController * __unused)dismissed {
	return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController * __unused)presented
																			presentingController:(UIViewController * __unused)presenting
																				sourceController:(UIViewController * __unused)source {
	return self;
}

- (void)presentationTransitionWillBegin {
	id <UIViewControllerTransitionCoordinator> transitionCoordinator =
	[[self presentingViewController] transitionCoordinator];
	
	[self.tableView.backgroundView setAlpha:0.0];
	[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self.tableView.backgroundView setAlpha:1.0];
	} completion:nil];
}

- (void)presentationTransitionDidEnd:(BOOL)completed {
	if (!completed) {
		[self.tableView.backgroundView removeFromSuperview];
	}
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning> __unused)transitionContext {
	return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning> __unused)transitionContext {
}

@end
