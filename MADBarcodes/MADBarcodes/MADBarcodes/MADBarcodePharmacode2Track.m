//
//  MADBarcodePharmacode2Track.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodePharmacode2Track.h"

@interface MADBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodePharmacode2Track

- (instancetype)init {
	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodePharmacode2Track type];
		self.name = @"Pharmacode 2-track";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypePharmaTwo;
}

- (void)loadSampleData {
	self.input = @"64570080";
	self.primaryData = @"";
}

@end
