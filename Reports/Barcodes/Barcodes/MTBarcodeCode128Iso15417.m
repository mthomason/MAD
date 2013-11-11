//
//  MTBarcodeCode128Iso15417.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode128Iso15417.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode128Iso15417

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCode128Iso15417 type]];
        [self setName: @"Code 128 (ISO 15417)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODE128;
}

@end
