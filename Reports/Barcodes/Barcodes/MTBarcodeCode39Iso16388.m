//
//  MTBarcodeCode39Iso16388.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode39Iso16388.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode39Iso16388

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode39Iso16388 type]];
        [self setName: @"Code 39 (ISO 16388)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODE39;
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

@implementation MTBarcodeCode39Hbic

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode39Iso16388 type]];
        [self setName: @"Code 39 (HBIC)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeHibc39;
}

- (void)initSampleData {
    [self setInput:              @"*CODE39*"];
    [self setPrimaryData:        @""];
}

@end
