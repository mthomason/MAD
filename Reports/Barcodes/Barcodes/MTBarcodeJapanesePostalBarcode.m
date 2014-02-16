//
//  MTBarcodeJapanesePostalBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeJapanesePostalBarcode.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeJapanesePostalBarcode

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:MTBarcodeTypeJapanPost];
        [self setName: @"Japanese Postal Barcode"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return [MTBarcodeJapanesePostalBarcode type];
}

- (void)initSampleData {
    [self setInput:              @"Japanese-Postal-Barcode"];
    [self setPrimaryData:        @""];
}

@end
