//
//  MTBarcodeKoreanPostalBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeKoreanPostalBarcode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeKoreanPostalBarcode

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeKoreanPostalBarcode type];
        self.name = @"Korean Postal Barcode";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeKoreaPost;
}

- (void)loadSampleData {
    self.input = @"1234569";
    self.primaryData = @"";
}

@end
