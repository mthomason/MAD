//
//  MADBarcodes.h
//  MADBarcodes
//
//  Created by Michael Thomason on 9/15/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <Foundation/NSObjCRuntime.h>

//! Project version number for MADBarcodes.
FOUNDATION_EXPORT double MADBarcodesVersionNumber;

//! Project version string for MADBarcodes.
FOUNDATION_EXPORT const unsigned char MADBarcodesVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MADBarcodes/PublicHeader.h>

//#import <MADBarcodes/png.h>
//#import <MADBarcodes/pnglibconf.h>
//#import <MADBarcodes/pngconf.h>

#import <MADBarcodes/zint.h>
#import <MADBarcodes/png.h>
#import <MADBarcodes/MADBarcodeProtocol.h>
#import <MADBarcodes/MADBarcodeType.h>
#import <MADBarcodes/MADBarcode.h>
#import <MADBarcodes/MADBarcodeCache.h>
#import <MADBarcodes/MADBarcodeView.h>
#import <MADBarcodes/MADBarcodeDataMatrixIso16022.h>
#import <MADBarcodes/MADBarcodeCode39Iso16388.h>
#import <MADBarcodes/MADBarcodeAztec.h>
#import <MADBarcodes/MADBarcodeQrCodeIso18004.h>
#import <MADBarcodes/MADBarcodeGridMatrix.h>
#import <MADBarcodes/MADBarcodeMicroQrCode.h>
#import <MADBarcodes/MADBarcodeMaxicodeIso16023.h>
#import <MADBarcodes/MADBarcodePdf417Iso15438.h>
#import <MADBarcodes/MADBarcodeCodeOne.h>
#import <MADBarcodes/MADBarcodeDatabarStacked.h>
#import <MADBarcodes/MADBarcodeDatabarExpandedStacked.h>
#import <MADBarcodes/MADBarcodeMsiPlessey.h>
#import <MADBarcodes/MADBarcodeMicroPdf417Iso24728.h>
#import <MADBarcodes/MADBarcodeChannelCode.h>
#import <MADBarcodes/MADBarcodeCode39Extended.h>

// Remaining public headers, so the module umbrella is complete.
// (-Wincomplete-umbrella; keep in sync with the Public headers phase.)
#import <MADBarcodes/MADBarcodeBorderStyle.h>
#import <MADBarcodes/MADBarcodeSizingMode.h>
#import <MADBarcodes/pngconf.h>
#import <MADBarcodes/pnglibconf.h>
