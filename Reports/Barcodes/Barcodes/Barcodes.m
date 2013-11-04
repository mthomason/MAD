//
//  Barcodes.m
//  Barcodes
//
//  Created by Michael Thomason on 11/2/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "Barcodes.h"
#import "zint.h"
#import <Foundation/Foundation.h>

@implementation Barcodes

+ (UIImage *)test {
    
    struct zint_symbol *barcode;
    barcode = ZBarcode_Create();
    if(barcode == NULL) {
        barcode = ZBarcode_Create();
    }
    barcode->symbology = BARCODE_UPCA;
    barcode->height = 100;
    barcode->width = 100;
    barcode->whitespace_width = 50;
    barcode->border_width = 0;
    barcode->scale = 1.0000f;
    
    //barcode->output_options = 0; //0, BARCODE_BIND, or BARCODE_BOX
    barcode->input_mode = UNICODE_MODE; //UNICODE_MODE, DATA_MODE, or GS1_MODE

    strcpy(barcode->primary, "");

    strcpy(barcode->fgcolour, "000000");
    strcpy(barcode->bgcolour, "FFFFFF");
    NSURL *url = [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@"tmp" isDirectory:YES];
    NSString *fn = [[url path] stringByAppendingPathComponent:@"out.png"];
    strcpy(barcode->outfile, [fn UTF8String]);

    
    const char *input = "72527270270";
    int inputLen = strlen(input);
    

    
    int ss = ZBarcode_Encode(barcode, (unsigned char *)input, inputLen);
    char *pngBuffer;
    int imgWidth, imgHeight;
    ss = ZBarcode_PNG_Buffer(barcode, 0, &pngBuffer, &imgWidth, &imgHeight);
    
    
    // FIXME: Someone buffer this shit, so we don't read and write to and from the fucking magnet.
    //          Below is my try after two hours.

    
    //CGImageRef imgRef = (CGImageRef)barcode->bitmap;
 
    //UIImage *image = [UIImage imageWithCGImage:imgRef];
    //size_t height = (size_t)barcode->bitmap_height;
    //size_t width = (size_t)barcode->bitmap_width;
/*    unsigned rowBytes = 4 * imgWidth;
    CGColorSpaceRef defaultSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreateWithData(pngBuffer, imgWidth, imgHeight, 8, rowBytes, defaultSpace, kCGBitmapAlphaInfoMask, NULL, NULL);
    CGColorSpaceRelease(defaultSpace);
    
    CGImageRef resultImageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage *image = [UIImage imageWithCGImage: (CGImageRef)resultImageRef];
    
    CGContextRelease(bitmapContext);
*/
    
    
    int error_number2;
	float scaler = barcode->scale;
	char *scaled_pixelbuf;
	int horiz, vert, i;
	int scale_width, scale_height;
	
	if(scaler == 0) { scaler = 0.5; }
	scale_width = imgWidth * scaler;
	scale_height = imgHeight * scaler;
	
	/* Apply scale options by creating another pixel buffer */
	if (!(scaled_pixelbuf = (char *) malloc(scale_width * scale_height))) {
		//printf("Insufficient memory for pixel buffer");
		//return ERROR_ENCODING_PROBLEM;
        return nil;
	} else {
		for(i = 0; i < (scale_width * scale_height); i++) {
			*(scaled_pixelbuf + i) = '0';
		}
	}
	
	for(vert = 0; vert < scale_height; vert++) {
		for(horiz = 0; horiz < scale_width; horiz++) {
			*(scaled_pixelbuf + (vert * scale_width) + horiz) = *(pngBuffer + ((int)(vert / scaler) * imgWidth) + (int)(horiz / scaler));
		}
	}
    
    
    
    
    
    int rotate_angle = 0;
    
    
    
//#ifndef _MSC_VER
//	unsigned char outdata[scale_width * 3 * scale_height];
//#else
	unsigned char *outdata = (unsigned char*)malloc(scale_width * 3 * scale_height);
//#endif
	int row, column, errno;
	int fgred, fggrn, fgblu, bgred, bggrn, bgblu;
	
	
	/* sort out colour options */
	//to_upper((unsigned char*)barcode->fgcolour);
	//to_upper((unsigned char*)barcode->bgcolour);
/*
	if(strlen(barcode->fgcolour) != 6) {
		//strcpy(barcode->errtxt, "Malformed foreground colour target");
		//return ERROR_INVALID_OPTION;
	}
	if(strlen(barcode->bgcolour) != 6) {
		//strcpy(barcode->errtxt, "Malformed background colour target");
		//return ERROR_INVALID_OPTION;
	}
	errno = is_sane(SSET, (unsigned char*)barcode->fgcolour, strlen(barcode->fgcolour));
	if (errno == ERROR_INVALID_DATA) {
		//strcpy(barcode->errtxt, "Malformed foreground colour target");
		//return ERROR_INVALID_OPTION;
	}
	errno = is_sane(SSET, (unsigned char*)barcode->bgcolour, strlen(barcode->bgcolour));
	if (errno == ERROR_INVALID_DATA) {
		//strcpy(barcode->errtxt, "Malformed background colour target");
		//return ERROR_INVALID_OPTION;
	}
	*/
	fgred = (16 * ctoi(barcode->fgcolour[0])) + ctoi(barcode->fgcolour[1]);
	fggrn = (16 * ctoi(barcode->fgcolour[2])) + ctoi(barcode->fgcolour[3]);
	fgblu = (16 * ctoi(barcode->fgcolour[4])) + ctoi(barcode->fgcolour[5]);
	bgred = (16 * ctoi(barcode->bgcolour[0])) + ctoi(barcode->bgcolour[1]);
	bggrn = (16 * ctoi(barcode->bgcolour[2])) + ctoi(barcode->bgcolour[3]);
	bgblu = (16 * ctoi(barcode->bgcolour[4])) + ctoi(barcode->bgcolour[5]);
    
	switch(rotate_angle) {
		case 0: /* Plot the right way up */
			for(row = 0; row < scale_height; row++) {
				for(column = 0; column < scale_width; column++) {
					int i = row * column * 3;
					switch(*(scaled_pixelbuf + (scale_width * row) + column))
					{
						case '1':
							outdata[i] = fgred;
							outdata[i + 1] = fggrn;
							outdata[i + 2] = fgblu;
							break;
						default:
							outdata[i] = bgred;
							outdata[i + 1] = bggrn;
							outdata[i + 2] = bgblu;
							break;
                            
					}
				}
			}
			break;
		case 90: /* Plot 90 degrees clockwise */
			for(row = 0; row < scale_width; row++) {
				for(column = 0; column < scale_height; column++) {
					int i = row * column * 3;
					switch(*(scaled_pixelbuf + (scale_width * (scale_height - column - 1)) + row))
					{
						case '1':
							outdata[i] = fgred;
							outdata[i + 1] = fggrn;
							outdata[i + 2] = fgblu;
							break;
						default:
							outdata[i] = bgred;
							outdata[i + 1] = bggrn;
							outdata[i + 2] = bgblu;
							break;
                            
					}
				}
			}
			break;
		case 180: /* Plot upside down */
			for(row = 0; row < scale_height; row++) {
				for(column = 0; column < scale_width; column++) {
					int i = row * column * 3;
					switch(*(scaled_pixelbuf + (scale_width * (scale_height - row - 1)) + (scale_width - column - 1)))
					{
						case '1':
							outdata[i] = fgred;
							outdata[i + 1] = fggrn;
							outdata[i + 2] = fgblu;
							break;
						default:
							outdata[i] = bgred;
							outdata[i + 1] = bggrn;
							outdata[i + 2] = bgblu;
							break;
                            
					}
				}
			}
			break;
		case 270: /* Plot 90 degrees anti-clockwise */
			for(row = 0; row < scale_width; row++) {
				for(column = 0; column < scale_height; column++) {
 					int i = row * column * 3;
					switch(*(scaled_pixelbuf + (scale_width * column) + (scale_width - row - 1)))
					{
						case '1':
							outdata[i] = fgred;
							outdata[i + 1] = fggrn;
							outdata[i + 2] = fgblu;
							break;
						default:
							outdata[i] = bgred;
							outdata[i + 1] = bggrn;
							outdata[i + 2] = bgblu;
							break;
                            
					}
				}
			}
			break;
	}
    
 
    
    NSUInteger len = abs(scale_width * 3 * scale_height);
    
    //CFDataRef dr = CFDataCreate(NULL, (const UInt8 *)outdata, len);
    //CGDataProviderRef dp = CGDataProviderCreateWithCFData(dr);

    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, (const UInt8 *)outdata, len, NULL);
    
    CGColorSpaceRef defaultSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imgr = CGImageCreate(scale_width, scale_height, 8, 8*3, scale_width * 3, defaultSpace, kCGBitmapByteOrderMask, dp, NULL, NO, kCGRenderingIntentDefault);

    
    //CGImageRef resultImageRef = CGImageCreateWithPNGDataProvider(dp, NULL, NO, kCGRenderingIntentDefault);


