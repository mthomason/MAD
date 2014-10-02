//
//  MTBarcodeMicroPdf417Iso24728.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeMicroPdf417Iso24728.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeMicroPdf417Iso24728

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeMicroPdf417Iso24728 type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasMicroPdf417"];
        [self setName: @"MicroPDF417 (ISO 24728)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMicroPdf417;
}

- (NSInteger)numberOfDataColumns {
    return self.option2;
}

- (NSInteger)errorCorrectionCapacity {
    return self.option1;
}

- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns {
    self.option2 = numberOfDataColumns;
}

- (void)initSampleData {
    [self setInput:              self.name];
    [self setPrimaryData:        @""];
}

@end
