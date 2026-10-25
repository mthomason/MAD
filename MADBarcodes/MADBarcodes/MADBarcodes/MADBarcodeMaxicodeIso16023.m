//
//  MADBarcodeMaxicodeIso16023.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeMaxicodeIso16023.h"
#import <Foundation/NSString.h>

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeMaxicodeIso16023

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeMaxicode;
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasMaxicode";
		self.name = @"Maxicode (ISO 16023)";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		self.option1 = -1;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeMaxicode;
}

- (void)setPrimaryDataString:(NSString *)primaryData {
	if (primaryData) {
		NSString *pdata = primaryData.copy;
		self.primaryData = pdata;
	} else {
		self.primaryData = @"";
	}
}

- (void)setEncodingMode:(NSInteger)encodingMode {
	if (encodingMode == -1 || encodingMode == 2 || encodingMode == 3 || encodingMode == 4 || encodingMode == 5 || encodingMode == 6) {
		self.option1 = (int16_t)encodingMode;
	}
}

- (NSInteger)encodingMode {
	return self.option1;
}

- (NSString *)primaryDataString {
	return self.primaryData;
}

- (void)loadSampleData {
	self.input = @"666001433";
	self.primaryData = @"MAD Designer";
}

@end