//    CGContextRelease(bitmapContext);
    
    UIImage *image = [UIImage imageWithCGImage: imgr];

    CGColorSpaceRelease(defaultSpace);
    
//	unsigned char * d = outdata;
//    NSUInteger len = abs(scale_width * 3 * scale_height);
//    NSData *data = [NSData dataWithBytes:outdata length:len];
//    UIImage *image = [UIImage imageWithCGImage: (CGImageRef) data];
//    UIImage *image = [UIImage imageWithData: (NSData *) scaled_pixelbuf];

    
    /*
	if(image_type == PNG_DATA) {
#ifndef NO_PNG
		error_number = png_pixel_plot(symbol, scale_height, scale_width, scaled_pixelbuf, rotate_angle);
#else
		return ERROR_INVALID_OPTION;
#endif
	} else {
		error_number = bmp_pixel_plot(symbol, scale_height, scale_width, scaled_pixelbuf, rotate_angle);
	}*/
	
	free(scaled_pixelbuf);
    
    
    //UIImage *resultImageFile = [[UIImage alloc] initWithContentsOfFile:fn];
    
    
    free(pngBuffer);
    
    ZBarcode_Delete(barcode);
    
    return image;
}

+ (UIImage *)test3 {
    
    struct zint_symbol *barcode;
    barcode = ZBarcode_Create();
    if(barcode == NULL) {
        barcode = ZBarcode_Create();
    }
    barcode->symbology = BARCODE_UPCA;
    barcode->height = 100;
    barcode->width = 100;
    barcode->whitespace_width = 0;
    barcode->border_width = 0;
    barcode->scale = 0.0000f;
    
    //barcode->output_options = 0; //0, BARCODE_BIND, or BARCODE_BOX
    barcode->input_mode = UNICODE_MODE; //UNICODE_MODE, DATA_MODE, or GS1_MODE
    
    strcpy(barcode->primary, "");
    
    strcpy(barcode->fgcolour, "000000");
    strcpy(barcode->bgcolour, "ffffff");
    NSURL *url = [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@"tmp" isDirectory:YES];
    NSString *fn = [[url path] stringByAppendingPathComponent:@"out.png"];
    strcpy(barcode->outfile, [fn UTF8String]);
    
    
    const char *input = "72527270270";
    int inputLen = strlen(input);
    
    
    
    int ss = ZBarcode_Encode(barcode, (unsigned char *)input, inputLen);
    //ss = ZBarcode_Print(barcode, 0);
    
    
    // FIXME: Someone buffer this shit, so we don't read and write to and from the fucking magnet.
    //          Below is my try after two hours.
     ss = ZBarcode_Buffer(barcode, 0);

    size_t height = (size_t)barcode->bitmap_height;
     size_t width = (size_t)barcode->bitmap_width;
     unsigned rowBytes = 3 * width;
     CGColorSpaceRef defaultSpace = CGColorSpaceCreateDeviceRGB();
     CGContextRef bitmapContext = CGBitmapContextCreateWithData(barcode->bitmap, width, height, 8, rowBytes, defaultSpace, kCGBitmapAlphaInfoMask, NULL, NULL);
     CGColorSpaceRelease(defaultSpace);
     
     CGImageRef resultImageRef = CGBitmapContextCreateImage(bitmapContext);
     
     CGContextRelease(bitmapContext);
     
     UIImage *image = [UIImage imageWithCGImage: resultImageRef];
    //UIImage *resultImageFile = [[UIImage alloc] initWithContentsOfFile:fn];
    
    
    ZBarcode_Delete(barcode);
    
    return image;
}

