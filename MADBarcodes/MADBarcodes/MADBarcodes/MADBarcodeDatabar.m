//
//  MADBarcodeDatabar.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeDatabar.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeDatabar

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeDatabar type];
		self.name = @"Databar";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeRss14;
}

- (void)loadSampleData {
	self.input = @"6660000000001";
	self.primaryData = @"";
}

@end
