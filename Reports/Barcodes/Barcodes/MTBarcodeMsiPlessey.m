//
//  MTBarcodeMsiPlessey.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeMsiPlessey.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeMsiPlessey

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeMsiPlessey type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasMsiPlessey"];
        [self setName: @"MSI Plessey"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMsiPlessey;
}

- (NSInteger)checkpointDigit {
    return [self option2];
}

- (void)setCheckDigit:(NSInteger)checkDigit {
    NSAssert(checkDigit == 0 || checkDigit == 1 || checkDigit == 2 || checkDigit == 3 || checkDigit == 4, @"Incorrect barcode check digit.");
    [self setOption2: checkDigit];
}

- (void)initSampleData {
    [self setOption2:            0];
    [self setInput:              @"87654321"];
    [self setPrimaryData:        @""];
}

@end
