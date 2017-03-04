//
//  MTBarcodeAztecRunes.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAztecRunes.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAztecRunes

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeAztecRunes type];
        self.name = @"Aztec Runes";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeAzrune;
}

- (void)loadSampleData {
    self.input = @"314159265359";
    self.primaryData = @"";
}

@end
