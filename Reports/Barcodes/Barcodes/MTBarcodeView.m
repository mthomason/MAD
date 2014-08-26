//
//  MTBarcodeView.m
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeView.h"
#import "MTBarcode.h"

@interface MTBarcodeView ()

@end

@implementation MTBarcodeView

- (void)dealloc {
    [_barcode release];
    [super dealloc];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSAssert(NO, @"Don't you dare!");
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

/*
- (instancetype)initWithFrame:(CGRect)frame
                 type:(MTBarcodeType)barcodeType
          borderStyle:(MTBarcodeBorderStyle)borderStyle
       stringToEncode:(NSString *)stringToEncode
      whitespaceWidth:(NSInteger)whitespaceWidth {

    self = [super initWithFrame:frame];
    if (self) {
        
        [self setRotate:(90 * M_PI / 180)];
        self.backgroundColor = [UIColor clearColor];
        
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
 */

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    if ([self barcode]) {
        [[self barcode] setCenter: YES];
        [[self barcode] drawInRect:rect];
    }
}

@end
