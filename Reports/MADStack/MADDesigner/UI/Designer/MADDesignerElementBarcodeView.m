//
//  MADDesignerElementBarcodeView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerElementBarcodeView.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MADBarcodes/MTBarcode.h>
#import <MADCocoaExtensions/MADColor.h>

@implementation MADDesignerElementBarcodeView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	RptqDocumentElement *element = (RptqDocumentElement *)[self.managedObjectContext objectWithID:self.objectID];
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
