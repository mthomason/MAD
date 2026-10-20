//
//  MADBarcodeInternationalStandardBookNumberIsbn.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeInternationalStandardBookNumberIsbn.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeInternationalStandardBookNumberIsbn

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = MADBarcodeTypeIsbnX;
		self.name = @"International Standard Book Number (ISBN)";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return [MADBarcodeInternationalStandardBookNumberIsbn type];
}

- (void)loadSampleData {
	self.input = @"0812511816";
	self.primaryData = @"";
}

@end
