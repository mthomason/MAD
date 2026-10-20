//
//  MADBarcodeMicroPdf417Iso24728.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeMicroPdf417Iso24728.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeMicroPdf417Iso24728

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeMicroPdf417Iso24728 type];
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasMicroPdf417";
		self.name = @"MicroPDF417 (ISO 24728)";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeMicroPdf417;
}

- (NSInteger)numberOfDataColumns {
	return self.option2;
}

- (NSInteger)errorCorrectionCapacity {
	return self.option1;
}

- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns {
	self.option2 = numberOfDataColumns;
}

- (void)loadSampleData {
	self.input = self.name;
	self.primaryData = @"";
}

@end
