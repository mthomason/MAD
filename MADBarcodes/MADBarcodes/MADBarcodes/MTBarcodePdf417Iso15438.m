//
//  MTBarcodePdf417Iso15438.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodePdf417Iso15438.h"

NSString * const MADStringDisplayPdf417     = @"PDF417 (ISO 15438)";
NSString * const MADStringDisplayPdfTrunc   = @"PDF417 Trunc";
NSString * const MADStringDisplayPdfHibc    = @"HIBC PDF";

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePdf417Iso15438

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypePdf417;
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasPdf417";
        self.name = MADStringDisplayPdf417;
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypePdf417; }

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
    return self.option2;
}

- (void)setNumberOfColumns:(NSInteger)numberOfColumns {
    self.option2 = numberOfColumns;
}

- (NSInteger)errorCorrectionCapacity {
    return self.option1;
}

- (void)setErrorCorrectionCapacity:(NSInteger)errorCorrectionCapacity {
    self.option1 = errorCorrectionCapacity;
}

- (void)loadSampleData {
    self.input = self.name;
    self.primaryData = @"";
}

@end
