//
//  MTBarcodeCodabar.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCodabar.h"

@interface MTBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCodabar

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MTBarcodeCodabar type];
		self.name = @"Codabar";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MTBarcodeType)type {
	return MTBarcodeTypeCODABAR;
}

- (void)loadSampleData {
	self.input = @"9-$:/.+D";
	self.primaryData = @"";
}

@end
