//
//  MADBarcodeCode39Iso16388.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeCode39Iso16388.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode39Iso16388

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeCODE39;
		self.name = @"Code 39 (ISO 16388)";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		
	}
	return self;
}

+ (MADBarcodeType)type { return MADBarcodeTypeCODE39; }

- (void)setMod43CheckDigitEnabled:(BOOL)enabled {
	self.option2 = enabled ? 1 : 0;
}

- (BOOL)mod43CheckDigitEnabled {
	return self.option2 == 1;
}

@end

@implementation MADBarcodeCode39Hbic

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeHibc39;
		self.name = @"Code 39 (HBIC)";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeHibc39;
}

- (void)loadSampleData {
	self.input = @"*CODE39*";
	self.primaryData = @"";
}

@end
