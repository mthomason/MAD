//
//  MTBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

@interface MTBarcode ()

@property (nonatomic, assign) CGFloat rotate;

@end

@implementation MTBarcode

- (void)dealloc {
    [_input release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {

        [self setShowErrorMessages:YES];
        [self setHumanReadable:YES];
        [self setBorderWidth:0];
        [self setWidth:0];
        [self setHeight:0];
        
        [self setRotate:(90 * M_PI / 180)];
        
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {

    struct zint_symbol *barcode = ZBarcode_Create();
    
    if (barcode == NULL) {
        CGFloat midY = CGRectGetMidY(rect);
        [@"No barcode data." drawAtPoint:CGPointMake(CGPointZero.x, midY) withAttributes:nil];
        
    } else {

        barcode->symbology = [self barcodeType];
        barcode->height = [self height];
        //barcode->width = [self width];
        barcode->border_width = [self borderWidth];
        barcode->whitespace_width = [self whitespaceWidth];
        barcode->show_hrt = [self humanReadable];
        barcode->output_options = [self borderStyle];
        barcode->scale = 1.0000f;
        barcode->input_mode = MTBarcodeDataTypeUnicode;
        
        NSInteger inputLength = [[self input] length];
        NSString *inputString = inputLength > 0 ? [self input] : @"";
        const char *input = [inputString UTF8String];
        int inputLen = strlen(input);
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
            CGFloat midY = CGRectGetMidY(rect);
            [errorMessage drawAtPoint:CGPointMake(CGPointZero.x, midY) withAttributes:nil];
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
            skewValue = 1.0000f;
        }
        
        CGAffineTransform affineTransformMakeFit = CGAffineTransformMakeScale(skewValue, skewValue);
        CGAffineTransform affineTransformMoveOriginCenter = CGAffineTransformMakeTranslation(rect.size.width / 2.0000f, rect.size.height / 2.0000f);
        CGAffineTransform affineTransformRotate90 = CGAffineTransformMakeRotation([self rotate]);
        CGAffineTransform affineTransformResetOrigin = CGAffineTransformMakeTranslation(-rect.size.width / 2.0000f, -rect.size.height / 2.0000f);
        CGAffineTransform affineTransformMoveOffscreenTop = CGAffineTransformMakeTranslation(0, rect.size.height);
        CGAffineTransform affineTransformReflectDown = CGAffineTransformMakeScale(1.0000f, -1.0000f);
        
        
        //Scale to fit
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextConcatCTM(context, affineTransformMakeFit);
        
        //Center, rotate, reset to origin
        CGContextConcatCTM(context, affineTransformMoveOriginCenter);
        CGContextConcatCTM(context, affineTransformRotate90);
        CGContextConcatCTM(context, affineTransformResetOrigin);
        
        //Move up and flip down
        CGContextConcatCTM(context, affineTransformMoveOffscreenTop);
        CGContextConcatCTM(context, affineTransformReflectDown);
        
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
    }
    
}

+ (NSDictionary *)names {
    
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
                   @BARCODE_CODE16K         : @"Code 16k",
                   @BARCODE_C25LOGIC        : @"Code 2 of 5 Data Logic",
                   @BARCODE_C25IATA         : @"Code 2 of 5 IATA",
                   @BARCODE_C25IND          : @"Code 2 of 5 Industrial",
                   @BARCODE_C25INTER        : @"Code 2 of 5 Interleaved",
                   @BARCODE_C25MATRIX       : @"Code 2 of 5 Matrix",
                   @BARCODE_CODE32          : @"Code 32 (Italian Pharmacode)",
                   @BARCODE_CODE39          : @"Code 39 (ISO 16388)",
                   @BARCODE_EXCODE39        : @"Code 39 Extended",
                   @BARCODE_CODE49          : @"Code 49",
                   @BARCODE_CODE93          : @"Code 93",
                   @BARCODE_CODEONE         : @"Code One",
                   @BARCODE_RSS14           : @"Databar",
                   @BARCODE_RSS_EXP         : @"Databar Expanded",
                   @BARCODE_RSS_EXPSTACK_CC : @"Databar Expanded Stacked",
                   @BARCODE_RSS_LTD_CC      : @"Databar Limited",
                   @BARCODE_RSS14STACK_CC   : @"Databar Stacked",
                   @BARCODE_RSS14_OMNI_CC   : @"Databar Stacked Omnidirectional",
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

+ (NSString *)barcodeNameForType:(MTBarcodeType)type {
    return [[MTBarcode names] objectForKey:@(type)];
}

@end
