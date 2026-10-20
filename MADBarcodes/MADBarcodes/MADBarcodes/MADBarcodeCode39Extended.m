//
//  MADBarcodeCode39Extended.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeCode39Extended.h"

@interface MADBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode39Extended

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeEXCODE39;
		self.name = @"Code 39 Extended";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeEXCODE39;
}

- (void)setMod43CheckDigitEnabled:(BOOL)enabled {
	if (enabled) {
		self.option2 = 1;
	} else {
		self.option2 = 0;
	}
}

- (BOOL)mod43CheckDigitEnabled {
	return self.option2 == 1;
}

- (void)loadSampleData {
	self.input = @"*CODE39*";
	self.primaryData = @"";
}

@end
