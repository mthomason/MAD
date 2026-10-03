//
//  MADDesignerElementBarcodeView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerElementBarcodeView.h"
#import <MAD/RptqDocumentElement+Extras.h>
#import <MADBarcodes/MTBarcode.h>
#import <MADCocoaExtensions/MADColor.h>

@implementation MADDesignerElementBarcodeView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	RptqDocumentElement *element = (RptqDocumentElement *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:self.objectID];
	[self.displayObject loadSampleData];
	//MADColor *color = [[MADColor alloc] initWithColor:[UIColor lightGrayColor]];
	//((MTBarcode *)self.displayObject).forgroundColor = color;
	[((MTBarcode *)self.displayObject) drawInRect:[element innerRect]];
}

- (void)updateWithElement:(RptqDocumentElement *)element {
	[super updateWithElement:element];
	
	MTBarcode *barcode;
	barcode = [MTBarcode newBarcode:(id <MTBarcodeProtocol>)element];
	self.displayObject = barcode;
	
}

@end
