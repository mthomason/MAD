//
//  MTBarcodeCode2of5DataLogic.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode2of5DataLogic.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode2of5DataLogic

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = [MTBarcodeCode2of5DataLogic type];
        self.name = @"Code 2 of 5 Data Logic";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeC25LOGIC;
}

- (void)initSampleData {
    self.input = @"11111111111";
    self.primaryData = @"";
}

@end
