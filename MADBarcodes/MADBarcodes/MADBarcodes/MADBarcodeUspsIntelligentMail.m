//
//  MADBarcodeUspsIntelligentMail.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeUspsIntelligentMail.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeUspsIntelligentMail

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeOneCode;
		self.name = @"USPS OneCode (Intelligent Mail)";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeOneCode;
}

- (void)loadSampleData {
	self.input = @"01234567094987654321-01234567891";
	self.primaryData = @"";
}

@end
