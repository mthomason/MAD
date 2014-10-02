//
//  MTBarcodePdf417Iso15438.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodePdf417Iso15438.h"

NSString * const MADStringDisplayPdf417 = @"PDF417 (ISO 15438)";
NSString * const MADStringDisplayPdfTrunc = @"PDF417 Trunc";
NSString * const MADStringDisplayPdfHibc = @"HIBC PDF";

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePdf417Iso15438

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodePdf417Iso15438 type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasPdf417"];
        [self setName: MADStringDisplayPdf417];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePdf417;
}

- (NSInteger)format {
    return self.barcodeType;
}

- (void)setFormat:(NSInteger)format {
    switch (format) {
        case 1:
            self.barcodeType = MTBarcodeTypePdf417;
            self.name = MADStringDisplayPdf417;
            break;
        case 2:
            self.barcodeType = MTBarcodeTypePdf417Trunc;
            self.name = MADStringDisplayPdfTrunc;
            break;
        case 3:
            self.barcodeType = MTBarcodeTypeHibcPdf;
            self.name = MADStringDisplayPdfHibc;
            break;
        default:
            break;
    }
}

- (NSInteger)numberOfColumns {
    return [self option2];
}

- (void)setNumberOfColumns:(NSInteger)numberOfColumns {
    [self setOption2:numberOfColumns];
}

- (NSInteger)errorCorrectionCapacity {
    return [self option1];
}

- (void)setErrorCorrectionCapacity:(NSInteger)errorCorrectionCapacity {
    [self setOption1:errorCorrectionCapacity];
}

- (void)initSampleData {
    [self setInput:              self.name];
    [self setPrimaryData:        @""];
}

@end
