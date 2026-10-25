//
//  MADBarcodeAusPostStandardCustomer.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeAusPostStandardCustomer.h"

@interface MADBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeAusPostStandardCustomer

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeAusPostStandardCustomer type];
		self.name = @"Australia Post Standard Customer";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeAuspost;
}

- (void)loadSampleData {
	self.input = @"39549554";
	self.primaryData = @"";
}

@end
