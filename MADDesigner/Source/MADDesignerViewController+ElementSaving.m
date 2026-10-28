//
//  MADDesignerViewController+ElementSaving.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController+ElementSaving.h"

@implementation MADDesignerViewController (ElementSaving)

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController * __unused)fromViewController
							 sender:(nullable id __unused)sender {
	return action == @selector(unwindToDesigner:);
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController * __unused)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	// FIXME: Add ability to edit image fields.  84848422
	
	UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
	if (selectedImage == nil) {
		selectedImage = info[UIImagePickerControllerOriginalImage];
	}
	
	if (selectedImage != nil) {
		__weak MADDesignerViewController *weakself = self;
		[self dismissViewControllerAnimated:YES completion:^{
			__strong MADDesignerViewController *strongSelf = weakself;
			if (strongSelf != nil) {
				strongSelf.hidesStatusBar = NO;
			}
		}];
		
		NSNumber *type = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeImage];
		NSDictionary *defination = [[NSDictionary alloc] initWithObjectsAndKeys:
									type,           MTDocumentObjectDefinationType,
									selectedImage,  MTDocumentObjectDefinationObject, nil];
		[self insertDocumentObjectWithDefination: defination];
	}
	
	[self setDisplayActive];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController * __unused)picker {
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
	[self setDisplayActive];
}

#pragma mark -
#pragma mark MADViewControllerBarcodeDelegate

- (void)didUpdateBarcodeWithObjectID:(int64_t)barcodeObjectID
					   barcodeObject:(MADBarcode *)barcode
						withFieldOne:(int64_t /* RptqQueryField */)fieldOne
						 andFieldTwo:(int64_t /* RptqQueryField */)fieldTwo {
	
	MADocument *document = self.document;
	RptqStoreContext *private = document.storeContext;
	int64_t barcodeToEditObjectID = barcodeObjectID;

	RptqDocumentElementBarcode *barcodeToEdit = (RptqDocumentElementBarcode *)[private objectForEntity:NSStringFromClass([RptqDocumentElementBarcode class]) identifier:barcodeToEditObjectID];
	[barcodeToEdit updateWithBarcode: barcode field1ID: fieldOne field2ID: fieldTwo];
	NSError *error = NULL;
	[private save:&error];
	if (error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
	}
	[document updateChangeCount: UIDocumentChangeDone];
}

#pragma mark -
#pragma mark MTViewControllerAggregateDelegate

- (void)didUpdateggregateFunctionWithType: (MTAggregateFunctionType)functionType
								inputType: (MTAggregateFunctionInputType __unused)inputType
							  inputObject: (int64_t)objectID
								groupType: (MTAggregateGroupByType)groupType
							  groupNumber: (int32_t)groupNumber {
	MADocument *document = self.document;
	RptqDocumentElementAggregate *aggregateToEdit = (RptqDocumentElementAggregate *)[document.storeContext objectForEntity:NSStringFromClass([RptqDocumentElementAggregate class]) identifier: self.aggregateToEditObjectID];
	[aggregateToEdit updateAggregateFunctionWithFunctionType: functionType
												   inputType: MTAggregateFunctionInputTypeField
												   groupType: groupType
										   aggregateObjectID: objectID
												 groupNumber: i32abs(groupNumber)];
	[document updateChangeCount: UIDocumentChangeDone];
}

#pragma mark -
#pragma mark MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController * __unused)controller
									withFieldID: (int64_t)fieldID {
	
	if (self.objectIdEditDynamicLabel == nil) return;
	RptqStoreContext *context = self.document.storeContext;
	RptqQueryField *field = (RptqQueryField *)[context objectForEntity:NSStringFromClass([RptqQueryField class]) identifier: fieldID];
	RptqDocumentElementLabelDataField *documentObject = [RptqDocumentElementLabelDataField newDocumentElementWithIdentifier: self.objectIdEditDynamicLabel.longLongValue
																										  fromObjectContext: context];
	if (documentObject != nil && field != nil) {
		documentObject.referencesQueryField = field;
		NSError *error = NULL;
		BOOL saved = [documentObject.storeContext save:&error];
		if (!saved && error != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
		} else {
			MADDesignerElementView *elementView = [self elementViewForManagedObject:documentObject];
			if (elementView != nil) {
				[elementView updateWithElement:documentObject];
				[elementView setNeedsDisplay];
			}
		}
	}
	self.objectIdEditDynamicLabel = nil;
}

