//
//  MADBarcodeCode128Iso15417.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeCode128Iso15417.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCode128Iso15417

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode128Iso15417 type];
		self.name = @"Code 128 (ISO 15417)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCODE128;
}

- (void)loadSampleData {
	self.input = @"Code 128";
	self.primaryData = @"";
}

@end

@implementation MADBarcodeCode128SubsetB

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode128SubsetB type];
		self.name = @"Code 128 (Subset C Suppression)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCode128b;
}

- (void)loadSampleData {
	self.input = @"Code 128b";
	self.primaryData = @"";
}

@end

@implementation MADBarcodeCode128Ean14

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode128Ean14 type];
		self.name = @"Code 128 (EAN-14)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeEan14;
}

- (void)loadSampleData {
	self.input = @"9889876543210";
	self.primaryData = @"";
}

@end

@implementation MADBarcodeCode128Nve18

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode128Nve18 type];
		self.name = @"Code 128 (HBIC)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeNve18;
}

- (void)loadSampleData {
	self.input = @"13666666666666613";
	self.primaryData = @"";
}

@end

@implementation MADBarcodeCode128Hibc

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode128Hibc type];
		self.name = @"Code 128 (GS1-128)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeHibc128;
}

- (void)loadSampleData {
	self.input = @"27182818";
	self.primaryData = @"";
}

@end

@implementation MADBarcodeCode128Ean128

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCode128Hibc type];
		self.name = @"Code 128 (GS1-128)";
		self.has2dComponent = YES;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeEAN128;
}

- (void)loadSampleData {
	self.input = @"27182818";
	self.primaryData = @"";
}

@end
