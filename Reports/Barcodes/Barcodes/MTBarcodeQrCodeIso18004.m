//
//  MTBarcodeQrCodeIso18004.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

- (instancetype)init {
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

- (MTBarcodeSizingMode)sizingMode {
    MTBarcodeSizingMode result = MTBarcodeSizingModeAutomaticResizing;
    if ([self option1] == NO && [self option2] == NO && [self option3] == NO) {
        result = MTBarcodeSizingModeAutomaticResizing;
    } else if ([self option1] != NO) {
        result = MTBarcodeSizingModeSpecificErrorLevel;
    } else if ([self option2] != NO) {
        result = MTBarcodeSizingModeSpecificSize;
    }
    return result;
}

- (void)enableAutomaticResizing {
    [self setOption1:NO];
    [self setOption2:NO];
    [self setOption3:NO];
}
- (void)setSize:(NSInteger)size {
    [self setOption1:NO];
    [self setOption2:size];
    [self setOption3:NO];
}
- (void)setErrorCorrection:(NSInteger)errorCorrection {
    [self setOption1:errorCorrection];
    [self setOption2:NO];
    [self setOption3:NO];
}
- (NSInteger)size {
    return [self option2];
}
- (NSInteger)errorCorrection {
    return [self option1];
}

- (void)initSampleData {
    [self setInput:              @"1Ei3RbGUevDJBVoM93g5ffrSE5snfFvfFS"];
    [self setPrimaryData:        @""];
}

@end
