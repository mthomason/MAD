//
//  MTBarcodePdf417Iso15438.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodePdf417Iso15438.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePdf417Iso15438

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodePdf417Iso15438 type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasPdf417"];
        [self setName: @"PDF417 (ISO 15438)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePdf417;
}

- (void)setNumberOfColumns:(NSInteger)numberOfColumns {
    [self setOption2:numberOfColumns];
}

- (void)setErrorCorrectionCapacity:(NSInteger)errorCorrectionCapacity {
    [self setOption1:errorCorrectionCapacity];
}

- (NSInteger)errorCorrectionCapacity {
    return [self option1];
}

- (void)setMaximumCodewordLength:(NSInteger)codewordLength {
    [self setOption3:codewordLength];
}

- (NSInteger)codewordLength {
    return [self option3];
}

- (void)initSampleData {
    [self setInput:              [self name]];
    [self setPrimaryData:        @""];
}

@end
