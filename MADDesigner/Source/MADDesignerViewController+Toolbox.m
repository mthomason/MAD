//
//  MADDesignerViewController+Toolbox.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController+Toolbox.h"
#import "MADDesignerViewController+ElementSaving.h"

@implementation MADDesignerViewController (Toolbox)

#pragma mark -
#pragma mark MADDesignerSectionLayoutDelegate

- (void)sectionLayoutSettingsDidFinish:(MADDesignerSectionLayoutController * __unused)controller {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	[self actionHideToolbox];
}

- (void)layoutSettings:(MADDesignerSectionLayoutController * __unused)layoutSettings
		  newPageAfter:(BOOL)newPageAfter {
	
	NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
	RptqStoreContext *private = self.document.storeContext;

	RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = database.hasQueries.anyObject;
	
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber
														  withNumberOfGroups: query.hasQueryGroups.count];
	
	[section setProducesFormFeed: newPageAfter];
	NSError *error = NULL;
	BOOL saved = [private save:&error];
	if (!saved && error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
	}
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
	
	NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
	RptqStoreContext *private = self.document.storeContext;
	NSDictionary <NSNumber *, MADDesignerSectionView *> *sectionViews = self.view.scroller.container.sectionViews;

	RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = database.hasQueries.anyObject;
	
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber
														  withNumberOfGroups: query.hasQueryGroups.count];
	section.visibility = [NSNumber numberWithBool:isVisible];

	NSNumber *key = @(section.identifier);
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		MADDesignerSectionView *documentSectionView = sectionViews[key];
		documentSectionView.visible = isVisible;
	}];

	NSError *error = NULL;
	BOOL saved = [private save:&error];
	if (!saved && error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
	}
}

//FIXME: Unused... used to allow user to change the height of the sections.
- (void)sectionLayoutDidUpdateHeight:(CGFloat __unused)height {
	RptqDocument *document = self.document.activeDocumentModel;
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = [database.hasQueries anyObject];
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
														  withNumberOfGroups: query.hasQueryGroups.count];
	
	UICollectionView *documentSectionView = [self getSectionViewForSectionID: section.identifier];
	CGSize collectionViewContentSize = [documentSectionView.collectionViewLayout collectionViewContentSize];
	[section setInterfaceHeight: collectionViewContentSize.height];

	UICollectionView *collectionView = self.view.scroller.container.sectionViews[@(section.identifier)];
	[collectionView.backgroundView setNeedsDisplay];
	[documentSectionView.collectionViewLayout invalidateLayout];
	[section setInterfaceHeight: collectionViewContentSize.height];

	NSError *error = NULL;
	BOOL saved = [section.storeContext save:&error];
	if (!saved && error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
	}
	
	[self.view setNeedsUpdateConstraints];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(int32_t)numberOfRows {
	
	MADocument *doc = self.document;
	RptqDocument *document = doc.activeDocumentModel;
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = database.hasQueries.anyObject;
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
														  withNumberOfGroups: query.hasQueryGroups.count];
	
	BOOL insertNewSection = numberOfRows > section.numberOfRows;
	BOOL deleteLastSection = numberOfRows < section.numberOfRows;
	
	UICollectionView *documentSectionView = [self getSectionViewForSectionID: section.identifier];
	
	if (section.numberOfRows == (int64_t)numberOfRows) {
		// No change... do nothing
	} else if ((int64_t)numberOfRows > section.numberOfRows) {
		
		RptqDocumentSectionRows *newRowToAppend = (RptqDocumentSectionRows *)[doc.storeContext insertObjectForEntity:NSStringFromClass([RptqDocumentSectionRows class])
																										   identifier: 0];
		NSArray *hasRowsArray = section.hasRows.array;
		NSMutableOrderedSet *hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
		[[NSMutableOrderedSet alloc] init];
		newRowToAppend.inSection = section;
		[hasRows addObject:newRowToAppend];
		section.hasRows = hasRows;
		
	} else if ((int64_t)numberOfRows < section.numberOfRows) {
		
		RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
		NSArray *hasRowsArray = section.hasRows.array;
		NSMutableOrderedSet *hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
		[[NSMutableOrderedSet alloc] init];
		if ([hasRows count] > 0) {
			[hasRows.lastObject setInSection:nil];
			[hasRows removeObjectAtIndex:hasRows.count - 1];
			section.hasRows = hasRows;
			[rowToDelete setInSection:nil];
		}
	}
	
	section.numberOfRows = numberOfRows;
	NSNumber *sectionKey = @(section.identifier);
	UICollectionView *collectionView = self.view.scroller.container.sectionViews[sectionKey];
	MADDesignerSectionBackground *backgroundView = (MADDesignerSectionBackground *)collectionView.backgroundView;
	[backgroundView setNumberOfRowsInBackground:numberOfRows];
	
	NSError *error = NULL;
	[doc.storeContext save:&error];
	if (error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
	}
	[doc updateChangeCount:UIDocumentChangeDone];
	[doc autosaveWithCompletionHandler:^(BOOL __unused success) {
		if (insertNewSection) {
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)numberOfRows - 1];
			[documentSectionView insertSections:indexSet];
		} else if (deleteLastSection) {
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)numberOfRows];
			[documentSectionView deleteSections:indexSet];
		}
	}];
}

