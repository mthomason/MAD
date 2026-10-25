//
//  MADBarcodeUniversalProductCodeUpca.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeUniversalProductCodeUpca.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeUniversalProductCodeUpca

- (instancetype)init {
	
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeUniversalProductCodeUpca type];
		self.name = @"Universal Product Code (UPC-A)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeUpca;
}

- (void)loadSampleData {
	self.input = @"72527270270+12345";
	self.primaryData = @"";
}

@end
