//
//  MTBarcodePostnet.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodePostnet.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePostnet

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodePostnet type]];
        [self setName: @"Postnet"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePostnet;
}

- (void)initSampleData {
    [self setInput:              @"45202"];
    [self setPrimaryData:        @""];
}

@end
