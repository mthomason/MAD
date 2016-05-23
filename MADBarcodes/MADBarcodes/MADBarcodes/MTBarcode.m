//
//  MTBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTBarcode.h"
#import "MTBarcodeAusPostStandardCustomer.h"
#import "MTBarcodeAusreDirect.h"
#import "MTBarcodeAusreply.h"
#import "MTBarcodeAusRoute.h"
#import "MTBarcodeAztec.h"
#import "MTBarcodeAztecRunes.h"
#import "MTBarcodeChannelCode.h"
#import "MTBarcodeCodabar.h"
#import "MTBarcodeCode11.h"
#import "MTBarcodeCode128Iso15417.h"
#import "MTBarcodeCode16k.h"
#import "MTBarcodeCode2of5DataLogic.h"
#import "MTBarcodeCode2of5Iata.h"
#import "MTBarcodeCode2of5Industrial.h"
#import "MTBarcodeCode2of5Interleaved.h"
#import "MTBarcodeCode2of5Matrix.h"
#import "MTBarcodeCode32ItalianPharmacode.h"
#import "MTBarcodeCode39Extended.h"
#import "MTBarcodeCode39Iso16388.h"
#import "MTBarcodeCode49.h"
#import "MTBarcodeCode93.h"
#import "MTBarcodeCodeOne.h"
#import "MTBarcodeDatabar.h"
#import "MTBarcodeDatabarExpanded.h"
#import "MTBarcodeDatabarExpandedStacked.h"
#import "MTBarcodeDatabarLimited.h"
#import "MTBarcodeDatabarStacked.h"
#import "MTBarcodeDatabarStackedOmnidirectional.h"
#import "MTBarcodeDataMatrixIso16022.h"
#import "MTBarcodeDeutschePostIdentcode.h"
#import "MTBarcodeDeutschePostLeitcode.h"
#import "MTBarcodeDutchPostKix.h"
#import "MTBarcodeEan14.h"
#import "MTBarcodeEuropeanArticleNumberEan.h"
#import "MTBarcodeFacingIdentificationMarkFim.h"
#import "MTBarcodeFlattermarken.h"
#import "MTBarcodeGridMatrix.h"
#import "MTBarcodeInternationalStandardBookNumberIsbn.h"
#import "MTBarcodeItf14.h"
#import "MTBarcodeJapanesePostalBarcode.h"
#import "MTBarcodeKoreanPostalBarcode.h"
#import "MTBarcodeLogmars.h"
#import "MTBarcodeMaxicodeIso16023.h"
#import "MTBarcodeMicroPdf417Iso24728.h"
#import "MTBarcodeMicroQrCode.h"
#import "MTBarcodeMsiPlessey.h"
#import "MTBarcodeNve18.h"
#import "MTBarcodePdf417Iso15438.h"
#import "MTBarcodePharmacode.h"
#import "MTBarcodePharmacode2Track.h"
#import "MTBarcodePharmaZentralnummerPzn.h"
#import "MTBarcodePlanet.h"
#import "MTBarcodePostnet.h"
#import "MTBarcodeQrCodeIso18004.h"
#import "MTBarcodeRoyalMail4StateBarcode.h"
#import "MTBarcodeTelepen.h"
#import "MTBarcodeTelepenNumeric.h"
#import "MTBarcodeUkPlessey.h"
#import "MTBarcodeUniversalProductCodeUpca.h"
#import "MTBarcodeUniversalProductCodeUpce.h"
#import "MTBarcodeUspsIntelligentMail.h"

#import <UIKit/UIGraphics.h>
#import <UIKit/NSStringDrawing.h>

#import <MADCocoaExtensions/MADColor.h>

@interface MTBarcode ()

    @property (nonatomic, assign) CGFloat rotate;

    @property (nonatomic, copy, readwrite) MADColor *backgroundColor;

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;
    @property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

    + (instancetype)newBarcodeWithType:(MTBarcodeType)type;

@end

@implementation MTBarcode

