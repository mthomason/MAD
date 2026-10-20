//
//  MADBarcodeAztec.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeAztec_h
#define Barcodes_MADBarcodeAztec_h

#import <MADBarcodes/MADBarcode.h>

typedef NS_ENUM(NSUInteger, MADBarcodeAztecSizingMode) {
	MADBarcodeAztecSizingModeAutomaticResizing		= 1,
	MADBarcodeAztecSizingModeSpecificSize			= 2,
	MADBarcodeAztecSizingModeSpecificErrorLevel		= 3
};

typedef NS_ENUM(NSUInteger, MADBarcodeAztecSpecificSize) {
	MADBarcodeAztecSpecificSize15x15Compact = 1,
	MADBarcodeAztecSpecificSize19x19Compact = 2,
	MADBarcodeAztecSpecificSize23x23Compact = 3,
	MADBarcodeAztecSpecificSize27x27Compact = 4,
	MADBarcodeAztecSpecificSize19x19 = 5,
	MADBarcodeAztecSpecificSize23x23 = 6,
	MADBarcodeAztecSpecificSize27x27 = 7,
	MADBarcodeAztecSpecificSize31x31 = 8,
	MADBarcodeAztecSpecificSize37x37 = 9,
	MADBarcodeAztecSpecificSize41x41 = 10,
	MADBarcodeAztecSpecificSize45x45 = 11,
	MADBarcodeAztecSpecificSize49x49 = 12,
	MADBarcodeAztecSpecificSize53x53 = 13,
	MADBarcodeAztecSpecificSize57x57 = 14,
	MADBarcodeAztecSpecificSize61x61 = 15,
	MADBarcodeAztecSpecificSize67x67 = 16,
	MADBarcodeAztecSpecificSize71x71 = 17,
	MADBarcodeAztecSpecificSize75x75 = 18,
	MADBarcodeAztecSpecificSize79x79 = 19,
	MADBarcodeAztecSpecificSize83x83 = 20,
	MADBarcodeAztecSpecificSize87x87 = 21,
	MADBarcodeAztecSpecificSize91x91 = 22,
	MADBarcodeAztecSpecificSize95x95 = 23,
	MADBarcodeAztecSpecificSize101x101 = 24,
	MADBarcodeAztecSpecificSize105x105 = 25,
	MADBarcodeAztecSpecificSize109x109 = 26,
	MADBarcodeAztecSpecificSize113x113 = 27,
	MADBarcodeAztecSpecificSize117x117 = 28,
	MADBarcodeAztecSpecificSize121x121 = 29,
	MADBarcodeAztecSpecificSize125x125 = 30,
	MADBarcodeAztecSpecificSize131x131 = 31,
	MADBarcodeAztecSpecificSize135x135 = 32,
	MADBarcodeAztecSpecificSize139x139 = 33,
	MADBarcodeAztecSpecificSize143x143 = 34,
	MADBarcodeAztecSpecificSize147x147 = 35,
	MADBarcodeAztecSpecificSize151x151 = 36
};

typedef NS_ENUM(NSUInteger, MADBarcodeAztecErrorCorrection) {
	MADBarcodeAztecErrorCorrection10   = 1,
	MADBarcodeAztecErrorCorrection23   = 2,
	MADBarcodeAztecErrorCorrection36   = 3,
	MADBarcodeAztecErrorCorrection50   = 4
};

@interface MADBarcodeAztec : MADBarcode

- (MADBarcodeAztecSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(MADBarcodeAztecSpecificSize)size;
- (void)setMinmumErrorCorrection:(MADBarcodeAztecErrorCorrection)minmumErrorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end

#endif
