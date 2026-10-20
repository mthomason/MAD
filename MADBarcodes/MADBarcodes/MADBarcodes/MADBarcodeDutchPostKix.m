//
//  MADBarcodeDutchPostKix.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarcodeDutchPostKix.h"

@interface MADBarcode ()

	@property (nonatomic, strong, readwrite) NSString *name;
	@property (nonatomic, assign, readwrite) int16_t barcodeType;
	@property (nonatomic, assign, readwrite) BOOL has2dComponent;
	@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MADBarcodeDutchPostKix

- (instancetype)init {

	if (self = [super init]) {
		
		self.barcodeType = [MADBarcodeDutchPostKix type];
		self.name = @"Dutch Post KIX";
		self.has2dComponent = NO;
		self.hasOptionalInput = NO;
		
	}
	return self;
}

+ (MADBarcodeType)type {
	return MADBarcodeTypeKix;
}

- (void)loadSampleData {
	self.input = @"DUTCHPOSTKX";
	self.primaryData = @"";
}

@end
