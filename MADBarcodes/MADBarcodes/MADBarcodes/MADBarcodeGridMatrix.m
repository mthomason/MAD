//
//  MADBarcodeGridMatrix.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeGridMatrix.h"

@interface MADBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeGridMatrix

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeGridMatrix type];
		self.name = @"Grid Matrix";
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasGridMatrix";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeGridMatrix;
}

- (MADBarcodeSizingMode)sizingMode {
	MADBarcodeSizingMode result = MADBarcodeSizingModeAutomaticResizing;
	if (self.option1 == NO && self.option2 == NO && self.option3 == NO) {
		result = MADBarcodeSizingModeAutomaticResizing;
	} else if (self.option1 != NO) {
		result = MADBarcodeSizingModeSpecificErrorLevel;
	} else if (self.option2 != NO) {
		result = MADBarcodeSizingModeSpecificSize;
	}
	return result;
}

- (void)enableAutomaticResizing {
	[self setOption1:NO];
	[self setOption2:NO];
	[self setOption3:NO];
}
- (void)setSize:(NSInteger)size {
	[self setOption1:NO];
	self.option2 = (int16_t)size;
	[self setOption3:NO];
}
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection {
	self.option1 = (int16_t)minmumErrorCorrection;
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
	self.input = @"http://www.everydayapps.com/";
	self.primaryData = @"";
}

@end
