//
//  MTBarcodeDatabarExpandedStacked.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeDatabarExpandedStacked.h"

@interface MTBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarExpandedStacked

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = [MTBarcodeDatabarExpandedStacked type];
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasDataBarExpandedStacked";
		self.name = @"Databar Expanded Stacked";
		self.has2dComponent = YES;
		self.hasOptionalInput = YES;
		
	}
	return self;
}

+ (MTBarcodeType)type {
	return MTBarcodeTypeRssExpstack;
}

- (NSInteger)numberOfDataColumns {
	return self.option2;
}

- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns {
	self.option2 = numberOfDataColumns;
}

- (void)loadSampleData {
	self.input = @"1666666666661";
	self.primaryData = @"";
}

@end
