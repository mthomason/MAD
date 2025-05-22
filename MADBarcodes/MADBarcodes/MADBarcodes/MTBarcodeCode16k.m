//
//  MTBarcodeCode16k.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCode16k.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode16k

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeCode16k type];
        self.name = @"Code 16k";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODE16K;
}

- (void)loadSampleData {
    self.input = @"Code 16k";
    self.primaryData = @"";
}

@end
