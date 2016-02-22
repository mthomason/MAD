//
//  MTBarcode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcode_h
#define Barcodes_MTBarcode_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MTBarcodeProtocol.h"
#import "MADBarcodeType.h"
#import "zint.h"

typedef NS_ENUM(unsigned char, MTBarcodeSizingMode) {
    MTBarcodeSizingModeAutomaticResizing     = 1,
    MTBarcodeSizingModeSpecificSize          = 2,
    MTBarcodeSizingModeSpecificErrorLevel    = 3
};

typedef NS_ENUM(unsigned char, MTBarcodeBorderStyle) {
    MTBarcodeBorderStyleNone    = 0,
    MTBarcodeBorderStyleBind    = BARCODE_BIND,
    MTBarcodeBorderStyleBox     = BARCODE_BOX
};

typedef NS_ENUM(unsigned char, MTBarcodeDataInputType) {
    MTBarcodeDataTypeUnicode = UNICODE_MODE,
    MTBarcodeDataTypeData = DATA_MODE,
    MTBarcodeDataTypeGs1 = GS1_MODE
};

@interface MTBarcode : NSObject
    <MTBarcodeProtocol>

@property (nonatomic, retain, readwrite) UIColor *forgroundColor;
@property (nonatomic, retain, readwrite) UIColor *backgroundColor;

@property (nonatomic, assign, readonly) MTBarcodeType barcodeType;
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSString *detailsSegueIdentifer;
@property (nonatomic, retain) NSString *primaryData;

@property (nonatomic, assign, readonly) BOOL has2dComponent;
@property (nonatomic, assign, readonly) BOOL hasOptionalInput;

@property (nonatomic, assign) NSInteger option1;
@property (nonatomic, assign) NSInteger option2;
@property (nonatomic, assign) NSInteger option3;

@property (nonatomic, assign) BOOL center;

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
+ (instancetype)barcodeWithType :(MTBarcodeType)type;

@end

#endif
