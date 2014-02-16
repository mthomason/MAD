//
//  MTBarcodePharmaZentralnummerPzn.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodePharmaZentralnummerPzn.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePharmaZentralnummerPzn

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodePharmaZentralnummerPzn type]];
        [self setName: @"Pharma Zentralnummer (PZN)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePzn;
}

- (void)initSampleData {
    [self setInput:              @"123456"];
    [self setPrimaryData:        @""];
}

@end
