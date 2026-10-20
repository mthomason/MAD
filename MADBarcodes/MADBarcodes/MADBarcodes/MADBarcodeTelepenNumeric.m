//
//  MADBarcodeTelepenNumeric.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeTelepenNumeric.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeTelepenNumeric

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeTelepenNumeric type];
		self.name = @"Telepen Numeric";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeTelepenNum;
}

- (void)loadSampleData {
	self.input = @"466X33";
	self.primaryData = @"";
}

@end
