//
//  MADPrintPageElementBarcode.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElementBarcode.h"
#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectDataReferenceBarcode.h"
#import "MADPrintPageRendererDataSource.h"
#import <MADFoundation/madlog.h>

#import <MADBarcodes/MADBarcode.h>

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

@implementation MADPrintPageElementBarcode {
	MADBarcode *_drawingObject;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceBarcode *)definition {
	if (self = [super init]) {
		NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
		datasource = definition.datasource;
		
		NSError *error = nil;
		NSDictionary *rowData = [datasource dataForRow:definition.detailRowId error:&error];
		if (error != nil) {
			os_log_error(GetMadLog(), "Error getting data for row: %@", error);
		}
		
		NSString *tableFieldKey1 = definition.fieldKey1;
		NSString *tableFieldKey2 = definition.fieldKey2;
		
		id value1 = rowData[tableFieldKey1], value2 = rowData[tableFieldKey2];
		NSString *input1 = [definition formattedStringForValue1: value1];
		NSString *input2 = [definition formattedStringForValue2: value2];
		
		MADBarcode *barcode = [MADBarcode newBarcode:definition.barcode
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
