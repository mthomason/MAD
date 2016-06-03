//
//  MTBarcodeMaxicodeIso16023.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeMaxicodeIso16023.h"
#import <Foundation/NSString.h>

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeMaxicodeIso16023

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeMaxicode;
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasMaxicode";
        self.name = @"Maxicode (ISO 16023)";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        self.option1 = -1;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMaxicode;
}

- (void)setPrimaryDataString:(NSString *)primaryData {
    if (primaryData) {
        NSString *pdata = primaryData.copy;
        self.primaryData = pdata;
    } else {
        self.primaryData = @"";
    }
}

- (void)setEncodingMode:(NSInteger)encodingMode {
    if (encodingMode == -1 || encodingMode == 2 || encodingMode == 3 || encodingMode == 4 || encodingMode == 5 || encodingMode == 6) {
        self.option1 = encodingMode;
    }
}

- (NSInteger)encodingMode {
    return self.option1;
}

- (NSString *)primaryDataString {
    return self.primaryData;
}

- (void)initSampleData {
    self.input = @"666001433";
    self.primaryData = @"MAD Designer";
}

@end