#pragma mark -
#pragma mark MADElementPickerProtocol

- (void)insertDocumentObjectDataField:(RptqQueryField *)field {
	[self setDisplayActive];
	[self insertDocumentObjectWithDefination: @{
		MTDocumentObjectDefinationType: [NSNumber numberWithShort:MADPrintPageElementTypeLabelDynamic],
		MTDocumentObjectDefinationObject: @(field.identifier),
	}];
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
											   inputType:(MTAggregateFunctionInputType)inputType
											 inputObject:(int64_t)inputObject
											   groupType:(MTAggregateGroupByType)groupType
											 groupNumber:(NSNumber *)groupNumber {
	[self setDisplayActive];
	NSDictionary *documentObject = @{
		MTDocumentObjectDefinationAggregateType: [NSNumber numberWithShort: functionType],
		MTDocumentObjectDefinationAggregatePivotNumber: groupNumber,
		MTDocumentObjectDefinationAggregatePivotType: [NSNumber numberWithShort: groupType],
		MTDocumentObjectDefinationAggregateObjectId: @(inputObject),
		MTDocumentObjectDefinationAggregateFunctionInputType: [NSNumber numberWithShort: inputType],
	};
	
	[self insertDocumentObjectWithDefination: @{
		MTDocumentObjectDefinationType: [NSNumber numberWithShort: MADPrintPageElementTypeAggregate],
		MTDocumentObjectDefinationObject: documentObject,
	}];
	self.hidesStatusBar = NO;
}

- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
	[self setDisplayActive];
	[self insertDocumentObjectWithDefination:@{
		MTDocumentObjectDefinationType: [NSNumber numberWithShort: MADPrintPageElementTypeLabelStatic],
		MTDocumentObjectDefinationObject: labelText,
	}];
}

- (void)insertDocumentObjectWhitespace {
	[self saveWhiteSpace];
}

#pragma mark -
#pragma mark Save after Unwind from Modal View Controller

- (void)saveStaticLabel:(MTDocumentObjectNewStaticLabelViewController *)viewController {
	[self insertDocumentObjectNewLabel: viewController.textField.text];
	[self scrollToDetailSectionView];
}

- (void)saveWhiteSpace {
	NSNumber *type = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeWhtiespace];
	NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys: type, MTDocumentObjectDefinationType, nil];
	[self insertDocumentObjectWithDefination: options];
	[self scrollToDetailSectionView];
}

- (void)saveDynamicLabel:(MADQueryChooseFieldController *)viewController {
	NSNumber *objectID = @(viewController.queryFieldID);
	NSNumber *keyDynamic = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeLabelDynamic];
	NSDictionary *definations = [[NSDictionary alloc] initWithObjectsAndKeys: keyDynamic, MTDocumentObjectDefinationType, objectID, MTDocumentObjectDefinationObject, nil];
	
	[self insertDocumentObjectWithDefination: definations];
	[self scrollToDetailSectionView];
}

- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController {
	
	if (_editAggregate && self.aggregateToEditObjectID != 0) {
		
		if (viewController.fieldObjectID != 0) {
			MADocument *document = self.document;
			RptqDocumentElementAggregate *aggregateToEdit = (RptqDocumentElementAggregate *)[document.storeContext objectForEntity:NSStringFromClass([RptqDocumentElementAggregate class]) identifier: self.aggregateToEditObjectID];
			[aggregateToEdit updateAggregateFunctionWithFunctionType: viewController.aggregateFunctionType
														   inputType: MTAggregateFunctionInputTypeField
														   groupType: viewController.aggregateGroupByType
												   aggregateObjectID: viewController.fieldObjectID
														 groupNumber: viewController.groupTypeSectionNumber];
			[document updateChangeCount: UIDocumentChangeDone];
		}
		
	} else {
		if (viewController.fieldObjectID != 0) {
			
			NSNumber *groupNumber = [[NSNumber alloc] initWithInteger:viewController.groupTypeSectionNumber];
			[self insertDocumentObjectNewAggregateFunctionWithType: viewController.aggregateFunctionType
														 inputType: MTAggregateFunctionInputTypeField
													   inputObject: viewController.fieldObjectID
														 groupType: viewController.aggregateGroupByType
													   groupNumber: groupNumber];
			
		}
	}
	[self scrollToDetailSectionView];
}

