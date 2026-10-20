//
//  MADBarcodeNve18.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeNve18.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeNve18

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeNve18;
		self.name = @"NVE-18";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeNve18;
}

- (void)loadSampleData {
	self.input = @"12345678901234567";
	self.primaryData = @"";
}

@end
