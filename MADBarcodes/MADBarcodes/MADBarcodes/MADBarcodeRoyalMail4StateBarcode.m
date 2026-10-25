//
//  MADBarcodeRoyalMail4StateBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeRoyalMail4StateBarcode.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeRoyalMail4StateBarcode

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeRoyalMail4StateBarcode type];
		self.name = @"Royal Mail 4-state Barcode";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeRm4scc;
}

- (void)loadSampleData {
	self.input = @"W1J0TR01";
	self.primaryData = @"";
}

@end