- (void)dealloc { }

- (instancetype)init {
    if (self = [super init]) {
        MADColor *blackColor = [[MADColor alloc] initWithColor:[UIColor blackColor]];
        MADColor *whiteColor = [[MADColor alloc] initWithColor:[UIColor whiteColor]];
        _forgroundColor = blackColor;
        _backgroundColor = whiteColor;
        _showErrorMessages = YES;
        _humanReadable = YES;
        _height = 50;
        _borderWidth = 5;
        _rotate = (90.0000f * M_PI / 180.0000f);
        _option1 = NO;
        _option2 = NO;
        _option3 = NO;
        _center = NO;
        _scale = 1.0000f;
    }
    return self;
}

+ (instancetype)newBarcodeWithType:(MTBarcodeType)type {
    id result = nil;
    switch (type) {
        case MTBarcodeTypeAuspost:
            result = [[MTBarcodeAusPostStandardCustomer alloc] init];
            break;
        case MTBarcodeTypeAusreDirect:
            result = [[MTBarcodeAusreDirect alloc] init];
            break;
        case MTBarcodeTypeAusreply:
            result = [[MTBarcodeAusreply alloc] init];
            break;
        case MTBarcodeTypeAusroute:
            result = [[MTBarcodeAusRoute alloc] init];
            break;
        case MTBarcodeTypeAzrune:
            result = [[MTBarcodeAztecRunes alloc] init];
            break;
        case MTBarcodeTypeAztec:
            result = [[MTBarcodeAztec alloc] init];
            break;
        case MTBarcodeTypeC25IATA:
            result = [[MTBarcodeCode2of5Iata alloc] init];
            break;
        case MTBarcodeTypeC25IND:
            result = [[MTBarcodeCode2of5Industrial alloc] init];
            break;
        case MTBarcodeTypeC25INTER:
            result = [[MTBarcodeCode2of5Interleaved alloc] init];
            break;
        case MTBarcodeTypeC25LOGIC:
            result = [[MTBarcodeCode2of5DataLogic alloc] init];
            break;
        case MTBarcodeTypeC25MATRIX:
            result = [[MTBarcodeCode2of5Matrix alloc] init];
            break;
        case MTBarcodeTypeChannel:
            result = [[MTBarcodeChannelCode alloc] init];
            break;
        case MTBarcodeTypeCodeOne:
            result = [[MTBarcodeCodeOne alloc] init];
            break;
        case MTBarcodeTypeCODABAR:
            result = [[MTBarcodeCodabar alloc] init];
            break;
        case MTBarcodeTypeCode11:
            result = [[MTBarcodeCode11 alloc] init];
            break;
        case MTBarcodeTypeCODE128:
            result = [[MTBarcodeCode128Iso15417 alloc] init];
            break;
        case MTBarcodeTypeCode128b:
            result = [[MTBarcodeCode128SubsetB alloc] init];
            break;
        case MTBarcodeTypeEan14:
            result = [[MTBarcodeCode128Ean14 alloc] init];
            break;
        case MTBarcodeTypeNve18:
            result = [[MTBarcodeCode128Nve18 alloc] init];
            break;
        case MTBarcodeTypeHibc128:
            result = [[MTBarcodeCode128Hibc alloc] init];
            break;
        case MTBarcodeTypeEAN128:
            result = [[MTBarcodeCode128Ean128 alloc] init];
            break;
        case MTBarcodeTypeCODE16K:
            result = [[MTBarcodeCode16k alloc] init];
            break;
        case MTBarcodeTypeCode32:
            result = [[MTBarcodeCode32ItalianPharmacode alloc] init];
            break;
        case MTBarcodeTypeCODE39:
            result = [[MTBarcodeCode39Iso16388 alloc] init];
            break;
        case MTBarcodeTypeHibc39:
            result = [[MTBarcodeCode39Hbic alloc] init];
            break;
        case MTBarcodeTypeCODE49:
            result = [[MTBarcodeCode49 alloc] init];
            break;
        case MTBarcodeTypeCODE93:
            result = [[MTBarcodeCode93 alloc] init];
            break;
        case MTBarcodeTypeDataMatrix:
            result = [[MTBarcodeDataMatrixIso16022 alloc] init];
            break;
        case MTBarcodeTypeDPIDENT:
            result = [[MTBarcodeDeutschePostIdentcode alloc] init];
            break;
        case MTBarcodeTypeDPLEIT:
            result = [[MTBarcodeDeutschePostLeitcode alloc] init];
            break;
            //case MTBarcodeTypeEan14:
            //    result = [[MTBarcodeEan14 alloc] init];
            //    break;
        case MTBarcodeTypeEANX:
            result = [[MTBarcodeEuropeanArticleNumberEan alloc] init];
            break;
        case MTBarcodeTypeEXCODE39:
            result = [[MTBarcodeCode39Extended alloc] init];
            break;
        case MTBarcodeTypeFim:
            result = [[MTBarcodeFacingIdentificationMarkFim alloc] init];
            break;
        case MTBarcodeTypeFlat:
            result = [[MTBarcodeFlattermarken alloc] init];
            break;
        case MTBarcodeTypeGridMatrix:
            result = [[MTBarcodeGridMatrix alloc] init];
            break;
        case MTBarcodeTypeItf14:
            result = [[MTBarcodeItf14 alloc] init];
            break;
        case MTBarcodeTypeIsbnX:
            result = [[MTBarcodeInternationalStandardBookNumberIsbn alloc] init];
            break;
        case MTBarcodeTypeJapanPost:
            result = [[MTBarcodeJapanesePostalBarcode alloc] init];
            break;
        case MTBarcodeTypeKoreaPost:
            result = [[MTBarcodeKoreanPostalBarcode alloc] init];
            break;
        case MTBarcodeTypeLogmars:
            result = [[MTBarcodeLogmars alloc] init];
            break;
        case MTBarcodeTypeMaxicode:
            result = [[MTBarcodeMaxicodeIso16023 alloc] init];
            break;
        case MTBarcodeTypeMicroPdf417:
            result = [[MTBarcodeMicroPdf417Iso24728 alloc] init];
            break;
        case MTBarcodeTypeMicroqr:
            result = [[MTBarcodeMicroQrCode alloc] init];
            break;
        case MTBarcodeTypeMsiPlessey:
            result = [[MTBarcodeMsiPlessey alloc] init];
            break;
            //case MTBarcodeTypeNve18:
            //    result = [[MTBarcodeNve18 alloc] init];
            //    break;
        case MTBarcodeTypePdf417:
            result = [[MTBarcodePdf417Iso15438 alloc] init];
            break;
        case MTBarcodeTypePharma:
            result = [[MTBarcodePharmacode alloc] init];
            break;
        case MTBarcodeTypePharmaTwo:
            result = [[MTBarcodePharmacode2Track alloc] init];
            break;
        case MTBarcodeTypePzn:
            result = [[MTBarcodePharmaZentralnummerPzn alloc] init];
            break;
        case MTBarcodeTypePlanet:
            result = [[MTBarcodePlanet alloc] init];
            break;
        case MTBarcodeTypePostnet:
            result = [[MTBarcodePostnet alloc] init];
            break;
        case MTBarcodeTypeQrcode:
            result = [[MTBarcodeQrCodeIso18004 alloc] init];
            break;
        case MTBarcodeTypeRm4scc:
            result = [[MTBarcodeRoyalMail4StateBarcode alloc] init];
            break;
        case MTBarcodeTypeTelepen:
            result = [[MTBarcodeTelepen alloc] init];
            break;
        case MTBarcodeTypeTelepenNum:
            result = [[MTBarcodeTelepenNumeric alloc] init];
            break;
        case MTBarcodeTypePlessey:
            result = [[MTBarcodeUkPlessey alloc] init];
            break;
        case MTBarcodeTypeUpca:
            result = [[MTBarcodeUniversalProductCodeUpca alloc] init];
            break;
        case MTBarcodeTypeUpce:
            result = [[MTBarcodeUniversalProductCodeUpce alloc] init];
            break;
        case MTBarcodeTypeOneCode:
            result = [[MTBarcodeUspsIntelligentMail alloc] init];
            break;
        case MTBarcodeTypeRss14:
            result = [[MTBarcodeDatabar alloc] init];
            break;
        case MTBarcodeTypeRssLtd:
            result = [[MTBarcodeDatabarLimited alloc] init];
            break;
        case MTBarcodeTypeRssExp:
            result = [[MTBarcodeDatabarExpanded alloc] init];
            break;
        case MTBarcodeTypeRss14Stack:
            result = [[MTBarcodeDatabarStacked alloc] init];
            break;
        case MTBarcodeTypeRss14StackOmni:
            result = [[MTBarcodeDatabarStackedOmnidirectional alloc] init];
            break;
        case MTBarcodeTypeRssExpstack:
            result = [[MTBarcodeDatabarExpandedStacked alloc] init];
            break;
        case MTBarcodeTypeKix:
            result = [[MTBarcodeDutchPostKix alloc] init];
            break;
        default:
            break;
    }
    return result;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self = [super init]) {
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeFloat:     self.rotate                 forKey:@""];
    [coder encodeObject:    self.name                   forKey:@""];
    [coder encodeInteger:   self.barcodeType            forKey:@""];
    [coder encodeBool:      self.has2dComponent         forKey:@""];
    [coder encodeBool:      self.hasOptionalInput       forKey:@""];
    [coder encodeObject:    self.detailsSegueIdentifer  forKey:@""];
    [coder encodeObject:    self.primaryData            forKey:@""];
    [coder encodeInteger:   self.option1                forKey:@""];
    [coder encodeInteger:   self.option2                forKey:@""];
    [coder encodeInteger:   self.option3                forKey:@""];
    [coder encodeBool:      self.center                 forKey:@""];
    [coder encodeObject:    self.input                  forKey:@""];

    [coder encodeInteger:   self.height                 forKey:@""];
    [coder encodeInteger:   self.width                  forKey:@""];
    [coder encodeInteger:   self.borderWidth            forKey:@""];
    [coder encodeInteger:   self.whitespaceWidth        forKey:@""];
    [coder encodeBool:      self.humanReadable          forKey:@""];
    [coder encodeInteger:   self.borderStyle            forKey:@""];
    [coder encodeBool:      self.showErrorMessages      forKey:@""];
    [coder encodeBool:      self.has2dComponentEnabled  forKey:@""];
    [coder encodeInteger:   self.has2dComponentType     forKey:@""];
    [coder encodeFloat:     self.scale                  forKey:@""];
}

