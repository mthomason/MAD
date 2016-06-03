//
//  MTBarcodeNve18.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeNve18.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeNve18

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = MTBarcodeTypeNve18;
        self.name = @"NVE-18";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeNve18;
}

- (void)initSampleData {
    self.input = @"12345678901234567";
    self.primaryData = @"";
}

@end
