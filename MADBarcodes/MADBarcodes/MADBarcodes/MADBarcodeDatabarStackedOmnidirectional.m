//
//  MADBarcodeDatabarStackedOmnidirectional.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeDatabarStackedOmnidirectional.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeDatabarStackedOmnidirectional

- (instancetype)init {
	if (self = [super init]) {
		self.barcodeType = [MADBarcodeDatabarStackedOmnidirectional type];
		self.name = @"Databar Stacked Omnidirectional";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeRss14StackOmni;
}

- (void)loadSampleData {
	self.input = @"1111111999999";
	self.primaryData = @"";
}

@end
