//
//  MADBarcodeChannelCode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeChannelCode.h"

@interface MADBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeChannelCode

- (instancetype)init {
	if (self = [super init]) {
		self.barcodeType = [MADBarcodeChannelCode type];
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasChannelCode";
		self.name = @"Channel Code";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeChannel;
}

- (void)setNumberOfChannels:(NSInteger)numberOfChannels {
	self.option2 = (int16_t)numberOfChannels;
}

- (NSInteger)numberOfChannels {
	return self.option2;
}

- (void)loadSampleData {
	[self setNumberOfChannels:   4];
	self.input = @"257";
	self.primaryData = @"";
}

@end
