//
//  MADBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADBarcode.h"
#import "MADBarcodeCache.h"
#import "MADBarcodeAusPostStandardCustomer.h"
#import "MADBarcodeAusreDirect.h"
#import "MADBarcodeAusreply.h"
#import "MADBarcodeAusRoute.h"
#import "MADBarcodeAztec.h"
#import "MADBarcodeAztecRunes.h"
#import "MADBarcodeChannelCode.h"
#import "MADBarcodeCodabar.h"
#import "MADBarcodeCode11.h"
#import "MADBarcodeCode128Iso15417.h"
#import "MADBarcodeCode16k.h"
#import "MADBarcodeCode2of5DataLogic.h"
#import "MADBarcodeCode2of5Iata.h"
#import "MADBarcodeCode2of5Industrial.h"
#import "MADBarcodeCode2of5Interleaved.h"
#import "MADBarcodeCode2of5Matrix.h"
#import "MADBarcodeCode32ItalianPharmacode.h"
#import "MADBarcodeCode39Extended.h"
#import "MADBarcodeCode39Iso16388.h"
#import "MADBarcodeCode49.h"
#import "MADBarcodeCode93.h"
#import "MADBarcodeCodeOne.h"
#import "MADBarcodeDatabar.h"
#import "MADBarcodeDatabarExpanded.h"
#import "MADBarcodeDatabarExpandedStacked.h"
#import "MADBarcodeDatabarLimited.h"
#import "MADBarcodeDatabarStacked.h"
#import "MADBarcodeDatabarStackedOmnidirectional.h"
#import "MADBarcodeDataMatrixIso16022.h"
#import "MADBarcodeDeutschePostIdentcode.h"
#import "MADBarcodeDeutschePostLeitcode.h"
#import "MADBarcodeDutchPostKix.h"
#import "MADBarcodeEan14.h"
#import "MADBarcodeEuropeanArticleNumberEan.h"
#import "MADBarcodeFacingIdentificationMarkFim.h"
#import "MADBarcodeFlattermarken.h"
#import "MADBarcodeGridMatrix.h"
#import "MADBarcodeInternationalStandardBookNumberIsbn.h"
#import "MADBarcodeItf14.h"
#import "MADBarcodeJapanesePostalBarcode.h"
#import "MADBarcodeKoreanPostalBarcode.h"
#import "MADBarcodeLogmars.h"
#import "MADBarcodeMaxicodeIso16023.h"
#import "MADBarcodeMicroPdf417Iso24728.h"
#import "MADBarcodeMicroQrCode.h"
#import "MADBarcodeMsiPlessey.h"
#import "MADBarcodeNve18.h"
#import "MADBarcodePdf417Iso15438.h"
#import "MADBarcodePharmacode.h"
#import "MADBarcodePharmacode2Track.h"
#import "MADBarcodePharmaZentralnummerPzn.h"
#import "MADBarcodePlanet.h"
#import "MADBarcodePostnet.h"
#import "MADBarcodeQrCodeIso18004.h"
#import "MADBarcodeRoyalMail4StateBarcode.h"
#import "MADBarcodeTelepen.h"
#import "MADBarcodeTelepenNumeric.h"
#import "MADBarcodeUkPlessey.h"
#import "MADBarcodeUniversalProductCodeUpca.h"
#import "MADBarcodeUniversalProductCodeUpce.h"
#import "MADBarcodeUspsIntelligentMail.h"

#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/UIColor.h>
#import <CoreGraphics/CGColorSpace.h>
#import <CoreGraphics/CGDataProvider.h>
#import <CoreGraphics/CGImage.h>

typedef NS_ENUM(unsigned char, MADBarcodeDataInputType) {
	MADBarcodeDataTypeUnicode = UNICODE_MODE,
	MADBarcodeDataTypeData = DATA_MODE,
	MADBarcodeDataTypeGs1 = GS1_MODE
};

