//
//  MTBarcodeGridMatrix.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeGridMatrix.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeGridMatrix

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeGridMatrix type]];
        [self setName: @"Grid Matrix"];
        [self setDetailsSegueIdentifer: @"MTIdentiferSegueBarcodeExtrasGridMatrix"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeGridMatrix;
}

- (MTBarcodeSizingMode)sizingMode {
    MTBarcodeSizingMode result = MTBarcodeSizingModeAutomaticResizing;
    if ([self option1] == NO && [self option2] == NO && [self option3] == NO) {
        result = MTBarcodeSizingModeAutomaticResizing;
    } else if ([self option1] != NO) {
        result = MTBarcodeSizingModeSpecificErrorLevel;
    } else if ([self option2] != NO) {
        result = MTBarcodeSizingModeSpecificSize;
    }
    return result;
}

- (void)enableAutomaticResizing {
    [self setOption1:NO];
    [self setOption2:NO];
    [self setOption3:NO];
}
- (void)setSize:(NSInteger)size {
    [self setOption1:NO];
    [self setOption2:size];
    [self setOption3:NO];
}
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection {
    [self setOption1:minmumErrorCorrection];
    [self setOption2:NO];
    [self setOption3:NO];
}
- (NSInteger)size {
    return [self option2];
}
- (NSInteger)errorCorrection {
    return [self option1];
}

- (void)initSampleData {
    [self setInput:              @"http://www.everydayapps.com/"];
    [self setPrimaryData:        @""];
}

@end
