//
//  MADBarcodeCode16k.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeCode16k.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode16k

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode16k type];
		self.name = @"Code 16k";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCODE16K;
}

- (void)loadSampleData {
	self.input = @"Code 16k";
	self.primaryData = @"";
}

@end
