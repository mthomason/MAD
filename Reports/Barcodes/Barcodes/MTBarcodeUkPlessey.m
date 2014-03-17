//
//  MTBarcodeUkPlessey.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeUkPlessey.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeUkPlessey

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeUkPlessey type]];
        [self setName: @"UK Plessey"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePlessey;
}

- (void)initSampleData {
    [self setInput:              @"87654321"];
    [self setPrimaryData:        @""];
}

@end
