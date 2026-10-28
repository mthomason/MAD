//
//  MADDesignerViewController+CollectionView.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController+CollectionView.h"
#import "MADDesignerViewController+ElementSaving.h"
#import "MADDesignerViewController+Toolbox.h"

@implementation MADDesignerViewController (CollectionView)

#pragma mark -
#pragma mark MADCellElement Delegate

- (MADPrintPageElementType)objectTypeRepresentedByCell:(MADCellElement *)cell {
	RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier: cell.identifier
																	   fromObjectContext: self.document.storeContext];
	return element.type;
}

- (void)formatDocumentObjectRepresentedByCell:(MADCellElement *)cell {
	[self deselectAllElementsAnimated:YES];
	_lastMenuItemSelectRequiresElementView = YES;
	
	__kindof MADDesignerElementView *elementView = [self.elementViewsDictionary objectForKey:@(cell.identifier)];
	[self selectElementView: elementView];
}

- (void)editDocumentObjectRepresentedByCell:(MADCellElement *)cell {
	
	RptqStoreContext *private = self.document.storeContext;
	int64_t elementID = cell.identifier;

	RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: elementID
																			  fromObjectContext: private];
	RptqDocumentSection *inSection = documentObject.inSectionRow.inSection;
	int64_t sectionID = inSection.identifier;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		MADDesignerSectionView *designerSectionView = [self getSectionViewForSectionID:sectionID];
		int64_t designerSectionViewID = designerSectionView.identifier;
		
		RptqDocumentSection *section = [RptqDocumentSection newDocumentSectionWithIdentifier: designerSectionViewID
																		   fromObjectContext: private];
		BOOL found = NO;
		
		NSOrderedSet *documentSectionHasRows = section.hasRows;
		for (RptqDocumentSectionRows *row in documentSectionHasRows) {
			
			NSMutableOrderedSet *hasObjects = row.hasObjects.mutableCopy;
			NSUInteger i = 0;
			for (RptqDocumentElement *object in hasObjects) {
				if (object.identifier == elementID) {
					found = YES;
					break;
				}
				i++;
			}
			
			if (found) {
				
				RptqDocumentElement *objectToEdit = hasObjects[i];
				
				switch (objectToEdit.type) {
						
					case MADPrintPageElementTypeAggregate: {
						dispatch_async(dispatch_get_main_queue(), ^{
							NSNumber *objectID  = @(objectToEdit.identifier);
							[self editDocumentObjectAggregateWithID: objectID
														   objectID: objectToEdit.identifier];
						});
						break;
					}
						
					case MADPrintPageElementTypeBarcode: {
						dispatch_async(dispatch_get_main_queue(), ^{
							NSNumber *objectID  = @(objectToEdit.identifier);
							[self editDocumentObjectBarcodeWithID: objectID];
						});
						break;
					}
						
					case MADPrintPageElementTypeImage: {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self editDocumentObjectImage: objectToEdit];
						});
						break;
					}
						
					case MADPrintPageElementTypeLabelDynamic: {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self editDocumentObjectLabelDynamic:objectToEdit];
						});
						break;
					}
						
					case MADPrintPageElementTypeLabelStatic: {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self editDocumentObjectLabelStatic:objectToEdit];
						});
						break;
					}
						
					case MADPrintPageElementTypeWhtiespace:
						break;
						
					default:
						break;
						
				}
			}
		}
	});
}

#pragma mark MADCellElement Helpers

