//
//  MADBarcodeCode11.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeCode11.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode11

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode11 type];
		self.name = @"Code 11";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCode11;
}

- (void)loadSampleData {
	self.input = @"555-555-0199";
	self.primaryData = @"";
}

@end
