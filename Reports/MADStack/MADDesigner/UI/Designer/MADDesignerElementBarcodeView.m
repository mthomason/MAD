//
//  MADDesignerElementBarcodeView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerElementBarcodeView.h"
#import <MADBarcodes/MTBarcode.h>
#import <MADCocoaExtensions/MADColor.h>

@implementation MADDesignerElementBarcodeView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self.displayObject loadSampleData];
    MADColor *color = [[MADColor alloc] initWithColor:[UIColor lightGrayColor]];
    ((MTBarcode *)self.displayObject).forgroundColor = color;
}

- (void)updateWithElement:(RptqDocumentElement *)element {
    [super updateWithElement:element];
    
    MTBarcode *barcode;
    barcode = [MTBarcode newBarcode:(id <MTBarcodeProtocol>)element];
    self.displayObject = barcode;
    
}

@end
