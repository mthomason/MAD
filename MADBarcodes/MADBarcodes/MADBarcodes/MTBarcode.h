//
//  MTBarcode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcode_h
#define Barcodes_MTBarcode_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

#import "MTBarcodeProtocol.h"
#import "MADBarcodeType.h"

#import "MADBarcodeBorderStyle.h"
#import "MADBarcodeSizingMode.h"

@class MADColor;

@interface MTBarcode : NSObject
    <MTBarcodeProtocol>

    + (instancetype)newBarcodeWithType:(MTBarcodeType)type;

    @property (nonatomic, readonly, strong) NSString *name;
    @property (nonatomic, readonly, strong) NSString *detailsSegueIdentifer;
    @property (nonatomic, copy)             NSString *primaryData;

    @property (nonatomic, copy, readwrite)  MADColor *forgroundColor;
    @property (nonatomic, copy, readonly)   MADColor *backgroundColor;

    @property (nonatomic, assign, readonly) MTBarcodeType barcodeType;

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

    @property (nonatomic, assign) float scale;

    - (void)drawInRect:(CGRect)rect;

    + (NSString *)newBarcodeNameForType:(MTBarcodeType)type;
    + (NSDictionary *)newDictionaryNames;

@end

#endif