- (void)editDocumentObjectAggregateWithID:(NSNumber *)identifier
								 objectID:(int64_t)objectID {
	
	self.aggregateToEditObjectID = objectID;
	_editAggregate = YES;
	
	__weak MADDesignerViewController *weakself = self;
	
	void (^updateAggregate)(void) = ^{
		
		MADDesignerViewController *strongself = weakself;
		if (!strongself) return;
		
		UIView *viewToEdit = [strongself.elementViewsDictionary objectForKey:identifier];
		UINavigationController *navigation = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeAggregateAdd];
		[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];
		
		MADocument *document = strongself.document;
		RptqDocumentElementAggregate *aggregateToEdit = (RptqDocumentElementAggregate *)[document.storeContext objectForEntity:NSStringFromClass([RptqDocumentElementAggregate class]) identifier:objectID];
		
		MTDocumentObjectNewAggregateViewController *aggregateViewController = navigation.viewControllers.firstObject;
		aggregateViewController.document = document;
		aggregateViewController.aggregateDelegate = strongself;
		[aggregateViewController setAggregateObjectToEdit:aggregateToEdit];
		
		UIBarButtonItem *dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																				 target: strongself
																				 action: @selector(actionCancel:)];
		
		[aggregateViewController.navigationItem setRightBarButtonItem:dismiss animated:NO];
		[aggregateViewController.navigationItem setLeftBarButtonItem:nil animated:NO];
		
		navigation.modalPresentationStyle = UIModalPresentationPopover;
		navigation.preferredContentSize = sizePopoverFonts();
		
		UIPopoverPresentationController *popoverController = navigation.popoverPresentationController;
		popoverController.delegate = strongself;
		popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
														toView: strongself.view.scroller.container];
		
		popoverController.sourceView = strongself.view.scroller.container;
		popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
		[strongself presentViewController:navigation animated:YES completion:nil];
		[strongself setDisplayInactive];
		
	};
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:updateAggregate];
}

- (void)editDocumentObjectBarcodeWithID:(NSNumber *)objectID {
	
	self.barcodeToEditObjectID = objectID.copy;
	
	__weak MADDesignerViewController *weakself = self;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		
		MADDesignerViewController *strongself = weakself;
		if (!strongself) return;
		
		UIView *viewToEdit = [self.elementViewsDictionary objectForKey:objectID];
		
		MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode newViewControllerBarcode];
		barcodeViewController.document = strongself.document;
		barcodeViewController.delegate = strongself;
		barcodeViewController.preferredContentSize = sizePopoverFonts();
		barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
		barcodeViewController.bartcodeToEditObjectID = objectID.longLongValue;
		
		UIPopoverPresentationController *popoverController = barcodeViewController.popoverPresentationController;
		popoverController.delegate = strongself;
		popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
														toView: strongself.view.scroller.container];
		popoverController.sourceView = strongself.view.scroller.container;
		popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
		[strongself presentViewController:barcodeViewController animated:YES completion:nil];
		[strongself setDisplayInactive];
	}];
}

- (void)editDocumentObjectBarcode:(RptqDocumentElement *)object {
	
	UIView *viewToEdit = [self.elementViewsDictionary objectForKey:@(object.identifier)];
	
	MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode newViewControllerBarcode];
	barcodeViewController.document = self.document;
	barcodeViewController.delegate = self;
	
	barcodeViewController.preferredContentSize = sizePopoverFonts();
	barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
	
	UIPopoverPresentationController *popoverController = barcodeViewController.popoverPresentationController;
	popoverController.delegate = self;
	popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
													toView: self.view.scroller.container];
	popoverController.sourceView = self.view.scroller.container;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	[self presentViewController:barcodeViewController animated:YES completion:nil];
	[self setDisplayInactive];
}

- (void)editDocumentObjectImage:(RptqDocumentElement *)object {
	self.objectIdEditImage = @(object.identifier);
}

- (void)editDocumentObjectLabelDynamic:(RptqDocumentElement *)object {
	
	self.objectIdEditDynamicLabel = @(object.identifier);
	
	UIView *viewToEdit = [self.elementViewsDictionary objectForKey:self.objectIdEditDynamicLabel];
	
	MADQueryChooseFieldController *chooseFieldViewController;
	chooseFieldViewController = [MADQueryChooseFieldController newQueryBuilderChooseFieldViewController];
	chooseFieldViewController.document = self.document;
	chooseFieldViewController.delegate = self;
	
	chooseFieldViewController.modalPresentationStyle = UIModalPresentationPopover;
	chooseFieldViewController.preferredContentSize = sizePopoverFonts();
	
	UIPopoverPresentationController *popoverController;
	popoverController = chooseFieldViewController.popoverPresentationController;
	popoverController.delegate = self;
	popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
													toView: self.view.scroller.container];
	popoverController.sourceView = self.view.scroller.container;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	[self presentViewController:chooseFieldViewController animated:YES completion:nil];
	[self setDisplayInactive];
}