- (void)saveBarcodeLabel:(MTViewControllerBarcode *)viewController {
	
	if (self.objectIdEditBarcode != nil) {
		MADocument *document = self.document;
		MADBarcode *barcode = viewController.barcode;
		
		RptqStoreContext *managedObjectContext = document.storeContext;
		RptqDocumentElementBarcode *object = [RptqDocumentElementBarcode newDocumentElementWithIdentifier: self.objectIdEditBarcode.longLongValue
																						fromObjectContext: managedObjectContext];
		[object updateWithBarcode: barcode
						 field1ID: viewController.queryField1ID
						 field2ID: viewController.queryField2ID];
		[document updateChangeCount: UIDocumentChangeDone];
		self.objectIdEditBarcode = nil;
		
	} else {
		
		NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
		NSNumber *type = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeBarcode];
		defination[MTDocumentObjectDefinationType] = type;
		defination[MTDocumentObjectDefinationObject] = viewController.barcode;
		
		int64_t queryField1ID = viewController.queryField1ID;
		if (queryField1ID != 0) {
			defination[MTDocumentObjectDefinationField1] = @(queryField1ID);
		}

		int64_t queryField2ID = viewController.queryField2ID;
		if (queryField2ID != 0) {
			defination[MTDocumentObjectDefinationField2] = @(queryField2ID);
		}
		[self insertDocumentObjectWithDefination: defination];
		
	}
	[self scrollToDetailSectionView];
}

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {
	
	[self setDisplayActive];
	
	MADocument *document = self.document;
	RptqDocument *rptqDocument = document.activeDocumentModel;
	
	MADDesignerSectionView *collectionView = [self getSectionViewForDocumentSection: rptqDocument.hasDetailSection];
	NSNumber *identifier = [[NSNumber alloc] initWithLongLong:collectionView.identifier];
	MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[identifier];
	
	RptqStoreContext *managedObjectContext = document.storeContext;
	
	__weak MADDesignerViewController *weakSelf = self;
	__block CGRect newElementFrame = CGRectZero;
	__block NSIndexPath *newElementPath = nil;
	[collectionView performBatchUpdates:^{
		
		__strong MADDesignerViewController *strongSelf = weakSelf;
		if (!strongSelf) return;
		
		
		RptqDocument *bgRptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: managedObjectContext];
		RptqDocumentSection *bgSection = rptqDocument.hasDetailSection;
		
		RptqDocumentElement *element = [bgRptqDocument addDocumentObject: documentObjectDefination
													managedObjectContext: managedObjectContext];

		NSIndexPath *path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count
												inSection: 0];
		newElementPath = path;
		
		strongSelf->_identifierJustDisplayed = element.identifier;
		
		MADSectionLayoutAttributes *layoutAttribute = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
		layoutAttribute.frame = [element elementViewFrameDesignerFrameCalculated];
		newElementFrame = layoutAttribute.frame;
		
		NSArray *indexPathsInserted = [[NSArray alloc] initWithObjects: path, nil];
		[bgSection addDocumentObject: element
					   withDropPoint: layoutAttribute.frame.origin
				managedObjectContext: managedObjectContext];
		
		[collectionView insertItemsAtIndexPaths: indexPathsInserted];
		
		NSError *saveError = nil;
		BOOL saved = [managedObjectContext save:&saveError];
		if (!saved && saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}

		layoutAttribute.objectID = element.identifier;
		[layoutManager addItem:layoutAttribute];
		[layoutManager layout];
		
	} completion:^(BOOL __unused finished) {
		__strong MADDesignerViewController *strongself = weakSelf;
		if (!strongself) return;
		MADocument *doc = strongself.document;
		[strongself.view.scroller.container setNeedsUpdateConstraints];
		[doc updateChangeCount: UIDocumentChangeDone];
		[doc autosaveWithCompletionHandler:^(BOOL success) {
			if (!success) {
				os_log_info(GetDesignerLog(), "Autosave did not succeed.");
			}
		}];
	}];
}

@end