static NSString * const MADBarcodeCodingKeyName					= @"name";
static NSString * const MADBarcodeCodingKeyDetailsSegue			= @"detailsSegueIdentifer";
static NSString * const MADBarcodeCodingKeyBarcodeType			= @"barcodeType";
static NSString * const MADBarcodeCodingKeyBorderStyle			= @"barcodeBorderStyle";
static NSString * const MADBarcodeCodingKeyWhitespaceWidth		= @"whitespaceWidth";
static NSString * const MADBarcodeCodingKeyBorderWidth			= @"barcodeBorderWidth";
static NSString * const MADBarcodeCodingKeyHeight				= @"barcodeHeight";
static NSString * const MADBarcodeCodingKeyHumanReadable		= @"humanReadable";
static NSString * const MADBarcodeCodingKeyOption1				= @"option1";
static NSString * const MADBarcodeCodingKeyOption2				= @"option2";
static NSString * const MADBarcodeCodingKeyOption3				= @"option3";
static NSString * const MADBarcodeCodingKeyShowErrorMessage		= @"showErrorMessage";
static NSString * const MADBarcodeCodingKeyScale				= @"scale";
static NSString * const MADBarcodeCodingKeyHas2dComponentEnabled = @"has2dComponentEnabled";
static NSString * const MADBarcodeCodingKeyHas2dComponent		= @"has2dComponent";
static NSString * const MADBarcodeCodingKeyHasOptionalInput		= @"hasOptionalInput";
static NSString * const MADBarcodeCodingKeyHas2dComponentType	= @"has2dComponentType";
static NSString * const MADBarcodeCodingKeyInput				= @"input";
static NSString * const MADBarcodeCodingKeyPrimaryData			= @"primaryData";
static NSString * const MADBarcodeCodingKeyCenter				= @"center";
static NSString * const MADBarcodeCodingKeyWidth				= @"width";
static NSString * const MADBarcodeCodingKeyRotate				= @"rotate";

// zint's raster buffer is 8-bit RGB, three bytes per pixel, row-major and
// opaque.  A CGImage consumes that layout directly; this class never sets
// fgcolour/bgcolour, so the bytes already are the black and white the paint
// loop used to clamp to.
static UIImage *MADBarcodeImageFromZintBitmap(const struct zint_symbol *symbol) {
	if (symbol->bitmap == NULL || symbol->bitmap_width <= 0 || symbol->bitmap_height <= 0) {
		return nil;
	}

	const size_t width = (size_t)symbol->bitmap_width;
	const size_t height = (size_t)symbol->bitmap_height;
	const size_t bytesPerRow = width * 3;
	NSData *data = [NSData dataWithBytes:symbol->bitmap length:bytesPerRow * height];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width, height, 8, 24, bytesPerRow, colorSpace,
									   (CGBitmapInfo)kCGImageAlphaNone, provider, NULL, false,
									   kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	CGDataProviderRelease(provider);
	if (cgImage == NULL) {
		return nil;
	}
	UIImage *image = [UIImage imageWithCGImage:cgImage
										 scale:1.0
								   orientation:UIImageOrientationUp];
	CGImageRelease(cgImage);
	return image;
}


@interface MADBarcode ()

@property (nonatomic, assign) CGFloat rotate;

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

+ (instancetype)newBarcodeWithType:(MADBarcodeType)type;

// The rendering primitive behind -renderedImage, and the only caller that can
// see the message from the same zint pass that failed.  MADBarcodeCache
// declares it too, to keep it off the public header.
- (UIImage *)renderedImageWithErrorMessage:(NSString * __autoreleasing *)errorMessage;

@end

@implementation MADBarcode

@synthesize barcodeType = _barcodeType;
@synthesize whitespaceWidth = _whitespaceWidth;
@synthesize has2dComponentEnabled = _has2dComponentEnabled;
@synthesize barcodeBorderStyle = _barcodeBorderStyle;
@synthesize barcodeBorderWidth = _barcodeBorderWidth;
@synthesize barcodeHeight = _barcodeHeight;
@synthesize humanReadable = _humanReadable;
@synthesize option1 = _option1;
@synthesize option2 = _option2;
@synthesize option3 = _option3;
@synthesize showErrorMessage = _showErrorMessage;
@synthesize scale = _scale;

- (void)dealloc { }

- (instancetype)init {
	if (self = [super init]) {
		//MADColor *blackColor = [[MADColor alloc] initWithColor:[UIColor blackColor]];
		//MADColor *whiteColor = [[MADColor alloc] initWithColor:[UIColor whiteColor]];
		//_forgroundColor = blackColor;
		//_backgroundColor = whiteColor;
		_showErrorMessage = YES;
		_humanReadable = YES;
		_barcodeHeight = 50;
		_barcodeBorderWidth = 5;
		_rotate = (90.0000f * M_PI / 180.0000f);
		_option1 = NO;
		_option2 = NO;
		_option3 = NO;
		_center = NO;
		_scale = 1.0000f;
	}
	return self;
}

+ (instancetype)newBarcode:(id <MADBarcodeProtocol>)documentObject {
	
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:documentObject.barcodeType];
	barcode.has2dComponentEnabled =		documentObject.has2dComponentEnabled;
	barcode.barcodeBorderStyle =		documentObject.barcodeBorderStyle;
	barcode.barcodeBorderWidth =		documentObject.barcodeBorderWidth;
	barcode.barcodeHeight =				documentObject.barcodeHeight;
	barcode.humanReadable =				documentObject.humanReadable;
	barcode.option1 =					documentObject.option1;
	barcode.option2 =					documentObject.option2;
	barcode.option3 =					documentObject.option3;
	barcode.showErrorMessage =			documentObject.showErrorMessage;
	barcode.whitespaceWidth =			documentObject.whitespaceWidth;
	barcode.scale =						documentObject.scale;
	barcode.input =						@"Sample data";
	barcode.primaryData =				@"";
	return barcode;
}

