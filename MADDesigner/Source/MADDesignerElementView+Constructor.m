//
//  MADDesignerElementView+Constructor.m
//  MAD Designer
//
//  Created by Michael on 9/2/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDesignerElementView+Constructor.h"
#import <MAD/RptqStoreContext.h>
#import "MADDesignerElementTextView.h"
#import "MADDesignerElementBarcodeView.h"
#import "MADDesignerElementImageView.h"
#import "UITapGestureRecognizer+Designer.h"
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>

@interface MADDesignerElementView ()

	@property (nonatomic, readwrite, weak) RptqStoreContext *managedObjectContext;
	@property (nonatomic, readwrite, assign) int64_t objectID;

@end

@implementation MADDesignerElementView (Constructor)

+ (instancetype)newDesignerElementView:(RptqDocumentElement *)documentObject
					tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
						   tapSelector:(SEL)selector {
	CGRect rect = MADRectOfSize([documentObject sizeCalculated]);
	MADDesignerElementView <MADDesignerElementViewProtocol, MADManagedObjectViewProtocol> *elementView;
	switch (documentObject.documentObjectType) {
		case MADPrintPageElementTypeImage:
			elementView = [[MADDesignerElementImageView alloc] initWithFrame:rect];
			break;
		case MADPrintPageElementTypeBarcode:
			elementView = [[MADDesignerElementBarcodeView alloc] initWithFrame:rect];
			break;
		default:
			elementView = [[MADDesignerElementTextView alloc] initWithFrame:rect];
			break;
	}
	
	if (elementView) {
		
		elementView.identifier = documentObject.identifier;
		elementView.objectID = documentObject.identifier;
		[elementView updateWithElement:documentObject];
		
		elementView.managedObjectContext = documentObject.storeContext;
		UIGestureRecognizer *tap = [MADTapGestureRecognizer newTapGestureRecognizerTapWithTarget: tapGestureDelegate
																						  action: selector
																						delegate: tapGestureDelegate];
		[elementView addGestureRecognizer:tap];
	}
	return elementView;
}

@end
