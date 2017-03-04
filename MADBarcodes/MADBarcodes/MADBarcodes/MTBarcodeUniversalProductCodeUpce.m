//
//  MTBarcodeUniversalProductCodeUpce.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeUniversalProductCodeUpce.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeUniversalProductCodeUpce

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeUpce;
        self.name = @"Universal Product Code (UPC-E)";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeUpce;
}

- (void)loadSampleData {
    self.input = @"1123456";
    self.primaryData = @"";
}

@end
