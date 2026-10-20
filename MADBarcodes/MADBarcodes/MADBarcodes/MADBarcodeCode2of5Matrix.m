//
//  MADBarcodeCode2of5Matrix.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeCode2of5Matrix.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode2of5Matrix

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode2of5Matrix type];
		self.name = @"Code 2 of 5 Matrix";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeC25MATRIX;
}

- (void)loadSampleData {
	self.input = @"11111111111";
	self.primaryData = @"";
}

@end
