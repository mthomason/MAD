//
//  MTBarcodePdf417Iso15438.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodePdf417Iso15438.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePdf417Iso15438

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodePdf417Iso15438 type]];
        [self setName: @"PDF417 (ISO 15438)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePdf417;
}

@end
