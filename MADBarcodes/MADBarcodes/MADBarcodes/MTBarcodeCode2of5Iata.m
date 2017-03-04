//
//  MTBarcodeCode2of5Iata.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode2of5Iata.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode2of5Iata

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeC25IATA;
        self.name = @"Code 2 of 5 IATA";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeC25IATA;
}

- (void)loadSampleData {
    self.input = @"11111111111";
    self.primaryData = @"";
}

@end