- (void)editDocumentObjectLabelStatic:(RptqDocumentElement *)object {
	
	NSString *oldText = [((RptqDocumentElementLabel *)object).text copy];

	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Edit Label", @"Edit Label")
																   message: NSLocalizedString(@"Please enter updated text.", @"Please enter updated text.")
															preferredStyle: UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.text = [oldText copy];
		textField.clearButtonMode = UITextFieldViewModeAlways;
	}];
	
	RptqStoreContext *context = object.storeContext;
	int64_t objectID = object.identifier;

	__weak MADDesignerViewController *weakSelf = self;
	[alert addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Change", @"Change")
											  style: UIAlertActionStyleDefault
											handler: ^(UIAlertAction *__unused action) {
		__strong MADDesignerViewController *strongSelf = weakSelf;
		if (!strongSelf) return;

		RptqDocumentElementLabel *label = (RptqDocumentElementLabel *)[context objectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:objectID];
		if (label != nil) {
			label.text = [alert.textFields.firstObject.text copy];
			NSError *saveError = nil;
			if (![context save:&saveError]) {
				os_log_error(GetDesignerLog(), "%s: Error saving context %@", __PRETTY_FUNCTION__, saveError);
			} else {
				MADDesignerElementView *elementView = [strongSelf elementViewForManagedObject:label];
				if (elementView) {
					[elementView updateWithElement:label];
					[elementView setNeedsDisplay];
				}
			}
		} else {
			os_log_error(GetDesignerLog(), "%s: Label is null.", __PRETTY_FUNCTION__);
		}
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
											  style: UIAlertActionStyleCancel
											handler: nil]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteDocumentObjectRepresentedByCell:(MADCellElement *)cell {
	int64_t cellIdentifier = cell.identifier;
	NSNumber *objectId = @(cell.identifier);
	
	MADocument *document = self.document;
	__kindof RptqDocumentElement *element = (__kindof RptqDocumentElement *)[document.storeContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:cellIdentifier];
	MADDesignerSectionView *sectionView = [self getSectionViewForDocumentSection:element.inSectionRow.inSection];
	
	NSNumber *sectionIdentifier = [[NSNumber alloc] initWithLongLong:sectionView.identifier];
	MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[sectionIdentifier];
	MADSectionLayoutAttributes *itemToRemove = (layoutManager.items)[objectId];
	
	__weak MADDesignerViewController *weakSelf = self;
	[sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
		__strong MADDesignerViewController *strongSelf = weakSelf;
		if (!strongSelf) return;
		[strongSelf.document removeDocumentObjectWithObjectID: cellIdentifier];
	} animationComplete:^(BOOL complete) {
		if (complete) {
			__strong MADDesignerViewController *strongSelf = weakSelf;
			if (!strongSelf) return;
			[strongSelf.view.scroller.container invalidateIntrinsicContentSize];
			[strongSelf.view setNeedsUpdateConstraints];
		}
	} completion:^() {
		__strong MADDesignerViewController *strongSelf = weakSelf;
		if (!strongSelf) return;
		[strongSelf redrawAllElementViewsInCollectionView:sectionView];
		MADocument *doc = strongSelf.document;
		RptqDocumentElement *elementB = [RptqDocumentElement newDocumentElementWithIdentifier:cellIdentifier
																			fromObjectContext:doc.storeContext];
		[doc.storeContext deleteObject:elementB error:NULL];
		NSError *saveError = NULL;
		BOOL saved = [doc.storeContext save:&saveError];
		if (!saved && saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}];
}

#pragma mark -
#pragma mark MADDesignerSectionLayoutLiquidDelegate

- (void)collectionViewDidFinishUpdates:(UICollectionView * __unused)collectionView { }

- (void)collectionView: (MADDesignerSectionView *)collectionView prepareLayout: (UICollectionViewLayout * __unused)collectionViewLayout {
	MADocument *document = self.document;
	NSNumber *identifier = @(collectionView.identifier);
	MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[identifier];
	RptqStoreContext *objectContext = document.storeContext;
	for (MADSectionLayoutAttributes *attributes in layoutManager.items.allValues) {
		RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: attributes.objectID
																				  fromObjectContext: objectContext];
		[documentObject setOriginPoint:attributes.frame.origin];
	}
}

