//
//  MADBarcodeCodeOne.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeCodeOne.h"

@interface MADBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeCodeOne

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeCodeOne type];
		self.name = @"Code One";
		self.has2dComponent = NO;
		self.hasOptionalInput = YES;
		self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasCodeOne";
   
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeCodeOne;
}

- (void)setSize:(NSInteger)size {
	self.option2 = (int16_t)size;
}

- (NSInteger)size {
	return self.option2;
}

- (void)loadSampleData {
	self.input = @"http://www.everydayapps.com/";
	self.primaryData = @"";
}

@end
