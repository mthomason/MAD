//
//  MTBarcodeNve18.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeNve18.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeNve18

- (instancetype)init {
    if (self = [super init]) {
        
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

- (void)loadSampleData {
    self.input = @"12345678901234567";
    self.primaryData = @"";
}

@end
