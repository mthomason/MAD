//
//  MTBarcodeDataMatrixIso16022.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDataMatrixIso16022.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@property (nonatomic, assign, readwrite) NSInteger option2;
@property (nonatomic, assign, readwrite) NSInteger option3;

@end

@implementation MTBarcodeDataMatrixIso16022

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeDataMatrixIso16022 type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasDataMatrix"];
        [self setName: @"Data Matrix (ISO 16022)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeDataMatrix;
}

- (void)setSymbolSize:(NSInteger)symbolSize {
    [self setOption2:symbolSize];
}

- (void)suppressRectangularSymbolsInAutomaticMode:(BOOL)suppress {
    if (suppress) {
        [self setOption3: DM_SQUARE];
    } else {
        [self setOption3: 0];
    }
}

@end
