//
//  Barcodes.h
//  Barcodes
//
//  Created by Michael Thomason on 11/2/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "zint.h"

typedef NS_ENUM(NSUInteger, MTBarcodeBorderStyle) {
    MTBarcodeBorderStyleNone    = 0,
    MTBarcodeBorderStyleBind    = BARCODE_BIND,
    MTBarcodeBorderStyleBox = BARCODE_BOX
};

typedef NS_ENUM(NSUInteger, MTBarcodeDataInputType) {
    MTBarcodeDataTypeUnicode = UNICODE_MODE,
    MTBarcodeDataTypeData = DATA_MODE,
    MTBarcodeDataTypeGs1 = GS1_MODE
};

typedef NS_ENUM(NSUInteger, MTBarcodeType) {
	MTBarcodeCode11         = BARCODE_CODE11,
    MTBarcodeC25MATRIX      = BARCODE_C25MATRIX,
    MTBarcodeC25INTER       = BARCODE_C25INTER,
    MTBarcodeC25IATA        = BARCODE_C25IATA,
    MTBarcodeC25LOGIC       = BARCODE_C25LOGIC,
    MTBarcodeC25IND         = BARCODE_C25IND,
    MTBarcodeCODE39         = BARCODE_CODE39,
    MTBarcodeEXCODE39       = BARCODE_EXCODE39,
    MTBarcodeEANX           = BARCODE_EANX,
    MTBarcodeEAN128         = BARCODE_EAN128,
    MTBarcodeCODABAR        = BARCODE_CODABAR,
    MTBarcodeCODE128        = BARCODE_CODE128,
    MTBarcodeDPLEIT         = BARCODE_DPLEIT,
    MTBarcodeDPIDENT        = BARCODE_DPIDENT,
    MTBarcodeCODE16K        = BARCODE_CODE16K,
    MTBarcodeCODE49         = BARCODE_CODE49,
    MTBarcodeCODE93         = BARCODE_CODE93,
    MTBarcodeFlat           = BARCODE_FLAT,
    MTBarcodeRss14          = BARCODE_RSS14,
    MTBarcodeRssLtd         = BARCODE_RSS_LTD,
    MTBarcodeRssExp         = BARCODE_RSS_EXP,
    MTBarcodeTelepen        = BARCODE_TELEPEN,
    MTBarcodeUpca           = BARCODE_UPCA,
    MTBarcodeUpce           = BARCODE_UPCE,
    MTBarcodePostnet        = BARCODE_POSTNET,
    MTBarcodeMsiPlessey     = BARCODE_MSI_PLESSEY,
    MTBarcodeFim            = BARCODE_FIM,
    MTBarcodeLogmars        = BARCODE_LOGMARS,
    MTBarcodePharma         = BARCODE_PHARMA,
    MTBarcodePzn            = BARCODE_PZN,
    MTBarcodePharmaTwo      = BARCODE_PHARMA_TWO,
    MTBarcodePdf417         = BARCODE_PDF417,
    MTBarcodePdf417Trunc    = BARCODE_PDF417TRUNC,
    MTBarcodeMaxicode       = BARCODE_MAXICODE,
    MTBarcodeQrcode         = BARCODE_QRCODE,
    MTBarcodeCode128b       = BARCODE_CODE128B,
    MTBarcodeAuspost        = BARCODE_AUSPOST,
    MTBarcodeAusreply       = BARCODE_AUSREPLY,
    MTBarcodeAusroute       = BARCODE_AUSROUTE,
    MTBarcodeAusreDirect    = BARCODE_AUSREDIRECT,
    MTBarcodeIsbnX          = BARCODE_ISBNX,
    MTBarcodeRm4scc         = BARCODE_RM4SCC,
    MTBarcodeDataMatrix     = BARCODE_DATAMATRIX,
    MTBarcodeEan14          = BARCODE_EAN14,
    MTBarcodeCoadBlockF     = BARCODE_CODABLOCKF,
    MTBarcodeNve18          = BARCODE_NVE18,
    MTBarcodeJapanPost      = BARCODE_JAPANPOST,
    MTBarcodeKoreaPost      = BARCODE_KOREAPOST,
    MTBarcodeRss14Stack     = BARCODE_RSS14STACK,
    MTBarcodeRss14StackOmni = BARCODE_RSS14STACK_OMNI,
    MTBarcodeRssExpstack    = BARCODE_RSS_EXPSTACK,
    MTBarcodePlanet         = BARCODE_PLANET,
    MTBarcodeMicroPdf417    = BARCODE_MICROPDF417,
    MTBarcodeOneCode        = BARCODE_ONECODE,
    MTBarcodePlessey        = BARCODE_PLESSEY,
    
    /* Tbarcode 8 codes */
    MTBarcodeTelepenNum     = BARCODE_TELEPEN_NUM,
    MTBarcodeItf14          = BARCODE_ITF14,
    MTBarcodeKix            = BARCODE_KIX,
    MTBarcodeAztec          = BARCODE_AZTEC,
    MTBarcodeDaft           = BARCODE_DAFT,
    MTBarcodeMicroqr        = BARCODE_MICROQR,
    
    /* Tbarcode 9 codes */
    MTBarcodeHibc128        = BARCODE_HIBC_128,
    MTBarcodeHibc39         = BARCODE_HIBC_39,
    MTBarcodeHibcDm         = BARCODE_HIBC_DM,
    MTBarcodeHibcQr         = BARCODE_HIBC_QR,
    MTBarcodeHibcPdf        = BARCODE_HIBC_PDF,
    MTBarcodeHibcMicPdf     = BARCODE_HIBC_MICPDF,
    MTBarcodeHibcBlockF     = BARCODE_HIBC_BLOCKF,
    MTBarcodeHibcAztec      = BARCODE_HIBC_AZTEC,
    
    /* Zint specific */
    MTBarcodeAzrune         = BARCODE_AZRUNE,
    MTBarcodeCode32         = BARCODE_CODE32,
    MTBarcodeEanxCc         = BARCODE_EANX_CC,
    MTBarcodeEan128Cc       = BARCODE_EAN128_CC,
    MTBarcodeRss14Cc        = BARCODE_RSS14_CC,
    MTBarcodeRssLtdCc       = BARCODE_RSS_LTD_CC,
    MTBarcodeRssExpCc       = BARCODE_RSS_EXP_CC,
    MTBarcodeUpcaCc         = BARCODE_UPCA_CC,
    MTBarcodeUpceCc         = BARCODE_UPCE_CC,
    MTBarcodeRss14StackCc   = BARCODE_RSS14STACK_CC,
    MTBarcodeRss14OmniCc    = BARCODE_RSS14_OMNI_CC,
    MTBarcodeRssExpstackCc  = BARCODE_RSS_EXPSTACK_CC,
    MTBarcodeChannel        = BARCODE_CHANNEL,
    MTBarcodeCodeOne        = BARCODE_CODEONE,
    MTBarcodeGridMatrix     = BARCODE_GRIDMATRIX,
};

@interface Barcodes : NSObject

+ (void)barcodeForType:(MTBarcodeType)barcodeType
                  size:(CGSize)barcodeSize
           borderStyle:(MTBarcodeBorderStyle)borderStyle
        stringToEncode:(NSString *)stringToEncode
       whitespaceWidth:(NSInteger)whitespaceWidth
                 scale:(CGFloat)scale
            completion:(void(^)(UIImage *barcodeImage, BOOL success, NSError *error))completion;

+ (NSString *)barcodeNameForType:(MTBarcodeType)type;
+ (NSDictionary *)names;

@end
