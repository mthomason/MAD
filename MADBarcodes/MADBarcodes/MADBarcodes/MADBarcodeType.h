//
//  MADBarcodeType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADBarcodeType_h
#define MAD_MADBarcodeType_h

#import <Foundation/NSObjCRuntime.h>
#import <MADBarcodes/zint.h>

typedef NS_ENUM(int16_t, MADBarcodeType) {
	MADBarcodeTypeCode11			= BARCODE_CODE11,
	MADBarcodeTypeC25MATRIX		= BARCODE_C25MATRIX,
	MADBarcodeTypeC25INTER		= BARCODE_C25INTER,
	MADBarcodeTypeC25IATA		= BARCODE_C25IATA,
	MADBarcodeTypeC25LOGIC		= BARCODE_C25LOGIC,
	MADBarcodeTypeC25IND			= BARCODE_C25IND,
	MADBarcodeTypeCODE39			= BARCODE_CODE39,
	MADBarcodeTypeEXCODE39		= BARCODE_EXCODE39,
	MADBarcodeTypeEANX			= BARCODE_EANX,
	MADBarcodeTypeEAN128			= BARCODE_EAN128,
	MADBarcodeTypeCODABAR		= BARCODE_CODABAR,
	MADBarcodeTypeCODE128		= BARCODE_CODE128,
	MADBarcodeTypeDPLEIT			= BARCODE_DPLEIT,
	MADBarcodeTypeDPIDENT		= BARCODE_DPIDENT,
	MADBarcodeTypeCODE16K		= BARCODE_CODE16K,
	MADBarcodeTypeCODE49			= BARCODE_CODE49,
	MADBarcodeTypeCODE93			= BARCODE_CODE93,
	MADBarcodeTypeFlat			= BARCODE_FLAT,
	MADBarcodeTypeRss14			= BARCODE_RSS14,
	MADBarcodeTypeRssLtd			= BARCODE_RSS_LTD,
	MADBarcodeTypeRssExp			= BARCODE_RSS_EXP,
	MADBarcodeTypeTelepen		= BARCODE_TELEPEN,
	MADBarcodeTypeUpca			= BARCODE_UPCA,
	MADBarcodeTypeUpce			= BARCODE_UPCE,
	MADBarcodeTypePostnet		= BARCODE_POSTNET,
	MADBarcodeTypeMsiPlessey		= BARCODE_MSI_PLESSEY,
	MADBarcodeTypeFim			= BARCODE_FIM,
	MADBarcodeTypeLogmars		= BARCODE_LOGMARS,
	MADBarcodeTypePharma			= BARCODE_PHARMA,
	MADBarcodeTypePzn			= BARCODE_PZN,
	MADBarcodeTypePharmaTwo		= BARCODE_PHARMA_TWO,
	MADBarcodeTypePdf417			= BARCODE_PDF417,
	MADBarcodeTypePdf417Trunc	= BARCODE_PDF417TRUNC,
	MADBarcodeTypeMaxicode		= BARCODE_MAXICODE,
	MADBarcodeTypeQrcode			= BARCODE_QRCODE,
	MADBarcodeTypeCode128b		= BARCODE_CODE128B,
	MADBarcodeTypeAuspost		= BARCODE_AUSPOST,
	MADBarcodeTypeAusreply		= BARCODE_AUSREPLY,
	MADBarcodeTypeAusroute		= BARCODE_AUSROUTE,
	MADBarcodeTypeAusreDirect	= BARCODE_AUSREDIRECT,
	MADBarcodeTypeIsbnX			= BARCODE_ISBNX,
	MADBarcodeTypeRm4scc			= BARCODE_RM4SCC,
	MADBarcodeTypeDataMatrix		= BARCODE_DATAMATRIX,
	MADBarcodeTypeEan14			= BARCODE_EAN14,
	MADBarcodeTypeCoadBlockF		= BARCODE_CODABLOCKF,
	MADBarcodeTypeNve18			= BARCODE_NVE18,
	MADBarcodeTypeJapanPost		= BARCODE_JAPANPOST,
	MADBarcodeTypeKoreaPost		= BARCODE_KOREAPOST,
	MADBarcodeTypeRss14Stack		= BARCODE_RSS14STACK,
	MADBarcodeTypeRss14StackOmni	= BARCODE_RSS14STACK_OMNI,
	MADBarcodeTypeRssExpstack	= BARCODE_RSS_EXPSTACK,
	MADBarcodeTypePlanet			= BARCODE_PLANET,
	MADBarcodeTypeMicroPdf417	= BARCODE_MICROPDF417,
	MADBarcodeTypeOneCode		= BARCODE_ONECODE,
	MADBarcodeTypePlessey		= BARCODE_PLESSEY,
	
	/* Tbarcode 8 codes */
	MADBarcodeTypeTelepenNum		= BARCODE_TELEPEN_NUM,
	MADBarcodeTypeItf14			= BARCODE_ITF14,
	MADBarcodeTypeKix			= BARCODE_KIX,
	MADBarcodeTypeAztec			= BARCODE_AZTEC,
	MADBarcodeTypeDaft			= BARCODE_DAFT,
	MADBarcodeTypeMicroqr		= BARCODE_MICROQR,
	
	/* Tbarcode 9 codes */
	MADBarcodeTypeHibc128		= BARCODE_HIBC_128,
	MADBarcodeTypeHibc39			= BARCODE_HIBC_39,
	MADBarcodeTypeHibcDm			= BARCODE_HIBC_DM,
	MADBarcodeTypeHibcQr			= BARCODE_HIBC_QR,
	MADBarcodeTypeHibcPdf		= BARCODE_HIBC_PDF,
	MADBarcodeTypeHibcMicPdf		= BARCODE_HIBC_MICPDF,
	MADBarcodeTypeHibcBlockF		= BARCODE_HIBC_BLOCKF,
	MADBarcodeTypeHibcAztec		= BARCODE_HIBC_AZTEC,
	
	/* Zint specific */
	MADBarcodeTypeAzrune			= BARCODE_AZRUNE,
	MADBarcodeTypeCode32			= BARCODE_CODE32,
	MADBarcodeTypeEanxCc			= BARCODE_EANX_CC,
	MADBarcodeTypeEan128Cc		= BARCODE_EAN128_CC,
	MADBarcodeTypeRss14Cc		= BARCODE_RSS14_CC,
	MADBarcodeTypeRssLtdCc		= BARCODE_RSS_LTD_CC,
	MADBarcodeTypeRssExpCc		= BARCODE_RSS_EXP_CC,
	MADBarcodeTypeUpcaCc			= BARCODE_UPCA_CC,
	MADBarcodeTypeUpceCc			= BARCODE_UPCE_CC,
	MADBarcodeTypeRss14StackCc	= BARCODE_RSS14STACK_CC,
	MADBarcodeTypeRss14OmniCc	= BARCODE_RSS14_OMNI_CC,
	MADBarcodeTypeRssExpstackCc	= BARCODE_RSS_EXPSTACK_CC,
	MADBarcodeTypeChannel		= BARCODE_CHANNEL,
	MADBarcodeTypeCodeOne		= BARCODE_CODEONE,
	MADBarcodeTypeGridMatrix		= BARCODE_GRIDMATRIX,
	
};

static inline MADBarcodeType barcodeTypeForInt(int16_t t);
static inline MADBarcodeType barcodeTypeForInt(int16_t t) {
	return (MADBarcodeType)t;
}

#endif
