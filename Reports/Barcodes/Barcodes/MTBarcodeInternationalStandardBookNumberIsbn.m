//
//  MTBarcodeInternationalStandardBookNumberIsbn.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeInternationalStandardBookNumberIsbn.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeInternationalStandardBookNumberIsbn

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:MTBarcodeTypeIsbnX];
        [self setName: @"International Standard Book Number (ISBN)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return [MTBarcodeInternationalStandardBookNumberIsbn type];
}

- (void)initSampleData {
    [self setInput:              @"0812511816"];
    [self setPrimaryData:        @""];
}

@end
