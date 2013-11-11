//
//  MTBarcodeDatabarStackedOmnidirectional.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDatabarStackedOmnidirectional.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarStackedOmnidirectional

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeDatabarStackedOmnidirectional type]];
        [self setName: @"Databar Stacked Omnidirectional"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRss14OmniCc;
}

@end
