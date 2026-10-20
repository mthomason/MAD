//
//  MADBarcodeUkPlessey.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeUkPlessey.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeUkPlessey

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeUkPlessey type];
		self.name = @"UK Plessey";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypePlessey;
}

- (void)loadSampleData {
	self.input = @"87654321";
	self.primaryData = @"";
}

@end
