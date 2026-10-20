//
//  MADBarcodeDataMatrixIso16022.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeDataMatrixIso16022.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeDataMatrixIso16022

- (instancetype)init {

	if (self = [super init]) {
		self.barcodeType = [MADBarcodeDataMatrixIso16022 type];
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasDataMatrix";
		self.name = @"Data Matrix (ISO 16022)";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeDataMatrix;
}

- (void)setSymbolSize:(NSInteger)symbolSize {
	self.option2 = symbolSize;	// Gives warning: Implicit conversion loses integer precision: 'NSInteger' (aka 'long') to 'int16_t' (aka 'short')
}

- (NSInteger)symbolSize {
	return self.option2;
}

- (void)suppressRectangularSymbolsInAutomaticMode:(BOOL)suppress {
	if (suppress) {
		[self setOption3: DM_SQUARE];
	} else {
		self.option3 = 0;
	}
}

- (BOOL)suppressRectangularSymbols {
	return self.option3 == DM_SQUARE;
}

- (void)loadSampleData {
	self.input = @"Thank you for using MAD Designer. Contact admin@everydayapps.com for your enterprise BI needs.";
	self.primaryData = @"";
}

@end
