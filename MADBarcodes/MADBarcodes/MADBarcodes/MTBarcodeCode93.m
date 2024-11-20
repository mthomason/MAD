//
//  MTBarcodeCode93.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCode93.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode93

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeCode93 type];
        self.name = @"Code 93";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODE93;
}

- (void)loadSampleData {
    self.input = @"CODE93";
    self.primaryData = @"";
}

@end
