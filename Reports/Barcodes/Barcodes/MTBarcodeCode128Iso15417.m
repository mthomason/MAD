//
//  MTBarcodeCode128Iso15417.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode128Iso15417.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode128Iso15417

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128Iso15417 type]];
        [self setName: @"Code 128 (ISO 15417)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODE128;
}

- (void)initSampleData {
    [self setInput:              @"Code 128"];
    [self setPrimaryData:        @""];
}

@end

@implementation MTBarcodeCode128SubsetB

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128SubsetB type]];
        [self setName: @"Code 128 (Subset C Suppression)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCode128b;
}

- (void)initSampleData {
    [self setInput:              @"Code 128b"];
    [self setPrimaryData:        @""];
}

@end

@implementation MTBarcodeCode128Ean14

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128Ean14 type]];
        [self setName: @"Code 128 (EAN-14)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEan14;
}

- (void)initSampleData {
    [self setInput:              @"9889876543210"];
    [self setPrimaryData:        @""];
}

@end

@implementation MTBarcodeCode128Nve18

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128Nve18 type]];
        [self setName: @"Code 128 (HBIC)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeNve18;
}

- (void)initSampleData {
    [self setInput:              @"13666666666666613"];
    [self setPrimaryData:        @""];
}

@end

@implementation MTBarcodeCode128Hibc

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128Hibc type]];
        [self setName: @"Code 128 (GS1-128)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeHibc128;
}

- (void)initSampleData {
    [self setInput:              @"27182818"];
    [self setPrimaryData:        @""];
}

@end

@implementation MTBarcodeCode128Ean128

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128Hibc type]];
        [self setName: @"Code 128 (GS1-128)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEAN128;
}

- (void)initSampleData {
    [self setInput:              @"27182818"];
    [self setPrimaryData:        @""];
}

@end