- (void)drawInRect:(CGRect)rect {
    CGRect originalRect = rect;

    struct zint_symbol *barcode = ZBarcode_Create();
    
    if (barcode == NULL) {
        [@"No barcode data." drawInRect:rect withAttributes:nil];
        
    } else {

        if (self.has2dComponentEnabled == NO) {
            barcode->symbology = self.barcodeType;
        } else {
            switch (self.barcodeType) {
                case MTBarcodeTypeEANX:
                    barcode->symbology = MTBarcodeTypeEanxCc;
                    break;
                case MTBarcodeTypeEAN128:
                    barcode->symbology = MTBarcodeTypeEan128Cc;
                    break;
                case MTBarcodeTypeCODE128:
                    barcode->symbology = MTBarcodeTypeCode128b;
                    break;
                case MTBarcodeTypeRss14:
                    barcode->symbology = MTBarcodeTypeRss14Cc;
                    break;
                case MTBarcodeTypeRssLtd:
                    barcode->symbology = MTBarcodeTypeRssLtdCc;
                    break;
                case MTBarcodeTypeRssExp:
                    barcode->symbology = MTBarcodeTypeRssExpCc;
                    break;
                case MTBarcodeTypeUpca:
                    barcode->symbology = MTBarcodeTypeUpcaCc;
                    break;
                case MTBarcodeTypeRss14Stack:
                    barcode->symbology = MTBarcodeTypeRss14StackCc;
                    break;
                case MTBarcodeTypeRss14StackOmni:
                    barcode->symbology = MTBarcodeTypeRss14OmniCc;
                    break;
                case MTBarcodeTypeRssExpstack:
                    barcode->symbology = MTBarcodeTypeRssExpstackCc;
                    break;
                case MTBarcodeTypeTelepenNum:
                    
                    
                    
                default:
                    break;
            }
        }
        NSString *forgroundColor = [self.forgroundColor hexStringValue];
        NSString *backgroundColor = [self.backgroundColor hexStringValue];
        const char *fgcolor = [forgroundColor cStringUsingEncoding:NSUTF8StringEncoding];
        const char *bgcolor = [backgroundColor cStringUsingEncoding:NSUTF8StringEncoding];
        strcpy(barcode->fgcolour, fgcolor);
        strcpy(barcode->bgcolour, bgcolor);
        
        barcode->height = (int)[self height];
        barcode->border_width = (int)[self borderWidth];
        barcode->whitespace_width = (int)[self whitespaceWidth];
        barcode->show_hrt = [self humanReadable];
        barcode->output_options = self.borderStyle;
        barcode->scale = 1.0000f;
        barcode->input_mode = MTBarcodeDataTypeUnicode;
        
        if (barcode->symbology != MTBarcodeTypeMaxicode) {
            barcode->option_1 = (int)[self option1];
            barcode->option_2 = (int)[self option2];
            barcode->option_3 = (int)[self option3];
        } else {
        }
        
        NSString *primaryInput = nil;
        if (self.has2dComponentEnabled) {
            
            primaryInput = [self primaryData];
            barcode->option_1 = (int)[self has2dComponentType];
            
            if ([[self input] length] > 0) {
                const char *primaryData = [[self input] UTF8String];
                strcpy(barcode->primary, primaryData);
            } else {
                strcpy(barcode->primary, "");
            }

        } else {
            primaryInput = [self input];
        }
        
        
        NSInteger inputLength = [primaryInput length];
        NSString *inputString = inputLength > 0 ? primaryInput : @"";
        
        if (barcode->symbology == MTBarcodeTypeTelepenNum) {
            NSCharacterSet *numeric = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            inputString = [[inputString componentsSeparatedByCharactersInSet:numeric] componentsJoinedByString:@""];
        }

        
        const char *input = [inputString UTF8String];
        int inputLen = (int)strlen(input);
        int success = ZBarcode_Encode_and_Buffer(barcode, (unsigned char *)input, inputLen, 0);
        NSString *errorMessage = nil;
        switch (success) {
            case WARN_INVALID_OPTION:
                errorMessage = NSLocalizedString(@"Warning: Invalid Option.", @"Warning: Invalid Option.");
                break;
            case ERROR_TOO_LONG:
                errorMessage = NSLocalizedString(@"Barcode error: To long.", @"Barcode error: To long.");
                break;
            case ERROR_INVALID_DATA:
                errorMessage = NSLocalizedString(@"Barcode error: Invalid data.", @"Barcode error: Invalid data.");
                break;
            case ERROR_INVALID_CHECK:
                errorMessage = NSLocalizedString(@"Barcode error: Invalid check.", @"Barcode error: Invalid check.");
                break;
            case ERROR_ENCODING_PROBLEM:
                errorMessage = NSLocalizedString(@"Barcode error: Encoding problem.", @"Barcode error: Encoding problem.");
                break;
            case ERROR_FILE_ACCESS:
                errorMessage = NSLocalizedString(@"Barcode error: File access.", @"Barcode error: File access.");
                break;
            case ERROR_MEMORY:
                errorMessage = NSLocalizedString(@"Barcode error: Memory error.", @"Barcode error: Memory error.");
                break;
            default:
                break;
        }
        
        if (errorMessage) {
            if ([self showErrorMessages]) {
                [errorMessage drawInRect:rect withAttributes:nil];
            }
        }
        
        CGFloat skewValue, skewValue2;
        BOOL portrait = barcode->bitmap_height > barcode->bitmap_width;
        BOOL makeSmaller, makeSmaller2;
        if (portrait) {
            makeSmaller = barcode->bitmap_height > rect.size.height;
            if (makeSmaller) {    //Make bigger
                skewValue = rect.size.height / barcode->bitmap_height;
            } else {
                skewValue = barcode->bitmap_height / rect.size.height;
            }
            makeSmaller2 = barcode->bitmap_width > rect.size.width;
            if (makeSmaller2) {
                skewValue2 = rect.size.width / barcode->bitmap_width;
            } else {
                skewValue2 = barcode->bitmap_width / rect.size.width;
            }

        } else {
            makeSmaller = barcode->bitmap_width > rect.size.width;
            if (makeSmaller) {
                skewValue = rect.size.width / barcode->bitmap_width;
            } else {
                skewValue = barcode->bitmap_width / rect.size.width;
            }
            makeSmaller2 = barcode->bitmap_height > rect.size.height;
            if (makeSmaller2) {
                skewValue2 = rect.size.height / barcode->bitmap_height;
            } else {
                skewValue2 = barcode->bitmap_height / rect.size.height;
            }
            
        }
        
        if (makeSmaller && makeSmaller2) {
            skewValue = MIN(skewValue, skewValue2);
        } else if (makeSmaller) {
            skewValue = skewValue;
        } else if (makeSmaller2) {
            skewValue = skewValue2;
        } else {
            skewValue = [self scale];
        }
        
        CGAffineTransform affineTransformMakeFit = CGAffineTransformMakeScale(skewValue, skewValue);
        CGAffineTransform affineTransformMoveOriginCenter = CGAffineTransformMakeTranslation(rect.size.width / 2.0000f, rect.size.height / 2.0000f);
        CGAffineTransform affineTransformRotate90 = CGAffineTransformMakeRotation(self.rotate);
        
        //Scale to fit
        CGContextRef context = UIGraphicsGetCurrentContext();

        CGContextSaveGState(context);
        //CGContextClipToRect(context, originalRect);
        
        if ([self center]) {
            CGRect bitmapRect = CGRectMake(CGPointZero.x, CGPointZero.y, barcode->bitmap_width * skewValue, barcode->bitmap_height * skewValue);
            CGFloat mx = CGRectGetMidX(bitmapRect);
            CGFloat my = CGRectGetMidY(bitmapRect);
            CGPoint bitmapCenter = CGPointMake(mx, my);
            mx = CGRectGetMidX(originalRect);
            my = CGRectGetMidY(originalRect);
            CGPoint origionalCenter = CGPointMake(mx, my);
            mx = origionalCenter.x - bitmapCenter.x;
            my = origionalCenter.y - bitmapCenter.y;
            CGAffineTransform affineTransformOrigin = CGAffineTransformMakeTranslation(mx, my);
            CGContextConcatCTM(context, affineTransformOrigin);
            
        }

        //Center, rotate, reset to origin
        CGContextConcatCTM(context, affineTransformMoveOriginCenter);
        CGContextConcatCTM(context, affineTransformRotate90);

        rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.height, rect.size.width);
        CGAffineTransform affineTransformResetOrigin = CGAffineTransformMakeTranslation(-rect.size.width / 2.0000f, -rect.size.height / 2.0000f);
        CGAffineTransform affineTransformMoveOffscreenTop = CGAffineTransformMakeTranslation(0, rect.size.height);
        CGAffineTransform affineTransformReflectDown = CGAffineTransformMakeScale(1.0000f, -1.0000f);

        CGContextConcatCTM(context, affineTransformResetOrigin);
        
        //Move up and flip down
        CGContextConcatCTM(context, affineTransformMoveOffscreenTop);
        CGContextConcatCTM(context, affineTransformReflectDown);
        
            //Right now we are at zero point.  Move to rect.org
            CGAffineTransform affineTransformOrigin = CGAffineTransformMakeTranslation(originalRect.origin.y, originalRect.origin.x);
            CGContextConcatCTM(context, affineTransformOrigin);
            /*
            CGRect bitmapRect = CGRectMake(CGPointZero.x, CGPointZero.y, barcode->bitmap_width * skewValue, barcode->bitmap_height * skewValue);
            CGFloat mx = CGRectGetMidX(bitmapRect);
            CGFloat my = CGRectGetMidY(bitmapRect);
            CGPoint bitmapCenter = CGPointMake(mx, my);
            mx = CGRectGetMidX(originalRect);
            my = CGRectGetMidY(originalRect);
            CGPoint origionalCenter = CGPointMake(mx, my);
            mx = origionalCenter.x - bitmapCenter.x;
            my = origionalCenter.y - bitmapCenter.y;
            CGAffineTransform affineTransformOrigin = CGAffineTransformMakeTranslation(mx, my);
            CGContextConcatCTM(context, affineTransformMoveOriginCenter);*/
        //Skew that bitch
        CGContextConcatCTM(context, affineTransformMakeFit);

        
        
        
        //Draw barcode
        if (success == 0) {
            int i = 0;
            int red, blue, green;
            for(int row = 0; row < barcode->bitmap_height; row++) {
                for(int column = 0; column < barcode->bitmap_width; column++) {
                    red = barcode->bitmap[i++];
                    green = barcode->bitmap[i++];
                    blue = barcode->bitmap[i++];
                    if (blue != -1 || red != -1 || green != -1) {
                        CGRect pixelToShade = CGRectMake(row, column, 1, 1);
                        CGContextSetRGBFillColor(context, red, green, blue, 1.0);
                        CGContextFillRect(context, pixelToShade);                       //Draw transparent background
                    } else {
                        CGRect pixelToShade = CGRectMake(row, column, 1, 1);
                        CGContextSetRGBFillColor(context, 1, 1, 1, 1.0);
                        CGContextFillRect(context, pixelToShade);                       //Draw transparent background
                    }
                }
            }
        }
        
        ZBarcode_Delete(barcode);
        barcode = NULL;
        
        CGContextRestoreGState(context);
        

    }
}

