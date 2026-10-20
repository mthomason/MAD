//
//  MADBarcodeKoreanPostalBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeKoreanPostalBarcode.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeKoreanPostalBarcode

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeKoreanPostalBarcode type];
		self.name = @"Korean Postal Barcode";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeKoreaPost;
}

- (void)loadSampleData {
	self.input = @"1234569";
	self.primaryData = @"";
}

@end
