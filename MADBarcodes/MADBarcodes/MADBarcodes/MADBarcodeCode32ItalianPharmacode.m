//
//  MADBarcodeCode32ItalianPharmacode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeCode32ItalianPharmacode.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode32ItalianPharmacode

- (instancetype)init {
	
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode32ItalianPharmacode type];
		self.name = @"Code 32 (Italian Pharmacode)";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCode32;
}

- (void)loadSampleData {
	self.input = @"27182818";
	self.primaryData = @"";
}

@end
