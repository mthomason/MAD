//
//  MTBarcodeAztecRunes.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAztecRunes.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAztecRunes

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeAztecRunes type]];
        [self setName: @"Aztec Runes"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeAzrune;
}

- (void)initSampleData {
    [self setInput:              @"314159265359"];
    [self setPrimaryData:        @""];
}

@end
