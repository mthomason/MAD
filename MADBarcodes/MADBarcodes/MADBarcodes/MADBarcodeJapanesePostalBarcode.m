//
//  MADBarcodeJapanesePostalBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeJapanesePostalBarcode.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeJapanesePostalBarcode

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeJapanPost;
		self.name = @"Japanese Postal Barcode";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type { return MADBarcodeTypeJapanPost; }

- (void)loadSampleData {
	self.input = @"Japanese-Postal-Barcode";
	self.primaryData = @"";
}

@end
