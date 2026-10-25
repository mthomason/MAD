//
//  MADDesignerElementBarcodeView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDesignerElementBarcodeView.h"
#import <MAD/RptqDocumentElement+Extras.h>
#import <MADBarcodes/MADBarcode.h>
#import <MADCocoaExtensions/MADColor.h>

@implementation MADDesignerElementBarcodeView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	RptqDocumentElement *element = (RptqDocumentElement *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:self.objectID];
	[self.displayObject loadSampleData];
	//MADColor *color = [[MADColor alloc] initWithColor:[UIColor lightGrayColor]];
	//((MADBarcode *)self.displayObject).forgroundColor = color;
	[((MADBarcode *)self.displayObject) drawInRect:[element innerRect]];
}

- (void)updateWithElement:(RptqDocumentElement *)element {
	[super updateWithElement:element];
	
	MADBarcode *barcode;
	barcode = [MADBarcode newBarcode:(id <MADBarcodeProtocol>)element];
	self.displayObject = barcode;
	
}

@end