+ (NSDictionary *)newDictionaryNames {
    
    NSDictionary *names = @{
                  @BARCODE_AUSREDIRECT      : @"Australia Post Redirect Code",
                   @BARCODE_AUSREPLY        : @"Australia Post Reply-Paid",
                   @BARCODE_AUSROUTE        : @"Australia Post Routing Code",
                   @BARCODE_AUSPOST         : @"Australia Post Standard Customer",
                   @BARCODE_AZTEC           : @"Aztec Code (ISO 24778)",
                   @BARCODE_AZRUNE          : @"Aztec Runes",
                   @BARCODE_CHANNEL         : @"Channel Code",
                   @BARCODE_CODABAR         : @"Codabar",
                   @BARCODE_CODE11          : @"Code 11",
                   @BARCODE_CODE128         : @"Code 128 (ISO 15417)",
                   @(MTBarcodeTypeCode128b) : @"Code 128 (Subset C Suppression)",
                   @(MTBarcodeTypeEan14)    : @"Code 128 (EAN-14)",
                   @(MTBarcodeTypeHibc128)  : @"Code 128 (HBIC)",
                   @(MTBarcodeTypeEAN128)   : @"Code 128 (HBIC)",
                   @BARCODE_CODE16K         : @"Code 16k",
                   @BARCODE_C25LOGIC        : @"Code 2 of 5 Data Logic",
                   @BARCODE_C25IATA         : @"Code 2 of 5 IATA",
                   @BARCODE_C25IND          : @"Code 2 of 5 Industrial",
                   @BARCODE_C25INTER        : @"Code 2 of 5 Interleaved",
                   @BARCODE_C25MATRIX       : @"Code 2 of 5 Matrix",
                   @BARCODE_CODE32          : @"Code 32 (Italian Pharmacode)",
                   @BARCODE_CODE39          : @"Code 39 (ISO 16388)",
                   @BARCODE_EXCODE39        : @"Code 39 (Extended)",
                   @(MTBarcodeTypeHibc39)   : @"Code 39 (HBIC)",
                   @BARCODE_CODE49          : @"Code 49",
                   @BARCODE_CODE93          : @"Code 93",
                   @BARCODE_CODEONE         : @"Code One",
                   @BARCODE_RSS14           : @"Databar",
                   @BARCODE_RSS_EXP         : @"Databar Expanded",
                   @BARCODE_RSS_EXPSTACK    : @"Databar Expanded Stacked",
                   @BARCODE_RSS_LTD         : @"Databar Limited",
                   @BARCODE_RSS14STACK      : @"Databar Stacked",
                   @BARCODE_RSS14STACK_OMNI : @"Databar Stacked Omnidirectional",
                   @BARCODE_DATAMATRIX      : @"Data Matrix (ISO 16022)",
                   @BARCODE_DPIDENT         : @"Deutsche Post Identcode",
                   @BARCODE_DPLEIT          : @"Deutsche Post Leitcode",
                   @BARCODE_KIX             : @"Dutch Post KIX",
                   @BARCODE_EAN14           : @"EAN-14",
                   @BARCODE_EANX            : @"European Article Number (EAN)",
                   @BARCODE_FIM             : @"Facing Identification Mark (FIM)",
                   @BARCODE_FLAT            : @"Flattermarken",
                   @BARCODE_GRIDMATRIX      : @"Grid Matrix",
                   @BARCODE_ITF14           : @"ITF-14",
                   @BARCODE_ISBNX           : @"International Standard Book Number (ISBN)",
                   @BARCODE_JAPANPOST       : @"Japanese Postal Barcode",
                   @BARCODE_KOREAPOST       : @"Korean Postal Barcode",
                   @BARCODE_LOGMARS         : @"LOGMARS",
                   @BARCODE_MAXICODE        : @"Maxicode (ISO 16023)",
                   @BARCODE_MICROPDF417     : @"MicroPDF417 (ISO 24728)",
                   @BARCODE_MICROQR         : @"Micro QR Code",
                   @BARCODE_MSI_PLESSEY     : @"MSI Plessey",
                   @BARCODE_NVE18           : @"NVE-18",
                   @BARCODE_PDF417          : @"PDF417 (ISO 15438)",
                   @BARCODE_PHARMA          : @"Pharmacode",
                   @BARCODE_PHARMA_TWO      : @"Pharmacode 2-track",
                   @BARCODE_PZN             : @"Pharma Zentralnummer (PZN)",
                   @BARCODE_PLANET          : @"PLANET",
                   @BARCODE_POSTNET         : @"Postnet",
                   @BARCODE_QRCODE          : @"QR Code (ISO 18004)",
                   @BARCODE_RM4SCC          : @"Royal Mail 4-state Barcode",
                   @BARCODE_TELEPEN         : @"Telepen",
                   @BARCODE_TELEPEN_NUM     : @"Telepen Numeric",
                   @BARCODE_PLESSEY         : @"UK Plessey",
                   @BARCODE_UPCA            : @"Universal Product Code (UPC-A)",
                   @BARCODE_UPCE            : @"Universal Product Code (UPC-E)",
                   @BARCODE_ONECODE         : @"USPS Intelligent Mail"
                   };
    return names;
}

+ (NSString *)newBarcodeNameForType:(MTBarcodeType)type {
    id t = [[NSNumber alloc] initWithUnsignedInteger: type];
    NSDictionary *names = [MTBarcode newDictionaryNames];
    NSString *name = [names objectForKey: t];
    return name.copy;
}

- (void)initSampleData {
    
}

@end