#pragma mark -
#pragma mark UIPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
(UIPresentationController * __unused)controller {
	return UIModalPresentationOverFullScreen;
}

- (UIViewController *)presentationController:(UIPresentationController *)controller
  viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	
	UIViewController *result = nil;
	id presented = controller.presentedViewController;
	if (style != UIModalPresentationPopover && [presented isKindOfClass:[UINavigationController class]] == NO) {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
																					  target: self
																					  action: @selector(actionCancel:)];
		[controller.presentedViewController.navigationItem setLeftBarButtonItem: cancelButton
																	   animated: NO];
		controller.presentedViewController.view.backgroundColor = [UIColor clearColor];
		
		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController: presented];
		[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];
		result = navigation;
		
	} else if ([controller.presentedViewController isKindOfClass:[UINavigationController class]]) {
		
		if ([((UINavigationController *)controller.presentedViewController).topViewController
			 isKindOfClass:[MADDesignerElementPickerViewController class]]) {
			
			UINavigationController *navigationController;
			navigationController = (UINavigationController *)controller.presentedViewController;
			
			if (navigationController.navigationItem.leftBarButtonItem == nil) {
				UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						target:self
																						action:@selector(actionCancel:)];
				[navigationController.topViewController.navigationItem setLeftBarButtonItem:cancel animated:NO];
			}
			
			UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
			visualEffectsView.frame = navigationController.view.bounds;
			visualEffectsView.autoresizingMask = MADViewAutoresizingFlexable();
			[navigationController.view insertSubview:visualEffectsView atIndex:0];
			result = navigationController;
			
		} else {
			result = controller.presentedViewController;
		}
		
	} else {
		result = controller.presentedViewController;
	}
	return result;
}

#pragma mark -
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	popoverPresentationController.backgroundColor = nil;
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController * __unused)presentationController {
	return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController * __unused)presentationController {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	[self actionDismiss];
	[self setDisplayActive];
}

#pragma mark -
#pragma mark MADReportSectionDelegate Protocol

- (void)designView:(MADDesignerLayoutDesignView * __unused)designView handleTapStray:(UITapGestureRecognizer *)sender {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	if (sender.state != UIGestureRecognizerStateEnded) return;
	if (self.presentedViewController != nil) {
		[self actionHideToolbox];
	}
}

- (void)designView:(MADDesignerLayoutDesignView * __unused)designView handleTapLabel:(UITapGestureRecognizer *)sender {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	
	if (sender.state != UIGestureRecognizerStateEnded) return;
	
	MADDesignerSectionLabel *label = (MADDesignerSectionLabel *)sender.view;
	[self dismissToolboxPresentationIfOpen];
	
	NSSet *selectedElementViews = [self selectedElementViews];
	
	BOOL hideToolbox = NO;
	if (selectedElementViews.count >= 1) {
		hideToolbox = YES;
	}
	
	self.viewControllerToolbox.document = self.document;
	
	if (label.selected) {
		[label normalView];
		hideToolbox = YES;
	} else {
		[self deselectAllElementsAnimated:YES];
		self.lastSelectedSectionControlPanel = label.tag;
		self.lastSelectedLabel = label;
		RptqDocumentSection *section = [self sectionForLabelTag:label.tag];
		MADDesignerSectionView *superView = [self getSectionViewForDocumentSection: section];
		superView.selected = YES;
		[label dimView];
		MADDesignerSectionLayoutController *sectionSettings = self.viewControllerSectionLayoutSettings;
		[sectionSettings updateDisplay:section.height
							visibility:section.visibility
					  producesFormFeed:section.producesFormFeed
						  numberOfRows:section.numberOfRows];
		UIEdgeInsets hs = sectionSettings.tableView.horizontalScrollIndicatorInsets;
		UIEdgeInsets vs = sectionSettings.tableView.verticalScrollIndicatorInsets;
		sectionSettings.tableView.contentInset = UIEdgeInsetsMake(vs.top, hs.left, vs.bottom, hs.right);
		sectionSettings.tableView.verticalScrollIndicatorInsets = vs;
		sectionSettings.tableView.horizontalScrollIndicatorInsets = hs;
		[self actionShowSectionSettingsFromLabel:label];
		[self setDisplayInactive];
	}
	
	if (hideToolbox) {
		[self actionHideToolbox];
	}
}

