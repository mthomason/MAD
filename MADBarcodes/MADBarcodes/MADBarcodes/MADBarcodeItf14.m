//
//  MADBarcodeItf14.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeItf14.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeItf14

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeItf14 type];
		self.name = @"ITF-14";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeItf14;
}

- (void)loadSampleData {
	self.input = @"9891234567890";
	self.primaryData = @"";
}

@end
