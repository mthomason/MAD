//
//  MADBarcodeFlattermarken.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeFlattermarken.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeFlattermarken

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeFlattermarken type];
		self.name = @"Flattermarken";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeFlat;
}

- (void)loadSampleData {
	self.input = @"3301";
	self.primaryData = @"";
}

@end
