# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADBarcodes subset the headless builds compile: the base class, the
# factory and every symbology subclass -- 62 of the 64 implementation files.
#
# Excluded, and why:
#
#   The Apple drawing path.  Both classes are UIKit/AppKit types; the render
#   core they draw is MADBarcode.m, which is portable.
#     MADBarcodeCache.m   NSCache of UIImage/NSImage, keyed by the render key
#     MADBarcodeView.m    a UIView/NSView subclass
#
# zint and libpng arrive through libraries.conf (Linux/lib/libraries.sh,
# Windows/Engine/build.ps1); MADBarcodes links both.

set(MADBARCODES_SOURCES
	"${SOURCE_DIR}/MADBarcode.m"
	"${SOURCE_DIR}/MADBarcodeAusPostStandardCustomer.m"
	"${SOURCE_DIR}/MADBarcodeAusRoute.m"
	"${SOURCE_DIR}/MADBarcodeAusreDirect.m"
	"${SOURCE_DIR}/MADBarcodeAusreply.m"
	"${SOURCE_DIR}/MADBarcodeAztec.m"
	"${SOURCE_DIR}/MADBarcodeAztecRunes.m"
	"${SOURCE_DIR}/MADBarcodeChannelCode.m"
	"${SOURCE_DIR}/MADBarcodeCodabar.m"
	"${SOURCE_DIR}/MADBarcodeCode11.m"
	"${SOURCE_DIR}/MADBarcodeCode128Iso15417.m"
	"${SOURCE_DIR}/MADBarcodeCode16k.m"
	"${SOURCE_DIR}/MADBarcodeCode2of5DataLogic.m"
	"${SOURCE_DIR}/MADBarcodeCode2of5Iata.m"
	"${SOURCE_DIR}/MADBarcodeCode2of5Industrial.m"
	"${SOURCE_DIR}/MADBarcodeCode2of5Interleaved.m"
	"${SOURCE_DIR}/MADBarcodeCode2of5Matrix.m"
	"${SOURCE_DIR}/MADBarcodeCode32ItalianPharmacode.m"
	"${SOURCE_DIR}/MADBarcodeCode39Extended.m"
	"${SOURCE_DIR}/MADBarcodeCode39Iso16388.m"
	"${SOURCE_DIR}/MADBarcodeCode49.m"
	"${SOURCE_DIR}/MADBarcodeCode93.m"
	"${SOURCE_DIR}/MADBarcodeCodeOne.m"
	"${SOURCE_DIR}/MADBarcodeDataMatrixIso16022.m"
	"${SOURCE_DIR}/MADBarcodeDatabar.m"
	"${SOURCE_DIR}/MADBarcodeDatabarExpanded.m"
	"${SOURCE_DIR}/MADBarcodeDatabarExpandedStacked.m"
	"${SOURCE_DIR}/MADBarcodeDatabarLimited.m"
	"${SOURCE_DIR}/MADBarcodeDatabarStacked.m"
	"${SOURCE_DIR}/MADBarcodeDatabarStackedOmnidirectional.m"
	"${SOURCE_DIR}/MADBarcodeDeutschePostIdentcode.m"
	"${SOURCE_DIR}/MADBarcodeDeutschePostLeitcode.m"
	"${SOURCE_DIR}/MADBarcodeDutchPostKix.m"
	"${SOURCE_DIR}/MADBarcodeEan14.m"
	"${SOURCE_DIR}/MADBarcodeEuropeanArticleNumberEan.m"
	"${SOURCE_DIR}/MADBarcodeFacingIdentificationMarkFim.m"
	"${SOURCE_DIR}/MADBarcodeFlattermarken.m"
	"${SOURCE_DIR}/MADBarcodeGridMatrix.m"
	"${SOURCE_DIR}/MADBarcodeInternationalStandardBookNumberIsbn.m"
	"${SOURCE_DIR}/MADBarcodeItf14.m"
	"${SOURCE_DIR}/MADBarcodeJapanesePostalBarcode.m"
	"${SOURCE_DIR}/MADBarcodeKoreanPostalBarcode.m"
	"${SOURCE_DIR}/MADBarcodeLogmars.m"
	"${SOURCE_DIR}/MADBarcodeMaxicodeIso16023.m"
	"${SOURCE_DIR}/MADBarcodeMicroPdf417Iso24728.m"
	"${SOURCE_DIR}/MADBarcodeMicroQrCode.m"
	"${SOURCE_DIR}/MADBarcodeMsiPlessey.m"
	"${SOURCE_DIR}/MADBarcodeNve18.m"
	"${SOURCE_DIR}/MADBarcodePdf417Iso15438.m"
	"${SOURCE_DIR}/MADBarcodePharmaZentralnummerPzn.m"
	"${SOURCE_DIR}/MADBarcodePharmacode.m"
	"${SOURCE_DIR}/MADBarcodePharmacode2Track.m"
	"${SOURCE_DIR}/MADBarcodePlanet.m"
	"${SOURCE_DIR}/MADBarcodePostnet.m"
	"${SOURCE_DIR}/MADBarcodeQrCodeIso18004.m"
	"${SOURCE_DIR}/MADBarcodeRoyalMail4StateBarcode.m"
	"${SOURCE_DIR}/MADBarcodeTelepen.m"
	"${SOURCE_DIR}/MADBarcodeTelepenNumeric.m"
	"${SOURCE_DIR}/MADBarcodeUkPlessey.m"
	"${SOURCE_DIR}/MADBarcodeUniversalProductCodeUpca.m"
	"${SOURCE_DIR}/MADBarcodeUniversalProductCodeUpce.m"
	"${SOURCE_DIR}/MADBarcodeUspsIntelligentMail.m"
)
