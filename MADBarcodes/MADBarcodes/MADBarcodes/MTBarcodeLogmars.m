//
//  MTBarcodeLogmars.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeLogmars.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeLogmars

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = [MTBarcodeLogmars type];
        self.name = @"LOGMARS";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeLogmars;
}

- (void)initSampleData {
    self.input = self.name;
    self.primaryData = @"";
}

@end