+ (instancetype)newBarcode:(id <MADBarcodeProtocol>)documentObject
					input1:(NSString *)input1
					input2:(NSString *)input2 {
	MADBarcode *barcode = [self newBarcode:documentObject];
	barcode.input = input1.copy;
	barcode.primaryData = input2.copy;
	return barcode;
}

+ (MADBarcodeType)type {
	return (MADBarcodeType)0;
}

+ (instancetype)newBarcodeWithType:(MADBarcodeType)type {
	id result = nil;
	switch (type) {
		case MADBarcodeTypeAuspost:
			result = [[MADBarcodeAusPostStandardCustomer alloc] init];
			break;
		case MADBarcodeTypeAusreDirect:
			result = [[MADBarcodeAusreDirect alloc] init];
			break;
		case MADBarcodeTypeAusreply:
			result = [[MADBarcodeAusreply alloc] init];
			break;
		case MADBarcodeTypeAusroute:
			result = [[MADBarcodeAusRoute alloc] init];
			break;
		case MADBarcodeTypeAzrune:
			result = [[MADBarcodeAztecRunes alloc] init];
			break;
		case MADBarcodeTypeAztec:
			result = [[MADBarcodeAztec alloc] init];
			break;
		case MADBarcodeTypeC25IATA:
			result = [[MADBarcodeCode2of5Iata alloc] init];
			break;
		case MADBarcodeTypeC25IND:
			result = [[MADBarcodeCode2of5Industrial alloc] init];
			break;
		case MADBarcodeTypeC25INTER:
			result = [[MADBarcodeCode2of5Interleaved alloc] init];
			break;
		case MADBarcodeTypeC25LOGIC:
			result = [[MADBarcodeCode2of5DataLogic alloc] init];
			break;
		case MADBarcodeTypeC25MATRIX:
			result = [[MADBarcodeCode2of5Matrix alloc] init];
			break;
		case MADBarcodeTypeChannel:
			result = [[MADBarcodeChannelCode alloc] init];
			break;
		case MADBarcodeTypeCodeOne:
			result = [[MADBarcodeCodeOne alloc] init];
			break;
		case MADBarcodeTypeCODABAR:
			result = [[MADBarcodeCodabar alloc] init];
			break;
		case MADBarcodeTypeCode11:
			result = [[MADBarcodeCode11 alloc] init];
			break;
		case MADBarcodeTypeCODE128:
			result = [[MADBarcodeCode128Iso15417 alloc] init];
			break;
		case MADBarcodeTypeCode128b:
			result = [[MADBarcodeCode128SubsetB alloc] init];
			break;
		case MADBarcodeTypeEan14:
			result = [[MADBarcodeCode128Ean14 alloc] init];
			break;
		case MADBarcodeTypeNve18:
			result = [[MADBarcodeCode128Nve18 alloc] init];
			break;
		case MADBarcodeTypeHibc128:
			result = [[MADBarcodeCode128Hibc alloc] init];
			break;
		case MADBarcodeTypeEAN128:
			result = [[MADBarcodeCode128Ean128 alloc] init];
			break;
		case MADBarcodeTypeCODE16K:
			result = [[MADBarcodeCode16k alloc] init];
			break;
		case MADBarcodeTypeCode32:
			result = [[MADBarcodeCode32ItalianPharmacode alloc] init];
			break;
		case MADBarcodeTypeCODE39:
			result = [[MADBarcodeCode39Iso16388 alloc] init];
			break;
		case MADBarcodeTypeHibc39:
			result = [[MADBarcodeCode39Hbic alloc] init];
			break;
		case MADBarcodeTypeCODE49:
			result = [[MADBarcodeCode49 alloc] init];
			break;
		case MADBarcodeTypeCODE93:
			result = [[MADBarcodeCode93 alloc] init];
			break;
		case MADBarcodeTypeDataMatrix:
			result = [[MADBarcodeDataMatrixIso16022 alloc] init];
			break;
		case MADBarcodeTypeDPIDENT:
			result = [[MADBarcodeDeutschePostIdentcode alloc] init];
			break;
		case MADBarcodeTypeDPLEIT:
			result = [[MADBarcodeDeutschePostLeitcode alloc] init];
			break;
			//case MADBarcodeTypeEan14:
			//	result = [[MADBarcodeEan14 alloc] init];
			//	break;
		case MADBarcodeTypeEANX:
			result = [[MADBarcodeEuropeanArticleNumberEan alloc] init];
			break;
		case MADBarcodeTypeEXCODE39:
			result = [[MADBarcodeCode39Extended alloc] init];
			break;
		case MADBarcodeTypeFim:
			result = [[MADBarcodeFacingIdentificationMarkFim alloc] init];
			break;
		case MADBarcodeTypeFlat:
			result = [[MADBarcodeFlattermarken alloc] init];
			break;
		case MADBarcodeTypeGridMatrix:
			result = [[MADBarcodeGridMatrix alloc] init];
			break;
		case MADBarcodeTypeItf14:
			result = [[MADBarcodeItf14 alloc] init];
			break;
		case MADBarcodeTypeIsbnX:
			result = [[MADBarcodeInternationalStandardBookNumberIsbn alloc] init];
			break;
		case MADBarcodeTypeJapanPost:
			result = [[MADBarcodeJapanesePostalBarcode alloc] init];
			break;
		case MADBarcodeTypeKoreaPost:
			result = [[MADBarcodeKoreanPostalBarcode alloc] init];
			break;
		case MADBarcodeTypeLogmars:
			result = [[MADBarcodeLogmars alloc] init];
			break;
		case MADBarcodeTypeMaxicode:
			result = [[MADBarcodeMaxicodeIso16023 alloc] init];
			break;
		case MADBarcodeTypeMicroPdf417:
			result = [[MADBarcodeMicroPdf417Iso24728 alloc] init];
			break;
		case MADBarcodeTypeMicroqr:
			result = [[MADBarcodeMicroQrCode alloc] init];
			break;
		case MADBarcodeTypeMsiPlessey:
			result = [[MADBarcodeMsiPlessey alloc] init];
			break;
			//case MADBarcodeTypeNve18:
			//	result = [[MADBarcodeNve18 alloc] init];
			//	break;
		case MADBarcodeTypePdf417:
			result = [[MADBarcodePdf417Iso15438 alloc] init];
			break;
		case MADBarcodeTypePharma:
			result = [[MADBarcodePharmacode alloc] init];
			break;
		case MADBarcodeTypePharmaTwo:
			result = [[MADBarcodePharmacode2Track alloc] init];
			break;
		case MADBarcodeTypePzn:
			result = [[MADBarcodePharmaZentralnummerPzn alloc] init];
			break;
		case MADBarcodeTypePlanet:
			result = [[MADBarcodePlanet alloc] init];
			break;
		case MADBarcodeTypePostnet:
			result = [[MADBarcodePostnet alloc] init];
			break;
		case MADBarcodeTypeQrcode:
			result = [[MADBarcodeQrCodeIso18004 alloc] init];
			break;
		case MADBarcodeTypeRm4scc:
			result = [[MADBarcodeRoyalMail4StateBarcode alloc] init];
			break;
		case MADBarcodeTypeTelepen:
			result = [[MADBarcodeTelepen alloc] init];
			break;
		case MADBarcodeTypeTelepenNum:
			result = [[MADBarcodeTelepenNumeric alloc] init];
			break;
		case MADBarcodeTypePlessey:
			result = [[MADBarcodeUkPlessey alloc] init];
			break;
		case MADBarcodeTypeUpca:
			result = [[MADBarcodeUniversalProductCodeUpca alloc] init];
			break;
		case MADBarcodeTypeUpce:
			result = [[MADBarcodeUniversalProductCodeUpce alloc] init];
			break;
		case MADBarcodeTypeOneCode:
			result = [[MADBarcodeUspsIntelligentMail alloc] init];
			break;
		case MADBarcodeTypeRss14:
			result = [[MADBarcodeDatabar alloc] init];
			break;
		case MADBarcodeTypeRssLtd:
			result = [[MADBarcodeDatabarLimited alloc] init];
			break;
		case MADBarcodeTypeRssExp:
			result = [[MADBarcodeDatabarExpanded alloc] init];
			break;
		case MADBarcodeTypeRss14Stack:
			result = [[MADBarcodeDatabarStacked alloc] init];
			break;
		case MADBarcodeTypeRss14StackOmni:
			result = [[MADBarcodeDatabarStackedOmnidirectional alloc] init];
			break;
		case MADBarcodeTypeRssExpstack:
			result = [[MADBarcodeDatabarExpandedStacked alloc] init];
			break;
		case MADBarcodeTypeKix:
			result = [[MADBarcodeDutchPostKix alloc] init];
			break;
		default:
			break;
	}
	return result;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [self init]) {
		_name = [[coder decodeObjectOfClass:[NSString class]
									 forKey:MADBarcodeCodingKeyName] copy];
		_detailsSegueIdentifer = [[coder decodeObjectOfClass:[NSString class]
													 forKey:MADBarcodeCodingKeyDetailsSegue] copy];
		_barcodeType = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyBarcodeType];
		_barcodeBorderStyle = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyBorderStyle];
		_whitespaceWidth = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyWhitespaceWidth];
		_barcodeBorderWidth = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyBorderWidth];
		_barcodeHeight = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyHeight];
		_humanReadable = [coder decodeBoolForKey:MADBarcodeCodingKeyHumanReadable];
		_option1 = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyOption1];
		_option2 = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyOption2];
		_option3 = (int16_t)[coder decodeIntegerForKey:MADBarcodeCodingKeyOption3];
		_showErrorMessage = [coder decodeBoolForKey:MADBarcodeCodingKeyShowErrorMessage];
		_scale = [coder decodeFloatForKey:MADBarcodeCodingKeyScale];
		_has2dComponentEnabled = [coder decodeBoolForKey:MADBarcodeCodingKeyHas2dComponentEnabled];
		_has2dComponent = [coder decodeBoolForKey:MADBarcodeCodingKeyHas2dComponent];
		_hasOptionalInput = [coder decodeBoolForKey:MADBarcodeCodingKeyHasOptionalInput];
		_has2dComponentType = [coder decodeIntegerForKey:MADBarcodeCodingKeyHas2dComponentType];
		_input = [[coder decodeObjectOfClass:[NSString class]
									  forKey:MADBarcodeCodingKeyInput] copy];
		_primaryData = [[coder decodeObjectOfClass:[NSString class]
											forKey:MADBarcodeCodingKeyPrimaryData] copy];
		_center = [coder decodeBoolForKey:MADBarcodeCodingKeyCenter];
		_width = [coder decodeIntegerForKey:MADBarcodeCodingKeyWidth];
		_rotate = [coder decodeDoubleForKey:MADBarcodeCodingKeyRotate];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:	self.name					forKey:MADBarcodeCodingKeyName];
	[coder encodeObject:	self.detailsSegueIdentifer	forKey:MADBarcodeCodingKeyDetailsSegue];
	[coder encodeInteger:	self.barcodeType			forKey:MADBarcodeCodingKeyBarcodeType];
	[coder encodeInteger:	self.barcodeBorderStyle		forKey:MADBarcodeCodingKeyBorderStyle];
	[coder encodeInteger:	self.whitespaceWidth		forKey:MADBarcodeCodingKeyWhitespaceWidth];
	[coder encodeInteger:	self.barcodeBorderWidth		forKey:MADBarcodeCodingKeyBorderWidth];
	[coder encodeInteger:	self.barcodeHeight			forKey:MADBarcodeCodingKeyHeight];
	[coder encodeBool:		self.humanReadable			forKey:MADBarcodeCodingKeyHumanReadable];
	[coder encodeInteger:	self.option1				forKey:MADBarcodeCodingKeyOption1];
	[coder encodeInteger:	self.option2				forKey:MADBarcodeCodingKeyOption2];
	[coder encodeInteger:	self.option3				forKey:MADBarcodeCodingKeyOption3];
	[coder encodeBool:		self.showErrorMessage		forKey:MADBarcodeCodingKeyShowErrorMessage];
	[coder encodeFloat:		self.scale					forKey:MADBarcodeCodingKeyScale];
	[coder encodeBool:		self.has2dComponentEnabled	forKey:MADBarcodeCodingKeyHas2dComponentEnabled];
	[coder encodeBool:		self.has2dComponent			forKey:MADBarcodeCodingKeyHas2dComponent];
	[coder encodeBool:		self.hasOptionalInput		forKey:MADBarcodeCodingKeyHasOptionalInput];
	[coder encodeInteger:	self.has2dComponentType		forKey:MADBarcodeCodingKeyHas2dComponentType];
	[coder encodeObject:	self.input					forKey:MADBarcodeCodingKeyInput];
	[coder encodeObject:	self.primaryData			forKey:MADBarcodeCodingKeyPrimaryData];
	[coder encodeBool:		self.center					forKey:MADBarcodeCodingKeyCenter];
	[coder encodeInteger:	self.width					forKey:MADBarcodeCodingKeyWidth];
	[coder encodeDouble:	self.rotate					forKey:MADBarcodeCodingKeyRotate];
}