+ (UIImage *)test2 {
    
    struct zint_symbol *barcode;
    barcode = ZBarcode_Create();
    if(barcode == NULL) {
        barcode = ZBarcode_Create();
    }
    barcode->symbology = BARCODE_UPCA;
    barcode->height = 200;
    barcode->width = 200;
    barcode->whitespace_width = 0;
    barcode->border_width = 0;
    barcode->scale = 1.0000f;
    
    //barcode->output_options = 0; //0, BARCODE_BIND, or BARCODE_BOX
    barcode->input_mode = UNICODE_MODE; //UNICODE_MODE, DATA_MODE, or GS1_MODE
    
    strcpy(barcode->primary, "");
    
    strcpy(barcode->fgcolour, "000000");
    strcpy(barcode->bgcolour, "ffffff");
    NSURL *url = [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@"tmp" isDirectory:YES];
    NSString *fn = [[url path] stringByAppendingPathComponent:@"out.png"];
    strcpy(barcode->outfile, [fn UTF8String]);
    
    
    const char *input = "72527270270";
    int inputLen = strlen(input);
    
    
    
    int ss = ZBarcode_Encode(barcode, (unsigned char *)input, inputLen);
    ss = ZBarcode_Print(barcode, 0);
    
    
    // FIXME: Someone buffer this shit, so we don't read and write to and from the fucking magnet.
    //          Below is my try after two hours.
    /*
     ss = ZBarcode_Buffer(barcode, 0);
     CGImageRef imgRef = (CGImageRef)barcode->bitmap;
     
     UIImage *image = [UIImage imageWithCGImage:imgRef];
     size_t height = (size_t)barcode->bitmap_height;
     size_t width = (size_t)barcode->bitmap_width;
     unsigned rowBytes = 4 * width;
     CGColorSpaceRef defaultSpace = CGColorSpaceCreateDeviceRGB();
     CGContextRef bitmapContext = CGBitmapContextCreateWithData(barcode->bitmap, width, height, 8, 0, defaultSpace, kCGBitmapAlphaInfoMask | kCGBitmapByteOrderDefault, NULL, NULL);
     CGColorSpaceRelease(defaultSpace);
     
     CGImageRef resultImageRef = CGBitmapContextCreateImage(bitmapContext);
     
     CGContextRelease(bitmapContext);
     
     UIImage *image = [UIImage imageWithCGImage: resultImageRef];
     */
    UIImage *resultImageFile = [[UIImage alloc] initWithContentsOfFile:fn];
    
    
    ZBarcode_Delete(barcode);
    
    return resultImageFile;
}

