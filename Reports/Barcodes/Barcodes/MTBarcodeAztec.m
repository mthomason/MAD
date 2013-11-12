//
//  MTBarcodeAztec.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAztec.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@property (nonatomic, assign, readwrite) NSInteger option1;
@property (nonatomic, assign, readwrite) NSInteger option2;
@property (nonatomic, assign, readwrite) NSInteger option3;

@end

@implementation MTBarcodeAztec

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeAztec type]];
        [self setName: @"Aztec Code (ISO 24778)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        [self setDetailsSegueIdentifer: @"MTIdentiferSegueBarcodeExtrasAztec"];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeAztec;
}

- (MTBarcodeAztecSizingMode)sizingMode {
    MTBarcodeAztecSizingMode result = MTBarcodeAztecSizingModeAutomaticResizing;
    if ([self option1] == NO && [self option2] == NO && [self option3] == NO) {
        result = MTBarcodeAztecSizingModeAutomaticResizing;
    } else if ([self option1] != NO) {
        result = MTBarcodeAztecSizingModeSpecificErrorLevel;
    } else if ([self option2] != NO) {
        result = MTBarcodeAztecSizingModeSpecificSize;
    }
    
    return result;
}

- (void)enableAutomaticResizing {
    [self setOption1:NO];
    [self setOption2:NO];
    [self setOption3:NO];
}
- (void)setSize:(MTBarcodeAztecSpecificSize)size {
    [self setOption1:NO];
    [self setOption2:size];
    [self setOption3:NO];
}
- (void)setMinmumErrorCorrection:(MTBarcodeAztecErrorCorrection)minmumErrorCorrection {
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

@end
