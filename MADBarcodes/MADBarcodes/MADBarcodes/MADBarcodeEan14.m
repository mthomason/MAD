//
//  MADBarcodeEan14.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeEan14.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeEan14

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeEan14;
		self.name = @"EAN-14";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeEan14;
}

- (void)loadSampleData {
	self.input = @"1111111111111";
	self.primaryData = @"";
}

@end
