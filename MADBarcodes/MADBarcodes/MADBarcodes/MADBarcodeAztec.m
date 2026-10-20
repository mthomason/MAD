//
//  MADBarcodeAztec.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeAztec.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeAztec

- (instancetype)init {

	if (self = [super init]) {
		self.barcodeType = [MADBarcodeAztec type];
		self.name = @"Aztec Code (ISO 24778)";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasAztec";
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeAztec;
}

- (MADBarcodeAztecSizingMode)sizingMode {
	MADBarcodeAztecSizingMode result = MADBarcodeAztecSizingModeAutomaticResizing;
	if (self.option1 == NO && self.option2 == NO && self.option3 == NO) {
		result = MADBarcodeAztecSizingModeAutomaticResizing;
	} else if (self.option1 != NO) {
		result = MADBarcodeAztecSizingModeSpecificErrorLevel;
	} else if (self.option2 != NO) {
		result = MADBarcodeAztecSizingModeSpecificSize;
	}
	
	return result;
}

- (void)enableAutomaticResizing {
	[self setOption1:NO];
	[self setOption2:NO];
	[self setOption3:NO];
}
- (void)setSize:(MADBarcodeAztecSpecificSize)size {
	[self setOption1:NO];
	self.option2 = size;
	[self setOption3:NO];
}
- (void)setMinmumErrorCorrection:(MADBarcodeAztecErrorCorrection)minmumErrorCorrection {
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
