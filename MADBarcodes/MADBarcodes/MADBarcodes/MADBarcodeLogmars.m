//
//  MADBarcodeLogmars.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeLogmars.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeLogmars

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeLogmars type];
		self.name = @"LOGMARS";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeLogmars;
}

- (void)loadSampleData {
	self.input = self.name;
	self.primaryData = @"";
}

@end
