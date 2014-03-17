//
//  MTBarcodeEan14.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeEan14.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeEan14

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeEan14 type]];
        [self setName: @"EAN-14"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEan14;
}

- (void)initSampleData {
    [self setInput:              @"1111111111111"];
    [self setPrimaryData:        @""];
}

@end
