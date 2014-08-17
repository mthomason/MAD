//
//  MTBarcodeEuropeanArticleNumberEan.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeEuropeanArticleNumberEan.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeEuropeanArticleNumberEan

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeEuropeanArticleNumberEan type]];
        [self setName: @"European Article Number (EAN)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEANX;
}

- (void)initSampleData {
    [self setInput:              @"54321"];
    [self setPrimaryData:        @""];
}

@end
