//
//  MADBarcodeEuropeanArticleNumberEan.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeEuropeanArticleNumberEan.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeEuropeanArticleNumberEan

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeEuropeanArticleNumberEan type];
		self.name = @"European Article Number (EAN)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeEANX;
}

- (void)loadSampleData {
	self.input = @"54321";
	self.primaryData = @"";
}

@end
