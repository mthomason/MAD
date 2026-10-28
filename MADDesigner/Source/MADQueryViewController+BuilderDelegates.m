//
//  MADQueryViewController+BuilderDelegates.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryViewController+BuilderDelegates.h"

@implementation MADQueryViewController (BuilderDelegates)

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
	[hasQueryTables enumerateObjectsUsingBlock:^(RptqQueryTable * _Nonnull hasTable, BOOL * _Nonnull __unused stop) {
		if (table.identifier == hasTable.identifier) {
			objectToDelete = hasTable;
		}
	}];
	
	__block short ctr = 0;
	NSMutableIndexSet *indexSetSections = [[NSMutableIndexSet alloc] init];
	[indexSetSectionsOld enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull __unused stop) {
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
	[document autosaveWithCompletionHandler:^(BOOL __unused successAutosave) { }];
}

- (void)deleteQueryLinksFromTableView: (UITableView *)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	MADocument *document = self.document;
	MADTableViewCellQueryLink *cell = (MADTableViewCellQueryLink *)[tableView cellForRowAtIndexPath:indexPath];
	int64_t tableID = cell.linkID;
	RptqStoreContext *private = document.storeContext;
	
	RptqObject *objectToDelete = [private objectForEntity:NSStringFromClass([RptqQueryLinks class]) identifier:tableID];
	NSAssert(objectToDelete != nil, @"Need a non-nil value for %lld", (long long)tableID);
	[private deleteObject:objectToDelete error:NULL];
	
	NSError *error = nil;
	BOOL successSave = [private save:&error];
	if (!successSave && error != nil) {
		os_log_error(GetDesignerLog(), "Error saving managed object: %s", error.localizedDescription.UTF8String);
	}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL __unused successAutosave) { }];
}

- (void)deleteQueryGroupFromTableView: (UITableView * __unused)tableView
						  atIndexPath: (NSIndexPath *)indexPath {
	
	MADocument *document = self.document;
	RptqStoreContext *private = document.storeContext;
	RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
	RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
	RptqQuery *rptqQuery = rptqDatabase.hasQueries.anyObject;
	RptqQueryGroup *groupToRemove = [rptqQuery queryGroupForIndex:(NSUInteger)indexPath.row];
	[document removeGroupWitObjectID:groupToRemove.identifier fromManagedObjectContext:private];
	
	NSError *error = nil;
	BOOL successSave = [private save:&error];
	if (!successSave && error != nil) {
		os_log_error(GetDesignerLog(), "Error saving managed object: %s", error.localizedDescription.UTF8String);
	}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL __unused successAutosave) { }];
}

- (void)deleteQueryPredicateFromTableView: (UITableView *)tableView
							  atIndexPath: (NSIndexPath *)indexPath {
	MADocument *document = self.document;
	MADTableViewCellQueryPredicate *cell = (MADTableViewCellQueryPredicate *)[tableView cellForRowAtIndexPath:indexPath];
	int64_t objid = cell.predicateID;
	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[document.storeContext objectForEntity:NSStringFromClass([RptqQueryPredicate class]) identifier:objid];
	[document.storeContext deleteObject:predicate error:NULL];

	NSError *error = nil;
	BOOL successSave = [document.storeContext save:&error];
	if (!successSave && error != nil) {
		os_log_error(GetDesignerLog(), "Error saving managed object context: %@", error);
	}
	[document updateChangeCount: UIDocumentChangeDone];
	[document autosaveWithCompletionHandler:^(BOOL __unused successAutosave) { }];
}

#pragma mark -
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController * __unused)popoverPresentationController {
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController * __unused)presentationController {
	return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController * __unused)presentationController {
	[(MADTabBarController *)self.tabBarController enableTabBarItems];
}

- (void)popoverPresentationController:(UIPopoverPresentationController * __unused)popoverPresentationController
		  willRepositionPopoverToRect:(inout CGRect * __unused)rect inView:(inout UIView * __nonnull __autoreleasing * __nonnull __unused)view {
}

#pragma mark -
#pragma mark MADQueryBuilderPredicateFormatDelegate

- (void)viewController:(MADQueryPredicateFormatController * __unused)controller addedQueryPredicate:(RptqQueryPredicate * __unused)predicate {
	[self dismissViewController];
}

#pragma mark -
#pragma mark MADQueryBuilderLinkBuilderDelegate

- (void)viewController:(MADQueryLinkBuilderController * __unused)controller addedQueryLink:(int64_t __unused)linkID {
	
	[self dismissViewController];
	
	NSInteger suspectedSection = 2;
	
	MADIdentifierQueryViewSections tableSection = [self.queryViewDataSource sectionAtIndex:(short)suspectedSection];
	
	if (tableSection == MADIdentifierQueryViewSectionsLinks) {
		[self.tableView reloadSections: [NSIndexSet indexSetWithIndex:(NSUInteger)suspectedSection]
					  withRowAnimation: UITableViewRowAnimationAutomatic];
	}
}

#pragma mark -
#pragma mark MADQueryBuilderAddGroupDelegate

- (void)viewController:(MADQueryBuilderAddGroupViewController * __unused)vc addedGroupOnQueryField:(int64_t)objectID
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
	[newQueryLayout.sectionTypesIndexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull __unused stop) {
		if ([indexesToAdd containsIndex:idx]) {
			[indexSetSections addIndex:(NSUInteger)ctr];
		}
		ctr++;
	}];
	return indexSetSections;
}

- (void)viewController:(MADQueryBuilderAddTableViewController * __unused)vc addedQueryTableWithID:(int64_t)objectID {
	
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
		NSUInteger tableIndex = [self.queryViewDataSource.queryTablesController indexOfObjectPassingTest:^BOOL(RptqQueryTable *  _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
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
	[document autosaveWithCompletionHandler:^(BOOL __unused success) {
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

- (void)layoutSettings:(MADDesignerSectionLayoutController * __unused)layoutSettings newPageAfter:(BOOL)newPageAfter {
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

- (void)viewControllerDidFinish:(id __unused)sender {
	[self dismissViewController];
}

- (void)viewControllerDidCancel:(id __unused)sender {
	[self dismissViewController];
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
#pragma mark Builder Presentation Actions

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

- (void)addTable:(id __unused)sender {
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

- (void)addLink:(id __unused)sender {
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

- (void)addPredicate:(id __unused)sender {
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

- (void)addGroup:(id __unused)sender {
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

@end
