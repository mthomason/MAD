//
//  MADBarcodeQrCodeIso18004.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeQrCodeIso18004.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeQrCodeIso18004

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeQrCodeIso18004 type];
		self.name = @"QR Code (ISO 18004)";
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasQrCode";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeQrcode;
}

- (MADBarcodeSizingMode)sizingMode {
	MADBarcodeSizingMode result = MADBarcodeSizingModeAutomaticResizing;
	if (self.option1 == NO && self.option2 == NO && self.option3 == NO) {
		result = MADBarcodeSizingModeAutomaticResizing;
	} else if (self.option1 != NO) {
		result = MADBarcodeSizingModeSpecificErrorLevel;
	} else if (self.option2 != NO) {
		result = MADBarcodeSizingModeSpecificSize;
	}
	return result;
}

- (void)enableAutomaticResizing {
	[self setOption1:NO];
	[self setOption2:NO];
	[self setOption3:NO];
}
- (void)setSize:(NSInteger)size {
	[self setOption1:NO];
	self.option2 = size;
	[self setOption3:NO];
}
- (void)setErrorCorrection:(NSInteger)errorCorrection {
	self.option1 = errorCorrection;
	[self setOption2:NO];
	[self setOption3:NO];
}
- (NSInteger)size {
	return self.option2;
}
- (NSInteger)errorCorrection {
	return self.option1;
}

- (void)loadSampleData {
	self.input = @"1Ei3RbGUevDJBVoM93g5ffrSE5snfFvfFS";
	self.primaryData = @"";
}

@end
