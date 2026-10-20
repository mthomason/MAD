//
//  MTBarcodeDeutschePostIdentcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeDeutschePostIdentcode.h"

@interface MTBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDeutschePostIdentcode

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = [MTBarcodeDeutschePostIdentcode type];
		self.name = @"Deutsche Post Identcode";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MTBarcodeType)type {
	return MTBarcodeTypeDPIDENT;
}

- (void)loadSampleData {
	self.input = @"11111111111";
	self.primaryData = @"";
}

@end