- (void)drawInRect:(CGRect)rect {
	MADBarcodeCache *cache = [MADBarcodeCache sharedCache];
	UIImage *image = [cache imageForBarcode:self];

	if (image == nil) {
		if (self.showErrorMessage) {
			NSString *errorMessage = [cache errorMessageForBarcode:self];
			if (errorMessage != nil) {
				[errorMessage drawInRect:rect withAttributes:nil];
			}
		}
		return;
	}

	// The paint loop this replaces walked the zint rows and columns and painted
	// cell (column, row) at (row, column) through a rotate/flip stack whose net
	// effect was the natural bitmap, scaled to fit, at the rect's origin.  The
	// image is that natural bitmap, so one draw call reproduces the result.
	const CGFloat bitmapWidth = image.size.width;
	const CGFloat bitmapHeight = image.size.height;

	CGFloat skewValue, skewValue2;
	BOOL makeSmaller, makeSmaller2;
	BOOL portrait = bitmapHeight > bitmapWidth;
	if (portrait) {
		makeSmaller = bitmapHeight > rect.size.height;
		if (makeSmaller) {
			skewValue = rect.size.height / bitmapHeight;
		} else {
			skewValue = bitmapHeight / rect.size.height;
		}
		makeSmaller2 = bitmapWidth > rect.size.width;
		if (makeSmaller2) {
			skewValue2 = rect.size.width / bitmapWidth;
		} else {
			skewValue2 = bitmapWidth / rect.size.width;
		}
	} else {
		makeSmaller = bitmapWidth > rect.size.width;
		if (makeSmaller) {
			skewValue = rect.size.width / bitmapWidth;
		} else {
			skewValue = bitmapWidth / rect.size.width;
		}
		makeSmaller2 = bitmapHeight > rect.size.height;
		if (makeSmaller2) {
			skewValue2 = rect.size.height / bitmapHeight;
		} else {
			skewValue2 = bitmapHeight / rect.size.height;
		}
	}

	if (makeSmaller && makeSmaller2) {
		skewValue = MIN(skewValue, skewValue2);
	} else if (makeSmaller) {
		// skewValue already holds the fit.
	} else if (makeSmaller2) {
		skewValue = skewValue2;
	} else {
		skewValue = self.scale;
	}

	CGFloat x = rect.origin.x;
	CGFloat y = rect.origin.y;
	if (self.center) {
		x += CGRectGetMidX(rect) - (bitmapWidth * skewValue) / 2.0000f;
		y += CGRectGetMidY(rect) - (bitmapHeight * skewValue) / 2.0000f;
	}

	[image drawInRect:CGRectMake(x, y, bitmapWidth * skewValue, bitmapHeight * skewValue)];
}

