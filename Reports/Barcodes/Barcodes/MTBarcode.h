//
//  MTBarcode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "zint.h"

typedef NS_ENUM(NSUInteger, MTBarcodeSizingMode) {
    MTBarcodeSizingModeAutomaticResizing     = 1,
    MTBarcodeSizingModeSpecificSize          = 2,
    MTBarcodeSizingModeSpecificErrorLevel    = 3
};

typedef NS_ENUM(NSUInteger, MTBarcodeBorderStyle) {
    MTBarcodeBorderStyleNone    = 0,
    MTBarcodeBorderStyleBind    = BARCODE_BIND,
    MTBarcodeBorderStyleBox     = BARCODE_BOX
};

typedef NS_ENUM(NSUInteger, MTBarcodeDataInputType) {
    MTBarcodeDataTypeUnicode = UNICODE_MODE,
    MTBarcodeDataTypeData = DATA_MODE,
    MTBarcodeDataTypeGs1 = GS1_MODE
};

typedef NS_ENUM(NSUInteger, MTBarcodeType) {
	MTBarcodeTypeCode11         = BARCODE_CODE11,
    MTBarcodeTypeC25MATRIX      = BARCODE_C25MATRIX,
    MTBarcodeTypeC25INTER       = BARCODE_C25INTER,
    MTBarcodeTypeC25IATA        = BARCODE_C25IATA,
    MTBarcodeTypeC25LOGIC       = BARCODE_C25LOGIC,
    MTBarcodeTypeC25IND         = BARCODE_C25IND,
    MTBarcodeTypeCODE39         = BARCODE_CODE39,
    MTBarcodeTypeEXCODE39       = BARCODE_EXCODE39,
    MTBarcodeTypeEANX           = BARCODE_EANX,
    MTBarcodeTypeEAN128         = BARCODE_EAN128,
    MTBarcodeTypeCODABAR        = BARCODE_CODABAR,
    MTBarcodeTypeCODE128        = BARCODE_CODE128,
    MTBarcodeTypeDPLEIT         = BARCODE_DPLEIT,
    MTBarcodeTypeDPIDENT        = BARCODE_DPIDENT,
    MTBarcodeTypeCODE16K        = BARCODE_CODE16K,
    MTBarcodeTypeCODE49         = BARCODE_CODE49,
    MTBarcodeTypeCODE93         = BARCODE_CODE93,
    MTBarcodeTypeFlat           = BARCODE_FLAT,
    MTBarcodeTypeRss14          = BARCODE_RSS14,
    MTBarcodeTypeRssLtd         = BARCODE_RSS_LTD,
    MTBarcodeTypeRssExp         = BARCODE_RSS_EXP,
    MTBarcodeTypeTelepen        = BARCODE_TELEPEN,
    MTBarcodeTypeUpca           = BARCODE_UPCA,
    MTBarcodeTypeUpce           = BARCODE_UPCE,
    MTBarcodeTypePostnet        = BARCODE_POSTNET,
    MTBarcodeTypeMsiPlessey     = BARCODE_MSI_PLESSEY,
    MTBarcodeTypeFim            = BARCODE_FIM,
    MTBarcodeTypeLogmars        = BARCODE_LOGMARS,
    MTBarcodeTypePharma         = BARCODE_PHARMA,
    MTBarcodeTypePzn            = BARCODE_PZN,
    MTBarcodeTypePharmaTwo      = BARCODE_PHARMA_TWO,
    MTBarcodeTypePdf417         = BARCODE_PDF417,
    MTBarcodeTypePdf417Trunc    = BARCODE_PDF417TRUNC,
    MTBarcodeTypeMaxicode       = BARCODE_MAXICODE,
    MTBarcodeTypeQrcode         = BARCODE_QRCODE,
    MTBarcodeTypeCode128b       = BARCODE_CODE128B,
    MTBarcodeTypeAuspost        = BARCODE_AUSPOST,
    MTBarcodeTypeAusreply       = BARCODE_AUSREPLY,
    MTBarcodeTypeAusroute       = BARCODE_AUSROUTE,
    MTBarcodeTypeAusreDirect    = BARCODE_AUSREDIRECT,
    MTBarcodeTypeIsbnX          = BARCODE_ISBNX,
    MTBarcodeTypeRm4scc         = BARCODE_RM4SCC,
    MTBarcodeTypeDataMatrix     = BARCODE_DATAMATRIX,
    MTBarcodeTypeEan14          = BARCODE_EAN14,
    MTBarcodeTypeCoadBlockF     = BARCODE_CODABLOCKF,
    MTBarcodeTypeNve18          = BARCODE_NVE18,
    MTBarcodeTypeJapanPost      = BARCODE_JAPANPOST,
    MTBarcodeTypeKoreaPost      = BARCODE_KOREAPOST,
    MTBarcodeTypeRss14Stack     = BARCODE_RSS14STACK,
    MTBarcodeTypeRss14StackOmni = BARCODE_RSS14STACK_OMNI,
    MTBarcodeTypeRssExpstack    = BARCODE_RSS_EXPSTACK,
    MTBarcodeTypePlanet         = BARCODE_PLANET,
    MTBarcodeTypeMicroPdf417    = BARCODE_MICROPDF417,
    MTBarcodeTypeOneCode        = BARCODE_ONECODE,
    MTBarcodeTypePlessey        = BARCODE_PLESSEY,
    
    /* Tbarcode 8 codes */
    MTBarcodeTypeTelepenNum     = BARCODE_TELEPEN_NUM,
    MTBarcodeTypeItf14          = BARCODE_ITF14,
    MTBarcodeTypeKix            = BARCODE_KIX,
    MTBarcodeTypeAztec          = BARCODE_AZTEC,
    MTBarcodeTypeDaft           = BARCODE_DAFT,
    MTBarcodeTypeMicroqr        = BARCODE_MICROQR,
    
    /* Tbarcode 9 codes */
    MTBarcodeTypeHibc128        = BARCODE_HIBC_128,
    MTBarcodeTypeHibc39         = BARCODE_HIBC_39,
    MTBarcodeTypeHibcDm         = BARCODE_HIBC_DM,
    MTBarcodeTypeHibcQr         = BARCODE_HIBC_QR,
    MTBarcodeTypeHibcPdf        = BARCODE_HIBC_PDF,
    MTBarcodeTypeHibcMicPdf     = BARCODE_HIBC_MICPDF,
    MTBarcodeTypeHibcBlockF     = BARCODE_HIBC_BLOCKF,
    MTBarcodeTypeHibcAztec      = BARCODE_HIBC_AZTEC,
    
    /* Zint specific */
    MTBarcodeTypeAzrune         = BARCODE_AZRUNE,
    MTBarcodeTypeCode32         = BARCODE_CODE32,
    MTBarcodeTypeEanxCc         = BARCODE_EANX_CC,
    MTBarcodeTypeEan128Cc       = BARCODE_EAN128_CC,
    MTBarcodeTypeRss14Cc        = BARCODE_RSS14_CC,
    MTBarcodeTypeRssLtdCc       = BARCODE_RSS_LTD_CC,
    MTBarcodeTypeRssExpCc       = BARCODE_RSS_EXP_CC,
    MTBarcodeTypeUpcaCc         = BARCODE_UPCA_CC,
    MTBarcodeTypeUpceCc         = BARCODE_UPCE_CC,
    MTBarcodeTypeRss14StackCc   = BARCODE_RSS14STACK_CC,
    MTBarcodeTypeRss14OmniCc    = BARCODE_RSS14_OMNI_CC,
    MTBarcodeTypeRssExpstackCc  = BARCODE_RSS_EXPSTACK_CC,
    MTBarcodeTypeChannel        = BARCODE_CHANNEL,
    MTBarcodeTypeCodeOne        = BARCODE_CODEONE,
    MTBarcodeTypeGridMatrix     = BARCODE_GRIDMATRIX,
};

@interface MTBarcode : NSObject

@property (nonatomic, assign, readonly) MTBarcodeType barcodeType;
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSString *detailsSegueIdentifer;
@property (nonatomic, retain) NSString *primaryData;

@property (nonatomic, assign, readonly) BOOL has2dComponent;
@property (nonatomic, assign, readonly) BOOL hasOptionalInput;

@property (nonatomic, assign) NSInteger option1;
@property (nonatomic, assign) NSInteger option2;
@property (nonatomic, assign) NSInteger option3;

@property (nonatomic, retain) NSString *input;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger borderWidth;
@property (nonatomic, assign) NSInteger whitespaceWidth;
@property (nonatomic, assign) BOOL humanReadable;
@property (nonatomic, assign) MTBarcodeBorderStyle borderStyle;
@property (nonatomic, assign) BOOL showErrorMessages;

@property (nonatomic, assign) BOOL has2dComponentEnabled;
@property (nonatomic, assign) NSInteger has2dComponentType;

@property (nonatomic, assign) CGFloat scale;

- (void)drawInRect:(CGRect)rect;

+ (NSString *)barcodeNameForType:(MTBarcodeType)type;
+ (NSDictionary *)names;
+ (id)barcodeWithType :(MTBarcodeType)type;

@end
