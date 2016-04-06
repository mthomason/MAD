//
//  MTBarcodeEan14.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeEan14.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeEan14

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = MTBarcodeTypeEan14;
        self.name = @"EAN-14";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEan14;
}

- (void)initSampleData {
    [self setInput:              @"1111111111111"];
    [self setPrimaryData:        @""];
}

@end