- (NSString *)renderCacheKey {
	NSMutableString *key = [NSMutableString string];
	[key appendFormat:@"%d.%d.%ld.%d.%d.%d.%d.%d.%d.%d.%d.%d.",
	 (int)self.barcodeType,
	 self.has2dComponentEnabled ? 1 : 0,
	 (long)self.has2dComponentType,
	 (int)self.barcodeBorderStyle,
	 (int)self.barcodeBorderWidth,
	 (int)self.barcodeHeight,
	 (int)self.whitespaceWidth,
	 self.humanReadable ? 1 : 0,
	 (int)self.option1,
	 (int)self.option2,
	 (int)self.option3,
	 self.showErrorMessage ? 1 : 0];
	[key appendFormat:@"%.9g.", (double)self.scale];
	[key appendFormat:@"%.17g.", (double)self.rotate];
	[key appendFormat:@"%d.", self.center ? 1 : 0];
	// Length-prefixed so a value can never forge a field boundary.
	[key appendFormat:@"%lu:", (unsigned long)self.input.length];
	[key appendString:self.input ?: @""];
	[key appendFormat:@".%lu:", (unsigned long)self.primaryData.length];
	[key appendString:self.primaryData ?: @""];
	return key;
}

- (UIImage *)renderedImage {
	return [self renderedImageWithErrorMessage:NULL];
}

