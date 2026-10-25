//
//  MADBarcodeFacingIdentificationMarkFim.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeFacingIdentificationMarkFim.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeFacingIdentificationMarkFim

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeFacingIdentificationMarkFim type];
		self.name = @"Facing Identification Mark (FIM)";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeFim;
}

- (void)loadSampleData {
	self.input = @"A";
	self.primaryData = @"";
}

@end
