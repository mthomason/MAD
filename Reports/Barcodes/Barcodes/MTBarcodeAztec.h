//
//  MTBarcodeAztec.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

typedef NS_ENUM(NSUInteger, MTBarcodeAztecSizingMode) {
    MTBarcodeAztecSizingModeAutomaticResizing     = 1,
    MTBarcodeAztecSizingModeSpecificSize          = 2,
    MTBarcodeAztecSizingModeSpecificErrorLevel    = 3
};

typedef NS_ENUM(NSUInteger, MTBarcodeAztecSpecificSize) {
    MTBarcodeAztecSpecificSize15x15Compact = 1,
    MTBarcodeAztecSpecificSize19x19Compact = 2,
    MTBarcodeAztecSpecificSize23x23Compact = 3,
    MTBarcodeAztecSpecificSize27x27Compact = 4,
    MTBarcodeAztecSpecificSize19x19 = 5,
    MTBarcodeAztecSpecificSize23x23 = 6,
    MTBarcodeAztecSpecificSize27x27 = 7,
    MTBarcodeAztecSpecificSize31x31 = 8,
    MTBarcodeAztecSpecificSize37x37 = 9,
    MTBarcodeAztecSpecificSize41x41 = 10,
    MTBarcodeAztecSpecificSize45x45 = 11,
    MTBarcodeAztecSpecificSize49x49 = 12,
    MTBarcodeAztecSpecificSize53x53 = 13,
    MTBarcodeAztecSpecificSize57x57 = 14,
    MTBarcodeAztecSpecificSize61x61 = 15,
    MTBarcodeAztecSpecificSize67x67 = 16,
    MTBarcodeAztecSpecificSize71x71 = 17,
    MTBarcodeAztecSpecificSize75x75 = 18,
    MTBarcodeAztecSpecificSize79x79 = 19,
    MTBarcodeAztecSpecificSize83x83 = 20,
    MTBarcodeAztecSpecificSize87x87 = 21,
    MTBarcodeAztecSpecificSize91x91 = 22,
    MTBarcodeAztecSpecificSize95x95 = 23,
    MTBarcodeAztecSpecificSize101x101 = 24,
    MTBarcodeAztecSpecificSize105x105 = 25,
    MTBarcodeAztecSpecificSize109x109 = 26,
    MTBarcodeAztecSpecificSize113x113 = 27,
    MTBarcodeAztecSpecificSize117x117 = 28,
    MTBarcodeAztecSpecificSize121x121 = 29,
    MTBarcodeAztecSpecificSize125x125 = 30,
    MTBarcodeAztecSpecificSize131x131 = 31,
    MTBarcodeAztecSpecificSize135x135 = 32,
    MTBarcodeAztecSpecificSize139x139 = 33,
    MTBarcodeAztecSpecificSize143x143 = 34,
    MTBarcodeAztecSpecificSize147x147 = 35,
    MTBarcodeAztecSpecificSize151x151 = 36
};

typedef NS_ENUM(NSUInteger, MTBarcodeAztecErrorCorrection) {
    MTBarcodeAztecErrorCorrection10   = 1,
    MTBarcodeAztecErrorCorrection23   = 2,
    MTBarcodeAztecErrorCorrection36   = 3,
    MTBarcodeAztecErrorCorrection50   = 4
};

@interface MTBarcodeAztec : MTBarcode

- (MTBarcodeAztecSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(MTBarcodeAztecSpecificSize)size;
- (void)setMinmumErrorCorrection:(MTBarcodeAztecErrorCorrection)minmumErrorCorrection;

@end
