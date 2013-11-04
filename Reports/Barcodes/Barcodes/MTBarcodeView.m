//
//  MTBarcodeView.m
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeView.h"
#import "Barcodes.h"

@interface MTBarcodeView ()

@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, assign) struct zint_symbol *barcode;
@property (nonatomic, assign) CGFloat pixelSize;
@property (nonatomic, assign) CGFloat rotate;

@end

@implementation MTBarcodeView

- (void)dealloc {
    [_errorMessage release];
    ZBarcode_Delete(_barcode);
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSAssert(NO, @"Don't you dare!");
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
                 type:(MTBarcodeType)barcodeType
          borderStyle:(MTBarcodeBorderStyle)borderStyle
       stringToEncode:(NSString *)stringToEncode
      whitespaceWidth:(NSInteger)whitespaceWidth {

    self = [super initWithFrame:frame];
    if (self) {
        
        [self setRotate:(90 * M_PI / 180)];
        [self setBackgroundColor:[UIColor clearColor]];
        
        CGFloat pixelSize = 1.0000f * [[UIScreen mainScreen] scale];
        [self setPixelSize:pixelSize];

        struct zint_symbol *barcode;
        barcode = ZBarcode_Create();
        if(barcode == NULL) {
            barcode = ZBarcode_Create();
        }
        int sizeWidth = (int)frame.size.width / 2;
        int sizeHeight = (int)frame.size.height / 2;
        barcode->symbology = barcodeType;
        barcode->height = sizeHeight;
        barcode->width = sizeWidth;
        barcode->whitespace_width = 0;//whitespaceWidth;
        barcode->border_width = 0;
        barcode->scale = 1.0000f;
        
        barcode->output_options = MTBarcodeBorderStyleBox; //borderStyle;
        barcode->input_mode = MTBarcodeDataTypeUnicode;
        
        strcpy(barcode->primary, "");
        
        strcpy(barcode->fgcolour, "000000");
        strcpy(barcode->bgcolour, "ffffff");
        
        const char *input = [stringToEncode UTF8String];
        int inputLen = strlen(input);
        
        int success = ZBarcode_Encode(barcode, (unsigned char *)input, inputLen);
        
        [self setBarcode:barcode];
        
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
        [self setErrorMessage:errorMessage];
    
    }
    return self;
    
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    struct zint_symbol *barcode = [self barcode];
    int success = ZBarcode_Buffer(barcode, 0);

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

    
}

@end
