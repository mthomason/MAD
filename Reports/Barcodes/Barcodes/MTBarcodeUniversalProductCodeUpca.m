//
//  MTBarcodeUniversalProductCodeUpca.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeUniversalProductCodeUpca.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeUniversalProductCodeUpca

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeUniversalProductCodeUpca type]];
        [self setName: @"Universal Product Code (UPC-A)"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeUpca;
}

@end
