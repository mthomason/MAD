//
//  MADBarcodeAztecRunes.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeAztecRunes.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeAztecRunes

- (instancetype)init {
	if (self = [super init]) {
		self.barcodeType = [MADBarcodeAztecRunes type];
		self.name = @"Aztec Runes";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeAzrune;
}

- (void)loadSampleData {
	self.input = @"314159265359";
	self.primaryData = @"";
}

@end
