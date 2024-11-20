//
//  MTBarcodeCode39Iso16388.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCode39Iso16388.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode39Iso16388

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeCODE39;
        self.name = @"Code 39 (ISO 16388)";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypeCODE39; }

- (void)setMod43CheckDigitEnabled:(BOOL)enabled {
    self.option2 = enabled ? 1 : 0;
}

- (BOOL)mod43CheckDigitEnabled {
    return self.option2 == 1;
}

@end

@implementation MTBarcodeCode39Hbic

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeHibc39;
        self.name = @"Code 39 (HBIC)";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeHibc39;
}

- (void)loadSampleData {
    self.input = @"*CODE39*";
    self.primaryData = @"";
}

@end
