//
//  MTBarcodeJapanesePostalBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeJapanesePostalBarcode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeJapanesePostalBarcode

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = MTBarcodeTypeJapanPost;
        self.name = @"Japanese Postal Barcode";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypeJapanPost; }

- (void)initSampleData {
    self.input = @"Japanese-Postal-Barcode";
    self.primaryData = @"";
}

@end
