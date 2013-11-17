//
//  MTBarcodeCode39Extended.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode39Extended.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode39Extended

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode39Extended type]];
        [self setName: @"Code 39 Extended"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEXCODE39;
}

- (void)setMod43CheckDigitEnabled:(BOOL)enabled {
    if (enabled) {
        [self setOption2:1];
    } else {
        [self setOption2:0];
    }
}

- (BOOL)mod43CheckDigitEnabled {
    return [self option2] == 1;
}

@end
