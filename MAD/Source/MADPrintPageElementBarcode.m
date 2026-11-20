//
//  MADPrintPageElementBarcode.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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

		// A row read is needed only for a field-backed input; a static input (or an
		// unbound one) answers from the element, with no row key to look up.
		BOOL needsRow = !definition.usesStaticInput1 || !definition.usesStaticInput2;
		NSDictionary *rowData = nil;
		if (needsRow) {
			NSError *error = nil;
			rowData = [datasource dataForRow:definition.detailRowId error:&error];
			if (error != nil) {
				os_log_error(GetMadLog(), "Error getting data for row: %@", error);
			}
		}

		NSString *fieldKey1 = definition.usesStaticInput1 ? nil : definition.fieldKey1;
		NSString *fieldKey2 = definition.usesStaticInput2 ? nil : definition.fieldKey2;
		NSString *input1 = definition.usesStaticInput1
			? definition.staticInput1
			: (fieldKey1 != nil ? [definition formattedStringForValue1: rowData[fieldKey1]] : @"");
		NSString *input2 = definition.usesStaticInput2
			? definition.staticInput2
			: (fieldKey2 != nil ? [definition formattedStringForValue2: rowData[fieldKey2]] : @"");

		MADBarcode *barcode = [MADBarcode newBarcode:definition.barcode
											input1:input1
											input2:input2];
		_drawingObject = barcode;

		// The line representations read -text; the barcode's content is the input the
		// drawing object encodes, first input then the optional second one.
		NSMutableString *text = [[NSMutableString alloc] initWithString:input1 ?: @""];
		if (input2.length > 0) [text appendString:input2];
		self.text = text;
	}
	return self;
}

- (void)drawInRect:(CGRect)rect {
	[_drawingObject drawInRect:rect];
}

- (NSData *)renderedImageData {
	return [_drawingObject renderedPNGData];
}

@end