+ (void)barcodeForType:(MTBarcodeType)barcodeType
                  size:(CGSize)barcodeSize
           borderStyle:(MTBarcodeBorderStyle)borderStyle
             stringToEncode:(NSString *)stringToEncode
       whitespaceWidth:(NSInteger)whitespaceWidth
                 scale:(CGFloat)scale
            completion:(void(^)(UIImage *barcodeImage, BOOL success, NSError *error))completion {
    
    struct zint_symbol *barcode;
    barcode = ZBarcode_Create();
    if(barcode == NULL) {
        barcode = ZBarcode_Create();
    }
    int sizeWidth = (int)barcodeSize.width;
    int sizeHeight = (int)barcodeSize.height;
    barcode->symbology = barcodeType;
    barcode->height = sizeHeight;
    barcode->width = sizeWidth;
    barcode->whitespace_width = whitespaceWidth;
    barcode->border_width = whitespaceWidth;
    barcode->scale = scale;
    
    barcode->output_options = borderStyle;
    barcode->input_mode = MTBarcodeDataTypeUnicode;
    
    strcpy(barcode->primary, "");
    
    strcpy(barcode->fgcolour, "000000");
    strcpy(barcode->bgcolour, "ffffff");
    int aScale = (int)scale;
    NSString *tmpFileName = [NSString stringWithFormat:@"%@%d-%d-X-%d-%d-%d.png", stringToEncode, barcodeType, sizeWidth, sizeHeight, whitespaceWidth, aScale];
    NSURL *url = [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@"tmp" isDirectory:YES];
    NSString *fn = [[url path] stringByAppendingPathComponent:tmpFileName];
    strcpy(barcode->outfile, [fn UTF8String]);
    
    
    const char *input = [stringToEncode UTF8String];
    int inputLen = strlen(input);
    
    int success = ZBarcode_Encode(barcode, (unsigned char *)input, inputLen);
    success = ZBarcode_Print(barcode, 0);
    
    NSString *errorMessage = nil;
    NSError *error = nil;
    switch (success) {
        case WARN_INVALID_OPTION:
            errorMessage = @"Warning: Invalid Option.";
            break;
        case ERROR_TOO_LONG:
            errorMessage = @"Barcode error: To long.";
            break;
        case ERROR_INVALID_DATA:
            errorMessage = @"Barcode error: Invalid data.";
            break;
        case ERROR_INVALID_CHECK:
            errorMessage = @"Barcode error: Invalid check.";
            break;
        case ERROR_ENCODING_PROBLEM:
            errorMessage = @"Barcode error: Encoding problem.";
            break;
        case ERROR_FILE_ACCESS:
            errorMessage = @"Barcode error: File access.";
            break;
        case ERROR_MEMORY:
            errorMessage = @"Barcode error: Memory error.";
            break;
        default:
            break;
    }
    if (errorMessage != nil) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorMessage};
        error = [NSError errorWithDomain:@"Barcodes" code:success userInfo:userInfo];
    }
    
    UIImage *resultImageFile = [[UIImage alloc] initWithContentsOfFile:fn];
    
    
    ZBarcode_Delete(barcode);
    
    BOOL returnSucces = success == 0;
    completion(resultImageFile, returnSucces, error);
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
    return [[Barcodes names] objectForKey:@(type)];
}

@end
