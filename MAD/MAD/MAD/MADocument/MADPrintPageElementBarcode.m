//
//  MADPrintPageElementBarcode.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPrintPageElementBarcode.h"

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

#import <MADBarcodes/MTBarcode.h>

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

@implementation MADPrintPageElementBarcode {
    MTBarcode *_drawingObject;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceBarcode *)definition {
    if (self = [super init]) {
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        datasource = definition.datasource;
        
        NSDictionary *rowData = [datasource dataForRow:definition.detailRowId];
        
        NSString *tableFieldKey1 = definition.fieldKey1,
                 *tableFieldKey2 = definition.fieldKey2;
        
        id value1 = rowData[tableFieldKey1], value2 = rowData[tableFieldKey2];
        NSString *input1 = [definition formattedStringForValue1: value1];
        NSString *input2 = [definition formattedStringForValue2: value2];
        
        MTBarcode *barcode = [MTBarcode newBarcode:definition.barcode
                                            input1:input1
                                            input2:input2];
        _drawingObject = barcode;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [_drawingObject drawInRect:rect];
}

@end