- (UIImage *)renderedImageWithErrorMessage:(NSString * __autoreleasing *)errorMessageOut {
	struct zint_symbol *barcode = ZBarcode_Create();

	if (barcode == NULL) {
		if (errorMessageOut != NULL) {
			*errorMessageOut = NSLocalizedString(@"No barcode data.", @"No barcode data.");
		}
		return nil;
	}

	if (self.has2dComponentEnabled == NO) {
		barcode->symbology = self.barcodeType;
	} else {
		switch (self.barcodeType) {
			case MADBarcodeTypeEANX:
				barcode->symbology = MADBarcodeTypeEanxCc;
				break;
			case MADBarcodeTypeEAN128:
				barcode->symbology = MADBarcodeTypeEan128Cc;
				break;
			case MADBarcodeTypeCODE128:
				barcode->symbology = MADBarcodeTypeCode128b;
				break;
			case MADBarcodeTypeRss14:
				barcode->symbology = MADBarcodeTypeRss14Cc;
				break;
			case MADBarcodeTypeRssLtd:
				barcode->symbology = MADBarcodeTypeRssLtdCc;
				break;
			case MADBarcodeTypeRssExp:
				barcode->symbology = MADBarcodeTypeRssExpCc;
				break;
			case MADBarcodeTypeUpca:
				barcode->symbology = MADBarcodeTypeUpcaCc;
				break;
			case MADBarcodeTypeRss14Stack:
				barcode->symbology = MADBarcodeTypeRss14StackCc;
				break;
			case MADBarcodeTypeRss14StackOmni:
				barcode->symbology = MADBarcodeTypeRss14OmniCc;
				break;
			case MADBarcodeTypeRssExpstack:
				barcode->symbology = MADBarcodeTypeRssExpstackCc;
				break;
			case MADBarcodeTypeTelepenNum:
			default:
				break;
		}
	}
	barcode->height = (float)self.barcodeHeight;
	barcode->border_width = (int)self.barcodeBorderWidth;
	barcode->whitespace_width = (int)self.whitespaceWidth;
	barcode->show_hrt = self.humanReadable;
	barcode->output_options = self.barcodeBorderStyle;
	barcode->scale = 1.0000f;
	barcode->input_mode = MADBarcodeDataTypeUnicode;

	if (barcode->symbology != MADBarcodeTypeMaxicode) {
		barcode->option_1 = (int)self.option1;
		barcode->option_2 = (int)self.option2;
		barcode->option_3 = (int)self.option3;
	}

	NSString *primaryInput = nil;
	BOOL primaryTooLong = NO;
	if (self.has2dComponentEnabled) {

		primaryInput = self.primaryData;
		barcode->option_1 = (int)self.has2dComponentType;

		if (self.input.length > 0) {
			const char *primaryData = self.input.UTF8String;
			size_t primaryLength = strlen(primaryData);
			if (primaryLength >= sizeof(barcode->primary)) {
				// zint's primary buffer is a fixed 128-byte array; copying an
				// overlong value would run past the end of the struct.
				NSLog(@"Barcode primary data is %zu bytes; zint's primary buffer holds %zu.",
					  primaryLength, sizeof(barcode->primary) - 1);
				primaryTooLong = YES;
			} else {
				// The length check above bounds this copy by the 128-byte buffer.
				memcpy(barcode->primary, primaryData, primaryLength + 1);
			}
		} else {
			barcode->primary[0] = '\0';
		}

	} else {
		primaryInput = self.input;
	}

	NSString *inputString = primaryInput.length > 0 ? primaryInput : @"";

	if (barcode->symbology == MADBarcodeTypeTelepenNum) {
		NSCharacterSet *numeric = [NSCharacterSet decimalDigitCharacterSet].invertedSet;
		inputString = [[inputString componentsSeparatedByCharactersInSet:numeric] componentsJoinedByString:@""];
	}

	NSString *errorMessage = nil;
	int success = ZINT_ERROR_INVALID_DATA;
	if (primaryTooLong) {
		errorMessage = NSLocalizedString(@"Barcode error: Primary data too long.", @"Barcode error: Primary data too long.");
	} else {
		const char *input = inputString.UTF8String;
		int inputLen = (int)strlen(input);
		success = ZBarcode_Encode_and_Buffer(barcode, (unsigned char *)input, inputLen, 0);
		switch (success) {
			case ZINT_WARN_INVALID_OPTION:
				errorMessage = NSLocalizedString(@"Warning: Invalid Option.", @"Warning: Invalid Option.");
				break;
			case ZINT_ERROR_TOO_LONG:
				errorMessage = NSLocalizedString(@"Barcode error: To long.", @"Barcode error: To long.");
				break;
			case ZINT_ERROR_INVALID_DATA:
				errorMessage = NSLocalizedString(@"Barcode error: Invalid data.", @"Barcode error: Invalid data.");
				break;
			case ZINT_ERROR_INVALID_CHECK:
				errorMessage = NSLocalizedString(@"Barcode error: Invalid check.", @"Barcode error: Invalid check.");
				break;
			case ZINT_ERROR_ENCODING_PROBLEM:
				errorMessage = NSLocalizedString(@"Barcode error: Encoding problem.", @"Barcode error: Encoding problem.");
				break;
			case ZINT_ERROR_FILE_ACCESS:
				errorMessage = NSLocalizedString(@"Barcode error: File access.", @"Barcode error: File access.");
				break;
			case ZINT_ERROR_MEMORY:
				errorMessage = NSLocalizedString(@"Barcode error: Memory error.", @"Barcode error: Memory error.");
				break;
			default:
				break;
		}
	}

	UIImage *image = nil;
	if (success == 0 && errorMessage == nil) {
		image = MADBarcodeImageFromZintBitmap(barcode);
	}

	ZBarcode_Delete(barcode);
	barcode = NULL;

	if (errorMessageOut != NULL) {
		*errorMessageOut = errorMessage;
	}
	return image;
}

