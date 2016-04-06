//
//  MTBarcodeCode2of5Industrial.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode2of5Industrial.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode2of5Industrial

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeC25IND;
        self.name = @"Code 2 of 5 Industrial";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeC25IND;
}

- (void)initSampleData {
    [self setInput:              @"11111111111"];
    [self setPrimaryData:        @""];
}

@end
