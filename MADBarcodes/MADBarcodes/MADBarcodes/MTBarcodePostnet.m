//
//  MTBarcodePostnet.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodePostnet.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePostnet

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodePostnet type];
        self.name = @"Postnet";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePostnet;
}

- (void)loadSampleData {
    self.input = @"45202";
    self.primaryData = @"";
}

@end