+ (NSDictionary *)newDictionaryNames {
	
	NSDictionary *names = @{
				  @BARCODE_AUSREDIRECT		: @"Australia Post Redirect Code",
				   @BARCODE_AUSREPLY		: @"Australia Post Reply-Paid",
				   @BARCODE_AUSROUTE		: @"Australia Post Routing Code",
				   @BARCODE_AUSPOST			: @"Australia Post Standard Customer",
				   @BARCODE_AZTEC			: @"Aztec Code (ISO 24778)",
				   @BARCODE_AZRUNE			: @"Aztec Runes",
				   @BARCODE_CHANNEL			: @"Channel Code",
				   @BARCODE_CODABAR			: @"Codabar",
				   @BARCODE_CODE11			: @"Code 11",
				   @BARCODE_CODE128			: @"Code 128 (ISO 15417)",
				   @(MADBarcodeTypeCode128b)	: @"Code 128 (Subset C Suppression)",
				   @(MADBarcodeTypeHibc128)	: @"Code 128 (HBIC)",
				   @(MADBarcodeTypeEAN128)	: @"Code 128 (HBIC)",
				   @BARCODE_CODE16K			: @"Code 16k",
				   @BARCODE_C25LOGIC		: @"Code 2 of 5 Data Logic",
				   @BARCODE_C25IATA			: @"Code 2 of 5 IATA",
				   @BARCODE_C25IND			: @"Code 2 of 5 Industrial",
				   @BARCODE_C25INTER		: @"Code 2 of 5 Interleaved",
				   @BARCODE_C25MATRIX		: @"Code 2 of 5 Matrix",
				   @BARCODE_CODE32			: @"Code 32 (Italian Pharmacode)",
				   @BARCODE_CODE39			: @"Code 39 (ISO 16388)",
				   @BARCODE_EXCODE39		: @"Code 39 (Extended)",
				   @(MADBarcodeTypeHibc39)	: @"Code 39 (HBIC)",
				   @BARCODE_CODE49			: @"Code 49",
				   @BARCODE_CODE93			: @"Code 93",
				   @BARCODE_CODEONE			: @"Code One",
				   @BARCODE_RSS14			: @"Databar",
				   @BARCODE_RSS_EXP			: @"Databar Expanded",
				   @BARCODE_RSS_EXPSTACK	: @"Databar Expanded Stacked",
				   @BARCODE_RSS_LTD			: @"Databar Limited",
				   @BARCODE_RSS14STACK		: @"Databar Stacked",
				   @BARCODE_RSS14STACK_OMNI	: @"Databar Stacked Omnidirectional",
				   @BARCODE_DATAMATRIX		: @"Data Matrix (ISO 16022)",
				   @BARCODE_DPIDENT			: @"Deutsche Post Identcode",
				   @BARCODE_DPLEIT			: @"Deutsche Post Leitcode",
				   @BARCODE_KIX				: @"Dutch Post KIX",
				   @BARCODE_EAN14			: @"EAN-14",
				   @BARCODE_EANX			: @"European Article Number (EAN)",
				   @BARCODE_FIM				: @"Facing Identification Mark (FIM)",
				   @BARCODE_FLAT			: @"Flattermarken",
				   @BARCODE_GRIDMATRIX		: @"Grid Matrix",
				   @BARCODE_ITF14			: @"ITF-14",
				   @BARCODE_ISBNX			: @"International Standard Book Number (ISBN)",
				   @BARCODE_JAPANPOST		: @"Japanese Postal Barcode",
				   @BARCODE_KOREAPOST		: @"Korean Postal Barcode",
				   @BARCODE_LOGMARS			: @"LOGMARS",
				   @BARCODE_MAXICODE		: @"Maxicode (ISO 16023)",
				   @BARCODE_MICROPDF417		: @"MicroPDF417 (ISO 24728)",
				   @BARCODE_MICROQR			: @"Micro QR Code",
				   @BARCODE_MSI_PLESSEY		: @"MSI Plessey",
				   @BARCODE_NVE18			: @"NVE-18",
				   @BARCODE_PDF417			: @"PDF417 (ISO 15438)",
				   @BARCODE_PHARMA			: @"Pharmacode",
				   @BARCODE_PHARMA_TWO		: @"Pharmacode 2-track",
				   @BARCODE_PZN				: @"Pharma Zentralnummer (PZN)",
				   @BARCODE_PLANET			: @"PLANET",
				   @BARCODE_POSTNET			: @"Postnet",
				   @BARCODE_QRCODE			: @"QR Code (ISO 18004)",
				   @BARCODE_RM4SCC			: @"Royal Mail 4-state Barcode",
				   @BARCODE_TELEPEN			: @"Telepen",
				   @BARCODE_TELEPEN_NUM		: @"Telepen Numeric",
				   @BARCODE_PLESSEY			: @"UK Plessey",
				   @BARCODE_UPCA			: @"Universal Product Code (UPC-A)",
				   @BARCODE_UPCE			: @"Universal Product Code (UPC-E)",
				   @BARCODE_ONECODE			: @"USPS Intelligent Mail"
				   };
	return names;
}

+ (NSString *)newBarcodeNameForType:(MADBarcodeType)type {
	NSNumber *typeWrapper = [[NSNumber alloc] initWithUnsignedInteger: (NSUInteger)type];
	NSDictionary *names = [MADBarcode newDictionaryNames];
	NSString *name = names[typeWrapper];
	return name.copy;
}

- (void)loadSampleData {

}

@end
