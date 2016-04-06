//
//  MTBarcodeDatabarStacked.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDatabarStacked.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarStacked

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeDatabarStacked type];
        self.name = @"Databar Stacked";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRss14Stack;
}

- (void)initSampleData {
    [self setInput:              @"1111111111111"];
    [self setPrimaryData:        @""];
}

@end