#pragma mark -
#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id __unused)sender {
	[self setDisplayActive];
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Toolbox & Section Settings Positioning

- (void)adjustContextOffsetForToolboxWithToolboxType:(MTToolboxType)toolboxType {
	switch (toolboxType) {
		case MTToolboxTypeSection:
			[self adjustContentOffsetForLastSelectedSectionControlPanel];
			break;
		case MTToolboxTypeElement:
			[self adjustContentOffsetForSelectedElements];
			break;
		default:
			break;
	}
}

- (void)adjustContentOffsetForSelectedElements {
	if (self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil && [self.toolboxTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
		CGRect frame = ((MADToolboxTransitioningDelegate *)self.toolboxTransitioningDelegate).presentationController.presentedViewController.view.frame;
		CGRect bounds = [self.view.scroller positionForRectOfInterest: [self rectForSelectedElements]
													withPresentedRect: frame
														containerSize: self.view.frame.size
														   adjustment: self.view.safeAreaInsets.top];
		[self.view.scroller.container repositionSectionViews:bounds];
	}
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanel {
	RptqDocument *document = self.document.activeDocumentModel;
	RptqQuery *query = document.defaultDatabase.defaultQuery;
	RptqDocumentSection *documentSection = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
																  withNumberOfGroups: query.hasQueryGroups.count];
	
	UIView *selectedSectionView = [self getSectionViewForDocumentSection:documentSection];
	if (self.settingsTransitioningDelegate.presentationController.presentedViewController != nil &&
		[self.settingsTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
		CGRect presentedRect = ((MADToolboxTransitioningDelegate *)self.settingsTransitioningDelegate).
		presentationController.presentedViewController.view.frame;
		CGRect position = [self.view.scroller positionForRectOfInterest: selectedSectionView.frame
													  withPresentedRect: presentedRect
														  containerSize: self.view.frame.size
															 adjustment: self.view.safeAreaInsets.top];
		[self.view.scroller.container repositionSectionViews:position];
	}
}

- (void)adjustContextOffsetForOpenPopover {
	if ([self padLike]) {
		if (_sectionSettingsVisible &&
			self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
			
			[self adjustSettingsLocation];
			
		} else if (_toolboxVisible &&
				   self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
			
			[self adjustToolboxLocation];
			
		}
	}
}

- (void)adjustPassthroughViews {
	if (_sectionSettingsVisible) {
		self.settingsTransitioningDelegate.passthroughContainers = self.view.scroller.container.passthroughContainers;
		self.settingsTransitioningDelegate.passthroughViews = [self passthroughViews];
		self.settingsTransitioningDelegate.passthroughContainer = self.view.scroller;
	} else if (_toolboxVisible) {
		self.toolboxTransitioningDelegate.passthroughContainers = self.view.scroller.container.passthroughContainers;
		self.toolboxTransitioningDelegate.passthroughViews = [self passthroughViews];
		self.toolboxTransitioningDelegate.passthroughContainer = self.view.scroller;
	}
}

- (void)dismissSectionPresentationIfOpen {
	if (_sectionSettingsVisible && self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
		_sectionSettingsVisible = NO;
		[self dismissViewControllerAnimated: YES completion: nil];
		[self.view.scroller.container removeBorderFromAllSectionViews];

		__strong MADocument *document = self.document;
		NSError *saveError = nil;
		BOOL saved = [document.storeContext save:&saveError];
		if (!saved && saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
}

- (void)dismissToolboxPresentationIfOpen {
	if (_toolboxVisible && self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
		_toolboxVisible = NO;
		[self dismissViewControllerAnimated: YES completion: nil];
		[self deselectAllElementsAnimated:YES];

		__strong MADocument *document = self.document;
		NSError *saveError = nil;
		BOOL saved = [document.storeContext save:&saveError];
		if (!saved && saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
}

- (void)adjustSettingsLocation {
	self.settingsTransitioningDelegate.sourceRect = self.lastSelectedLabel.frame;
}

- (void)adjustToolboxLocation {
	self.toolboxTransitioningDelegate.sourceRect = self.rectForSelectedElements;
	self.viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
}

#pragma mark -
#pragma mark Actions

- (IBAction)actionDone:(id __unused)sender {
	__strong MADocument *document = self.document;
	if ([document.storeContext hasChanges]) {
		NSError *saveError = NULL;
		[document.storeContext save:&saveError];
		if (saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
	if (![self dismissAllPopovers]) {
		[self.delegate viewControllerDidFinish:nil];
	} else {
		[self deselectAllElementsAnimated:YES];
	}
}

- (IBAction)actionAdd:(id)sender {
	UINavigationController *navigation = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeElementPicker];
	[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];
	
	MADDesignerElementPickerViewController *pickerController = (MADDesignerElementPickerViewController *)navigation.topViewController;
	pickerController.objectSelectorDelegate = self;
	pickerController.document = self.document;
	
	navigation.modalPresentationStyle = UIModalPresentationPopover;
	navigation.preferredContentSize = sizePopoverDefault();
	
	UIPopoverPresentationController *popoverController = navigation.popoverPresentationController;
	popoverController.delegate = self;
	popoverController.barButtonItem = sender;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	
	[self presentViewController: navigation animated: YES completion:^{
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, pickerController);
	}];
	[self setDisplayInactive];
}

- (IBAction)actionCancel:(id __unused)sender {
	self.hidesStatusBar = NO;
	__weak MADDesignerViewController *weakSelf = self;
	[self dismissViewControllerAnimated:YES completion:^{
		[weakSelf setDisplayActive];
	}];
}

- (IBAction)actionDismiss {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	[self deselectAllElementsAnimated:YES];
	__strong MADocument *document = self.document;
	if ([document.storeContext hasChanges]) {
		NSError *saveError = NULL;
		[document.storeContext save:&saveError];
		if (saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
}

- (IBAction)actionShowToolbox {
	MADLogDebug("%s: Showing toolbox", __PRETTY_FUNCTION__);
	_toolboxVisible = YES;
	_sectionSettingsVisible = NO;
	MADLogDebug("%s: Updated visibility flags - toolbox: %d, section settings: %d",
				__PRETTY_FUNCTION__, _toolboxVisible, _sectionSettingsVisible);
	
	self.toolboxTransitioningDelegate.sourceView = self.view.scroller.container;
	self.toolboxTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
	self.toolboxTransitioningDelegate.popoverPresentationControllerDelegate = self;
	self.toolboxTransitioningDelegate.container = self.view.scroller.container;
	self.toolboxTransitioningDelegate.passthroughContainers = self.view.scroller.container.passthroughContainers;
	self.toolboxTransitioningDelegate.passthroughViews = [self passthroughViews];
	self.toolboxTransitioningDelegate.passthroughContainer = self.view.scroller;
	
	self.viewControllerToolbox.clearsBackground = [self padLike];
	self.viewControllerToolbox.document = self.document;
	[self adjustToolboxLocation];
	
	__weak MADDesignerViewController *weakSelf = self;
	[self presentViewController:self.navigationControllerToolbox animated:YES completion:^{
		__strong MADDesignerViewController *strongSelf = weakSelf;
		if (strongSelf) {
			strongSelf.navigationControllerToolbox.presentationController.delegate = strongSelf;
			[strongSelf adjustContextOffsetForToolboxWithToolboxType:MTToolboxTypeElement];
		}
		MADLogDebug("%s: Toolbox presentation completed", __PRETTY_FUNCTION__);
	}];
}

- (IBAction)actionShowSectionSettingsFromLabel:(UILabel *)label {
	_toolboxVisible = NO;
	self.settingsTransitioningDelegate.sourceRect = label.frame;
	self.settingsTransitioningDelegate.sourceView = self.view.scroller.container;
	self.settingsTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
	self.settingsTransitioningDelegate.popoverPresentationControllerDelegate = self;
	self.settingsTransitioningDelegate.container = self.view.scroller.container;
	self.settingsTransitioningDelegate.passthroughContainers = self.view.scroller.container.passthroughContainers;
	self.settingsTransitioningDelegate.passthroughViews = [self passthroughViews];
	self.settingsTransitioningDelegate.passthroughContainer = self.view.scroller;
	
	if (_sectionSettingsVisible == NO) {
		_sectionSettingsVisible = YES;
		[self adjustPassthroughViews];
		__weak MADDesignerViewController *weakSelf = self;
		[self presentViewController: self.navigationControllerSectionLayoutSettings animated: YES completion: ^{
			__strong MADDesignerViewController *strongSelf = weakSelf;
			[strongSelf adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
		}];
	} else {
		[self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
	}
}

#pragma mark -
#pragma mark Convenience

- (BOOL)padLike {
	return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
	self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
}

- (NSSet <__kindof UIView *> *)passthroughViews {
	NSSet <MADDesignerSectionView *> *sectionViews = self.view.scroller.container.passthroughContainers;
	NSMutableSet <__kindof UIView *> *sectionLabels = [[NSMutableSet alloc] initWithCapacity:sectionViews.count];
	for (MADDesignerSectionView *view in sectionViews) {
		[sectionLabels addObject:view.sectionLabel];
	}
	[sectionLabels unionSet:sectionViews];
	[sectionLabels unionSet:self.visibleElementViews];
	return sectionLabels;
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)section {
	return self.view.scroller.container.sectionLabels[@(section.identifier)];
}

@end
