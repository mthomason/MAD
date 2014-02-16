//
//  MTBarcodeRoyalMail4StateBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeRoyalMail4StateBarcode.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeRoyalMail4StateBarcode

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeRoyalMail4StateBarcode type]];
        [self setName: @"Royal Mail 4-state Barcode"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRm4scc;
}

- (void)initSampleData {
    [self setInput:              @"W1J0TR01"];
    [self setPrimaryData:        @""];
}

@end
