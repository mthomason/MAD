//
//  MADDesignerElementView+Constructor.m
//  MAD Designer
//
//  Created by Michael on 9/2/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerElementView+Constructor.h"
#import "MADDesignerElementTextView.h"
#import "MADDesignerElementBarcodeView.h"
#import "MADDesignerElementImageView.h"
#import "UITapGestureRecognizer+Designer.h"
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>

@interface MADDesignerElementView ()

	@property (nonatomic, readwrite, weak) NSManagedObjectContext *managedObjectContext;
	@property (nonatomic, readwrite, copy) NSManagedObjectID *objectID;

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
		elementView.objectID = documentObject.objectID.copy;
		[elementView updateWithElement:documentObject];
		
		elementView.managedObjectContext = documentObject.managedObjectContext;
		UIGestureRecognizer *tap = [MADTapGestureRecognizer newTapGestureRecognizerTapWithTarget: tapGestureDelegate
																						  action: selector
																						delegate: tapGestureDelegate];
		[elementView addGestureRecognizer:tap];
	}
	return elementView;
}

@end
