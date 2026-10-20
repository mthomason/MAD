//
//  MTBarcodeAztec.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeAztec.h"

@interface MTBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAztec

- (instancetype)init {

	if (self = [super init]) {
		self.barcodeType = [MTBarcodeAztec type];
		self.name = @"Aztec Code (ISO 24778)";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasAztec";
	}
	return self;
}

+ (MTBarcodeType)type {
	return MTBarcodeTypeAztec;
}

- (MTBarcodeAztecSizingMode)sizingMode {
	MTBarcodeAztecSizingMode result = MTBarcodeAztecSizingModeAutomaticResizing;
	if (self.option1 == NO && self.option2 == NO && self.option3 == NO) {
		result = MTBarcodeAztecSizingModeAutomaticResizing;
	} else if (self.option1 != NO) {
		result = MTBarcodeAztecSizingModeSpecificErrorLevel;
	} else if (self.option2 != NO) {
		result = MTBarcodeAztecSizingModeSpecificSize;
	}
	
	return result;
}

- (void)enableAutomaticResizing {
	[self setOption1:NO];
	[self setOption2:NO];
	[self setOption3:NO];
}
- (void)setSize:(MTBarcodeAztecSpecificSize)size {
	[self setOption1:NO];
	self.option2 = size;
	[self setOption3:NO];
}
- (void)setMinmumErrorCorrection:(MTBarcodeAztecErrorCorrection)minmumErrorCorrection {
	self.option1 = minmumErrorCorrection;
	[self setOption2:NO];
	[self setOption3:NO];
}
- (NSInteger)size {
	return self.option2;
}
- (NSInteger)errorCorrection {
	return self.option1;
}

- (void)loadSampleData {
	self.input = @"Sample Data";
	self.primaryData = @"";
}

@end