- (MADSectionLayoutAttributes *)collectionView: (MADDesignerSectionView *)collectionView
										layout: (UICollectionViewLayout * __unused)collectionViewLayout
			layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {
	
	NSNumber *identifier = @(collectionView.identifier);
	MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[identifier];
	__block MADSectionLayoutAttributes *item;
	[layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id __unused key,
															 MADSectionLayoutAttributes *object,
															 BOOL *stop) {
		if (object.indexPath.item == indexPath.item &&
			object.indexPath.section == indexPath.section) {
			item = object;
			*stop = YES;
		}
	}];
	return item;
}

- (NSUInteger)numberOfItemsInSection: (NSUInteger __unused)section ofCollectionView: (MADDesignerSectionView *)collectionView {
	MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
	return layoutManager.items.count;
}

- (NSArray *)collectionView: (MADDesignerSectionView *)collectionView attributesForLayout: (UICollectionViewLayout * __unused)collectionViewLayout {
	MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
	return layoutManager.items.allValues;
}

- (CGSize)collectionView: (MADDesignerSectionView *)collectionView sizeForLayout: (UICollectionViewLayout * __unused)collectionViewLayout {
	MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
	return layoutManager.size;
}

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView: (MADDesignerSectionView *)collectionView
				  cellForItemAtIndexPath: (NSIndexPath *)indexPath {
	
	MADocument *document = self.document;
	MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[@(collectionView.identifier)];
	
	__block MADSectionLayoutAttributes *attributes;
	[layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id __unused key, MADSectionLayoutAttributes *object, BOOL *stop) {
		if (object.indexPath.section == indexPath.section &&
			object.indexPath.row == indexPath.row) {
			attributes = object;
			*stop = YES;
		}
	}];
	
	
	RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: attributes.objectID
																			  fromObjectContext: document.storeContext];

	CGFloat contextScale = self.view.scroller.zoomScale * self.view.scroller.traitCollection.displayScale;
	NSString *resuseId = [MADCellElement reuseIdentifier];
	
	MADCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId forIndexPath:indexPath];
	cell.delegate = self;

	if (documentObject == nil) return cell;
	
	CGSize documentObjectSize = [documentObject sizeCalculated];
	CGRect cellBounds = CGRectMake(CGPointZero.x, CGPointZero.y, documentObjectSize.width, documentObjectSize.height);
	
	switch (documentObject.documentObjectType) {
		case MADPrintPageElementTypeFormula:
		case MADPrintPageElementTypeLabelStatic:
		case MADPrintPageElementTypeLabelDynamic:
		case MADPrintPageElementTypeAggregate:
		default: {
			
			NSArray *subviews = cell.contentView.subviews;
			for (id subview in subviews) {
				[subview removeFromSuperview];
			}
			int64_t identifier = documentObject.identifier;
			
			cell.contentView.autoresizingMask = MADViewAutoresizingFlexable();
			
			MADDesignerElementView *elementView = [self elementViewForManagedObject:documentObject];
			NSNumber *elementViewIdentifier = @(identifier);
			[self.elementViewsDictionary setObject: elementView
											forKey: elementViewIdentifier];
			
			UIGestureRecognizer *panGesture, *pinchGesture;
			panGesture = [MADPanGestureRecognizer newPanGestureRecognizerElement: self
																		  action: @selector(handlePanPiece:)
																		delegate: self];
			[self.view.scroller.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
			[elementView addGestureRecognizer:panGesture];
			
			pinchGesture = [MADPinchGestureRecognizer newPinchGestureRecognizerElement: self
																				action: @selector(handlePinchPiece:)
																			  delegate: self];
			
			[self.view.scroller.pinchGestureRecognizer requireGestureRecognizerToFail:pinchGesture];
			[elementView addGestureRecognizer:pinchGesture];
			
			if (cell.frame.origin.x < 0.0f || cell.frame.origin.y < 0.0f) {
				cell.frame = cellBounds;
			} else {
				cell.bounds = cellBounds;
			}
			cell.identifier = documentObject.identifier;
			
			elementView.userInteractionEnabled = YES;
			cell.userInteractionEnabled = YES;
			elementView.backgroundColor = [UIColor tertiarySystemFillColor];
			
			NSNumber *identifierNumber = @(identifier);
			if ([self.selectedElementIDs containsObject: identifierNumber]) {
				[self.view.scroller.container applyBorderToView:elementView];
			}
			
			[cell addElementView:elementView];
			
			if (cell) {
				cell.contentScaleFactor = contextScale;
				(cell.contentView).contentScaleFactor = contextScale;
			}
			
			elementView.contentScaleFactor = contextScale;
			break;
		}
	}
	return cell;
}

- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind: (NSString *)kind
								 atIndexPath: (NSIndexPath *)indexPath {
	
	MTCollectionReuseableViewDefault *result = nil;
	
	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
		result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
													withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
														   forIndexPath: indexPath];
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 22.0)];
		label.text = NSLocalizedString(@"Header", @"Header");
		[result addSubview:label];
	} else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
		result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
													withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
														   forIndexPath: indexPath];
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 22.0)];
		label.text = NSLocalizedString(@"Footer", @"Footer");
		[result addSubview:label];
	} else {
		result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
													withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
														   forIndexPath: indexPath];
	}
	return result;
}

- (NSInteger)collectionView: (MADDesignerSectionView *)collectionView numberOfItemsInSection: (NSInteger __unused)section {
	if (collectionView == nil) return 0;
	MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
	return (NSInteger)layoutManager.items.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView * __unused)collectionView {
	return 1;
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView: (UICollectionView * __unused)collectionView willDisplayCell: (MADManagedObjectCollectionViewCell *)cell forItemAtIndexPath: (NSIndexPath * __unused)indexPath {
	
	__kindof MADDesignerElementView *elementView = nil;
	
	for (UIView *view in cell.contentView.subviews) {
		if ([view isKindOfClass:[MADDesignerElementView class]]) {
			elementView = (MADDesignerElementView *)view;
			break;
		}
	}
	
	if (cell.frame.origin.x < 0.0f || cell.frame.origin.y < 0.0f) {
		cell.frame = CGRectMake(CGPointZero.x, CGPointZero.y, cell.frame.size.width, cell.frame.size.height);
	}
	if (elementView) {
		[self.visibleElementViews addObject:elementView];
	}
	[self adjustPassthroughViews];
}

- (void)collectionView: (UICollectionView * __unused)collectionView
  didEndDisplayingCell: (MADManagedObjectCollectionViewCell *)cell
	forItemAtIndexPath: (NSIndexPath * __unused)indexPath {
	
	NSSet <__kindof MADDesignerElementView *> *elementViewSet;
	
	BOOL (^predicate)(id obj, BOOL *stop) = ^BOOL(__kindof MADDesignerElementView * _Nonnull obj, BOOL * _Nonnull stop) {
		if (obj.identifier == cell.identifier) {
			*stop = YES;
			return YES;
		} else {
			return NO;
		}
	};
	elementViewSet = [self.visibleElementViews objectsPassingTest:predicate];
	
	[self.visibleElementViews minusSet:elementViewSet];
	[self adjustPassthroughViews];
}

- (void)collectionView:(UICollectionView * __unused)collectionView
didEndDisplayingSupplementaryView:(UICollectionReusableView * __unused)view
	  forElementOfKind:(NSString * __unused)elementKind
		   atIndexPath:(NSIndexPath * __unused)indexPath {
}

- (void)collectionView:(UICollectionView * __unused)collectionView didDeselectItemAtIndexPath:(NSIndexPath * __unused)indexPath { }
- (void)collectionView:(UICollectionView * __unused)collectionView didHighlightItemAtIndexPath:(NSIndexPath * __unused)indexPath { }
- (void)collectionView:(UICollectionView * __unused)collectionView didSelectItemAtIndexPath:(NSIndexPath * __unused)indexPath { }
- (void)collectionView:(UICollectionView * __unused)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath * __unused)indexPath { }

@end
