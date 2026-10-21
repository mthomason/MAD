//
//  RptqDocumentElementBarcode+Extras.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocumentElementBarcode+Extras.h"

#import "RptqDocumentElement+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDataHelper.h"

#import <MADFoundation/MADDataType.h>
#import <MADBarcodes/MADBarcodes.h>
#import <MADBarcodes/MADBarcodeType.h>

#import <MADFoundation/madlog.h>

@implementation RptqDocumentElementBarcode (Extras)

@dynamic has2dComponentEnabled;

- (NSString *)designerRepresentationText {
	NSString *barcodeName = [MADBarcode newBarcodeNameForType:barcodeTypeForInt(self.barcodeType)];
	id result = [[NSString alloc] initWithFormat:@"Barcode (%@)", barcodeName];
	return result;
}

- (void)setHas2dComponentEnabled:(BOOL)has2dComponentEnabled {
	self.add2dComponent = has2dComponentEnabled;
}

- (BOOL)has2dComponentEnabled {
	return self.add2dComponent;
}

- (void)updateWithBarcode: (MADBarcode *)barcode
				 field1ID: (int64_t)field1ID
				 field2ID: (int64_t)field2ID {
	RptqStoreContext * storeContext = self.storeContext;

	RptqQueryField *field1 = (RptqQueryField *)[storeContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:field1ID];
	RptqQueryField *field2 = (RptqQueryField *)[storeContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:field2ID];
	
	self.add2dComponent =       @(barcode.has2dComponent);
	self.barcodeBorderStyle =   barcode.barcodeBorderStyle;
	self.barcodeBorderWidth =   barcode.barcodeBorderWidth;
	self.barcodeType =          barcode.barcodeType;
	self.barcodeHeight =        barcode.barcodeHeight;
	self.humanReadable =        barcode.humanReadable;
	self.option1 =              barcode.option1;
	self.option2 =              barcode.option2;
	self.option3 =              barcode.option3;
	self.showErrorMessage =     barcode.showErrorMessage;
	self.whitespaceWidth =      barcode.whitespaceWidth;
	self.scale =                barcode.scale;
	self.referencesField1 =     field1;
	self.referencesField2 =     field2;
	BOOL success = NO;
	NSError * __autoreleasing saveError = nil;
	if (!(success = [storeContext save:&saveError])) {
		os_log_error(OS_LOG_DEFAULT, "Error saving managed object: %@", saveError.localizedDescription);
	}
}

+ (instancetype)barcodeWithMtBarcode:(MADBarcode *)barcode
					   queryFieldOne:(RptqQueryField *)queryFieldOne
					   queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED {
	
	RptqDocumentElementBarcode *reportObject = nil;
	
	if (queryFieldOne != nil) {
	
		NSString *className = NSStringFromClass([RptqDocumentElementBarcode class]);
		RptqStoreContext *objectContext = queryFieldOne.storeContext;

		reportObject = (RptqDocumentElementBarcode *)[objectContext insertObjectForEntity:className identifier:0];
		reportObject.add2dComponent = barcode.has2dComponentEnabled;
		reportObject.barcodeBorderStyle = barcode.barcodeBorderStyle;
		reportObject.barcodeBorderWidth = barcode.barcodeBorderWidth;
		reportObject.backgroundColor = [UIColor whiteColor];
		reportObject.foregroundColor = [UIColor blackColor];
		reportObject.barcodeHeight = barcode.barcodeHeight;
		reportObject.humanReadable = barcode.humanReadable;
		reportObject.option1 = barcode.option1;
		reportObject.option2 = barcode.option2;
		reportObject.option3 = barcode.option3;
		reportObject.showErrorMessage = barcode.showErrorMessage;
		reportObject.type = MADPrintPageElementTypeBarcode;
		reportObject.barcodeType = barcode.barcodeType;
		reportObject.whitespaceWidth = barcode.whitespaceWidth;
		reportObject.useStaticInput1 = NO;
		reportObject.useStaticInput2 = NO;
		reportObject.scale = barcode.scale;
		
		reportObject.referencesField1 = queryFieldOne;
		reportObject.referencesField2 = queryFieldTwo;

	}
	
	return reportObject;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Encoded text:           %@\n", self.toStringHumanReadable];
	[description appendFormat:@"*********"];
	return description;
}

@end
