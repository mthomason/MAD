//
//  MTBarcodeQrCodeIso18004.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeQrCodeIso18004.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeQrCodeIso18004

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeQrCodeIso18004 type]];
        [self setName: @"QR Code (ISO 18004)"];
        [self setDetailsSegueIdentifer: @"MTIdentiferSegueBarcodeExtrasQrCode"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeOneCode;
}

@end
