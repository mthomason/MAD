//
//  MTBarcodeMaxicodeIso16023.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeMaxicodeIso16023.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
//@property (nonatomic, retain, readwrite) NSString *primaryData;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeMaxicodeIso16023

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeMaxicodeIso16023 type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasMaxicode"];
        [self setName: @"Maxicode (ISO 16023)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        [self setOption1:-1];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMaxicode;
}

- (void)setPrimaryDataString:(NSString *)primaryData {
    if (primaryData) {
        [self setPrimaryData:primaryData];
    } else {
        [self setPrimaryData:@""];
    }
}

- (void)setEncodingMode:(NSInteger)encodingMode {
    if (encodingMode == -1 || encodingMode == 2 || encodingMode == 3 || encodingMode == 4 || encodingMode == 5 || encodingMode == 6) {
        [self setOption1:encodingMode];
    }
}

- (NSInteger)encodingMode {
    return [self option1];
}

- (NSString *)primaryDataString {
    return [self primaryData];
}

- (void)initSampleData {
    [self setInput:              @"666001433"];
    [self setPrimaryData:        @"MAD Designer"];
}

@end
