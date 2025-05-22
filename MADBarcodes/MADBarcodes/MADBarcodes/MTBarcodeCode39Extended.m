//
//  MTBarcodeCode39Extended.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCode39Extended.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode39Extended

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeEXCODE39;
        self.name = @"Code 39 Extended";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEXCODE39;
}

- (void)setMod43CheckDigitEnabled:(BOOL)enabled {
    if (enabled) {
        self.option2 = 1;
    } else {
        self.option2 = 0;
    }
}

- (BOOL)mod43CheckDigitEnabled {
    return self.option2 == 1;
}

- (void)loadSampleData {
    self.input = @"*CODE39*";
    self.primaryData = @"";
}

@end
