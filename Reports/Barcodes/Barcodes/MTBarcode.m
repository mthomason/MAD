//
//  MTBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

@interface MTBarcode ()

@property (nonatomic, assign) struct zint_symbol *barcode;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, assign) CGFloat rotate;

@end

@implementation MTBarcode

- (void)dealloc {
    if (self->_barcode != NULL) {
        ZBarcode_Delete(_barcode);
    }
    [_input release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {

        struct zint_symbol *barcode;
        barcode = ZBarcode_Create();
        [self setBarcode:barcode];
        
        [self setShowErrorMessages:YES];
        [self setRotate:(90 * M_PI / 180)];
        
    }
    return self;
}

- (MTBarcodeType)barcodeType {
    return self->_barcode->symbology;
}

- (void)setBarcodeType:(MTBarcodeType)barcodeType {
    if (self->_barcode != NULL) {
        self->_barcode->symbology = barcodeType;
    }
}

- (NSInteger)height {
    return self->_barcode->height;
}

- (void)setHeight:(NSInteger)height {
    if (self->_barcode != NULL) {
        self->_barcode->height = height;
    }
}

- (NSInteger)width {
    return self->_barcode->height;
}

- (void)setWidth:(NSInteger)width {
    if (self->_barcode != NULL) {
        self->_barcode->width = width;
    }
}

- (NSInteger)borderWidth {
    return self->_barcode->height;
}

- (void)setBorderWidth:(NSInteger)borderWidth {
    if (self->_barcode != NULL) {
        self->_barcode->border_width = borderWidth;
    }
}


- (NSInteger)whitespaceWidth {
    return self->_barcode->whitespace_width;
}

- (void)setWhitespaceWidth:(NSInteger)whitespaceWidth {
    if (self->_barcode != NULL) {
        self->_barcode->whitespace_width = whitespaceWidth;
    }
}

- (BOOL)humanReadable {
    return self->_barcode->show_hrt;
}

- (void)setHumanReadable:(BOOL)humanReadable {
    if (self->_barcode != NULL) {
        self->_barcode->show_hrt = humanReadable;
    }
}

- (MTBarcodeBorderStyle)borderStyle {
    return self->_barcode->output_options;
}

- (void)setBorderStyle:(MTBarcodeBorderStyle)borderStyle {
    if (self->_barcode != NULL) {
        self->_barcode->output_options = borderStyle;
    }
}

- (void)encodeAndBuffer {
    if ([self barcode] != NULL) {
        NSString *inputString = [[self input] length] > 0 ? [self input] : @"";
        const char *input = [inputString UTF8String];
        int inputLen = strlen(input);
        BOOL success = ZBarcode_Encode_and_Buffer(self->_barcode, (unsigned char *)input, inputLen, 0);
        [self setSuccess:success];
    }
}

- (NSString *)errorMessage {
    NSString *errorMessage = nil;
    
    switch ([self success]) {
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
    return errorMessage;
}

- (void)drawInRect:(CGRect)rect {
    struct zint_symbol *barcode = [self barcode];
    if (barcode == NULL) {
        CGFloat midY = CGRectGetMidY(rect);
        [@"No barcode data." drawAtPoint:CGPointMake(CGPointZero.x, midY) withAttributes:nil];
        
    } else {
        
        if ([self errorMessage]) {
            CGFloat midY = CGRectGetMidY(rect);
            [[self errorMessage] drawAtPoint:CGPointMake(CGPointZero.x, midY) withAttributes:nil];
        }
        
        CGFloat skewValue;
        BOOL portrait = barcode->bitmap_height > barcode->bitmap_width;
        BOOL makeSmaller;
        if (portrait) {
            makeSmaller = barcode->bitmap_height > rect.size.height;
            if (makeSmaller) {    //Make bigger
                skewValue = rect.size.height / barcode->bitmap_height;
            } else {
                skewValue = barcode->bitmap_height / rect.size.height;
            }
        } else {
            makeSmaller = barcode->bitmap_width > rect.size.width;
            if (makeSmaller) {
                skewValue = rect.size.width / barcode->bitmap_width;
            } else {
                skewValue = barcode->bitmap_width / rect.size.width;
            }
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
        if ([self success] == 0) {
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
        
    }
}

+ (NSDictionary *)names {
    
    static NSDictionary *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @{
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
    });
    return names;
}

+ (NSString *)barcodeNameForType:(MTBarcodeType)type {
    return [[MTBarcode names] objectForKey:@(type)];
}

@end
