//
//  MADBarcodeCodabar.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBarcodeCodabar.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCodabar

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCodabar type];
		self.name = @"Codabar";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCODABAR;
}

- (void)loadSampleData {
	self.input = @"9-$:/.+D";
	self.primaryData = @"";
}

@end
