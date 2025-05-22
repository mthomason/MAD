//
//  MTBarcodeCode2of5Interleaved.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCode2of5Interleaved.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode2of5Interleaved

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeCode2of5Interleaved type];
        self.name = @"Code 2 of 5 Interleaved";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeC25INTER;
}

- (void)loadSampleData {
    self.input = @"11111111111";
    self.primaryData = @"";
}

@end
